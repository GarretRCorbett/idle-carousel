extends GdUnitTestSuite
## Click routing: nearest enemy within its click radius wins; misses do nothing.

const LEAF_SCENE: PackedScene = preload("res://scenes/enemies/Leaf.tscn")

var _router: ClickRouter
var _clicked: Array[EnemyBase] = []


func before_test() -> void:
	_router = auto_free(ClickRouter.new())
	add_child(_router)
	_clicked.clear()
	_router.enemy_clicked.connect(func(e: EnemyBase) -> void: _clicked.append(e))


func _enemy_at(pos: Vector2, click_radius: float = 20.0) -> EnemyBase:
	var data := EnemyData.new()
	data.base_health = 1.0
	data.click_radius = click_radius
	var enemy := LEAF_SCENE.instantiate() as EnemyBase
	enemy.data = data
	enemy.position = pos
	add_child(enemy)
	auto_free(enemy)
	_router.register_enemy(enemy)
	return enemy


func test_click_inside_radius_hits() -> void:
	var enemy := _enemy_at(Vector2(100.0, 100.0))
	assert_bool(_router.route_click(Vector2(115.0, 100.0))).is_true()
	assert_array(_clicked).contains_exactly([enemy])


func test_click_outside_every_radius_does_nothing() -> void:
	_enemy_at(Vector2(100.0, 100.0))
	assert_bool(_router.route_click(Vector2(125.0, 100.0))).is_false()
	assert_array(_clicked).is_empty()


func test_nearest_enemy_wins_when_they_overlap() -> void:
	_enemy_at(Vector2(100.0, 100.0))
	var near := _enemy_at(Vector2(110.0, 100.0))
	_router.route_click(Vector2(108.0, 100.0))
	assert_array(_clicked).contains_exactly([near])


func test_dead_enemies_are_skipped() -> void:
	var dead := _enemy_at(Vector2(100.0, 100.0))
	var alive := _enemy_at(Vector2(110.0, 100.0))
	dead.take_damage(10.0)
	_router.route_click(Vector2(100.0, 100.0))
	assert_array(_clicked).contains_exactly([alive])


func test_unregistered_enemies_are_ignored() -> void:
	var enemy := _enemy_at(Vector2(100.0, 100.0))
	_router.unregister_enemy(enemy)
	assert_bool(_router.route_click(Vector2(100.0, 100.0))).is_false()


func test_only_left_presses_count() -> void:
	_enemy_at(Vector2(100.0, 100.0))
	var cases: Array = [[MOUSE_BUTTON_RIGHT, true], [MOUSE_BUTTON_LEFT, false], [MOUSE_BUTTON_WHEEL_UP, true]]
	for c: Array in cases:
		var event := InputEventMouseButton.new()
		event.button_index = c[0]
		event.pressed = c[1]
		event.position = Vector2(100.0, 100.0)
		_router._unhandled_input(event)
	assert_array(_clicked).is_empty()
