extends GdUnitTestSuite
## Selected tier and kills per tier (Phase 3 Step 3d), and the F2/F3 dev keys.

const LEAF_SCENE: PackedScene = preload("res://scenes/enemies/Leaf.tscn")
const CATALOG: TierCatalog = preload("res://resources/tiers/tier_catalog.tres")

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


func _admitted_leaf(game: Game, tier: TierData, bearing: float = 0.0) -> EnemyBase:
	var carousel := game.get_node("World/Carousel") as Carousel
	var enemy := LEAF_SCENE.instantiate() as EnemyBase
	enemy.configure(tier, 1.0)
	enemy.position = carousel.position + Vector2.from_angle(bearing) * (carousel.radius + 80.0)
	game._on_enemy_spawned(enemy)
	game._admit_pending_spawns()
	return enemy


func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event


# --- GameState ------------------------------------------------------------------------

func test_run_starts_on_grey_with_no_kills() -> void:
	GameState.record_kill(0)
	GameState.set_selected_tier(2)
	GameState.reset_run(_config)
	assert_int(GameState.get_selected_tier()).is_equal(0)
	assert_int(GameState.get_tier_kills(0)).is_equal(0)


func test_selecting_a_tier_signals_once() -> void:
	var seen: Array[int] = []
	GameState.selected_tier_changed.connect(func(rank: int) -> void: seen.append(rank))
	GameState.set_selected_tier(1)
	GameState.set_selected_tier(1)
	GameState.set_selected_tier(-1)
	assert_array(seen).is_equal([1])


func test_each_run_gets_a_new_seed() -> void:
	var first := GameState.get_run_seed()
	GameState.reset_run(_config)
	assert_int(GameState.get_run_seed()).is_not_equal(first)


# --- Kills in the Game scene ------------------------------------------------------------

## A Green enemy killed while Grey is selected counts for Green.
func test_a_kill_counts_for_the_enemys_own_tier() -> void:
	var game := _game()
	var green := _admitted_leaf(game, CATALOG.get_tier(1))
	var grey := _admitted_leaf(game, CATALOG.get_tier(0), 2.0)
	green.take_damage(100.0)
	grey.take_damage(100.0)
	assert_int(GameState.get_tier_kills(1)).is_equal(1)
	assert_int(GameState.get_tier_kills(0)).is_equal(1)


func test_clears_and_the_safety_net_are_not_kills() -> void:
	var game := _game()
	var latched := _admitted_leaf(game, CATALOG.get_tier(0))
	latched.advance(100.0)
	GameState.add_gold(1000.0)
	assert_bool(GameState.try_emergency_clear()).is_true()
	_admitted_leaf(game, CATALOG.get_tier(0), 2.0)
	GameState.stall_timed_out.emit()
	assert_int(GameState.get_tier_kills(0)).is_equal(0)


## Switching tier changes future waves only; live enemies keep their stats.
func test_switching_tier_leaves_live_enemies_alone() -> void:
	var game := _game()
	var waves := game.get_node("WaveManager") as WaveManager
	var grey_enemy := _admitted_leaf(game, CATALOG.get_tier(0))
	var health := grey_enemy.get_max_health()
	GameState.set_selected_tier(2)
	assert_float(grey_enemy.get_max_health()).is_equal(health)
	assert_int(grey_enemy.get_tier_rank()).is_equal(0)
	assert_object(waves.tier).is_same(CATALOG.get_tier(2))
	var spawned: Array[EnemyBase] = []
	waves.enemy_spawned.connect(func(e: EnemyBase) -> void: spawned.append(e))
	waves.spawn_wave()
	for enemy in spawned:
		assert_int(enemy.get_tier_rank()).is_equal(2)


## Unlocks read kills in the selected tier: 40 Grey kills let Sticks in.
func test_grey_kills_unlock_sticks_in_grey_waves() -> void:
	var game := _game()
	var waves := game.get_node("WaveManager") as WaveManager
	assert_int(waves.tier_kills.call()).is_equal(0)
	for i in 40:
		GameState.record_kill(0)
	assert_int(waves.tier_kills.call()).is_equal(40)
	GameState.set_selected_tier(1)
	assert_int(waves.tier_kills.call()).is_equal(0)


# --- Dev keys -------------------------------------------------------------------------

func test_f3_and_f2_step_through_tiers_and_stop_at_the_ends() -> void:
	var game := _game()
	game._unhandled_input(_key(game.previous_tier_key))
	assert_int(GameState.get_selected_tier()).is_equal(0)
	for i in 10:
		game._unhandled_input(_key(game.next_tier_key))
	assert_int(GameState.get_selected_tier()).is_equal(CATALOG.tiers.size() - 1)
	game._unhandled_input(_key(game.previous_tier_key))
	assert_int(GameState.get_selected_tier()).is_equal(CATALOG.tiers.size() - 2)
