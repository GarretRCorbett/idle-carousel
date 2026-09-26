class_name ParkGuide
extends HBoxContainer
## The Park Guide (Phase 4 Step 8): a "Guide" tab in the pause menu, a
## Hades-style almanac of everything in the park. A list on the left, grouped
## under small gold headers; the chosen entry on the right: its picture, name,
## a short text and live stats. An entry not met yet shows a silhouette and
## "???". Built in code from GuideCatalog, so new data gets a page for free.
##
## Controller-ready (CLAUDE.md): the list is focusable buttons, up/down moves,
## and the page follows focus. A mouse click picks an entry and lets go of focus.

## Group headers, in GuideEntry.Group order.
@export var group_keys: PackedStringArray = [
	"GUIDE_GROUP_MOUNTS", "GUIDE_GROUP_ENEMIES", "GUIDE_GROUP_BOSSES", "GUIDE_GROUP_EVENTS",
]
## Shown for an entry's name until it's met.
@export var unknown_key: String = "GUIDE_UNKNOWN"
@export_group("Stat lines")
@export var owned_key: String = "GUIDE_MOUNT_OWNED"
@export var level_track_key: String = "GUIDE_MOUNT_LEVELS"
@export var star_key: String = "SHOP_STAR_TIP"
@export var tier_stats_key: String = "GUIDE_TIER_STATS"
@export var boss_tier_key: String = "GUIDE_BOSS_TIER"
@export var boss_time_key: String = "GUIDE_BOSS_TIME"
@export var boss_reward_key: String = "GUIDE_BOSS_REWARD"
@export var beaten_key: String = "BOSS_BEATEN"
@export var event_duration_key: String = "GUIDE_EVENT_DURATION"
@export_group("Look")
@export var list_width: float = 190.0
@export var page_size: Vector2 = Vector2(400.0, 340.0)
@export var icon_size: float = 72.0
@export_range(8, 32, 1) var header_font_size: int = 11
@export_range(8, 32, 1) var entry_font_size: int = 13
@export_range(8, 48, 1) var title_font_size: int = 20
@export_range(8, 32, 1) var text_font_size: int = 13
## Unmet entries in the list.
@export var unknown_modulate: Color = Color(1.0, 1.0, 1.0, 0.55)
## The chosen entry's button.
@export var selected_modulate: Color = Color(1.25, 1.2, 1.05)
## Live stats under the text.
@export var stats_color: Color = Color(0.48, 0.64, 1.0, 1.0)

var _tiers: TierCatalog
var _events: Array[EventData] = []
var _entries: Array[GuideEntry] = []
var _buttons: Array[Button] = []
var _selected: int = 0
var _list: VBoxContainer
var _icon: GuideIcon
var _title: Label
var _body: Label
var _stats: Label


## Game passes its tier catalog and event list (the same data play uses).
func _init(tiers: TierCatalog = null, events: Array[EventData] = []) -> void:
	_tiers = tiers
	_events = events
	name = "Guide"
	add_theme_constant_override(&"separation", 16)
	# Text is built here, already translated.
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED


func _ready() -> void:
	if _tiers != null:
		_entries = GuideCatalog.build(_tiers, _events)
	_build_list()
	_build_page()
	visibility_changed.connect(_on_visibility_changed)
	SaveManager.discovered.connect(_on_discovered)
	ThemeManager.theme_changed.connect(_on_theme_changed)
	refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		refresh()


func get_entries() -> Array[GuideEntry]:
	return _entries


func get_entry_buttons() -> Array[Button]:
	return _buttons


func get_selected() -> int:
	return _selected


## What the page shows now (tests read these).
func get_page_title() -> String:
	return _title.text


func get_page_body() -> String:
	return _body.text


func get_page_stats() -> String:
	return _stats.text


