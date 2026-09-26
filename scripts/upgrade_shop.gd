class_name UpgradeShop
extends PanelContainer
## The shop (Phase 4 Step 5, layout A): tabs of compact rows, always in catalog
## order so rows never shift under the cursor.
## - Upgrades: one line per upgrade (name, short description, level
##   pips, a gold price button).
## - Mounts: one row per animal: icon (greyed while locked), name, how many you
##   own, its ★, level pips, then Buy · Sell · Up. Up buys the next step of the
##   mount's track (GDD v1.17: levels 1-3, the ★2 star-up, levels 4-6); it glows
##   when the star-up is next, and its tooltip says what the next step does.
## Visibility (GDD "Upgrade Visibility System", Phase 4 Step 6): a row stays
## hidden until you're one boss away from unlocking it, then shows locked with
## its requirement. Affordable gold buttons pulse; a thin bar under each shows
## Gold toward the price. The Upgrades tab has small section headers.
## Controller-ready: buttons take focus (a mouse click lets go of it, so Space
## stays Boost), LB/RB switch tabs, and an info line under the tabs shows what
## the focused or hovered button does (nothing is hover-only).
## Row states:
##   LOCKED      prerequisite, boss, ★2 count, or (mounts) no empty slot
##   SAVING      Gold below the next price
##   AFFORDABLE  buy button enabled
##   MAXED       every level bought

enum RowState { LOCKED, SAVING, AFFORDABLE, MAXED }

# Wording: translation keys in localization/strings.csv. Placeholders are {0}, {1}...
@export var cost_key: String = "SHOP_COST"
@export var requires_key: String = "SHOP_REQUIRES"
@export var maxed_key: String = "SHOP_MAXED"
@export var needs_slot_key: String = "SHOP_NEEDS_SLOT"
@export var needs_star2_key: String = "SHOP_NEEDS_STAR2_TYPES"
@export var beat_boss_key: String = "SHOP_BEAT_BOSS"
@export var sell_key: String = "SHOP_SELL"
@export var buy_key: String = "SHOP_BUY"
@export var up_key: String = "SHOP_UP"
@export var star_up_key: String = "SHOP_STAR_UP"
@export var count_key: String = "SHOP_COUNT"
## Up button tooltips: "{name} (level {n}): {what it does}" and "Star up: {what it does}".
@export var level_tip_key: String = "SHOP_LEVEL_TIP"
@export var star_tip_key: String = "SHOP_STAR_TIP"
## Tier bosses, to name the boss a gated row is waiting for.
@export var tier_catalog: TierCatalog = preload("res://resources/tiers/tier_catalog.tres")
## Section headers, in UpgradeData.Section order (NONE has none).
@export var section_keys: PackedStringArray = ["", "SHOP_SECTION_CAROUSEL", "SHOP_SECTION_BOOST", "SHOP_SECTION_CLICKS", "SHOP_SECTION_GOLD"]
## Info line: "{name}: {what it does} (level {n}/{max})" and a mount's "{name}: {count} owned".
@export var info_row_key: String = "SHOP_INFO_ROW"
@export var info_mount_key: String = "SHOP_INFO_MOUNT"
## Tab titles, in UpgradeData.Tab order.
@export var tab_title_keys: PackedStringArray = ["SHOP_TAB_UPGRADES", "SHOP_TAB_MOUNTS"]

