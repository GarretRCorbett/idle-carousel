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

# Wording: translation keys in localization/strings.csv. Placeholders are {0}, {1}...
# (numbered, so pseudolocalization and translators can't mangle them).
@export var gold_key: String = "HUD_GOLD"
@export var gold_per_second_key: String = "HUD_GOLD_PER_SEC"
@export var speed_key: String = "HUD_SPEED"
@export var wave_countdown_key: String = "HUD_SEND_WAVE_COUNTDOWN"
@export var wave_paused_key: String = "HUD_SEND_WAVE"
@export var emergency_ready_key: String = "HUD_CLEAR_READY"
@export var emergency_cooldown_key: String = "HUD_CLEAR_COOLDOWN"
## With Auto-Boost bought, the Boost button says what it holds ("Boost (auto 65%)").
@export var boost_auto_key: String = "HUD_BOOST_AUTO"
## While stalled, the Boost button shows this label (a translation key).
## Bar colors come from the UI theme's CrankBar / OverdriveBar roles.
@export var crank_button_key: String = "HUD_CRANK"
## Input Map action for Boost (Space, or the right trigger on a controller).
@export var boost_action: StringName = &"boost"
## "Saved" flashes in the bottom-left corner after each save (GDD: a small save icon).
@export var saved_key: String = "HUD_SAVED"
@export_range(0.1, 5.0, 0.1, "suffix:s") var saved_show_seconds: float = 1.2

@export_group("Boost bar")
## A thin tick on the Boost bar where Auto-Boost holds it.
@export var auto_marker_color: Color = Color(1.0, 0.96, 0.86, 0.9)
@export_range(1.0, 6.0, 0.5, "suffix:px") var auto_marker_width: float = 2.0
## While latched enemies drain the bar, it pulses toward this tint, so you can
## see why the bar is sinking (GDD v1.17: latches drain it gently).
@export var drain_tint: Color = Color(1.0, 0.4, 0.35)
@export_range(0.5, 20.0, 0.5, "suffix:/s") var drain_pulse_speed: float = 6.0

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
## What the Clear button shows now, so it's only rebuilt when something changes
## (it's checked every frame). Seconds -2 forces a rebuild.
var _clear_seconds_shown: int = -2
var _clear_cost_shown: float = -1.0
var _clear_enabled_shown: bool = false
var _saved_label: Label
var _auto_marker: ColorRect
var _pulse_time: float = 0.0
var _saved_tween: Tween


func _ready() -> void:
	_gold_label.add_theme_color_override(&"font_color", _gold_label.get_theme_color(&"gold", &"Palette"))
	_gold_per_sec_label.add_theme_color_override(&"font_color", _gold_per_sec_label.get_theme_color(&"muted", &"Palette"))
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.health_changed.connect(_on_health_changed)
	GameState.gold_per_second_changed.connect(_on_gold_per_second_changed)
	GameState.spin_speed_changed.connect(_on_spin_speed_changed)
	GameState.overdrive_changed.connect(_on_overdrive_changed)
	GameState.stall_changed.connect(_on_stall_changed)
	GameState.crank_changed.connect(_on_crank_changed)
	_boost_button_text = _boost_button.text
	# These show text built in code with tr(); don't translate it a second time.
	for node: Control in [_gold_label, _gold_per_sec_label, _speed_label, _wave_button, _emergency_button, _boost_button]:
		node.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_boost_button.text = tr(_boost_button_text)
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
	_boost_button.shortcut = _make_shortcut(boost_action)
	_make_saved_label()
	SaveManager.run_saved.connect(_on_run_saved)
	_make_auto_marker()
	GameState.upgrade_applied.connect(func(_id: StringName, _level: int) -> void: _refresh_auto_boost())
	GameState.run_reset.connect(_refresh_auto_boost)
	_boost_bar.resized.connect(_refresh_auto_boost)
	# Read the current values in case they were announced before we connected.
	_on_gold_changed(GameState.get_gold(), 0.0)
	_on_health_changed(GameState.get_health(), GameState.get_max_health())
	_on_gold_per_second_changed(GameState.get_recent_gold_per_second())
	_on_spin_speed_changed(GameState.get_effective_spin_speed_rad_s())
	_on_overdrive_changed(GameState.is_overdrive_active())
	_on_stall_changed(GameState.is_stalled())
	# Also here, not only in _process: a run can start paused ("Welcome back").
	_refresh_emergency_button()


## Language changed: rebuild the text this script fills in (scene text updates itself).
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_on_gold_changed(GameState.get_gold(), 0.0)
		_on_gold_per_second_changed(GameState.get_recent_gold_per_second())
		_on_spin_speed_changed(GameState.get_effective_spin_speed_rad_s())
		_on_stall_changed(GameState.is_stalled())
		_refresh_wave_button()
		_clear_seconds_shown = -2
		_refresh_emergency_button()
		_saved_label.text = tr(saved_key)


func _process(delta: float) -> void:
	_refresh_emergency_button()
	_pulse_drain(delta)
	var held := _mouse_holding_boost or Input.is_action_pressed(boost_action)
	if held != _boost_held:
		_boost_held = held
		boost_held_changed.emit(held)


func _on_gold_changed(balance: float, _delta: float) -> void:
	_gold_label.text = tr(gold_key).format([NumberFormat.gold(balance)])


func _on_gold_per_second_changed(value: float) -> void:
	_gold_per_sec_label.text = tr(gold_per_second_key).format([NumberFormat.decimal(value, 1)])


