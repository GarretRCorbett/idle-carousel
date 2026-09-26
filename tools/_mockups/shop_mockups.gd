extends Node
## Developer-only renders for Phase 4 Step 4: compact shop layouts over the
## real game, with made-up mount levels and stars (not built yet). Writes PNGs
## to planning/phase4/mockups/. Text is English-only on purpose (not shipped).
##   "$GODOT" --path . --audio-driver Dummy tools/_mockups/ShopMockups.tscn

const OUT := "res://planning/phase4/mockups/"
const GAME_SCENE := "res://scenes/Game.tscn"
const STAR_COLOR := Color("ffd24a")
const PIP_LEVELS := 3

## Made-up mid-run state (two bosses beaten).
const MOUNTS: Array[Dictionary] = [
	{"id": "horse", "name": "Horse", "owned": 2, "star": 1, "level": 2, "buy": 590, "up": 300,
		"next": "Lv 3: +15% Gold per pass"},
	{"id": "wolf", "name": "Wolf", "owned": 2, "star": 2, "level": 1, "buy": 390, "up": 900,
		"next": "Lv 5: +0.5 damage per hit"},
	{"id": "giraffe", "name": "Giraffe", "owned": 1, "star": 1, "level": 3, "buy": 590, "star_up": 2600,
		"next": "Star up: hits harder"},
	{"id": "sloth", "name": "Sloth", "owned": 0, "star": 1, "level": 0, "buy": 590, "up": 250,
		"next": "Lv 1: longer slows"},
	{"id": "elephant", "name": "Elephant", "owned": 0, "star": 1, "level": 0, "buy": 3250,
		"locked": "Beat Boulder"},
	{"id": "panda", "name": "Panda", "owned": 0, "star": 1, "level": 0, "buy": 11700,
		"locked": "3 mounts at star 2"},
]

var _game: Game
var _columns: Control
var _shop: Control


func _ready() -> void:
	TranslationServer.set_locale("en")
	LocaleFonts.apply("en")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_game = (load(GAME_SCENE) as PackedScene).instantiate() as Game
	add_child(_game)
	await _frames(3)
	GameState.debug_set_bosses_beaten(2)
	GameState.add_gold(20000.0)
	for i in 4:
		UpgradeManager.purchase(&"mount_slot")
	for id: StringName in [&"horse", &"wolf", &"wolf", &"giraffe"]:
		UpgradeManager.purchase(id)
	await _frames(90)
	_columns = _game.get_node("HUD/HUDRoot/ScreenMargin/Columns")
	_shop = _columns.get_node("ShopPanel")
	_shop.visible = false
	for option: String in ["a", "b", "c"]:
		var panel := _build(option)
		_columns.add_child(panel)
		_columns.move_child(panel, _shop.get_index())
		await _frames(3)
		_capture("%s_mounts.png" % option)
		panel.queue_free()
		await _frames(1)
	var carousel := _panel(250, "Carousel", _carousel_page())
	_columns.add_child(carousel)
	_columns.move_child(carousel, _shop.get_index())
	await _frames(3)
	_capture("compact_carousel_tab.png")
	get_tree().quit()


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _capture(file: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT + file))
	print("wrote ", file)


func _build(option: String) -> Control:
	match option:
		"a":
			return _panel(270, "Mounts", _rows_page())
		"b":
			return _panel(290, "Mounts", _cards_page())
	return _panel(250, "Mounts", _list_page())


