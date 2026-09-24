class_name RotationMath
extends RefCounted
## Pure angle math for the rotating carousel. Angles are in radians and
## "unwrapped": they keep growing past 2π instead of wrapping, so no full
## turn is ever lost.


## How many times a point moving from previous_angle by delta_angle reaches
## target_angle (any multiple of a full turn counts).
## "Arrival counts, departure doesn't": ending exactly on the target counts;
## starting on it doesn't, so a boundary is never counted twice.
static func count_crossings(previous_angle: float, delta_angle: float, target_angle: float) -> int:
	var start_turns := (previous_angle - target_angle) / TAU
	var end_turns := (previous_angle + delta_angle - target_angle) / TAU
	if delta_angle > 0.0:
		return floori(end_turns) - floori(start_turns)
	if delta_angle < 0.0:
		return ceili(start_turns) - ceili(end_turns)
	return 0
