extends GdUnitTestSuite
## Click Damage upgrade and kill payouts in the real Game scene.

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.base_click_damage = 1.0
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


func _click_upgrade(value: float, levels: int) -> UpgradeData:
	var upgrade := UpgradeData.new()
	upgrade.id = &"click"
	upgrade.effect_type = UpgradeData.EffectType.ADD_CLICK_DAMAGE
	upgrade.effect_value = value
	upgrade.cost_gold = 1.0
	upgrade.cost_growth = 1.0
	upgrade.max_level = levels
	return upgrade


func test_click_damage_starts_at_base() -> void:
	assert_float(GameState.get_click_damage()).is_equal(1.0)


func test_each_level_adds_its_value_up_to_max() -> void:
	var upgrade := _click_upgrade(0.5, 3)
	GameState.add_gold(100.0)
	for i in 3:
		assert_bool(GameState.try_purchase_upgrade(upgrade)).is_true()
	assert_bool(GameState.try_purchase_upgrade(upgrade)).is_false()
	assert_float(GameState.get_click_damage()).is_equal_approx(2.5, 0.00001)


func test_click_damage_row_is_in_the_shop() -> void:
	var row := UpgradeManager.get_definition(&"click_damage")
	assert_object(row).is_not_null()
	assert_int(row.effect_type).is_equal(UpgradeData.EffectType.ADD_CLICK_DAMAGE)


# --- In the Game scene ---------------------------------------------------------------

func _game() -> Game:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	GameState.reset_run(_config)  # Game._ready() reset to the real config
	return game


func _first_enemy(game: Game) -> EnemyBase:
	var waves := game.get_node("WaveManager") as WaveManager
	waves.spawn_wave()
	return game.get_node("World/EnemyLayer").get_child(0) as EnemyBase


func test_kill_pays_gold_once_even_if_hit_twice_in_one_frame() -> void:
	var game := _game()
	var enemy := _first_enemy(game)
	enemy.take_damage(100.0)
	enemy.take_damage(100.0)
	assert_float(GameState.get_gold()).is_equal(enemy.data.gold_drop)


func test_clicks_kill_a_leaf_for_its_gold() -> void:
	var game := _game()
	var enemy := _first_enemy(game)
	var router := game.get_node("World/ClickRouter") as ClickRouter
	var needed := ceili(enemy.data.base_health / GameState.get_click_damage())
	var gold_drop := enemy.data.gold_drop
	var spot := enemy.global_position
	for i in needed:
		assert_bool(router.route_click(spot)).is_true()
	assert_bool(enemy.can_receive_click()).is_false()
	assert_float(GameState.get_gold()).is_equal(gold_drop)
	# Once dead it takes no more clicks, so it can't pay twice.
	assert_bool(router.route_click(spot)).is_false()
	assert_float(GameState.get_gold()).is_equal(gold_drop)


func test_leaf_at_the_rim_latches_and_its_kill_unlatches() -> void:
	var game := _game()
	var enemy := _first_enemy(game)
	enemy.advance(100.0)  # far enough to reach the rim in one step
	assert_int(GameState.get_latched_count()).is_equal(1)
	assert_float(GameState.get_total_drag()).is_equal_approx(enemy.data.latch_drag, 0.00001)
	enemy.take_damage(100.0)
	assert_int(GameState.get_latched_count()).is_equal(0)
	assert_float(GameState.get_total_drag()).is_equal(0.0)


func test_overload_removes_every_enemy_without_gold() -> void:
	_config.fail_rule = RunConfig.FailRule.OVERLOAD_CLEAR
	var game := _game()
	var layer := game.get_node("World/EnemyLayer")
	(game.get_node("WaveManager") as WaveManager).spawn_wave()
	for enemy: EnemyBase in layer.get_children():
		enemy.advance(100.0)
	GameState.overloaded.emit()
	for enemy: EnemyBase in layer.get_children():
		assert_bool(enemy.is_queued_for_deletion()).is_true()
	assert_int(GameState.get_latched_count()).is_equal(0)
	assert_float(GameState.get_gold()).is_equal(0.0)
