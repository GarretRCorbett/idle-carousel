class_name WaveManager
extends Node
## Sends waves of enemies on a countdown that always runs, whether or not the
## last wave is cleared (GDD). What a wave holds, how often it comes, and from
## how many directions come from the current tier's WaveProfile. Each cluster
## is spread a little sideways and staggered outward so enemies arrive one
## after another. It only creates enemies (with their tier stats fixed); Game
## adds them to the world and wires them.

signal enemy_spawned(enemy: EnemyBase)
## Whole seconds until the next wave, rounded up. Emitted when it changes.
signal countdown_changed(seconds_left: int)
## Auto waves turned on or off.
signal auto_changed(on: bool)
## Send wave became allowed or blocked (too many enemies alive).
signal send_available_changed(available: bool)

@export_group("Timing")
## Seconds from the start of a run to the first wave.
@export_range(0.0, 600.0, 0.5, "suffix:s") var first_wave_delay: float = 10.0
## Leaves in a wave you send early drop this much Gold (1.5 = +50%).
@export_range(1.0, 10.0, 0.05) var early_send_gold_multiplier: float = 1.5

@export_group("Wave Shape")
## Distance from the carousel center where enemies appear (just off-screen).
@export_range(100.0, 2000.0, 1.0, "suffix:px") var spawn_radius: float = 380.0
## Each enemy's direction is within ± this of the wave's direction.
@export_range(0.0, 180.0, 1.0, "suffix:°") var cluster_spread_deg: float = 30.0
## Each enemy starts up to this much further out, so they don't arrive stacked.
@export_range(0.0, 500.0, 1.0, "suffix:px") var cluster_depth_px: float = 120.0

@export_group("Controls")
## This key sends the next wave right away (Garret wants it kept as a real control).
@export var send_wave_key: Key = KEY_N
## Send wave is blocked while more enemies than this are alive, so waves can't be
## stacked without limit (Garret, 2026-09-24; revisit with Sticks and Rocks).
## Auto waves still come on their timer. 0 = no limit.
@export_range(0, 1000, 1) var max_live_enemies_to_send: int = 30

## Where the carousel center is, in World space. Set by Game.
var center: Vector2 = Vector2.ZERO
## The tier new waves come from. Set by Game; enemies already alive keep theirs.
var tier: TierData
## Returns kills so far in the current tier, for WaveEntry unlocks. Set by
## Game. Unset = 0 (only entries unlocked from the start appear).
var tier_kills: Callable
## Seeded once per run (GameState's run seed), so the same seed gives the
## same waves.
var rng := RandomNumberGenerator.new()
var _shown_seconds: int = -1
var _auto: bool = true
## Returns how many enemies are alive or waiting to join, for the Send limit.
## Set by Game. Unset = no limit.
var live_enemy_count: Callable
var _send_available: bool = true

@onready var _timer: Timer = $WaveTimer


func _ready() -> void:
	_timer.one_shot = true
	_timer.timeout.connect(_on_wave_timer_timeout)


## Starts the countdown to the first wave, with wave randomness seeded from
## `seed_value`. Game calls this when a run starts.
func start(seed_value: int = 0) -> void:
	rng.seed = seed_value
	_timer.start(first_wave_delay)
	_timer.paused = not _auto
	_emit_countdown_if_changed()


## Seconds between waves in the current tier.
func get_wave_interval() -> float:
	return tier.waves.interval_seconds


## Restarts the countdown at a full interval without sending a wave. A new
## tier's interval applies from here.
func restart_countdown() -> void:
	_timer.start(get_wave_interval())
	_timer.paused = not _auto
	_emit_countdown_if_changed()


## Sends the next wave right now (Send button or N). Its Leaves drop bonus
## Gold, and the countdown restarts, so waves never pile up by accident.
func send_wave_now() -> int:
	if not can_send_wave():
		return 0
	var count := spawn_wave(early_send_gold_multiplier)
	restart_countdown()
	return count


## Off: the countdown pauses and waves only come when sent.
## False while more than max_live_enemies_to_send enemies are alive.
func can_send_wave() -> bool:
	if max_live_enemies_to_send <= 0 or not live_enemy_count.is_valid():
		return true
	return live_enemy_count.call() <= max_live_enemies_to_send


func set_auto(on: bool) -> void:
	if on == _auto:
		return
	_auto = on
	_timer.paused = not on
	auto_changed.emit(on)


func is_auto() -> bool:
	return _auto


func get_seconds_left() -> float:
	return _timer.time_left


func _process(_delta: float) -> void:
	_emit_countdown_if_changed()
	var available := can_send_wave()
	if available != _send_available:
		_send_available = available
		send_available_changed.emit(available)


func _on_wave_timer_timeout() -> void:
	spawn_wave()
	restart_countdown()


func _emit_countdown_if_changed() -> void:
	var seconds := ceili(_timer.time_left)
	if seconds != _shown_seconds:
		_shown_seconds = seconds
		countdown_changed.emit(seconds)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == send_wave_key:
		send_wave_now()
		get_viewport().set_input_as_handled()


## Creates one wave from the current tier and announces each enemy, its
## stats already fixed for the tier (and gold_multiplier for early sends).
## Returns how many were sent.
func spawn_wave(gold_multiplier: float = 1.0) -> int:
	var kills: int = tier_kills.call() if tier_kills.is_valid() else 0
	var picks := tier.waves.roll(rng, kills)
	var positions := plan_positions(rng, center, picks.size(), tier.waves.directions,
			spawn_radius, deg_to_rad(cluster_spread_deg), cluster_depth_px)
	for i in picks.size():
		var enemy := picks[i].enemy_scene.instantiate() as EnemyBase
		enemy.position = positions[i]
		enemy.configure(tier, gold_multiplier)
		enemy_spawned.emit(enemy)
	return picks.size()


## Start positions for `count` enemies in `clusters` groups, evenly spread
## round from a random first direction; enemy i joins cluster i % clusters.
## Pure math, so tests can check it with a seeded RNG.
static func plan_positions(random: RandomNumberGenerator, wave_center: Vector2,
		count: int, clusters: int, radius: float,
		spread_rad: float, depth: float) -> PackedVector2Array:
	var positions := PackedVector2Array()
	var first_bearing := random.randf_range(-PI, PI)
	clusters = maxi(1, clusters)
	for i in count:
		var bearing := first_bearing + TAU * (i % clusters) / clusters
		var direction := bearing + random.randf_range(-spread_rad, spread_rad)
		var distance := radius + random.randf_range(0.0, depth)
		positions.append(wave_center + Vector2.from_angle(direction) * distance)
	return positions
