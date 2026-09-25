extends GdUnitTestSuite
## Click Damage upgrade and kill payouts in the real Game scene.

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.base_click_damage = 1.0
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


func _click_upgrade(value: float, levels: int) -> UpgradeData:
	var upgrade := UpgradeData.new()
	upgrade.id = &"click"
	upgrade.effect_type = UpgradeData.EffectType.ADD_CLICK_DAMAGE
	upgrade.effect_value = value
	upgrade.cost_gold = 1.0
	upgrade.cost_growth = 1.0
	upgrade.max_level = levels
	return upgrade


func test_click_damage_starts_at_base() -> void:
	assert_float(GameState.get_click_damage()).is_equal(1.0)


func test_each_level_adds_its_value_up_to_max() -> void:
	var upgrade := _click_upgrade(0.5, 3)
	GameState.add_gold(100.0)
	for i in 3:
		assert_bool(GameState.try_purchase_upgrade(upgrade)).is_true()
	assert_bool(GameState.try_purchase_upgrade(upgrade)).is_false()
	assert_float(GameState.get_click_damage()).is_equal_approx(2.5, 0.00001)


func test_click_damage_row_is_in_the_shop() -> void:
	var row := UpgradeManager.get_definition(&"click_damage")
	assert_object(row).is_not_null()
	assert_int(row.effect_type).is_equal(UpgradeData.EffectType.ADD_CLICK_DAMAGE)


# --- In the Game scene ---------------------------------------------------------------

func _game() -> Game:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	GameState.reset_run(_config)  # Game._ready() reset to the real config
	return game


## Spawns a wave and keeps only its first Leaf, so random spawn spots can't
## put a second Leaf under the same click.
func _first_enemy(game: Game) -> EnemyBase:
	var waves := game.get_node("WaveManager") as WaveManager
	waves.spawn_wave()
	var layer := game.get_node("World/EnemyLayer")
	var router := game.get_node("World/ClickRouter") as ClickRouter
	for i in range(layer.get_child_count() - 1, 0, -1):
		var extra := layer.get_child(i) as EnemyBase
		router.unregister_enemy(extra)
		layer.remove_child(extra)
		extra.free()
	return layer.get_child(0) as EnemyBase


func test_kill_pays_gold_once_even_if_hit_twice_in_one_frame() -> void:
	var game := _game()
	var enemy := _first_enemy(game)
	enemy.take_damage(100.0)
	enemy.take_damage(100.0)
	assert_float(GameState.get_gold()).is_equal(enemy.data.gold_drop)


func test_clicks_kill_a_leaf_for_its_gold() -> void:
	var game := _game()
	var enemy := _first_enemy(game)
	var router := game.get_node("World/ClickRouter") as ClickRouter
	var needed := ceili(enemy.data.base_health / GameState.get_click_damage())
	var gold_drop := enemy.data.gold_drop
	var spot := enemy.global_position
	for i in needed:
		assert_bool(router.route_click(spot)).is_true()
	assert_bool(enemy.can_receive_click()).is_false()
	assert_float(GameState.get_gold()).is_equal(gold_drop)
	# Once dead it takes no more clicks, so it can't pay twice.
	assert_bool(router.route_click(spot)).is_false()
	assert_float(GameState.get_gold()).is_equal(gold_drop)


func test_leaf_at_the_rim_latches_and_its_kill_unlatches() -> void:
	var game := _game()
	var enemy := _first_enemy(game)
	enemy.advance(100.0)  # far enough to reach the rim in one step
	assert_int(GameState.get_latched_count()).is_equal(1)
	assert_float(GameState.get_total_drag()).is_equal_approx(enemy.data.latch_drag, 0.00001)
	enemy.take_damage(100.0)
	assert_int(GameState.get_latched_count()).is_equal(0)
	assert_float(GameState.get_total_drag()).is_equal(0.0)


func test_stall_timeout_removes_every_enemy_without_gold() -> void:
	var game := _game()
	var layer := game.get_node("World/EnemyLayer")
	(game.get_node("WaveManager") as WaveManager).spawn_wave()
	for enemy: EnemyBase in layer.get_children():
		enemy.advance(100.0)
	GameState.stall_timed_out.emit()
	for enemy: EnemyBase in layer.get_children():
		assert_bool(enemy.is_queued_for_deletion()).is_true()
	assert_int(GameState.get_latched_count()).is_equal(0)
	assert_float(GameState.get_gold()).is_equal(0.0)


## Regression (Codex review): a Leaf one step from the rim when the safety net
## fires must not latch on the same tick. That latch had no enemy left to kill.
func test_leaf_cleared_by_stall_timeout_cannot_latch_the_same_tick() -> void:
	var game := _game()
	var enemy := _first_enemy(game)
	var carousel := game.get_node("World/Carousel") as Carousel
	var gap := (enemy.position - carousel.position).length() - carousel.radius - enemy.data.hitbox_radius
	enemy.advance((gap - 0.5) / enemy.data.move_speed)  # half a pixel short of the rim
	assert_int(GameState.get_latched_count()).is_equal(0)
	GameState.stall_timed_out.emit()
	game._physics_process(0.1)
	assert_int(GameState.get_latched_count()).is_equal(0)
	assert_float(GameState.get_total_drag()).is_equal(0.0)


