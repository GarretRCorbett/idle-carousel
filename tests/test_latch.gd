extends GdUnitTestSuite
## Latches and carousel health: drag curve, latch damage and grace, regen,
## and the TEMPORARY stall (clear, crank, timeout).

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.base_spin_speed_deg_s = 90.0
	_config.max_health = 100.0
	_config.latch_grace_seconds = 0.0
	_config.regen_per_second = 0.0
	_config.regen_delay_seconds = 2.0
	_config.stall_recovery_fraction = 0.25
	_config.crank_presses = 10
	_config.crank_hold_seconds = 4.0
	_config.crank_restart_fraction = 0.15
	_config.crank_protection_seconds = 3.0
	_config.stall_timeout_seconds = 60.0
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


func _base_speed() -> float:
	return deg_to_rad(90.0)


func _reset_with(changes: Callable) -> void:
	changes.call()
	GameState.reset_run(_config)


## Latches one enemy with enough damage to stall a 100-health carousel in 1 s.
func _stall() -> void:
	GameState.register_latch(1, 0.05, 200.0)
	GameState.advance_simulation(1.0)
	assert_bool(GameState.is_stalled()).is_true()


# --- Drag -----------------------------------------------------------------------------

func test_drag_softens_as_it_stacks() -> void:
	GameState.register_latch(1, 0.05, 0.0)
	GameState.register_latch(2, 0.05, 0.0)
	assert_float(GameState.get_total_drag()).is_equal_approx(0.10, 0.00001)
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal_approx(_base_speed() / 1.1, 0.00001)


func test_heavy_drag_never_stops_it_and_boost_still_helps() -> void:
	for i in 25:
		GameState.register_latch(i, 0.05, 0.0)
	var slowed := GameState.get_effective_spin_speed_rad_s()
	assert_float(slowed).is_equal_approx(_base_speed() / 2.25, 0.00001)
	GameState.add_click_boost()
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_greater(slowed)


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


func test_latching_signals_the_new_count() -> void:
	var counts: Array[int] = []
	GameState.latch_count_changed.connect(func(c: int) -> void: counts.append(c))
	GameState.register_latch(1, 0.05, 1.0)
	GameState.unregister_latch(1)
	assert_array(counts).is_equal([1, 0])


# --- Latch damage, grace, regen -------------------------------------------------------

func test_latched_damage_lowers_health_over_time() -> void:
	GameState.register_latch(1, 0.05, 1.0)
	GameState.register_latch(2, 0.05, 1.0)
	GameState.advance_simulation(5.0)
	assert_float(GameState.get_health()).is_equal_approx(90.0, 0.00001)


func test_grace_delays_damage_but_not_drag() -> void:
	_reset_with(func() -> void: _config.latch_grace_seconds = 2.0)
	GameState.register_latch(1, 0.5, 10.0)
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_less(_base_speed())
	GameState.advance_simulation(1.5)
	assert_float(GameState.get_health()).is_equal(100.0)
	GameState.advance_simulation(1.0)  # 0.5 s past the grace
	assert_float(GameState.get_health()).is_equal_approx(95.0, 0.00001)


func test_grace_is_the_same_in_small_ticks() -> void:
	_reset_with(func() -> void: _config.latch_grace_seconds = 2.0)
	GameState.register_latch(1, 0.0, 10.0)
	for i in 150:
		GameState.advance_simulation(1.0 / 60.0)  # 2.5 s
	assert_float(GameState.get_health()).is_equal_approx(95.0, 0.001)


func test_regen_starts_after_the_rim_is_clear_for_the_delay() -> void:
	_reset_with(func() -> void: _config.regen_per_second = 2.0)
	GameState.damage_carousel(50.0)
	GameState.advance_simulation(1.9)
	assert_float(GameState.get_health()).is_equal(50.0)
	GameState.advance_simulation(0.1)  # reaches the 2 s delay this tick
	GameState.advance_simulation(1.0)
	assert_float(GameState.get_health()).is_between(51.9, 52.3)


func test_no_regen_while_anything_is_latched() -> void:
	_reset_with(func() -> void: _config.regen_per_second = 2.0)
	GameState.damage_carousel(50.0)
	GameState.register_latch(1, 0.05, 0.0)
	GameState.advance_simulation(10.0)
	assert_float(GameState.get_health()).is_equal(50.0)


