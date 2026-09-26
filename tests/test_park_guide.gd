extends GdUnitTestSuite
## The Park Guide tab (Phase 4 Step 8): in the Game's pause menu, one focusable
## button per entry, "???" and no text until met, live stats once met.

const CSV := "res://localization/strings.csv"

var _real_discovered: PackedStringArray
var _saved_locale: String


func before_test() -> void:
	_saved_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	_real_discovered = SaveManager.get_discovered()
	SaveManager.clear_discoveries()
	GameState.reset_run()


func after_test() -> void:
	get_tree().paused = false
	SaveManager.clear_discoveries()
	for id in _real_discovered:
		SaveManager.discover(id)
	GameState.reset_run()
	TranslationServer.set_locale(_saved_locale)


func _game() -> Game:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	return game


## A Guide on its own, built from the Game scene's data.
func _guide() -> ParkGuide:
	var game := _game()
	var guide := ParkGuide.new(game.tier_catalog, game.event_list)
	add_child(guide)
	auto_free(guide)
	return guide


func _index_of(guide: ParkGuide, kind: GuideEntry.Kind, id: StringName) -> int:
	var entries := guide.get_entries()
	for i in entries.size():
		if entries[i].kind == kind and entries[i].id == id:
			return i
	return -1


func test_the_pause_menu_has_a_guide_tab_before_debug() -> void:
	var game := _game()
	var tabs := game.find_child("OptionsTabs", true, false) as TabContainer
	var guide_tab := -1
	for i in tabs.get_tab_count():
		if tabs.get_tab_control(i) is ParkGuide:
			guide_tab = i
	assert_int(guide_tab).is_equal(2)  # after Settings and Controls
	assert_str(tabs.get_tab_title(guide_tab)).is_equal("OPT_TAB_GUIDE")
	assert_str(tabs.get_tab_title(tabs.get_tab_count() - 1)).is_equal("Debug")


func test_every_entry_is_a_focusable_button_and_focus_picks_the_page() -> void:
	var guide := _guide()
	var buttons := guide.get_entry_buttons()
	assert_int(buttons.size()).is_equal(guide.get_entries().size())
	for button in buttons:
		assert_int(button.focus_mode).is_equal(Control.FOCUS_ALL)
	var wolf := _index_of(guide, GuideEntry.Kind.MOUNT, &"wolf")
	buttons[wolf].grab_focus()
	assert_int(guide.get_selected()).is_equal(wolf)
	var rock := _index_of(guide, GuideEntry.Kind.ENEMY, &"rock")
	buttons[rock].grab_focus()
	assert_int(guide.get_selected()).is_equal(rock)


func test_an_unmet_entry_shows_only_question_marks() -> void:
	var guide := _guide()
	var wolf := _index_of(guide, GuideEntry.Kind.MOUNT, &"wolf")
	guide.select(wolf)
	assert_str(guide.get_entry_buttons()[wolf].text).is_equal("???")
	assert_str(guide.get_page_title()).is_equal("???")
	assert_str(guide.get_page_body()).is_empty()
	assert_str(guide.get_page_stats()).is_empty()


func test_a_met_entry_shows_its_name_text_and_live_stats() -> void:
	var guide := _guide()
	var wolf := _index_of(guide, GuideEntry.Kind.MOUNT, &"wolf")
	GameState.add_gold(1000000.0)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"wolf")  # discovers the Wolf (the Game is watching)
	guide.refresh()
	guide.select(wolf)
	assert_str(guide.get_entry_buttons()[wolf].text).is_equal("Wolf")
	assert_str(guide.get_page_title()).is_equal("Wolf")
	assert_str(guide.get_page_body()).is_equal(tr("GUIDE_MOUNT_WOLF_BODY"))
	assert_str(guide.get_page_stats()).contains("Owned: 1")
	assert_str(guide.get_page_stats()).contains("Wolf Fang")


func test_boss_and_tier_pages_show_their_numbers() -> void:
	var guide := _guide()
	SaveManager.discover("boss:leaf_storm")
	SaveManager.discover("tier:grey")
	guide.refresh()
	guide.select(_index_of(guide, GuideEntry.Kind.BOSS, &"leaf_storm"))
	assert_str(guide.get_page_title()).is_equal("Leaf Storm")
	assert_str(guide.get_page_stats()).contains("Guards the Grey tier")
	assert_str(guide.get_page_stats()).contains("Time limit")
	guide.select(_index_of(guide, GuideEntry.Kind.TIER, &"grey"))
	assert_str(guide.get_page_stats()).contains("health ×")


func test_the_horse_and_boost_are_known_from_the_start() -> void:
	var guide := _guide()
	guide.select(_index_of(guide, GuideEntry.Kind.MOUNT, &"horse"))
	assert_str(guide.get_page_title()).is_equal("Horse")
	assert_str(guide.get_page_stats()).contains("Owned: 1")
	guide.select(_index_of(guide, GuideEntry.Kind.MECHANIC, &"boost"))
	assert_str(guide.get_page_title()).is_equal("Boost")


func test_lb_and_rb_switch_pause_menu_tabs() -> void:
	var game := _game()
	var menu := game.find_child("OptionsMenu", true, false) as OptionsMenu
	var tabs := game.find_child("OptionsTabs", true, false) as TabContainer
	menu.open()
	var next := InputEventAction.new()
	next.action = &"shop_next_tab"
	next.pressed = true
	menu._unhandled_input(next)
	menu._unhandled_input(next)
	assert_bool(tabs.get_current_tab_control() is ParkGuide).is_true()
	var previous := InputEventAction.new()
	previous.action = &"shop_prev_tab"
	previous.pressed = true
	menu._unhandled_input(previous)
	assert_int(tabs.current_tab).is_equal(1)
	menu.close()


func test_guide_text_keys_exist() -> void:
	var keys := {}
	var file := FileAccess.open(CSV, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 2:
			keys[row[0]] = true
	var guide := ParkGuide.new()
	for key in Array(guide.group_keys) + [guide.unknown_key, guide.owned_key, guide.level_track_key,
			guide.star_key, guide.tier_stats_key, guide.boss_tier_key, guide.boss_time_key, guide.boss_reward_key,
			guide.beaten_key, guide.event_duration_key, "OPT_TAB_GUIDE"]:
		assert_bool(keys.has(key)).override_failure_message("missing key %s" % key).is_true()
	guide.free()
