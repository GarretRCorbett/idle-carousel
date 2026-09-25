class_name EnemyLeafStorm
extends EnemyBoss
## The first boss (Garret + memo S). A big swirl of wind and leaves that never
## latches: it drifts along a fixed arc below the carousel, just out of the
## Wolf's reach, and every so often stops, gathers wind (a visible warning),
## and throws a pack of storm leaves at the carousel. The player clicks the
## Storm; the Wolf and Boost handle the pack. When it dies it bursts into 4
## Grey Leaves, which must also die for the win.
##
## Everything runs on game ticks (advance), so it's exact, pauses with the
## game, and plays the same for the same run seed.

enum Phase { QUIET, GUST, DRIFT, REST }

@export_group("Path")
## Distance of the drift path from the carousel center. Past the Wolf's reach
## (165 px + the Storm's size); the Giraffe (325 px) can reach it.
@export_range(100.0, 400.0, 1.0, "suffix:px") var path_radius: float = 215.0
## The path runs between these screen angles (0 = right, 90 = down), so the
## Storm stays below the carousel, clear of the top strip and side panels.
@export_range(-180.0, 360.0, 1.0, "suffix:°") var arc_from_deg: float = -20.0
@export_range(-180.0, 360.0, 1.0, "suffix:°") var arc_to_deg: float = 200.0
@export_range(-180.0, 360.0, 1.0, "suffix:°") var start_deg: float = 40.0
## How far along the path one drift goes. With drift_seconds this sets its
## speed (30° at 215 px over 4 s: about 28 px/s on average, 42 at most).
@export_range(5.0, 90.0, 1.0, "suffix:°") var drift_step_deg: float = 30.0

@export_group("Rhythm")
## Seconds before the first gust, to find the Storm and start clicking.
@export_range(0.0, 30.0, 0.1, "suffix:s") var quiet_seconds: float = 3.0
## The warning: it stops and gathers wind, then throws the pack.
@export_range(0.1, 10.0, 0.1, "suffix:s") var gust_seconds: float = 1.5
@export_range(0.1, 30.0, 0.1, "suffix:s") var drift_seconds: float = 4.0
@export_range(0.0, 30.0, 0.1, "suffix:s") var rest_seconds: float = 6.5

@export_group("Packs")
## The first pack is smaller, to teach; then every pack is pack_size (Garret: ~20).
@export_range(0, 100, 1) var first_pack_size: int = 14
@export_range(0, 100, 1) var pack_size: int = 20
@export var summon_scene: PackedScene = preload("res://scenes/enemies/Leaf.tscn")
## Storm leaves: 1 health, light latch damage and drag. 20 normal Leaves
## latched at once would stall the carousel every pack.
@export var summon_data: EnemyData = preload("res://resources/enemies/storm_leaf.tres")
## Packs land in two fans, this far to each side of the Storm's bearing...
@export_range(0.0, 90.0, 1.0, "suffix:°") var fan_offset_deg: float = 28.0
## ...each this wide...
@export_range(0.0, 45.0, 1.0, "suffix:°") var fan_spread_deg: float = 14.0
## ...this far from the carousel center: inside the visible play area (the
## side panels start ~330 px out, the Boost button ~280 px below), about 2 s
## from the rim.
@export_range(150.0, 500.0, 1.0, "suffix:px") var pack_distance_min: float = 250.0
@export_range(150.0, 500.0, 1.0, "suffix:px") var pack_distance_max: float = 280.0

@export_group("Death split")
@export_range(0, 12, 1) var split_count: int = 4
@export var split_scene: PackedScene = preload("res://scenes/enemies/Leaf.tscn")
@export var split_data: EnemyData = preload("res://resources/enemies/leaf.tres")
## How far from the Storm's center the split Leaves appear.
@export_range(0.0, 100.0, 1.0, "suffix:px") var split_offset: float = 30.0

@export_group("Wind")
@export var wind_color: Color = Color(0.92, 0.95, 1.0, 0.55)
@export var warning_color: Color = Color(1.0, 0.95, 0.7, 0.8)
## Spin of the wind arcs and the leaf, and how much faster during a gust.
@export_range(0.0, 1080.0, 1.0, "suffix:°/s") var spin_deg_s: float = 90.0
@export_range(1.0, 10.0, 0.1) var gust_spin_multiplier: float = 3.5

var _phase: Phase = Phase.QUIET
var _phase_time: float = 0.0
## Where it is on the path, radians (screen angle from the center).
var _angle: float = 0.0
var _drift_from: float = 0.0
var _drift_to: float = 0.0
var _direction: float = 1.0
var _packs_sent: int = 0
var _wind_angle: float = 0.0
var _rng := RandomNumberGenerator.new()


