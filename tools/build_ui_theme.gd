extends SceneTree
## Builds res://assets/ui/game_theme.tres, the HUD and menu look, from Kenney
## UI Pack sprites, Kenney Future Narrow, and palette A "Gilded Garden"
## (planning/phase3/codex_memo_t_palette.md). Every color and
## margin is here in one readable place. Re-run after changing it:
##   "$GODOT" --headless --path . -s res://tools/build_ui_theme.gd
## (Or edit game_theme.tres in the Inspector; re-running overwrites those edits.)

const OUT := "res://assets/ui/game_theme.tres"
## Kenney Future with Rubik behind it for letters Kenney lacks (Polish/Turkish
## accents, Cyrillic). CJK will swap the whole font per language later.
const UI_FONT_OUT := "res://assets/fonts/ui_font.tres"
const TITLE_FONT_OUT := "res://assets/fonts/title_font.tres"
## Rubik weight to sit next to Kenney Future's heavy strokes.
const FALLBACK_WEIGHT := 600

# GDD palette plus UI neutrals.
const CREAM := Color("fff4dc")     # ivory text
const INK := Color("243955")           # ink blue: dark text on gold buttons
const PANEL := Color("243955f0")
const PANEL_BORDER := Color("ddb96a")  # gold trim
const TRACK := Color("182840")
const GOLD := Color("ddb96a")
const HEALTH := Color("79c9ae")
const MUTED := Color("c0cad7")
const TAB_IDLE := Color("405d83")
const TAB_HOVER := Color("52709a")
## Price text on a disabled (grey) button: dark enough to read on light grey.
const DISABLED_TEXT := Color("4a5a70")
## Kenney's blue buttons are sky-cyan; this tint makes them royal blue.
const ROYAL_TINT := Color(0.55, 0.52, 1.0)


