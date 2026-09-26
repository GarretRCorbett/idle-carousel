extends GdUnitTestSuite
## Run saves: round trip through the file, rebuilt stats, backups, and bad data.

const TEST_PATH := "user://test_save_data.json"

var _real_path: String
var _real_enabled: bool


func before_test() -> void:
	_real_path = SaveManager.run_save_path
	_real_enabled = SaveManager.run_saves_enabled
	SaveManager.run_save_path = TEST_PATH
	SaveManager.run_saves_enabled = true
	SaveManager.delete_run_save()
	GameState.reset_run()


func after_test() -> void:
	SaveManager.delete_run_save()
	SaveManager.run_save_path = _real_path
	SaveManager.run_saves_enabled = _real_enabled
	GameState.reset_run()


func _buy(id: StringName, times: int = 1) -> void:
	for i in times:
		assert_bool(UpgradeManager.purchase(id)).override_failure_message("couldn't buy %s" % id).is_true()


## A run with a bit of everything: upgrades, a second mount, a beaten boss,
## a new tier, kills and run time.
func _play_a_little() -> void:
	GameState.add_gold(1000000.0)
	GameState.record_boss_victory(0)
	_buy(&"carousel_speed", 2)
	_buy(&"boost_power")
	_buy(&"click_damage")
	_buy(&"mount_slot", 2)
	_buy(&"wolf")
	_buy(&"wolf_level", 5)  # 3 levels, the star-up, level 4
	_buy(&"ticket_booth")
	GameState.set_selected_tier(1)
	for i in 7:
		GameState.record_kill(1)
	GameState.advance_simulation(12.5)


func test_round_trip_keeps_every_saved_value() -> void:
	_play_a_little()
	var before := GameState.to_save_data()
	assert_bool(SaveManager.save_run()).is_true()
	GameState.reset_run()
	assert_bool(SaveManager.load_run()).is_true()
	assert_dict(GameState.to_save_data()).is_equal(before)


func test_loaded_stats_match_the_run_that_bought_them() -> void:
	_play_a_little()
	var speed := GameState.get_spin_upgrade_multiplier()
	var cap := GameState.get_boost_cap()
	var click := GameState.get_click_damage()
	var booths := GameState.get_booth_count()
	var slots := GameState.get_mount_slots()
	var roster := GameState.get_mount_roster()
	var wolf_damage := GameState.get_mount_damage(load("res://resources/mounts/wolf.tres"))
	SaveManager.save_run()
	GameState.reset_run()
	SaveManager.load_run()
	assert_float(GameState.get_spin_upgrade_multiplier()).is_equal_approx(speed, 0.00001)
	assert_float(GameState.get_boost_cap()).is_equal_approx(cap, 0.00001)
	assert_float(GameState.get_click_damage()).is_equal_approx(click, 0.00001)
	assert_int(GameState.get_booth_count()).is_equal(booths)
	assert_int(GameState.get_mount_slots()).is_equal(slots)
	assert_array(GameState.get_mount_roster()).is_equal(roster)
	assert_float(GameState.get_mount_damage(load("res://resources/mounts/wolf.tres"))).is_equal_approx(wolf_damage, 0.00001)
	assert_int(GameState.get_mount_star(&"wolf")).is_equal(2)
	assert_int(GameState.get_mount_level(&"wolf")).is_equal(4)
	assert_bool(GameState.is_tier_unlocked(1)).is_true()
	assert_int(GameState.get_selected_tier()).is_equal(1)


func test_a_loaded_run_starts_clean_at_full_health() -> void:
	_play_a_little()
	GameState.damage_carousel(40.0)
	GameState.register_latch(1, 0.5, 1.0)
	GameState.set_boss_active(true)
	SaveManager.save_run()
	GameState.reset_run()
	SaveManager.load_run()
	assert_float(GameState.get_health()).is_equal(GameState.get_max_health())
	assert_int(GameState.get_latched_count()).is_equal(0)
	assert_bool(GameState.is_boss_active()).is_false()


func test_no_save_means_nothing_to_load() -> void:
	assert_bool(SaveManager.has_run_save()).is_false()
	assert_bool(SaveManager.load_run()).is_false()


