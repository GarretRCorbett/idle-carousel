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
## The boost bar reached max (true) or fell back below the "maxed" line (false).
signal boost_maxed_changed(maxed: bool)
## Overdrive started (true) or ended (false).
signal overdrive_changed(active: bool)
## An upgrade level was bought and fully applied (Gold, level, and effect).
signal upgrade_applied(id: StringName, level: int)
## A mount was sold back; its level is already lowered and the refund paid.
signal upgrade_sold(id: StringName, level: int)
## The mounts on the carousel changed. roster lists mount ids in placement order.
signal mounts_changed(roster: Array[StringName])
## Mount slot capacity changed.
signal mount_slots_changed(count: int)
## Number of latched enemies changed.
signal latch_count_changed(count: int)
## TEMPORARY: the carousel stalled at 0 health (true) or restarted (false).
signal stall_changed(stalled: bool)
## TEMPORARY: while stalled, how full the crank meter is (0..1).
signal crank_changed(fraction: float)
## TEMPORARY: stalled too long. Latches are already cleared and health restored;
## Game removes every enemy (no Gold).
signal stall_timed_out
## Emitted after every value has been reset, before the fresh values are re-announced.
signal run_reset

## One latched enemy's share of drag and damage, and how long it has held on
## (damage starts after the grace period).
class Latch:
	var drag: float
	var damage_per_second: float
	var age: float = 0.0

	func _init(drag_amount: float, dps: float) -> void:
		drag = drag_amount
		damage_per_second = dps


## The mount a run starts with (RunConfig.starting_horses of them).
const STARTING_MOUNT: StringName = &"horse"
const DEFAULT_CONFIG: RunConfig = preload("res://resources/config/run_config.tres")

var _config: RunConfig = DEFAULT_CONFIG
var _gold: float = 0.0
var _health: float = 0.0
# Click boost: the bonus at the latest press, fading linearly to 0 over the decay time.
var _boost_peak: float = 0.0
var _boost_elapsed: float = 0.0
var _boost_maxed: bool = false
var _boost_maxed_seconds: float = 0.0
var _overdrive: bool = false
## Temporary speed multipliers by source (overdrive now; random events later).
## They multiply together and into the effective speed.
var _speed_modifiers: Dictionary[StringName, float] = {}
# Upgrade effects, summed over bought levels.
var _spin_bonus: float = 0.0
var _boost_cap_bonus: float = 0.0
var _click_damage_bonus: float = 0.0
var _wolf_damage_bonus: float = 0.0
var _booth_count: int = 1
# Mounts: ids (the BUY_MOUNT upgrade id, e.g. &"horse") in placement order.
var _mount_roster: Array[StringName] = []
var _mount_slots: int = 1
var _upgrade_levels: Dictionary[StringName, int] = {}
var _purchase_in_progress: bool = false
# Gold/sec: Gold earned per time bucket in a ring (bucket = epoch % count).
var _income_buckets := PackedFloat64Array()
var _income_epoch: int = 0
var _recent_income: float = 0.0
var _elapsed: float = 0.0
# Latched enemies by instance ID. Totals are recomputed from this, so removing
# one enemy removes exactly its share.
var _latches: Dictionary[int, Latch] = {}
# Sum of latched enemies' drag, not clamped (the speed curve softens it instead).
var _total_drag: float = 0.0
var _total_latch_dps: float = 0.0
# Seconds since the rim was last latched (drives regen).
var _clear_seconds: float = 0.0
# TEMPORARY stall (see RunConfig "Stall").
var _stalled: bool = false
var _stall_seconds: float = 0.0
var _crank: float = 0.0
var _boost_held: bool = false
var _protection_left: float = 0.0


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
	_boost_maxed = false
	_boost_maxed_seconds = 0.0
	_overdrive = false
	_speed_modifiers.clear()
	_spin_bonus = 0.0
	_boost_cap_bonus = 0.0
	_click_damage_bonus = 0.0
	_wolf_damage_bonus = 0.0
	_booth_count = config.starting_booths
	_mount_slots = config.starting_mount_slots
	_mount_roster.clear()
	for i in config.starting_horses:
		_mount_roster.append(STARTING_MOUNT)
	_latches.clear()
	_total_drag = 0.0
	_total_latch_dps = 0.0
	_clear_seconds = 0.0
	_stalled = false
	_stall_seconds = 0.0
	_crank = 0.0
	_boost_held = false
	_protection_left = 0.0
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
	mount_slots_changed.emit(_mount_slots)
	mounts_changed.emit(get_mount_roster())
	boost_maxed_changed.emit(false)
	overdrive_changed.emit(false)
	latch_count_changed.emit(0)
	stall_changed.emit(false)
	crank_changed.emit(0.0)


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


