class_name UiThemeBuilder
extends SceneTree
## Builds res://assets/ui/game_theme.tres, the HUD and menu look, from Kenney
## UI Pack sprites, Kenney Future Narrow, and a semantic UiPalette. Every color and
## margin is here in one readable place. Re-run after changing it:
##   "$GODOT" --headless --path . -s res://tools/build_ui_theme.gd
## Colors live in resources/ui_palettes/*.tres; do not hand-edit the output.

const OUT := "res://assets/ui/game_theme.tres"
## Kenney Future with Rubik behind it for letters Kenney lacks (Polish/Turkish
## accents, Cyrillic). CJK will swap the whole font per language later.
const UI_FONT_OUT := "res://assets/fonts/ui_font.tres"
const TITLE_FONT_OUT := "res://assets/fonts/title_font.tres"
## Rubik weight to sit next to Kenney Future's heavy strokes.
const FALLBACK_WEIGHT := 600

## Select a study palette with -- purple_garden or -- gilded_plum.
var palette: UiPalette


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var palette_id: String = args[0] if not args.is_empty() else "purple_garden"
	if palette_id not in ["purple_garden", "gilded_plum"]:
		push_error("Unknown UI palette: %s" % palette_id)
		quit(1)
		return
	palette = load("res://resources/ui_palettes/%s.tres" % palette_id) as UiPalette
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

	theme.set_color("font_color", "Label", palette.body)

	# Default = primary; legacy BlueButton is the secondary role.
	_role_button(theme, "Button", palette.primary, palette.primary_text, palette.lighten_primary_states)
	theme.set_type_variation("BlueButton", "Button")
	_role_button(theme, "BlueButton", palette.secondary, palette.body)
	theme.set_type_variation("CrankButton", "Button")
	_role_button(theme, "CrankButton", palette.danger, palette.body)
	for role: String in ["gold", "body", "muted", "highlight", "ink", "danger", "health"]:
		theme.set_color(role, "Palette", palette.get(role))

	# Toggles (Auto waves, Fullscreen): plain text plus the switch, not a button.
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var empty := StyleBoxEmpty.new()
		empty.content_margin_top = 4.0
		empty.content_margin_bottom = 4.0
		theme.set_stylebox(state, "CheckButton", empty)
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(color, "CheckButton", palette.body)

	var panel := _flat(palette.panel, 12)
	panel.border_color = palette.border
	panel.set_border_width_all(2)
	theme.set_stylebox("panel", "PanelContainer", panel)

	theme.set_stylebox("background", "ProgressBar", _flat(palette.track, 4))
	theme.set_stylebox("fill", "ProgressBar", _flat(palette.gold, 4))
	theme.set_type_variation("HealthBar", "ProgressBar")
	theme.set_stylebox("fill", "HealthBar", _flat(palette.health, 4))
	theme.set_type_variation("CrankBar", "ProgressBar")
	theme.set_stylebox("fill", "CrankBar", _flat(palette.danger, 4))
	theme.set_type_variation("OverdriveBar", "ProgressBar")
	theme.set_stylebox("fill", "OverdriveBar", _flat(palette.highlight, 4))

	var selected := _flat(palette.body, 8)
	selected.corner_radius_bottom_left = 0
	selected.corner_radius_bottom_right = 0
	_pad(selected, 10, 4)
	var idle := selected.duplicate() as StyleBoxFlat
	idle.bg_color = palette.tab_idle
	var hover := selected.duplicate() as StyleBoxFlat
	hover.bg_color = palette.tab_hover
	theme.set_stylebox("tab_selected", "TabContainer", selected)
	theme.set_stylebox("tab_unselected", "TabContainer", idle)
	theme.set_stylebox("tab_hovered", "TabContainer", hover)
	var tab_panel := StyleBoxEmpty.new()
	tab_panel.content_margin_top = 10
	theme.set_stylebox("panel", "TabContainer", tab_panel)
	theme.set_color("font_selected_color", "TabContainer", palette.ink)
	theme.set_color("font_unselected_color", "TabContainer", palette.muted)
	theme.set_color("font_hovered_color", "TabContainer", palette.body)

	var track := _flat(palette.track, 4)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", _flat(palette.gold, 4))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _flat(palette.gold, 4))

	var err := ResourceSaver.save(theme, OUT)
	print("Saved %s (%s)" % [OUT, error_string(err)])
	quit(0 if err == OK else 1)


## Kenney buttons: 9-sliced, with a 4 px "depth" lip at the bottom that
## disappears when pressed, so the label shifts down to look pushed in.
func _role_button(theme: Theme, type: String, fill: Color, text: Color, lighten: bool = false) -> void:
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var pressed := state in ["pressed", "hover_pressed"]
		var box := _texture("button_grey", 10 if pressed else 6, 6 if pressed else 10)
		var amount := palette.pressed_darkening if pressed else palette.hover_darkening
		box.modulate_color = fill
		if state != "normal":
			box.modulate_color = fill.lightened(amount) if lighten else fill.darkened(amount)
		if state == "disabled":
			box.modulate_color = palette.disabled
		theme.set_stylebox(state, type, box)
	var focus := _flat(Color.TRANSPARENT, 6)
	focus.border_color = palette.highlight
	focus.set_border_width_all(2)
	theme.set_stylebox("focus", type, focus)
	for color: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(color, type, text)
	theme.set_color("font_disabled_color", type, palette.disabled_text)


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
