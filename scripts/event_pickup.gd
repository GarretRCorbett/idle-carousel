class_name EventPickup
extends Node2D
## A pickup event's token (GDD "Random Events"): a glowing coin, bolt or ticket
## that bobs in the play area and fades after a few seconds. Click or tap it,
## or press the grab button on a controller (Game calls grab()). Missing it
## costs nothing. Drawn in code; lives in World, not on the carousel.

signal grabbed(pickup: EventPickup)

var event: EventData
## Seconds before it's gone.
var lifetime: float = 8.0
## Draw the controller's grab-button prompt (a controller is in use).
var show_prompt: bool = false:
	set(value):
		show_prompt = value
		queue_redraw()

@export_range(4.0, 64.0, 1.0, "suffix:px") var radius: float = 16.0
## Clicks this far out still count (it's a moving target).
@export_range(1.0, 3.0, 0.1) var click_radius_scale: float = 1.6
@export_range(0.0, 20.0, 0.5, "suffix:px") var bob_height: float = 5.0
@export_range(0.1, 5.0, 0.1, "suffix:/s") var bob_speed: float = 2.0
## Fades out over its last this-many seconds.
@export_range(0.1, 5.0, 0.1, "suffix:s") var fade_seconds: float = 2.0
@export var glow_color: Color = Color(1.0, 0.9, 0.5, 0.35)
@export var ink_color: Color = Color(0.16, 0.09, 0.03, 1.0)

var _age: float = 0.0
var _home: Vector2
var _taken: bool = false


func _ready() -> void:
	_home = position


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	position = _home + Vector2(0.0, sin(_age * TAU * bob_speed * 0.5) * bob_height)
	modulate.a = clampf((lifetime - _age) / fade_seconds, 0.0, 1.0)
	queue_redraw()


## Mouse and touch (touch arrives as a mouse click). Pickups sit above the
## enemies' click layer, so a click on the token never hits an enemy behind it.
func _unhandled_input(input: InputEvent) -> void:
	var click := input as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT or not click.pressed:
		return
	var point := get_canvas_transform().affine_inverse() * click.position
	if point.distance_to(global_position) <= radius * click_radius_scale:
		grab()
		get_viewport().set_input_as_handled()


## Takes it (once). Game starts the event.
func grab() -> void:
	if _taken:
		return
	_taken = true
	grabbed.emit(self)
	queue_free()


func _draw() -> void:
	var color := event.color if event != null else Color.GOLD
	draw_circle(Vector2.ZERO, radius * 1.6, glow_color, true, -1.0, true)
	match event.shape if event != null else EventData.Shape.COIN:
		EventData.Shape.COIN:
			draw_circle(Vector2.ZERO, radius, ink_color, true, -1.0, true)
			draw_circle(Vector2.ZERO, radius - 2.5, color, true, -1.0, true)
			draw_arc(Vector2.ZERO, radius * 0.55, 0.0, TAU, 24, ink_color.lerp(color, 0.5), 2.0, true)
		EventData.Shape.BOLT:
			draw_circle(Vector2.ZERO, radius, ink_color, true, -1.0, true)
			var r := radius * 0.8
			var bolt := PackedVector2Array([Vector2(0.15, -1.0), Vector2(-0.45, 0.1), Vector2(-0.05, 0.1),
					Vector2(-0.2, 1.0), Vector2(0.5, -0.2), Vector2(0.08, -0.2)])
			for i in bolt.size():
				bolt[i] *= r
			draw_colored_polygon(bolt, color)
		EventData.Shape.TICKET:
			var rect := Rect2(-radius * 1.2, -radius * 0.75, radius * 2.4, radius * 1.5)
			draw_rect(rect.grow(2.0), ink_color)
			draw_rect(rect, color)
			draw_circle(Vector2(rect.position.x, 0.0), radius * 0.3, ink_color, true, -1.0, true)
			draw_circle(Vector2(rect.end.x, 0.0), radius * 0.3, ink_color, true, -1.0, true)
			draw_line(Vector2(0.0, rect.position.y + 3.0), Vector2(0.0, rect.end.y - 3.0), ink_color, 1.5)
	if show_prompt:
		_draw_prompt(Vector2(radius * 1.1, -radius * 1.1))


## The grab button as four face-button dots with the top one filled, so it
## reads on any controller (Y on Xbox, X on Nintendo, triangle on PlayStation).
func _draw_prompt(center: Vector2) -> void:
	draw_circle(center, 9.0, ink_color, true, -1.0, true)
	for i in 4:
		var spot := center + Vector2.from_angle(-PI / 2.0 + i * PI / 2.0) * 4.5
		if i == 0:
			draw_circle(spot, 2.6, Color.WHITE, true, -1.0, true)
		else:
			draw_arc(spot, 2.0, 0.0, TAU, 10, Color(1, 1, 1, 0.7), 1.0, true)
