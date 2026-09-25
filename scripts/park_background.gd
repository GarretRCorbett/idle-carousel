class_name ParkBackground
extends Node2D
## The play-field backdrop, a theme-park plaza (Garret: "more concrete like
## a theme park, less grass"): warm pavement in big slabs, a stone plaza under
## the carousel with a brick ring and four curving brick walkways (laid out
## like a theme-park carousel's: one down toward the Boost button, one to
## each side, one to the top right), shop rooftops framing the corners,
## grass only in curbed planters, flower beds with benches, a few lamps, a
## cart in a bench nook and two trees. Everything but the trees is drawn in
## code; nothing moves or looks like an enemy, and the middle stays quiet so
## Leaves and mounts are easy to see.
## Lives first under World, centered on the carousel.

@export_group("Pavement")
## Warm concrete, like a theme park's walkways; big enough to cover the screen.
@export var pavement_color: Color = Color("e2d6bf")
@export var pavement_half_size: Vector2 = Vector2(1100.0, 700.0)
## Slabs with faint joints; each row is offset by half a slab, like real
## pavement.
@export var slab_size: Vector2 = Vector2(128.0, 80.0)
@export var slab_joint_color: Color = Color(0.45, 0.36, 0.25, 0.07)
## No slab joints this close to the carousel, so the busy middle stays quiet.
@export_range(0.0, 600.0, 1.0, "suffix:px") var quiet_radius: float = 230.0

@export_group("Planters")
## Curbed lawns (rects from the carousel center), the only grass. Keep them
## clear of the walkways and near the screen edges.
@export var planters: Array[Rect2] = [
	Rect2(-460.0, 205.0, 200.0, 175.0), Rect2(-340.0, -300.0, 140.0, 76.0),
]
## Per-planter corner radii (top left, top right, bottom right, bottom left),
## in planter order; missing = planter_corner_radius. A big radius on the
## corner facing a walkway makes the lawn curve along it.
@export var planter_corners: Array[Vector4] = [Vector4(80.0, 40.0, 0.0, 0.0)]
@export var lawn_color: Color = Color("86b98c")
@export var curb_color: Color = Color("fff4dc")
## Same width as the walkway edging, so every curb looks the same scale.
@export_range(0.0, 20.0, 1.0, "suffix:px") var curb_width: float = 3.0
@export_range(0.0, 80.0, 1.0, "suffix:px") var planter_corner_radius: float = 38.0

@export_group("Rooftops")
## Shop roofs seen from above, framing the plaza from the corners like the
## buildings around a theme-park carousel (no castles or real places). Rects
## from the carousel center; each roof's ridge runs left to right and its
## scalloped trim faces the plaza (up). Keep them at the screen edges.
@export var roofs: Array[Rect2] = [Rect2(125.0, 270.0, 280.0, 120.0), Rect2(-680.0, 250.0, 210.0, 140.0)]
@export var roof_colors: Array[Color] = [Color("5f82b0"), Color("c98ea6")]
@export var roof_trim_color: Color = Color("fff4dc")
@export var roof_ridge_color: Color = Color("ddb96a")
@export var roof_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.12)

@export_group("Nooks")
## Small paved recesses (slightly darker slabs) that group a bench and a cart.
@export var nooks: Array[Rect2] = [Rect2(125.0, 176.0, 180.0, 86.0)]
@export var nook_color: Color = Color("d6c8ad")

@export_group("Clearing")
@export var clearing_color: Color = Color("ccc4b5")
@export_range(0.0, 600.0, 1.0, "suffix:px") var clearing_radius: float = 150.0
## Soft outer edge, drawn as a few fading rings.
@export_range(0.0, 200.0, 1.0, "suffix:px") var clearing_feather: float = 40.0

@export_group("Paths")
## The paved ring around the plaza, and its edging.
@export_range(0.0, 200.0, 1.0, "suffix:px") var ring_width: float = 34.0
## Warm brick for the ring and walkways, like a theme park's main street,
## with an ivory border (Garret tried beige and preferred brick).
@export var paving_color: Color = Color("d49c83")
@export var edging_color: Color = Color("fff4dc")
@export_range(0.0, 20.0, 1.0, "suffix:px") var edging_width: float = 3.0
@export var joint_color: Color = Color(0.45, 0.2, 0.15, 0.18)
## Walkways leading off the ring, each a curve through 4 points (a cubic
## Bezier from the carousel center outward; the ring hides the start). Keep
## them clear of the planters.
@export var walkways: Array[PackedVector2Array] = [
	PackedVector2Array([Vector2(0.0, 100.0), Vector2(0.0, 250.0), Vector2(0.0, 330.0), Vector2(0.0, 420.0)]),
	PackedVector2Array([Vector2(-110.0, -30.0), Vector2(-350.0, -75.0), Vector2(-520.0, -45.0), Vector2(-700.0, 50.0)]),
	PackedVector2Array([Vector2(150.0, 0.0), Vector2(300.0, -20.0), Vector2(360.0, 60.0), Vector2(720.0, 40.0)]),
	PackedVector2Array([Vector2(90.0, -120.0), Vector2(170.0, -230.0), Vector2(160.0, -300.0), Vector2(300.0, -440.0)]),
]
@export_range(4.0, 160.0, 1.0, "suffix:px") var path_width: float = 62.0
## Per-walkway widths, in walkway order (missing = path_width). The walkway
## down toward the Boost button is the wide main one.
@export var walkway_widths: PackedFloat32Array = PackedFloat32Array([110.0, 85.0])
## Each walkway flares out where it meets the ring, like a plaza opening up.
@export_range(4.0, 400.0, 1.0, "suffix:px") var flare_width: float = 140.0
## How far along the walkway the flare narrows to path_width (0 = no flare).
@export_range(0.0, 1.0, 0.01) var flare_length: float = 0.45

