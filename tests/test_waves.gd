extends GdUnitTestSuite
## Waves: the random-with-caps roll, cluster layout, and the countdown.

const LEAF: PackedScene = preload("res://scenes/enemies/Leaf.tscn")
const STICK: PackedScene = preload("res://scenes/enemies/Stick.tscn")
const ROCK: PackedScene = preload("res://scenes/enemies/Rock.tscn")
const CATALOG: TierCatalog = preload("res://resources/tiers/tier_catalog.tres")


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _entry(scene: PackedScene, weight: float, cap: int = 0, unlock: int = 0) -> WaveEntry:
	var entry := WaveEntry.new()
	entry.enemy_scene = scene
	entry.weight = weight
	entry.max_per_wave = cap
	entry.unlock_after_kills = unlock
	return entry


## Test fixture: 3-5 enemies; Sticks capped at 1, Rocks locked until 40 kills
## and capped at 2. Weights are high for the capped ones, so caps get tested.
func _profile(interval: float = 15.0) -> WaveProfile:
	var profile := WaveProfile.new()
	profile.interval_seconds = interval
	profile.min_enemies = 3
	profile.max_enemies = 5
	profile.entries = [_entry(LEAF, 10.0), _entry(STICK, 50.0, 1), _entry(ROCK, 50.0, 2, 40)]
	return profile


func _tier(profile: WaveProfile = _profile()) -> TierData:
	var tier := TierData.new()
	tier.tier_id = &"test"
	tier.waves = profile
	return tier


func _count(picks: Array[WaveEntry], scene: PackedScene) -> int:
	return picks.filter(func(e: WaveEntry) -> bool: return e.enemy_scene == scene).size()


# --- The roll -----------------------------------------------------------------------

func test_wave_size_stays_in_range() -> void:
	var rng := _rng(1)
	var profile := _profile()
	var seen := {}
	for i in 200:
		var count := profile.roll(rng, 100).size()
		assert_int(count).is_between(3, 5)
		seen[count] = true
	assert_int(seen.size()).is_equal(3)  # every size shows up


func test_caps_are_never_exceeded() -> void:
	var rng := _rng(2)
	var profile := _profile()
	var saw_stick := false
	var saw_two_rocks := false
	for i in 500:
		var picks := profile.roll(rng, 100)
		assert_int(_count(picks, STICK)).is_less_equal(1)
		assert_int(_count(picks, ROCK)).is_less_equal(2)
		saw_stick = saw_stick or _count(picks, STICK) == 1
		saw_two_rocks = saw_two_rocks or _count(picks, ROCK) == 2
	assert_bool(saw_stick and saw_two_rocks).is_true()  # the caps were actually reached


func test_locked_entries_never_appear_before_their_kills() -> void:
	var rng := _rng(3)
	var profile := _profile()
	for i in 300:
		assert_int(_count(profile.roll(rng, 39), ROCK)).is_equal(0)
	var rocks := 0
	for i in 100:
		rocks += _count(profile.roll(rng, 40), ROCK)
	assert_int(rocks).is_greater(0)


func test_same_seed_gives_the_same_waves() -> void:
	var profile := _profile()
	var a := _rng(42)
	var b := _rng(42)
	for i in 50:
		var first := profile.roll(a, 100)
		var second := profile.roll(b, 100)
		assert_array(first).is_equal(second)


## Every real tier can always fill a wave, even with nothing unlocked yet (memo O8).
func test_every_tier_can_fill_a_wave() -> void:
	var rng := _rng(4)
	for tier in CATALOG.tiers:
		assert_array(tier.waves.get_problems()).is_empty()
		for kills: int in [0, 1000]:
			for i in 100:
				var picks := tier.waves.roll(rng, kills)
				assert_int(picks.size()).is_between(tier.waves.min_enemies, tier.waves.max_enemies)


func test_grey_starts_with_leaves_only_and_green_adds_rocks_later() -> void:
	var rng := _rng(5)
	var grey := CATALOG.get_tier(0).waves
	var green := CATALOG.get_tier(1).waves
	for i in 200:
		var picks := grey.roll(rng, 0)
		assert_int(_count(picks, STICK) + _count(picks, ROCK)).is_equal(0)
		assert_int(_count(green.roll(rng, 0), ROCK)).is_equal(0)


