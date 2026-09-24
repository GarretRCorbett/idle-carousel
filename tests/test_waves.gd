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


# --- Countdown ---------------------------------------------------------------------

var _sent: int = 0


func _running_waves() -> WaveManager:
	var waves := WaveManager.new()
	var timer := Timer.new()
	timer.name = "WaveTimer"
	waves.add_child(timer)
	waves.enemy_scene = load("res://scenes/enemies/Leaf.tscn")
	waves.first_wave_delay = 7.0
	waves.wave_interval = 15.0
	add_child(waves)
	auto_free(waves)
	waves.enemy_spawned.connect(func(e: EnemyBase) -> void:
		_sent += 1
		e.free())
	return waves


func test_first_wave_uses_the_first_delay() -> void:
	var waves := _running_waves()
	var shown: Array[int] = []
	waves.countdown_changed.connect(func(s: int) -> void: shown.append(s))
	waves.start()
	assert_float(waves.get_seconds_left()).is_equal_approx(7.0, 0.001)
	assert_array(shown).is_equal([7])


func test_each_wave_restarts_the_countdown_at_the_interval() -> void:
	_sent = 0
	var waves := _running_waves()
	waves.start()
	waves._on_wave_timer_timeout()
	assert_int(_sent).is_between(3, 5)
	assert_float(waves.get_seconds_left()).is_equal_approx(15.0, 0.001)


func test_restart_countdown_sends_no_wave() -> void:
	_sent = 0
	var waves := _running_waves()
	waves.start()
	waves.restart_countdown()
	assert_int(_sent).is_equal(0)
	assert_float(waves.get_seconds_left()).is_equal_approx(15.0, 0.001)
