extends GdUnitTestSuite
## The five tier bosses after Leaf Storm (Phase 3 Step 7): each one's behavior
## and win rule, through the real Game and BossEncounter.

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


## Unlocks `rank`, selects it, meets its kill gate, starts the fight, admits the boss.
func _fight(game: Game, rank: int) -> EnemyBoss:
	GameState.debug_set_bosses_beaten(rank)
	assert_bool(GameState.set_selected_tier(rank) or rank == 0).is_true()
	for i in CATALOG.get_tier(rank).boss.kills_required:
		GameState.record_kill(rank)
	assert_bool(game.challenge_boss()).is_true()
	game._admit_pending_spawns()
	return game.get_encounter().get_boss()


func _role(game: Game, role: EnemyBase.EncounterRole) -> Array[EnemyBase]:
	var found: Array[EnemyBase] = []
	for child in game.get_node("World/EnemyLayer").get_children():
		var enemy := child as EnemyBase
		if enemy != null and enemy.is_active() and enemy.encounter_role == role:
			found.append(enemy)
	return found


func _center(game: Game) -> Vector2:
	return (game.get_node("World/Carousel") as Carousel).position


# --- Data -------------------------------------------------------------------------------

func test_every_tier_has_a_valid_boss() -> void:
	for tier in CATALOG.tiers:
		assert_object(tier.boss).override_failure_message(String(tier.tier_id)).is_not_null()
		assert_array(tier.boss.get_problems()).is_empty()
		var boss := tier.boss.scene.instantiate()
		assert_bool(boss is EnemyBoss).is_true()
		boss.free()
	for rank in range(1, CATALOG.tiers.size()):
		assert_int(CATALOG.get_tier(rank).boss.kills_required).is_greater(CATALOG.get_tier(rank - 1).boss.kills_required)


func test_bosses_that_fly_in_start_off_screen() -> void:
	var game := _game()
	var giant := _fight(game, 1)
	assert_float((giant.position - _center(game)).length()).is_greater(380.0)


# --- Stick Giant (Green) -------------------------------------------------------------------

func test_stick_giant_zigzags_in_and_latches_protected() -> void:
	var game := _game()
	var giant := _fight(game, 1) as EnemyStickGiant
	var bearings: Array[float] = []
	var center := _center(game)
	while giant.is_active() and not giant.is_at_rim():
		giant.advance(1.0 / 60.0)
		bearings.append((giant.position - center).angle())
	var swing := 0.0
	for b in bearings:
		swing = maxf(swing, absf(angle_difference(bearings[0], b)))
	assert_float(swing).is_greater(deg_to_rad(giant.zigzag_degrees))  # it swung both ways
	assert_bool(giant.is_at_rim()).is_true()
	assert_bool(GameState.is_latch_protected(giant.get_instance_id())).is_true()


# --- Boulder (Yellow) ----------------------------------------------------------------------

func test_boulder_rolls_faster_near_the_rim() -> void:
	var game := _game()
	var boulder := _fight(game, 2) as EnemyBoulder
	var far := boulder._speed_multiplier()
	boulder.position = _center(game) + Vector2(boulder._stop_distance + 5.0, 0.0)
	assert_float(far).is_equal(1.0)
	assert_float(boulder._speed_multiplier()).is_greater(2.0)


func test_boulder_breaks_into_three_grips_sharing_its_health() -> void:
	var game := _game()
	var boulder := _fight(game, 2) as EnemyBoulder
	boulder.take_damage(boulder.get_max_health() * 0.4)  # hits on the way in count
	var left := boulder.get_health()
	var drag_before := GameState.get_total_drag()
	while boulder.is_active():
		boulder.advance(1.0 / 60.0)
	game._admit_pending_spawns()
	game._physics_process(1.0 / 60.0)  # grips latch
	var grips := _role(game, EnemyBase.EncounterRole.REQUIRED)
	assert_int(grips.size()).is_equal(3)
	for grip in grips:
		assert_float(grip.get_max_health()).is_equal_approx(left / 3.0, 0.001)
		assert_bool(grip.is_at_rim()).is_true()
	var drag_three := GameState.get_total_drag()
	assert_float(drag_three).is_greater(drag_before)
	grips[0].take_damage(1000.0)
	assert_float(GameState.get_total_drag()).is_less(drag_three)  # drag drops as grips break
	assert_bool(GameState.is_boss_active()).is_true()
	grips[1].take_damage(1000.0)
	grips[2].take_damage(1000.0)
	assert_bool(GameState.is_boss_active()).is_false()
	assert_int(GameState.get_bosses_beaten()).is_equal(3)


func test_boulder_killed_before_the_rim_wins_outright() -> void:
	var game := _game()
	var boulder := _fight(game, 2)
	boulder.take_damage(1000000.0)
	game._admit_pending_spawns()
	assert_int(_role(game, EnemyBase.EncounterRole.REQUIRED).size()).is_equal(0)
	assert_bool(GameState.is_boss_active()).is_false()


# --- Gilded Gale (Orange) ------------------------------------------------------------------

func test_gilded_gale_trickles_two_leaves_every_few_seconds() -> void:
	var game := _game()
	var gale := _fight(game, 3) as EnemyLeafStorm
	var cycle := gale.gust_seconds + gale.drift_seconds + gale.rest_seconds
	assert_float(cycle).is_less_equal(5.0)
	for i in roundi((gale.quiet_seconds + gale.gust_seconds + cycle * 3.0) * 60.0) + 10:
		gale.advance(1.0 / 60.0)
	assert_int(gale.get_packs_sent()).is_equal(4)
	game._admit_pending_spawns()
	var summons := _role(game, EnemyBase.EncounterRole.SUMMON)
	assert_int(summons.size()).is_equal(8)
	for leaf in summons:
		assert_int(leaf.get_tier_rank()).is_equal(3)  # Orange Leaves
	gale.take_damage(1000000.0)  # no split: killing it wins
	assert_bool(GameState.is_boss_active()).is_false()


# --- Ancient Log (Red) ------------------------------------------------------------------------

func test_ancient_log_blunts_its_first_three_hits_and_ignores_slow() -> void:
	var game := _game()
	var log := _fight(game, 4) as EnemyAncientLog
	var health := log.get_health()
	for i in 3:
		log.take_damage(4.0)
	assert_float(health - log.get_health()).is_equal_approx(3.0 * 4.0 * log.armor_damage_multiplier, 0.0001)
	assert_int(log.get_armor_left()).is_equal(0)
	health = log.get_health()
	log.take_damage(4.0)
	assert_float(health - log.get_health()).is_equal_approx(4.0, 0.0001)
	log.apply_slow(0.5, 3.0)
	assert_bool(log.is_slowed()).is_false()


# --- Obsidian Boulder (Charcoal) ------------------------------------------------------------

func test_obsidian_boulder_splits_into_two_red_rocks_that_must_die() -> void:
	var game := _game()
	var obsidian := _fight(game, 5)
	obsidian.take_damage(1000000.0)
	game._admit_pending_spawns()
	var pieces := _role(game, EnemyBase.EncounterRole.REQUIRED)
	assert_int(pieces.size()).is_equal(2)
	for rock in pieces:
		assert_int(rock.get_tier_rank()).is_equal(4)  # Red
	assert_bool(GameState.is_boss_active()).is_true()
	for rock in pieces:
		rock.take_damage(1000000.0)
	assert_bool(GameState.is_boss_active()).is_false()
	assert_int(GameState.get_bosses_beaten()).is_equal(6)