func test_bought_wolf_kills_a_latched_leaf() -> void:
	var game := _game()
	GameState.add_gold(1000.0)
	assert_bool(UpgradeManager.purchase(&"mount_slot")).is_true()
	assert_bool(UpgradeManager.purchase(&"wolf")).is_true()
	var enemy := _first_enemy(game)
	var gold_drop := enemy.data.gold_drop
	var gold_before := GameState.get_gold()
	enemy.advance(100.0)  # latch at the rim
	# Real ticks (snapshot, then the carousel turns), a minute at most.
	for i in 3600:
		game._physics_process(1.0 / 60.0)
		if not enemy.can_receive_click():
			break
	assert_bool(enemy.can_receive_click()).is_false()
	# The Horse also passes the booth during the turns, so Gold rises by at least the drop.
	assert_float(GameState.get_gold() - gold_before).is_greater_equal(gold_drop)
	assert_int(GameState.get_latched_count()).is_equal(0)


# --- Mounts in the Game scene ------------------------------------------------------

func _mounts(game: Game) -> Array[MountBase]:
	var mounts: Array[MountBase] = []
	for child in game.get_node("World/Carousel/MountSlots").get_children():
		if child is MountBase and not child.is_queued_for_deletion():
			mounts.append(child)
	return mounts


func test_run_starts_with_one_horse_at_the_top() -> void:
	var game := _game()
	var mounts := _mounts(game)
	assert_int(mounts.size()).is_equal(1)
	assert_bool(mounts[0] is MountHorse).is_true()
	assert_float(mounts[0].get_slot_angle()).is_equal_approx(-PI / 2.0, 0.00001)


func test_buying_mounts_adds_nodes_spaced_evenly() -> void:
	var game := _game()
	GameState.add_gold(10000.0)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"wolf")
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"horse")
	var mounts := _mounts(game)
	assert_int(mounts.size()).is_equal(3)
	assert_bool(mounts[1] is MountWolf).is_true()
	for i in 3:
		var expected := -PI / 2.0 + TAU * i / 3.0
		assert_float(absf(angle_difference(mounts[i].get_slot_angle(), expected))).is_less(0.02)


func test_selling_a_horse_removes_its_node() -> void:
	var game := _game()
	GameState.add_gold(10000.0)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"horse")
	assert_int(_mounts(game).size()).is_equal(2)
	assert_bool(UpgradeManager.sell(&"horse")).is_true()
	assert_int(_mounts(game).size()).is_equal(1)


func test_respacing_never_pays_a_booth_pass() -> void:
	var game := _game()
	GameState.add_gold(10000.0)
	var gold := GameState.get_gold()
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"horse")  # the first Horse stays on top, the new one goes to the bottom
	var carousel := game.get_node("World/Carousel") as Carousel
	carousel.advance_rotation(1.0, 0.01)
	var spent := UpgradeManager.get_definition(&"mount_slot").cost_gold + UpgradeManager.get_definition(&"horse").cost_gold
	assert_float(GameState.get_gold()).is_equal(gold - spent)


func test_wolf_fang_needs_the_wolf_and_adds_damage() -> void:
	GameState.add_gold(10000.0)
	assert_bool(UpgradeManager.purchase(&"wolf_fang")).is_false()
	assert_int(UpgradeShop.get_row_state(&"wolf_fang")).is_equal(UpgradeShop.RowState.LOCKED)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"wolf")
	assert_bool(UpgradeManager.purchase(&"wolf_fang")).is_true()
	var fang := UpgradeManager.get_definition(&"wolf_fang")
	assert_int(fang.tab).is_equal(UpgradeData.Tab.COMBAT)
	assert_float(GameState.get_mount_damage_bonus(&"wolf")).is_equal_approx(fang.effect_value, 0.00001)
	var wolf := load("res://resources/mounts/wolf.tres") as MountData
	assert_float(GameState.get_mount_damage(wolf)).is_equal_approx(wolf.base_damage + fang.effect_value, 0.00001)
	# Other mount types don't get the Wolf's bonus.
	assert_float(GameState.get_mount_damage_bonus(&"horse")).is_equal(0.0)


## The damage Game applies on a sweep comes from GameState, so upgrades count.
func test_game_applies_mount_damage_from_game_state() -> void:
	var game := _game()
	GameState.add_gold(10000.0)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"wolf")
	UpgradeManager.purchase(&"wolf_fang")
	var wolf := _mounts(game)[1]
	var enemy := _first_enemy(game)
	var health := enemy.get_health()
	game._on_enemy_swept(wolf, enemy)
	assert_float(health - enemy.get_health()).is_equal_approx(minf(health, GameState.get_mount_damage(wolf.data)), 0.00001)


