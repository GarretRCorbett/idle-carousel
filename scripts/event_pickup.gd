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
## The action that grabs it; the prompt shows whatever button it's bound to.
var grab_action: StringName = &"grab_pickup"

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
	# The prompt shows only while a controller is in use (it redraws each frame).


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
	draw_circle(Vector2.ZERO, radius * 1.6, glow_color, true, -1.0, true)
	draw_token(self, event, radius, ink_color)
	if ControllerInput.using_controller:
		ControllerPrompt.draw_action(self, Vector2(radius * 1.1, -radius * 1.1), grab_action, 9.0, ink_color)


## An event's token (its shape in its color) on `canvas` at its origin. The
## Park Guide draws the same token as its icon.
static func draw_token(canvas: CanvasItem, event_data: EventData, size: float, ink: Color) -> void:
	var color := event_data.color if event_data != null else Color.GOLD
	match event_data.shape if event_data != null else EventData.Shape.COIN:
		EventData.Shape.COIN:
			canvas.draw_circle(Vector2.ZERO, size, ink, true, -1.0, true)
			canvas.draw_circle(Vector2.ZERO, size - 2.5, color, true, -1.0, true)
			canvas.draw_arc(Vector2.ZERO, size * 0.55, 0.0, TAU, 24, ink.lerp(color, 0.5), 2.0, true)
		EventData.Shape.BOLT:
			canvas.draw_circle(Vector2.ZERO, size, ink, true, -1.0, true)
			var r := size * 0.8
			var bolt := PackedVector2Array([Vector2(0.15, -1.0), Vector2(-0.45, 0.1), Vector2(-0.05, 0.1),
					Vector2(-0.2, 1.0), Vector2(0.5, -0.2), Vector2(0.08, -0.2)])
			for i in bolt.size():
				bolt[i] *= r
			canvas.draw_colored_polygon(bolt, color)
		EventData.Shape.TICKET:
			var rect := Rect2(-size * 1.2, -size * 0.75, size * 2.4, size * 1.5)
			canvas.draw_rect(rect.grow(2.0), ink)
			canvas.draw_rect(rect, color)
			canvas.draw_circle(Vector2(rect.position.x, 0.0), size * 0.3, ink, true, -1.0, true)
			canvas.draw_circle(Vector2(rect.end.x, 0.0), size * 0.3, ink, true, -1.0, true)
			canvas.draw_line(Vector2(0.0, rect.position.y + 3.0), Vector2(0.0, rect.end.y - 3.0), ink, 1.5)
