class_name Hud
extends CanvasLayer
## Shows GameState values. Listens to signals; gameplay never references the HUD.

# TODO(Garret): text. Formats hold only numbers until you write the real labels.
@export var gold_format: String = "%d"
@export var gold_per_second_format: String = "%.1f"

@onready var _gold_label: Label = %GoldLabel
@onready var _gold_per_sec_label: Label = %GoldPerSecLabel
@onready var _health_bar: ProgressBar = %HealthBar


func _ready() -> void:
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.health_changed.connect(_on_health_changed)
	# Read the current values in case they were announced before we connected.
	_on_gold_changed(GameState.get_gold(), 0.0)
	_on_health_changed(GameState.get_health(), GameState.get_max_health())
	_gold_per_sec_label.text = gold_per_second_format % 0.0  # real value arrives in Step 4


func _on_gold_changed(balance: float, _delta: float) -> void:
	_gold_label.text = gold_format % floorf(balance)


func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
