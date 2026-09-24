class_name ClickRouter
extends Node2D
## The one place gameplay clicks are decided. Godot offers every click to the
## UI first; HUD panels STOP clicks, so only clicks on the open play area reach
## _unhandled_input here. Each click takes exactly one path:
##   enemy under the cursor -> enemy_click_requested   (Step 6)
##   anywhere else          -> play_area_click_requested (boost; Gold burst in Step 4)

signal play_area_click_requested


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT or not mouse.pressed:
		return
	if not get_viewport_rect().has_point(mouse.position):
		return
	get_viewport().set_input_as_handled()
	# Screen position -> world position via the canvas transform, so this stays
	# right if the window is resized or the world moves.
	route_world_click(get_canvas_transform().affine_inverse() * mouse.position)


## Split out from input handling so tests can call it directly.
func route_world_click(_world_point: Vector2) -> void:
	# Step 6 checks here for the nearest enemy within its click radius.
	play_area_click_requested.emit()
