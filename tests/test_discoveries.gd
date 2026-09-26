extends GdUnitTestSuite
## Park Guide discoveries (Phase 4 Step 8): kept in the save's "permanent"
## section, so they outlive runs.

const TEST_PATH := "user://test_discoveries.json"

var _real_path: String
var _real_enabled: bool
var _real_discovered: PackedStringArray


func before_test() -> void:
	_real_path = SaveManager.run_save_path
	_real_enabled = SaveManager.run_saves_enabled
	_real_discovered = SaveManager.get_discovered()
	SaveManager.run_save_path = TEST_PATH
	SaveManager.run_saves_enabled = true
	SaveManager.delete_run_save()
	SaveManager.clear_discoveries()
	GameState.reset_run()


func after_test() -> void:
	SaveManager.delete_run_save()
	SaveManager.run_save_path = _real_path
	SaveManager.run_saves_enabled = _real_enabled
	SaveManager.clear_discoveries()
	for id in _real_discovered:
		SaveManager.discover(id)
	GameState.reset_run()


func _saved_permanent() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEST_PATH))
	return parsed["permanent"]


func test_discover_marks_once_and_signals_once() -> void:
	var heard: Array[String] = []
	var listener := func(id: String) -> void: heard.append(id)
	SaveManager.discovered.connect(listener)
	SaveManager.discover("mount:wolf")
	SaveManager.discover("mount:wolf")
	SaveManager.discover("")
	SaveManager.discovered.disconnect(listener)
	assert_bool(SaveManager.is_discovered("mount:wolf")).is_true()
	assert_bool(SaveManager.is_discovered("enemy:leaf")).is_false()
	assert_array(heard).is_equal(["mount:wolf"])


func test_discoveries_are_saved_sorted_in_the_permanent_section() -> void:
	SaveManager.discover("enemy:leaf")
	SaveManager.discover("boss:leaf_storm")
	assert_bool(SaveManager.save_run()).is_true()
	assert_array(_saved_permanent()["discovered"]).is_equal(["boss:leaf_storm", "enemy:leaf"])


func test_discoveries_survive_save_new_run_and_load() -> void:
	SaveManager.discover("mount:wolf")
	SaveManager.discover("tier:green")
	SaveManager.save_run()
	# New run: a fresh GameState, saved over the old run.
	GameState.reset_run()
	SaveManager.save_run()
	# Next launch: memory starts empty and is read back from the file.
	SaveManager.clear_discoveries()
	SaveManager.load_permanent()
	assert_bool(SaveManager.is_discovered("mount:wolf")).is_true()
	assert_bool(SaveManager.is_discovered("tier:green")).is_true()
	# Continue still loads the run next to it.
	assert_bool(SaveManager.load_run()).is_true()


func test_no_save_means_nothing_discovered() -> void:
	SaveManager.discover("mount:wolf")
	SaveManager.load_permanent()
	assert_array(Array(SaveManager.get_discovered())).is_empty()


func test_nothing_is_written_while_run_saving_is_off() -> void:
	SaveManager.run_saves_enabled = false
	SaveManager.discover("mount:wolf")
	assert_bool(SaveManager.save_run()).is_false()
	assert_bool(FileAccess.file_exists(TEST_PATH)).is_false()


func test_bad_permanent_data_is_ignored() -> void:
	SaveManager.save_run()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TEST_PATH))
	for bad: Variant in ["oops", {"discovered": "wolf"}, {"discovered": [3, "", "mount:wolf"]}]:
		data["permanent"] = bad
		var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
		file.store_string(JSON.stringify(data))
		file.close()
		SaveManager.load_permanent()
		var expected: Array = ["mount:wolf"] if bad is Dictionary and bad["discovered"] is Array else []
		assert_array(Array(SaveManager.get_discovered())).is_equal(expected)