## Shows entry `index` on the right.
func select(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	_selected = index
	for i in _buttons.size():
		_buttons[i].self_modulate = selected_modulate if i == index else Color.WHITE
	_show_page()


## Rewrites every name and the page (discoveries and live stats change while
## you play; the Guide is only looked at while paused, so this is cheap).
func refresh() -> void:
	for i in _entries.size():
		var entry := _entries[i]
		var known := entry.is_discovered()
		_buttons[i].text = tr(entry.get_title_key()) if known else tr(unknown_key)
		_buttons[i].modulate = Color.WHITE if known else unknown_modulate
	select(_selected)


func _build_list() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "ListScroll"
	scroll.custom_minimum_size = Vector2(list_width, page_size.y)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true  # a controller's focus scrolls the list
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override(&"separation", 2)
	scroll.add_child(_list)
	var group := -1
	for i in _entries.size():
		var entry := _entries[i]
		if entry.group != group:
			group = entry.group
			_add_header(group)
		_add_button(i)


func _add_header(group: int) -> void:
	var header := Label.new()
	header.text = group_keys[group] if group < group_keys.size() else ""
	# A plain key: let Godot translate it (the Guide itself doesn't).
	header.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_ALWAYS
	header.add_theme_font_size_override(&"font_size", header_font_size)
	header.add_theme_color_override(&"font_color", get_theme_color(&"gold", &"Palette"))
	_list.add_child(header)


func _add_button(index: int) -> void:
	var button := Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.clip_text = true
	button.add_theme_font_size_override(&"font_size", entry_font_size)
	button.focus_entered.connect(select.bind(index))
	button.pressed.connect(select.bind(index))
	button.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and not event.pressed:
			button.release_focus.call_deferred())
	_list.add_child(button)
	_buttons.append(button)


func _build_page() -> void:
	var page := VBoxContainer.new()
	page.name = "Page"
	page.custom_minimum_size = page_size
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override(&"separation", 10)
	add_child(page)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 14)
	page.add_child(top)
	_icon = GuideIcon.new()
	_icon.custom_minimum_size = Vector2(icon_size, icon_size)
	top.add_child(_icon)
	_title = _label(title_font_size)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_title)
	_body = _label(text_font_size)
	page.add_child(_body)
	_stats = _label(text_font_size)
	_stats.add_theme_color_override(&"font_color", stats_color)
	page.add_child(_stats)


func _label(font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", font_size)
	return label


func _show_page() -> void:
	if _entries.is_empty():
		return
	var entry := _entries[_selected]
	_icon.entry = entry
	if not entry.is_discovered():
		_title.text = tr(unknown_key)
		_body.text = ""
		_stats.text = ""
		return
	_title.text = tr(entry.get_title_key())
	_body.text = tr(entry.body_key)
	_stats.text = "\n".join(_stat_lines(entry))


## Live numbers under the text: straight from the data and this run.
func _stat_lines(entry: GuideEntry) -> PackedStringArray:
	var lines := PackedStringArray()
	match entry.kind:
		GuideEntry.Kind.MOUNT:
			var owned := GameState.get_mount_roster().count(entry.id)
			lines.append(tr(owned_key).format([owned, GameState.get_mount_level(entry.id),
					GameState.get_mount_star(entry.id)]))
			if entry.level_upgrade != null:
				lines.append(tr(level_track_key).format([tr(entry.level_upgrade.display_name),
						tr(entry.level_upgrade.description)]))
				if entry.level_upgrade.star_description != "":
					lines.append(tr(star_key).format([tr(entry.level_upgrade.star_description)]))
		GuideEntry.Kind.TIER:
			var tier := entry.data as TierData
			lines.append(tr(tier_stats_key).format([NumberFormat.decimal(tier.health_multiplier, 2),
					NumberFormat.decimal(tier.speed_multiplier, 2), NumberFormat.decimal(tier.drag_multiplier, 2),
					NumberFormat.decimal(tier.gold_multiplier, 2)]))
		GuideEntry.Kind.BOSS:
			var boss := entry.data as BossData
			if entry.tier != null:
				lines.append(tr(boss_tier_key).format([tr(entry.tier.name_key)]))
			lines.append(tr(boss_time_key).format([int(boss.time_limit_seconds)]))
			lines.append(tr(boss_reward_key).format([NumberFormat.gold(boss.first_clear_gold),
					NumberFormat.gold(boss.repeat_clear_gold)]))
			if entry.tier != null and GameState.is_boss_beaten(entry.tier.rank):
				lines.append(tr(beaten_key))
		GuideEntry.Kind.EVENT:
			var event := entry.data as EventData
			if event.duration > 0.0:
				lines.append(tr(event_duration_key).format([int(event.duration)]))
	return lines


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		return
	refresh()
	if ControllerInput.using_controller and not _buttons.is_empty():
		_buttons[_selected].grab_focus.call_deferred()


func _on_discovered(_id: String) -> void:
	if is_visible_in_tree():
		refresh()


func _on_theme_changed(_theme: ParkTheme) -> void:
	refresh()
