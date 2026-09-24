extends Node
## Single source of truth for runtime run data.
## Read values through the getters; change them only through these functions.
## Balance numbers live in RunConfig (res://resources/config/run_config.tres).

signal gold_changed(balance: float, delta: float)
## Actual Gold earned per second, averaged over about the last 10 seconds.
signal gold_per_second_changed(value: float)
signal health_changed(current: float, maximum: float)
## Effective spin speed in radians/second (what Carousel applies each tick).
signal spin_speed_changed(speed_rad_s: float)
signal booth_count_changed(count: int)
## An upgrade level was bought and fully applied (Gold, level, and effect).
signal upgrade_applied(id: StringName, level: int)
## Emitted after every value has been reset, before the fresh values are re-announced.
signal run_reset

const DEFAULT_CONFIG: RunConfig = preload("res://resources/config/run_config.tres")

var _config: RunConfig = DEFAULT_CONFIG
var _gold: float = 0.0
var _health: float = 0.0
# Click boost: the bonus at the latest press, fading linearly to 0 over the decay time.
var _boost_peak: float = 0.0
var _boost_elapsed: float = 0.0
# Upgrade effects, summed over bought levels.
var _spin_bonus: float = 0.0
var _boost_cap_bonus: float = 0.0
var _booth_count: int = 1
var _upgrade_levels: Dictionary[StringName, int] = {}
var _purchase_in_progress: bool = false
# Gold/sec: Gold earned per time bucket in a ring (bucket = epoch % count).
var _income_buckets := PackedFloat64Array()
var _income_epoch: int = 0
var _recent_income: float = 0.0
var _elapsed: float = 0.0
# Sum of latched enemies' drag, deliberately NOT clamped at 1.0. Added in Step 7.
var _total_drag: float = 0.0


func _ready() -> void:
	reset_run()


## Starts a fresh run. Tests pass their own config so the real .tres is never edited.
func reset_run(config_override: RunConfig = null) -> void:
	var config: RunConfig = config_override if config_override != null else DEFAULT_CONFIG
	var problems := config.get_problems()
	if not problems.is_empty():
		push_error("RunConfig invalid, using defaults: %s" % ", ".join(problems))
		config = DEFAULT_CONFIG
	_config = config
	_gold = config.starting_gold
	_health = config.max_health
	_boost_peak = 0.0
	_boost_elapsed = 0.0
	_spin_bonus = 0.0
	_boost_cap_bonus = 0.0
	_booth_count = config.starting_booths
	_total_drag = 0.0
	_upgrade_levels.clear()
	_income_buckets = PackedFloat64Array()
	_income_buckets.resize(config.income_bucket_count)
	_income_epoch = 0
	_recent_income = 0.0
	_elapsed = 0.0
	# Set everything first so listeners never see a half-reset run.
	run_reset.emit()
	gold_changed.emit(_gold, 0.0)
	gold_per_second_changed.emit(get_recent_gold_per_second())
	health_changed.emit(_health, get_max_health())
	spin_speed_changed.emit(get_effective_spin_speed_rad_s())
	booth_count_changed.emit(_booth_count)


# --- Gold -------------------------------------------------------------------

func get_gold() -> float:
	return _gold


## Adds earned Gold. Ignores zero, negative, and non-finite amounts.
func add_gold(amount: float) -> void:
	if not is_finite(amount) or amount <= 0.0:
		return
	_gold += amount
	_income_buckets[_income_epoch % _income_buckets.size()] += amount
	_recent_income += amount
	gold_changed.emit(_gold, amount)
	gold_per_second_changed.emit(get_recent_gold_per_second())


## Actual Gold earned per second over the income window. Spending doesn't lower it.
## Starts from zero and fills up over the first window (no spike from one payout).
func get_recent_gold_per_second() -> float:
	return _recent_income / (_config.income_bucket_count * _config.income_bucket_seconds)


func can_afford(cost: float) -> bool:
	return is_finite(cost) and cost >= 0.0 and cost <= _gold


## All-or-nothing: returns false and changes nothing if the cost can't be paid.
func spend_gold(cost: float) -> bool:
	if not can_afford(cost):
		return false
	if cost == 0.0:
		return true
	_gold -= cost
	gold_changed.emit(_gold, -cost)
	return true


# --- Carousel health ----------------------------------------------------------

func get_health() -> float:
	return _health


func get_max_health() -> float:
	return _config.max_health


## Lowers health, never below zero. (The TEMPORARY stall at zero arrives in Step 7.)
func damage_carousel(amount: float) -> void:
	if not is_finite(amount) or amount <= 0.0:
		return
	var new_health := maxf(0.0, _health - amount)
	if new_health == _health:
		return
	_health = new_health
	health_changed.emit(_health, get_max_health())


# --- Simulation ----------------------------------------------------------------

