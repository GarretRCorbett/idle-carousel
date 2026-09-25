class_name EnemySlowIcon
extends Node2D
## The sleepy "Zzz" over a slowed enemy (GDD: Sloth). Three Z strokes drawn in
## code, small to large, rising to the right. A sibling of the enemy's Visual,
## so it isn't tinted, flashed or spun. EnemyBase shows it while slowed.

@export var color: Color = Color(1.0, 1.0, 1.0, 0.95)
@export var outline_color: Color = Color(0.1, 0.08, 0.07, 0.8)
## Height of the smallest Z, in pixels.
@export_range(2.0, 20.0, 0.5, "suffix:px") var z_size: float = 4.0
@export_range(0.5, 4.0, 0.25, "suffix:px") var line_width: float = 1.25


func _draw() -> void:
	var origin := Vector2.ZERO
	for i in 3:
		var size := z_size * (1.0 + 0.35 * i)
		var points := PackedVector2Array([origin, origin + Vector2(size, 0.0),
				origin + Vector2(0.0, size), origin + Vector2(size, size)])
		draw_polyline(points, outline_color, line_width + 1.5, true)
		draw_polyline(points, color, line_width, true)
		origin += Vector2(size * 0.9, -size * 1.1)
