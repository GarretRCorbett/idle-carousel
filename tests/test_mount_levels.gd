extends GdUnitTestSuite
## Mount levels and stars (GDD v1.17, Phase 4 Step 5): one track per mount
## type (levels 1-3, the ★2 star-up, levels 4-6), shared by every mount of the
## type and applied through GameState's getters.

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.latch_grace_seconds = 0.0
	GameState.reset_run(_config)
	GameState.debug_set_bosses_beaten(6)  # the star-up waits for the first boss


func after_test() -> void:
	GameState.reset_run()


func _game() -> Game:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	GameState.reset_run(_config)
	GameState.debug_set_bosses_beaten(6)
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


## Buys on the track, set directly (the rows need their mount owned; tested below).
func _set_track(id: StringName, buys: int) -> void:
	GameState._mount_track[id] = buys


func test_types_start_at_level_0_star_1_and_reset_with_the_run() -> void:
	GameState.add_gold(100000.0)
	UpgradeManager.purchase(&"horse_level")
	assert_int(GameState.get_mount_level(&"horse")).is_equal(1)
	assert_int(GameState.get_mount_star(&"horse")).is_equal(1)
	assert_int(GameState.get_mount_level(&"wolf")).is_equal(0)
	GameState.reset_run(_config)
	assert_int(GameState.get_mount_level(&"horse")).is_equal(0)


func test_tracks_need_their_mount_except_the_horse() -> void:
	GameState.add_gold(100000.0)
	assert_bool(UpgradeManager.purchase(&"wolf_level")).is_false()
	assert_bool(UpgradeManager.purchase(&"horse_level")).is_true()  # the starting Horse counts
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"wolf")
	assert_bool(UpgradeManager.purchase(&"wolf_level")).is_true()


func test_the_star_up_waits_for_the_first_boss() -> void:
	GameState.reset_run(_config)
	GameState.add_gold(100000.0)
	for i in 3:
		assert_bool(UpgradeManager.purchase(&"horse_level")).is_true()
	assert_bool(UpgradeManager.purchase(&"horse_level")).is_false()
	GameState.record_boss_victory(0)
	assert_bool(UpgradeManager.purchase(&"horse_level")).is_true()
	assert_int(GameState.get_mount_star(&"horse")).is_equal(2)


func test_levels_then_star_then_levels_4_to_6() -> void:
	GameState.add_gold(1000000.0)
	var levels: Array[int] = []
	var stars: Array[int] = []
	for i in 7:
		assert_bool(UpgradeManager.purchase(&"horse_level")).is_true()
		levels.append(GameState.get_mount_level(&"horse"))
		stars.append(GameState.get_mount_star(&"horse"))
	assert_array(levels).is_equal([1, 2, 3, 3, 4, 5, 6])
	assert_array(stars).is_equal([1, 1, 1, 2, 2, 2, 2])
	assert_bool(UpgradeManager.purchase(&"horse_level")).is_false()  # full track


func test_the_star_up_has_its_own_price() -> void:
	var track := UpgradeManager.get_definition(&"wolf_level")
	var levels := [track.get_cost_for_level(0), track.get_cost_for_level(1), track.get_cost_for_level(2)]
	assert_float(levels[1]).is_greater(levels[0])
	assert_float(track.get_cost_for_level(UpgradeData.STAR_BUY)).is_equal(track.star_cost)
	# Levels 4-6 carry on the level curve: level 4 costs what a 4th level would have.
	assert_float(track.get_cost_for_level(4)).is_equal(roundf(track.cost_gold * pow(track.cost_growth, 3)))


func test_each_level_adds_its_bonus() -> void:
	var wolf := _data("wolf")
	var giraffe := _data("giraffe")
	var sloth := _data("sloth")
	var elephant := _data("elephant")
	var horse := _data("horse")
	var panda := _data("panda")
	for id: StringName in [&"wolf", &"giraffe", &"sloth", &"elephant", &"horse", &"panda"]:
		_set_track(id, 2)
	assert_float(GameState.get_mount_damage(wolf)).is_equal_approx(wolf.base_damage + 2.0 * wolf.level_damage_bonus, 0.0001)
	assert_float(GameState.get_mount_reach(giraffe)).is_equal_approx(giraffe.sweep_range * (1.0 + 2.0 * giraffe.level_reach_bonus), 0.0001)
	assert_float(GameState.get_mount_slow_seconds(sloth)).is_equal_approx(
			sloth.slow_seconds * (1.0 + 2.0 * sloth.level_slow_seconds_bonus), 0.0001)
	assert_float(GameState.get_mount_arc(elephant)).is_equal_approx(elephant.sweep_arc * (1.0 + 2.0 * elephant.level_arc_bonus), 0.0001)
	assert_float(GameState.get_mount_gold(horse)).is_equal_approx(horse.base_gold_bonus * (1.0 + 2.0 * horse.level_gold_bonus), 0.0001)
	assert_float(GameState.get_mount_gold_per_turn(panda)).is_equal_approx(panda.gold_per_turn * (1.0 + 2.0 * panda.level_gold_bonus), 0.0001)
	assert_float(GameState.get_mount_heal(panda)).is_equal_approx(panda.heal_per_kill * (1.0 + 2.0 * panda.level_heal_bonus), 0.0001)
	# Each level does something.
	for value: float in [wolf.level_damage_bonus, giraffe.level_reach_bonus, sloth.level_slow_seconds_bonus,
			elephant.level_arc_bonus, horse.level_gold_bonus, panda.level_gold_bonus, panda.level_heal_bonus]:
		assert_float(value).is_greater(0.0)


