class_name StubMascot
extends Node2D
## Stub, the ticket mascot (GDD v1.20 "Theme and Mascot"), drawn entirely in
## code so any theme can re-skin it with colors. Punch-hole eyes, a small
## mouth, and one of three body styles (Garret picks one; the others can go).
## Idle: a gentle hop and tilt. The tutorial and tips will use this node.

enum Style {
	CLASSIC,  ## a wide admission ticket: notched sides, a perforated stub end
	TALL,     ## an upright gold cinema-style ticket
	TORN,     ## just the torn-off stub: a zigzag edge and tiny arms
}
enum Mood { HAPPY, SURPRISED, WORRIED, CHEER }
## Versions of the classic ticket (Garret asked for a few more to compare).
enum ClassicVariant {
	PLAIN,      ## notches and a perforated stub end
	SCALLOPED,  ## little bites along the top and bottom, like a tear-off ticket
	TWO_TONE,   ## the stub end filled with the trim color, a star punched out
	CHUNKY,     ## taller and rounder, with little feet
}

@export var style: Style = Style.CLASSIC:
	set(value):
		style = value
		queue_redraw()
@export var classic_variant: ClassicVariant = ClassicVariant.PLAIN:
	set(value):
		classic_variant = value
		queue_redraw()
@export var mood: Mood = Mood.HAPPY:
	set(value):
		mood = value
		queue_redraw()
## Size of the ticket body (width of the classic ticket), in pixels.
@export_range(20.0, 400.0, 1.0, "suffix:px") var size: float = 120.0
@export var paper_color: Color = Color("fff4dc")
@export var trim_color: Color = Color("c0392b")
@export var ink_color: Color = Color("2a1f2d")
@export var cheek_color: Color = Color(1.0, 0.55, 0.55, 0.6)
## What shows through the punch holes and side notches (the panel Stub sits on).
@export var backdrop_color: Color = Color(0.13, 0.11, 0.16)
## Idle motion (0 = still, e.g. for renders).
@export_range(0.0, 20.0, 0.5, "suffix:px") var hop_height: float = 4.0
@export_range(0.0, 10.0, 0.5, "suffix:°") var tilt_degrees: float = 4.0
@export_range(0.1, 5.0, 0.1, "suffix:/s") var idle_speed: float = 1.2

var _time: float = 0.0


func _process(delta: float) -> void:
	if hop_height <= 0.0 and tilt_degrees <= 0.0:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var hop := -absf(sin(_time * TAU * idle_speed * 0.5)) * hop_height
	var tilt := deg_to_rad(sin(_time * TAU * idle_speed * 0.25) * tilt_degrees)
	draw_set_transform(Vector2(0.0, hop), tilt)
	match style:
		Style.CLASSIC:
			_draw_classic()
		Style.TALL:
			_draw_tall()
		Style.TORN:
			_draw_torn()
	draw_set_transform(Vector2.ZERO)


# --- Bodies ----------------------------------------------------------------------

func _draw_classic() -> void:
	var chunky := classic_variant == ClassicVariant.CHUNKY
	var w := size * (0.85 if chunky else 1.0)
	var h := size * (0.72 if chunky else 0.55)
	var rect := Rect2(-w / 2.0, -h / 2.0, w, h)
	if chunky:
		# Little feet under the body.
		for fx: float in [-w * 0.18, w * 0.08]:
			draw_line(Vector2(fx, rect.end.y), Vector2(fx, rect.end.y + h * 0.12), trim_color, 4.0, true)
			draw_line(Vector2(fx, rect.end.y + h * 0.12), Vector2(fx + w * 0.06, rect.end.y + h * 0.12), trim_color, 4.0, true)
	_ticket(rect, h * 0.16, Color(0, 0, 0, 0), h * (0.28 if chunky else 0.1))
	var x := rect.end.x - w * 0.22
	if classic_variant == ClassicVariant.TWO_TONE:
		var stub := Rect2(Vector2(x, rect.position.y), Vector2(rect.end.x - x, h)).grow(-2.0)
		var band := StyleBoxFlat.new()
		band.bg_color = trim_color
		band.corner_radius_top_right = int(h * 0.1)
		band.corner_radius_bottom_right = int(h * 0.1)
		draw_style_box(band, stub)
		_star(stub.get_center() + Vector2(0.0, -h * 0.26), h * 0.12, backdrop_color)  # above the notch
		# The side notch shows over the band too.
		draw_circle(Vector2(rect.end.x, rect.get_center().y), h * 0.16, backdrop_color, true, -1.0, true)
	else:
		_perforation(Vector2(x, rect.position.y + 6.0), Vector2(x, rect.end.y - 6.0))
	if classic_variant == ClassicVariant.SCALLOPED:
		var bites := int(w / 12.0)
		for i in bites:
			var bx := rect.position.x + w * (i + 0.5) / bites
			draw_circle(Vector2(bx, rect.position.y), 3.2, backdrop_color, true, -1.0, true)
			draw_circle(Vector2(bx, rect.end.y), 3.2, backdrop_color, true, -1.0, true)
	_face(Vector2(rect.position.x + (w - w * 0.22) / 2.0, -h * 0.06), h * (0.8 if chunky else 0.9))


func _draw_tall() -> void:
	var w := size * 0.55
	var h := size * 0.95
	var rect := Rect2(-w / 2.0, -h / 2.0, w, h)
	_ticket(rect, w * 0.14, Color("ffd24a"))
	var y := rect.end.y - h * 0.24
	_perforation(Vector2(rect.position.x + 6.0, y), Vector2(rect.end.x - 6.0, y))
	_face(Vector2(0.0, rect.position.y + h * 0.33), w * 1.05)


