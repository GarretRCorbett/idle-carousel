class_name Carousel
extends Node2D
## The spinning platform. Only mounts and slots are children; enemies live in
## World/EnemyLayer. Draws a code placeholder until real art exists.

@export_group("Placeholder Visuals")
@export_range(10.0, 400.0, 1.0, "suffix:px") var radius: float = 100.0
@export_range(1.0, 50.0, 1.0, "suffix:px") var rim_width: float = 8.0
@export_range(1.0, 100.0, 1.0, "suffix:px") var hub_radius: float = 16.0
## Spokes make the rotation visible on a plain circle.
@export_range(0, 24, 1) var spoke_count: int = 6
@export_range(0.5, 10.0, 0.5, "suffix:px") var spoke_width: float = 2.0
@export var base_color: Color = Color("4a7a3d")
@export var rim_color: Color = Color("2d5a25")
@export var hub_color: Color = Color("2d5a25")


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, base_color)
	for i in spoke_count:
		var direction := Vector2.from_angle(TAU * i / spoke_count)
		draw_line(direction * hub_radius, direction * (radius - rim_width), rim_color, spoke_width)
	draw_arc(Vector2.ZERO, radius - rim_width / 2.0, 0.0, TAU, 64, rim_color, rim_width)
	draw_circle(Vector2.ZERO, hub_radius, hub_color)
