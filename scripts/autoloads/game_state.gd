extends Node
## Single source of truth for runtime run data.
## Read values through the getters; change them only through these functions.
## Balance numbers live in RunConfig (res://resources/config/run_config.tres).

signal gold_changed(balance: float, delta: float)
signal health_changed(current: float, maximum: float)
## Emitted after every value has been reset, before the fresh values are re-announced.
signal run_reset

const DEFAULT_CONFIG: RunConfig = preload("res://resources/config/run_config.tres")

var _config: RunConfig = DEFAULT_CONFIG
var _gold: float = 0.0
var _health: float = 0.0


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
	# Set everything first so listeners never see a half-reset run.
	run_reset.emit()
	gold_changed.emit(_gold, 0.0)
	health_changed.emit(_health, get_max_health())


# --- Gold -------------------------------------------------------------------

func get_gold() -> float:
	return _gold


## Adds earned Gold. Ignores zero, negative, and non-finite amounts.
func add_gold(amount: float) -> void:
	if not is_finite(amount) or amount <= 0.0:
		return
	_gold += amount
	gold_changed.emit(_gold, amount)


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