## Lowers health, never below zero. At zero the carousel stalls (TEMPORARY).
func damage_carousel(amount: float) -> void:
	if not is_finite(amount) or amount <= 0.0:
		return
	var new_health := maxf(0.0, _health - amount)
	if new_health != _health:
		_set_health(new_health)


## Sets health, settles the stall rule, then announces everything.
func _set_health(value: float) -> void:
	var previous_speed := get_effective_spin_speed_rad_s()
	_health = value
	var stall_flipped := _evaluate_temporary_stall()
	health_changed.emit(_health, get_max_health())
	if stall_flipped:
		stall_changed.emit(_stalled)
	_emit_speed_if_changed(previous_speed)


## Latch damage (after each latch's grace), regen once the rim is clear, and
## the stall's crank and timeout. Called once per tick from advance_simulation().
func _advance_health(delta: float) -> void:
	var damage := 0.0
	for latch: Latch in _latches.values():
		var before := latch.age
		latch.age += delta
		var grace := _config.latch_grace_seconds
		damage += latch.damage_per_second * (maxf(0.0, latch.age - grace) - maxf(0.0, before - grace))
	if _stalled:
		_advance_stall(delta)
		return
	if _protection_left > 0.0:
		_protection_left = maxf(0.0, _protection_left - delta)
		damage = 0.0
	damage_carousel(damage)
	if not _latches.is_empty():
		_clear_seconds = 0.0
		return
	_clear_seconds += delta
	if _clear_seconds >= _config.regen_delay_seconds and _health < get_max_health():
		_set_health(minf(get_max_health(), _health + _config.regen_per_second * delta))


func is_stalled() -> bool:
	return _stalled


## Crank meter while stalled, 0..1.
func get_crank_fraction() -> float:
	return _crank


## Whether the Boost button (or its key) is held down. Holding cranks a stall.
func set_boost_held(held: bool) -> void:
	_boost_held = held


# --- Latches -------------------------------------------------------------------------

## An enemy grabbed the rim. Returns false (and changes nothing) if it's already latched.
func register_latch(enemy_id: int, drag: float, damage_per_second: float) -> bool:
	if _latches.has(enemy_id) or not is_finite(drag) or not is_finite(damage_per_second):
		return false
	var previous_speed := get_effective_spin_speed_rad_s()
	_latches[enemy_id] = Latch.new(maxf(0.0, drag), maxf(0.0, damage_per_second))
	_clear_seconds = 0.0
	_recompute_latch_totals()
	latch_count_changed.emit(_latches.size())
	_emit_speed_if_changed(previous_speed)
	return true


## A latched enemy is gone. Safe to call twice or for an enemy that never latched.
func unregister_latch(enemy_id: int) -> bool:
	if not _latches.has(enemy_id):
		return false
	var previous_speed := get_effective_spin_speed_rad_s()
	_latches.erase(enemy_id)
	_recompute_latch_totals()
	var stall_flipped := _evaluate_temporary_stall()
	latch_count_changed.emit(_latches.size())
	if stall_flipped:
		health_changed.emit(_health, get_max_health())
		stall_changed.emit(_stalled)
	_emit_speed_if_changed(previous_speed)
	return true


func get_latched_count() -> int:
	return _latches.size()


## Damage per second of every latch, including ones still in their grace period.
func get_total_latch_dps() -> float:
	return _total_latch_dps


func _recompute_latch_totals() -> void:
	_total_drag = 0.0
	_total_latch_dps = 0.0
	for latch: Latch in _latches.values():
		_total_drag += latch.drag
		_total_latch_dps += latch.damage_per_second


# --- TEMPORARY Phase 2 stall ----------------------------------------------------------
# Replace once Garret decides the GDD's DECISION PENDING fail state
# (direction so far: planning/phase2/README.md, "Package A").

## Stall at 0 health; restart at 25% once nothing is latched (0 health with
## nothing latched restarts right away). Returns true if the stall flipped.
## Only sets state; callers announce it.
func _evaluate_temporary_stall() -> bool:
	var was_stalled := _stalled
	if _health <= 0.0 and not _stalled:
		_stalled = true
		_stall_seconds = 0.0
		_crank = 0.0
	if _stalled and _latches.is_empty():
		_health = get_max_health() * _config.stall_recovery_fraction
		_stalled = false
	return _stalled != was_stalled


func _advance_stall(delta: float) -> void:
	_stall_seconds += delta
	if _boost_held:
		_add_crank(delta / _config.crank_hold_seconds)
	if _stalled and _stall_seconds >= _config.stall_timeout_seconds:
		_latches.clear()
		_recompute_latch_totals()
		latch_count_changed.emit(0)
		_restart_from_stall(_config.stall_recovery_fraction)
		stall_timed_out.emit()


