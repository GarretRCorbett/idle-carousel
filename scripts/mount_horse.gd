class_name MountHorse
extends MountBase
## The generator. Each time it passes the ticket booth it reports a pass; Game
## pays data.base_gold_bonus per pass. The payout is fixed; faster spin only
## means more passes (GDD v1.4).

signal booth_passed(horse: MountHorse, pass_count: int)

## The booth's direction from the carousel center, in World space.
var _booth_bearing: float = 0.0


func set_booth_bearing(bearing: float) -> void:
	_booth_bearing = bearing


## Uses only the carousel's travel, never the slot position, so moving the
## Horse to a new slot can't count as a pass.
func _on_rotation_advanced(previous_angle: float, delta_angle: float) -> void:
	var passes := RotationMath.count_crossings(previous_angle + get_slot_angle(), delta_angle, _booth_bearing)
	if passes > 0:
		booth_passed.emit(self, passes)
