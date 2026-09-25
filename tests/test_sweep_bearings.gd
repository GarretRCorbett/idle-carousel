extends GdUnitTestSuite
## Unwrapped bearings (Phase 3 Step 2g): enemies that move sideways across the
## ±180° line, or in and out of reach, get exactly one hit per pass; moving
## mounts between ticks gives no free hit.

const LEAF_SCENE: PackedScene = preload("res://scenes/enemies/Leaf.tscn")

var _carousel: Carousel
var _layer: Node2D
var _wolf: MountWolf
var _snapshot: EnemySnapshot
var _hits: Array[EnemyBase] = []


## Carousel at the origin; Wolf 75 px out at angle 0, reaching to 140 px.
func _setup_wolf() -> void:
	_carousel = auto_free(Carousel.new())
	add_child(_carousel)
	_layer = auto_free(Node2D.new())
	add_child(_layer)
	_wolf = MountWolf.new()
	_wolf.data = MountData.new()
	_wolf.data.sweep_range = 65.0
	_carousel.add_child(_wolf)
	_wolf.place(0.0, 75.0)
	_wolf.setup(_carousel)
	_snapshot = EnemySnapshot.new()
	_wolf.set_enemy_snapshot(_snapshot)
	_hits.clear()
	_wolf.enemy_swept.connect(func(_m: MountBase, e: EnemyBase) -> void: _hits.append(e))


func _enemy_at(bearing: float, distance: float) -> EnemyBase:
	var data := EnemyData.new()
	data.base_health = 1000.0
	data.hitbox_radius = 10.0
	var enemy := LEAF_SCENE.instantiate() as EnemyBase
	enemy.data = data
	enemy.position = Vector2.from_angle(bearing) * distance
	_layer.add_child(enemy)
	enemy.setup(Vector2.ZERO, 100.0)
	return enemy


func _move(enemy: EnemyBase, bearing: float, distance: float = 110.0) -> void:
	enemy.position = Vector2.from_angle(bearing) * distance


func _turn(total: float, ticks: int = 1) -> void:
	for i in ticks:
		_snapshot.rebuild(_layer, _carousel.global_position)
		_carousel.advance_rotation(1.0, total / ticks)


# --- The unwrapped bearing itself -------------------------------------------------------

func test_bearing_keeps_going_past_180() -> void:
	_setup_wolf()
	var enemy := _enemy_at(PI - 0.1, 110.0)
	assert_float(enemy.get_unwrapped_bearing()).is_equal_approx(PI - 0.1, 0.00001)
	_move(enemy, PI + 0.1)  # shows up as -PI + 0.1
	assert_float(enemy.update_bearing(-PI + 0.1)).is_equal_approx(PI + 0.1, 0.00001)
	assert_float(enemy.update_bearing(-PI + 0.1)).is_equal_approx(PI + 0.1, 0.00001)  # no move, no change
	assert_float(enemy.update_bearing(PI - 0.1)).is_equal_approx(PI - 0.1, 0.00001)  # and back


# --- Crossing the seam ------------------------------------------------------------------

## Hit near 180°, then it slips across to -179°: same pass, no second hit.
## Before unwrapping, the bearing jumped by a full turn and looked like a new pass.
func test_crossing_the_seam_forward_gives_no_extra_hit() -> void:
	_setup_wolf()
	var enemy := _enemy_at(PI - 0.02, 110.0)
	_turn(PI, 60)  # line now at 180°, on the enemy
	assert_int(_hits.size()).is_equal(1)
	_move(enemy, PI + 0.02)
	_turn(0.01)
	assert_int(_hits.size()).is_equal(1)
	_turn(TAU, 120)  # and the next pass still hits once
	assert_int(_hits.size()).is_equal(2)


## The other way: hit just past -180°, slips back across to +179°. The next
## turn must still hit (a wrapped bearing would count it as an old pass).
func test_crossing_the_seam_backward_keeps_the_next_hit() -> void:
	_setup_wolf()
	var enemy := _enemy_at(-PI + 0.02, 110.0)
	_turn(PI + 0.03, 60)
	assert_int(_hits.size()).is_equal(1)
	_move(enemy, PI - 0.02)
	_turn(0.01)
	assert_int(_hits.size()).is_equal(1)
	_turn(TAU, 120)
	assert_int(_hits.size()).is_equal(2)


## A zigzag back and forth across the seam while the line sits on it: one hit.
func test_zigzag_on_the_seam_is_hit_once_per_pass() -> void:
	_setup_wolf()
	var enemy := _enemy_at(PI - 0.03, 110.0)
	_turn(PI - 0.03, 60)
	assert_int(_hits.size()).is_equal(1)
	for i in 10:
		_move(enemy, PI + (0.03 if i % 2 == 0 else -0.03))
		_turn(0.001)
	assert_int(_hits.size()).is_equal(1)


## Out of reach and back while the line is still there: not hit again until
## the line comes round.
func test_in_and_out_of_reach_is_hit_once_per_pass() -> void:
	_setup_wolf()
	var enemy := _enemy_at(1.0, 110.0)
	_turn(1.0, 20)
	assert_int(_hits.size()).is_equal(1)
	_move(enemy, 1.0, 200.0)
	_turn(0.01)
	_move(enemy, 1.0, 110.0)
	_turn(0.01)
	assert_int(_hits.size()).is_equal(1)
	_turn(TAU, 120)
	assert_int(_hits.size()).is_equal(2)


# --- Buying mounts between ticks (real Game) ----------------------------------------------

## Mounts re-space when one is bought. A Wolf that lands on a latched enemy
## gets no free hit; it rebases against where the enemies are now.
func test_buying_mounts_gives_no_free_hit() -> void:
	var config := RunConfig.new()
	GameState.reset_run(config)
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	GameState.reset_run(config)
	(game.get_node("WaveManager") as WaveManager).set_auto(false)
	var carousel := game.get_node("World/Carousel") as Carousel
	# Latched Leaves where the Wolf will land: bottom (2 mounts), then
	# 30° below the right (3 mounts: horse, wolf, horse).
	var at_bottom := _latched_leaf(game, carousel, PI / 2.0)
	var at_right := _latched_leaf(game, carousel, PI / 6.0)
	game._admit_pending_spawns()
	at_bottom.advance(100.0)
	at_right.advance(100.0)
	GameState.add_gold(100000.0)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"wolf")
	carousel.advance_rotation(1.0 / 60.0, 0.01)
	assert_float(at_bottom.get_health()).is_equal(at_bottom.data.base_health)
	UpgradeManager.purchase(&"horse")
	carousel.advance_rotation(1.0 / 60.0, 0.01)
	assert_float(at_right.get_health()).is_equal(at_right.data.base_health)
	GameState.reset_run()


func _latched_leaf(game: Game, carousel: Carousel, bearing: float) -> EnemyBase:
	var enemy := LEAF_SCENE.instantiate() as EnemyBase
	enemy.position = carousel.position + Vector2.from_angle(bearing) * (carousel.radius + 40.0)
	game._on_enemy_spawned(enemy)
	return enemy
