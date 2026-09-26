class_name ControllerPrompt
extends RefCounted
## Draws a controller button prompt in code, for whatever button an action is
## bound to (ControllerInput.get_joy_button / get_joy_axis). Face buttons are
## drawn by position (four dots, the bound one filled): Godot numbers them by
## position, not letter, so this matches any controller (Y on Xbox, X on
## Nintendo, triangle on PlayStation are all "top"). The D-pad is a cross with
## the bound arm filled; shoulders and triggers are an L/R pill; anything else
## is a plain dot. Real letter/symbol icons (e.g. Kenney Input Prompts, CC0)
## can replace this in the full controller pass.

const FACE_ANGLES: Dictionary[int, float] = {
	JOY_BUTTON_A: PI / 2.0,      # bottom
	JOY_BUTTON_B: 0.0,           # right
	JOY_BUTTON_X: PI,            # left
	JOY_BUTTON_Y: -PI / 2.0,     # top
}
const DPAD_ANGLES: Dictionary[int, float] = {
	JOY_BUTTON_DPAD_UP: -PI / 2.0,
	JOY_BUTTON_DPAD_DOWN: PI / 2.0,
	JOY_BUTTON_DPAD_LEFT: PI,
	JOY_BUTTON_DPAD_RIGHT: 0.0,
}


## Draws the prompt for `action` on `canvas` (call from its _draw()). Nothing
## is drawn if the action has no controller binding.
static func draw_action(canvas: CanvasItem, center: Vector2, action: StringName, radius: float = 9.0,
		ink: Color = Color(0.16, 0.09, 0.03), fill: Color = Color.WHITE) -> void:
	var button := ControllerInput.get_joy_button(action)
	if button >= 0:
		draw_button(canvas, center, button, radius, ink, fill)
		return
	var axis := ControllerInput.get_joy_axis(action)
	if axis == JOY_AXIS_TRIGGER_LEFT or axis == JOY_AXIS_TRIGGER_RIGHT:
		_draw_side_pill(canvas, center, axis == JOY_AXIS_TRIGGER_RIGHT, radius, ink, fill, true)


static func draw_button(canvas: CanvasItem, center: Vector2, button: int, radius: float = 9.0,
		ink: Color = Color(0.16, 0.09, 0.03), fill: Color = Color.WHITE) -> void:
	if FACE_ANGLES.has(button):
		canvas.draw_circle(center, radius, ink, true, -1.0, true)
		for index: int in FACE_ANGLES:
			var spot := center + Vector2.from_angle(FACE_ANGLES[index]) * radius * 0.5
			if index == button:
				canvas.draw_circle(spot, radius * 0.29, fill, true, -1.0, true)
			else:
				canvas.draw_arc(spot, radius * 0.22, 0.0, TAU, 10, Color(fill, 0.7), 1.0, true)
	elif DPAD_ANGLES.has(button):
		canvas.draw_circle(center, radius, ink, true, -1.0, true)
		for index: int in DPAD_ANGLES:
			var arm := Vector2.from_angle(DPAD_ANGLES[index])
			var rect := Rect2(center + arm * radius * 0.45 - Vector2.ONE * radius * 0.2, Vector2.ONE * radius * 0.4)
			canvas.draw_rect(rect, fill if index == button else Color(fill, 0.35))
	elif button == JOY_BUTTON_LEFT_SHOULDER or button == JOY_BUTTON_RIGHT_SHOULDER:
		_draw_side_pill(canvas, center, button == JOY_BUTTON_RIGHT_SHOULDER, radius, ink, fill, false)
	else:
		canvas.draw_circle(center, radius, ink, true, -1.0, true)
		canvas.draw_circle(center, radius * 0.35, fill, true, -1.0, true)


## L or R as a small pill (a bumper), or a taller rounded tab (a trigger).
static func _draw_side_pill(canvas: CanvasItem, center: Vector2, right: bool, radius: float, ink: Color,
		fill: Color, trigger: bool) -> void:
	var size := Vector2(radius * 2.4, radius * (1.9 if trigger else 1.3))
	canvas.draw_rect(Rect2(center - size / 2.0, size), ink)
	var font := load(LocaleFonts.DEFAULT_UI) as Font  # bundled fonts only
	var text := "R" if right else "L"
	var font_size := int(radius * 1.2)
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	canvas.draw_string(font, center + Vector2(-width / 2.0, font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, fill)
