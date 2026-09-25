class_name MountHorse
extends MountBase
## The generator. Each time it passes a ticket booth it reports a pass; Game
## pays GameState.get_mount_gold(data) per pass (Tier 2 doubles it). The payout is fixed; faster spin only
## means more passes (GDD v1.4).

## Each booth's direction from the carousel center, in World space.
var _booth_bearings: Array[float] = []


func set_booth_bearings(bearings: Array[float]) -> void:
	_booth_bearings = bearings.duplicate()


## Uses only the carousel's travel, never the slot or booth positions, so
## moving the Horse or re-spacing the booths can't count as a pass.
func _on_rotation_advanced(previous_angle: float, delta_angle: float) -> void:
	var start := previous_angle + get_slot_angle()
	for i in _booth_bearings.size():
		var passes := RotationMath.count_crossings(start, delta_angle, _booth_bearings[i])
		if passes > 0:
			booth_passed.emit(self, i, passes)
