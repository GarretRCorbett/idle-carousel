extends GdUnitTestSuite
## Controller strike (Phase 4): the strike action hits the enemy nearest the
## carousel, the same as clicking it.


func _game() -> Game:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	(game.get_node("WaveManager") as WaveManager).set_auto(false)
	return game


func _leaf(game: Game, distance: float, angle: float) -> EnemyBase:
	var carousel := game.get_node("World/Carousel") as Carousel
	var data := (load("res://resources/enemies/leaf.tres") as EnemyData).duplicate() as EnemyData
	data.base_health = 100.0
	data.move_speed = 0.0
	var enemy := (load("res://scenes/enemies/Leaf.tscn") as PackedScene).instantiate() as EnemyBase
	enemy.data = data
	enemy.position = carousel.position + Vector2.from_angle(angle) * distance
	game._on_enemy_spawned(enemy)
	game._admit_pending_spawns()
	return enemy


func after_test() -> void:
	GameState.reset_run()


func test_choose_nearest_skips_nothing_and_picks_the_closest() -> void:
	var game := _game()
	var far := _leaf(game, 300.0, 0.0)
	var near := _leaf(game, 180.0, PI)
	var carousel := game.get_node("World/Carousel") as Carousel
	var enemies: Array[EnemyBase] = [far, near]
	assert_object(ClickRouter.choose_nearest(carousel.global_position, enemies)).is_same(near)
	assert_object(ClickRouter.choose_nearest(carousel.global_position, [] as Array[EnemyBase])).is_null()


func test_strike_hits_the_nearest_enemy_like_a_click() -> void:
	var game := _game()
	var far := _leaf(game, 300.0, 0.0)
	var near := _leaf(game, 180.0, PI)
	var router := game.get_node("World/ClickRouter") as ClickRouter
	var strike := InputEventAction.new()
	strike.action = &"strike"
	strike.pressed = true
	router._unhandled_input(strike)
	assert_float(near.get_health()).is_equal(100.0 - GameState.get_click_damage())
	assert_float(far.get_health()).is_equal(100.0)


func test_strike_with_no_enemies_does_nothing() -> void:
	var game := _game()
	var router := game.get_node("World/ClickRouter") as ClickRouter
	assert_bool(router.strike()).is_false()