## Starts on its path (not where it was spawned) with the run's seed, so the
## same run plays the same fight.
func setup(center: Vector2, rim_radius: float) -> void:
	super.setup(center, rim_radius)
	_rng.seed = GameState.get_run_seed() + 7919
	_angle = deg_to_rad(start_deg)
	position = _path_point(_angle)
	_phase = Phase.QUIET
	_phase_time = 0.0
	queue_redraw()


## Never flies at the carousel or latches; it follows its own rhythm.
func advance(delta: float) -> void:
	if not is_active() or delta <= 0.0:
		return
	_phase_time += delta
	var spin := deg_to_rad(spin_deg_s) * delta
	if _phase == Phase.GUST:
		spin *= gust_spin_multiplier
	_wind_angle += spin
	_visual.rotation += spin * 0.5
	match _phase:
		Phase.QUIET:
			if _phase_time >= quiet_seconds:
				_begin(Phase.GUST)
		Phase.GUST:
			if _phase_time >= gust_seconds:
				_throw_pack()
				_begin_drift()
		Phase.DRIFT:
			var t := clampf(_phase_time / drift_seconds, 0.0, 1.0)
			_angle = lerpf(_drift_from, _drift_to, smoothstep(0.0, 1.0, t))
			position = _path_point(_angle)
			if t >= 1.0:
				_begin(Phase.REST)
		Phase.REST:
			if _phase_time >= rest_seconds:
				_begin(Phase.GUST)
	queue_redraw()


func get_phase() -> Phase:
	return _phase


func get_packs_sent() -> int:
	return _packs_sent


## Where the next pack will land: the centers of its two fans (world space).
func get_fan_centers() -> PackedVector2Array:
	var middle := (pack_distance_min + pack_distance_max) / 2.0
	var offset := deg_to_rad(fan_offset_deg)
	return PackedVector2Array([_center + Vector2.from_angle(_angle - offset) * middle,
			_center + Vector2.from_angle(_angle + offset) * middle])


func make_death_split() -> Array[EnemyBase]:
	var children: Array[EnemyBase] = []
	for i in split_count:
		var leaf := split_scene.instantiate() as EnemyBase
		leaf.data = split_data
		leaf.position = position + Vector2.from_angle(TAU * i / split_count + _wind_angle) * split_offset
		children.append(leaf)
	return children


func _begin(phase: Phase) -> void:
	_phase = phase
	_phase_time = 0.0


## The next stretch of the path; turns back at either end.
func _begin_drift() -> void:
	var step := deg_to_rad(drift_step_deg) * _direction
	var low := deg_to_rad(arc_from_deg)
	var high := deg_to_rad(arc_to_deg)
	if _angle + step > high or _angle + step < low:
		_direction = -_direction
		step = -step
	_drift_from = _angle
	_drift_to = clampf(_angle + step, low, high)
	_begin(Phase.DRIFT)


func _throw_pack() -> void:
	var count := first_pack_size if _packs_sent == 0 else pack_size
	_packs_sent += 1
	var pack: Array[EnemyBase] = []
	var offset := deg_to_rad(fan_offset_deg)
	var spread := deg_to_rad(fan_spread_deg)
	for i in count:
		var side := -offset if i % 2 == 0 else offset
		var bearing := _angle + side + _rng.randf_range(-spread, spread)
		var leaf := summon_scene.instantiate() as EnemyBase
		leaf.data = summon_data
		leaf.position = _center + Vector2.from_angle(bearing) * _rng.randf_range(pack_distance_min, pack_distance_max)
		pack.append(leaf)
	summon_requested.emit(pack)


func _path_point(angle: float) -> Vector2:
	return _center + Vector2.from_angle(angle) * path_radius


## Wind arcs around the Storm; during a gust, brighter arcs and rings where
## the pack will land. Drawn on the Storm itself (not Visual), so it doesn't
## flash or tint.
func _draw() -> void:
	var size := data.placeholder_size if data != null else 40.0
	var gusting := _phase == Phase.GUST
	var color := warning_color if gusting else wind_color
	var growth := 1.0 + (0.25 * _phase_time / gust_seconds if gusting else 0.0)
	for i in 3:
		var start := _wind_angle + TAU * i / 3.0
		draw_arc(Vector2.ZERO, size * (1.05 + 0.18 * i) * growth, start, start + 1.9, 16, color, 2.5, true)
	if gusting:
		var pulse := 0.5 + 0.5 * sin(_phase_time * 12.0)
		for center in get_fan_centers():
			draw_arc(center - position, 26.0, 0.0, TAU, 24, Color(warning_color, 0.35 + 0.4 * pulse), 2.0, true)
