class_name ClickRouter
extends Node2D
## The one place gameplay clicks are decided. The HUD sees every click first
## (panels and buttons stop them), so only clicks on the play area get here.
## A click goes to the nearest live enemy whose click radius covers it; a click
## on empty space does nothing (GDD). Game decides what an enemy click does.

signal enemy_clicked(enemy: EnemyBase)

## Registered enemies, as a set in registration order. A Dictionary, so adding
## and removing stay constant-time with hundreds alive (an Array's has/erase
## would scan them all for every enemy that joins or leaves).
var _enemies: Dictionary[EnemyBase, bool] = {}


func register_enemy(enemy: EnemyBase) -> void:
	_enemies[enemy] = true


func unregister_enemy(enemy: EnemyBase) -> void:
	_enemies.erase(enemy)


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT or not click.pressed:
		return
	# Screen position → World space (undoes the camera/canvas, not this node).
	var world_point := get_canvas_transform().affine_inverse() * click.position
	if route_click(world_point):
		get_viewport().set_input_as_handled()


## Sends a World-space click to its enemy. Returns true if one was hit.
func route_click(world_point: Vector2) -> bool:
	var enemies: Array[EnemyBase] = []
	enemies.assign(_enemies.keys())
	var target := choose_target(world_point, enemies)
	if target == null:
		return false
	enemy_clicked.emit(target)
	return true


## Nearest clickable enemy whose click radius covers the point, or null.
## Ties keep the earlier-registered enemy. A click inside a boss's body
## (its hitbox) always goes to the boss, even with a Leaf in front of it.
static func choose_target(world_point: Vector2, enemies: Array[EnemyBase]) -> EnemyBase:
	var best: EnemyBase = null
	var best_distance_squared := INF
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_active():
			continue
		if enemy.encounter_role == EnemyBase.EncounterRole.BOSS:
			var core := enemy.get_hitbox_radius()
			if world_point.distance_squared_to(enemy.global_position) <= core * core:
				return enemy
		var distance_squared := world_point.distance_squared_to(enemy.global_position)
		var radius := enemy.get_click_radius()
		if distance_squared <= radius * radius and distance_squared < best_distance_squared:
			best = enemy
			best_distance_squared = distance_squared
	return best
