extends GdUnitTestSuite
## Wolf sweep: angle math for passes, and a real Wolf on a carousel hitting
## enemies in world space.

const LEAF_SCENE: PackedScene = preload("res://scenes/enemies/Leaf.tscn")

var _carousel: Carousel
var _layer: Node2D
var _wolf: MountWolf
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


# --- A real Wolf ----------------------------------------------------------------------

## Carousel at the origin; Wolf in a slot 75 px out at angle 0 (pointing +X),
## reaching 65 px further (to 140 px from the center).
func _setup_wolf() -> void:
	_carousel = auto_free(Carousel.new())
	add_child(_carousel)
	_layer = auto_free(Node2D.new())
	add_child(_layer)
	var slot := Marker2D.new()
	slot.position = Vector2(75.0, 0.0)
	_carousel.add_child(slot)
	var data := MountData.new()
	data.sweep_range = 65.0
	data.base_damage = 3.0
	_wolf = MountWolf.new()
	_wolf.data = data
	slot.add_child(_wolf)
	_wolf.setup(_carousel)
	_wolf.set_enemy_layer(_layer)
	_hits.clear()
	_wolf.enemy_swept.connect(func(_w: MountWolf, e: EnemyBase) -> void: _hits.append(e))


func _enemy_at(bearing: float, distance: float, health: float = 100.0) -> EnemyBase:
	var data := EnemyData.new()
	data.base_health = health
	data.hitbox_radius = 10.0
	var enemy := LEAF_SCENE.instantiate() as EnemyBase
	enemy.data = data
	enemy.position = Vector2.from_angle(bearing) * distance
	_layer.add_child(enemy)
	return enemy


func _turn(total: float, ticks: int = 1) -> void:
	for i in ticks:
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
	_carousel.advance_rotation(1.0, 0.0)
	assert_array(_hits).is_empty()


func test_placing_a_wolf_on_an_enemy_gives_no_free_hit() -> void:
	_carousel = auto_free(Carousel.new())
	add_child(_carousel)
	_layer = auto_free(Node2D.new())
	add_child(_layer)
	var enemy := _enemy_at(0.0, 110.0)
	var slot := Marker2D.new()
	slot.position = Vector2(75.0, 0.0)
	_carousel.add_child(slot)
	_wolf = MountWolf.new()
	_wolf.data = MountData.new()
	_wolf.data.sweep_range = 65.0
	slot.add_child(_wolf)
	_wolf.setup(_carousel)
	_wolf.set_enemy_layer(_layer)
	_hits.clear()
	_wolf.enemy_swept.connect(func(_w: MountWolf, e: EnemyBase) -> void: _hits.append(e))
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
