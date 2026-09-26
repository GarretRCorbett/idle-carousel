extends GdUnitTestSuite
## Park Guide discovery hooks (Phase 4 Step 8): the first time you own a mount,
## meet an enemy or a tier, challenge a boss, see an event, or hit Overdrive,
## a latch or a stall, its entry unlocks.

var _real_discovered: PackedStringArray


func before_test() -> void:
	_real_discovered = SaveManager.get_discovered()
	SaveManager.clear_discoveries()
	GameState.reset_run()


func after_test() -> void:
	SaveManager.clear_discoveries()
	for id in _real_discovered:
		SaveManager.discover(id)
	GameState.reset_run()
	GameState.set_selected_tier(0)


func _game() -> Game:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	return game


func test_owning_a_mount_discovers_it() -> void:
	_game()
	assert_bool(SaveManager.is_discovered("mount:horse")).is_true()  # the starting Horse
	assert_bool(SaveManager.is_discovered("mount:wolf")).is_false()
	GameState.add_gold(1000000.0)
	assert_bool(UpgradeManager.purchase(&"mount_slot")).is_true()
	assert_bool(UpgradeManager.purchase(&"wolf")).is_true()
	assert_bool(SaveManager.is_discovered("mount:wolf")).is_true()


func test_an_admitted_enemy_discovers_its_type_and_tier() -> void:
	var game := _game()
	game.debug_step_tier(1)  # Green
	game.debug_send_waves(1)
	for i in 3:
		game._physics_process(1.0 / 60.0)
	assert_int(game.get_live_enemy_count()).is_greater(0)
	assert_bool(SaveManager.is_discovered("tier:green")).is_true()
	assert_bool(SaveManager.is_discovered("tier:grey")).is_false()
	var found := false
	for id in SaveManager.get_discovered():
		found = found or id.begins_with("enemy:")
	assert_bool(found).is_true()


func test_challenging_a_boss_discovers_it() -> void:
	var game := _game()
	assert_bool(SaveManager.is_discovered("boss:leaf_storm")).is_false()
	game.debug_fill_kill_gate()
	assert_bool(game.challenge_boss()).is_true()
	assert_bool(SaveManager.is_discovered("boss:leaf_storm")).is_true()
	game.give_up_boss()


func test_events_are_discovered_when_they_happen_or_appear() -> void:
	var game := _game()
	game.debug_spawn_event(&"popup_booth")  # a visitor: just happens
	assert_bool(SaveManager.is_discovered("event:popup_booth")).is_true()
	game.debug_spawn_event(&"speed_surge")  # a pickup: its token appears
	assert_bool(SaveManager.is_discovered("event:speed_surge")).is_true()
	assert_bool(SaveManager.is_discovered("event:golden_hour")).is_false()


func test_overdrive_latch_and_stall_are_discovered_when_they_start() -> void:
	var discovery := GuideDiscovery.new()
	add_child(discovery)
	auto_free(discovery)
	GameState.overdrive_changed.emit(false)
	GameState.latch_count_changed.emit(0)
	GameState.stall_changed.emit(false)
	assert_bool(SaveManager.is_discovered("mechanic:overdrive")).is_false()
	assert_bool(SaveManager.is_discovered("mechanic:latch")).is_false()
	assert_bool(SaveManager.is_discovered("mechanic:stall")).is_false()
	GameState.overdrive_changed.emit(true)
	GameState.latch_count_changed.emit(2)
	GameState.stall_changed.emit(true)
	assert_bool(SaveManager.is_discovered("mechanic:overdrive")).is_true()
	assert_bool(SaveManager.is_discovered("mechanic:latch")).is_true()
	assert_bool(SaveManager.is_discovered("mechanic:stall")).is_true()
