extends GdUnitTestSuite
## The first boss fight (Phase 3 Step 6): kill gate, timer, Leaf Storm's packs
## and split, rewards (first vs repeat), giving up, and what's protected.

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


func _meet_kill_gate() -> void:
	for i in CATALOG.get_tier(0).boss.kills_required:
		GameState.record_kill(0)


## Starts the fight and admits the Storm.
func _fight(game: Game) -> EnemyLeafStorm:
	_meet_kill_gate()
	assert_bool(game.challenge_boss()).is_true()
	game._admit_pending_spawns()
	return game.get_encounter().get_boss() as EnemyLeafStorm


func _encounter_enemies(game: Game, role: EnemyBase.EncounterRole) -> Array[EnemyBase]:
	var found: Array[EnemyBase] = []
	for child in game.get_node("World/EnemyLayer").get_children():
		var enemy := child as EnemyBase
		if enemy != null and enemy.is_active() and enemy.encounter_role == role:
			found.append(enemy)
	return found


# --- Starting ---------------------------------------------------------------------------

func test_challenge_needs_the_kill_gate() -> void:
	var game := _game()
	assert_bool(game.challenge_boss()).is_false()
	_meet_kill_gate()
	assert_bool(game.challenge_boss()).is_true()
	assert_bool(GameState.is_boss_active()).is_true()
	assert_bool(game.challenge_boss()).is_false()  # one at a time


func test_a_fight_pauses_waves_and_tier_switching() -> void:
	var game := _game()
	var waves := game.get_node("WaveManager") as WaveManager
	GameState.record_boss_victory(0)
	_fight(game)
	assert_bool(waves.is_suspended()).is_true()
	assert_bool(waves.can_send_wave()).is_false()
	assert_int(waves.send_wave_now()).is_equal(0)
	assert_bool(GameState.set_selected_tier(1)).is_false()
	game.give_up_boss()
	assert_bool(waves.is_suspended()).is_false()
	assert_bool(GameState.set_selected_tier(1)).is_true()


# --- Leaf Storm ---------------------------------------------------------------------------

func test_storm_drifts_on_its_path_and_never_latches() -> void:
	var game := _game()
	var storm := _fight(game)
	var carousel := game.get_node("World/Carousel") as Carousel
	for i in 60 * 30:  # half a minute
		storm.advance(1.0 / 60.0)
		assert_float((storm.position - carousel.position).length()).is_equal_approx(storm.path_radius, 0.01)
	assert_bool(storm.is_at_rim()).is_false()
	assert_bool(storm.is_active()).is_true()


func test_storm_warns_then_throws_packs_of_summons() -> void:
	var game := _game()
	var storm := _fight(game)
	for i in roundi(storm.quiet_seconds * 60.0) + 1:
		storm.advance(1.0 / 60.0)
	assert_int(storm.get_phase()).is_equal(EnemyLeafStorm.Phase.GUST)
	assert_int(storm.get_packs_sent()).is_equal(0)
	for i in roundi(storm.gust_seconds * 60.0) + 1:
		storm.advance(1.0 / 60.0)
	assert_int(storm.get_packs_sent()).is_equal(1)
	game._admit_pending_spawns()
	assert_int(_encounter_enemies(game, EnemyBase.EncounterRole.SUMMON).size()).is_equal(storm.first_pack_size)
	assert_int(storm.pack_size).is_greater_equal(18)  # Garret: packs of about 20


func test_summons_are_capped() -> void:
	var game := _game()
	game.get_encounter().max_summons = 5
	var storm := _fight(game)
	storm._throw_pack()
	storm._throw_pack()
	game._admit_pending_spawns()
	assert_int(_encounter_enemies(game, EnemyBase.EncounterRole.SUMMON).size()).is_equal(5)


func test_summons_pay_nothing_and_do_not_count_as_kills() -> void:
	var game := _game()
	var storm := _fight(game)
	storm._throw_pack()
	game._admit_pending_spawns()
	var gold := GameState.get_gold()
	var kills := GameState.get_tier_kills(0)
	for summon in _encounter_enemies(game, EnemyBase.EncounterRole.SUMMON):
		summon.take_damage(100.0)
	assert_float(GameState.get_gold()).is_equal(gold)
	assert_int(GameState.get_tier_kills(0)).is_equal(kills)


# --- Winning -----------------------------------------------------------------------------

