class_name ParkScenery
extends Control
## The title screen's park, drawn over the sky backdrop: a lawn and a paved
## promenade, a row of storybook shop-houses on each side (the middle stays
## clear for the title and carousel), an iron fence, a few bushes, and lamp
## posts with bunting strung between them. Kenney Background Elements sprites
## plus code-drawn lamps, bunting, shop awnings, balloons and a red-brick
## promenade (the theme-park cues: Main Street shops and pavement). Positions
## are fractions of the screen, so it fits any window size. Kept sparse on purpose.

@export_group("Ground")
## Where the lawn starts (fraction of the height from the top).
@export_range(0.3, 1.0, 0.01) var horizon: float = 0.7
@export var lawn_color: Color = Color("8fbf96")
@export var lawn_far_color: Color = Color("a9cfae")
## Warm brick, like a theme park's main street.
@export var promenade_color: Color = Color("c9826a")
@export var brick_line_color: Color = Color(0.45, 0.2, 0.15, 0.22)
@export_range(0.0, 0.3, 0.01) var promenade_top: float = 0.84
@export_range(0.0, 0.3, 0.01) var promenade_height: float = 0.07

@export_group("Shop-houses")
@export var houses: Array[Texture2D] = []
## Height of each house as a fraction of the screen height.
@export_range(0.05, 0.6, 0.01) var house_height: float = 0.16
## Houses fill from each edge toward the middle, up to this fraction of the
## width on each side.
@export_range(0.1, 0.5, 0.01) var house_side_width: float = 0.21
## Pushes them back into the distance.
@export var house_tint: Color = Color(0.93, 0.95, 1.0)
## Striped shop awnings over each house's ground floor; stripes alternate.
@export var awning_colors: Array[Color] = [Color("fff4dc"), Color("70568b")]
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
@export var lamp_color: Color = Color("243955")
@export var lamp_glow_color: Color = Color(1.0, 0.85, 0.55, 0.45)
@export var lamp_bulb_color: Color = Color("fff4dc")
@export_range(0.05, 0.6, 0.01) var lamp_height: float = 0.26
## Bunting flags cycle through these (palette A).
@export var bunting_colors: Array[Color] = [Color("fff4dc"), Color("70568b"), Color("ddb96a"), Color("405d83")]
@export_range(0.0, 0.2, 0.005) var bunting_sag: float = 0.04
@export_range(4.0, 40.0, 1.0, "suffix:px") var flag_size: float = 12.0

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
	# Lawn (a lighter strip far away), then the promenade.
	draw_rect(Rect2(0.0, ground_y, w, h - ground_y), lawn_color)
	draw_rect(Rect2(0.0, ground_y, w, h * 0.025), lawn_far_color)
	_draw_promenade(w, h)
	_draw_fence(w, h, ground_y)
	_draw_bushes(w, h, ground_y)
	_draw_lamps_and_bunting(w, h)
	_draw_balloons(w, h)


func _draw_houses(w: float, h: float, ground_y: float) -> void:
	if houses.is_empty():
		return
	for side in [-1, 1]:
		var x := 0.0 if side == -1 else w
		var limit := w * house_side_width
		var i := 0 if side == -1 else 1
		while absf(x - (0.0 if side == -1 else w)) < limit:
			var texture: Texture2D = houses[i % houses.size()]
			var scale := h * house_height / texture.get_height()
			var drawn := texture.get_size() * scale
			var left := x if side == -1 else x - drawn.x
			var rect := Rect2(Vector2(left, ground_y - drawn.y + 2.0), drawn)
			draw_texture_rect(texture, rect, false, house_tint)
			_draw_awning(rect)
			# Each row fills from its screen edge toward the middle.
			x -= drawn.x * 0.92 * side
			i += 1


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
		draw_circle(Vector2(x, top_y - 6.0), 16.0, lamp_glow_color, true, -1.0, true)
		draw_circle(Vector2(x, top_y - 6.0), 7.0, lamp_bulb_color, true, -1.0, true)
		draw_rect(Rect2(x - 8.0, top_y + 1.0, 16.0, 3.0), lamp_color)
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


## A striped awning with a scalloped edge across a house's ground floor.
func _draw_awning(house: Rect2) -> void:
	var width := house.size.x * 0.72
	var height := house.size.y * 0.075
	var top := Vector2(house.position.x + (house.size.x - width) / 2.0, house.position.y + house.size.y * 0.6)
	var stripe := width / awning_stripes
	for i in awning_stripes:
		var color: Color = awning_colors[i % awning_colors.size()]
		draw_rect(Rect2(top + Vector2(stripe * i, 0.0), Vector2(stripe, height)), color)
		draw_circle(top + Vector2(stripe * (i + 0.5), height), stripe / 2.0, color, true, -1.0, true)


## Warm brick: the band plus faint mortar lines, staggered row to row.
func _draw_promenade(w: float, h: float) -> void:
	var top := h * promenade_top
	var height := h * promenade_height
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
