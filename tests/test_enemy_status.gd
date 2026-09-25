extends GdUnitTestSuite
## Slow (Phase 3 Step 4c): EnemyStatus timing and rules, and a slowed enemy's
## movement and "Zzz" icon.

const LEAF_SCENE: PackedScene = preload("res://scenes/enemies/Leaf.tscn")


# --- EnemyStatus ----------------------------------------------------------------------

func test_slow_lasts_its_seconds_in_ticks() -> void:
	var status := EnemyStatus.new()
	assert_float(status.get_speed_factor()).is_equal(1.0)
	status.apply_slow(0.5, 3.0)
	assert_bool(status.is_slowed()).is_true()
	assert_float(status.get_speed_factor()).is_equal(0.5)
	for i in 179:
		status.advance(1.0 / 60.0)
	assert_bool(status.is_slowed()).is_true()
	status.advance(1.0 / 60.0 + 0.0001)
	assert_bool(status.is_slowed()).is_false()
	assert_float(status.get_speed_factor()).is_equal(1.0)


func test_a_second_slow_refreshes_instead_of_stacking() -> void:
	var status := EnemyStatus.new()
	status.apply_slow(0.5, 3.0)
	status.advance(2.0)
	status.apply_slow(0.5, 3.0)  # refreshed to 3 s, still half speed (not a quarter)
	assert_float(status.get_speed_factor()).is_equal(0.5)
	assert_float(status.get_slow_seconds_left()).is_equal_approx(3.0, 0.0001)
	status.apply_slow(0.8, 1.0)  # weaker and shorter: changes nothing
	assert_float(status.get_speed_factor()).is_equal(0.5)
	assert_float(status.get_slow_seconds_left()).is_equal_approx(3.0, 0.0001)
	status.apply_slow(0.25, 0.5)  # stronger: takes the stronger slow, keeps the longer time
	assert_float(status.get_speed_factor()).is_equal(0.25)
	assert_float(status.get_slow_seconds_left()).is_equal_approx(3.0, 0.0001)


func test_bad_slows_are_ignored() -> void:
	var status := EnemyStatus.new()
	status.apply_slow(0.5, 0.0)
	status.apply_slow(NAN, 3.0)
	status.apply_slow(0.5, INF)
	assert_bool(status.is_slowed()).is_false()


# --- On an enemy ----------------------------------------------------------------------

## A Leaf 300 px right of the center, rim at 100 px, speed 100 px/s.
func _enemy() -> EnemyBase:
	var data := EnemyData.new()
	data.move_speed = 100.0
	data.hitbox_radius = 10.0
	var enemy := LEAF_SCENE.instantiate() as EnemyBase
	enemy.data = data
	enemy.position = Vector2(300.0, 0.0)
	add_child(enemy)
	auto_free(enemy)
	enemy.setup(Vector2.ZERO, 100.0)
	return enemy


func test_slowed_enemy_moves_at_half_speed_then_recovers() -> void:
	var enemy := _enemy()
	enemy.apply_slow(0.5, 1.0)
	assert_float(enemy.get_current_speed()).is_equal(50.0)
	for i in 60:
		enemy.advance(1.0 / 60.0)
	assert_float(enemy.position.x).is_equal_approx(250.0, 0.01)  # 1 s at 50 px/s
	assert_bool(enemy.is_slowed()).is_false()
	enemy.advance(0.5)
	assert_float(enemy.position.x).is_equal_approx(200.0, 0.01)  # back to 100 px/s


func test_zzz_shows_only_while_slowed() -> void:
	var enemy := _enemy()
	var icon := enemy.get_node("SlowIcon") as Node2D
	assert_bool(icon.visible).is_false()
	enemy.apply_slow(0.5, 0.5)
	assert_bool(icon.visible).is_true()
	enemy.advance(0.6)
	assert_bool(icon.visible).is_false()


func test_dead_enemy_cannot_be_slowed() -> void:
	var enemy := _enemy()
	enemy.take_damage(100.0)
	enemy.apply_slow(0.5, 3.0)
	assert_bool(enemy.is_slowed()).is_false()