func test_regen_never_passes_max() -> void:
	_reset_with(func() -> void: _config.regen_per_second = 50.0)
	GameState.damage_carousel(1.0)
	GameState.advance_simulation(3.0)
	GameState.advance_simulation(3.0)
	assert_float(GameState.get_health()).is_equal(100.0)


# --- TEMPORARY stall: clearing ----------------------------------------------------------

func test_zero_health_stalls_and_boost_cannot_move_it() -> void:
	_stall()
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
	_stall()
	GameState.unregister_latch(1)
	assert_array(flips).is_equal([true, false])


# --- TEMPORARY stall: crank -------------------------------------------------------------

func test_presses_crank_instead_of_boosting() -> void:
	_stall()
	for i in 9:
		GameState.add_click_boost()
	assert_bool(GameState.is_stalled()).is_true()
	assert_float(GameState.get_crank_fraction()).is_equal_approx(0.9, 0.00001)
	assert_float(GameState.get_click_boost()).is_equal(0.0)
	GameState.add_click_boost()
	assert_bool(GameState.is_stalled()).is_false()


func test_crank_restart_keeps_latches_at_low_health() -> void:
	_stall()
	for i in 10:
		GameState.add_click_boost()
	assert_int(GameState.get_latched_count()).is_equal(1)
	assert_float(GameState.get_health()).is_equal_approx(15.0, 0.00001)
	assert_float(GameState.get_crank_fraction()).is_equal(0.0)
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_greater(0.0)


func test_holding_boost_cranks_over_time() -> void:
	_stall()
	GameState.set_boost_held(true)
	GameState.advance_simulation(2.0)
	assert_float(GameState.get_crank_fraction()).is_equal_approx(0.5, 0.00001)
	GameState.advance_simulation(2.0)
	assert_bool(GameState.is_stalled()).is_false()


func test_crank_restart_has_a_short_damage_break() -> void:
	_stall()
	for i in 10:
		GameState.add_click_boost()
	GameState.advance_simulation(2.0)
	assert_float(GameState.get_health()).is_equal_approx(15.0, 0.00001)
	GameState.advance_simulation(1.0)  # protection runs out this tick
	assert_float(GameState.get_health()).is_equal_approx(15.0, 0.00001)
	GameState.advance_simulation(0.05)
	assert_float(GameState.get_health()).is_less(15.0)


func test_crank_resets_after_a_stall_ends() -> void:
	_stall()
	GameState.add_click_boost()
	GameState.unregister_latch(1)
	GameState.register_latch(2, 0.05, 200.0)
	GameState.advance_simulation(1.0)
	assert_bool(GameState.is_stalled()).is_true()
	assert_float(GameState.get_crank_fraction()).is_equal(0.0)


# --- TEMPORARY stall: safety-net timeout ----------------------------------------------

func test_long_stall_times_out_clears_latches_and_restarts() -> void:
	var timeouts := [0]
	GameState.stall_timed_out.connect(func() -> void: timeouts[0] += 1)
	_stall()
	GameState.advance_simulation(58.0)
	assert_int(timeouts[0]).is_equal(0)
	GameState.advance_simulation(2.0)
	assert_int(timeouts[0]).is_equal(1)
	assert_bool(GameState.is_stalled()).is_false()
	assert_int(GameState.get_latched_count()).is_equal(0)
	assert_float(GameState.get_health()).is_equal_approx(25.0, 0.00001)


## Totals are kept as a running sum (hundreds of Leaves can latch at once);
## they must match a fresh sum and end at exactly zero.
func test_running_latch_totals_match_and_end_at_zero() -> void:
	for i in 200:
		GameState.register_latch(i, 0.01 * (i % 7 + 1), 0.1 * (i % 3 + 1))
	for i in range(0, 200, 2):
		GameState.unregister_latch(i)
	var drag := 0.0
	var dps := 0.0
	for i in range(1, 200, 2):
		drag += 0.01 * (i % 7 + 1)
		dps += 0.1 * (i % 3 + 1)
	assert_float(GameState.get_total_drag()).is_equal_approx(drag, 0.000001)
	assert_float(GameState.get_total_latch_dps()).is_equal_approx(dps, 0.000001)
	for i in range(1, 200, 2):
		GameState.unregister_latch(i)
	assert_float(GameState.get_total_drag()).is_equal(0.0)
	assert_float(GameState.get_total_latch_dps()).is_equal(0.0)