## Advances time-based state by one physics tick. Game calls this once per tick,
## before moving the carousel, so everything updates in one known order.
func advance_simulation(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	var previous_speed := get_effective_spin_speed_rad_s()
	_boost_elapsed = minf(_config.click_boost_decay_seconds, _boost_elapsed + delta)
	_emit_speed_if_changed(previous_speed)
	_elapsed += delta
	_advance_income_window()


func _advance_income_window() -> void:
	var epoch := floori(_elapsed / _config.income_bucket_seconds)
	if epoch == _income_epoch:
		return
	var count := _income_buckets.size()
	if epoch - _income_epoch >= count:
		_income_buckets.fill(0.0)
		_recent_income = 0.0
	else:
		for e in range(_income_epoch + 1, epoch + 1):
			_recent_income -= _income_buckets[e % count]
			_income_buckets[e % count] = 0.0
		_recent_income = maxf(0.0, _recent_income)  # guard against float drift
	_income_epoch = epoch
	gold_per_second_changed.emit(get_recent_gold_per_second())


# --- Spin speed ------------------------------------------------------------------

## base × upgrades × (1 + click boost) × (1 − drag), never below zero.
func get_effective_spin_speed_rad_s() -> float:
	var drag_factor := maxf(0.0, 1.0 - _total_drag)
	return (deg_to_rad(_config.base_spin_speed_deg_s)
			* get_spin_upgrade_multiplier()
			* (1.0 + get_click_boost())
			* drag_factor)


## Current speed as a multiple of base speed (1.35 = 35% faster than base).
## Includes upgrades, boost, and drag; this is what the HUD shows.
func get_speed_multiplier() -> float:
	var base := deg_to_rad(_config.base_spin_speed_deg_s)
	return get_effective_spin_speed_rad_s() / base if base > 0.0 else 0.0


## 1.0 plus every purchased spin bonus, added together (+20% twice = 1.4).
func get_spin_upgrade_multiplier() -> float:
	return 1.0 + _spin_bonus


func get_total_drag() -> float:
	return _total_drag


## Max boost as a fraction (0.5 = +50%), including Boost Power levels.
func get_boost_cap() -> float:
	return _config.click_boost_cap + _boost_cap_bonus


## Current click bonus as a fraction (0.3 = +30%).
func get_click_boost() -> float:
	var remaining := maxf(0.0, 1.0 - _boost_elapsed / _config.click_boost_decay_seconds)
	return _boost_peak * remaining


## How full the boost bar is, 0..1.
func get_click_boost_fraction() -> float:
	var cap := get_boost_cap()
	return get_click_boost() / cap if cap > 0.0 else 0.0


## One Boost press: add 1/presses_to_fill of the cap, stack up to the cap, and
## restart the fade.
func add_click_boost() -> void:
	var previous_speed := get_effective_spin_speed_rad_s()
	var cap := get_boost_cap()
	_boost_peak = minf(cap, get_click_boost() + cap / _config.boost_presses_to_fill)
	_boost_elapsed = 0.0
	_emit_speed_if_changed(previous_speed)


func _emit_speed_if_changed(previous_speed: float) -> void:
	var speed := get_effective_spin_speed_rad_s()
	if speed != previous_speed:
		spin_speed_changed.emit(speed)


# --- Ticket booths ------------------------------------------------------------------

func get_booth_count() -> int:
	return _booth_count


# --- Upgrades --------------------------------------------------------------------

## Levels bought (0 = not bought).
func get_upgrade_level(id: StringName) -> int:
	return _upgrade_levels.get(id, 0)


func is_upgrade_purchased(id: StringName) -> bool:
	return get_upgrade_level(id) > 0


func is_upgrade_maxed(upgrade: UpgradeData) -> bool:
	return upgrade != null and get_upgrade_level(upgrade.id) >= upgrade.max_level


## Price of the next level.
func get_upgrade_cost(upgrade: UpgradeData) -> float:
	return upgrade.get_cost_for_level(get_upgrade_level(upgrade.id))


## True if the next level could be bought right now (funds, prerequisite, not
## maxed, effect supported). UpgradeManager.purchase() is the normal entry point.
func can_purchase_upgrade(upgrade: UpgradeData) -> bool:
	if upgrade == null or not upgrade.get_problems().is_empty():
		return false
	if is_upgrade_maxed(upgrade):
		return false
	if upgrade.prerequisite_id != &"" and not is_upgrade_purchased(upgrade.prerequisite_id):
		return false
	if not _is_effect_supported(upgrade):
		return false
	return can_afford(get_upgrade_cost(upgrade))


## Charges, records, and applies one level, all before any signal fires, so a
## listener can never see (or trigger) a half-finished purchase.
func try_purchase_upgrade(upgrade: UpgradeData) -> bool:
	if _purchase_in_progress or not can_purchase_upgrade(upgrade):
		return false
	_purchase_in_progress = true
	var cost := get_upgrade_cost(upgrade)
	var previous_speed := get_effective_spin_speed_rad_s()
	var previous_booths := _booth_count
	_gold -= cost
	_upgrade_levels[upgrade.id] = get_upgrade_level(upgrade.id) + 1
	match upgrade.effect_type:
		UpgradeData.EffectType.ADD_SPIN_BONUS:
			_spin_bonus += upgrade.effect_value
		UpgradeData.EffectType.ADD_BOOST_CAP:
			_boost_cap_bonus += upgrade.effect_value
		UpgradeData.EffectType.ADD_TICKET_BOOTH:
			_booth_count += 1
	# Everything is committed; now announce it.
	gold_changed.emit(_gold, -cost)
	_emit_speed_if_changed(previous_speed)
	if _booth_count != previous_booths:
		booth_count_changed.emit(_booth_count)
	upgrade_applied.emit(upgrade.id, get_upgrade_level(upgrade.id))
	_purchase_in_progress = false
	return true


func _is_effect_supported(upgrade: UpgradeData) -> bool:
	return upgrade.effect_type in [
		UpgradeData.EffectType.ADD_SPIN_BONUS,
		UpgradeData.EffectType.ADD_BOOST_CAP,
		UpgradeData.EffectType.ADD_TICKET_BOOTH,
	]