func test_saving_is_off_unless_enabled() -> void:
	SaveManager.run_saves_enabled = false
	assert_bool(SaveManager.save_run()).is_false()
	assert_bool(SaveManager.has_run_save()).is_false()


func test_a_broken_save_falls_back_to_the_backup() -> void:
	GameState.add_gold(111.0)
	SaveManager.save_run()
	GameState.add_gold(222.0)
	SaveManager.save_run()  # the first save is now the backup
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("{ not json")
	file.close()
	GameState.reset_run()
	assert_bool(SaveManager.load_run()).is_true()
	assert_float(GameState.get_gold()).is_equal(111.0)


func test_a_save_from_a_newer_build_is_left_alone() -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": SaveManager.SAVE_VERSION + 1, "run": {"upgrade_levels": {}}}))
	file.close()
	assert_bool(SaveManager.has_run_save()).is_false()


func test_unknown_upgrades_are_skipped_and_levels_clamped() -> void:
	var speed := UpgradeManager.get_definition(&"carousel_speed")
	var loaded := GameState.load_save_data(
			{"upgrade_levels": {"no_such_upgrade": 3, "carousel_speed": 999}}, UpgradeManager.get_definitions())
	assert_bool(loaded).is_true()
	assert_int(GameState.get_upgrade_level(&"carousel_speed")).is_equal(speed.max_level)
	assert_int(GameState.get_upgrade_level(&"no_such_upgrade")).is_equal(0)


func test_saved_roster_order_is_kept() -> void:
	GameState.load_save_data({"upgrade_levels": {"mount_slot": 1, "wolf": 1},
			"mount_roster": ["wolf", "horse"]}, UpgradeManager.get_definitions())
	assert_array(GameState.get_mount_roster()).is_equal([&"wolf", &"horse"])


func test_a_roster_that_doesnt_match_the_levels_is_rebuilt() -> void:
	GameState.load_save_data({"upgrade_levels": {"mount_slot": 1, "wolf": 1},
			"mount_roster": ["wolf", "wolf"]}, UpgradeManager.get_definitions())
	assert_array(GameState.get_mount_roster()).is_equal([&"horse", &"wolf"])


func test_bad_numbers_fall_back_to_a_fresh_runs() -> void:
	GameState.load_save_data({"upgrade_levels": {}, "gold": -50.0, "run_seconds": -3.0,
			"selected_tier": 4, "bosses_beaten": 1}, UpgradeManager.get_definitions())
	assert_float(GameState.get_gold()).is_equal(0.0)
	assert_float(GameState.get_run_seconds()).is_equal(0.0)
	assert_int(GameState.get_selected_tier()).is_equal(0)  # tier 4 isn't unlocked


func test_not_a_save_changes_nothing() -> void:
	GameState.add_gold(50.0)
	assert_bool(GameState.load_save_data({"gold": 9.0}, UpgradeManager.get_definitions())).is_false()
	assert_float(GameState.get_gold()).is_equal(50.0)


## Version 1 saves had Tier 2 rows and Wolf Fang; they become tracks.
func test_a_version_1_save_is_converted() -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "saved_at": 1, "run": {
		"upgrade_levels": {"mount_slot": 2, "wolf": 1, "giraffe": 1, "wolf_fang": 5, "wolf_tier2": 1,
			"horse_tier2": 1, "giraffe_tier2": 0}, "bosses_beaten": 1}}))
	file.close()
	assert_bool(SaveManager.load_run()).is_true()
	assert_int(GameState.get_mount_star(&"wolf")).is_equal(2)
	assert_int(GameState.get_mount_level(&"wolf")).is_equal(5)  # Wolf Fang 5 = levels 1-3 + 4-5
	assert_int(GameState.get_mount_star(&"horse")).is_equal(2)
	assert_int(GameState.get_mount_level(&"horse")).is_equal(3)
	assert_int(GameState.get_mount_star(&"giraffe")).is_equal(1)
	assert_int(GameState.get_mount_level(&"giraffe")).is_equal(0)
	assert_int(GameState.get_upgrade_level(&"wolf_fang")).is_equal(0)


func test_wolf_fang_without_tier_2_stops_at_level_3() -> void:
	var run := {"upgrade_levels": {"wolf_fang": 8}}
	SaveManager._upgrade_v1(run)
	assert_dict(run["upgrade_levels"]).is_equal({"wolf_level": 3})
