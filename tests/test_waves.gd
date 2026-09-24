extends GdUnitTestSuite
## Wave layout: group size, cluster spread, and spawn distance.


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_group_size_stays_in_range() -> void:
	var rng := _rng(1)
	var seen := {}
	for i in 200:
		var count := WaveManager.plan_wave(rng, Vector2.ZERO, 3, 5, 380.0, 0.3, 60.0).size()
		assert_int(count).is_between(3, 5)
		seen[count] = true
	assert_int(seen.size()).is_equal(3)  # every size shows up


func test_spawns_are_clustered_and_at_spawn_distance() -> void:
	var rng := _rng(7)
	var center := Vector2(50.0, -20.0)
	var spread := deg_to_rad(20.0)
	for i in 50:
		var positions := WaveManager.plan_wave(rng, center, 3, 5, 380.0, spread, 60.0)
		var first_angle := (positions[0] - center).angle()
		for p in positions:
			var distance := (p - center).length()
			assert_float(distance).is_between(380.0 - 0.001, 440.0 + 0.001)
			# Any two enemies in one wave are at most 2 x spread apart.
			var gap := absf(angle_difference(first_angle, (p - center).angle()))
			assert_float(gap).is_less_equal(2.0 * spread + 0.0001)


func test_spawn_wave_announces_each_enemy() -> void:
	var waves := auto_free(WaveManager.new()) as WaveManager
	waves.enemy_scene = load("res://scenes/enemies/Leaf.tscn")
	waves.rng.seed = 3
	var spawned: Array[EnemyBase] = []
	waves.enemy_spawned.connect(func(e: EnemyBase) -> void: spawned.append(e))
	var count := waves.spawn_wave()
	assert_int(count).is_between(3, 5)
	assert_int(spawned.size()).is_equal(count)
	for enemy in spawned:
		enemy.free()
