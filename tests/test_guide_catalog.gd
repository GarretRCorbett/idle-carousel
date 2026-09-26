extends GdUnitTestSuite
## Park Guide entries (Phase 4 Step 8): built from the game's data, so every
## mount, enemy, tier, boss and event has one, with text that exists.

const CSV := "res://localization/strings.csv"

var _real_discovered: PackedStringArray


func before_test() -> void:
	_real_discovered = SaveManager.get_discovered()
	SaveManager.clear_discoveries()


func after_test() -> void:
	SaveManager.clear_discoveries()
	for id in _real_discovered:
		SaveManager.discover(id)
	GameState.reset_run()


func _game() -> Game:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	return game


func _entries(game: Game) -> Array[GuideEntry]:
	return GuideCatalog.build(game.tier_catalog, game.event_list)


func _ids(entries: Array[GuideEntry], kind: GuideEntry.Kind) -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry in entries:
		if entry.kind == kind:
			ids.append(entry.id)
	return ids


func _csv_keys() -> Dictionary:
	var keys := {}
	var file := FileAccess.open(CSV, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 2 and row[0] != "":
			keys[row[0]] = true
	return keys


func test_every_mount_has_an_entry_with_its_data_and_level_track() -> void:
	var entries := _entries(_game())
	var expected: Array[StringName] = []
	for upgrade in UpgradeManager.get_definitions():
		if upgrade.mount_scene != null:
			expected.append(upgrade.id)
	assert_array(_ids(entries, GuideEntry.Kind.MOUNT)).is_equal(expected)
	assert_array(expected).contains([&"horse", &"wolf", &"giraffe", &"sloth", &"elephant", &"panda"])
	for entry in entries:
		if entry.kind == GuideEntry.Kind.MOUNT:
			assert_object(entry.data).override_failure_message("%s data" % entry.id).is_instanceof(MountData)
			assert_object(entry.level_upgrade).override_failure_message("%s levels" % entry.id).is_not_null()
			assert_str(String(entry.level_upgrade.target_mount)).is_equal(String(entry.id))


func test_every_wave_enemy_tier_boss_and_event_has_an_entry() -> void:
	var game := _game()
	var entries := _entries(game)
	assert_array(_ids(entries, GuideEntry.Kind.ENEMY)).contains_exactly([&"leaf", &"stick", &"rock"])
	var tiers: Array[StringName] = []
	var bosses: Array[StringName] = []
	for tier in game.tier_catalog.tiers:
		tiers.append(tier.tier_id)
		if tier.boss != null:
			bosses.append(tier.boss.boss_id)
	assert_array(_ids(entries, GuideEntry.Kind.TIER)).is_equal(tiers)
	assert_array(_ids(entries, GuideEntry.Kind.BOSS)).is_equal(bosses)
	assert_int(bosses.size()).is_equal(6)
	var events: Array[StringName] = []
	for event in game.event_list:
		events.append(event.id)
	assert_array(_ids(entries, GuideEntry.Kind.EVENT)).is_equal(events)
	assert_int(events.size()).is_equal(4)
	assert_array(_ids(entries, GuideEntry.Kind.MECHANIC)).is_equal(GuideCatalog.MECHANICS)
	for entry in entries:
		if entry.kind == GuideEntry.Kind.BOSS:
			assert_object(entry.boss_body).override_failure_message("%s body" % entry.id).is_not_null()


func test_entries_come_in_group_order_with_unique_discovery_ids() -> void:
	var entries := _entries(_game())
	var seen := {}
	var last_group := 0
	for entry in entries:
		assert_bool(entry.group >= last_group).override_failure_message("%s out of order" % entry.id).is_true()
		last_group = entry.group
		var discovery_id := entry.get_discovery_id()
		assert_bool(seen.has(discovery_id)).override_failure_message("duplicate %s" % discovery_id).is_false()
		seen[discovery_id] = true


func test_every_entry_has_its_text() -> void:
	var keys := _csv_keys()
	for entry in _entries(_game()):
		assert_bool(keys.has(entry.get_title_key())).override_failure_message(
				"%s: no title key %s" % [entry.id, entry.get_title_key()]).is_true()
		assert_bool(keys.has(entry.body_key)).override_failure_message(
				"%s: no body key %s" % [entry.id, entry.body_key]).is_true()


func test_only_the_horse_boost_and_auto_boost_start_known() -> void:
	var known: Array[StringName] = []
	for entry in _entries(_game()):
		if entry.is_discovered():
			known.append(entry.id)
	# The game discovers the Horse it starts with; the entry knows it anyway.
	assert_array(known).contains_exactly([&"horse", &"boost", &"auto_boost"])


func test_meeting_something_unlocks_its_entry() -> void:
	var entries := _entries(_game())
	var wolf: GuideEntry
	for entry in entries:
		if entry.kind == GuideEntry.Kind.MOUNT and entry.id == &"wolf":
			wolf = entry
	assert_bool(wolf.is_discovered()).is_false()
	SaveManager.discover("mount:wolf")
	assert_bool(wolf.is_discovered()).is_true()
