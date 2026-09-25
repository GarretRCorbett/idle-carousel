class_name ParkScenery
extends Control
## The title screen's park, drawn over the sky backdrop, matching the play
## field's look: a concrete plaza with a planter strip of blooms, a brick
## promenade with ivory edging, a row of shopfronts on each side (cream
## fronts, blue and pink roofs with scalloped ivory trim and a gold ridge,
## striped awnings; the middle stays clear for the title and carousel), an
## iron fence, bushes, gold double lamps with bunting, an umbrella cart and
## balloons. Kenney sprites for the fence and bushes; everything else is drawn
## in code. Positions are fractions of the screen, so it fits any window size.

@export_group("Ground")
## Where the ground starts (fraction of the height from the top).
@export_range(0.3, 1.0, 0.01) var horizon: float = 0.7
## Warm concrete, like a theme park's walkways (Garret: "more concrete").
@export var pavement_color: Color = Color("e2d6bf")
@export var slab_joint_color: Color = Color(0.45, 0.36, 0.25, 0.16)
## The only grass: a planter strip along the fence, with an ivory curb.
@export var lawn_color: Color = Color("86b98c")
@export var curb_color: Color = Color("fff4dc")
@export_range(0.0, 0.2, 0.005) var planter_height: float = 0.035
## Warm brick with an ivory edge, like the play field's walkways.
@export var promenade_color: Color = Color("d49c83")
@export var promenade_edge_color: Color = Color("fff4dc")
## Blooms along the planter strip (soft colors, like the play field's beds).
@export var bloom_colors: Array[Color] = [Color("fff4dc"), Color("b6a3cd"), Color("dca9bb")]
@export var brick_line_color: Color = Color(0.45, 0.2, 0.15, 0.22)
@export_range(0.0, 0.3, 0.01) var promenade_top: float = 0.84
@export_range(0.0, 0.3, 0.01) var promenade_height: float = 0.07

@export_group("Shopfronts")
## Shopfronts fill from each edge toward the middle, up to this fraction of
## the width on each side. Widths and heights (fractions of the screen) cycle.
@export_range(0.1, 0.5, 0.01) var house_side_width: float = 0.24
@export var shop_widths: PackedFloat32Array = PackedFloat32Array([0.1, 0.085, 0.11, 0.09])
@export var shop_heights: PackedFloat32Array = PackedFloat32Array([0.17, 0.14, 0.19, 0.15])
@export var facade_colors: Array[Color] = [Color("fff4dc"), Color("f0e2c8"), Color("f6ead6")]
## The same blues and pink as the play field's rooftops.
@export var roof_colors: Array[Color] = [Color("4f79a8"), Color("c98ea6"), Color("5f82b0")]
@export var window_color: Color = Color("405d83")
@export var trim_color: Color = Color("fff4dc")
@export var ridge_color: Color = Color("ddb96a")
@export_range(3, 16, 1) var awning_stripes: int = 7

@export_group("Fence and bushes")
@export var fence: Texture2D
## The Kenney iron fence is bright green; this tints it toward the ink blue.
@export var fence_tint: Color = Color(0.55, 0.62, 0.85)
@export_range(0.02, 0.3, 0.01) var fence_height: float = 0.07
@export var bushes: Array[Texture2D] = []
## Where bushes sit along the fence (fractions of the width).
@export var bush_spots: PackedFloat32Array = PackedFloat32Array([0.06, 0.24, 0.38, 0.62, 0.77, 0.95])
@export_range(0.02, 0.3, 0.01) var bush_height: float = 0.06

@export_group("Lamps and bunting")
## Lamp posts along the promenade (fractions of the width).
@export var lamp_spots: PackedFloat32Array = PackedFloat32Array([0.12, 0.34, 0.66, 0.88])
## Navy posts with the play field's gold double lamp heads.
@export var lamp_color: Color = Color("243955")
@export var lamp_gold_color: Color = Color("ddb96a")
@export var lamp_glow_color: Color = Color(1.0, 0.85, 0.55, 0.4)
@export var lamp_bulb_color: Color = Color("fff4dc")
@export_range(0.05, 0.6, 0.01) var lamp_height: float = 0.26
## Bunting flags cycle through these (palette A).
@export var bunting_colors: Array[Color] = [Color("fff4dc"), Color("70568b"), Color("ddb96a"), Color("405d83")]
@export_range(0.0, 0.2, 0.005) var bunting_sag: float = 0.04
@export_range(4.0, 40.0, 1.0, "suffix:px") var flag_size: float = 12.0