func test_star_2_applies_each_multiplier_once() -> void:
	var wolf := _data("wolf")
	var giraffe := _data("giraffe")
	var sloth := _data("sloth")
	var elephant := _data("elephant")
	var horse := _data("horse")
	for id: StringName in [&"wolf", &"giraffe", &"sloth", &"elephant", &"horse"]:
		_set_track(id, 3)
	var before := [GameState.get_mount_damage(wolf), GameState.get_mount_damage(giraffe),
			GameState.get_mount_slow_seconds(sloth), GameState.get_mount_arc(elephant), GameState.get_mount_gold(horse)]
	for id: StringName in [&"wolf", &"giraffe", &"sloth", &"elephant", &"horse"]:
		_set_track(id, UpgradeData.STAR_BUY + 1)  # the star-up adds no level
	assert_float(GameState.get_mount_damage(wolf)).is_equal_approx(before[0] * wolf.star2_damage_multiplier, 0.0001)
	# Giraffe ★2 hits harder (GDD), its reach comes from levels.
	assert_float(GameState.get_mount_damage(giraffe)).is_equal_approx(before[1] * giraffe.star2_damage_multiplier, 0.0001)
	assert_float(GameState.get_mount_slow_seconds(sloth)).is_equal_approx(before[2] * sloth.star2_slow_seconds_multiplier, 0.0001)
	assert_float(GameState.get_mount_arc(elephant)).is_equal_approx(before[3] * elephant.star2_arc_multiplier, 0.0001)
	assert_float(GameState.get_mount_gold(horse)).is_equal_approx(before[4] * horse.star2_gold_multiplier, 0.0001)
	for value: float in [wolf.star2_damage_multiplier, giraffe.star2_damage_multiplier, sloth.star2_slow_seconds_multiplier,
			elephant.star2_arc_multiplier, horse.star2_gold_multiplier]:
		assert_float(value).is_greater(1.0)


## Wolf levels reach Wolves already on the carousel and ones bought later.
func test_wolf_levels_reach_every_wolf() -> void:
	var game := _game()
	GameState.add_gold(100000.0)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"wolf")
	UpgradeManager.purchase(&"wolf_level")
	UpgradeManager.purchase(&"wolf")
	var wolves := _mounts(game).filter(func(m: MountBase) -> bool: return m.data.mount_id == &"wolf")
	assert_int(wolves.size()).is_equal(2)
	var expected := _data("wolf").base_damage + _data("wolf").level_damage_bonus
	for wolf: MountBase in wolves:
		assert_float(GameState.get_mount_damage(wolf.data)).is_equal_approx(expected, 0.0001)


func test_selling_a_mount_keeps_its_track() -> void:
	GameState.add_gold(100000.0)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"wolf")
	UpgradeManager.purchase(&"wolf_level")
	UpgradeManager.sell(&"wolf")
	assert_int(GameState.get_mount_level(&"wolf")).is_equal(1)


func test_horse_star_2_doubles_booth_gold() -> void:
	var game := _game()
	_set_track(&"horse", UpgradeData.STAR_BUY + 1)
	var horse := _mounts(game)[0]
	var gold := GameState.get_gold()
	game._on_booth_passed(horse, 0, 1)
	var expected := _data("horse").base_gold_bonus * (1.0 + 3.0 * _data("horse").level_gold_bonus) * 2.0
	assert_float(GameState.get_gold() - gold).is_equal_approx(expected, 0.0001)


## A longer reach doesn't give a free hit on an enemy that's under the line
## the moment the level lands.
func test_giraffe_reach_level_gives_no_free_hit() -> void:
	var game := _game()
	GameState.add_gold(100000.0)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"giraffe")
	var giraffe := _mounts(game)[1]
	var carousel := game.get_node("World/Carousel") as Carousel
	# Just past the Giraffe's reach, but inside it after one Long Neck level.
	var reach := GameState.get_mount_reach(giraffe.data)
	var data := (load("res://resources/enemies/leaf.tres") as EnemyData).duplicate() as EnemyData
	data.base_health = 100.0
	data.move_speed = 0.0
	var enemy := (load("res://scenes/enemies/Leaf.tscn") as PackedScene).instantiate() as EnemyBase
	enemy.data = data
	enemy.position = carousel.position + Vector2.from_angle(giraffe.get_slot_angle()) * (giraffe.get_slot_radius() + reach + 10.0)
	game._on_enemy_spawned(enemy)
	game._admit_pending_spawns()
	UpgradeManager.purchase(&"giraffe_level")
	assert_float(GameState.get_mount_reach(giraffe.data)).is_greater(reach + 10.0)
	carousel.advance_rotation(1.0 / 60.0, 0.1)
	assert_float(enemy.get_health()).is_equal(100.0)
