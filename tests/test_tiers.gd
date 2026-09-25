extends GdUnitTestSuite
## Color tiers (Phase 3 Step 3a/3c): the catalog, and enemy stats fixed at
## spawn as base × tier multiplier.

const LEAF_SCENE: PackedScene = preload("res://scenes/enemies/Leaf.tscn")
const CATALOG: TierCatalog = preload("res://resources/tiers/tier_catalog.tres")

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.latch_grace_seconds = 0.0
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


## Test fixture: a tier with round multipliers, so expected values are easy to read.
func _tier(rank: int = 1) -> TierData:
	var tier := TierData.new()
	tier.tier_id = &"test"
	tier.rank = rank
	tier.tint = Color(0.2, 0.9, 0.3)
	tier.health_multiplier = 2.0
	tier.speed_multiplier = 1.5
	tier.drag_multiplier = 3.0
	tier.latch_dps_multiplier = 4.0
	tier.gold_multiplier = 5.0
	tier.waves = CATALOG.get_tier(0).waves
	return tier


func _data() -> EnemyData:
	var data := EnemyData.new()
	data.base_health = 2.0
	data.move_speed = 100.0
	data.latch_drag = 0.1
	data.damage_per_second = 0.5
	data.gold_drop = 3.0
	data.hitbox_radius = 10.0
	data.click_radius = 20.0
	return data


func _leaf(data: EnemyData = _data()) -> EnemyBase:
	var enemy := LEAF_SCENE.instantiate() as EnemyBase
	enemy.data = data
	return enemy


# --- Catalog -------------------------------------------------------------------------

func test_catalog_has_six_tiers_in_rank_order() -> void:
	assert_int(CATALOG.tiers.size()).is_equal(6)
	assert_array(CATALOG.get_problems()).is_empty()
	var ids: Array[StringName] = []
	for tier in CATALOG.tiers:
		ids.append(tier.tier_id)
	assert_array(ids).is_equal([&"grey", &"green", &"yellow", &"orange", &"red", &"charcoal"])
	assert_object(CATALOG.get_tier(6)).is_null()
	assert_object(CATALOG.get_tier(-1)).is_null()


func test_grey_multiplies_nothing_and_tiers_only_get_harder() -> void:
	var grey := CATALOG.get_tier(0)
	for value in [grey.health_multiplier, grey.speed_multiplier, grey.drag_multiplier,
			grey.latch_dps_multiplier, grey.gold_multiplier]:
		assert_float(value).is_equal(1.0)
	for rank in range(1, CATALOG.tiers.size()):
		var tier := CATALOG.get_tier(rank)
		var lower := CATALOG.get_tier(rank - 1)
		assert_float(tier.health_multiplier).is_greater(lower.health_multiplier)
		assert_float(tier.gold_multiplier).is_greater(lower.gold_multiplier)


func test_catalog_rejects_a_rank_out_of_place() -> void:
	var catalog := TierCatalog.new()
	catalog.tiers = [_tier(1)]
	assert_array(catalog.get_problems()).is_not_empty()


func test_tier_rejects_bad_multipliers() -> void:
	var tier := _tier(0)
	assert_array(tier.get_problems()).is_empty()
	tier.health_multiplier = 0.0
	assert_array(tier.get_problems()).is_not_empty()
	tier.health_multiplier = 1.0
	tier.gold_multiplier = NAN
	assert_array(tier.get_problems()).is_not_empty()


# --- Effective stats -----------------------------------------------------------------

func test_configure_multiplies_each_stat_once() -> void:
	var enemy := _leaf()
	enemy.configure(_tier(), 1.0)
	add_child(enemy)
	auto_free(enemy)
	assert_int(enemy.get_tier_rank()).is_equal(1)
	assert_float(enemy.get_max_health()).is_equal(4.0)
	assert_float(enemy.get_health()).is_equal(4.0)
	assert_float(enemy.get_move_speed()).is_equal(150.0)
	assert_float(enemy.get_latch_drag()).is_equal_approx(0.3, 0.00001)
	assert_float(enemy.get_latch_dps()).is_equal(2.0)
	assert_float(enemy.get_kill_gold()).is_equal(15.0)
	# Hitbox and click size don't scale with tier.
	assert_float(enemy.get_hitbox_radius()).is_equal(10.0)
	assert_float(enemy.get_click_radius()).is_equal(20.0)
	# The shared data is untouched.
	assert_float(enemy.data.base_health).is_equal(2.0)


func test_early_send_bonus_goes_on_top_of_tier_gold() -> void:
	var enemy := auto_free(_leaf()) as EnemyBase
	enemy.configure(_tier(), 1.5)
	assert_float(enemy.get_kill_gold()).is_equal(3.0 * 5.0 * 1.5)


func test_unconfigured_enemy_uses_grey_stats() -> void:
	var enemy := _leaf()
	add_child(enemy)
	auto_free(enemy)
	assert_int(enemy.get_tier_rank()).is_equal(0)
	assert_float(enemy.get_max_health()).is_equal(2.0)
	assert_float(enemy.get_move_speed()).is_equal(100.0)
	assert_float(enemy.get_kill_gold()).is_equal(3.0)


func test_moves_at_the_tier_speed() -> void:
	var enemy := _leaf()
	enemy.configure(_tier(), 1.0)
	enemy.position = Vector2(300.0, 0.0)
	add_child(enemy)
	auto_free(enemy)
	enemy.setup(Vector2.ZERO, 100.0)
	enemy.advance(0.5)
	assert_vector(enemy.position).is_equal_approx(Vector2(225.0, 0.0), Vector2(0.001, 0.001))


## The tint and the hit flash live on different properties, so neither erases the other.
func test_tint_survives_the_hit_flash() -> void:
	var enemy := _leaf()
	var tier := _tier()
	enemy.configure(tier, 1.0)
	add_child(enemy)
	auto_free(enemy)
	var visual := enemy.get_node("Visual") as Node2D
	assert_object(visual.self_modulate).is_equal(tier.tint)
	enemy.take_damage(0.5)
	assert_object(visual.modulate).is_equal(enemy.hit_flash_modulate)
	assert_object(visual.self_modulate).is_equal(tier.tint)
	enemy._process(enemy.hit_flash_seconds)
	assert_object(visual.modulate).is_equal(Color.WHITE)
	assert_object(visual.self_modulate).is_equal(tier.tint)


## Memo O5 end to end: a Green Leaf sent early goes through admission, is hit,
## latches, and dies, and pays base × Green Gold × early-send bonus exactly once.
func test_green_early_sent_leaf_pays_tier_and_bonus_gold() -> void:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	GameState.reset_run(_config)
	(game.get_node("WaveManager") as WaveManager).set_auto(false)
	var green := CATALOG.get_tier(1)
	var data := load("res://resources/enemies/leaf.tres") as EnemyData
	var enemy := _leaf(data)
	enemy.configure(green, 1.5)
	var carousel := game.get_node("World/Carousel") as Carousel
	enemy.position = carousel.position + Vector2(carousel.radius + 60.0, 0.0)
	game._on_enemy_spawned(enemy)
	game._admit_pending_spawns()
	assert_float(enemy.get_health()).is_equal_approx(data.base_health * green.health_multiplier, 0.00001)
	enemy.take_damage(1.0)
	enemy.advance(100.0)  # latches
	assert_float(GameState.get_total_latch_dps()).is_equal_approx(data.damage_per_second * green.latch_dps_multiplier, 0.00001)
	enemy.take_damage(100.0)
	assert_float(GameState.get_gold()).is_equal_approx(data.gold_drop * green.gold_multiplier * 1.5, 0.00001)