@export_group("Flower beds and benches")
## Bed centers (from the carousel center); each gets a bench beside it.
## Benches are blue and level, so they never look like a Stick flying in.
@export var flower_beds: PackedVector2Array = PackedVector2Array([Vector2(-270.0, -262.0), Vector2(245.0, 232.0)])
@export var bed_size: Vector2 = Vector2(96.0, 46.0)
@export var bed_edge_color: Color = Color("765642")
@export var bed_soil_color: Color = Color("6f9a79")
## Soft pinks, lavender and ivory only: no yellow or green dots that could
## pass for small enemies (Codex look review).
@export var bloom_colors: Array[Color] = [Color("fff4dc"), Color("b6a3cd"), Color("dca9bb")]
@export var bench_color: Color = Color("405d83")
@export var bench_leg_color: Color = Color("243955")

@export_group("Umbrella cart")
## A concession cart under a striped umbrella (a little carousel echo).
## Empty = none.
## Beside a bench, away from the carousel; soft stripes so it never reads
## as a second little carousel.
@export var carts: PackedVector2Array = PackedVector2Array([Vector2(158.0, 205.0)])
@export var cart_color: Color = Color("405d83")
@export var umbrella_colors: Array[Color] = [Color("fff4dc"), Color("a9bcd6")]
@export_range(8.0, 60.0, 1.0, "suffix:px") var umbrella_radius: float = 22.0

@export_group("Lamps")
## Lamp posts just outside the ring (degrees round the plaza).
## Placed to flank the walkways.
@export var lamp_angles_deg: PackedFloat32Array = PackedFloat32Array([20.0, 50.0, 130.0, 160.0, 235.0, 340.0])
## Kept quiet (navy, small globes, a faint glow) so lamps never read as
## yellow enemies or pickups (Codex look review).
@export var lamp_color: Color = Color("fff4dc")
@export var lamp_rim_color: Color = Color("243955")
@export var lamp_glow_color: Color = Color(1.0, 0.85, 0.55, 0.1)
## A very faint shadow that grounds each lamp.
@export var lamp_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.1)

@export_group("Trees")
@export var tree_textures: Array[Texture2D] = []
## Where trees stand (from the center) and how big; x, y, scale. Keep them out
## near the edges, away from where Leaves fly in and latch.
@export var trees: PackedVector3Array = PackedVector3Array([
	Vector3(-375.0, 290.0, 1.5), Vector3(-318.0, 262.0, 1.1),
])
@export var tree_tint: Color = Color(0.85, 0.95, 0.88)


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	queue_redraw()


func _draw() -> void:
	_draw_pavement()
	var ring_outer := clearing_radius + ring_width
	for nook in nooks:
		_draw_nook(nook)
	for i in planters.size():
		_draw_planter(planters[i], planter_corners[i] if i < planter_corners.size() else Vector4.ONE * planter_corner_radius)
	# Walkway borders, the ring with its border, then the walkway fills on top
	# (so the border opens where each walkway joins), then the stone plaza.
	_draw_paths()
	draw_circle(Vector2.ZERO, ring_outer + edging_width, edging_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, ring_outer, paving_color, true, -1.0, true)
	_draw_path_fills()
	for i in 36:
		var direction := Vector2.from_angle(TAU * i / 36.0)
		draw_line(direction * clearing_radius, direction * ring_outer, joint_color, 1.0, true)
	draw_circle(Vector2.ZERO, clearing_radius + 3.0, curb_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, clearing_radius, clearing_color, true, -1.0, true)
	for i in flower_beds.size():
		_draw_bed(flower_beds[i], i)
	for angle in lamp_angles_deg:
		_draw_lamp(Vector2.from_angle(deg_to_rad(angle)) * (ring_outer + 16.0))
	for cart in carts:
		_draw_cart(cart)
	for i in roofs.size():
		_draw_roof(roofs[i], roof_colors[i % roof_colors.size()])
	for i in trees.size():
		if tree_textures.is_empty():
			break
		var texture := tree_textures[i % tree_textures.size()]
		var spot := trees[i]
		var size := texture.get_size() * spot.z
		draw_texture_rect(texture, Rect2(Vector2(spot.x, spot.y) - size / 2.0, size), false, tree_tint)


