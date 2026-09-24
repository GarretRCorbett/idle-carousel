extends GdUnitTestSuite
## Localization: every key the game uses exists, and numbers format consistently.

const CSV := "res://localization/strings.csv"
const SCENES: Array[String] = ["res://scenes/Game.tscn", "res://scenes/MainMenu.tscn", "res://scenes/OptionsMenu.tscn"]


func _csv_keys() -> Dictionary:
	var keys := {}
	var file := FileAccess.open(CSV, FileAccess.READ)
	file.get_csv_line()  # header
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 2 and row[0] != "":
			keys[row[0]] = row[1]
	return keys


func test_csv_keys_are_unique_and_filled() -> void:
	var seen := {}
	var file := FileAccess.open(CSV, FileAccess.READ)
	assert_array(Array(file.get_csv_line())).is_equal(["keys", "en"])
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 2 or row[0] == "":
			continue
		assert_bool(seen.has(row[0])).override_failure_message("duplicate key %s" % row[0]).is_false()
		assert_str(row[1]).override_failure_message("empty English for %s" % row[0]).is_not_empty()
		seen[row[0]] = true


func test_scene_text_is_all_keys() -> void:
	var keys := _csv_keys()
	for path in SCENES:
		var text := FileAccess.get_file_as_string(path)
		var regex := RegEx.create_from_string('\ntext = "([^"]*)"')
		for m in regex.search_all(text):
			var value := m.get_string(1)
			assert_bool(keys.has(value)).override_failure_message(
					"%s: text \"%s\" isn't a translation key" % [path, value]).is_true()


func test_upgrade_text_is_all_keys() -> void:
	var keys := _csv_keys()
	for upgrade in UpgradeManager.get_definitions():
		assert_bool(keys.has(upgrade.display_name)).override_failure_message("%s name" % upgrade.id).is_true()
		assert_bool(keys.has(upgrade.description)).override_failure_message("%s description" % upgrade.id).is_true()


func test_code_keys_exist() -> void:
	var keys := _csv_keys()
	var hud := Hud.new()
	var shop := UpgradeShop.new()
	for key in [hud.gold_key, hud.gold_per_second_key, hud.speed_key, hud.wave_countdown_key, hud.wave_paused_key,
			hud.emergency_ready_key, hud.emergency_cooldown_key, hud.crank_button_key,
			shop.cost_key, shop.requires_key, shop.maxed_key, shop.needs_slot_key, shop.sell_key,
			"OPT_TAB_SETTINGS", "OPT_TAB_CONTROLS"] + Array(shop.tab_title_keys):
		assert_bool(keys.has(key)).override_failure_message("missing key %s" % key).is_true()
	hud.free()
	shop.free()


func test_gold_numbers() -> void:
	assert_str(NumberFormat.gold(0.0)).is_equal("0")
	assert_str(NumberFormat.gold(999.9)).is_equal("999")
	assert_str(NumberFormat.gold(1234.0)).is_equal("1,234")
	assert_str(NumberFormat.gold(9999.0)).is_equal("9,999")
	assert_str(NumberFormat.gold(12345.0)).is_equal("12.3K")
	assert_str(NumberFormat.gold(123456.0)).is_equal("123K")
	assert_str(NumberFormat.gold(4567890.0)).is_equal("4.56M")
	assert_str(NumberFormat.gold(7.89e9)).is_equal("7.89B")
	assert_str(NumberFormat.gold(-1500.0)).is_equal("-1,500")


func test_decimals() -> void:
	assert_str(NumberFormat.decimal(3.0, 1)).is_equal("3.0")
	assert_str(NumberFormat.decimal(1.234, 2)).is_equal("1.23")
