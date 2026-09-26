extends Node
## Controller support in one place (Garret, 2026-09-26: "use those functions in
## other places as it comes up"):
## - using_controller: was a controller the last thing used? Button prompts
##   show only then; any mouse, key or touch input hides them again.
## - get_joy_button(action): the controller button an Input Map action is bound
##   to, so a prompt always shows the real binding (remaps included).
## Draw prompts with ControllerPrompt.draw(). Every player control is an Input
## Map action (project.godot), never a hard-coded key or button.

## The last input switched between a controller and mouse/keyboard/touch.
signal device_changed(using_controller: bool)

## Stick and trigger motion smaller than this doesn't count (resting sticks drift).
const MOTION_DEADZONE := 0.4

var using_controller: bool = false


func _input(event: InputEvent) -> void:
	var controller := event is InputEventJoypadButton \
			or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > MOTION_DEADZONE)
	var other := event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch
	if controller and not using_controller:
		set_using_controller(true)
	elif other and using_controller:
		set_using_controller(false)


## Also for tests and future settings (e.g. a "prompts: controller" option).
func set_using_controller(value: bool) -> void:
	if value == using_controller:
		return
	using_controller = value
	device_changed.emit(value)


## The controller button bound to `action` (a JoyButton), or -1 if it has none.
## Axis bindings (triggers) return -1; use get_joy_axis() for those.
func get_joy_button(action: StringName) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


## The controller axis bound to `action` (a JoyAxis, e.g. the right trigger), or -1.
func get_joy_axis(action: StringName) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var motion := event as InputEventJoypadMotion
		if motion != null:
			return motion.axis
	return -1
