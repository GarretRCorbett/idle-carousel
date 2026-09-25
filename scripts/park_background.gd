class_name ParkBackground
extends Node2D
## The play-field backdrop, a small formal park (Garret: "a park, not a
## forest"; memo T/Codex): grass, a stone plaza under the carousel with a paved
## ring path and two short paths leading off, two flower beds with benches,
## a few lamps, and just two trees. Everything but the grass and trees is
## drawn in code; nothing moves or looks like an enemy, and the middle stays
## quiet so Leaves and mounts are easy to see. Lives first under World,
## centered on the carousel.

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

@export_group("Paths")
## The paved ring around the plaza, and its edging.
@export_range(0.0, 200.0, 1.0, "suffix:px") var ring_width: float = 34.0
## Warm brick for the ring and paths, like a theme park's main street.
@export var paving_color: Color = Color("d49c83")
@export var edging_color: Color = Color("fff4dc")
@export var joint_color: Color = Color(0.45, 0.2, 0.15, 0.18)
## Directions of the paths leading off the ring (degrees, 0 = right, 90 = down).
@export var path_angles_deg: PackedFloat32Array = PackedFloat32Array([130.0, -50.0])
@export_range(4.0, 100.0, 1.0, "suffix:px") var path_width: float = 30.0
@export_range(0.0, 1000.0, 1.0, "suffix:px") var path_length: float = 700.0

@export_group("Flower beds and benches")
## Bed centers (from the carousel center); each gets a bench beside it.
## Benches are blue and level, so they never look like a Stick flying in.
@export var flower_beds: PackedVector2Array = PackedVector2Array([Vector2(-270.0, -250.0), Vector2(262.0, 250.0)])
@export var bed_size: Vector2 = Vector2(96.0, 46.0)
@export var bed_edge_color: Color = Color("765642")
@export var bed_soil_color: Color = Color("6f9a79")
@export var bloom_colors: Array[Color] = [Color("fff4dc"), Color("b6a3cd"), Color("dca9bb"), Color("ddb96a")]
@export var bench_color: Color = Color("405d83")
@export var bench_leg_color: Color = Color("243955")

@export_group("Umbrella cart")
## A concession cart under a striped umbrella (a little carousel echo).
## Empty = none.
@export var carts: PackedVector2Array = PackedVector2Array([Vector2(215.0, -250.0)])
@export var cart_color: Color = Color("405d83")
@export var umbrella_colors: Array[Color] = [Color("fff4dc"), Color("70568b")]
@export_range(8.0, 60.0, 1.0, "suffix:px") var umbrella_radius: float = 22.0

@export_group("Lamps")
## Lamp posts just outside the ring (degrees round the plaza).
@export var lamp_angles_deg: PackedFloat32Array = PackedFloat32Array([20.0, 160.0, 200.0, 340.0])
@export var lamp_color: Color = Color("fff4dc")
@export var lamp_rim_color: Color = Color("ddb96a")
@export var lamp_glow_color: Color = Color(1.0, 0.85, 0.55, 0.25)

