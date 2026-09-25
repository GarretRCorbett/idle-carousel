class_name WaveManager
extends Node
## Sends waves of enemies on a countdown that always runs, whether or not the
## last wave is cleared (GDD). A wave is one cluster from a random direction,
## spread a little sideways and staggered outward so they arrive one after
## another. It only creates enemies; Game adds them to the world and wires them.

signal enemy_spawned(enemy: EnemyBase)
## Whole seconds until the next wave, rounded up. Emitted when it changes.
signal countdown_changed(seconds_left: int)
## Auto waves turned on or off.
signal auto_changed(on: bool)
## Send wave became allowed or blocked (too many enemies alive).
signal send_available_changed(available: bool)

@export var enemy_scene: PackedScene

@export_group("Timing")
## Seconds from the start of a run to the first wave.
@export_range(0.0, 600.0, 0.5, "suffix:s") var first_wave_delay: float = 10.0
## Seconds between waves after that.
@export_range(1.0, 600.0, 0.5, "suffix:s") var wave_interval: float = 20.0
## Leaves in a wave you send early drop this much Gold (1.5 = +50%).
@export_range(1.0, 10.0, 0.05) var early_send_gold_multiplier: float = 1.5

@export_group("Wave Shape")
@export_range(1, 50, 1) var min_group: int = 3
@export_range(1, 50, 1) var max_group: int = 5
## Distance from the carousel center where enemies appear (just off-screen).
@export_range(100.0, 2000.0, 1.0, "suffix:px") var spawn_radius: float = 380.0
## Each enemy's direction is within ± this of the wave's direction.
@export_range(0.0, 180.0, 1.0, "suffix:°") var cluster_spread_deg: float = 20.0
## Each enemy starts up to this much further out, so they don't arrive stacked.
@export_range(0.0, 500.0, 1.0, "suffix:px") var cluster_depth_px: float = 60.0

@export_group("Controls")
## This key sends the next wave right away (Garret wants it kept as a real control).
@export var send_wave_key: Key = KEY_N
## Send wave is blocked while more enemies than this are alive, so waves can't be
## stacked without limit (Garret, 2026-09-24; revisit with Sticks and Rocks).
## Auto waves still come on their timer. 0 = no limit.
@export_range(0, 1000, 1) var max_live_enemies_to_send: int = 30

## Where the carousel center is, in World space. Set by Game.
var center: Vector2 = Vector2.ZERO
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


## Starts the countdown to the first wave. Game calls this when a run starts.
func start() -> void:
	_timer.start(first_wave_delay)
	_timer.paused = not _auto
	_emit_countdown_if_changed()


## Restarts the countdown at a full wave_interval without sending a wave.
func restart_countdown() -> void:
	_timer.start(wave_interval)
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


## Creates one wave and announces each enemy. Returns how many were sent.
func spawn_wave(gold_multiplier: float = 1.0) -> int:
	var positions := plan_wave(rng, center, min_group, max_group,
			spawn_radius, deg_to_rad(cluster_spread_deg), cluster_depth_px)
	for spawn_position in positions:
		var enemy := enemy_scene.instantiate() as EnemyBase
		enemy.position = spawn_position
		enemy.gold_multiplier = gold_multiplier
		enemy_spawned.emit(enemy)
	return positions.size()


## Start positions for one wave: min..max enemies clustered around one random
## direction. Pure math, so tests can check it with a seeded RNG.
static func plan_wave(random: RandomNumberGenerator, wave_center: Vector2,
		group_min: int, group_max: int, radius: float,
		spread_rad: float, depth: float) -> PackedVector2Array:
	var positions := PackedVector2Array()
	var count := random.randi_range(mini(group_min, group_max), maxi(group_min, group_max))
	var bearing := random.randf_range(-PI, PI)
	for i in count:
		var direction := bearing + random.randf_range(-spread_rad, spread_rad)
		var distance := radius + random.randf_range(0.0, depth)
		positions.append(wave_center + Vector2.from_angle(direction) * distance)
	return positions
