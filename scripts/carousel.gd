class_name Carousel
extends Node2D
## The spinning platform. Only mounts and slots are children; enemies live in
## World/EnemyLayer. Draws a code placeholder until real art exists.

## Emitted once per tick after rotating. previous_angle is the unwrapped angle
## before this tick (it never wraps at 360°), so mounts can count booth passes
## and sweep exactly the arc travelled, even across many turns.
signal rotation_advanced(previous_angle: float, delta_angle: float)

@export_group("Placeholder Visuals")
@export_range(10.0, 400.0, 1.0, "suffix:px") var radius: float = 100.0
@export_range(1.0, 50.0, 1.0, "suffix:px") var rim_width: float = 8.0
@export_range(1.0, 100.0, 1.0, "suffix:px") var hub_radius: float = 16.0
## Spokes make the rotation visible on a plain circle.
@export_range(0, 24, 1) var spoke_count: int = 6
@export_range(0.5, 10.0, 0.5, "suffix:px") var spoke_width: float = 2.0
@export var base_color: Color = Color("4a7a3d")
@export var rim_color: Color = Color("2d5a25")
@export var hub_color: Color = Color("2d5a25")

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
	draw_circle(Vector2.ZERO, radius, base_color, true, -1.0, true)
	for i in spoke_count:
		var direction := Vector2.from_angle(TAU * i / spoke_count)
		# Antialiased so thin spokes glide instead of snapping pixel to pixel.
		draw_line(direction * hub_radius, direction * (radius - rim_width), rim_color, spoke_width, true)
	draw_arc(Vector2.ZERO, radius - rim_width / 2.0, 0.0, TAU, 64, rim_color, rim_width, true)
	draw_circle(Vector2.ZERO, hub_radius, hub_color, true, -1.0, true)
