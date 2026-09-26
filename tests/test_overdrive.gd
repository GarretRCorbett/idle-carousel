extends GdUnitTestSuite
## Holding the boost maxed triggers Overdrive (×2 speed) until the boost drops.

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.base_spin_speed_deg_s = 90.0
	_config.click_boost_cap = 0.5
	_config.boost_presses_to_fill = 10
	_config.click_boost_decay_seconds = 4.0
	_config.boost_maxed_on_fraction = 0.99
	_config.boost_maxed_off_fraction = 0.8
	_config.overdrive_hold_seconds = 5.0
	_config.overdrive_multiplier = 2.0
	_config.boost_drain_per_latch = 0.05
	_config.boost_drain_max = 0.2
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


func _fill_bar() -> void:
	for i in _config.boost_presses_to_fill:
		GameState.add_click_boost()


## Hold the bar maxed for `seconds`, pressing 3 times a second at 60 ticks/s.
func _hold(seconds: float) -> void:
	var ticks := roundi(seconds * 60.0)
	for t in ticks:
		if t % 20 == 0:
			GameState.add_click_boost()
		GameState.advance_simulation(1.0 / 60.0)


func test_filling_the_bar_marks_it_maxed() -> void:
	assert_bool(GameState.is_boost_maxed()).is_false()
	_fill_bar()
	assert_bool(GameState.is_boost_maxed()).is_true()
	assert_bool(GameState.is_overdrive_active()).is_false()


func test_dips_between_presses_keep_it_maxed() -> void:
	_fill_bar()
	GameState.advance_simulation(0.5)  # 1.0 -> 0.875, still above 0.8
	assert_bool(GameState.is_boost_maxed()).is_true()


func test_overdrive_starts_after_holding_long_enough() -> void:
	_fill_bar()
	_hold(4.9)
	assert_bool(GameState.is_overdrive_active()).is_false()
	_hold(0.2)
	assert_bool(GameState.is_overdrive_active()).is_true()


func test_overdrive_doubles_speed() -> void:
	_fill_bar()
	var before := GameState.get_effective_spin_speed_rad_s() / (1.0 + GameState.get_click_boost())
	_hold(5.1)
	var after := GameState.get_effective_spin_speed_rad_s() / (1.0 + GameState.get_click_boost())
	assert_float(after / before).is_equal_approx(2.0, 0.00001)


func test_overdrive_ends_when_the_boost_drops() -> void:
	_fill_bar()
	_hold(5.1)
	assert_bool(GameState.is_overdrive_active()).is_true()
	GameState.advance_simulation(1.0)  # no presses: 1.0 -> ~0.75, below 0.8
	assert_bool(GameState.is_boost_maxed()).is_false()
	assert_bool(GameState.is_overdrive_active()).is_false()
	assert_float(GameState.get_speed_modifier_multiplier()).is_equal(1.0)


func test_dropping_restarts_the_hold_timer() -> void:
	_fill_bar()
	_hold(4.0)
	GameState.advance_simulation(1.0)  # drop out
	_fill_bar()
	_hold(4.0)
	assert_bool(GameState.is_overdrive_active()).is_false()


func test_signals_fire_once_each_way() -> void:
	var events: Array = []
	GameState.overdrive_changed.connect(func(active: bool) -> void: events.append(active))
	_fill_bar()
	_hold(6.0)
	GameState.advance_simulation(2.0)
	assert_array(events).is_equal([true, false])


func test_speed_modifiers_multiply() -> void:
	var base := GameState.get_effective_spin_speed_rad_s()
	GameState.set_speed_modifier(&"event_a", 2.0)
	GameState.set_speed_modifier(&"event_b", 1.5)
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal_approx(base * 3.0, 0.00001)
	GameState.remove_speed_modifier(&"event_a")
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal_approx(base * 1.5, 0.00001)


func test_reset_clears_overdrive_and_modifiers() -> void:
	_fill_bar()
	_hold(5.1)
	GameState.set_speed_modifier(&"event", 3.0)
	GameState.reset_run(_config)
	assert_bool(GameState.is_overdrive_active()).is_false()
	assert_bool(GameState.is_boost_maxed()).is_false()
	assert_float(GameState.get_speed_modifier_multiplier()).is_equal(1.0)


func _boost_power(value: float) -> UpgradeData:
	var upgrade := UpgradeData.new()
	upgrade.id = &"test_boost_power"
	upgrade.effect_type = UpgradeData.EffectType.ADD_BOOST_CAP
	upgrade.effect_value = value
	upgrade.max_level = 5
	return upgrade


## Playtest 3 bug: a bigger cap made the same boost read below 80% and ended Overdrive.
func test_buying_boost_power_keeps_overdrive_and_the_fill_fraction() -> void:
	_fill_bar()
	_hold(5.1)
	var fraction := GameState.get_click_boost_fraction()
	assert_bool(GameState.try_purchase_upgrade(_boost_power(0.5))).is_true()  # cap 0.5 -> 1.0
	assert_float(GameState.get_click_boost_fraction()).is_equal_approx(fraction, 0.00001)
	assert_float(GameState.get_boost_cap()).is_equal_approx(1.0, 0.00001)
	GameState.advance_simulation(1.0 / 60.0)
	assert_bool(GameState.is_boost_maxed()).is_true()
	assert_bool(GameState.is_overdrive_active()).is_true()


func test_boost_power_on_an_empty_bar_stays_empty() -> void:
	GameState.try_purchase_upgrade(_boost_power(0.5))
	assert_float(GameState.get_click_boost()).is_equal(0.0)


## Fill the bar, then let `seconds` pass with `latches` enemies latched.
func _fraction_after(latches: int, seconds: float) -> float:
	GameState.reset_run(_config)
	for i in latches:
		GameState.register_latch(1000 + i, 0.0, 0.0)
	_fill_bar()
	GameState.advance_simulation(seconds)
	return GameState.get_click_boost_fraction()


func test_one_latch_drains_the_bar_gently() -> void:
	# The fade alone: 1.0 -> 0.75 in 1 s. One latch takes another 0.05.
	assert_float(_fraction_after(0, 1.0)).is_equal_approx(0.75, 0.00001)
	assert_float(_fraction_after(1, 1.0)).is_equal_approx(0.70, 0.00001)


func test_more_latches_drain_faster_up_to_the_max() -> void:
	assert_float(_fraction_after(3, 1.0)).is_equal_approx(0.60, 0.00001)
	# 10 latches would be 0.5/s; the max holds it to 0.2/s.
	assert_float(_fraction_after(10, 1.0)).is_equal_approx(0.55, 0.00001)


func test_drain_never_goes_below_empty() -> void:
	var fraction := _fraction_after(10, 3.5)
	assert_float(fraction).is_greater_equal(0.0)
	assert_float(fraction).is_less(0.2)


func test_latches_push_you_out_of_overdrive_over_time() -> void:
	_fill_bar()
	_hold(5.1)
	GameState.register_latch(1, 0.0, 0.0)
	GameState.register_latch(2, 0.0, 0.0)
	GameState.register_latch(3, 0.0, 0.0)
	GameState.register_latch(4, 0.0, 0.0)
	GameState.advance_simulation(1.0 / 60.0)
	assert_bool(GameState.is_overdrive_active()).override_failure_message(
			"a latch must not end Overdrive instantly").is_true()
	_hold(3.0)  # 3 presses a second can't keep up with the fade plus 0.2/s
	assert_bool(GameState.is_overdrive_active()).is_false()
