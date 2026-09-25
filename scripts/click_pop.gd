class_name ClickPop
extends Node2D
## A quick ring that grows and fades where the player clicked an enemy, so every
## click feels like a click (even the one that kills). Game spawns one per
## enemy click; it frees itself when done. Clicks are human-speed, so it's cheap.

@export_range(1.0, 64.0, 1.0, "suffix:px") var start_radius: float = 6.0
@export_range(1.0, 128.0, 1.0, "suffix:px") var end_radius: float = 22.0
@export_range(0.5, 8.0, 0.5, "suffix:px") var width: float = 3.0
@export_range(0.05, 1.0, 0.01, "suffix:s") var duration: float = 0.2
@export var color: Color = Color(1.0, 0.97, 0.85, 0.9)

var _age: float = 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_age / duration, 0.0, 1.0)
	var faded := color
	faded.a *= 1.0 - t
	draw_arc(Vector2.ZERO, lerpf(start_radius, end_radius, t), 0.0, TAU, 24, faded, width, true)
