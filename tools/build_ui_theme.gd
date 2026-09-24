extends SceneTree
## Builds res://assets/ui/game_theme.tres, the HUD and menu look, from Kenney
## UI Pack sprites, Kenney Future Narrow, and the GDD palette. Every color and
## margin is here in one readable place. Re-run after changing it:
##   "$GODOT" --headless --path . -s res://tools/build_ui_theme.gd
## (Or edit game_theme.tres in the Inspector; re-running overwrites those edits.)

const OUT := "res://assets/ui/game_theme.tres"

# GDD palette plus UI neutrals.
const CREAM := Color("f4ebdd")
const INK := Color("3d3530")           # GDD background; dark text on buttons
const PANEL := Color("2b2420f0")
const PANEL_BORDER := Color("5a4a3e")
const TRACK := Color("1e1916")
const GOLD := Color("f2c94c")
const HEALTH := Color("7bb35a")
const MUTED := Color("9a8e84")
const TAB_IDLE := Color("3a302a")
const TAB_HOVER := Color("4a3f38")


func _initialize() -> void:
	var theme := Theme.new()
	theme.default_font = load("res://assets/fonts/kenney_future_narrow.ttf")
	theme.default_font_size = 15

	theme.set_color("font_color", "Label", CREAM)

	_button(theme, "Button", "button_yellow", "button_yellow_hover", "button_yellow_pressed")
	# The Boost button while stalled ("Crank!").
	theme.set_type_variation("CrankButton", "Button")
	_button(theme, "CrankButton", "button_red", "button_red", "button_red")
	theme.set_color("font_color", "CrankButton", CREAM)
	theme.set_color("font_hover_color", "CrankButton", CREAM)
	theme.set_color("font_pressed_color", "CrankButton", CREAM)

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

	var err := ResourceSaver.save(theme, OUT)
	print("Saved %s (%s)" % [OUT, error_string(err)])
	quit(0 if err == OK else 1)


## Kenney buttons: 9-sliced, with a 4 px "depth" lip at the bottom that
## disappears when pressed, so the label shifts down to look pushed in.
func _button(theme: Theme, type: String, normal: String, hover: String, pressed: String) -> void:
	theme.set_stylebox("normal", type, _texture(normal, 6, 10))
	theme.set_stylebox("hover", type, _texture(hover, 6, 10))
	theme.set_stylebox("pressed", type, _texture(pressed, 10, 6))
	theme.set_stylebox("disabled", type, _texture("button_grey", 6, 10))
	theme.set_stylebox("focus", type, StyleBoxEmpty.new())
	theme.set_color("font_color", type, INK)
	theme.set_color("font_hover_color", type, INK)
	theme.set_color("font_pressed_color", type, INK)
	theme.set_color("font_disabled_color", type, MUTED)


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
