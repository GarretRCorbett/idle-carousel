extends GdUnitTestSuite
## GameState: Gold, health, and reset. Every test starts from a known config.

var _config: RunConfig
var _gold_events: Array = []
var _health_events: Array = []


func before_test() -> void:
	_config = RunConfig.new()
	_config.starting_gold = 0.0
	_config.max_health = 100.0
	GameState.reset_run(_config)
	_gold_events.clear()
	_health_events.clear()
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.health_changed.connect(_on_health_changed)


func after_test() -> void:
	GameState.gold_changed.disconnect(_on_gold_changed)
	GameState.health_changed.disconnect(_on_health_changed)
	GameState.reset_run()


func _on_gold_changed(balance: float, delta: float) -> void:
	_gold_events.append([balance, delta])


func _on_health_changed(current: float, maximum: float) -> void:
	_health_events.append([current, maximum])


func test_add_gold() -> void:
	GameState.add_gold(10.0)
	assert_float(GameState.get_gold()).is_equal(10.0)
	assert_array(_gold_events).is_equal([[10.0, 10.0]])


func test_add_gold_ignores_zero_negative_and_nan() -> void:
	GameState.add_gold(0.0)
	GameState.add_gold(-5.0)
	GameState.add_gold(NAN)
	GameState.add_gold(INF)
	assert_float(GameState.get_gold()).is_equal(0.0)
	assert_array(_gold_events).is_empty()


func test_spend_gold_success() -> void:
	GameState.add_gold(10.0)
	_gold_events.clear()
	assert_bool(GameState.spend_gold(8.0)).is_true()
	assert_float(GameState.get_gold()).is_equal(2.0)
	assert_array(_gold_events).is_equal([[2.0, -8.0]])


func test_spend_gold_cannot_afford_changes_nothing() -> void:
	GameState.add_gold(2.0)
	_gold_events.clear()
	assert_bool(GameState.spend_gold(3.0)).is_false()
	assert_float(GameState.get_gold()).is_equal(2.0)
	assert_array(_gold_events).is_empty()


func test_spend_exact_balance() -> void:
	GameState.add_gold(5.0)
	assert_bool(GameState.can_afford(5.0)).is_true()
	assert_bool(GameState.spend_gold(5.0)).is_true()
	assert_float(GameState.get_gold()).is_equal(0.0)


func test_spend_rejects_negative_and_nan() -> void:
	GameState.add_gold(5.0)
	assert_bool(GameState.spend_gold(-1.0)).is_false()
	assert_bool(GameState.spend_gold(NAN)).is_false()
	assert_float(GameState.get_gold()).is_equal(5.0)


## Uses the no-stall rule: under HEALTH_STALL, 0 health with nothing latched
## refills right away (covered in test_latch.gd).
func test_damage_clamps_at_zero() -> void:
	_config.fail_rule = RunConfig.FailRule.OVERLOAD_CLEAR
	GameState.reset_run(_config)
	_health_events.clear()
	GameState.damage_carousel(30.0)
	assert_float(GameState.get_health()).is_equal(70.0)
	GameState.damage_carousel(150.0)
	assert_float(GameState.get_health()).is_equal(0.0)
	assert_array(_health_events).is_equal([[70.0, 100.0], [0.0, 100.0]])
	GameState.damage_carousel(10.0)  # already at zero: no new event
	assert_int(_health_events.size()).is_equal(2)


func test_reset_restores_config_before_announcing() -> void:
	var seen: Array = []
	var check := func() -> void: seen.append([GameState.get_gold(), GameState.get_health()])
	GameState.run_reset.connect(check)
	GameState.add_gold(50.0)
	GameState.damage_carousel(40.0)
	var other := RunConfig.new()
	other.starting_gold = 25.0
	other.max_health = 80.0
	GameState.reset_run(other)
	GameState.run_reset.disconnect(check)
	# The run_reset listener already saw the fully reset values.
	assert_array(seen).is_equal([[25.0, 80.0]])
	assert_float(GameState.get_max_health()).is_equal(80.0)


func test_invalid_config_falls_back_to_defaults() -> void:
	var bad := RunConfig.new()
	bad.max_health = -5.0
	assert_bool(bad.get_problems().is_empty()).is_false()
	GameState.reset_run(bad)
	assert_float(GameState.get_max_health()).is_equal(GameState.DEFAULT_CONFIG.max_health)


func test_production_config_is_valid() -> void:
	var config := load("res://resources/config/run_config.tres") as RunConfig
	assert_object(config).is_not_null()
	assert_array(config.get_problems()).is_empty()
