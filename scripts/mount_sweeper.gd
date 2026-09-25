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

## Smoothness of the wedge outline.
const WEDGE_SEGMENTS := 12

var _snapshot: EnemySnapshot
var _sweep: MountSweep = MountSweep.new()


func set_enemy_snapshot(snapshot: EnemySnapshot) -> void:
	_snapshot = snapshot
	rebase()


## Anything already under the line counts as hit on this pass, so placing or
## moving a mount gives no free hit.
func rebase() -> void:
	_update_sweep_shape()
	if _snapshot == null:
		return
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


## Copies the current shape into the sweep, and redraws the reach marker if
## it changed (placement, or a tier upgrade).
func _update_sweep_shape() -> void:
	var inner := get_slot_radius()
	var reach := GameState.get_mount_reach(data)
	var half_arc := deg_to_rad(GameState.get_mount_arc(data)) / 2.0
	if inner != _sweep.inner_radius or reach != _sweep.reach or half_arc != _sweep.half_arc:
		queue_redraw()
	_sweep.inner_radius = inner
	_sweep.reach = reach
	_sweep.half_arc = half_arc


## The reach marker: a line, or for a wedge mount (Elephant) the outline of
## the wedge. The wedge is centered on the carousel, which sits at
## (-slot radius, 0) in this mount's own space (its +X points outward).
func _draw() -> void:
	if data != null:
		if _sweep.half_arc <= 0.0:
			draw_line(Vector2.ZERO, Vector2(_sweep.reach, 0.0), reach_line_color, reach_line_width, true)
		else:
			var center := Vector2(-_sweep.inner_radius, 0.0)
			var outer := _sweep.inner_radius + _sweep.reach
			var points := PackedVector2Array()
			for i in WEDGE_SEGMENTS + 1:
				var angle := lerpf(-_sweep.half_arc, _sweep.half_arc, float(i) / WEDGE_SEGMENTS)
				points.append(center + Vector2.from_angle(angle) * outer)
			for i in range(WEDGE_SEGMENTS, -1, -1):
				var angle := lerpf(-_sweep.half_arc, _sweep.half_arc, float(i) / WEDGE_SEGMENTS)
				points.append(center + Vector2.from_angle(angle) * _sweep.inner_radius)
			draw_colored_polygon(points, Color(reach_line_color, reach_line_color.a * 0.5))
			points.append(points[0])
			draw_polyline(points, reach_line_color, reach_line_width, true)
	super._draw()
