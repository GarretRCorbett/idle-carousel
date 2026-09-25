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
## Spawned enemies, freed after each test. Freeing them inside the signal would
## hand later listeners a freed object (and their checks would silently skip).
var _spawned: Array[EnemyBase] = []


func after_test() -> void:
	for enemy in _spawned:
		if is_instance_valid(enemy):
			enemy.free()
	_spawned.clear()


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
		_spawned.append(e))
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


func test_sending_early_restarts_the_countdown_and_marks_bonus_gold() -> void:
	var waves := _running_waves()
	var multipliers: Array[float] = []
	waves.enemy_spawned.connect(func(e: EnemyBase) -> void: multipliers.append(e.get_kill_gold() / e.data.gold_drop))
	waves.start()
	_sent = 0
	var count := waves.send_wave_now()
	assert_int(_sent).is_equal(count)
	assert_float(waves.get_seconds_left()).is_equal_approx(15.0, 0.001)
	assert_int(multipliers.size()).is_equal(count)
	for m in multipliers:
		assert_float(m).is_equal(waves.early_send_gold_multiplier)


func test_timed_waves_have_no_bonus() -> void:
	var waves := _running_waves()
	var multipliers: Array[float] = []
	waves.enemy_spawned.connect(func(e: EnemyBase) -> void: multipliers.append(e.get_kill_gold() / e.data.gold_drop))
	waves.start()
	_sent = 0
	waves._on_wave_timer_timeout()
	assert_int(multipliers.size()).is_greater(0)
	assert_int(multipliers.size()).is_equal(_sent)
	for m in multipliers:
		assert_float(m).is_equal(1.0)


func test_auto_off_pauses_the_countdown() -> void:
	var waves := _running_waves()
	var seen: Array[bool] = []
	waves.auto_changed.connect(func(on: bool) -> void: seen.append(on))
	waves.start()
	waves.set_auto(false)
	assert_bool((waves.get_node("WaveTimer") as Timer).paused).is_true()
	waves.send_wave_now()  # sending still works, and the new countdown stays paused
	assert_bool((waves.get_node("WaveTimer") as Timer).paused).is_true()
	waves.set_auto(true)
	assert_bool((waves.get_node("WaveTimer") as Timer).paused).is_false()
	assert_array(seen).is_equal([false, true])


## Send wave is blocked while too many enemies are alive; auto waves aren't.
func test_send_wave_is_blocked_above_the_live_enemy_limit() -> void:
	var waves := _running_waves()
	var live: Array[int] = [4]
	waves.live_enemy_count = func() -> int: return live[0]
	waves.max_live_enemies_to_send = 3
	waves.start()
	_sent = 0
	assert_bool(waves.can_send_wave()).is_false()
	assert_int(waves.send_wave_now()).is_equal(0)
	assert_int(_sent).is_equal(0)
	waves._on_wave_timer_timeout()  # the timer still sends
	assert_int(_sent).is_greater(0)
	live[0] = 3
	assert_bool(waves.can_send_wave()).is_true()
	assert_int(waves.send_wave_now()).is_greater(0)


## Send works at exactly the limit, not one over it.
func test_send_limit_boundary() -> void:
	var waves := _running_waves()
	var live: Array[int] = [30]
	waves.live_enemy_count = func() -> int: return live[0]
	waves.max_live_enemies_to_send = 30
	assert_bool(waves.can_send_wave()).is_true()
	live[0] = 31
	assert_bool(waves.can_send_wave()).is_false()