func test_profile_validation() -> void:
	var profile := _profile()
	assert_array(profile.get_problems()).is_empty()
	profile.entries[0].max_per_wave = 3  # no uncapped filler left
	assert_array(profile.get_problems()).is_not_empty()
	profile = _profile()
	profile.entries[1].weight = -1.0
	assert_array(profile.get_problems()).is_not_empty()
	profile = _profile()
	profile.entries[1].weight = INF
	assert_array(profile.get_problems()).is_not_empty()
	profile = _profile()
	profile.min_enemies = 6
	assert_array(profile.get_problems()).is_not_empty()
	profile = _profile()
	profile.interval_seconds = 0.0
	assert_array(profile.get_problems()).is_not_empty()


# --- Layout -------------------------------------------------------------------------

func test_spawns_are_clustered_and_at_spawn_distance() -> void:
	var rng := _rng(7)
	var center := Vector2(50.0, -20.0)
	var spread := deg_to_rad(20.0)
	for i in 50:
		var positions := WaveManager.plan_positions(rng, center, 5, 1, 380.0, spread, 60.0)
		var first_angle := (positions[0] - center).angle()
		for p in positions:
			var distance := (p - center).length()
			assert_float(distance).is_between(380.0 - 0.001, 440.0 + 0.001)
			# Any two enemies in one wave are at most 2 x spread apart.
			var gap := absf(angle_difference(first_angle, (p - center).angle()))
			assert_float(gap).is_less_equal(2.0 * spread + 0.0001)


func test_clusters_come_from_evenly_spread_directions() -> void:
	var rng := _rng(8)
	var spread := deg_to_rad(10.0)
	var positions := WaveManager.plan_positions(rng, Vector2.ZERO, 6, 3, 380.0, spread, 0.0)
	# Enemy i is in cluster i % 3; clusters sit a third of a turn apart.
	for i in 3:
		var a := positions[i].angle()
		var b := positions[(i + 1) % 3].angle()
		assert_float(absf(angle_difference(a, b))).is_between(TAU / 3.0 - 2.0 * spread - 0.0001, TAU / 3.0 + 2.0 * spread + 0.0001)
		var same_cluster := positions[i + 3].angle()
		assert_float(absf(angle_difference(a, same_cluster))).is_less_equal(2.0 * spread + 0.0001)


func test_spawn_wave_announces_each_enemy_with_its_tier() -> void:
	var waves := auto_free(WaveManager.new()) as WaveManager
	var tier := _tier()
	tier.health_multiplier = 3.0
	waves.tier = tier
	waves.rng.seed = 3
	var spawned: Array[EnemyBase] = []
	waves.enemy_spawned.connect(func(e: EnemyBase) -> void: spawned.append(e))
	var count := waves.spawn_wave()
	assert_int(count).is_between(3, 5)
	assert_int(spawned.size()).is_equal(count)
	for enemy in spawned:
		assert_float(enemy.get_max_health()).is_equal_approx(enemy.data.base_health * 3.0, 0.00001)
		enemy.free()


## Unlocks read the kill count Game hands over.
func test_spawn_wave_uses_the_tier_kill_count() -> void:
	var waves := auto_free(WaveManager.new()) as WaveManager
	var profile := _profile()
	profile.entries = [_entry(LEAF, 1.0), _entry(ROCK, 1000.0, 0, 5)]
	waves.tier = _tier(profile)
	var kills: Array[int] = [0]
	waves.tier_kills = func() -> int: return kills[0]
	var scenes: Array[String] = []
	waves.enemy_spawned.connect(func(e: EnemyBase) -> void:
		scenes.append(e.scene_file_path)
		_spawned.append(e))
	waves.spawn_wave()
	assert_bool(scenes.has(ROCK.resource_path)).is_false()
	kills[0] = 5
	scenes.clear()
	waves.spawn_wave()
	assert_bool(scenes.has(ROCK.resource_path)).is_true()


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
	waves.tier = _tier(_profile(15.0))
	waves.first_wave_delay = 7.0
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


## A new tier's interval applies from the next countdown.
func test_interval_comes_from_the_tier() -> void:
	var waves := _running_waves()
	waves.start()
	waves.tier = _tier(_profile(20.0))
	assert_float(waves.get_seconds_left()).is_equal_approx(7.0, 0.001)
	waves.restart_countdown()
	assert_float(waves.get_seconds_left()).is_equal_approx(20.0, 0.001)
