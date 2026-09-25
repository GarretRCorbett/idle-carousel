extends GdUnitTestSuite
## Mount tiers (Phase 3 Step 5b): per type, Tier 2 multipliers from MountData,
## applied through GameState's getters to every mount of the type.

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


func _mounts(game: Game) -> Array[MountBase]:
	var mounts: Array[MountBase] = []
	for child in game.get_node("World/Carousel/MountSlots").get_children():
		if child is MountBase and not child.is_queued_for_deletion():
			mounts.append(child)
	return mounts


func _data(id: String) -> MountData:
	return load("res://resources/mounts/%s.tres" % id) as MountData


func test_types_start_at_tier_1_and_reset_with_the_run() -> void:
	GameState.add_gold(10000.0)
	UpgradeManager.purchase(&"horse_tier2")
	assert_int(GameState.get_mount_tier(&"horse")).is_equal(2)
	assert_int(GameState.get_mount_tier(&"wolf")).is_equal(1)
	GameState.reset_run(_config)
	assert_int(GameState.get_mount_tier(&"horse")).is_equal(1)


func test_tier_rows_need_their_mount_except_the_horse() -> void:
	GameState.add_gold(10000.0)
	assert_bool(UpgradeManager.purchase(&"wolf_tier2")).is_false()
	assert_bool(UpgradeManager.purchase(&"horse_tier2")).is_true()  # the starting Horse counts
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"wolf")
	assert_bool(UpgradeManager.purchase(&"wolf_tier2")).is_true()
	assert_bool(UpgradeManager.purchase(&"wolf_tier2")).is_false()  # one level for now


func test_tier_2_applies_each_multiplier_once() -> void:
	var wolf := _data("wolf")
	var giraffe := _data("giraffe")
	var sloth := _data("sloth")
	var elephant := _data("elephant")
	var horse := _data("horse")
	var before := [GameState.get_mount_damage(wolf), GameState.get_mount_reach(giraffe),
			GameState.get_mount_slow_seconds(sloth), GameState.get_mount_arc(elephant), GameState.get_mount_gold(horse)]
	# The rows need their mount owned (tested above), so set the tiers directly.
	for id: StringName in [&"wolf", &"giraffe", &"sloth", &"elephant", &"horse"]:
		GameState._mount_tiers[id] = 2
	assert_float(GameState.get_mount_damage(wolf)).is_equal_approx(before[0] * wolf.tier2_damage_multiplier, 0.0001)
	assert_float(GameState.get_mount_reach(giraffe)).is_equal_approx(before[1] * giraffe.tier2_reach_multiplier, 0.0001)
	assert_float(GameState.get_mount_slow_seconds(sloth)).is_equal_approx(before[2] * sloth.tier2_slow_seconds_multiplier, 0.0001)
	assert_float(GameState.get_mount_arc(elephant)).is_equal_approx(before[3] * elephant.tier2_arc_multiplier, 0.0001)
	assert_float(GameState.get_mount_gold(horse)).is_equal_approx(before[4] * horse.tier2_gold_multiplier, 0.0001)
	# Each has a real effect.
	for value: float in [wolf.tier2_damage_multiplier, giraffe.tier2_reach_multiplier, sloth.tier2_slow_seconds_multiplier,
			elephant.tier2_arc_multiplier, horse.tier2_gold_multiplier]:
		assert_float(value).is_greater(1.0)


## Wolf Tier 2 reaches Wolves already on the carousel and ones bought later.
func test_wolf_tier_2_reaches_every_wolf() -> void:
	var game := _game()
	GameState.add_gold(10000.0)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"wolf")
	UpgradeManager.purchase(&"wolf_tier2")
	UpgradeManager.purchase(&"wolf")
	var wolves := _mounts(game).filter(func(m: MountBase) -> bool: return m.data.mount_id == &"wolf")
	assert_int(wolves.size()).is_equal(2)
	var expected := _data("wolf").base_damage * _data("wolf").tier2_damage_multiplier
	for wolf: MountBase in wolves:
		assert_float(GameState.get_mount_damage(wolf.data)).is_equal_approx(expected, 0.0001)


func test_horse_tier_2_doubles_booth_gold() -> void:
	var game := _game()
	GameState.add_gold(10000.0)
	UpgradeManager.purchase(&"horse_tier2")
	var horse := _mounts(game)[0]
	var gold := GameState.get_gold()
	game._on_booth_passed(horse, 0, 1)
	assert_float(GameState.get_gold() - gold).is_equal_approx(_data("horse").base_gold_bonus * 2.0, 0.0001)


## A longer reach doesn't give a free hit on an enemy that's under the line
## the moment the upgrade lands.
func test_giraffe_tier_2_reach_gives_no_free_hit() -> void:
	var game := _game()
	GameState.add_gold(10000.0)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"giraffe")
	var giraffe := _mounts(game)[1]
	var carousel := game.get_node("World/Carousel") as Carousel
	# Straight out from the Giraffe (bottom), past its 325 px, inside 75 + 375 = 450.
	var data := (load("res://resources/enemies/leaf.tres") as EnemyData).duplicate() as EnemyData
	data.base_health = 100.0
	data.move_speed = 0.0
	var enemy := (load("res://scenes/enemies/Leaf.tscn") as PackedScene).instantiate() as EnemyBase
	enemy.data = data
	enemy.position = carousel.position + Vector2.from_angle(giraffe.get_slot_angle()) * 380.0
	game._on_enemy_spawned(enemy)
	game._admit_pending_spawns()
	UpgradeManager.purchase(&"giraffe_tier2")
	carousel.advance_rotation(1.0 / 60.0, 0.1)
	assert_float(enemy.get_health()).is_equal(100.0)