func _draw_torn() -> void:
	var w := size * 0.42
	var h := size * 0.62
	var top := -h / 2.0
	var points := PackedVector2Array()
	# Zigzag torn top edge, then straight sides and a rounded-ish bottom.
	var teeth := 6
	for i in teeth + 1:
		var px := -w / 2.0 + w * i / teeth
		points.append(Vector2(px, top + (5.0 if i % 2 == 1 else 0.0)))
	points.append(Vector2(w / 2.0, h / 2.0))
	points.append(Vector2(-w / 2.0, h / 2.0))
	var outline := points.duplicate()
	outline.append(points[0])
	draw_colored_polygon(points, paper_color)
	draw_polyline(outline, trim_color, 3.0, true)
	# Tiny arms.
	var arm_y := h * 0.08
	draw_line(Vector2(-w / 2.0, arm_y), Vector2(-w / 2.0 - w * 0.28, arm_y - w * 0.22), trim_color, 3.0, true)
	draw_line(Vector2(w / 2.0, arm_y), Vector2(w / 2.0 + w * 0.28, arm_y - w * 0.22), trim_color, 3.0, true)
	_face(Vector2(0.0, -h * 0.02), w * 1.1)


# --- Pieces ----------------------------------------------------------------------

## A ticket body: paper with a trim border and half-circle notches on the sides.
func _ticket(rect: Rect2, notch: float, fill: Color = Color(0, 0, 0, 0), corner: float = -1.0) -> void:
	var paper := fill if fill.a > 0.0 else paper_color
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = paper
	style_box.border_color = trim_color
	style_box.set_border_width_all(3)
	style_box.set_corner_radius_all(int(corner if corner >= 0.0 else notch * 0.6))
	style_box.anti_aliasing = true
	draw_style_box(style_box, rect)
	# Notches: bites out of the middle of each side, showing the backdrop.
	# Only the inner half of each notch's edge is drawn, so they bite inward.
	var mid_y := rect.get_center().y
	draw_circle(Vector2(rect.position.x, mid_y), notch, backdrop_color, true, -1.0, true)
	draw_arc(Vector2(rect.position.x, mid_y), notch, -PI / 2.0, PI / 2.0, 12, trim_color, 3.0, true)
	draw_circle(Vector2(rect.end.x, mid_y), notch, backdrop_color, true, -1.0, true)
	draw_arc(Vector2(rect.end.x, mid_y), notch, PI / 2.0, PI * 1.5, 12, trim_color, 3.0, true)


## A five-point star (the punched star on the two-tone stub).
func _star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var r := radius if i % 2 == 0 else radius * 0.45
		points.append(center + Vector2.from_angle(-PI / 2.0 + i * PI / 5.0) * r)
	draw_colored_polygon(points, color)


func _perforation(from: Vector2, to: Vector2) -> void:
	var steps := int(from.distance_to(to) / 7.0)
	for i in steps + 1:
		draw_circle(from.lerp(to, float(i) / maxi(1, steps)), 1.4, trim_color, true, -1.0, true)


## Punch-hole eyes and a mouth, by mood. `span` is the face's width.
func _face(center: Vector2, span: float) -> void:
	var eye_r := span * 0.075
	var eye_dx := span * 0.17
	var holes := backdrop_color  # punched through: you see what's behind
	match mood:
		Mood.SURPRISED:
			for side: float in [-1.0, 1.0]:
				draw_circle(center + Vector2(side * eye_dx, 0.0), eye_r * 1.25, holes, true, -1.0, true)
			draw_circle(center + Vector2(0.0, span * 0.17), eye_r * 0.8, holes, true, -1.0, true)
		Mood.WORRIED:
			for side: float in [-1.0, 1.0]:
				var eye := center + Vector2(side * eye_dx, 0.0)
				draw_circle(eye, eye_r, holes, true, -1.0, true)
				draw_line(eye + Vector2(-side * eye_r * 1.3, -eye_r * 2.2), eye + Vector2(side * eye_r * 0.9, -eye_r * 1.5), ink_color, 2.0, true)
			draw_arc(center + Vector2(0.0, span * 0.24), span * 0.09, PI + 0.4, TAU - 0.4, 12, ink_color, 2.5, true)
		Mood.CHEER:
			for side: float in [-1.0, 1.0]:
				var eye := center + Vector2(side * eye_dx, 0.0)
				draw_arc(eye, eye_r, PI, TAU, 10, ink_color, 2.5, true)  # happy squint
			draw_circle(center + Vector2(0.0, span * 0.15), span * 0.09, ink_color, true, -1.0, true)
			_cheeks(center, span, eye_dx)
		_:
			for side: float in [-1.0, 1.0]:
				draw_circle(center + Vector2(side * eye_dx, 0.0), eye_r, holes, true, -1.0, true)
			draw_arc(center + Vector2(0.0, span * 0.1), span * 0.09, 0.3, PI - 0.3, 12, ink_color, 2.5, true)
			_cheeks(center, span, eye_dx)


func _cheeks(center: Vector2, span: float, eye_dx: float) -> void:
	for side: float in [-1.0, 1.0]:
		draw_circle(center + Vector2(side * eye_dx * 1.55, span * 0.1), span * 0.05, cheek_color, true, -1.0, true)