## The shop frame: panel, margin, three tabs with `selected` open.
func _panel(width: float, selected: String, page: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	panel.add_child(margin)
	var tabs := TabContainer.new()
	tabs.add_theme_font_size_override("font_size", 12)
	tabs.add_theme_constant_override("side_margin", 0)
	margin.add_child(tabs)
	for title: String in ["Carousel", "Combat", "Mounts"]:
		var holder: Control = page if title == selected else Control.new()
		holder.name = title
		tabs.add_child(holder)
	tabs.current_tab = ["Carousel", "Combat", "Mounts"].find(selected)
	return panel


# --- A: compact rows ---------------------------------------------------------------

func _rows_page() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	for m in MOUNTS:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 8)
		top.add_child(_icon(m, 34))
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 3)
		var name_line := HBoxContainer.new()
		name_line.add_child(_text(m["name"], 15))
		name_line.add_child(_count(m))
		name_line.add_child(_star_badge(m))
		info.add_child(name_line)
		info.add_child(_pips(m) if not m.has("locked") else _text(m["locked"], 11, true))
		top.add_child(info)
		row.add_child(top)
		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 4)
		buttons.add_child(_buy(m, "Buy %s" % _gold(m["buy"]), true))
		buttons.add_child(_button("Sell", "BlueButton", m["owned"] == 0 or m["id"] == "horse" and m["owned"] == 1))
		buttons.add_child(_upgrade_button(m, true))
		row.add_child(buttons)
		_dim_if_locked(row, m)
		page.add_child(row)
	return page


# --- B: cards ---------------------------------------------------------------------

func _cards_page() -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for m in MOUNTS:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.06)
		style.set_corner_radius_all(6)
		style.set_content_margin_all(6)
		if m.has("star_up"):
			style.border_color = STAR_COLOR
			style.set_border_width_all(2)
		card.add_theme_stylebox_override("panel", style)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 4)
		var head := HBoxContainer.new()
		head.alignment = BoxContainer.ALIGNMENT_CENTER
		head.add_child(_icon(m, 44))
		var side := VBoxContainer.new()
		side.add_child(_count(m))
		side.add_child(_star_badge(m))
		head.add_child(side)
		column.add_child(head)
		var name_label := _text(m["name"], 14)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(name_label)
		if m.has("locked"):
			var why := _text(m["locked"], 10, true)
			why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			why.autowrap_mode = TextServer.AUTOWRAP_WORD
			column.add_child(why)
		else:
			var pips := _pips(m)
			pips.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			column.add_child(pips)
		column.add_child(_buy(m, "Buy %s" % _gold(m["buy"]), false))
		column.add_child(_upgrade_button(m, false))
		var sell := _button("Sell", "BlueButton", m["owned"] == 0)
		sell.custom_minimum_size.y = 22
		sell.add_theme_font_size_override("font_size", 10)
		column.add_child(sell)
		card.add_child(column)
		_dim_if_locked(card, m)
		grid.add_child(card)
	return grid


# --- C: one line per mount + a details box ------------------------------------------

func _list_page() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 4)
	for m in MOUNTS:
		var row := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.12) if m["id"] == "giraffe" else Color(0, 0, 0, 0)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(3)
		row.add_theme_stylebox_override("panel", style)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		line.add_child(_icon(m, 26))
		var name_label := _text(m["name"], 13)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_label)
		line.add_child(_count(m))
		line.add_child(_star_badge(m))
		line.add_child(_buy(m, _gold(m["buy"]), true))
		row.add_child(line)
		_dim_if_locked(row, m)
		page.add_child(row)
	page.add_child(HSeparator.new())
	# Details of the selected mount (the Giraffe).
	var m: Dictionary = MOUNTS[2]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(_icon(m, 44))
	var info := VBoxContainer.new()
	var title := HBoxContainer.new()
	title.add_child(_text(m["name"], 16))
	title.add_child(_count(m))
	title.add_child(_star_badge(m))
	info.add_child(title)
	info.add_child(_pips(m))
	head.add_child(info)
	page.add_child(head)
	var next := _text("Reach the far field. " + String(m["next"]) + ".", 11, true)
	next.autowrap_mode = TextServer.AUTOWRAP_WORD
	page.add_child(next)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	buttons.add_child(_upgrade_button(m, true))
	buttons.add_child(_button("Sell 295", "BlueButton", false))
	page.add_child(buttons)
	return page


# --- Other tabs, compact (all options) ------------------------------------------------

