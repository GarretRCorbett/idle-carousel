extends GdUnitTestSuite
## Wolf sweep: angle math for passes, and a real Wolf on a carousel hitting
## enemies in world space.

const LEAF_SCENE: PackedScene = preload("res://scenes/enemies/Leaf.tscn")

var _carousel: Carousel
var _layer: Node2D
var _wolf: MountWolf
var _snapshot: EnemySnapshot
var _hits: Array[EnemyBase] = []


# --- Pure sweep math ------------------------------------------------------------------

func test_one_pass_per_turn() -> void:
	var passes := RotationMath.sweep_passes(-0.5, 1.0, 0.0, 0.1)
	assert_int(passes.y - passes.x + 1).is_equal(1)
	passes = RotationMath.sweep_passes(0.5, TAU - 1.0, 0.0, 0.1)
	assert_int(passes.y - passes.x + 1).is_equal(0)


func test_long_tick_crosses_several_passes() -> void:
	var passes := RotationMath.sweep_passes(-0.5, TAU * 2.0 + 1.0, 0.0, 0.1)
	assert_int(passes.y - passes.x + 1).is_equal(3)


func test_window_edges_count() -> void:
	# Ends just inside the window's leading edge.
	var passes := RotationMath.sweep_passes(-1.0, 0.91, 0.0, 0.1)
	assert_int(passes.y - passes.x + 1).is_equal(1)
	passes = RotationMath.sweep_passes(-1.0, 0.89, 0.0, 0.1)
	assert_int(passes.y - passes.x + 1).is_equal(0)


func test_pass_number_is_the_same_across_ticks_and_the_wrap() -> void:
	var bearing := PI - 0.05  # window straddles the ±PI wrap
	var a := RotationMath.sweep_passes(PI - 0.2, 0.1, bearing, 0.1)
	var b := RotationMath.sweep_passes(PI - 0.1, 0.2, bearing, 0.1)
	assert_int(a.y).is_equal(b.x)


func test_no_passes_when_stopped() -> void:
	var passes := RotationMath.sweep_passes(0.0, 0.0, 0.0, 0.5)
	assert_bool(passes.y < passes.x).is_true()


# --- Line-tip windows (MountSweep.line_half_window) ---------------------------------
# A line from 75 to 140 px out, enemies with a 10 px hitbox.

func test_middle_of_the_line_uses_the_plain_window() -> void:
	assert_float(MountSweep.line_half_window(110.0, 10.0, 75.0, 140.0)).is_equal_approx(asin(10.0 / 110.0), 0.000001)


func test_outer_tip_window_is_narrower() -> void:
	# The widest touch would be at 144.7 px, past the tip, so the tip (140) decides.
	var half := MountSweep.line_half_window(145.0, 10.0, 75.0, 140.0)
	assert_float(half).is_less(asin(10.0 / 145.0))
	# At that angle the tip is exactly one hitbox radius from the enemy.
	var tip := Vector2.from_angle(half) * 140.0
	assert_float(tip.distance_to(Vector2(145.0, 0.0))).is_equal_approx(10.0, 0.0001)


func test_inner_tip_window_is_narrower() -> void:
	var half := MountSweep.line_half_window(70.0, 10.0, 75.0, 140.0)
	assert_float(half).is_less(asin(10.0 / 70.0))
	var tip := Vector2.from_angle(half) * 75.0
	assert_float(tip.distance_to(Vector2(70.0, 0.0))).is_equal_approx(10.0, 0.0001)


func test_exact_tangency_at_either_end_is_a_zero_window() -> void:
	assert_float(MountSweep.line_half_window(150.0, 10.0, 75.0, 140.0)).is_equal_approx(0.0, 0.0001)
	assert_float(MountSweep.line_half_window(65.0, 10.0, 75.0, 140.0)).is_equal_approx(0.0, 0.0001)
	assert_float(MountSweep.line_half_window(150.01, 10.0, 75.0, 140.0)).is_equal(-1.0)
	assert_float(MountSweep.line_half_window(64.99, 10.0, 75.0, 140.0)).is_equal(-1.0)


func test_window_changes_over_smoothly_at_the_tip() -> void:
	# The plain window's touch point reaches the tip at d = sqrt(140² + 10²).
	var d := sqrt(140.0 * 140.0 + 100.0)
	for offset: float in [-0.01, 0.0, 0.01]:
		assert_float(MountSweep.line_half_window(d + offset, 10.0, 75.0, 140.0)).is_equal_approx(asin(10.0 / (d + offset)), 0.0001)


func test_enemy_covering_the_center_is_skipped() -> void:
	assert_float(MountSweep.line_half_window(8.0, 10.0, 0.0, 140.0)).is_equal(-1.0)


## A long tick lists an enemy once per pass; the Wolf rechecks before each hit,
## so the pass after a kill does nothing.
func test_long_tick_after_a_kill_gives_no_second_hit() -> void:
	_setup_wolf()
	var enemy := _enemy_at(1.0, 110.0, 2.0)
	_wolf.enemy_swept.connect(func(_m: MountBase, e: EnemyBase) -> void: e.take_damage(5.0))
	_turn(TAU * 3.0)
	assert_array(_hits).contains_exactly([enemy])


# --- A real Wolf ----------------------------------------------------------------------