func _add_crank(amount: float) -> void:
	_crank = minf(1.0, _crank + amount)
	# Approximate: ten presses of 0.1 add up to 0.9999999, not 1.
	if is_equal_approx(_crank, 1.0):
		_crank = 1.0
	crank_changed.emit(_crank)
	if _crank >= 1.0:
		# Latches stay: cranking buys movement, not a fix.
		_protection_left = _config.crank_protection_seconds
		_restart_from_stall(_config.crank_restart_fraction)


func _restart_from_stall(health_fraction: float) -> void:
	var previous_speed := get_effective_spin_speed_rad_s()
	_health = get_max_health() * health_fraction
	_stalled = false
	_stall_seconds = 0.0
	_crank = 0.0
	health_changed.emit(_health, get_max_health())
	stall_changed.emit(false)
	crank_changed.emit(0.0)
	_emit_speed_if_changed(previous_speed)


# --- Simulation ----------------------------------------------------------------

## Advances time-based state by one physics tick. Game calls this once per tick,
## before moving the carousel, so everything updates in one known order.
func advance_simulation(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	var previous_speed := get_effective_spin_speed_rad_s()
	_boost_elapsed = minf(_config.click_boost_decay_seconds, _boost_elapsed + delta)
	_update_boost_status(delta)
	_emit_speed_if_changed(previous_speed)
	_advance_health(delta)
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

## base × upgrades × (1 + click boost) × modifiers (Overdrive, events) ÷ (1 + drag).
## Drag slows it less and less as it stacks, so Boost always helps; only the
## TEMPORARY stall stops it completely.
func get_effective_spin_speed_rad_s() -> float:
	if _stalled:
		return 0.0
	var drag_factor := 1.0 / (1.0 + _total_drag)
	return (deg_to_rad(_config.base_spin_speed_deg_s)
			* get_spin_upgrade_multiplier()
			* (1.0 + get_click_boost())
			* get_speed_modifier_multiplier()
			* drag_factor)


## Product of every temporary speed modifier (1.0 when there are none).
func get_speed_modifier_multiplier() -> float:
	var product := 1.0
	for multiplier in _speed_modifiers.values():
		product *= multiplier
	return product


## Adds or replaces a temporary speed multiplier from one source (e.g. &"overdrive",
## later a random event). Remove it with remove_speed_modifier().
func set_speed_modifier(source: StringName, multiplier: float) -> void:
	if not is_finite(multiplier) or multiplier < 0.0:
		return
	var previous_speed := get_effective_spin_speed_rad_s()
	_speed_modifiers[source] = multiplier
	_emit_speed_if_changed(previous_speed)


func remove_speed_modifier(source: StringName) -> void:
	if not _speed_modifiers.has(source):
		return
	var previous_speed := get_effective_spin_speed_rad_s()
	_speed_modifiers.erase(source)
	_emit_speed_if_changed(previous_speed)


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
## restart the fade. While stalled, it turns the crank instead.
func add_click_boost() -> void:
	if _stalled:
		_add_crank(1.0 / _config.crank_presses)
		return
	var previous_speed := get_effective_spin_speed_rad_s()
	var cap := get_boost_cap()
	_boost_peak = minf(cap, get_click_boost() + cap / _config.boost_presses_to_fill)
	_boost_elapsed = 0.0
	_update_boost_status(0.0)
	_emit_speed_if_changed(previous_speed)


func is_boost_maxed() -> bool:
	return _boost_maxed


func is_overdrive_active() -> bool:
	return _overdrive


## Seconds the boost has stayed maxed (0 when not maxed); for a charge-up display.
func get_boost_maxed_seconds() -> float:
	return _boost_maxed_seconds


## Tracks "maxed" with two thresholds so dips between presses don't break it,
## and turns Overdrive on after holding it long enough, off when it breaks.
func _update_boost_status(delta: float) -> void:
	var fraction := get_click_boost_fraction()
	if not _boost_maxed and fraction >= _config.boost_maxed_on_fraction:
		_boost_maxed = true
		_boost_maxed_seconds = 0.0
		boost_maxed_changed.emit(true)
	elif _boost_maxed and fraction < _config.boost_maxed_off_fraction:
		_boost_maxed = false
		_boost_maxed_seconds = 0.0
		boost_maxed_changed.emit(false)
		if _overdrive:
			_overdrive = false
			remove_speed_modifier(&"overdrive")
			overdrive_changed.emit(false)
		return
	if _boost_maxed:
		_boost_maxed_seconds += delta
		if not _overdrive and _boost_maxed_seconds >= _config.overdrive_hold_seconds:
			_overdrive = true
			set_speed_modifier(&"overdrive", _config.overdrive_multiplier)
			overdrive_changed.emit(true)


func _emit_speed_if_changed(previous_speed: float) -> void:
	var speed := get_effective_spin_speed_rad_s()
	if speed != previous_speed:
		spin_speed_changed.emit(speed)


# --- Clicking ---------------------------------------------------------------------

## Damage one enemy click deals: base plus every Click Damage level.
func get_click_damage() -> float:
	return _config.base_click_damage + _click_damage_bonus


## Extra damage per Wolf hit from Wolf Fang levels (added to MountData.base_damage).
func get_wolf_damage_bonus() -> float:
	return _wolf_damage_bonus


# --- Ticket booths ------------------------------------------------------------------

func get_booth_count() -> int:
	return _booth_count


# --- Mounts ----------------------------------------------------------------------

## Mount ids in placement order (a copy).
func get_mount_roster() -> Array[StringName]:
	return _mount_roster.duplicate()


func get_mount_slots() -> int:
	return _mount_slots


func has_free_mount_slot() -> bool:
	return _mount_roster.size() < _mount_slots


## True if one of this mount can be sold back right now: it's sellable and at
## least one was bought (starting mounts don't count, so they can't be sold).
func can_sell_mount(upgrade: UpgradeData) -> bool:
	return (upgrade != null
			and upgrade.effect_type == UpgradeData.EffectType.BUY_MOUNT
			and upgrade.sell_refund_fraction > 0.0
			and get_upgrade_level(upgrade.id) > 0)


## Refund for selling one: sell_refund_fraction of what the last one cost.
func get_sell_refund(upgrade: UpgradeData) -> float:
	if not can_sell_mount(upgrade):
		return 0.0
	return roundf(upgrade.get_cost_for_level(get_upgrade_level(upgrade.id) - 1) * upgrade.sell_refund_fraction)


## Sells the most recently placed one of this mount. The refund isn't income,
## so it doesn't count toward Gold/sec. The level drops, so rebuying costs the
## same as before.
func try_sell_mount(upgrade: UpgradeData) -> bool:
	if _purchase_in_progress or not can_sell_mount(upgrade):
		return false
	var index := _mount_roster.rfind(upgrade.id)
	if index < 0:
		return false
	var refund := get_sell_refund(upgrade)
	_upgrade_levels[upgrade.id] = get_upgrade_level(upgrade.id) - 1
	_mount_roster.remove_at(index)
	_gold += refund
	gold_changed.emit(_gold, refund)
	mounts_changed.emit(get_mount_roster())
	upgrade_sold.emit(upgrade.id, get_upgrade_level(upgrade.id))
	return true


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
	if upgrade.effect_type == UpgradeData.EffectType.BUY_MOUNT and not has_free_mount_slot():
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
	var previous_slots := _mount_slots
	var previous_mount_count := _mount_roster.size()
	_gold -= cost
	_upgrade_levels[upgrade.id] = get_upgrade_level(upgrade.id) + 1
	match upgrade.effect_type:
		UpgradeData.EffectType.ADD_SPIN_BONUS:
			_spin_bonus += upgrade.effect_value
		UpgradeData.EffectType.ADD_BOOST_CAP:
			_boost_cap_bonus += upgrade.effect_value
		UpgradeData.EffectType.ADD_TICKET_BOOTH:
			_booth_count += 1
		UpgradeData.EffectType.ADD_CLICK_DAMAGE:
			_click_damage_bonus += upgrade.effect_value
		UpgradeData.EffectType.ADD_MOUNT_SLOT:
			_mount_slots += 1
		UpgradeData.EffectType.BUY_MOUNT:
			_mount_roster.append(upgrade.id)
		UpgradeData.EffectType.ADD_WOLF_DAMAGE:
			_wolf_damage_bonus += upgrade.effect_value
	# Everything is committed; now announce it.
	gold_changed.emit(_gold, -cost)
	_emit_speed_if_changed(previous_speed)
	if _booth_count != previous_booths:
		booth_count_changed.emit(_booth_count)
	if _mount_slots != previous_slots:
		mount_slots_changed.emit(_mount_slots)
	if _mount_roster.size() != previous_mount_count:
		mounts_changed.emit(get_mount_roster())
	upgrade_applied.emit(upgrade.id, get_upgrade_level(upgrade.id))
	_purchase_in_progress = false
	return true


func _is_effect_supported(upgrade: UpgradeData) -> bool:
	return upgrade.effect_type in [
		UpgradeData.EffectType.ADD_SPIN_BONUS,
		UpgradeData.EffectType.ADD_BOOST_CAP,
		UpgradeData.EffectType.ADD_TICKET_BOOTH,
		UpgradeData.EffectType.ADD_CLICK_DAMAGE,
		UpgradeData.EffectType.ADD_MOUNT_SLOT,
		UpgradeData.EffectType.BUY_MOUNT,
		UpgradeData.EffectType.ADD_WOLF_DAMAGE,
	]
