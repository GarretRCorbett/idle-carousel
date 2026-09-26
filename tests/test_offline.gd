extends GdUnitTestSuite
## Offline progress: booth + Panda income at base speed, the efficiency rate,
## the minimum and the 8-hour cap, and only time with the game closed counts.

const TEST_PATH := "user://test_offline_save.json"

var _config: RunConfig
var _real_path: String
var _real_enabled: bool


func before_test() -> void:
	_config = RunConfig.new()
	_config.base_spin_speed_deg_s = 36.0  # one turn every 10 s
	_config.offline_efficiency = 0.5
	_config.offline_max_hours = 8.0
	_config.offline_min_seconds = 60.0
	GameState.reset_run(_config)
	_real_path = SaveManager.run_save_path
	_real_enabled = SaveManager.run_saves_enabled
	SaveManager.run_save_path = TEST_PATH
	SaveManager.run_saves_enabled = true
	SaveManager.delete_run_save()


func after_test() -> void:
	SaveManager.delete_run_save()
	SaveManager.run_save_path = _real_path
	SaveManager.run_saves_enabled = _real_enabled
	GameState.reset_run()


func _horse_gold() -> float:
	return GameState.get_mount_gold(GameState.HORSE_DATA)


func test_one_horse_one_booth_at_half_rate() -> void:
	# 0.1 turns/s × 1 booth × Horse Gold, at 50%.
	var expected := 0.1 * _horse_gold() * 0.5
	assert_float(GameState.get_offline_gold_per_second()).is_equal_approx(expected, 0.00001)
	assert_float(GameState.grant_offline_gold(1000.0)).is_equal(floorf(expected * 1000.0))


func test_boost_and_drag_dont_change_it() -> void:
	var before := GameState.get_offline_gold_per_second()
	for i in 10:
		GameState.add_click_boost()
	GameState.register_latch(1, 5.0, 0.0)
	assert_float(GameState.get_offline_gold_per_second()).is_equal_approx(before, 0.00001)


func test_the_panda_adds_its_gold_per_turn() -> void:
	GameState.load_save_data({"upgrade_levels": {"mount_slot": 1, "panda": 1}}, UpgradeManager.get_definitions())
	var panda := GameState.get_mount_gold_per_turn(GameState.PANDA_DATA)
	var expected := (0.1 * _horse_gold() + 0.1 * panda) * 0.5
	assert_float(GameState.get_offline_gold_per_second()).is_equal_approx(expected, 0.00001)


func test_short_absences_pay_nothing() -> void:
	assert_float(GameState.grant_offline_gold(59.0)).is_equal(0.0)
	assert_float(GameState.get_gold()).is_equal(0.0)


func test_capped_at_the_max_hours() -> void:
	var rate := GameState.get_offline_gold_per_second()
	assert_float(GameState.grant_offline_gold(100.0 * 3600.0)).is_equal(floorf(rate * 8.0 * 3600.0))


func test_bad_times_pay_nothing() -> void:
	assert_float(GameState.grant_offline_gold(-500.0)).is_equal(0.0)
	assert_float(GameState.grant_offline_gold(NAN)).is_equal(0.0)


func test_offline_gold_is_not_counted_as_gold_per_second() -> void:
	GameState.grant_offline_gold(3600.0)
	assert_float(GameState.get_recent_gold_per_second()).is_equal(0.0)


func test_a_save_from_this_session_counts_no_time_away() -> void:
	SaveManager.save_run()
	assert_float(SaveManager.get_offline_seconds()).is_equal(0.0)


func test_a_save_from_an_earlier_session_counts_the_time_since() -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	var saved_at := int(Time.get_unix_time_from_system()) - 7200
	file.store_string(JSON.stringify({"version": 1, "saved_at": saved_at, "run": {"upgrade_levels": {}}}))
	file.close()
	SaveManager._saved_this_session = false
	assert_float(SaveManager.get_offline_seconds()).is_between(7199.0, 7260.0)