@export_group("Look")
@export var locked_modulate: Color = Color(1.0, 1.0, 1.0, 0.55)
@export var maxed_modulate: Color = Color(1.0, 1.0, 1.0, 0.7)
@export var row_list_separation: int = 10
@export var mount_icon_size: float = 34.0
@export var pip_size: Vector2 = Vector2(8.0, 5.0)
@export var mount_pip_size: Vector2 = Vector2(14.0, 6.0)
@export var mount_button_font_size: int = 11
@export var mount_button_height: float = 28.0
## ★2 badge, pips after the star-up, and the star-up button's glow.
@export var star_color: Color = Color("ffd24a")
@export var star_button_text: Color = Color("3a2400")
@export var star_glow: Color = Color(1.0, 0.85, 0.3, 0.6)
## Affordable gold buttons pulse this much brighter, this fast.
@export var pulse_tint: Color = Color(1.25, 1.2, 1.05)
@export_range(0.5, 10.0, 0.5, "suffix:/s") var pulse_speed: float = 3.0
@export_range(1.0, 8.0, 1.0, "suffix:px") var fill_height: float = 3.0
## Space kept clear for the tab's scrollbar.
@export_range(0, 30, 1, "suffix:px") var scrollbar_gutter: int = 12
## Level pips before the star-up (LevelPips' own blue).
@export var level_pip_color: Color = Color("7aa2ff")

## Greys out a locked mount's icon (the mockup's "fully greyed when locked").
const GREY_SHADER := """shader_type canvas_item;
void fragment() {
	float v = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = vec3(v * 0.8 + 0.1);
}
"""

@onready var _tabs: TabContainer = %ShopTabs
@onready var _info: Label = %ShopInfo

## Rows by the upgrade id they show (a mount row by its BUY_MOUNT id).
var _rows_by_id: Dictionary[StringName, ShopRow] = {}
var _pages: Array[VBoxContainer] = []
## Gold changes on every kill and booth pass; the rows refresh at most once a frame.
var _refresh_queued: bool = false
var _grey_material: ShaderMaterial
var _star_style: StyleBoxFlat
## Section headers by UpgradeData.Section, and which rows sit under each.
var _headers: Dictionary[int, Label] = {}
var _section_rows: Dictionary[int, Array] = {}
## Gold buttons pulsing right now (affordable and visible).
var _pulsing: Array[Button] = []
var _pulse_time: float = 0.0
## The button the info line describes (focused, else last hovered).
var _info_button: Button


class ShopRow:
	var root: Control
	var status: Label
	var pips: LevelPips
	## Buys the upgrade (Buy for a mount).
	var button: Button
	var sell_button: TwoStepButton
	# Mount rows only.
	var track_id: StringName = &""
	var up_button: Button
	## Thin "Gold toward the price" bar under each gold button.
	var fills: Dictionary[Button, ProgressBar] = {}
	## What each button does, for the info line (kept current by _refresh).
	var info: Dictionary[Button, String] = {}
	var icon: TextureRect
	var count: Label
	var star: StarBadge


