class_name EnemyHealthBar
extends Node2D
## A small health bar drawn as two rectangles, centered above its enemy.
## Cheaper than a ProgressBar control when hundreds of enemies are on screen.
## A sibling of the enemy's Visual, so it stays upright and never flashes.

@export var bar_size: Vector2 = Vector2(24.0, 4.0)
@export var background_color: Color = Color(0.1, 0.08, 0.07, 0.85)
@export var fill_color: Color = Color(0.95, 0.91, 0.8, 1.0)

var _fraction: float = 1.0


## 0..1 of the bar filled. Redraws only when it changes.
func set_fraction(fraction: float) -> void:
	fraction = clampf(fraction, 0.0, 1.0)
	if is_equal_approx(fraction, _fraction):
		return
	_fraction = fraction
	queue_redraw()


func get_fraction() -> float:
	return _fraction


func _draw() -> void:
	var top_left := Vector2(-bar_size.x / 2.0, -bar_size.y)
	draw_rect(Rect2(top_left, bar_size), background_color)
	if _fraction > 0.0:
		draw_rect(Rect2(top_left, Vector2(bar_size.x * _fraction, bar_size.y)), fill_color)