@export_group("Trees")
@export var tree_textures: Array[Texture2D] = []
## Where trees stand (from the center) and how big; x, y, scale. Keep them out
## near the edges, away from where Leaves fly in and latch.
@export var trees: PackedVector3Array = PackedVector3Array([
	Vector3(-320.0, 250.0, 2.1), Vector3(315.0, -280.0, 2.1),
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
	var ring_outer := clearing_radius + ring_width
	_draw_paths(ring_outer)
	# The ring path, then the plaza on top of its inner half.
	draw_circle(Vector2.ZERO, ring_outer + 3.0, edging_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, ring_outer, paving_color, true, -1.0, true)
	for i in 36:
		var direction := Vector2.from_angle(TAU * i / 36.0)
		draw_line(direction * clearing_radius, direction * ring_outer, joint_color, 1.0, true)
	draw_circle(Vector2.ZERO, clearing_radius + 2.0, edging_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, clearing_radius, clearing_color, true, -1.0, true)
	for i in flower_beds.size():
		_draw_bed(flower_beds[i], i)
	for angle in lamp_angles_deg:
		var direction := Vector2.from_angle(deg_to_rad(angle))
		_draw_lamp(direction * (ring_outer + 16.0), direction)
	for cart in carts:
		_draw_cart(cart)
	for i in trees.size():
		if tree_textures.is_empty():
			break
		var texture := tree_textures[i % tree_textures.size()]
		var spot := trees[i]
		var size := texture.get_size() * spot.z
		draw_texture_rect(texture, Rect2(Vector2(spot.x, spot.y) - size / 2.0, size), false, tree_tint)


func _draw_paths(ring_outer: float) -> void:
	for angle in path_angles_deg:
		var direction := Vector2.from_angle(deg_to_rad(angle))
		var from := direction * (ring_outer - 4.0)
		var to := direction * path_length
		draw_line(from, to, edging_color, path_width + 6.0)
		draw_line(from, to, paving_color, path_width)


## A rounded bed of blooms with a bench on the side nearer the plaza.
func _draw_bed(center: Vector2, index: int) -> void:
	var rect := Rect2(center - bed_size / 2.0, bed_size)
	var edge := StyleBoxFlat.new()
	edge.bg_color = bed_soil_color
	edge.border_color = bed_edge_color
	edge.set_border_width_all(4)
	edge.set_corner_radius_all(int(bed_size.y / 2.0))
	draw_style_box(edge, rect)
	# Blooms on a fixed pattern (never random, so the bed looks the same every run).
	for i in 9:
		var t := Vector2(0.18 + 0.32 * (i % 3), 0.28 + 0.22 * (i / 3))
		var jitter := Vector2(sin(i * 1.7 + index) * 5.0, cos(i * 2.3 + index) * 3.0)
		draw_circle(rect.position + rect.size * t + jitter, 4.0, bloom_colors[(i + index) % bloom_colors.size()], true, -1.0, true)
	# A level bench on the bed's side facing the plaza (above or below it).
	var side := -signf(center.y) if center.y != 0.0 else 1.0
	var bench := Rect2(center.x - 26.0, center.y + side * (bed_size.y / 2.0 + 10.0) - 7.0, 52.0, 14.0)
	draw_rect(bench, bench_color)
	draw_rect(Rect2(bench.position + Vector2(0.0, 5.0), Vector2(bench.size.x, 3.0)), bench_leg_color)


## An old-fashioned double lamp seen from above: a soft glow, a gold bar,
## and two ivory globes with gold rims, side by side along the ring.
func _draw_lamp(spot: Vector2, outward: Vector2) -> void:
	var along := Vector2(-outward.y, outward.x) * 8.0
	draw_circle(spot, 22.0, lamp_glow_color, true, -1.0, true)
	draw_line(spot - along, spot + along, lamp_rim_color, 3.0, true)
	for globe in [spot - along, spot + along]:
		draw_circle(globe, 6.0, lamp_rim_color, true, -1.0, true)
		draw_circle(globe, 4.2, lamp_color, true, -1.0, true)


## A cart peeking out under a striped umbrella, seen from above.
func _draw_cart(spot: Vector2) -> void:
	draw_rect(Rect2(spot + Vector2(-umbrella_radius * 0.9, umbrella_radius * 0.35), Vector2(umbrella_radius * 1.8, umbrella_radius * 0.8)), cart_color)
	var wedges := 8
	for i in wedges:
		var from := TAU * i / wedges
		var to := TAU * (i + 1) / wedges
		var points := PackedVector2Array([spot])
		for k in 5:
			points.append(spot + Vector2.from_angle(lerpf(from, to, k / 4.0)) * umbrella_radius)
		draw_colored_polygon(points, umbrella_colors[i % umbrella_colors.size()])
	draw_circle(spot, 3.0, lamp_rim_color, true, -1.0, true)