func _draw_pavement() -> void:
	var half := pavement_half_size
	draw_rect(Rect2(-half, half * 2.0), pavement_color)
	var row := 0
	var y := -ceilf(half.y / slab_size.y) * slab_size.y
	while y <= half.y:
		draw_line(Vector2(-half.x, y), Vector2(half.x, y), slab_joint_color, 1.0)
		var x := -ceilf(half.x / slab_size.x) * slab_size.x + (slab_size.x / 2.0 if row % 2 == 1 else 0.0)
		while x <= half.x:
			draw_line(Vector2(x, y), Vector2(x, y + slab_size.y), slab_joint_color, 1.0)
			x += slab_size.x
		y += slab_size.y
		row += 1
	draw_circle(Vector2.ZERO, quiet_radius, pavement_color, true, -1.0, true)


## A lawn with an ivory curb and rounded corners (tl, tr, br, bl).
func _draw_planter(rect: Rect2, corners: Vector4) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = lawn_color
	box.border_color = curb_color
	box.set_border_width_all(int(curb_width))
	box.corner_radius_top_left = int(corners.x)
	box.corner_radius_top_right = int(corners.y)
	box.corner_radius_bottom_right = int(corners.z)
	box.corner_radius_bottom_left = int(corners.w)
	box.corner_detail = 16
	box.anti_aliasing = true
	draw_style_box(box, rect)


func _draw_nook(rect: Rect2) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = nook_color
	box.set_corner_radius_all(16)
	box.anti_aliasing = true
	draw_style_box(box, rect)


## A shop roof from above: a soft shadow, a lighter front slope and a darker
## back slope with faint shingle rows, a gold ridge, and a scalloped ivory
## trim along the front (plaza) edge.
func _draw_roof(rect: Rect2, color: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(5.0, 6.0), rect.size), roof_shadow_color)
	var ridge_y := rect.position.y + rect.size.y * 0.45
	var front := Rect2(rect.position, Vector2(rect.size.x, ridge_y - rect.position.y))
	var back := Rect2(Vector2(rect.position.x, ridge_y), Vector2(rect.size.x, rect.end.y - ridge_y))
	draw_rect(front, color.lightened(0.12))
	draw_rect(back, color.darkened(0.08))
	var shingle := Color(color.darkened(0.35), 0.35)
	var y := rect.position.y + 12.0
	while y < rect.end.y:
		if absf(y - ridge_y) > 4.0:
			draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), shingle, 1.0)
		y += 12.0
	draw_line(Vector2(rect.position.x, ridge_y), Vector2(rect.end.x, ridge_y), roof_ridge_color, 3.0)
	var scallop := 8.0
	var x := rect.position.x + scallop
	while x < rect.end.x:
		draw_circle(Vector2(x, rect.position.y), scallop, roof_trim_color, true, -1.0, true)
		x += scallop * 2.0
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4.0)), roof_trim_color)


func _draw_paths() -> void:
	for i in walkways.size():
		if walkways[i].size() == 4:
			draw_colored_polygon(_walkway_outline(walkways[i], edging_width * 2.0, _walkway_width(i)), edging_color)


## The walkway fills, drawn over the ring's border so each walkway opens
## into the ring instead of stopping at it.
func _draw_path_fills() -> void:
	for i in walkways.size():
		if walkways[i].size() == 4:
			draw_colored_polygon(_walkway_outline(walkways[i], 0.0, _walkway_width(i)), paving_color)


func _walkway_width(index: int) -> float:
	return walkway_widths[index] if index < walkway_widths.size() else path_width


## The walkway's outline: both edges of the curve at its width there (wide at
## the ring, narrowing to path_width), plus extra for the edging.
func _walkway_outline(walkway: PackedVector2Array, extra: float, width: float) -> PackedVector2Array:
	var steps := 48
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		var tangent := (_bezier(walkway, minf(t + 0.01, 1.0)) - _bezier(walkway, maxf(t - 0.01, 0.0))).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		var flare := smoothstep(0.0, flare_length, t) if flare_length > 0.0 else 1.0
		var half := (lerpf(flare_width + width - path_width, width, flare) + extra) / 2.0
		var point := _bezier(walkway, t)
		left.append(point + normal * half)
		right.append(point - normal * half)
	right.reverse()
	return left + right


static func _bezier(p: PackedVector2Array, t: float) -> Vector2:
	var u := 1.0 - t
	return p[0] * u * u * u + p[1] * 3.0 * u * u * t + p[2] * 3.0 * u * t * t + p[3] * t * t * t


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


## A lamp seen from above: a faint glow and one ivory globe in a navy rim.
func _draw_lamp(spot: Vector2) -> void:
	draw_circle(spot + Vector2(2.0, 3.0), 6.0, lamp_shadow_color, true, -1.0, true)
	draw_circle(spot, 13.0, lamp_glow_color, true, -1.0, true)
	draw_circle(spot, 6.0, lamp_rim_color, true, -1.0, true)
	draw_circle(spot, 4.0, lamp_color, true, -1.0, true)


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
