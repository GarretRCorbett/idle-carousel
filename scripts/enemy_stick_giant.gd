class_name EnemyStickGiant
extends EnemyBoss
## The Green boss: a huge Stick that zigzags on its way in, swinging side to
## side so the Giraffe's long line has a harder time catching it, then latches
## with heavy drag. Its bearing crosses back and forth; the unwrapped bearings
## (Phase 3 Step 2) keep that from ever counting as an extra sweep pass.

## How far its bearing swings each way while it flies in.
@export_range(0.0, 60.0, 1.0, "suffix:°") var zigzag_degrees: float = 18.0
## Full swings (there and back) per second.
@export_range(0.0, 3.0, 0.05, "suffix:Hz") var zigzag_hz: float = 0.3
## Rocking of the stick itself, like the ordinary Stick's sway.
@export_range(0.0, 90.0, 1.0, "suffix:°") var sway_degrees: float = 12.0

var _base_bearing: float = 0.0
var _distance: float = 0.0
var _zigzag_time: float = 0.0


func setup(center: Vector2, rim_radius: float) -> void:
	super.setup(center, rim_radius)
	_base_bearing = (position - center).angle()
	_distance = (position - center).length()


## Straight in, with the bearing swinging; stops at the rim like any enemy.
func advance(delta: float) -> void:
	if not is_active() or delta <= 0.0:
		return
	var speed_factor := _advance_status(delta)
	if _state != State.APPROACHING:
		return
	_zigzag_time += delta * speed_factor
	var swing := sin(TAU * zigzag_hz * _zigzag_time)
	_visual.rotation = deg_to_rad(sway_degrees) * swing
	_distance = maxf(_stop_distance, _distance - get_move_speed() * speed_factor * delta)
	position = _center + Vector2.from_angle(get_bearing_now()) * _distance
	if _distance <= _stop_distance:
		_state = State.AT_RIM
		reached_rim.emit(self)


## Where it's heading right now (the base bearing plus the swing).
func get_bearing_now() -> float:
	return _base_bearing + deg_to_rad(zigzag_degrees) * sin(TAU * zigzag_hz * _zigzag_time)
