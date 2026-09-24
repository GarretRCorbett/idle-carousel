class_name EnemyLeaf
extends EnemyBase
## The swarmer: small, fast, low health. Tumbles as it flies in.

## Spin of the drawn shape while approaching. Stops once it grabs the rim.
@export_range(-1080.0, 1080.0, 1.0, "suffix:°/s") var tumble_speed_deg_s: float = 240.0


func advance(delta: float) -> void:
	super.advance(delta)
	if _state == State.APPROACHING:
		_visual.rotation += deg_to_rad(tumble_speed_deg_s) * delta
