class_name ParkBackground
extends Node2D
## The play-field backdrop: tiled grass, a dirt clearing under the carousel (so
## the green disc doesn't blend into green grass), and a few trees out near the
## edges. Kept dark and low-contrast so Leaves and mounts stay easy to see.
## Lives first under World, centered on the carousel.

@export var grass_texture: Texture2D
## Darkens and warms the grass (1 = original colors).
@export var grass_tint: Color = Color(0.72, 0.86, 0.74)
## How far the grass extends from the center; big enough to cover the screen.
@export var grass_half_size: Vector2 = Vector2(1100.0, 700.0)
## Scale of each grass tile.
@export_range(0.25, 8.0, 0.25) var grass_tile_scale: float = 1.5

@export_group("Clearing")
@export var clearing_color: Color = Color("ccc4b5")
@export_range(0.0, 600.0, 1.0, "suffix:px") var clearing_radius: float = 150.0
## Soft outer edge, drawn as a few fading rings.
@export_range(0.0, 200.0, 1.0, "suffix:px") var clearing_feather: float = 40.0

@export_group("Trees")
@export var tree_textures: Array[Texture2D] = []
## Where trees stand (from the center) and how big; x, y, scale. Keep them out
## near the edges, away from where Leaves fly in and latch.
@export var trees: PackedVector3Array = PackedVector3Array([
	Vector3(-300.0, -290.0, 2.2), Vector3(-330.0, 250.0, 2.0), Vector3(-250.0, 330.0, 1.2),
	Vector3(290.0, -300.0, 2.0), Vector3(310.0, 270.0, 2.3), Vector3(240.0, -330.0, 1.2),
])
@export var tree_tint: Color = Color(0.85, 0.95, 0.88)


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	queue_redraw()


func _draw() -> void:
	if grass_texture != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * grass_tile_scale)
		var half := grass_half_size / grass_tile_scale
		draw_texture_rect(grass_texture, Rect2(-half, half * 2.0), true, grass_tint)
		draw_set_transform(Vector2.ZERO)
	var rings := 6
	for i in rings:
		var t := float(i) / rings
		var faded := clearing_color
		faded.a = clearing_color.a * (t + 1.0 / rings)
		draw_circle(Vector2.ZERO, clearing_radius + clearing_feather * (1.0 - t), faded)
	draw_circle(Vector2.ZERO, clearing_radius, clearing_color)
	for i in trees.size():
		if tree_textures.is_empty():
			break
		var texture := tree_textures[i % tree_textures.size()]
		var spot := trees[i]
		var size := texture.get_size() * spot.z
		draw_texture_rect(texture, Rect2(Vector2(spot.x, spot.y) - size / 2.0, size), false, tree_tint)
