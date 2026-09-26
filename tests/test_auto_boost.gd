extends GdUnitTestSuite
## Auto-Boost (GDD v1.17): refills the bar toward its level's hold at a steady
## pace; keeps Overdrive going at the top level, never starts it; latches that
## drain faster than its spare refill still end Overdrive.

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.click_boost_cap = 0.5
	_config.boost_presses_to_fill = 10
	_config.click_boost_decay_seconds = 4.0
	_config.boost_maxed_on_fraction = 0.99
	_config.boost_maxed_off_fraction = 0.8
	_config.overdrive_hold_seconds = 5.0
	_config.auto_boost_holds = PackedFloat32Array([0.3, 0.5, 0.65, 0.82])
	_config.auto_boost_refill_per_second = 0.3
	_config.boost_drain_per_latch = 0.05
	_config.boost_drain_max = 0.3
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


func _auto_boost(levels: int) -> void:
	var upgrade := UpgradeData.new()
	upgrade.id = &"test_auto_boost"
	upgrade.effect_type = UpgradeData.EffectType.AUTO_BOOST
	upgrade.max_level = 4
	for i in levels:
		assert_bool(GameState.try_purchase_upgrade(upgrade)).is_true()


func _run(seconds: float) -> void:
	for t in roundi(seconds * 60.0):
		GameState.advance_simulation(1.0 / 60.0)


func _press_for(seconds: float) -> void:
	for t in roundi(seconds * 60.0):
		if t % 20 == 0:
			GameState.add_click_boost()
		GameState.advance_simulation(1.0 / 60.0)


func test_nothing_without_the_upgrade() -> void:
	_run(2.0)
	assert_float(GameState.get_click_boost_fraction()).is_equal(0.0)
	assert_float(GameState.get_auto_boost_hold()).is_equal(0.0)


func test_fills_at_a_steady_pace_and_holds_its_level() -> void:
	_auto_boost(1)
	_run(0.5)
	assert_float(GameState.get_click_boost_fraction()).is_equal_approx(0.15, 0.01)
	_run(5.0)
	assert_float(GameState.get_click_boost_fraction()).is_equal_approx(0.3, 0.001)


func test_each_level_holds_higher() -> void:
	_auto_boost(2)
	_run(5.0)
	assert_float(GameState.get_click_boost_fraction()).is_equal_approx(0.5, 0.001)


func test_never_lowers_a_bar_above_its_hold() -> void:
	_auto_boost(1)
	_press_for(1.0)  # well above 30%
	var fraction := GameState.get_click_boost_fraction()
	GameState.advance_simulation(1.0 / 60.0)
	assert_float(GameState.get_click_boost_fraction()).is_greater(0.3)
	assert_float(GameState.get_click_boost_fraction()).is_less_equal(fraction)


func test_top_level_alone_never_starts_overdrive() -> void:
	_auto_boost(4)
	_run(20.0)
	assert_float(GameState.get_click_boost_fraction()).is_equal_approx(0.82, 0.001)
	assert_bool(GameState.is_boost_maxed()).is_false()
	assert_bool(GameState.is_overdrive_active()).is_false()


func test_top_level_keeps_overdrive_going_once_started() -> void:
	_auto_boost(4)
	for i in 10:
		GameState.add_click_boost()
	_press_for(5.1)
	assert_bool(GameState.is_overdrive_active()).is_true()
	_run(20.0)  # hands off
	assert_bool(GameState.is_overdrive_active()).is_true()


func test_one_latch_cant_beat_it_but_a_few_end_overdrive() -> void:
	_auto_boost(4)
	for i in 10:
		GameState.add_click_boost()
	_press_for(5.1)
	GameState.register_latch(1, 0.0, 0.0)
	_run(10.0)
	assert_bool(GameState.is_overdrive_active()).override_failure_message("one latch").is_true()
	GameState.register_latch(2, 0.0, 0.0)
	GameState.register_latch(3, 0.0, 0.0)
	_run(3.0)
	assert_bool(GameState.is_overdrive_active()).override_failure_message("three latches").is_false()


func test_it_doesnt_crank_a_stall() -> void:
	_auto_boost(4)
	GameState.register_latch(1, 0.0, 1000.0)
	_run(3.0)  # grace, then the latch empties health
	assert_bool(GameState.is_stalled()).is_true()
	_run(1.0)
	assert_float(GameState.get_crank_fraction()).is_equal(0.0)