@export_group("Umbrella cart")
## Where the cart stands (fraction of the width), on the pavement in front.
@export_range(0.0, 1.0, 0.01) var cart_spot: float = 0.22
@export var cart_color: Color = Color("405d83")
@export var umbrella_colors: Array[Color] = [Color("fff4dc"), Color("a9bcd6")]

@export_group("Balloons")
## Where the balloon bunch is tied (fraction of the width), on the promenade.
@export_range(0.0, 1.0, 0.01) var balloon_spot: float = 0.95
@export var balloon_colors: Array[Color] = [Color("d9534f"), Color("70568b"), Color("ddb96a"), Color("405d83"), Color("fff4dc")]
@export_range(4.0, 40.0, 1.0, "suffix:px") var balloon_radius: float = 13.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var ground_y := h * horizon
	_draw_houses(w, h, ground_y)
	# Pavement, the planter strip along the fence, then the promenade.
	_draw_pavement(w, h, ground_y)
	_draw_promenade(w, h)
	_draw_fence(w, h, ground_y)
	_draw_bushes(w, h, ground_y)
	_draw_lamps_and_bunting(w, h)
	_draw_cart(w, h)
	_draw_balloons(w, h)


func _draw_houses(w: float, h: float, ground_y: float) -> void:
	if shop_widths.is_empty() or shop_heights.is_empty():
		return
	for side in [-1, 1]:
		var edge := 0.0 if side == -1 else w
		var x := edge
		var i := 0 if side == -1 else 1
		while absf(x - edge) < w * house_side_width:
			var size := Vector2(w * shop_widths[i % shop_widths.size()], h * shop_heights[i % shop_heights.size()])
			var left := x if side == -1 else x - size.x
			_draw_shopfront(Rect2(Vector2(left, ground_y - size.y + 2.0), size), i)
			# Each row fills from its screen edge toward the middle.
			x -= (size.x + 2.0) * side
			i += 1


## A Main Street-style shopfront: cream front, a mansard roof with shingle
## rows, a gold ridge and scalloped ivory trim, two upper windows, a striped
## awning over a shop window and a door.
func _draw_shopfront(body: Rect2, index: int) -> void:
	var roof_color: Color = roof_colors[index % roof_colors.size()]
	draw_rect(body, facade_colors[index % facade_colors.size()])
	# Mansard roof on top, a little wider than the front.
	var roof_h := body.size.y * 0.3
	var eave := body.position.y
	var roof := PackedVector2Array([
		Vector2(body.position.x - 5.0, eave), Vector2(body.end.x + 5.0, eave),
		Vector2(body.end.x - body.size.x * 0.12, eave - roof_h), Vector2(body.position.x + body.size.x * 0.12, eave - roof_h),
	])
	draw_colored_polygon(roof, roof_color)
	var shingle := Color(roof_color.darkened(0.35), 0.35)
	for k in range(1, 4):
		var y := eave - roof_h * k / 4.0
		var inset := body.size.x * 0.12 * k / 4.0
		draw_line(Vector2(body.position.x - 5.0 + inset, y), Vector2(body.end.x + 5.0 - inset, y), shingle, 1.0)
	draw_line(roof[3], roof[2], ridge_color, 3.0)
	var scallop := 5.0
	var sx := body.position.x - 5.0 + scallop
	while sx < body.end.x + 5.0:
		draw_circle(Vector2(sx, eave), scallop, trim_color, true, -1.0, true)
		sx += scallop * 2.0
	# Two upper windows with ivory frames.
	var win := Vector2(body.size.x * 0.2, body.size.y * 0.2)
	for fx in [0.22, 0.58]:
		var r := Rect2(body.position + Vector2(body.size.x * fx, body.size.y * 0.14), win)
		draw_rect(r.grow(2.0), trim_color)
		draw_rect(r, window_color)
	# Striped awning over the ground floor, then a shop window and a door.
	var awning := Rect2(body.position + Vector2(body.size.x * 0.08, body.size.y * 0.48), Vector2(body.size.x * 0.84, body.size.y * 0.1))
	var stripe := awning.size.x / awning_stripes
	for k in awning_stripes:
		var color := roof_color if k % 2 == 0 else trim_color
		draw_rect(Rect2(awning.position + Vector2(stripe * k, 0.0), Vector2(stripe, awning.size.y)), color)
		draw_circle(awning.position + Vector2(stripe * (k + 0.5), awning.size.y), stripe / 2.0, color, true, -1.0, true)
	var shop_window := Rect2(body.position + Vector2(body.size.x * 0.14, body.size.y * 0.66), Vector2(body.size.x * 0.44, body.size.y * 0.24))
	draw_rect(shop_window.grow(2.0), trim_color)
	draw_rect(shop_window, window_color)
	var door := Rect2(body.position + Vector2(body.size.x * 0.66, body.size.y * 0.64), Vector2(body.size.x * 0.18, body.size.y * 0.36))
	draw_rect(door.grow(2.0), trim_color)
	draw_rect(door, roof_color.darkened(0.25))


