class_name MountWolf
extends MountBase
## The cleaner. Its line reaches outward from its slot by data.sweep_range and
## sweeps round as the carousel turns. Every enemy the line crosses is hit,
## each once per pass (it pierces). Hits come from angle math, like booth
## passes, so nothing is missed at any spin speed. A stopped carousel sends no
## rotation, so a stopped Wolf deals no damage.

@export_group("Reach Line")
## Faint line showing how far the Wolf reaches, so reach is easy to tune.
@export var reach_line_color: Color = Color(1.0, 1.0, 1.0, 0.2)
@export_range(0.5, 10.0, 0.5, "suffix:px") var reach_line_width: float = 2.0

var _enemy_layer: Node
## The last pass each enemy was hit on, by instance ID. A pass is one trip of
## the line across that enemy, so it's hit again only after a full turn.
var _last_hit_pass: Dictionary[int, int] = {}


func set_enemy_layer(layer: Node) -> void:
	_enemy_layer = layer
	rebase()


## Anything already under the line counts as hit on this pass, so placing or
## moving a Wolf gives no free hit.
func rebase() -> void:
	if _enemy_layer == null:
		return
	var angle := _carousel.get_unwrapped_angle() + get_slot_angle()
	for enemy in _live_enemies():
		var window := _window_of(enemy)
		if window.y < 0.0:
			continue
		var pass_index := roundi((angle - window.x) / TAU)
		if absf(angle - window.x - pass_index * TAU) <= window.y:
			_last_hit_pass[enemy.get_instance_id()] = pass_index


## Game calls this when an enemy is removed, so the list doesn't grow forever.
func forget_enemy(id: int) -> void:
	_last_hit_pass.erase(id)


func _on_rotation_advanced(previous_angle: float, delta_angle: float) -> void:
	if _enemy_layer == null or delta_angle <= 0.0:
		return
	var start := previous_angle + get_slot_angle()
	for enemy in _live_enemies():
		var window := _window_of(enemy)
		if window.y < 0.0:
			continue
		var passes := RotationMath.sweep_passes(start, delta_angle, window.x, window.y)
		var id := enemy.get_instance_id()
		var first := maxi(passes.x, _last_hit_pass.get(id, passes.x - 1) + 1)
		for pass_index in range(first, passes.y + 1):
			if not enemy.can_receive_click():
				break
			_last_hit_pass[id] = pass_index
			enemy_swept.emit(self, enemy)


## The enemy's bearing from the carousel center and its angular half-width,
## as Vector2(bearing, half_width). half_width is -1 if it's out of reach.
func _window_of(enemy: EnemyBase) -> Vector2:
	var offset := enemy.global_position - _carousel.global_position
	var distance := offset.length()
	var hitbox := enemy.data.hitbox_radius
	var inner := get_slot_radius()
	var outer := inner + data.sweep_range
	if distance + hitbox < inner or distance - hitbox > outer or distance <= hitbox:
		return Vector2(0.0, -1.0)
	return Vector2(offset.angle(), asin(hitbox / distance))


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
