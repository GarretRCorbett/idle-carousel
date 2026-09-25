class_name TicketBooth
extends Node2D
## Fixed booth outside the carousel rim. Horse passes pay Gold here (Step 4).
## Draws a code placeholder until real art exists.

@export_group("Placeholder Visuals")
@export var size: Vector2 = Vector2(40.0, 30.0)
@export var roof_height: float = 8.0
@export var window_size: Vector2 = Vector2(16.0, 10.0)
@export var body_color: Color = Color("fff4dc")
@export var roof_color: Color = Color("405d83")
@export var window_color: Color = Color("ddb96a")

@export_group("Pass Feedback")
## Quick placeholder "pop" when the Horse pays out (the coin animation comes later).
@export var pop_scale: float = 1.3
@export_range(0.01, 1.0, 0.01, "suffix:s") var pop_duration: float = 0.15

var _pop_tween: Tween


func pop() -> void:
	if _pop_tween != null:
		_pop_tween.kill()
	scale = Vector2.ONE * pop_scale
	# Scale is part of the transform, which physics interpolation smooths, so
	# animate it on physics ticks too.
	_pop_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_pop_tween.tween_property(self, "scale", Vector2.ONE, pop_duration)


func _draw() -> void:
	var body := Rect2(-size / 2.0, size)
	draw_rect(body, body_color)
	draw_rect(Rect2(body.position, Vector2(size.x, roof_height)), roof_color)
	draw_rect(Rect2(-window_size / 2.0 + Vector2(0.0, roof_height / 2.0), window_size), window_color)
