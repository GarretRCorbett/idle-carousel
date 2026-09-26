class_name StyleStudy
extends Node
## Developer-only renders. No player settings are written; no source art is saved.
## Run after the theme builder: Godot --path . --audio-driver Dummy --fixed-fps 10
## tools/_style/StyleStudy.tscn -- purple_garden [sheets]

@export var output_dir: String = "res://planning/phase3/style_tiers_palette/"
@export var game_size: Vector2i = Vector2i(1280, 720)
@export var sheet_size: Vector2i = Vector2i(1660, 1430)
@export var sheet_origin: Vector2 = Vector2(156, 170)
@export var group_width: float = 372.0
@export var row_height: float = 204.0
@export var tile_size: Vector2 = Vector2(120, 180)
@export var font_size: int = 17
@export var heading_size: int = 28
@export var ink: Color = Color("292333")
@export var ivory: Color = Color("fff4dc")
@export var sheet_bg: Color = Color("211c2b")
@export var tier_shade_factor: float = 0.68
@export var seed_value: int = 7319
@export var wave_count: int = 2
@export var mid_tier: int = 2
@export var preview_gold: float = 850.0
@export var play_frames: int = 34
@export var zoom_factor: float = 2.0
## Real screen coordinates in the unmodified ParkBackground render.
@export var crop_rects: Array[Rect2i] = [
	Rect2i(475, 48, 120, 180), Rect2i(580, 530, 120, 180),
	Rect2i(580, 270, 120, 180), Rect2i(192, 535, 120, 180),
]
@export var background_names: PackedStringArray = ["Beige pavement", "Brick walkway", "Grey plaza stone", "Green planter"]
@export var option_names: PackedStringArray = ["A / Ink", "B / Ivory", "C / Tier shade"]
@export var tier_names: PackedStringArray = ["Grey", "Green", "Yellow", "Orange", "Red", "Charcoal"]
@export var enemy_names: PackedStringArray = ["Leaf", "Stick", "Rock", "Boulder"]
## Machado et al. 2009, severity 1.0, applied to linear RGB then back to sRGB.
@export var protan: PackedVector3Array = PackedVector3Array([
	Vector3(0.152286, 1.052583, -0.204868), Vector3(0.114503, 0.786281, 0.099216), Vector3(-0.003882, -0.048116, 1.051998)])
@export var deutan: PackedVector3Array = PackedVector3Array([
	Vector3(0.367322, 0.860646, -0.227968), Vector3(0.280085, 0.672501, 0.047413), Vector3(-0.011820, 0.042940, 0.968881)])

var _font: Font = preload("res://assets/fonts/rubik_variable.ttf")
var _catalog: TierCatalog = preload("res://resources/tiers/tier_catalog.tres")
var _palette_id: String = "purple_garden"


func _ready() -> void:
	# Keep developer captures reproducible irrespective of saved locale/window mode.
	TranslationServer.set_locale("en")
	LocaleFonts.apply("en")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_palette_id = args[0]
	await _game_frame()
	await _menu_frame()
	await _palette_sheet()
	if "sheets" in args:
		await _outline_sheets()
	if "compare" in args:
		await _comparison("hud")
		await _comparison("title")
	print("STYLE STUDY COMPLETE: ", _palette_id)
	get_tree().quit()