func _ready() -> void:
	_grey_material = ShaderMaterial.new()
	_grey_material.shader = Shader.new()
	_grey_material.shader.code = GREY_SHADER
	_star_style = StyleBoxFlat.new()
	_star_style.bg_color = star_color
	_star_style.set_corner_radius_all(4)
	_star_style.shadow_color = star_glow
	_star_style.shadow_size = 5
	for i in UpgradeData.Tab.size():
		# Each tab scrolls, so a long list never makes the shop taller than the
		# screen, which would push the whole HUD off it (Codex review, Step 6).
		var scroll := ScrollContainer.new()
		scroll.name = "Tab%d" % i
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.follow_focus = true  # a controller's focus scrolls the list
		var page := VBoxContainer.new()
		page.add_theme_constant_override("separation", row_list_separation)
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# A little room on the right, so the scrollbar never covers the buttons.
		var gutter := MarginContainer.new()
		gutter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gutter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gutter.add_theme_constant_override("margin_right", scrollbar_gutter)
		gutter.add_child(page)
		scroll.add_child(gutter)
		_tabs.add_child(scroll)
		# A key: the tab bar translates titles itself.
		_tabs.set_tab_title(i, tab_title_keys[i] if i < tab_title_keys.size() else str(i))
		_pages.append(page)
	_tabs.tab_changed.connect(func(_tab: int) -> void: AudioManager.play_sfx(&"tab"))
	_info.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_info.text = ""
	for upgrade in UpgradeManager.get_definitions():
		if upgrade.tab == UpgradeData.Tab.UPGRADES and upgrade.section != UpgradeData.Section.NONE \
				and not _headers.has(upgrade.section):
			_add_header(upgrade.section)
		match upgrade.effect_type:
			UpgradeData.EffectType.MOUNT_LEVEL:
				continue  # shown on its mount's row
			UpgradeData.EffectType.BUY_MOUNT:
				_rows_by_id[upgrade.id] = _build_mount_row(upgrade)
			_:
				_rows_by_id[upgrade.id] = _build_row(upgrade)
				if _headers.has(upgrade.section):
					_section_rows[upgrade.section].append(upgrade.id)
	GameState.gold_changed.connect(func(_b: float, _d: float) -> void: _queue_refresh())
	GameState.run_reset.connect(_refresh)
	GameState.mounts_changed.connect(func(_r: Array[StringName]) -> void: _refresh())
	UpgradeManager.upgrade_purchased.connect(func(_id: StringName) -> void: _refresh())
	UpgradeManager.upgrade_sold.connect(func(_id: StringName) -> void: _refresh())
	GameState.boss_beaten.connect(func(_rank: int, _first: bool) -> void: _refresh())
	GameState.debug_unlocks_changed.connect(_refresh)
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_refresh()


func _add_header(section: int) -> void:
	var header := _label(section_keys[section] if section < section_keys.size() else "", false, true)
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", get_theme_color(&"gold", &"Palette"))
	_pages[UpgradeData.Tab.UPGRADES].add_child(header)
	_headers[section] = header
	_section_rows[section] = []


## Hidden until one boss away from unlocking (maxed rows stay).
static func is_row_hidden(id: StringName) -> bool:
	var upgrade := UpgradeManager.get_definition(id)
	if upgrade == null or UpgradeManager.is_maxed(id):
		return false
	var needed := upgrade.get_bosses_needed(GameState.get_upgrade_level(id))
	return needed < 0 or needed > GameState.get_bosses_beaten() + 1


## The state a row should show right now.
static func get_row_state(id: StringName) -> RowState:
	if UpgradeManager.is_maxed(id):
		return RowState.MAXED
	if _locked_reason(id) != LockReason.NONE:
		return RowState.LOCKED
	return RowState.AFFORDABLE if UpgradeManager.can_purchase(id) else RowState.SAVING


enum LockReason { NONE, PREREQUISITE, BOSS, NO_SLOT, STAR2_TYPES }


static func _locked_reason(id: StringName) -> LockReason:
	var upgrade := UpgradeManager.get_definition(id)
	if upgrade.prerequisite_id != &"" and not UpgradeManager.is_purchased(upgrade.prerequisite_id):
		return LockReason.PREREQUISITE
	if GameState.is_boss_gated(upgrade):
		return LockReason.BOSS
	if GameState.get_star2_type_count(upgrade.id) < upgrade.required_star2_types:
		return LockReason.STAR2_TYPES
	if upgrade.effect_type == UpgradeData.EffectType.BUY_MOUNT and not GameState.has_free_mount_slot():
		return LockReason.NO_SLOT
	return LockReason.NONE


## The boss a boss-gated row is waiting for: the boss of tier (bosses needed - 1).
func _boss_name_for(upgrade: UpgradeData) -> String:
	var needed := upgrade.get_bosses_needed(GameState.get_upgrade_level(upgrade.id))
	var tier := tier_catalog.get_tier(needed - 1)
	if tier != null and tier.boss != null:
		return tr(ThemeManager.boss_name_key(tier.boss))
	return tr(tier.name_key) if tier != null else "?"


