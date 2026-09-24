extends GdUnitTestSuite
## Settings: saved to a file, reloaded, clamped, and applied to audio buses.

const TEST_PATH := "user://test_settings.cfg"

var _real_path: String


func before_test() -> void:
	_real_path = SaveManager.settings_path
	SaveManager.settings_path = TEST_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	SaveManager.load_settings()


func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	SaveManager.settings_path = _real_path
	SaveManager.load_settings()


func test_defaults_when_there_is_no_file() -> void:
	assert_float(SaveManager.get_setting(&"sfx_volume")).is_equal(SaveManager.DEFAULTS[&"sfx_volume"])
	assert_bool(SaveManager.get_setting(&"fullscreen")).is_false()


func test_settings_survive_a_reload() -> void:
	SaveManager.set_setting(&"sfx_volume", 0.3)
	SaveManager.set_setting(&"fullscreen", true)
	SaveManager.load_settings()
	assert_float(SaveManager.get_setting(&"sfx_volume")).is_equal_approx(0.3, 0.0001)
	assert_bool(SaveManager.get_setting(&"fullscreen")).is_true()


func test_volume_is_clamped_and_drives_its_bus() -> void:
	SaveManager.set_setting(&"sfx_volume", 5.0)
	assert_float(SaveManager.get_setting(&"sfx_volume")).is_equal(1.0)
	var bus := AudioServer.get_bus_index(&"SFX")
	assert_int(bus).is_greater_equal(0)
	assert_float(AudioServer.get_bus_volume_db(bus)).is_equal_approx(0.0, 0.001)
	SaveManager.set_setting(&"sfx_volume", 0.0)
	assert_bool(AudioServer.is_bus_mute(bus)).is_true()


func test_options_menu_has_both_tabs_and_starts_hidden() -> void:
	var menu := (load("res://scenes/OptionsMenu.tscn") as PackedScene).instantiate() as OptionsMenu
	add_child(menu)
	auto_free(menu)
	assert_bool(menu.visible).is_false()
	var tabs := menu.get_node("%OptionsTabs") as TabContainer
	assert_int(tabs.get_tab_count()).is_equal(2)
	menu.open()
	assert_bool(menu.visible).is_true()
	menu.close()
	assert_bool(menu.visible).is_false()