func _viewport(size_px: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = size_px
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_2d = Viewport.MSAA_2X
	add_child(viewport)
	return viewport


func _capture(viewport: SubViewport, file: String) -> Image:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	if not file.is_empty():
		var err := image.save_png(output_dir + file + ".png")
		assert(err == OK, "Cannot save " + file)
		print("Rendered ", file)
	return image


func _game_frame() -> void:
	seed(seed_value)
	var viewport := _viewport(game_size)
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	viewport.add_child(game)
	game.debug_step_tier(mid_tier)
	game.debug_fill_kill_gate()
	game.debug_add_gold(preview_gold)
	var waves := game.get_node("WaveManager") as WaveManager
	waves.set_auto(true) # Runtime only; does not save a preference.
	waves.start(seed_value)
	game.debug_send_waves(wave_count)
	for frame in play_frames:
		await get_tree().process_frame
	game.process_mode = Node.PROCESS_MODE_DISABLED
	await _capture(viewport, _palette_id + "_hud")
	viewport.queue_free()
	await get_tree().process_frame


func _menu_frame() -> void:
	var viewport := _viewport(game_size)
	var menu := (load("res://scenes/MainMenu.tscn") as PackedScene).instantiate() as MainMenu
	viewport.add_child(menu)
	await get_tree().process_frame
	menu.process_mode = Node.PROCESS_MODE_DISABLED
	await _capture(viewport, _palette_id + "_title")
	viewport.queue_free()
	await get_tree().process_frame


func _canvas(viewport: SubViewport, title: String, subtitle: String) -> Control:
	var canvas := Control.new()
	canvas.size = Vector2(viewport.size)
	viewport.add_child(canvas)
	_rect(canvas, Rect2(Vector2.ZERO, canvas.size), sheet_bg)
	_label(canvas, title, Vector2(24, 18), heading_size)
	_label(canvas, subtitle, Vector2(24, 62), font_size)
	return canvas


func _label(parent: Node, text: String, at: Vector2, size_px: int, color: Color = Color("fff4dc")) -> void:
	var label := Label.new()
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.text = text
	label.position = at
	label.add_theme_font_override(&"font", _font)
	label.add_theme_font_size_override(&"font_size", size_px)
	label.add_theme_color_override(&"font_color", color)
	parent.add_child(label)


func _rect(parent: Node, area: Rect2, color: Color) -> void:
	var rect := ColorRect.new()
	rect.position = area.position
	rect.size = area.size
	rect.color = color
	parent.add_child(rect)


func _picture(parent: Node, image: Image, area: Rect2) -> void:
	var picture := TextureRect.new()
	picture.texture = ImageTexture.create_from_image(image)
	picture.position = area.position
	picture.size = area.size
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	parent.add_child(picture)


func _outline_sheets() -> void:
	# Extract the actual scene node so exported background settings and Kenney trees match.
	var viewport := _viewport(game_size)
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate()
	var background := game.get_node("World/Background") as ParkBackground
	background.get_parent().remove_child(background)
	game.free()
	background.position = Vector2(game_size) / 2.0
	viewport.add_child(background)
	var park := await _capture(viewport, "park_crop_source")
	viewport.queue_free()
	await get_tree().process_frame
	for enemy_name in enemy_names:
		viewport = _viewport(sheet_size)
		var native_only := enemy_name == "Boulder"
		var subtitle := "Six tiers x three outlines x four real park crops. Top: game size; bottom: 2x detail. Existing outline width."
		if native_only:
			subtitle = "Boulder boss at game size (88 px texture diameter). Six tiers x three outlines x four real park crops."
		var canvas := _canvas(viewport, enemy_name + " / tier outline study", subtitle)
		for bg in background_names.size():
			_label(canvas, background_names[bg], Vector2(sheet_origin.x + bg * group_width, 108), font_size)
			for option in option_names.size():
				_label(canvas, option_names[option], Vector2(sheet_origin.x + bg * group_width + option * 124, 138), font_size)
		for rank in _catalog.tiers.size():
			var tier := _catalog.get_tier(rank)
			var y := sheet_origin.y + rank * row_height
			_label(canvas, "%d / %s" % [rank + 1, tier_names[rank]], Vector2(18, y + 30), font_size)
			_label(canvas, "#" + tier.tint.to_html(false), Vector2(18, y + 57), font_size)
			for bg in background_names.size():
				var crop := park.get_region(crop_rects[bg])
				for option in option_names.size():
					var at := Vector2(sheet_origin.x + bg * group_width + option * 124, y)
					_picture(canvas, crop, Rect2(at, tile_size))
					var colors: Array[Color] = [ink, ivory, tier.tint.darkened(tier_shade_factor)]
					var sample_tier := tier.duplicate() as TierData
					sample_tier.outline_color = colors[option]
					_enemy(canvas, enemy_name, sample_tier, at + Vector2(60, 86 if native_only else 40), 1.0)
					if not native_only:
						_enemy(canvas, enemy_name, sample_tier, at + Vector2(60, 120), zoom_factor)
		await _capture(viewport, "outlines_" + enemy_name.to_lower())
		viewport.queue_free()
		await get_tree().process_frame


func _enemy(parent: Node, enemy_name: String, tier: TierData, at: Vector2, zoom: float) -> void:
	var enemy := (load("res://scenes/enemies/%s.tscn" % enemy_name) as PackedScene).instantiate() as EnemyBase
	enemy.configure(tier, 1.0)
	enemy.position = at
	enemy.scale = Vector2.ONE * zoom
	parent.add_child(enemy)
	enemy.process_mode = Node.PROCESS_MODE_DISABLED


func _simulate(color: Color, mode: int) -> Color:
	if mode == 0:
		return color
	var linear := color.srgb_to_linear()
	var rgb := Vector3(linear.r, linear.g, linear.b)
	var matrix := deutan if mode == 1 else protan
	return Color(clampf(matrix[0].dot(rgb), 0, 1), clampf(matrix[1].dot(rgb), 0, 1), clampf(matrix[2].dot(rgb), 0, 1)).linear_to_srgb()


func _ratio(a: Color, b: Color) -> float:
	var first := a.srgb_to_linear().get_luminance()
	var second := b.srgb_to_linear().get_luminance()
	return (maxf(first, second) + 0.05) / (minf(first, second) + 0.05)


func _palette_sheet() -> void:
	var palette := load("res://resources/ui_palettes/%s.tres" % _palette_id) as UiPalette
	var theme := load("res://assets/ui/game_theme.tres") as Theme
	var viewport := _viewport(Vector2i(1500, 1150))
	var canvas := _canvas(viewport, palette.dev_name + " / roles, states and color vision", "Machado 2009 severity 1.0; simulations are a sanity check, not a guarantee. Tier order and numbered HUD pips remain fixed.")
	var modes: PackedStringArray = ["Standard vision", "Deuteranopia", "Protanopia"]
	var roles: PackedStringArray = ["Primary / Play, Boost, Buy", "Secondary / Send, Settings", "Danger / Crank, Give up"]
	var types: PackedStringArray = ["Button", "BlueButton", "CrankButton"]
	var report := "# " + palette.dev_name + " contrast measurements\n\nText contrast uses WCAG linear sRGB luminance. Kenney face sampled at texture center, multiplied by tint. Opaque panels.\n\n"
	for mode in modes.size():
		var x: float = 24 + mode * 494
		_label(canvas, modes[mode], Vector2(x, 110), heading_size)
		_rect(canvas, Rect2(x, 156, 468, 958), _simulate(palette.panel, mode))
		for role in roles.size():
			var y: float = 180 + role * 172
			_label(canvas, roles[role], Vector2(x + 12, y), font_size, _simulate(palette.body, mode))
			for state_index in 4:
				var state: String = ["normal", "hover", "pressed", "disabled"][state_index]
				var box := theme.get_stylebox(state, types[role]).duplicate() as StyleBoxTexture
				var foreground := theme.get_color("font_disabled_color" if state == "disabled" else "font_color", types[role])
				var texture_image := box.texture.get_image()
				var face := texture_image.get_pixel(texture_image.get_width() / 2, texture_image.get_height() / 2) * box.modulate_color
				var contrast := _ratio(foreground, face)
				if mode == 0:
					report += "%s %s: text #%s / face #%s = %.2f:1\n\n" % [types[role], state, foreground.to_html(false), face.to_html(false), contrast]
				# Neutral texture is slightly blue-grey: transform the composite face,
				# then undo that base so the simulated face is exact at the sample.
				var base := texture_image.get_pixel(texture_image.get_width() / 2, texture_image.get_height() / 2)
				var simulated := _simulate(face, mode)
				box.modulate_color = Color(simulated.r / base.r, simulated.g / base.g, simulated.b / base.b)
				var button := Button.new()
				button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
				button.text = state.capitalize()
				button.position = Vector2(x + 12 + (state_index % 2) * 222, y + 30 + (state_index / 2) * 60)
				button.size = Vector2(210, 50)
				button.theme = theme
				button.mouse_filter = Control.MOUSE_FILTER_IGNORE
				button.add_theme_stylebox_override(&"normal", box)
				button.add_theme_color_override(&"font_color", _simulate(foreground, mode))
				canvas.add_child(button)
		for rank in _catalog.tiers.size():
			var tier := _catalog.get_tier(rank)
			var tier_x: float = x + 12 + rank * 74
			_rect(canvas, Rect2(tier_x, 728, 65, 58), _simulate(tier.tint, mode))
			_label(canvas, str(rank + 1), Vector2(tier_x + 25, 790), font_size, _simulate(palette.body, mode))
		_label(canvas, "Tiers: 1 Grey > 2 Green > 3 Yellow", Vector2(x + 12, 838), font_size, _simulate(palette.body, mode))
		_label(canvas, "4 Orange > 5 Red > 6 Charcoal", Vector2(x + 12, 866), font_size, _simulate(palette.body, mode))
		var extras: PackedStringArray = ["health", "gold", "border", "muted", "highlight"]
		for index in extras.size():
			var color: Color = palette.get(extras[index])
			_rect(canvas, Rect2(x + 12, 920 + index * 34, 48, 24), _simulate(color, mode))
			_label(canvas, extras[index] + "  #" + color.to_html(false), Vector2(x + 74, 920 + index * 34), font_size, _simulate(palette.body, mode))
	for role: String in ["body", "muted", "gold"]:
		report += "%s / panel: %.2f:1\n\n" % [role, _ratio(palette.get(role), palette.panel)]
	report += "## Tier sanity check\n\n| Tier | Tint | Darker outline C | Deuteranopia | Protanopia |\n|---|---|---|---|---|\n"
	for rank in _catalog.tiers.size():
		var tint := _catalog.get_tier(rank).tint
		report += "| %s | #%s | #%s | #%s | #%s |\n" % [tier_names[rank], tint.to_html(false), tint.darkened(tier_shade_factor).to_html(false), _simulate(tint, 1).to_html(false), _simulate(tint, 2).to_html(false)]
	report += "\nGreen/Yellow luminance separation: deuteranopia %.2f:1; protanopia %.2f:1. They remain confusable.\n" % [_ratio(_simulate(_catalog.get_tier(1).tint, 1), _simulate(_catalog.get_tier(2).tint, 1)), _ratio(_simulate(_catalog.get_tier(1).tint, 2), _simulate(_catalog.get_tier(2).tint, 2))]
	var report_file := FileAccess.open(output_dir + _palette_id + "_contrast.md", FileAccess.WRITE)
	report_file.store_string(report)
	await _capture(viewport, _palette_id + "_accessibility")
	viewport.queue_free()
	await get_tree().process_frame


func _comparison(kind: String) -> void:
	var viewport := _viewport(Vector2i(game_size.x * 2, game_size.y + 92))
	var canvas := _canvas(viewport, "Purple Garden (A)", "Same scene, seed, tier and capture timing. View original PNGs at 100% to judge text and outlines.")
	_label(canvas, "Gilded Plum (B)", Vector2(game_size.x + 24, 18), heading_size)
	for index in 2:
		var id: String = ["purple_garden", "gilded_plum"][index]
		var image := Image.load_from_file(ProjectSettings.globalize_path(output_dir + id + "_" + kind + ".png"))
		_picture(canvas, image, Rect2(Vector2(index * game_size.x, 92), Vector2(game_size)))
	await _capture(viewport, "compare_" + kind)
	viewport.queue_free()
	await get_tree().process_frame
