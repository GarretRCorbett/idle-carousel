class_name Hud
extends CanvasLayer
## Shows GameState values and owns the Boost button. Listens to signals and
## asks for actions through its own signals; gameplay never references the HUD.

## Pressed the Boost button (or its keyboard shortcut). Game decides what happens.
signal boost_requested

# Label wording (Garret's text).
@export var gold_format: String = "Gold: %d"
@export var gold_per_second_format: String = "Gold per sec: %.1f"
@export var speed_format: String = "Speed: ×%.2f"
## Keyboard shortcut for the Boost button.
@export var boost_key: Key = KEY_SPACE

@onready var _gold_label: Label = %GoldLabel
@onready var _gold_per_sec_label: Label = %GoldPerSecLabel
@onready var _speed_label: Label = %SpeedLabel
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _boost_bar: ProgressBar = %BoostBar
@onready var _boost_button: Button = %BoostButton


func _ready() -> void:
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.health_changed.connect(_on_health_changed)
	GameState.gold_per_second_changed.connect(_on_gold_per_second_changed)
	GameState.spin_speed_changed.connect(_on_spin_speed_changed)
	_boost_button.pressed.connect(boost_requested.emit)
	_boost_button.shortcut = _make_shortcut(boost_key)
	# Read the current values in case they were announced before we connected.
	_on_gold_changed(GameState.get_gold(), 0.0)
	_on_health_changed(GameState.get_health(), GameState.get_max_health())
	_on_gold_per_second_changed(GameState.get_recent_gold_per_second())
	_on_spin_speed_changed(GameState.get_effective_spin_speed_rad_s())


func _on_gold_changed(balance: float, _delta: float) -> void:
	_gold_label.text = gold_format % floorf(balance)


func _on_gold_per_second_changed(value: float) -> void:
	_gold_per_sec_label.text = gold_per_second_format % value


## Fires every tick while the boost fades, so the bar drains smoothly.
func _on_spin_speed_changed(_speed_rad_s: float) -> void:
	_speed_label.text = speed_format % GameState.get_speed_multiplier()
	_boost_bar.value = GameState.get_click_boost_fraction()


func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current


func _make_shortcut(key: Key) -> Shortcut:
	var event := InputEventKey.new()
	event.keycode = key
	var shortcut := Shortcut.new()
	shortcut.events = [event]
	return shortcut
