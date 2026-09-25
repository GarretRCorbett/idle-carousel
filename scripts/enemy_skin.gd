class_name EnemySkin
extends Resource
## How one enemy looks in a theme: a sprite, or a shape drawn in code. Only
## looks live here. Stats, hitbox and click radius stay in EnemyData, so a
## reskin can never change how a fight plays. ThemeManager.skin_for() builds
## the default skin from EnemyData when the current theme has none (there,
## not here: a static builder naming EnemyData leaked both scripts at exit).

enum Shape {
	POLYGON,  ## A regular polygon with `points` corners (the old placeholder).
	ROUND,    ## A ball with a highlight (a snowball).
	STAR,     ## A star with `points` arms (a snowflake).
	SHARD,    ## A long, thin diamond (an icicle, a bone).
	PUMPKIN,  ## A ribbed pumpkin with a stem.
}

## Which enemy this skin dresses: EnemyData.id.
@export var enemy_id: StringName = &""
## Light grey or white art tints best with the tier colors. Empty = draw `shape`.
@export var texture: Texture2D = null
## A white silhouette a little bigger than `texture`, for the Charcoal tier.
@export var outline_texture: Texture2D = null
## How big it looks: half the sprite's longest side, or the shape's radius.
## Only looks: the hitbox and click radius come from EnemyData.
@export_range(1.0, 128.0, 1.0, "suffix:px") var visual_size: float = 12.0
@export var shape: Shape = Shape.POLYGON
@export var color: Color = Color.WHITE
## Corners (POLYGON) or arms (STAR).
@export_range(3, 32, 1) var points: int = 6


## Draws the shape on `canvas` at its origin, `size` px in radius.
func draw_shape(canvas: CanvasItem, size: float) -> void:
	match shape:
		Shape.ROUND:
			canvas.draw_circle(Vector2.ZERO, size, color, true, -1.0, true)
			canvas.draw_circle(Vector2(size * 0.15, size * 0.2), size * 0.8, color.darkened(0.12), true, -1.0, true)
			canvas.draw_circle(Vector2(-size * 0.1, -size * 0.1), size * 0.75, color, true, -1.0, true)
			canvas.draw_circle(Vector2(-size * 0.35, -size * 0.35), size * 0.22, color.lightened(0.5), true, -1.0, true)
		Shape.STAR:
			var star := PackedVector2Array()
			for i in points * 2:
				var radius := size if i % 2 == 0 else size * 0.42
				star.append(Vector2.from_angle(TAU * i / (points * 2)) * radius)
			canvas.draw_colored_polygon(star, color)
			canvas.draw_circle(Vector2.ZERO, size * 0.25, color.darkened(0.15), true, -1.0, true)
		Shape.SHARD:
			canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(size, 0.0), Vector2(0.0, size * 0.3), Vector2(-size, 0.0), Vector2(0.0, -size * 0.3),
			]), color)
			canvas.draw_line(Vector2(-size * 0.8, 0.0), Vector2(size * 0.8, 0.0), color.lightened(0.4), maxf(1.0, size * 0.08), true)
		Shape.PUMPKIN:
			for x in [-0.45, 0.45, 0.0]:
				canvas.draw_set_transform(Vector2(size * x, size * 0.08), 0.0, Vector2(0.62, 0.85))
				canvas.draw_circle(Vector2.ZERO, size, color if x == 0.0 else color.darkened(0.15), true, -1.0, true)
			canvas.draw_set_transform(Vector2.ZERO)
			canvas.draw_rect(Rect2(-size * 0.1, -size * 0.95, size * 0.2, size * 0.3), Color("4f7a3a"))
		_:
			var polygon := PackedVector2Array()
			for i in points:
				polygon.append(Vector2.from_angle(TAU * i / points) * size)
			canvas.draw_colored_polygon(polygon, color)
