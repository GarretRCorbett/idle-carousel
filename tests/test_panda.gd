extends GdUnitTestSuite
## The Panda (Phase 3 Step 5c): Gold once per full turn, heals on its own kills,
## unlocked by 3 different mount types at Tier 2.

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.latch_grace_seconds = 0.0
	_config.regen_per_second = 0.0
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


func _panda_data() -> MountData:
	return load("res://resources/mounts/panda.tres") as MountData


# --- Gold per turn ------------------------------------------------------------------

func test_pays_once_per_full_turn_at_any_speed() -> void:
	var carousel := auto_free(Carousel.new()) as Carousel
	add_child(carousel)
	var panda := (load("res://scenes/mounts/Panda.tscn") as PackedScene).instantiate() as MountPanda
	carousel.add_child(panda)
	panda.place(1.0, 75.0)
	panda.setup(carousel)
	panda.set_enemy_snapshot(EnemySnapshot.new())
	var paid: Array[float] = []
	panda.gold_earned.connect(func(_m: MountBase, amount: float) -> void: paid.append(amount))
	for i in 120:
		carousel.advance_rotation(1.0, TAU / 120.0)
	assert_array(paid).is_equal([_panda_data().gold_per_turn])
	carousel.advance_rotation(1.0, TAU * 3.0)  # one huge tick: three turns at once
	assert_float(paid[1]).is_equal_approx(_panda_data().gold_per_turn * 3.0, 0.0001)
	panda.place(3.0, 75.0)  # moving it never pays
	assert_int(paid.size()).is_equal(2)


# --- Healing ---------------------------------------------------------------------------

func _game() -> Game:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	GameState.reset_run(_config)
	(game.get_node("WaveManager") as WaveManager).set_auto(false)
	return game


func _weak_leaf(game: Game, bearing: float) -> EnemyBase:
	var carousel := game.get_node("World/Carousel") as Carousel
	var data := (load("res://resources/enemies/leaf.tres") as EnemyData).duplicate() as EnemyData
	data.base_health = 0.1
	var enemy := (load("res://scenes/enemies/Leaf.tscn") as PackedScene).instantiate() as EnemyBase
	enemy.data = data
	enemy.position = carousel.position + Vector2.from_angle(bearing) * 300.0
	game._on_enemy_spawned(enemy)
	game._admit_pending_spawns()
	return enemy


func _mount(game: Game, id: StringName) -> MountBase:
	for child in game.get_node("World/Carousel/MountSlots").get_children():
		if child is MountBase and (child as MountBase).data.mount_id == id:
			return child
	return null


func test_heals_only_on_its_own_kills() -> void:
	var game := _game()
	for id: StringName in [&"horse", &"wolf", &"giraffe"]:
		GameState._mount_tiers[id] = 2
	GameState.add_gold(100000.0)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"wolf")
	assert_bool(UpgradeManager.purchase(&"panda")).is_true()
	GameState.damage_carousel(30.0)
	var health := GameState.get_health()
	game._on_enemy_swept(_mount(game, &"wolf"), _weak_leaf(game, 1.0))
	assert_float(GameState.get_health()).is_equal(health)  # a Wolf kill heals nothing
	game._on_enemy_swept(_mount(game, &"panda"), _weak_leaf(game, 2.0))
	assert_float(GameState.get_health()).is_equal_approx(health + _panda_data().heal_per_kill, 0.0001)
	game._on_enemy_clicked(_weak_leaf(game, 3.0))  # nor a click
	assert_float(GameState.get_health()).is_equal_approx(health + _panda_data().heal_per_kill, 0.0001)


func test_heal_caps_at_max_and_skips_a_stall() -> void:
	GameState.heal_carousel(50.0)
	assert_float(GameState.get_health()).is_equal(GameState.get_max_health())
	GameState.register_latch(1, 0.0, 1000.0)
	GameState.advance_simulation(1.0)
	assert_bool(GameState.is_stalled()).is_true()
	var health := GameState.get_health()
	GameState.heal_carousel(10.0)
	assert_float(GameState.get_health()).is_equal(health)


# --- Unlock ---------------------------------------------------------------------------

func test_unlock_needs_three_different_types_at_tier_2() -> void:
	GameState.add_gold(100000.0)
	UpgradeManager.purchase(&"mount_slot")
	GameState._mount_tiers[&"horse"] = 2
	GameState._mount_tiers[&"wolf"] = 2
	GameState._mount_tiers[&"panda"] = 2  # the Panda never counts itself
	assert_int(GameState.get_tier2_type_count(&"panda")).is_equal(2)
	assert_bool(UpgradeManager.can_purchase(&"panda")).is_false()
	assert_int(UpgradeShop.get_row_state(&"panda")).is_equal(UpgradeShop.RowState.LOCKED)
	GameState._mount_tiers[&"sloth"] = 2
	assert_bool(UpgradeManager.can_purchase(&"panda")).is_true()


func test_panda_tier_2_raises_all_three_effects() -> void:
	var data := _panda_data()
	var damage := GameState.get_mount_damage(data)
	var gold := GameState.get_mount_gold_per_turn(data)
	var heal := GameState.get_mount_heal(data)
	GameState._mount_tiers[&"panda"] = 2
	assert_float(GameState.get_mount_damage(data)).is_equal_approx(damage * 1.5, 0.0001)
	assert_float(GameState.get_mount_gold_per_turn(data)).is_equal_approx(gold * 1.5, 0.0001)
	assert_float(GameState.get_mount_heal(data)).is_equal_approx(heal * 1.5, 0.0001)