## Kills the Storm and then its four split Leaves.
func _win(game: Game, storm: EnemyLeafStorm) -> void:
	storm.take_damage(1000.0)
	assert_int(game.get_encounter().get_phase()).is_equal(BossEncounter.Phase.CLEANUP)
	game._admit_pending_spawns()
	var required := _encounter_enemies(game, EnemyBase.EncounterRole.REQUIRED)
	assert_int(required.size()).is_equal(storm.split_count)
	for leaf in required:
		leaf.take_damage(1000.0)


func test_first_win_pays_big_and_unlocks_the_next_tier() -> void:
	var game := _game()
	var storm := _fight(game)
	storm._throw_pack()
	game._admit_pending_spawns()
	var gold := GameState.get_gold()
	_win(game, storm)
	var boss := CATALOG.get_tier(0).boss
	assert_float(GameState.get_gold() - gold).is_equal(boss.first_clear_gold)
	assert_int(GameState.get_bosses_beaten()).is_equal(1)
	assert_bool(GameState.is_tier_unlocked(1)).is_true()
	assert_bool(GameState.is_boss_active()).is_false()
	assert_int(_encounter_enemies(game, EnemyBase.EncounterRole.SUMMON).size()).is_equal(0)  # leftovers cleared


func test_repeat_win_pays_the_smaller_reward_without_new_kills() -> void:
	var game := _game()
	_win(game, _fight(game))
	var gold := GameState.get_gold()
	assert_bool(game.challenge_boss()).is_true()  # no new kill gate for a re-fight
	game._admit_pending_spawns()
	_win(game, game.get_encounter().get_boss() as EnemyLeafStorm)
	assert_float(GameState.get_gold() - gold).is_equal(CATALOG.get_tier(0).boss.repeat_clear_gold)
	assert_int(GameState.get_bosses_beaten()).is_equal(1)


# --- Ending without a win ----------------------------------------------------------------

func test_timeout_removes_the_fight_and_keeps_progress() -> void:
	var game := _game()
	var storm := _fight(game)
	storm._throw_pack()
	var kills := GameState.get_tier_kills(0)
	var ended: Array = []
	game.get_encounter().ended.connect(func(victory: bool, _first: bool) -> void: ended.append(victory))
	game.get_encounter().advance(CATALOG.get_tier(0).boss.time_limit_seconds + 0.1)
	assert_array(ended).is_equal([false])
	assert_bool(storm.is_removed()).is_true()
	assert_int(_encounter_enemies(game, EnemyBase.EncounterRole.SUMMON).size()).is_equal(0)
	assert_int(GameState.get_tier_kills(0)).is_equal(kills)
	assert_int(GameState.get_bosses_beaten()).is_equal(0)
	assert_bool(game.challenge_boss()).is_true()  # retry is free


func test_emergency_clear_leaves_required_split_leaves() -> void:
	var game := _game()
	var storm := _fight(game)
	storm.take_damage(1000.0)
	game._admit_pending_spawns()
	var required := _encounter_enemies(game, EnemyBase.EncounterRole.REQUIRED)
	for leaf in required:
		leaf.advance(1000.0)  # latch
	assert_bool(required[0].is_at_rim()).is_true()
	GameState.add_gold(1000.0)
	assert_bool(GameState.can_emergency_clear()).is_false()  # nothing it's allowed to clear
	var normal := (load("res://scenes/enemies/Leaf.tscn") as PackedScene).instantiate() as EnemyBase
	normal.position = (game.get_node("World/Carousel") as Carousel).position + Vector2(300.0, 0.0)
	game._on_enemy_spawned(normal)
	game._admit_pending_spawns()
	normal.advance(1000.0)
	assert_bool(GameState.try_emergency_clear()).is_true()
	assert_bool(normal.is_removed()).is_true()
	for leaf in required:
		assert_bool(leaf.is_active()).is_true()


# --- Clicking -----------------------------------------------------------------------------

## A click inside the Storm's body hits the Storm even with a Leaf right on top.
func test_click_in_the_storm_hits_the_storm() -> void:
	var game := _game()
	var storm := _fight(game)
	var leaf := (load("res://scenes/enemies/Leaf.tscn") as PackedScene).instantiate() as EnemyBase
	leaf.position = storm.position + Vector2(4.0, 0.0)
	game._on_enemy_spawned(leaf)
	game._admit_pending_spawns()
	var router := game.get_node("World/ClickRouter") as ClickRouter
	var health := storm.get_health()
	assert_bool(router.route_click(storm.global_position + Vector2(4.0, 0.0))).is_true()
	assert_float(storm.get_health()).is_less(health)
	assert_float(leaf.get_health()).is_equal(leaf.get_max_health())
