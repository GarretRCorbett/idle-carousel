class_name GoldPop
extends Node2D
## A "+X" Gold number that rises and fades where income was earned (booths,
## the Panda), so income is visible (GDD v1.17). Game spawns it in world space
## and it frees itself when done. Uses the shared UI theme, so its font follows
## the language like the HUD's.

@export var text_key: String = "POP_GOLD"
@export_range(1.0, 128.0, 1.0, "suffix:px") var rise: float = 26.0
@export_range(0.1, 5.0, 0.05, "suffix:s") var duration: float = 0.9
## Fraction of the duration spent fully visible before fading.
@export_range(0.0, 1.0, 0.05) var hold_fraction: float = 0.4
@export_range(6, 64, 1) var font_size: int = 17
## Brighter than the HUD's gold, so it reads over the busy park.
@export var color: Color = Color(1.0, 0.84, 0.22)
@export_range(0, 16, 1) var outline_size: int = 7
@export var outline_color: Color = Color(0.16, 0.09, 0.03, 1.0)

var amount: float = 0.0
var _age: float = 0.0
var _label: Label


func _ready() -> void:
	_label = Label.new()
	_label.theme = load(LocaleFonts.THEME_PATH) as Theme
	_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_label.text = tr(text_key).format([NumberFormat.gold(amount)])
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override(&"font_size", font_size)
	_label.add_theme_color_override(&"font_color", color)
	_label.add_theme_color_override(&"font_outline_color", outline_color)
	_label.add_theme_constant_override(&"outline_size", outline_size)
	add_child(_label)
	_label.reset_size()
	_place_label()


func _process(delta: float) -> void:
	_age += delta
	if _age >= duration:
		queue_free()
		return
	_place_label()


## Centered on the pop's point, rising; fades after the hold.
func _place_label() -> void:
	var t := clampf(_age / duration, 0.0, 1.0)
	_label.position = Vector2(-_label.size.x / 2.0, -_label.size.y / 2.0 - rise * t)
	var fade := clampf((t - hold_fraction) / maxf(0.001, 1.0 - hold_fraction), 0.0, 1.0)
	_label.modulate.a = 1.0 - fade
