extends GdUnitTestSuite
## The Esc menu's Debug tab (debug builds only; tests run in one) and the
## shortcuts behind it.


func after_test() -> void:
	GameState.reset_run()
	ThemeManager.set_theme(&"park")
	Engine.time_scale = 1.0


func _game() -> Game:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	return game


func test_the_esc_menu_has_a_debug_tab() -> void:
	var game := _game()
	var tabs := game.find_child("OptionsTabs", true, false) as TabContainer
	assert_str(tabs.get_tab_title(tabs.get_tab_count() - 1)).is_equal("Debug")
	assert_bool(tabs.get_tab_control(tabs.get_tab_count() - 1) is DebugPanel).is_true()


func test_gold_and_the_kill_gate_shortcuts() -> void:
	var game := _game()
	var before := GameState.get_gold()
	game.debug_add_gold(5000.0)
	assert_float(GameState.get_gold()).is_equal(before + 5000.0)
	var tier := game.tier_catalog.get_tier(0)
	assert_bool(BossEncounter.can_challenge(tier)).is_false()
	game.debug_fill_kill_gate()
	assert_bool(BossEncounter.can_challenge(tier)).is_true()


func test_tier_steps_unlock_and_select() -> void:
	var game := _game()
	game.debug_step_tier(1)
	assert_int(GameState.get_selected_tier()).is_equal(1)
	game.debug_step_tier(-1)
	assert_int(GameState.get_selected_tier()).is_equal(0)


## Game speed from the Debug tab never outlives the run.
func test_game_speed_resets_when_the_game_closes() -> void:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	Engine.time_scale = 4.0
	game.free()
	assert_float(Engine.time_scale).is_equal(1.0)
