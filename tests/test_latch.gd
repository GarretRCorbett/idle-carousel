extends GdUnitTestSuite
## Latches: drag stacks and unstacks, latched damage, and both TEMPORARY fail rules.

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.base_spin_speed_deg_s = 90.0
	_config.max_health = 100.0
	_config.fail_rule = RunConfig.FailRule.HEALTH_STALL
	_config.stall_recovery_fraction = 0.25
	_config.overload_speed_floor = 0.25
	_config.overload_seconds = 10.0
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


func _base_speed() -> float:
	return deg_to_rad(90.0)


func _use_overload_rule() -> void:
	_config.fail_rule = RunConfig.FailRule.OVERLOAD_CLEAR
	GameState.reset_run(_config)


# --- Drag ---------------------------------------------------------------------------

func test_two_latches_stack_drag() -> void:
	GameState.register_latch(1, 0.05, 1.0)
	GameState.register_latch(2, 0.05, 1.0)
	assert_int(GameState.get_latched_count()).is_equal(2)
	assert_float(GameState.get_total_drag()).is_equal_approx(0.10, 0.00001)
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal_approx(_base_speed() * 0.9, 0.00001)


func test_removing_one_latch_removes_exactly_its_share() -> void:
	GameState.register_latch(1, 0.05, 1.0)
	GameState.register_latch(2, 0.2, 1.0)
	GameState.unregister_latch(2)
	assert_float(GameState.get_total_drag()).is_equal_approx(0.05, 0.00001)
	assert_float(GameState.get_total_latch_dps()).is_equal_approx(1.0, 0.00001)


func test_registering_twice_fails_and_removing_twice_is_safe() -> void:
	assert_bool(GameState.register_latch(1, 0.05, 1.0)).is_true()
	assert_bool(GameState.register_latch(1, 0.05, 1.0)).is_false()
	assert_float(GameState.get_total_drag()).is_equal_approx(0.05, 0.00001)
	assert_bool(GameState.unregister_latch(1)).is_true()
	assert_bool(GameState.unregister_latch(1)).is_false()
	assert_float(GameState.get_total_drag()).is_equal(0.0)


func test_drag_has_no_floor_under_health_stall() -> void:
	for i in 25:
		GameState.register_latch(i, 0.05, 0.0)
	assert_float(GameState.get_total_drag()).is_equal_approx(1.25, 0.00001)  # unclamped
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal(0.0)


func test_latching_signals_the_new_count() -> void:
	var counts: Array[int] = []
	GameState.latch_count_changed.connect(func(c: int) -> void: counts.append(c))
	GameState.register_latch(1, 0.05, 1.0)
	GameState.unregister_latch(1)
	assert_array(counts).is_equal([1, 0])


# --- HEALTH_STALL ------------------------------------------------------------------

func test_latched_damage_lowers_health_over_time() -> void:
	GameState.register_latch(1, 0.05, 1.0)
	GameState.register_latch(2, 0.05, 1.0)
	GameState.advance_simulation(5.0)
	assert_float(GameState.get_health()).is_equal_approx(90.0, 0.00001)


func test_zero_health_stalls_even_with_boost() -> void:
	GameState.register_latch(1, 0.05, 50.0)
	GameState.advance_simulation(2.0)
	assert_bool(GameState.is_stalled()).is_true()
	GameState.add_click_boost()
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal(0.0)


func test_stall_lasts_until_the_last_latch_clears() -> void:
	GameState.register_latch(1, 0.05, 50.0)
	GameState.register_latch(2, 0.05, 50.0)
	GameState.advance_simulation(1.0)
	assert_bool(GameState.is_stalled()).is_true()
	GameState.unregister_latch(1)
	assert_bool(GameState.is_stalled()).is_true()
	assert_float(GameState.get_health()).is_equal(0.0)
	GameState.unregister_latch(2)
	assert_bool(GameState.is_stalled()).is_false()
	assert_float(GameState.get_health()).is_equal_approx(25.0, 0.00001)
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal_approx(_base_speed(), 0.00001)


func test_zero_health_with_nothing_latched_refills_right_away() -> void:
	GameState.damage_carousel(1000.0)
	assert_bool(GameState.is_stalled()).is_false()
	assert_float(GameState.get_health()).is_equal_approx(25.0, 0.00001)


func test_stall_signals_on_and_off() -> void:
	var flips: Array[bool] = []
	GameState.stall_changed.connect(func(s: bool) -> void: flips.append(s))
	GameState.register_latch(1, 0.05, 200.0)
	GameState.advance_simulation(1.0)
	GameState.unregister_latch(1)
	assert_array(flips).is_equal([true, false])


func test_a_drag_stop_is_not_a_stall() -> void:
	for i in 20:
		GameState.register_latch(i, 0.05, 0.0)
	GameState.advance_simulation(1.0)
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal(0.0)
	assert_bool(GameState.is_stalled()).is_false()
	assert_float(GameState.get_health()).is_equal(100.0)


# --- OVERLOAD_CLEAR ----------------------------------------------------------------

func test_overload_rule_has_no_health_drain() -> void:
	_use_overload_rule()
	GameState.register_latch(1, 0.05, 50.0)
	GameState.advance_simulation(5.0)
	assert_float(GameState.get_health()).is_equal(100.0)


func test_overload_rule_drag_stops_at_the_floor() -> void:
	_use_overload_rule()
	for i in 30:
		GameState.register_latch(i, 0.05, 0.0)
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal_approx(_base_speed() * 0.25, 0.00001)


func test_overload_clears_latches_after_time_at_the_floor() -> void:
	_use_overload_rule()
	var fired := [0]
	GameState.overloaded.connect(func() -> void: fired[0] += 1)
	for i in 16:  # 0.80 drag: at the 0.25 floor
		GameState.register_latch(i, 0.05, 0.0)
	GameState.advance_simulation(9.0)
	assert_int(fired[0]).is_equal(0)
	GameState.advance_simulation(1.0)
	assert_int(fired[0]).is_equal(1)
	assert_int(GameState.get_latched_count()).is_equal(0)
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal_approx(_base_speed(), 0.00001)


func test_overload_timer_resets_when_above_the_floor() -> void:
	_use_overload_rule()
	var fired := [0]
	GameState.overloaded.connect(func() -> void: fired[0] += 1)
	for i in 16:
		GameState.register_latch(i, 0.05, 0.0)
	GameState.advance_simulation(9.0)
	GameState.unregister_latch(0)  # 0.75 drag: exactly at the floor, still stuck
	GameState.unregister_latch(1)  # 0.70 drag: above the floor, timer resets
	GameState.advance_simulation(0.1)
	GameState.register_latch(100, 0.05, 0.0)
	GameState.register_latch(101, 0.05, 0.0)
	GameState.advance_simulation(9.0)
	assert_int(fired[0]).is_equal(0)
