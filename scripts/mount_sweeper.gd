class_name MountSweeper
extends MountBase
## Any mount whose line (or wedge) sweeps round with the carousel: the Wolf,
## the Giraffe (a much longer line), and the base for the Sloth, Elephant and
## Panda. The line reaches outward from its slot by data.sweep_range, widened
## to a wedge by data.sweep_arc. Every enemy it crosses is reported once per
## pass (it pierces); Game applies the damage and calls apply_sweep(). Hits
## come from angle math (MountSweep), like booth passes, so nothing is missed
## at any spin speed. A stopped carousel sends no rotation, so it does nothing.

@export_group("Reach Line")
## Faint line showing how far the mount reaches, so reach is easy to tune.
@export var reach_line_color: Color = Color(1.0, 1.0, 1.0, 0.2)
@export_range(0.5, 10.0, 0.5, "suffix:px") var reach_line_width: float = 2.0

var _snapshot: EnemySnapshot
var _sweep: MountSweep = MountSweep.new()


func set_enemy_snapshot(snapshot: EnemySnapshot) -> void:
	_snapshot = snapshot
	rebase()


## Anything already under the line counts as hit on this pass, so placing or
## moving a mount gives no free hit.
func rebase() -> void:
	if _snapshot == null:
		return
	_update_sweep_shape()
	_sweep.rebase(_snapshot, _carousel.get_unwrapped_angle() + get_slot_angle())


func forget_enemy(id: int) -> void:
	_sweep.forget(id)


func _on_rotation_advanced(previous_angle: float, delta_angle: float) -> void:
	if _snapshot == null or delta_angle <= 0.0:
		return
	_update_sweep_shape()
	var hits: Array[EnemyBase] = _sweep.collect(_snapshot, previous_angle + get_slot_angle(), delta_angle)
	for enemy in hits:
		# A long tick can list an enemy twice; the first hit may have killed it.
		if is_instance_valid(enemy) and enemy.is_active():
			enemy_swept.emit(self, enemy)


func _update_sweep_shape() -> void:
	_sweep.inner_radius = get_slot_radius()
	_sweep.reach = data.sweep_range
	_sweep.half_arc = deg_to_rad(data.sweep_arc) / 2.0


func _draw() -> void:
	if data != null:
		draw_line(Vector2.ZERO, Vector2(data.sweep_range, 0.0), reach_line_color, reach_line_width, true)
	super._draw()
