extends GdUnitTestSuite
## Enemy basics: runtime health, dying exactly once, approach, stopping at the rim.

const LEAF_SCENE: PackedScene = preload("res://scenes/enemies/Leaf.tscn")

var _data: EnemyData
var _deaths: int = 0
var _rim_arrivals: int = 0


func before_test() -> void:
	_data = EnemyData.new()
	_data.base_health = 2.0
	_data.move_speed = 100.0
	_data.hitbox_radius = 10.0
	_data.click_radius = 20.0
	_deaths = 0
	_rim_arrivals = 0


## A Leaf 300 px right of the center, with a rim at 100 px (it stops at 110).
func _enemy(data: EnemyData = _data) -> EnemyBase:
	var enemy := LEAF_SCENE.instantiate() as EnemyBase
	enemy.data = data
	enemy.position = Vector2(300.0, 0.0)
	add_child(enemy)
	auto_free(enemy)
	enemy.setup(Vector2.ZERO, 100.0)
	enemy.died.connect(func(_e: EnemyBase) -> void: _deaths += 1)
	enemy.reached_rim.connect(func(_e: EnemyBase) -> void: _rim_arrivals += 1)
	return enemy


func test_damage_never_changes_the_data_resource() -> void:
	var leaf_data := load("res://resources/enemies/leaf.tres") as EnemyData
	var starting_health := leaf_data.base_health
	var enemy := _enemy(leaf_data)
	enemy.take_damage(1.0)
	assert_float(enemy.get_health()).is_equal(starting_health - 1.0)
	assert_float(leaf_data.base_health).is_equal(starting_health)


func test_two_killing_hits_in_one_frame_die_once() -> void:
	var enemy := _enemy()
	assert_bool(enemy.take_damage(5.0)).is_true()
	assert_bool(enemy.take_damage(5.0)).is_false()
	assert_int(_deaths).is_equal(1)
	assert_bool(enemy.can_receive_click()).is_false()


func test_survivable_hit_does_not_kill() -> void:
	var enemy := _enemy()
	assert_bool(enemy.take_damage(1.0)).is_false()
	assert_float(enemy.get_health()).is_equal(1.0)
	assert_int(_deaths).is_equal(0)
	assert_bool(enemy.can_receive_click()).is_true()


func test_health_bar_hidden_until_first_hit() -> void:
	var enemy := _enemy()
	var bar := enemy.get_node("HealthBar") as EnemyHealthBar
	assert_bool(bar.visible).is_false()
	enemy.take_damage(0.5)
	assert_bool(bar.visible).is_true()
	assert_float(bar.get_fraction()).is_equal_approx(0.75, 0.0001)


func test_hit_flash_fades_back_and_stops_processing() -> void:
	var enemy := _enemy()
	var visual := enemy.get_node("Visual") as Node2D
	assert_bool(enemy.is_processing()).is_false()
	enemy.take_damage(0.5)
	assert_bool(enemy.is_processing()).is_true()
	assert_object(visual.modulate).is_equal(enemy.hit_flash_modulate)
	enemy._process(enemy.hit_flash_seconds)
	assert_object(visual.modulate).is_equal(Color.WHITE)
	assert_bool(enemy.is_processing()).is_false()


func test_lethal_hit_skips_bar_and_flash() -> void:
	var enemy := _enemy()
	enemy.take_damage(100.0)
	assert_bool((enemy.get_node("HealthBar") as Node2D).visible).is_false()
	assert_bool(enemy.is_processing()).is_false()


func test_zero_or_bad_damage_is_ignored() -> void:
	var enemy := _enemy()
	enemy.take_damage(0.0)
	enemy.take_damage(-3.0)
	enemy.take_damage(NAN)
	assert_float(enemy.get_health()).is_equal(2.0)


func test_moves_toward_the_center_at_move_speed() -> void:
	var enemy := _enemy()
	enemy.advance(0.5)
	assert_vector(enemy.position).is_equal_approx(Vector2(250.0, 0.0), Vector2(0.001, 0.001))


func test_stops_exactly_at_the_rim_once() -> void:
	var enemy := _enemy()
	enemy.advance(1.5)  # 150 px: 300 to 150, not there yet
	assert_int(_rim_arrivals).is_equal(0)
	enemy.advance(1.0)  # would reach 50; stops at rim 100 + hitbox 10
	assert_vector(enemy.position).is_equal_approx(Vector2(110.0, 0.0), Vector2(0.001, 0.001))
	assert_bool(enemy.is_at_rim()).is_true()
	enemy.advance(1.0)
	assert_vector(enemy.position).is_equal_approx(Vector2(110.0, 0.0), Vector2(0.001, 0.001))
	assert_int(_rim_arrivals).is_equal(1)


func test_small_ticks_reach_the_same_spot() -> void:
	var enemy := _enemy()
	for i in 60:
		enemy.advance(1.0 / 60.0)
	assert_vector(enemy.position).is_equal_approx(Vector2(200.0, 0.0), Vector2(0.01, 0.01))


func test_dead_enemy_stops_moving() -> void:
	var enemy := _enemy()
	enemy.take_damage(10.0)
	enemy.advance(1.0)
	assert_vector(enemy.position).is_equal(Vector2(300.0, 0.0))
