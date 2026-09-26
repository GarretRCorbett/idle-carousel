class_name Carousel
extends Node2D
## The spinning platform. Only mounts and slots are children; enemies live in
## World/EnemyLayer. Drawn in code: a walnut deck under alternating ivory and
## violet canopy wedges, a gold scalloped trim, a ring of warm bulbs, and a
## gold hub (palette A "Gilded Garden", planning/phase3/codex_memo_t_palette.md).

## Emitted once per tick after rotating. previous_angle is the unwrapped angle
## before this tick (it never wraps at 360°), so mounts can count booth passes
## and sweep exactly the arc travelled, even across many turns.
signal rotation_advanced(previous_angle: float, delta_angle: float)

@export_group("Look")
@export_range(10.0, 400.0, 1.0, "suffix:px") var radius: float = 100.0
## The deck showing around the canopy's edge.
@export var base_color: Color = Color("765642")
## Gilded Rims (Phase 4 Step 6): the rim blends from base_color toward this.
@export var gilded_base_color: Color = Color("c9a24a")
## Canopy wedges alternate these two; they also make the spin visible.
@export_range(4, 48, 2) var wedge_count: int = 12
@export var wedge_color_a: Color = Color("fff4dc")
@export var wedge_color_b: Color = Color("70568b")
## Gold trim: the scalloped edge, its line, and the hub.
@export var trim_color: Color = Color("ddb96a")
@export_range(0.0, 30.0, 1.0, "suffix:px") var canopy_inset: float = 10.0
@export_range(1.0, 20.0, 0.5, "suffix:px") var scallop_radius: float = 7.0
@export_range(1.0, 100.0, 1.0, "suffix:px") var hub_radius: float = 16.0
@export_group("Bulbs")
@export_range(0, 120, 1) var bulb_count: int = 36
@export var bulb_color: Color = Color("fff7e6")
@export var bulb_glow_color: Color = Color(1.0, 0.82, 0.54, 0.35)
@export_range(0.5, 10.0, 0.5, "suffix:px") var bulb_radius: float = 2.2
@export_range(1.0, 20.0, 0.5, "suffix:px") var bulb_glow_radius: float = 5.0

@export_group("Boost Glow")
## Glow while the boost bar is maxed out...
@export var boost_glow_modulate: Color = Color(1.3, 1.3, 1.1)
## ...and a gold glow during Overdrive (maxed long enough for ×2 speed).
@export var overdrive_glow_modulate: Color = Color(1.5, 1.3, 0.55)
## Seconds to fade between glow states.
@export_range(0.01, 2.0, 0.01, "suffix:s") var glow_fade_seconds: float = 0.25

var _glow_target: Color = Color.WHITE

var _unwrapped_angle: float = 0.0


## Called by Game once per physics tick; Carousel never moves itself.
## Positive speed turns clockwise on screen.
## How gilded the rim is, 0..1 (set_gilding).
var _gilding: float = 0.0

func advance_rotation(delta: float, speed_rad_s: float) -> void:
	var step := speed_rad_s * delta
	if step == 0.0 or not is_finite(step):
		return
	var previous := _unwrapped_angle
	_unwrapped_angle += step
	rotation = wrapf(_unwrapped_angle, -PI, PI)
	rotation_advanced.emit(previous, step)


func get_unwrapped_angle() -> float:
	return _unwrapped_angle


## Called each tick with the boost state from GameState.
## 0 = plain walnut rim, 1 = fully gilded (Gilded Rims levels bought / max).
func set_gilding(amount: float) -> void:
	_gilding = clampf(amount, 0.0, 1.0)
	queue_redraw()


func set_boost_state(maxed: bool, overdrive: bool) -> void:
	if overdrive:
		_glow_target = overdrive_glow_modulate
	elif maxed:
		_glow_target = boost_glow_modulate
	else:
		_glow_target = Color.WHITE


func get_glow_target() -> Color:
	return _glow_target


func _process(delta: float) -> void:
	modulate = modulate.lerp(_glow_target, clampf(delta / glow_fade_seconds, 0.0, 1.0))


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, base_color.lerp(gilded_base_color, _gilding), true, -1.0, true)
	var canopy := radius - canopy_inset
	for i in wedge_count:
		var from := TAU * i / wedge_count
		var to := TAU * (i + 1) / wedge_count
		var points := PackedVector2Array([Vector2.ZERO])
		for k in 7:
			points.append(Vector2.from_angle(lerpf(from, to, k / 6.0)) * canopy)
		draw_colored_polygon(points, wedge_color_a if i % 2 == 0 else wedge_color_b)
	# Scallops: a half-circle of trim at the middle of every half-wedge.
	for i in wedge_count * 2:
		draw_circle(Vector2.from_angle(TAU * (i + 0.5) / (wedge_count * 2)) * (canopy + 4.0), scallop_radius, trim_color, true, -1.0, true)
	draw_arc(Vector2.ZERO, canopy, 0.0, TAU, 64, trim_color, 3.0, true)
	for i in bulb_count:
		var spot := Vector2.from_angle(TAU * i / bulb_count) * (radius + 1.0)
		draw_circle(spot, bulb_glow_radius, bulb_glow_color, true, -1.0, true)
		draw_circle(spot, bulb_radius, bulb_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, hub_radius, trim_color, true, -1.0, true)
