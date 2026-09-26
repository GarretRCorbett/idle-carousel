class_name ClickRouter
extends Node2D
## The one place gameplay clicks are decided. The HUD sees every click first
## (panels and buttons stop them), so only clicks on the play area get here.
## A click goes to the nearest live enemy whose click radius covers it; a click
## on empty space does nothing (GDD). Game decides what an enemy click does.
## Controllers strike instead (Phase 4, Garret): the strike action hits the
## enemy nearest the carousel, the same as clicking it, and while a controller
## is in use that enemy wears a ring with the strike button's prompt.

signal enemy_clicked(enemy: EnemyBase)

## Input Map action for a controller strike (the left trigger by default).
@export var strike_action: StringName = &"strike"
@export var strike_ring_color: Color = Color(1.0, 0.95, 0.6, 0.9)
@export_range(1.0, 6.0, 0.5, "suffix:px") var strike_ring_width: float = 2.5

## The carousel (Game sets it): strikes pick the enemy nearest its center.
var carousel: Node2D
## The enemy a strike would hit now (only tracked while a controller is in use).
var _strike_target: EnemyBase

## Registered enemies, as a set in registration order. A Dictionary, so adding
## and removing stay constant-time with hundreds alive (an Array's has/erase
## would scan them all for every enemy that joins or leaves).
var _enemies: Dictionary[EnemyBase, bool] = {}


func register_enemy(enemy: EnemyBase) -> void:
	_enemies[enemy] = true


func unregister_enemy(enemy: EnemyBase) -> void:
	_enemies.erase(enemy)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(strike_action):
		if strike():
			get_viewport().set_input_as_handled()
		return
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
	var target := choose_target(world_point, enemies, GameState.get_click_range_multiplier())
	if target == null:
		return false
	enemy_clicked.emit(target)
	return true


## Nearest clickable enemy whose click radius covers the point, or null.
## Ties keep the earlier-registered enemy. A click inside a boss's body
## (its hitbox) always goes to the boss, even with a Leaf in front of it.
## `range_multiplier` scales every click radius (Click Range).
static func choose_target(world_point: Vector2, enemies: Array[EnemyBase], range_multiplier: float = 1.0) -> EnemyBase:
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
		var radius := enemy.get_click_radius() * range_multiplier
		if distance_squared <= radius * radius and distance_squared < best_distance_squared:
			best = enemy
			best_distance_squared = distance_squared
	return best


## A controller strike: hits the live enemy nearest the carousel (the one
## about to latch, or latched). Returns true if there was one.
func strike() -> bool:
	if carousel == null:
		return false
	var enemies: Array[EnemyBase] = []
	enemies.assign(_enemies.keys())
	var target := choose_nearest(carousel.global_position, enemies)
	if target == null:
		return false
	enemy_clicked.emit(target)
	return true


## The live enemy nearest `point` (World space), or null. Ties keep the
## earlier-registered enemy.
static func choose_nearest(point: Vector2, enemies: Array[EnemyBase]) -> EnemyBase:
	var best: EnemyBase = null
	var best_distance_squared := INF
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_active():
			continue
		var distance_squared := point.distance_squared_to(enemy.global_position)
		if distance_squared < best_distance_squared:
			best = enemy
			best_distance_squared = distance_squared
	return best


## While a controller is in use, keep the strike target marked.
func _process(_delta: float) -> void:
	var target: EnemyBase = null
	if ControllerInput.using_controller and carousel != null and not _enemies.is_empty():
		var enemies: Array[EnemyBase] = []
		enemies.assign(_enemies.keys())
		target = choose_nearest(carousel.global_position, enemies)
	if target != _strike_target or target != null:
		_strike_target = target
		queue_redraw()


func _draw() -> void:
	if _strike_target == null or not is_instance_valid(_strike_target):
		return
	var at := to_local(_strike_target.global_position)
	var radius := _strike_target.get_click_radius() * 1.15
	draw_arc(at, radius, 0.0, TAU, 32, strike_ring_color, strike_ring_width, true)
	ControllerPrompt.draw_action(self, at + Vector2(radius, -radius) * 0.75, strike_action, 8.0)