## Fires every tick while the boost fades, so the bar drains smoothly.
func _on_spin_speed_changed(_speed_rad_s: float) -> void:
	_speed_label.text = tr(speed_key).format([NumberFormat.decimal(GameState.get_speed_multiplier(), 2)])
	_refresh_boost_bar()


func _on_overdrive_changed(_active: bool) -> void:
	_refresh_boost_bar()


## Stalled: the Boost button becomes the crank.
func _on_stall_changed(stalled: bool) -> void:
	_boost_button.text = tr(crank_button_key) if stalled else _boost_label()
	_boost_button.theme_type_variation = &"CrankButton" if stalled else &""
	_refresh_boost_bar()


func _on_crank_changed(_fraction: float) -> void:
	_refresh_boost_bar()


## The bar shows the crank meter while stalled, otherwise the boost.
func _refresh_boost_bar() -> void:
	if GameState.is_stalled():
		_boost_bar.value = GameState.get_crank_fraction()
		_boost_bar.theme_type_variation = &"CrankBar"
		return
	_boost_bar.value = GameState.get_click_boost_fraction()
	_boost_bar.theme_type_variation = &"OverdriveBar" if GameState.is_overdrive_active() else &""


func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current


## Game forwards WaveManager's countdown here.
func set_wave_countdown(seconds_left: int) -> void:
	_wave_seconds = seconds_left
	_refresh_wave_button()


## Game forwards whether Send wave is allowed (not too many enemies alive).
func set_send_available(available: bool) -> void:
	_wave_button.disabled = not available


## Game forwards the auto-wave state here (and the toggle reports changes back).
func set_auto_wave(on: bool) -> void:
	_auto_wave_check.set_pressed_no_signal(on)
	_refresh_wave_button()


func _refresh_wave_button() -> void:
	_wave_button.text = (tr(wave_countdown_key).format([_wave_seconds])
			if _auto_wave_check.button_pressed else tr(wave_paused_key))


func _refresh_emergency_button() -> void:
	var seconds := ceili(GameState.get_emergency_clear_cooldown())
	var cost := GameState.get_emergency_clear_cost()
	var enabled := GameState.can_emergency_clear()
	if seconds == _clear_seconds_shown and cost == _clear_cost_shown and enabled == _clear_enabled_shown:
		return
	_clear_seconds_shown = seconds
	_clear_cost_shown = cost
	_clear_enabled_shown = enabled
	if seconds > 0:
		_emergency_button.text = tr(emergency_cooldown_key).format([seconds])
	else:
		_emergency_button.text = tr(emergency_ready_key).format([NumberFormat.gold(cost)])
	_emergency_button.disabled = not enabled


## "Boost", or "Boost (auto 65%)" once Auto-Boost is bought.
func _boost_label() -> String:
	var hold := GameState.get_auto_boost_hold()
	return tr(boost_auto_key).format([roundi(hold * 100.0)]) if hold > 0.0 else tr(_boost_button_text)


func _make_auto_marker() -> void:
	_auto_marker = ColorRect.new()
	_auto_marker.name = "AutoBoostMarker"
	_auto_marker.color = auto_marker_color
	_auto_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boost_bar.add_child(_auto_marker)
	_refresh_auto_boost()


## The marker sits where Auto-Boost holds the bar; the button says so too.
func _refresh_auto_boost() -> void:
	var hold := GameState.get_auto_boost_hold()
	_auto_marker.visible = hold > 0.0
	var height := _boost_bar.size.y + 6.0
	_auto_marker.position = Vector2(roundf(_boost_bar.size.x * hold - auto_marker_width / 2.0), -3.0)
	_auto_marker.size = Vector2(auto_marker_width, height)
	if not GameState.is_stalled():
		_boost_button.text = _boost_label()


## Pulses the bar red while latched enemies are draining a boost.
func _pulse_drain(delta: float) -> void:
	var draining := GameState.get_latched_count() > 0 and GameState.get_click_boost() > 0.0 and not GameState.is_stalled()
	if not draining:
		_pulse_time = 0.0
		_boost_bar.self_modulate = Color.WHITE
		return
	_pulse_time += delta
	var t := 0.5 + 0.5 * sin(_pulse_time * drain_pulse_speed)
	_boost_bar.self_modulate = Color.WHITE.lerp(drain_tint, t)


func _make_saved_label() -> void:
	_saved_label = Label.new()
	_saved_label.name = "SavedLabel"
	_saved_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_saved_label.text = tr(saved_key)
	_saved_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_saved_label.modulate.a = 0.0
	$HUDRoot.add_child(_saved_label)
	_saved_label.add_theme_color_override(&"font_color", _saved_label.get_theme_color(&"body", &"Palette"))
	_saved_label.add_theme_color_override(&"font_outline_color", _saved_label.get_theme_color(&"ink", &"Palette"))
	_saved_label.add_theme_constant_override(&"outline_size", 6)
	_saved_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE, 20)


func _on_run_saved() -> void:
	if _saved_tween != null:
		_saved_tween.kill()
	_saved_label.modulate.a = 1.0
	_saved_tween = create_tween()
	_saved_tween.tween_interval(saved_show_seconds)
	_saved_tween.tween_property(_saved_label, "modulate:a", 0.0, 0.4)


## A shortcut for an Input Map action, so every key and button bound to it works.
func _make_shortcut(action: StringName) -> Shortcut:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	var shortcut := Shortcut.new()
	shortcut.events = [event]
	return shortcut