func _initialize() -> void:
	var fallback := FontVariation.new()
	fallback.base_font = load("res://assets/fonts/rubik_variable.ttf")
	fallback.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): FALLBACK_WEIGHT}
	var ui_font := FontVariation.new()
	ui_font.base_font = load("res://assets/fonts/kenney_future_narrow.ttf")
	ui_font.fallbacks = [fallback]
	ResourceSaver.save(ui_font, UI_FONT_OUT)
	var title_font := FontVariation.new()
	title_font.base_font = load("res://assets/fonts/kenney_future.ttf")
	title_font.fallbacks = [fallback]
	ResourceSaver.save(title_font, TITLE_FONT_OUT)
	# Whole-UI fonts for languages Kenney Future can't write (see LocaleFonts).
	var cyrillic := fallback.duplicate() as FontVariation
	cyrillic.fallbacks = [ui_font]
	ResourceSaver.save(cyrillic, "res://assets/fonts/ui_font_cyrillic.tres")
	for lang in ["zh", "ja", "ko"]:
		var cjk := FontVariation.new()
		var file_code: String = {"zh": "sc", "ja": "jp", "ko": "kr"}[lang]
		cjk.base_font = load("res://assets/fonts/noto_sans_%s_subset.ttf" % file_code)
		cjk.fallbacks = [ui_font]
		ResourceSaver.save(cjk, "res://assets/fonts/ui_font_%s.tres" % lang)
	# The language list shows every language in its own script at once, whatever
	# the UI language is, so it needs every font in one chain.
	var language_list := FontVariation.new()
	language_list.base_font = load("res://assets/fonts/kenney_future_narrow.ttf")
	language_list.fallbacks = [fallback]
	for file_code in ["sc", "jp", "kr"]:
		language_list.fallbacks.append(load("res://assets/fonts/noto_sans_%s_subset.ttf" % file_code))
	ResourceSaver.save(language_list, "res://assets/fonts/language_list_font.tres")

	var theme := Theme.new()
	theme.default_font = load(UI_FONT_OUT)
	theme.default_font_size = 15

	theme.set_color("font_color", "Label", CREAM)

	# Every button is royal blue with ivory text (Garret: the Send wave blue
	# for Play, Boost, Challenge and buying too, instead of yellow).
	_blue_button(theme, "Button")
	# The Boost button while stalled ("Crank!").
	theme.set_type_variation("CrankButton", "Button")
	_button(theme, "CrankButton", "button_red", "button_red", "button_red")
	theme.set_color("font_color", "CrankButton", CREAM)
	theme.set_color("font_hover_color", "CrankButton", CREAM)
	theme.set_color("font_pressed_color", "CrankButton", CREAM)
	theme.set_color("font_focus_color", "CrankButton", CREAM)
	theme.set_color("font_hover_pressed_color", "CrankButton", CREAM)
	# Kept so scenes that name it still work; it now matches the default.
	theme.set_type_variation("BlueButton", "Button")
	_blue_button(theme, "BlueButton")

	# Toggles (Auto waves, Fullscreen): plain text plus the switch, not a button.
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var empty := StyleBoxEmpty.new()
		empty.content_margin_top = 4.0
		empty.content_margin_bottom = 4.0
		theme.set_stylebox(state, "CheckButton", empty)
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(color, "CheckButton", CREAM)

	var panel := _flat(PANEL, 12)
	panel.border_color = PANEL_BORDER
	panel.set_border_width_all(2)
	theme.set_stylebox("panel", "PanelContainer", panel)

	theme.set_stylebox("background", "ProgressBar", _flat(TRACK, 4))
	theme.set_stylebox("fill", "ProgressBar", _flat(GOLD, 4))
	theme.set_type_variation("HealthBar", "ProgressBar")
	theme.set_stylebox("fill", "HealthBar", _flat(HEALTH, 4))

	var selected := _flat(CREAM, 8)
	selected.corner_radius_bottom_left = 0
	selected.corner_radius_bottom_right = 0
	_pad(selected, 10, 4)
	var idle := selected.duplicate() as StyleBoxFlat
	idle.bg_color = TAB_IDLE
	var hover := selected.duplicate() as StyleBoxFlat
	hover.bg_color = TAB_HOVER
	theme.set_stylebox("tab_selected", "TabContainer", selected)
	theme.set_stylebox("tab_unselected", "TabContainer", idle)
	theme.set_stylebox("tab_hovered", "TabContainer", hover)
	var tab_panel := StyleBoxEmpty.new()
	tab_panel.content_margin_top = 10
	theme.set_stylebox("panel", "TabContainer", tab_panel)
	theme.set_color("font_selected_color", "TabContainer", INK)
	theme.set_color("font_unselected_color", "TabContainer", MUTED)
	theme.set_color("font_hovered_color", "TabContainer", CREAM)

	var track := _flat(TRACK, 4)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", _flat(GOLD, 4))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _flat(GOLD, 4))

	var err := ResourceSaver.save(theme, OUT)
	print("Saved %s (%s)" % [OUT, error_string(err)])
	quit(0 if err == OK else 1)


## Kenney buttons: 9-sliced, with a 4 px "depth" lip at the bottom that
## disappears when pressed, so the label shifts down to look pushed in.
func _blue_button(theme: Theme, type: String) -> void:
	_button(theme, type, "button_blue", "button_blue_hover", "button_blue_pressed")
	for state in ["normal", "hover", "pressed"]:
		(theme.get_stylebox(state, type) as StyleBoxTexture).modulate_color = ROYAL_TINT
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(color, type, CREAM)


func _button(theme: Theme, type: String, normal: String, hover: String, pressed: String) -> void:
	theme.set_stylebox("normal", type, _texture(normal, 6, 10))
	theme.set_stylebox("hover", type, _texture(hover, 6, 10))
	theme.set_stylebox("pressed", type, _texture(pressed, 10, 6))
	theme.set_stylebox("disabled", type, _texture("button_grey", 6, 10))
	theme.set_stylebox("focus", type, StyleBoxEmpty.new())
	theme.set_color("font_color", type, INK)
	theme.set_color("font_hover_color", type, INK)
	theme.set_color("font_pressed_color", type, INK)
	theme.set_color("font_focus_color", type, INK)
	theme.set_color("font_hover_pressed_color", type, INK)
	theme.set_color("font_disabled_color", type, DISABLED_TEXT)


func _texture(name: String, top: float, bottom: float) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load("res://assets/ui/%s.png" % name)
	box.set_texture_margin_all(14.0)
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = top
	box.content_margin_bottom = bottom
	return box


func _flat(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box


func _pad(box: StyleBox, horizontal: float, vertical: float) -> void:
	box.content_margin_left = horizontal
	box.content_margin_right = horizontal
	box.content_margin_top = vertical
	box.content_margin_bottom = vertical
