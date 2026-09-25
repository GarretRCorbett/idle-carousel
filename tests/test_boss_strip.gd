extends GdUnitTestSuite
## The boss strip above the carousel (Phase 3 Step 6f), in the real Game scene.

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


func _game() -> Game:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	GameState.reset_run(_config)
	(game.get_node("WaveManager") as WaveManager).set_auto(false)
	return game


func _strip(game: Game) -> BossStrip:
	return game.find_child("BossStrip", true, false) as BossStrip


func _action(strip: BossStrip) -> TwoStepButton:
	return strip.get_node("%ActionButton") as TwoStepButton


func _pips(strip: BossStrip) -> Array[Node]:
	return strip.get_node("%Pips").get_children()


func test_shows_the_kill_gate_and_enables_challenge_when_met() -> void:
	var game := _game()
	var strip := _strip(game)
	var progress := strip.get_node("%Progress") as Label
	assert_bool(_action(strip).disabled).is_true()
	for i in 42:
		GameState.record_kill(0)
	assert_str(progress.text).contains("42")
	for i in 18:
		GameState.record_kill(0)
	assert_bool(_action(strip).disabled).is_false()


func test_challenge_starts_the_fight_and_give_up_asks_first() -> void:
	var game := _game()
	var strip := _strip(game)
	for i in 60:
		GameState.record_kill(0)
	_action(strip).pressed.emit()  # Challenge: one press
	assert_bool(GameState.is_boss_active()).is_true()
	assert_bool(_action(strip).requires_confirm).is_true()
	_action(strip).pressed.emit()  # first press of Give up only asks
	assert_bool(GameState.is_boss_active()).is_true()
	_action(strip)._process(0.5)
	_action(strip).pressed.emit()
	assert_bool(GameState.is_boss_active()).is_false()


func test_fight_shows_the_timer() -> void:
	var game := _game()
	var strip := _strip(game)
	for i in 60:
		GameState.record_kill(0)
	game.challenge_boss()
	game.get_encounter().advance(18.0)  # 90 -> 72 s
	assert_str((strip.get_node("%Progress") as Label).text).is_equal("1:12")


func test_pips_follow_unlocks_and_switch_tiers() -> void:
	var game := _game()
	var pips := _pips(_strip(game))
	assert_int(pips.size()).is_equal(6)
	assert_bool((pips[0] as Button).disabled).is_false()
	assert_bool((pips[1] as Button).disabled).is_true()
	GameState.record_boss_victory(0)
	assert_bool((pips[1] as Button).disabled).is_false()
	(pips[1] as Button).pressed.emit()
	assert_int(GameState.get_selected_tier()).is_equal(1)
	# Green has no boss yet (Step 7): the strip says so and Challenge is off.
	assert_bool(_action(_strip(game)).disabled).is_true()


func test_pips_lock_during_a_fight() -> void:
	var game := _game()
	GameState.record_boss_victory(0)
	for i in 60:
		GameState.record_kill(0)
	game.challenge_boss()
	for pip in _pips(_strip(game)):
		assert_bool((pip as Button).disabled).is_true()


## Nothing in the strip changes size between farming Grey, farming a tier with
## no boss yet, and fighting (Garret: the bar shifted when switching tiers).
func test_strip_layout_never_shifts() -> void:
	var game := _game()
	var strip := _strip(game)
	var row := strip.get_node("Margin/Row") as HBoxContainer
	var widths := func() -> Array[float]:
		var list: Array[float] = []
		for child: Control in row.get_children():
			# A hidden piece takes no room in the row, so it counts as 0.
			list.append(child.get_combined_minimum_size().x if child.visible else 0.0)
		return list
	var farming: Array[float] = widths.call()
	GameState.record_boss_victory(0)
	(_pips(strip)[1] as Button).pressed.emit()  # Green: no boss yet
	assert_array(widths.call()).is_equal(farming)
	(_pips(strip)[0] as Button).pressed.emit()
	for i in 60:
		GameState.record_kill(0)
	game.challenge_boss()
	game.get_encounter().advance(1.0)
	assert_array(widths.call()).is_equal(farming)
