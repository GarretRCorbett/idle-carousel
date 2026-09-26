extends Node2D
## Developer-only render for Phase 4 Step 9b: Stub's three styles, each with
## four expressions, on the game's panel color. Writes
## planning/phase4/stub/stub_styles.png. Text is English-only (not shipped).
##   "$GODOT" --path . --audio-driver Dummy tools/_mockups/StubStudy.tscn

const OUT := "res://planning/phase4/stub/"
const CELL := Vector2(300.0, 230.0)
const ORIGIN := Vector2(190.0, 170.0)
const STYLES := ["A  Classic", "B  Tall", "C  Torn stub"]
const EXPRESSIONS := ["Happy", "Surprised", "Worried", "Cheer"]


func _ready() -> void:
	TranslationServer.set_locale("en")
	RenderingServer.set_default_clear_color(Color(0.13, 0.11, 0.16))
	for row in STYLES.size():
		_label(STYLES[row], Vector2(20.0, ORIGIN.y + row * CELL.y - 8.0), 22)
		for col in EXPRESSIONS.size():
			var stub := StubMascot.new()
			stub.style = row as StubMascot.Style
			stub.mood = col as StubMascot.Mood
			stub.size = 170.0
			stub.hop_height = 0.0
			stub.tilt_degrees = 0.0
			stub.position = ORIGIN + Vector2(col * CELL.x + 90.0, row * CELL.y)
			add_child(stub)
	for col in EXPRESSIONS.size():
		_label(EXPRESSIONS[col], Vector2(ORIGIN.x + col * CELL.x + 50.0, 40.0), 18)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "stub_styles.png"))
	print("wrote stub_styles.png")
	get_tree().quit()


func _label(text: String, at: Vector2, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.86))
	add_child(label)
