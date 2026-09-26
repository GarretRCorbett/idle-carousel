class_name EventChips
extends VBoxContainer
## Under the boss strip: a banner when an event happens, and one chip per
## running event with its seconds left (GDD "Random Events"). Game gives it
## the EventDirector; it only listens and reads.

@export var chip_key: String = "EVENT_CHIP"
@export_range(0.5, 10.0, 0.5, "suffix:s") var banner_seconds: float = 2.5
@export var chip_color: Color = Color(0.16, 0.12, 0.24, 0.9)

var _director: EventDirector
var _banner: Label
var _row: HBoxContainer
var _chips: Dictionary[StringName, Label] = {}
var _banner_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_BEGIN
	_banner = Label.new()
	_banner.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_theme_font_size_override(&"font_size", 18)
	_banner.add_theme_color_override(&"font_color", get_theme_color(&"gold", &"Palette"))
	_banner.add_theme_color_override(&"font_outline_color", get_theme_color(&"ink", &"Palette"))
	_banner.add_theme_constant_override(&"outline_size", 6)
	_banner.modulate.a = 0.0
	add_child(_banner)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override(&"separation", 6)
	add_child(_row)


func setup(director: EventDirector) -> void:
	_director = director
	director.event_started.connect(_on_event_started)
	director.event_ended.connect(_on_event_ended)


func _process(_delta: float) -> void:
	if _director == null:
		return
	for id in _chips:
		_chips[id].text = tr(chip_key).format([tr(_director.get_event(id).name_key), ceili(_director.get_time_left(id))])


func _on_event_started(event: EventData, amount: float) -> void:
	if event.banner_key != "":
		_show_banner(tr(event.banner_key).format([NumberFormat.gold(amount)]))
	if event.duration > 0.0 and not _chips.has(event.id):
		var chip := Label.new()
		chip.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_font_size_override(&"font_size", 12)
		chip.add_theme_color_override(&"font_color", event.color)
		var style := StyleBoxFlat.new()
		style.bg_color = chip_color
		style.set_corner_radius_all(8)
		style.set_content_margin_all(5)
		style.content_margin_left = 10
		style.content_margin_right = 10
		chip.add_theme_stylebox_override(&"normal", style)
		_row.add_child(chip)
		_chips[event.id] = chip
	_process(0.0)


func _on_event_ended(event: EventData) -> void:
	if _chips.has(event.id):
		_chips[event.id].queue_free()
		_chips.erase(event.id)


func _show_banner(text: String) -> void:
	_banner.text = text
	if _banner_tween != null:
		_banner_tween.kill()
	_banner.modulate.a = 1.0
	_banner_tween = create_tween()
	_banner_tween.tween_interval(banner_seconds)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.5)
