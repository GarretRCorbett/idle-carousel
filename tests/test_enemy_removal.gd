extends GdUnitTestSuite
## Removal is a state (Phase 3 Step 2e/2f): every way an enemy leaves, spawns
## that join at the next tick, kill attribution, and the Send limit counting
## the spawn queue. All through the real Game scene.

const LEAF_SCENE: PackedScene = preload("res://scenes/enemies/Leaf.tscn")

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.latch_grace_seconds = 0.0
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


## A Leaf `gap` px outside the rim at `bearing`, not yet admitted.
func _leaf(game: Game, bearing: float = 0.0, gap: float = 100.0, health: float = 2.0) -> EnemyBase:
	var carousel := game.get_node("World/Carousel") as Carousel
	var data := (load("res://resources/enemies/leaf.tres") as EnemyData).duplicate() as EnemyData
	data.base_health = health
	var enemy := LEAF_SCENE.instantiate() as EnemyBase
	enemy.data = data
	enemy.position = carousel.position + Vector2.from_angle(bearing) * (carousel.radius + data.hitbox_radius + gap)
	game._on_enemy_spawned(enemy)
	return enemy


func _admitted_leaf(game: Game, bearing: float = 0.0, gap: float = 100.0, health: float = 2.0) -> EnemyBase:
	var enemy := _leaf(game, bearing, gap, health)
	game._admit_pending_spawns()
	return enemy


func _layer(game: Game) -> Node:
	return game.get_node("World/EnemyLayer")


# --- Removal paths --------------------------------------------------------------------

func test_a_killed_enemy_is_removed_and_inert() -> void:
	var game := _game()
	var enemy := _admitted_leaf(game)
	var deaths: Array[int] = [0]
	enemy.died.connect(func(_e: EnemyBase, _k: Node) -> void: deaths[0] += 1)
	var start := enemy.position
	assert_bool(enemy.take_damage(100.0)).is_true()
	assert_bool(enemy.is_removed()).is_true()
	assert_bool(enemy.is_active()).is_false()
	assert_bool(enemy.take_damage(100.0)).is_false()
	enemy.advance(10.0)
	assert_vector(enemy.position).is_equal(start)
	assert_int(deaths[0]).is_equal(1)
	assert_int(game.get_live_enemy_count()).is_equal(0)


func test_emergency_clear_removes_once() -> void:
	var game := _game()
	var enemy := _admitted_leaf(game)
	enemy.advance(100.0)
	GameState.add_gold(1000.0)
	assert_bool(GameState.try_emergency_clear()).is_true()
	assert_bool(enemy.is_removed()).is_true()
	assert_int(game.get_live_enemy_count()).is_equal(0)
	game._remove_enemy(enemy)  # a second removal changes nothing
	assert_int(game.get_live_enemy_count()).is_equal(0)


func test_stall_safety_net_removes_every_active_enemy() -> void:
	var game := _game()
	var latched := _admitted_leaf(game, 0.0)
	var flying := _admitted_leaf(game, 2.0)
	latched.advance(100.0)
	GameState.stall_timed_out.emit()
	assert_bool(latched.is_removed()).is_true()
	assert_bool(flying.is_removed()).is_true()
	assert_int(game.get_live_enemy_count()).is_equal(0)
	assert_float(GameState.get_gold()).is_equal(0.0)


## Killing a latched enemy unregisters its latch, which sends signals. A
## listener that pokes the enemy then finds it already removed: no second
## kill, no extra Gold, no double count.
func test_listener_touching_the_enemy_during_cleanup_does_nothing() -> void:
	var game := _game()
	var enemy := _admitted_leaf(game)
	enemy.advance(100.0)
	var router := game.get_node("World/ClickRouter") as ClickRouter
	var deaths: Array[int] = [0]
	enemy.died.connect(func(_e: EnemyBase, _k: Node) -> void: deaths[0] += 1)
	var poked: Array[bool] = [false, false, false]  # poked, took damage, clicked
	var poke := func(_n: int) -> void:
		if poked[0]:
			return
		poked[0] = true
		poked[1] = enemy.take_damage(100.0)
		poked[2] = router.route_click(enemy.global_position)
		game._remove_enemy(enemy)
	GameState.latch_count_changed.connect(poke)
	assert_bool(enemy.take_damage(100.0)).is_true()
	GameState.latch_count_changed.disconnect(poke)
	assert_bool(poked[0]).is_true()
	assert_bool(poked[1]).is_false()
	assert_bool(poked[2]).is_false()
	assert_int(deaths[0]).is_equal(1)
	assert_float(GameState.get_gold()).is_equal(enemy.data.gold_drop)
	assert_int(game.get_live_enemy_count()).is_equal(0)


