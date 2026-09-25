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
	GameState.debug_set_bosses_beaten(2)
	GameState.set_selected_tier(2)
	GameState.record_boss_victory(2)
	GameState.reset_run(_config)
	assert_int(GameState.get_bosses_beaten()).is_equal(0)
	assert_int(GameState.get_selected_tier()).is_equal(0)
	assert_int(GameState.get_tier_kills(0)).is_equal(0)


func test_selecting_a_tier_signals_once() -> void:
	var seen: Array[int] = []
	GameState.selected_tier_changed.connect(func(rank: int) -> void: seen.append(rank))
	GameState.debug_set_bosses_beaten(1)
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
	GameState.debug_set_bosses_beaten(2)
	GameState.set_selected_tier(2)
	assert_float(grey_enemy.get_max_health()).is_equal(health)
	assert_int(grey_enemy.get_tier_rank()).is_equal(0)
	assert_object(waves.tier).is_same(CATALOG.get_tier(2))
	var spawned: Array[EnemyBase] = []
	waves.enemy_spawned.connect(func(e: EnemyBase) -> void: spawned.append(e))
	waves.spawn_wave()
	for enemy in spawned:
		assert_int(enemy.get_tier_rank()).is_equal(2)


## Unlocks read kills in the selected tier (Grey kills let Sticks into Grey waves).
func test_grey_kills_unlock_sticks_in_grey_waves() -> void:
	var game := _game()
	var waves := game.get_node("WaveManager") as WaveManager
	assert_int(waves.tier_kills.call()).is_equal(0)
	for i in 40:
		GameState.record_kill(0)
	assert_int(waves.tier_kills.call()).is_equal(40)
	GameState.debug_set_bosses_beaten(1)
	GameState.set_selected_tier(1)
	assert_int(waves.tier_kills.call()).is_equal(0)


# --- Unlocks and boss progress ----------------------------------------------------------

func test_locked_tiers_and_fights_refuse_switching() -> void:
	assert_bool(GameState.is_tier_unlocked(0)).is_true()
	assert_bool(GameState.is_tier_unlocked(1)).is_false()
	assert_bool(GameState.set_selected_tier(1)).is_false()
	assert_bool(GameState.record_boss_victory(0)).is_true()  # first clear unlocks Green
	assert_bool(GameState.set_selected_tier(1)).is_true()
	GameState.set_boss_active(true)
	assert_bool(GameState.set_selected_tier(0)).is_false()
	GameState.set_boss_active(false)
	assert_bool(GameState.set_selected_tier(0)).is_true()


func test_first_clear_unlocks_once_and_records_the_time() -> void:
	GameState.advance_simulation(12.5)
	var seen: Array = []
	GameState.boss_beaten.connect(func(rank: int, first: bool) -> void: seen.append([rank, first]))
	assert_bool(GameState.record_boss_victory(0)).is_true()
	assert_bool(GameState.record_boss_victory(0)).is_false()  # a repeat
	assert_int(GameState.get_bosses_beaten()).is_equal(1)
	assert_bool(GameState.is_boss_beaten(0)).is_true()
	assert_float(GameState.get_boss_clear_time(0)).is_equal_approx(12.5, 0.001)
	assert_float(GameState.get_boss_clear_time(1)).is_equal(-1.0)
	assert_array(seen).is_equal([[0, true], [0, false]])


func test_kills_signal_for_the_strip() -> void:
	var seen: Array = []
	GameState.tier_kills_changed.connect(func(rank: int, kills: int) -> void: seen.append([rank, kills]))
	GameState.record_kill(0)
	GameState.record_kill(0)
	assert_array(seen).is_equal([[0, 1], [0, 2]])


## During a fight a stall never times out (the safety net would remove the boss).
func test_no_safety_net_during_a_boss_fight() -> void:
	var timed_out: Array[bool] = [false]
	GameState.stall_timed_out.connect(func() -> void: timed_out[0] = true)
	GameState.set_boss_active(true)
	GameState.register_latch(1, 0.0, 1000.0)
	for i in 200:
		GameState.advance_simulation(1.0)
	assert_bool(GameState.is_stalled()).is_true()
	assert_bool(timed_out[0]).is_false()


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
