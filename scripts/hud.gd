class_name Hud
extends CanvasLayer
## Shows GameState values and owns the Boost button. Listens to signals and
## asks for actions through its own signals; gameplay never references the HUD.

## Pressed the Boost button (or its keyboard shortcut). Game decides what happens.
signal boost_requested
## The Boost button (or its key) started or stopped being held. Holding cranks a stall.
signal boost_held_changed(held: bool)
signal send_wave_requested
signal auto_wave_toggled(on: bool)
signal emergency_clear_requested

# Label wording (Garret's text).
@export var gold_format: String = "Gold: %d"
@export var gold_per_second_format: String = "Gold per sec: %.1f"
@export var speed_format: String = "Speed: ×%.2f"
# TODO(Garret): text
## Send button while the countdown runs; %d is seconds left.
@export var wave_countdown_format: String = "Send wave (%d)"
# TODO(Garret): text
## Send button while auto waves are off.
@export var wave_paused_text: String = "Send wave"
# TODO(Garret): text
## Emergency Clear when ready; %d is the price.
@export var emergency_ready_format: String = "Clear latched (%d)"
# TODO(Garret): text
## Emergency Clear on cooldown; %d is seconds left.
@export var emergency_cooldown_format: String = "Clear ready in %ds"
## Boost bar tint during Overdrive.
@export var overdrive_bar_modulate: Color = Color(1.6, 1.3, 0.35)
## While stalled, the Boost bar shows the crank meter in this tint...
@export var crank_bar_modulate: Color = Color(1.5, 0.6, 0.5)
# TODO(Garret): text
## ...and the Boost button shows this label.
@export var crank_button_text: String = "Crank!"
## Keyboard shortcut for the Boost button.
@export var boost_key: Key = KEY_SPACE

@onready var _gold_label: Label = %GoldLabel
@onready var _gold_per_sec_label: Label = %GoldPerSecLabel
@onready var _speed_label: Label = %SpeedLabel
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _wave_button: Button = %WaveButton
@onready var _auto_wave_check: CheckButton = %AutoWaveCheck
@onready var _emergency_button: Button = %EmergencyButton
@onready var _boost_bar: ProgressBar = %BoostBar
@onready var _boost_button: Button = %BoostButton

var _boost_button_text: String = ""
var _mouse_holding_boost: bool = false
var _boost_held: bool = false
var _wave_seconds: int = 0


func _ready() -> void:
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.health_changed.connect(_on_health_changed)
	GameState.gold_per_second_changed.connect(_on_gold_per_second_changed)
	GameState.spin_speed_changed.connect(_on_spin_speed_changed)
	GameState.overdrive_changed.connect(_on_overdrive_changed)
	GameState.stall_changed.connect(_on_stall_changed)
	GameState.crank_changed.connect(_on_crank_changed)
	_boost_button_text = _boost_button.text
	_wave_button.pressed.connect(func() -> void:
		AudioManager.play_sfx(&"click")
		send_wave_requested.emit())
	_auto_wave_check.toggled.connect(func(on: bool) -> void:
		AudioManager.play_sfx(&"click")
		auto_wave_toggled.emit(on))
	_emergency_button.pressed.connect(emergency_clear_requested.emit)
	_boost_button.pressed.connect(boost_requested.emit)
	_boost_button.pressed.connect(func() -> void:
		AudioManager.play_sfx(&"crank" if GameState.is_stalled() else &"click"))
	_boost_button.button_down.connect(func() -> void: _mouse_holding_boost = true)
	_boost_button.button_up.connect(func() -> void: _mouse_holding_boost = false)
	_boost_button.shortcut = _make_shortcut(boost_key)
	# Read the current values in case they were announced before we connected.
	_on_gold_changed(GameState.get_gold(), 0.0)
	_on_health_changed(GameState.get_health(), GameState.get_max_health())
	_on_gold_per_second_changed(GameState.get_recent_gold_per_second())
	_on_spin_speed_changed(GameState.get_effective_spin_speed_rad_s())
	_on_overdrive_changed(GameState.is_overdrive_active())
	_on_stall_changed(GameState.is_stalled())


func _process(_delta: float) -> void:
	_refresh_emergency_button()
	var held := _mouse_holding_boost or Input.is_key_pressed(boost_key)
	if held != _boost_held:
		_boost_held = held
		boost_held_changed.emit(held)


func _on_gold_changed(balance: float, _delta: float) -> void:
	_gold_label.text = gold_format % floorf(balance)


func _on_gold_per_second_changed(value: float) -> void:
	_gold_per_sec_label.text = gold_per_second_format % value


## Fires every tick while the boost fades, so the bar drains smoothly.
func _on_spin_speed_changed(_speed_rad_s: float) -> void:
	_speed_label.text = speed_format % GameState.get_speed_multiplier()
	_refresh_boost_bar()


func _on_overdrive_changed(_active: bool) -> void:
	_refresh_boost_bar()


## TEMPORARY stall: the Boost button becomes the crank.
func _on_stall_changed(stalled: bool) -> void:
	_boost_button.text = crank_button_text if stalled else _boost_button_text
	_boost_button.theme_type_variation = &"CrankButton" if stalled else &""
	_refresh_boost_bar()


func _on_crank_changed(_fraction: float) -> void:
	_refresh_boost_bar()


## The bar shows the crank meter while stalled, otherwise the boost.
func _refresh_boost_bar() -> void:
	if GameState.is_stalled():
		_boost_bar.value = GameState.get_crank_fraction()
		_boost_bar.self_modulate = crank_bar_modulate
		return
	_boost_bar.value = GameState.get_click_boost_fraction()
	_boost_bar.self_modulate = overdrive_bar_modulate if GameState.is_overdrive_active() else Color.WHITE


func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current


## Game forwards WaveManager's countdown here.
func set_wave_countdown(seconds_left: int) -> void:
	_wave_seconds = seconds_left
	_refresh_wave_button()


## Game forwards the auto-wave state here (and the toggle reports changes back).
func set_auto_wave(on: bool) -> void:
	_auto_wave_check.set_pressed_no_signal(on)
	_refresh_wave_button()


func _refresh_wave_button() -> void:
	_wave_button.text = wave_countdown_format % _wave_seconds if _auto_wave_check.button_pressed else wave_paused_text


func _refresh_emergency_button() -> void:
	var cooldown := GameState.get_emergency_clear_cooldown()
	if cooldown > 0.0:
		_emergency_button.text = emergency_cooldown_format % ceili(cooldown)
	else:
		_emergency_button.text = emergency_ready_format % GameState.get_emergency_clear_cost()
	_emergency_button.disabled = not GameState.can_emergency_clear()


func _make_shortcut(key: Key) -> Shortcut:
	var event := InputEventKey.new()
	event.keycode = key
	var shortcut := Shortcut.new()
	shortcut.events = [event]
	return shortcut