# --- Spawns join at the next tick -------------------------------------------------------

func test_spawn_waits_for_the_next_tick() -> void:
	var game := _game()
	var enemy := _leaf(game)
	assert_bool(enemy.is_inside_tree()).is_false()
	assert_int(game.get_live_enemy_count()).is_equal(1)  # counted while waiting
	var start := enemy.position
	game._physics_process(1.0 / 60.0)
	assert_object(enemy.get_parent()).is_same(_layer(game))
	assert_bool(enemy.position.is_equal_approx(start)).is_false()  # it moves in the tick it joins


## An enemy spawned in the middle of a tick (here: while the carousel turns and
## mounts sweep) doesn't join, move, or get hit until the next tick.
func test_enemy_spawned_mid_tick_joins_next_tick() -> void:
	var game := _game()
	var carousel := game.get_node("World/Carousel") as Carousel
	var late: Array[EnemyBase] = []
	var spawn_once := func(_p: float, _d: float) -> void:
		if late.is_empty():
			late.append(_leaf(game, 1.0))
	carousel.rotation_advanced.connect(spawn_once)
	game._physics_process(1.0 / 60.0)
	carousel.rotation_advanced.disconnect(spawn_once)
	assert_int(late.size()).is_equal(1)
	assert_bool(late[0].is_inside_tree()).is_false()
	var start := late[0].position
	game._physics_process(1.0 / 60.0)
	assert_bool(late[0].is_inside_tree()).is_true()
	assert_bool(late[0].position.is_equal_approx(start)).is_false()


## Spawned while a batch is being admitted: waits for the batch after.
func test_spawn_during_admission_waits_one_more_tick() -> void:
	var game := _game()
	var late: Array[EnemyBase] = []
	var spawn_once := func(_n: Node) -> void:
		if late.is_empty():
			late.append(_leaf(game, 2.0))
	_layer(game).child_entered_tree.connect(spawn_once)
	_leaf(game)
	game._admit_pending_spawns()
	_layer(game).child_entered_tree.disconnect(spawn_once)
	assert_int(late.size()).is_equal(1)
	assert_bool(late[0].is_inside_tree()).is_false()
	game._admit_pending_spawns()
	assert_bool(late[0].is_inside_tree()).is_true()


func test_waiting_spawns_are_freed_on_a_new_run() -> void:
	var game := _game()
	var enemy := _leaf(game)
	GameState.reset_run(_config)
	assert_bool(is_instance_valid(enemy)).is_false()
	assert_int(game.get_live_enemy_count()).is_equal(0)


# --- Send limit counts the queue -------------------------------------------------------

func test_repeated_sends_in_one_tick_respect_the_limit() -> void:
	var game := _game()
	var waves := game.get_node("WaveManager") as WaveManager
	waves.max_live_enemies_to_send = 6
	var sends := 0
	for i in 10:
		if waves.send_wave_now() > 0:
			sends += 1
	# Nothing was admitted, but the queue counts: once past 6, sends stop.
	assert_int(sends).is_between(1, 3)
	assert_bool(waves.can_send_wave()).is_false()
	assert_int(game.get_live_enemy_count()).is_greater(6)


func test_removed_enemies_stop_counting_at_once() -> void:
	var game := _game()
	var enemy := _admitted_leaf(game)
	assert_int(game.get_live_enemy_count()).is_equal(1)
	game._remove_enemy(enemy)
	assert_bool(enemy.is_inside_tree()).is_true()  # freed at the end of the frame
	assert_int(game.get_live_enemy_count()).is_equal(0)


# --- Kill attribution ----------------------------------------------------------------

func test_wolf_kill_reports_the_wolf_and_click_kill_reports_null() -> void:
	var game := _game()
	GameState.add_gold(10000.0)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"wolf")
	var wolf: MountBase = game.get_node("World/Carousel/MountSlots").get_child(1)
	var killers: Array = []
	var by_wolf := _admitted_leaf(game, 0.0, 100.0, 0.1)
	var by_click := _admitted_leaf(game, 2.0, 100.0, 0.1)
	by_wolf.died.connect(func(_e: EnemyBase, k: Node) -> void: killers.append(k))
	by_click.died.connect(func(_e: EnemyBase, k: Node) -> void: killers.append(k))
	game._on_enemy_swept(wolf, by_wolf)
	game._on_enemy_clicked(by_click)
	assert_int(killers.size()).is_equal(2)
	assert_object(killers[0]).is_same(wolf)
	assert_object(killers[1]).is_null()