## Why a row is locked, in words ("" if it isn't).
func _lock_text(id: StringName) -> String:
	var upgrade := UpgradeManager.get_definition(id)
	match _locked_reason(id):
		LockReason.NO_SLOT:
			return tr(needs_slot_key)
		LockReason.BOSS:
			return tr(beat_boss_key).format([_boss_name_for(upgrade)])
		LockReason.STAR2_TYPES:
			return tr(needs_star2_key).format([GameState.get_star2_type_count(id), upgrade.required_star2_types])
		LockReason.PREREQUISITE:
			return tr(requires_key).format([tr(UpgradeManager.get_definition(upgrade.prerequisite_id).display_name)])
	return ""


# --- Building rows -----------------------------------------------------------------

## Carousel and Combat: name, short description, pips, status | price button.
func _build_row(upgrade: UpgradeData) -> ShopRow:
	var row := ShopRow.new()
	var line := HBoxContainer.new()
	line.name = String(upgrade.id)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 6)
	row.root = line
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_constant_override("separation", 2)
	# Keys: these labels translate themselves, including on a language change.
	text.add_child(_label(upgrade.display_name, true, true))  # long names wrap
	var description := _label(upgrade.description, true, true)
	_mute(description)
	text.add_child(description)
	row.pips = LevelPips.new()
	row.pips.pip_size = pip_size
	row.pips.max_level = upgrade.max_level
	row.pips.visible = upgrade.max_level > 1
	text.add_child(row.pips)
	row.status = _label("", true)
	_mute(row.status)
	text.add_child(row.status)
	row.button = _gold_button()
	row.button.custom_minimum_size = Vector2(70, 32)
	row.button.pressed.connect(UpgradeManager.purchase.bind(upgrade.id))
	line.add_child(text)
	line.add_child(_with_fill(row, row.button))
	_pages[upgrade.tab].add_child(line)
	return row


## Mounts: icon | name ×n ★ / pips or lock reason, then Buy · Sell · Up.
func _build_mount_row(upgrade: UpgradeData) -> ShopRow:
	var row := ShopRow.new()
	var column := VBoxContainer.new()
	column.name = String(upgrade.id)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 4)
	row.root = column
	var track := _track_for(upgrade.id)
	row.track_id = track.id if track != null else &""

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 8)
	row.icon = TextureRect.new()
	var data := _mount_data(upgrade)
	row.icon.texture = data.texture if data != null else null
	row.icon.custom_minimum_size = Vector2(mount_icon_size, mount_icon_size)
	row.icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	row.icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(row.icon)
	var info := VBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	var name_line := HBoxContainer.new()
	name_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Short and never trimmed: a trimmed label has no minimum width in a row.
	var name_label := _label(upgrade.display_name, false, true)
	name_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	name_line.add_child(name_label)
	row.count = _label("", false)
	row.count.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	name_line.add_child(row.count)
	row.star = StarBadge.new()
	row.star.color = star_color
	name_line.add_child(row.star)
	info.add_child(name_line)
	row.pips = LevelPips.new()
	row.pips.pip_size = mount_pip_size
	row.pips.max_level = UpgradeData.STAR_BUY
	info.add_child(row.pips)
	row.status = _label("", true)
	_mute(row.status)
	info.add_child(row.status)
	top.add_child(info)
	column.add_child(top)

	var buttons := HBoxContainer.new()
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buttons.add_theme_constant_override("separation", 4)
	row.button = _mount_button(_gold_button())
	row.button.pressed.connect(UpgradeManager.purchase.bind(upgrade.id))
	buttons.add_child(_with_fill(row, row.button))
	if upgrade.sell_refund_fraction > 0.0:
		# Selling loses half the price, so it asks once (Garret, memo R).
		row.sell_button = TwoStepButton.new()
		row.sell_button.theme_type_variation = &"BlueButton"
		_mount_button(row.sell_button)
		row.sell_button.confirmed.connect(UpgradeManager.sell.bind(upgrade.id))
		buttons.add_child(_with_fill(row, row.sell_button, false))
	if track != null:
		row.up_button = _mount_button(_gold_button())
		row.up_button.pressed.connect(UpgradeManager.purchase.bind(track.id))
		buttons.add_child(_with_fill(row, row.up_button))
	column.add_child(buttons)
	_pages[upgrade.tab].add_child(column)
	return row