func _draw_fence(w: float, h: float, ground_y: float) -> void:
	if fence == null:
		return
	var scale := h * fence_height / fence.get_height()
	var drawn := fence.get_size() * scale
	var x := 0.0
	while x < w:
		draw_texture_rect(fence, Rect2(Vector2(x, ground_y - drawn.y * 0.55), drawn), false, fence_tint)
		x += drawn.x * 0.98


func _draw_bushes(w: float, h: float, ground_y: float) -> void:
	if bushes.is_empty():
		return
	for i in bush_spots.size():
		var texture: Texture2D = bushes[i % bushes.size()]
		var scale := h * bush_height / texture.get_height()
		var drawn := texture.get_size() * scale
		draw_texture_rect(texture, Rect2(Vector2(w * bush_spots[i] - drawn.x / 2.0, ground_y - drawn.y * 0.3), drawn), false)


func _draw_lamps_and_bunting(w: float, h: float) -> void:
	var base_y := h * (promenade_top + promenade_height * 0.3)
	var top_y := base_y - h * lamp_height
	var tops := PackedVector2Array()
	for spot in lamp_spots:
		var x := w * spot
		draw_line(Vector2(x, base_y), Vector2(x, top_y), lamp_color, 4.0, true)
		draw_rect(Rect2(x - 7.0, base_y - 4.0, 14.0, 6.0), lamp_color)
		# A gold crossbar with a globe at each end, like the play field's lamps.
		draw_circle(Vector2(x, top_y - 6.0), 26.0, lamp_glow_color, true, -1.0, true)
		draw_line(Vector2(x - 13.0, top_y + 2.0), Vector2(x + 13.0, top_y + 2.0), lamp_gold_color, 3.0, true)
		for gx in [x - 13.0, x + 13.0]:
			draw_circle(Vector2(gx, top_y - 6.0), 8.0, lamp_gold_color, true, -1.0, true)
			draw_circle(Vector2(gx, top_y - 6.0), 6.0, lamp_bulb_color, true, -1.0, true)
		draw_circle(Vector2(x, top_y - 2.0), 3.0, lamp_gold_color, true, -1.0, true)
		tops.append(Vector2(x, top_y + 4.0))
	# Bunting only between the two lamps on each side, so the middle stays clear.
	for pair in [[0, 1], [tops.size() - 2, tops.size() - 1]]:
		if pair[0] < 0 or pair[1] >= tops.size() or pair[0] >= pair[1]:
			continue
		_draw_bunting(tops[pair[0]], tops[pair[1]], h)


func _draw_bunting(from: Vector2, to: Vector2, h: float) -> void:
	var sag := h * bunting_sag
	var steps := maxi(2, int(from.distance_to(to) / (flag_size * 1.6)))
	var points := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		points.append(from.lerp(to, t) + Vector2(0.0, sag * 4.0 * t * (1.0 - t)))
	draw_polyline(points, Color(lamp_color, 0.8), 1.5, true)
	for i in steps:
		var a := points[i]
		var b := points[i + 1]
		var mid := (a + b) / 2.0 + Vector2(0.0, flag_size)
		draw_colored_polygon(PackedVector2Array([a, b, mid]), bunting_colors[i % bunting_colors.size()])


## Concrete slabs seen at a low angle: rows get taller toward the viewer,
## joints run to a vanishing point above the middle. The planter strip sits
## on top, right under the fence.
func _draw_pavement(w: float, h: float, ground_y: float) -> void:
	draw_rect(Rect2(0.0, ground_y, w, h - ground_y), pavement_color)
	var strip_bottom := ground_y + h * planter_height
	var y := strip_bottom
	var row := h * 0.03
	while y < h:
		draw_line(Vector2(0.0, y), Vector2(w, y), slab_joint_color, 1.0)
		y += row
		row *= 1.35
	var vanish := Vector2(w / 2.0, ground_y - h * 0.5)
	for i in range(-12, 13):
		var foot := Vector2(w / 2.0 + i * w * 0.09, h)
		var t := (strip_bottom - vanish.y) / (foot.y - vanish.y)
		draw_line(vanish.lerp(foot, t), foot, slab_joint_color, 1.0, true)
	draw_rect(Rect2(0.0, ground_y, w, h * planter_height), lawn_color)
	if not bloom_colors.is_empty():
		var bx := 9.0
		var k := 0
		while bx < w:
			var by := ground_y + h * planter_height * (0.55 + 0.25 * sin(k * 1.9))
			draw_circle(Vector2(bx, by), 3.0, bloom_colors[k % bloom_colors.size()], true, -1.0, true)
			bx += 17.0 + 6.0 * sin(k * 2.7)
			k += 1
	draw_line(Vector2(0.0, strip_bottom), Vector2(w, strip_bottom), curb_color, 3.0)


