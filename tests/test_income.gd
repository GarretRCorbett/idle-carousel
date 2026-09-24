extends GdUnitTestSuite
## Gold/sec (rolling window of actual earnings) and the play-area click burst.

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.income_bucket_seconds = 1.0
	_config.income_bucket_count = 10
	_config.play_area_click_gold = 0.25
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


func test_earnings_average_over_the_window() -> void:
	GameState.add_gold(20.0)
	assert_float(GameState.get_recent_gold_per_second()).is_equal_approx(2.0, 0.00001)


func test_spending_does_not_lower_income() -> void:
	GameState.add_gold(20.0)
	GameState.spend_gold(8.0)
	assert_float(GameState.get_recent_gold_per_second()).is_equal_approx(2.0, 0.00001)


func test_earnings_expire_after_the_window() -> void:
	GameState.add_gold(20.0)
	GameState.advance_simulation(9.5)
	assert_float(GameState.get_recent_gold_per_second()).is_equal_approx(2.0, 0.00001)
	GameState.advance_simulation(0.5)
	assert_float(GameState.get_recent_gold_per_second()).is_equal(0.0)


func test_steady_income_reads_steady() -> void:
	for second in 30:
		GameState.add_gold(3.0)
		GameState.advance_simulation(1.0)
	# After warm-up, 3 Gold every second reads as 3 Gold/sec.
	assert_float(GameState.get_recent_gold_per_second()).is_equal_approx(2.7, 0.3)


func test_long_idle_jump_clears_everything() -> void:
	GameState.add_gold(50.0)
	GameState.advance_simulation(100.0)
	assert_float(GameState.get_recent_gold_per_second()).is_equal(0.0)
	GameState.add_gold(10.0)
	assert_float(GameState.get_recent_gold_per_second()).is_equal_approx(1.0, 0.00001)


func test_reset_clears_income() -> void:
	GameState.add_gold(20.0)
	GameState.reset_run(_config)
	assert_float(GameState.get_recent_gold_per_second()).is_equal(0.0)


func test_play_area_click_gives_boost_and_gold_when_nothing_latched() -> void:
	GameState.register_play_area_click()
	assert_float(GameState.get_gold()).is_equal_approx(0.25, 0.00001)
	assert_float(GameState.get_click_boost()).is_greater(0.0)
