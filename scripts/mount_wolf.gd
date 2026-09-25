class_name MountWolf
extends MountBase
## The cleaner. Its line reaches outward from its slot by data.sweep_range and
## sweeps round as the carousel turns. Every enemy the line crosses is hit,
## each once per pass (it pierces). Hits come from angle math (MountSweep),
## like booth passes, so nothing is missed at any spin speed. A stopped
## carousel sends no rotation, so a stopped Wolf deals no damage.

@export_group("Reach Line")
## Faint line showing how far the Wolf reaches, so reach is easy to tune.
@export var reach_line_color: Color = Color(1.0, 1.0, 1.0, 0.2)
@export_range(0.5, 10.0, 0.5, "suffix:px") var reach_line_width: float = 2.0

var _enemy_layer: Node
var _sweep: MountSweep = MountSweep.new()


func set_enemy_layer(layer: Node) -> void:
	_enemy_layer = layer
	rebase()


## Anything already under the line counts as hit on this pass, so placing or
## moving a Wolf gives no free hit.
func rebase() -> void:
	if _enemy_layer == null:
		return
	_update_sweep_shape()
	_sweep.rebase(_live_enemies(), _carousel.global_position, _carousel.get_unwrapped_angle() + get_slot_angle())


func forget_enemy(id: int) -> void:
	_sweep.forget(id)


func _on_rotation_advanced(previous_angle: float, delta_angle: float) -> void:
	if _enemy_layer == null or delta_angle <= 0.0:
		return
	_update_sweep_shape()
	var hits: Array[EnemyBase] = _sweep.collect(_live_enemies(), _carousel.global_position, previous_angle + get_slot_angle(), delta_angle)
	for enemy in hits:
		# A long tick can list an enemy twice; the first hit may have killed it.
		if is_instance_valid(enemy) and enemy.can_receive_click():
			enemy_swept.emit(self, enemy)


func _update_sweep_shape() -> void:
	_sweep.inner_radius = get_slot_radius()
	_sweep.reach = data.sweep_range


func _live_enemies() -> Array[EnemyBase]:
	var enemies: Array[EnemyBase] = []
	for child in _enemy_layer.get_children():
		var enemy := child as EnemyBase
		if enemy != null and enemy.can_receive_click() and not enemy.is_queued_for_deletion():
			enemies.append(enemy)
	return enemies


func _draw() -> void:
	if data != null:
		draw_line(Vector2.ZERO, Vector2(data.sweep_range, 0.0), reach_line_color, reach_line_width, true)
	super._draw()
