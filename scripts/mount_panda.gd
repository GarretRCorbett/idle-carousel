class_name MountPanda
extends MountSweeper
## The all-rounder. Sweeps and damages like the Wolf, only weaker, pays Gold
## once per full turn of the carousel, and heals the carousel when it lands a
## killing hit (Game does that from the kill's attribution and
## MountData.heal_per_kill, so it needs nothing here).


## Full turns come from the carousel's own angle (every multiple of TAU it
## crosses), so the count is exact at any speed and moving the Panda to a new
## slot never pays.
func _on_rotation_advanced(previous_angle: float, delta_angle: float) -> void:
	super._on_rotation_advanced(previous_angle, delta_angle)
	var turns := RotationMath.count_crossings(previous_angle, delta_angle, 0.0)
	if turns > 0:
		gold_earned.emit(self, GameState.get_mount_gold_per_turn(data) * turns)
