class_name WelcomeBack
extends Control
## "Welcome back" after the game was closed: how long you were away and the
## Gold the carousel earned meanwhile (GDD "Offline Progress"). Game shows it
## on Continue; it pauses play until you collect.

signal collected

@export var away_key: String = "WELCOME_BACK_AWAY"
@export var gold_key: String = "WELCOME_BACK_GOLD"
@export var cap_key: String = "WELCOME_BACK_CAP"
@export var hours_minutes_key: String = "DURATION_HOURS_MINUTES"
@export var minutes_key: String = "DURATION_MINUTES"

@onready var _away_label: Label = %AwayLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _cap_label: Label = %CapLabel
@onready var _collect_button: Button = %CollectButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	for label: Label in [_away_label, _gold_label, _cap_label]:
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_gold_label.add_theme_color_override(&"font_color", get_theme_color(&"gold", &"Palette"))
	_collect_button.pressed.connect(_on_collect_pressed)


## `seconds_away` is the real time away; `capped` = more than the counted maximum.
func open(seconds_away: float, gold: float, capped: bool, max_hours: float) -> void:
	_away_label.text = tr(away_key).format([format_duration(seconds_away)])
	_gold_label.text = tr(gold_key).format([NumberFormat.gold(gold)])
	_cap_label.text = tr(cap_key).format([NumberFormat.decimal(max_hours, 0)])
	_cap_label.visible = capped
	show()
	get_tree().paused = true
	_collect_button.grab_focus.call_deferred()


## "2 h 05 min" or "7 min". Numbered placeholders, so each language orders them.
func format_duration(seconds: float) -> String:
	var minutes := floori(maxf(0.0, seconds) / 60.0)
	if minutes < 60:
		return tr(minutes_key).format([minutes])
	return tr(hours_minutes_key).format([minutes / 60, "%02d" % (minutes % 60)])


func _on_collect_pressed() -> void:
	AudioManager.play_sfx(&"coin")
	hide()
	get_tree().paused = false
	collected.emit()
