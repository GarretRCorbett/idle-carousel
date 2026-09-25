class_name TwoStepButton
extends Button
## A button that asks once before acting (Garret, memo R): the first press
## turns it into "Confirm?" for confirm_seconds, a second press emits
## `confirmed`. The game keeps running; nothing pops up. Used for Sell mount
## and Give up. Connect to `confirmed`, not `pressed`.

## The action was confirmed (second press, or the only press when
## requires_confirm is off).
signal confirmed

## Off: one press acts straight away (a future Settings toggle).
@export var requires_confirm: bool = true
## How long it waits for the second press.
@export_range(0.5, 10.0, 0.1, "suffix:s") var confirm_seconds: float = 3.0
## A second press sooner than this is ignored, so a quick double-click can't
## confirm by accident.
@export_range(0.0, 1.0, 0.05, "suffix:s") var min_confirm_delay: float = 0.25
## Text while waiting (translation key).
@export var confirm_key: String = "UI_CONFIRM"

## What the button says when it isn't waiting (set with set_idle_text).
var _idle_text: String = ""
## Seconds since the first press; below 0 = not waiting.
var _armed_for: float = -1.0


func _ready() -> void:
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_idle_text = text
	pressed.connect(_on_pressed)
	set_process(false)


## Sets the normal text. While it's waiting for the second press, the new
## text shows once it stops waiting (so a shop refresh can't hide "Confirm?").
func set_idle_text(value: String) -> void:
	_idle_text = value
	if not is_armed():
		text = value


func is_armed() -> bool:
	return _armed_for >= 0.0


## Stops waiting and shows the normal text again.
func disarm() -> void:
	_armed_for = -1.0
	text = _idle_text
	set_process(false)


func _on_pressed() -> void:
	if not requires_confirm:
		confirmed.emit()
		return
	if not is_armed():
		_armed_for = 0.0
		text = tr(confirm_key)
		set_process(true)
		return
	if _armed_for < min_confirm_delay:
		return
	disarm()
	confirmed.emit()


func _process(delta: float) -> void:
	_armed_for += delta
	if _armed_for >= confirm_seconds or disabled:
		disarm()
