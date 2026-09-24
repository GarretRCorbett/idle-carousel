extends GdUnitTestSuite
## Emergency Clear: price from normal income, cooldown, and what it clears.

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.base_spin_speed_deg_s = 45.0
	_config.emergency_clear_income_seconds = 20.0
	_config.emergency_clear_min_cost = 25.0
	_config.emergency_clear_cooldown_seconds = 60.0
	_config.latch_grace_seconds = 0.0
	_config.regen_per_second = 0.0
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


func test_price_has_a_floor() -> void:
	# 1 Horse, 1 booth, 5 Gold/pass, 1/8 turn/s = 0.625/s; 20 s = 12.5 -> floor 25.
	assert_float(GameState.get_normal_booth_income_per_second()).is_equal_approx(0.625, 0.0001)
	assert_float(GameState.get_emergency_clear_cost()).is_equal(25.0)


func test_drag_does_not_make_it_cheaper() -> void:
	_config.emergency_clear_min_cost = 0.0
	GameState.reset_run(_config)
	var price := GameState.get_emergency_clear_cost()
	for i in 10:
		GameState.register_latch(i, 0.2, 0.0)
	assert_float(GameState.get_emergency_clear_cost()).is_equal(price)


func test_needs_something_latched_and_the_gold() -> void:
	GameState.add_gold(100.0)
	assert_bool(GameState.try_emergency_clear()).is_false()
	GameState.register_latch(1, 0.05, 0.0)
	GameState.spend_gold(90.0)
	assert_bool(GameState.try_emergency_clear()).is_false()
	GameState.add_gold(20.0)
	assert_bool(GameState.try_emergency_clear()).is_true()
	assert_float(GameState.get_gold()).is_equal(5.0)
	assert_int(GameState.get_latched_count()).is_equal(0)


func test_cooldown_blocks_reuse() -> void:
	GameState.add_gold(1000.0)
	GameState.register_latch(1, 0.05, 0.0)
	GameState.try_emergency_clear()
	GameState.register_latch(2, 0.05, 0.0)
	assert_bool(GameState.try_emergency_clear()).is_false()
	GameState.advance_simulation(59.0)
	assert_bool(GameState.can_emergency_clear()).is_false()
	GameState.advance_simulation(1.0)
	assert_bool(GameState.try_emergency_clear()).is_true()


func test_clearing_ends_a_stall() -> void:
	GameState.add_gold(1000.0)
	GameState.register_latch(1, 0.05, 500.0)
	GameState.advance_simulation(1.0)
	assert_bool(GameState.is_stalled()).is_true()
	assert_bool(GameState.try_emergency_clear()).is_true()
	assert_bool(GameState.is_stalled()).is_false()
	assert_float(GameState.get_health()).is_greater(0.0)