## Game talks to mounts only through MountBase: no per-type branches.
func test_game_has_no_mount_type_branches() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/game.gd")
	for type_name in ["MountWolf", "MountHorse"]:
		assert_bool(source.contains(type_name)).override_failure_message(
				"game.gd mentions %s" % type_name).is_false()


func test_wolf_fang_level_1_kills_a_grey_leaf_in_one_pass() -> void:
	var wolf := load("res://resources/mounts/wolf.tres") as MountData
	var leaf := load("res://resources/enemies/leaf.tres") as EnemyData
	var fang := UpgradeManager.get_definition(&"wolf_fang")
	assert_float(wolf.base_damage).is_less(leaf.base_health)  # two passes without it
	assert_float(wolf.base_damage + fang.effect_value).is_greater_equal(leaf.base_health)


func test_early_sent_leaf_pays_bonus_gold() -> void:
	var game := _game()
	var waves := game.get_node("WaveManager") as WaveManager
	waves.send_wave_now()
	var enemy := game.get_node("World/EnemyLayer").get_child(0) as EnemyBase
	enemy.take_damage(100.0)
	assert_float(GameState.get_gold()).is_equal_approx(enemy.data.gold_drop * waves.early_send_gold_multiplier, 0.0001)


func test_emergency_clear_removes_only_latched_enemies() -> void:
	var game := _game()
	var layer := game.get_node("World/EnemyLayer")
	(game.get_node("WaveManager") as WaveManager).spawn_wave()
	var enemies: Array[EnemyBase] = []
	for child: EnemyBase in layer.get_children():
		enemies.append(child)
	enemies[0].advance(100.0)  # only the first one latches
	GameState.add_gold(1000.0)
	var gold := GameState.get_gold()
	assert_bool(GameState.try_emergency_clear()).is_true()
	assert_bool(enemies[0].is_queued_for_deletion()).is_true()
	assert_bool(enemies[1].is_queued_for_deletion()).is_false()
	assert_float(GameState.get_gold()).is_equal(gold - GameState.get_emergency_clear_cost())


func _pops(game: Game) -> Array[ClickPop]:
	var pops: Array[ClickPop] = []
	for child in game.get_node("World").get_children():
		if child is ClickPop:
			pops.append(child)
	return pops


## A click that doesn't kill shows a hit pop; the killing click shows one kill pop.
func test_clicks_show_hit_pops_and_kills_show_kill_pops() -> void:
	var game := _game()
	var enemy := _first_enemy(game)
	var router := game.get_node("World/ClickRouter") as ClickRouter
	enemy.take_damage(enemy.data.base_health - 0.01 - GameState.get_click_damage())
	assert_bool(router.route_click(enemy.global_position)).is_true()
	assert_int(_pops(game).size()).is_equal(1)
	assert_object(_pops(game)[0].color).is_equal(game.hit_pop_color)
	assert_bool(router.route_click(enemy.global_position)).is_true()
	assert_int(_pops(game).size()).is_equal(2)
	assert_object(_pops(game)[1].color).is_equal(game.kill_pop_color)


## Mount kills pop too (every kill goes through the same death path).
func test_wolf_style_kill_shows_a_kill_pop() -> void:
	var game := _game()
	var enemy := _first_enemy(game)
	enemy.take_damage(100.0)
	assert_int(_pops(game).size()).is_equal(1)
	assert_object(_pops(game)[0].color).is_equal(game.kill_pop_color)


## Emergency Clear pops each removed enemy, and pops are capped.
func test_clear_pops_each_enemy_up_to_the_cap() -> void:
	var game := _game()
	game.max_live_pops = 2
	var layer := game.get_node("World/EnemyLayer")
	(game.get_node("WaveManager") as WaveManager).spawn_wave()
	for enemy: EnemyBase in layer.get_children():
		enemy.advance(100.0)
	assert_int(layer.get_child_count()).is_greater(2)
	game._on_emergency_cleared()
	assert_int(_pops(game).size()).is_equal(2)
	assert_object(_pops(game)[0].color).is_equal(game.hit_pop_color)


## Garret (2026-09-24): more than one Wolf, and Wolves can be sold to swap builds.
func test_two_wolves_can_be_bought_and_one_sold() -> void:
	var game := _game()
	GameState.add_gold(10000.0)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"mount_slot")
	assert_bool(UpgradeManager.purchase(&"wolf")).is_true()
	assert_bool(UpgradeManager.purchase(&"wolf")).is_true()
	var wolves := _mounts(game).filter(func(m: MountBase) -> bool: return m is MountWolf)
	assert_int(wolves.size()).is_equal(2)
	var wolf := UpgradeManager.get_definition(&"wolf")
	var expected_refund := roundf(wolf.get_cost_for_level(1) * wolf.sell_refund_fraction)
	var gold_before := GameState.get_gold()
	assert_bool(UpgradeManager.sell(&"wolf")).is_true()
	assert_float(GameState.get_gold() - gold_before).is_equal(expected_refund)
	wolves = _mounts(game).filter(func(m: MountBase) -> bool: return m is MountWolf)
	assert_int(wolves.size()).is_equal(1)
