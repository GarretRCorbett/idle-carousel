extends GdUnitTestSuite
## Localization: every key the game uses exists, and numbers format consistently.

const CSV := "res://localization/strings.csv"
const SCENES: Array[String] = ["res://scenes/Game.tscn", "res://scenes/MainMenu.tscn", "res://scenes/OptionsMenu.tscn"]


var _saved_locale: String
var _saved_pseudo: bool


## These tests expect English. Switch to it (without touching the settings file)
## so a developer's saved language or pseudolocalization can't break them.
func before_test() -> void:
	_saved_locale = TranslationServer.get_locale()
	_saved_pseudo = TranslationServer.pseudolocalization_enabled
	TranslationServer.pseudolocalization_enabled = false
	TranslationServer.set_locale("en")


func after_test() -> void:
	TranslationServer.set_locale(_saved_locale)
	TranslationServer.pseudolocalization_enabled = _saved_pseudo


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
	var header := file.get_csv_line()
	assert_str(header[0]).is_equal("keys")
	assert_str(header[1]).is_equal("en")
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
	# Boundaries where float math used to drop a digit (Codex review).
	assert_str(NumberFormat.gold(1130000.0)).is_equal("1.13M")
	assert_str(NumberFormat.gold(1140000.0)).is_equal("1.14M")
	assert_str(NumberFormat.gold(10000.0)).is_equal("10.0K")
	assert_str(NumberFormat.gold(999999.0)).is_equal("999K")
	assert_str(NumberFormat.gold(1000000.0)).is_equal("1.00M")
	assert_str(NumberFormat.gold(2.5e12)).is_equal("2.50T")


func test_decimals() -> void:
	assert_str(NumberFormat.decimal(3.0, 1)).is_equal("3.0")
	assert_str(NumberFormat.decimal(1.234, 2)).is_equal("1.23")


## Every translation keeps the English placeholders ({0}, {1}...).
func test_translations_keep_placeholders() -> void:
	var file := FileAccess.open(CSV, FileAccess.READ)
	var header := file.get_csv_line()
	var regex := RegEx.create_from_string("[{][0-9]+[}]")
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < header.size():
			continue
		var expected := _placeholders(regex, row[1])
		for i in range(2, header.size()):
			assert_array(_placeholders(regex, row[i])).override_failure_message(
					"%s [%s] placeholders differ" % [row[0], header[i]]).is_equal(expected)


func _placeholders(regex: RegEx, text: String) -> Array:
	var found := []
	for m in regex.search_all(text):
		found.append(m.get_string())
	found.sort()
	return found


## Every character each language uses exists in that language's font (or its
## fallbacks). Fails when strings change without re-running tools/subset_fonts.py.
func test_every_language_can_draw_its_text() -> void:
	var file := FileAccess.open(CSV, FileAccess.READ)
	var header := file.get_csv_line()
	var rows: Array[PackedStringArray] = []
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == header.size():
			rows.append(row)
	for i in range(1, header.size()):
		var fonts := _font_chain(LocaleFonts.ui_font(header[i]))
		var missing := ""
		for row in rows:
			for c in row[i]:
				if c != " " and not _any_has(fonts, c.unicode_at(0)) and not c in missing:
					missing += c
		assert_str(missing).override_failure_message("%s font is missing: %s" % [header[i], missing]).is_empty()


func _font_chain(font: Font) -> Array[Font]:
	var chain: Array[Font] = []
	var queue: Array[Font] = [font]
	while not queue.is_empty():
		var f: Font = queue.pop_front()
		if f == null or f in chain:
			continue
		chain.append(f)
		if f is FontVariation:
			queue.append((f as FontVariation).base_font)
		queue.append_array(f.fallbacks)
	return chain


func _any_has(fonts: Array[Font], code: int) -> bool:
	for f in fonts:
		if f is FontFile and f.has_char(code):
			return true
	return false


func test_language_fonts() -> void:
	assert_object(LocaleFonts.ui_font("zh_CN")).is_not_null()
	assert_str(LocaleFonts.ui_font("es").resource_path).is_equal(LocaleFonts.DEFAULT_UI)
	assert_str(LocaleFonts.ui_font("ru").resource_path).contains("cyrillic")


## Every language column in the CSV is registered in Project Settings, so it
## loads and shows up in Settings -> Language.
func test_every_csv_language_is_loaded() -> void:
	var header := FileAccess.open(CSV, FileAccess.READ).get_csv_line()
	var loaded := TranslationServer.get_loaded_locales()
	for i in range(1, header.size()):
		assert_bool(header[i] in loaded).override_failure_message(
				"%s isn't in Project Settings > Localization > Translations" % header[i]).is_true()