## Carousel at the origin; Wolf 75 px out at angle 0 (pointing +X),
## reaching 65 px further (to 140 px from the center).
func _setup_wolf() -> void:
	_carousel = auto_free(Carousel.new())
	add_child(_carousel)
	_layer = auto_free(Node2D.new())
	add_child(_layer)
	var data := MountData.new()
	data.sweep_range = 65.0
	data.base_damage = 3.0
	_wolf = MountWolf.new()
	_wolf.data = data
	_carousel.add_child(_wolf)
	_wolf.place(0.0, 75.0)
	_wolf.setup(_carousel)
	_snapshot = EnemySnapshot.new()
	_wolf.set_enemy_snapshot(_snapshot)
	_hits.clear()
	_wolf.enemy_swept.connect(func(_m: MountBase, e: EnemyBase) -> void: _hits.append(e))


func _enemy_at(bearing: float, distance: float, health: float = 100.0) -> EnemyBase:
	var data := EnemyData.new()
	data.base_health = health
	data.hitbox_radius = 10.0
	var enemy := LEAF_SCENE.instantiate() as EnemyBase
	enemy.data = data
	enemy.position = Vector2.from_angle(bearing) * distance
	_layer.add_child(enemy)
	return enemy


## Like Game's tick: snapshot first, then the carousel turns.
func _turn(total: float, ticks: int = 1) -> void:
	for i in ticks:
		_snapshot.rebuild(_layer, _carousel.global_position)
		_carousel.advance_rotation(1.0, total / ticks)


func test_latched_enemy_is_hit_once_per_turn() -> void:
	_setup_wolf()
	var enemy := _enemy_at(1.0, 110.0)
	_turn(TAU, 120)
	assert_array(_hits).contains_exactly([enemy])
	_turn(TAU, 120)
	assert_int(_hits.size()).is_equal(2)


func test_one_huge_tick_still_hits_every_pass() -> void:
	_setup_wolf()
	_enemy_at(1.0, 110.0)
	_turn(TAU * 3.0)
	assert_int(_hits.size()).is_equal(3)


func test_line_pierces_every_enemy_on_it() -> void:
	_setup_wolf()
	var near := _enemy_at(2.0, 90.0)
	var far := _enemy_at(2.0, 130.0)
	_turn(2.5, 10)
	assert_array(_hits).contains_exactly_in_any_order([near, far])


func test_enemies_out_of_reach_are_not_hit() -> void:
	_setup_wolf()
	_enemy_at(2.0, 200.0)  # past 140 + hitbox
	_enemy_at(3.0, 40.0)   # inside the Wolf's slot radius
	_turn(TAU, 60)
	assert_array(_hits).is_empty()


func test_stopped_wolf_deals_nothing() -> void:
	_setup_wolf()
	_enemy_at(0.0, 110.0)  # right under the line
	_turn(0.0)
	assert_array(_hits).is_empty()


func test_placing_a_wolf_on_an_enemy_gives_no_free_hit() -> void:
	_carousel = auto_free(Carousel.new())
	add_child(_carousel)
	_layer = auto_free(Node2D.new())
	add_child(_layer)
	var enemy := _enemy_at(0.0, 110.0)
	_wolf = MountWolf.new()
	_wolf.data = MountData.new()
	_wolf.data.sweep_range = 65.0
	_carousel.add_child(_wolf)
	_wolf.place(0.0, 75.0)
	_wolf.setup(_carousel)
	_snapshot = EnemySnapshot.new()
	_snapshot.rebuild(_layer, _carousel.global_position)
	_wolf.set_enemy_snapshot(_snapshot)
	_hits.clear()
	_wolf.enemy_swept.connect(func(_m: MountBase, e: EnemyBase) -> void: _hits.append(e))
	_turn(0.3, 3)  # moves off the enemy
	assert_array(_hits).is_empty()
	_turn(TAU, 60)  # comes back around
	assert_array(_hits).contains_exactly([enemy])


func test_dead_enemies_are_skipped() -> void:
	_setup_wolf()
	var enemy := _enemy_at(1.0, 110.0)
	enemy.take_damage(1000.0)
	_turn(TAU, 60)
	assert_array(_hits).is_empty()


## A mount killed an enemy earlier in the tick; a later mount reading the same
## snapshot skips it.
func test_enemy_killed_earlier_in_the_tick_is_skipped() -> void:
	_setup_wolf()
	var enemy := _enemy_at(1.0, 110.0)
	_snapshot.rebuild(_layer, _carousel.global_position)
	enemy.take_damage(1000.0)
	_carousel.advance_rotation(1.0, TAU)
	assert_array(_hits).is_empty()


## The snapshot only holds live enemies, measured from the center.
func test_snapshot_measures_live_enemies() -> void:
	_setup_wolf()
	var alive := _enemy_at(0.5, 110.0)
	var dead := _enemy_at(1.0, 120.0)
	dead.take_damage(1000.0)
	_snapshot.rebuild(_layer, _carousel.global_position)
	assert_int(_snapshot.size()).is_equal(1)
	assert_object(_snapshot.enemies[0]).is_same(alive)
	assert_float(_snapshot.bearings[0]).is_equal_approx(0.5, 0.00001)
	assert_float(_snapshot.distances[0]).is_equal_approx(110.0, 0.0001)
	assert_float(_snapshot.radii[0]).is_equal(10.0)


## The distance check never drops an enemy that the full math would hit:
## every enemy whose circle overlaps the line's ring is hit in one turn.
func test_distance_check_keeps_every_enemy_in_reach() -> void:
	_setup_wolf()
	var expected: Array[EnemyBase] = []
	for i in 40:
		var distance := 61.25 + i * 2.5  # 61.25..158.75; the ring is 65..150 with the hitbox
		var enemy := _enemy_at(0.1 + i * 0.15, distance)
		if distance + 10.0 >= 75.0 and distance - 10.0 <= 140.0:
			expected.append(enemy)
	_turn(TAU, 360)
	assert_array(_hits).contains_exactly_in_any_order(expected)