func _carousel_page() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	var rows := [["Carousel Speed", 4, 10, "+20% base speed", 330], ["Boost Power", 2, 10, "+10% max boost", 360],
			["Auto-Boost", 1, 4, "Holds the bar higher", 1200], ["Ticket Booth", 2, 4, "Another booth", 3510]]
	for r: Array in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 2)
		info.add_child(_text(r[0], 14))
		info.add_child(_text(r[3], 11, true))
		var pips := LevelPips.new()
		pips.pip_size = Vector2(8, 5)
		pips.max_level = r[2]
		pips.level = r[1]
		info.add_child(pips)
		line.add_child(info)
		var button := _button(_gold(r[4]), "BuyButton", false)
		button.custom_minimum_size = Vector2(70, 32)
		line.add_child(button)
		page.add_child(line)
	return page


# --- Pieces -----------------------------------------------------------------------

func _icon(m: Dictionary, size: float) -> TextureRect:
	var texture: Texture2D = load("res://assets/sprites/mounts/%s.png" % m["id"])
	if m.has("locked"):
		var image := texture.get_image()
		image.decompress()
		image.convert(Image.FORMAT_RGBA8)
		for y in image.get_height():
			for x in image.get_width():
				var c := image.get_pixel(x, y)
				var v := c.get_luminance() * 0.8 + 0.1
				image.set_pixel(x, y, Color(v, v, v, c.a))
		texture = ImageTexture.create_from_image(image)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect


func _text(value: String, size: int, muted: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	if muted:
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	return label


func _count(m: Dictionary) -> Label:
	var label := _text(" ×%d" % m["owned"], 13, m["owned"] == 0)
	return label


## ★N drawn in code (the UI font has no star glyph).
func _star_badge(m: Dictionary) -> Control:
	var badge := StarBadge.new()
	badge.stars = m["star"]
	badge.color = STAR_COLOR
	return badge


func _pips(m: Dictionary) -> LevelPips:
	var pips := LevelPips.new()
	pips.pip_size = Vector2(14, 6)
	pips.max_level = PIP_LEVELS
	pips.level = m["level"]
	if m["star"] >= 2:
		pips.filled_color = STAR_COLOR
	return pips


func _buy(m: Dictionary, label: String, compact: bool) -> Button:
	var button := _button(label, "BuyButton", m.has("locked") or m["buy"] > 3000)
	if compact:
		button.custom_minimum_size = Vector2(0, 28)
		button.add_theme_font_size_override("font_size", 11)
	return button


func _upgrade_button(m: Dictionary, compact: bool) -> Button:
	var button: Button
	if m.has("star_up"):
		button = _button("Star up %s" % _gold(m["star_up"]), "BuyButton", false)
		button.add_theme_color_override("font_color", Color("3a2400"))
		var glow := StyleBoxFlat.new()
		glow.bg_color = STAR_COLOR
		glow.set_corner_radius_all(4)
		glow.shadow_color = Color(1.0, 0.85, 0.3, 0.6)
		glow.shadow_size = 5
		button.add_theme_stylebox_override("normal", glow)
	elif m.has("up"):
		button = _button("Up %s" % _gold(m["up"]), "BuyButton", m["owned"] == 0)
	else:
		button = _button("Up", "BuyButton", true)
	if compact:
		button.custom_minimum_size = Vector2(0, 28)
		button.add_theme_font_size_override("font_size", 11)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


func _button(label: String, variation: StringName, disabled: bool) -> Button:
	var button := Button.new()
	button.text = label
	button.theme_type_variation = variation
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 12)
	button.custom_minimum_size = Vector2(0, 30)
	return button


func _dim_if_locked(control: CanvasItem, m: Dictionary) -> void:
	if m.has("locked"):
		control.modulate = Color(1, 1, 1, 0.6)


func _gold(value: int) -> String:
	return NumberFormat.gold(value)


class StarBadge extends Control:
	var stars: int = 1
	var color: Color = Color.GOLD

	func _init() -> void:
		custom_minimum_size = Vector2(26, 16)

	func _draw() -> void:
		if stars < 2:
			return
		var center := Vector2(8, 8)
		var points := PackedVector2Array()
		for i in 10:
			var r := 7.0 if i % 2 == 0 else 3.0
			points.append(center + Vector2.from_angle(-PI / 2.0 + i * PI / 5.0) * r)
		draw_colored_polygon(points, color)
		draw_string(get_theme_default_font(), Vector2(16, 13), str(stars), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