## The MOUNT_LEVEL track for a mount type, if it has one.
func _track_for(mount_id: StringName) -> UpgradeData:
	for upgrade in UpgradeManager.get_definitions():
		if upgrade.effect_type == UpgradeData.EffectType.MOUNT_LEVEL and upgrade.target_mount == mount_id:
			return upgrade
	return null


## A mount's MountData, read from its scene without instancing it.
static func _mount_data(upgrade: UpgradeData) -> MountData:
	if upgrade.mount_scene == null:
		return null
	var state := upgrade.mount_scene.get_state()
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == &"data":
			return state.get_node_property_value(0, i) as MountData
	return null


func _gold_button() -> Button:
	var button := Button.new()
	button.theme_type_variation = &"BuyButton"  # spending Gold is always gold
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return button


## The button with a thin fill bar under it (`with_bar` false: an empty strip
## of the same height, so Sell lines up with Buy and Up). Also hooks the
## button up for focus and the info line.
func _with_fill(row: ShopRow, button: Button, with_bar: bool = true) -> Control:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	column.size_flags_horizontal = button.size_flags_horizontal
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.size_flags_horizontal = Control.SIZE_FILL
	column.add_child(button)
	var strip: Control
	if with_bar:
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = 1.0
		row.fills[button] = bar
		strip = bar
	else:
		strip = Control.new()
	strip.custom_minimum_size = Vector2(0, fill_height)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(strip)
	_hook(row, button)
	return column


## Focus for controllers (a mouse click lets go of it, so Space stays Boost),
## and the info line on focus or hover.
func _hook(row: ShopRow, button: Button) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.focus_entered.connect(_show_info.bind(row, button))
	button.mouse_entered.connect(_show_info.bind(row, button))
	button.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and not event.pressed:
			button.release_focus.call_deferred())


func _show_info(row: ShopRow, button: Button) -> void:
	_info_button = button
	_info.text = row.info.get(button, "")


## Buy, Sell and Up share the row equally, so the columns line up row to row.
func _mount_button(button: Button) -> Button:
	button.custom_minimum_size = Vector2(0, mount_button_height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", mount_button_font_size)
	return button


## `translates`: the text is a key the label translates itself. Otherwise the
## text arrives already translated and must not be translated again.
func _label(text: String, wraps: bool, translates: bool = false) -> Label:
	var label := Label.new()
	if not translates:
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wraps:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label


func _mute(label: Label) -> void:
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.6))


# --- Refreshing --------------------------------------------------------------------

## Language changed: rebuild the prices, status lines, and sell buttons.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and not _rows_by_id.is_empty():
		_refresh()


## A theme may rename the bosses that locked rows name.
func _on_theme_changed(_theme: ParkTheme) -> void:
	_queue_refresh()


func _queue_refresh() -> void:
	_refresh_queued = true


func _process(delta: float) -> void:
	if _refresh_queued:
		_refresh()
	_pulse_time += delta
	var glow := Color.WHITE.lerp(pulse_tint, 0.5 + 0.5 * sin(_pulse_time * pulse_speed))
	for button in _pulsing:
		button.self_modulate = glow if not button.disabled else Color.WHITE


