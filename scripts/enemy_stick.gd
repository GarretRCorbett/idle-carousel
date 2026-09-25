class_name EnemyStick
extends EnemyBase
## The bruiser. Rocks side to side as it flies in, like a stick tumbling
## loosely end over end, instead of spinning like the Leaf. Stops once it
## grabs the rim.

## How far it rocks each way from its starting angle.
@export_range(0.0, 90.0, 1.0, "suffix:°") var sway_degrees: float = 20.0
## Full rocks (there and back) per second.
@export_range(0.0, 10.0, 0.05, "suffix:Hz") var sway_hz: float = 0.9

## Seconds of swaying so far, started at a random point so Sticks in one wave
## don't rock in step.
var _sway_time: float = 0.0


func _ready() -> void:
	super._ready()
	_sway_time = randf() / maxf(sway_hz, 0.001)


## Visual only (rotation of Visual); movement and hits are unchanged.
func advance(delta: float) -> void:
	super.advance(delta)
	if _state == State.APPROACHING:
		_sway_time += delta
		_visual.rotation = deg_to_rad(sway_degrees) * sin(TAU * sway_hz * _sway_time)
