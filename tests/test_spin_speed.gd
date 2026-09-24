extends GdUnitTestSuite
## Spin speed formula and click boost (GameState), plus carousel rotation.

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.base_spin_speed_deg_s = 90.0
	_config.click_boost_increment = 0.2
	_config.click_boost_cap = 0.5
	_config.click_boost_decay_seconds = 2.0
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


func test_base_speed_converts_degrees_to_radians() -> void:
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal_approx(deg_to_rad(90.0), 0.00001)


func test_one_click_adds_the_increment() -> void:
	GameState.add_click_boost()
	assert_float(GameState.get_click_boost()).is_equal_approx(0.2, 0.00001)
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal_approx(deg_to_rad(90.0) * 1.2, 0.00001)


func test_clicks_stack_to_the_cap() -> void:
	for i in 5:
		GameState.add_click_boost()
	assert_float(GameState.get_click_boost()).is_equal_approx(0.5, 0.00001)


func test_boost_fades_linearly_after_last_click() -> void:
	for i in 3:
		GameState.add_click_boost()  # capped at 0.5
	GameState.advance_simulation(1.0)
	assert_float(GameState.get_click_boost()).is_equal_approx(0.25, 0.00001)
	GameState.advance_simulation(1.0)
	assert_float(GameState.get_click_boost()).is_equal(0.0)
	GameState.advance_simulation(5.0)
	assert_float(GameState.get_click_boost()).is_equal(0.0)


func test_click_during_fade_adds_to_what_is_left() -> void:
	GameState.add_click_boost()  # 0.2
	GameState.advance_simulation(1.0)  # 0.1 left
	GameState.add_click_boost()  # 0.1 + 0.2
	assert_float(GameState.get_click_boost()).is_equal_approx(0.3, 0.00001)


func test_click_at_cap_refreshes_the_fade() -> void:
	for i in 3:
		GameState.add_click_boost()
	GameState.advance_simulation(1.5)
	for i in 3:
		GameState.add_click_boost()
	GameState.advance_simulation(1.0)
	assert_float(GameState.get_click_boost()).is_equal_approx(0.25, 0.00001)


func test_fade_is_frame_rate_independent() -> void:
	for i in 3:
		GameState.add_click_boost()
	GameState.advance_simulation(1.0)
	var one_big_step := GameState.get_click_boost()
	GameState.reset_run(_config)
	for i in 3:
		GameState.add_click_boost()
	for i in 60:
		GameState.advance_simulation(1.0 / 60.0)
	assert_float(GameState.get_click_boost()).is_equal_approx(one_big_step, 0.00001)


func test_invalid_delta_is_ignored() -> void:
	GameState.add_click_boost()
	GameState.advance_simulation(-1.0)
	GameState.advance_simulation(NAN)
	assert_float(GameState.get_click_boost()).is_equal_approx(0.2, 0.00001)


func test_speed_signal_on_click_and_reset() -> void:
	var speeds: Array = []
	var record := func(speed: float) -> void: speeds.append(speed)
	GameState.spin_speed_changed.connect(record)
	GameState.add_click_boost()
	GameState.reset_run(_config)
	GameState.spin_speed_changed.disconnect(record)
	assert_int(speeds.size()).is_equal(2)
	assert_float(speeds[1]).is_equal_approx(deg_to_rad(90.0), 0.00001)


func test_carousel_tracks_unwrapped_angle_across_turns() -> void:
	var carousel: Carousel = auto_free(Carousel.new())
	var events: Array = []
	carousel.rotation_advanced.connect(func(prev: float, step: float) -> void: events.append([prev, step]))
	for i in 3:
		carousel.advance_rotation(1.0, PI)  # half a turn each
	assert_float(carousel.get_unwrapped_angle()).is_equal_approx(3.0 * PI, 0.00001)
	# rotation is stored in single precision, so allow a hair past ±PI.
	assert_float(carousel.rotation).is_between(-PI - 0.0001, PI + 0.0001)
	assert_int(events.size()).is_equal(3)
	assert_float(events[2][0]).is_equal_approx(2.0 * PI, 0.00001)


func test_stopped_carousel_emits_nothing() -> void:
	var carousel: Carousel = auto_free(Carousel.new())
	var count := [0]
	carousel.rotation_advanced.connect(func(_p: float, _s: float) -> void: count[0] += 1)
	carousel.advance_rotation(1.0, 0.0)
	assert_int(count[0]).is_equal(0)