## LB/RB switch tabs; the first D-pad press lands on the shop's first button.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"shop_prev_tab") or event.is_action_pressed(&"shop_next_tab"):
		var step := -1 if event.is_action_pressed(&"shop_prev_tab") else 1
		_tabs.current_tab = posmod(_tabs.current_tab + step, _tabs.get_tab_count())
		_focus_first_button()
		get_viewport().set_input_as_handled()
		return
	var joypad := event is InputEventJoypadButton or event is InputEventJoypadMotion
	if joypad and get_viewport().gui_get_focus_owner() == null:
		for action: StringName in [&"ui_up", &"ui_down", &"ui_left", &"ui_right"]:
			if event.is_action_pressed(action):
				_focus_first_button()
				get_viewport().set_input_as_handled()
				return


func _focus_first_button() -> void:
	for control in _pages[_tabs.current_tab].find_children("*", "Button", true, false):
		var button := control as Button
		if button.is_visible_in_tree() and button.focus_mode != Control.FOCUS_NONE:
			button.grab_focus()
			return


func _refresh() -> void:
	_refresh_queued = false
	_pulsing.clear()
	for id in _rows_by_id:
		var row := _rows_by_id[id]
		row.root.visible = not is_row_hidden(id)
		if row.icon != null:
			_refresh_mount_row(id, row)
		else:
			_refresh_row(id, row)
		if not row.root.visible:
			continue
		for button in row.fills:
			var bar := row.fills[button]
			var target := _price_target(row, button)
			var price := UpgradeManager.get_cost(target) if target != &"" else 0.0
			var saving := target != &"" and get_row_state(target) in [RowState.SAVING, RowState.AFFORDABLE]
			bar.modulate.a = 1.0 if saving else 0.0
			bar.value = clampf(GameState.get_gold() / price, 0.0, 1.0) if price > 0.0 else 1.0
			if not button.disabled and saving:
				_pulsing.append(button)
	for section in _headers:
		var any := false
		for id: StringName in _section_rows[section]:
			any = any or _rows_by_id[id].root.visible
		_headers[section].visible = any
	if _info_button != null and is_instance_valid(_info_button):
		for id in _rows_by_id:
			if _rows_by_id[id].info.has(_info_button):
				_info.text = _rows_by_id[id].info[_info_button]


## The upgrade a gold button buys (Up buys the mount's track).
func _price_target(row: ShopRow, button: Button) -> StringName:
	if button == row.up_button:
		return row.track_id
	for id in _rows_by_id:
		if _rows_by_id[id] == row:
			return id
	return &""


func _refresh_row(id: StringName, row: ShopRow) -> void:
	var state := get_row_state(id)
	row.pips.level = UpgradeManager.get_level(id)
	row.button.disabled = state != RowState.AFFORDABLE
	row.button.text = tr(maxed_key) if state == RowState.MAXED else tr(cost_key).format([NumberFormat.gold(UpgradeManager.get_cost(id))])
	row.status.visible = state == RowState.LOCKED
	row.status.text = _lock_text(id)
	row.root.modulate = locked_modulate if state == RowState.LOCKED else (maxed_modulate if state == RowState.MAXED else Color.WHITE)
	var upgrade := UpgradeManager.get_definition(id)
	var info := tr(info_row_key).format([tr(upgrade.display_name), tr(upgrade.description), UpgradeManager.get_level(id), upgrade.max_level])
	var lock := _lock_text(id)
	row.info[row.button] = info + ("\n" + lock if lock != "" else "")


