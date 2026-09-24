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

@export_group("Boost Feedback")
## Brief brighten when Boost is pressed, so the press visibly lands on the carousel.
@export var pulse_modulate: Color = Color(1.35, 1.35, 1.35)
@export_range(0.01, 1.0, 0.01, "suffix:s") var pulse_duration: float = 0.2

var _pulse_tween: Tween

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


func pulse() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
	modulate = pulse_modulate
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(self, "modulate", Color.WHITE, pulse_duration)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, base_color)
	for i in spoke_count:
		var direction := Vector2.from_angle(TAU * i / spoke_count)
		# Antialiased so thin spokes glide instead of snapping pixel to pixel.
		draw_line(direction * hub_radius, direction * (radius - rim_width), rim_color, spoke_width, true)
	draw_arc(Vector2.ZERO, radius - rim_width / 2.0, 0.0, TAU, 64, rim_color, rim_width, true)
	draw_circle(Vector2.ZERO, hub_radius, hub_color)