## Warm brick: the band plus faint mortar lines, staggered row to row.
func _draw_promenade(w: float, h: float) -> void:
	var top := h * promenade_top
	var height := h * promenade_height
	draw_rect(Rect2(0.0, top - 3.0, w, height + 6.0), promenade_edge_color)
	draw_rect(Rect2(0.0, top, w, height), promenade_color)
	var rows := 3
	var brick := height / rows * 2.2
	for row in rows:
		var y := top + height * row / rows
		if row > 0:
			draw_line(Vector2(0.0, y), Vector2(w, y), brick_line_color, 1.0)
		var x := brick * 0.5 * (row % 2)
		while x < w:
			draw_line(Vector2(x, y), Vector2(x, y + height / rows), brick_line_color, 1.0)
			x += brick


## A bunch of balloons tied to one spot on the promenade.
func _draw_balloons(w: float, h: float) -> void:
	if balloon_colors.is_empty():
		return
	var knot := Vector2(w * balloon_spot, h * (promenade_top + promenade_height * 0.2))
	var offsets := [Vector2(-18.0, -118.0), Vector2(6.0, -132.0), Vector2(26.0, -112.0), Vector2(-4.0, -100.0), Vector2(16.0, -92.0)]
	for i in offsets.size():
		var center: Vector2 = knot + offsets[i]
		draw_line(knot, center + Vector2(0.0, balloon_radius * 1.15), Color(0.2, 0.2, 0.25, 0.6), 1.0, true)
	for i in offsets.size():
		var center: Vector2 = knot + offsets[i]
		draw_set_transform(center, 0.0, Vector2(1.0, 1.2))
		draw_circle(Vector2.ZERO, balloon_radius, balloon_colors[i % balloon_colors.size()], true, -1.0, true)
		draw_circle(Vector2(-balloon_radius * 0.35, -balloon_radius * 0.35), balloon_radius * 0.25, Color(1.0, 1.0, 1.0, 0.45), true, -1.0, true)
		draw_set_transform(Vector2.ZERO)


## A concession cart under a striped umbrella, seen from the side.
func _draw_cart(w: float, h: float) -> void:
	var base := Vector2(w * cart_spot, h * (promenade_top - 0.015))
	var body := Rect2(base + Vector2(-26.0, -26.0), Vector2(52.0, 22.0))
	draw_rect(body, cart_color)
	draw_rect(Rect2(body.position + Vector2(0.0, -3.0), Vector2(body.size.x, 4.0)), trim_color)
	for wx in [-16.0, 16.0]:
		draw_circle(base + Vector2(wx, -3.0), 5.0, lamp_color, true, -1.0, true)
		draw_circle(base + Vector2(wx, -3.0), 2.0, lamp_gold_color, true, -1.0, true)
	var pole_top := base + Vector2(0.0, -58.0)
	draw_line(base + Vector2(0.0, -26.0), pole_top, lamp_color, 2.0, true)
	# Dome umbrella: striped wedges of a half circle, scalloped rim.
	var radius := 38.0
	var wedges := 6
	for i in wedges:
		var points := PackedVector2Array([pole_top])
		for k in 5:
			points.append(pole_top + Vector2.from_angle(PI + PI * (i + k / 4.0) / wedges) * Vector2(radius, radius * 0.8))
		draw_colored_polygon(points, umbrella_colors[i % umbrella_colors.size()])
	for i in wedges:
		var cx := pole_top.x - radius + radius * 2.0 * (i + 0.5) / wedges
		draw_circle(Vector2(cx, pole_top.y), radius / wedges, umbrella_colors[i % umbrella_colors.size()], true, -1.0, true)
	draw_circle(pole_top + Vector2(0.0, -radius * 0.8), 3.0, lamp_gold_color, true, -1.0, true)