func _refresh_mount_row(id: StringName, row: ShopRow) -> void:
	var state := get_row_state(id)
	var owned := GameState.get_mount_roster().count(id)
	# Locked for a real reason (a boss, the ★2 count): greyed until available.
	# A full carousel only disables Buy.
	var blocked := state == RowState.LOCKED and _locked_reason(id) != LockReason.NO_SLOT
	row.icon.material = _grey_material if blocked and owned == 0 else null
	row.root.modulate = locked_modulate if blocked and owned == 0 else Color.WHITE
	row.count.text = tr(count_key).format([owned])
	row.count.modulate.a = 0.6 if owned == 0 else 1.0
	row.status.visible = blocked
	row.status.text = _lock_text(id) if blocked else ""
	row.button.disabled = state != RowState.AFFORDABLE
	row.button.text = tr(maxed_key) if state == RowState.MAXED else tr(buy_key).format([NumberFormat.gold(UpgradeManager.get_cost(id))])
	var upgrade := UpgradeManager.get_definition(id)
	var lock := _lock_text(id)
	row.info[row.button] = tr(info_mount_key).format([tr(upgrade.display_name), owned]) + ("\n" + lock if lock != "" else "")
	if row.sell_button != null:
		row.sell_button.disabled = not UpgradeManager.can_sell(id)
		var refund := UpgradeManager.get_sell_refund(id)
		row.sell_button.set_idle_text(tr(sell_key).format([NumberFormat.gold(refund) if refund > 0.0 else ""]).strip_edges())
		row.info[row.sell_button] = tr(sell_key).format([NumberFormat.gold(refund)])
	var level := GameState.get_mount_level(id)
	var star := GameState.get_mount_star(id)
	row.star.stars = star
	row.pips.level = level - UpgradeData.STAR_BUY if star >= 2 else level
	row.pips.filled_color = star_color if star >= 2 else level_pip_color
	row.pips.visible = not blocked
	if row.up_button != null:
		_refresh_up_button(row)


## Up: the next level, or the glowing star-up, or Max. The tooltip says what it
## does (or why it's locked).
func _refresh_up_button(row: ShopRow) -> void:
	var track := UpgradeManager.get_definition(row.track_id)
	var state := get_row_state(row.track_id)
	var buys := GameState.get_upgrade_level(row.track_id)
	var price := NumberFormat.gold(UpgradeManager.get_cost(row.track_id))
	var star_next := buys == UpgradeData.STAR_BUY
	row.up_button.disabled = state != RowState.AFFORDABLE
	if state == RowState.MAXED:
		row.up_button.text = tr(maxed_key)
	elif star_next:
		row.up_button.text = tr(star_up_key).format([price])
	else:
		row.up_button.text = tr(up_key).format([price])
	var glow := star_next and state == RowState.AFFORDABLE
	for style_name: StringName in [&"normal", &"hover", &"pressed"]:
		if glow:
			row.up_button.add_theme_stylebox_override(style_name, _star_style)
		else:
			row.up_button.remove_theme_stylebox_override(style_name)
	if glow:
		row.up_button.add_theme_color_override(&"font_color", star_button_text)
		row.up_button.add_theme_color_override(&"font_hover_color", star_button_text)
	else:
		row.up_button.remove_theme_color_override(&"font_color")
		row.up_button.remove_theme_color_override(&"font_hover_color")
	var tip := ""
	if state != RowState.MAXED:
		if star_next:
			tip = tr(star_tip_key).format([tr(track.star_description)])
		else:
			var next_level := GameState.get_mount_level(track.target_mount) + 1
			tip = tr(level_tip_key).format([tr(track.display_name), next_level, tr(track.description)])
		var lock := _lock_text(row.track_id)
		if state == RowState.LOCKED and lock != "":
			tip += "\n" + lock
	row.info[row.up_button] = tip


## ★N, drawn in code (the UI font has no star glyph). Hidden below ★2.
class StarBadge extends Control:
	var color: Color = Color.GOLD
	var stars: int = 1:
		set(value):
			stars = value
			visible = value >= 2
			queue_redraw()

	func _init() -> void:
		custom_minimum_size = Vector2(26, 16)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = false

	func _draw() -> void:
		var center := Vector2(8, size.y / 2.0)
		var points := PackedVector2Array()
		for i in 10:
			var radius := 7.0 if i % 2 == 0 else 3.0
			points.append(center + Vector2.from_angle(-PI / 2.0 + i * PI / 5.0) * radius)
		draw_colored_polygon(points, color)
		draw_string(get_theme_default_font(), Vector2(16, center.y + 5), str(stars), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
