class_name LevelPips
extends Control
## A row of small segments showing levels bought out of the max (e.g. 3 of 10).

## Light royal blue, the Send wave blue brightened to read on the navy panel.
@export var filled_color: Color = Color("7aa2ff")
@export var empty_color: Color = Color(1.0, 1.0, 1.0, 0.18)
@export var pip_size: Vector2 = Vector2(12.0, 6.0)
@export var gap: float = 3.0

var level: int = 0:
	set(value):
		level = value
		queue_redraw()
var max_level: int = 1:
	set(value):
		max_level = maxi(1, value)
		custom_minimum_size = Vector2(max_level * (pip_size.x + gap) - gap, pip_size.y)
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	for i in max_level:
		var rect := Rect2(Vector2(i * (pip_size.x + gap), 0.0), pip_size)
		draw_rect(rect, filled_color if i < level else empty_color)
