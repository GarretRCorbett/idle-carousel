extends Node2D
## Developer-only render: the classic Stub's four variants in four Purple Garden
## colorways. Writes planning/phase4/stub/stub_classic.png (English-only).
##   "$GODOT" --path . --audio-driver Dummy tools/_mockups/StubClassicStudy.tscn

const OUT := "res://planning/phase4/stub/"
const PANEL := Color("30283e")
const CELL := Vector2(250.0, 160.0)
const ORIGIN := Vector2(330.0, 150.0)
const VARIANTS := ["1  Plain", "2  Scalloped", "3  Two-tone", "4  Chunky"]
## [name, paper, trim, cheeks]
const COLORWAYS := [
	["Ivory + gold", Color("fff4dc"), Color("c9a24a"), Color(1.0, 0.6, 0.55, 0.6)],
	["Violet + gold", Color("70568b"), Color("ddb96a"), Color(1.0, 0.7, 0.8, 0.5)],
	["Gold + violet", Color("f4d995"), Color("70568b"), Color(1.0, 0.55, 0.5, 0.55)],
	["Ivory + violet", Color("fff4dc"), Color("70568b"), Color(1.0, 0.6, 0.55, 0.6)],
]


func _ready() -> void:
	TranslationServer.set_locale("en")
	RenderingServer.set_default_clear_color(PANEL)
	for row in VARIANTS.size():
		_label(VARIANTS[row], Vector2(24.0, ORIGIN.y + row * CELL.y - 14.0), 22)
		for col in COLORWAYS.size():
			var way: Array = COLORWAYS[col]
			var stub := StubMascot.new()
			stub.classic_variant = row as StubMascot.ClassicVariant
			stub.mood = (StubMascot.Mood.CHEER if col == 3 else StubMascot.Mood.HAPPY) as StubMascot.Mood
			stub.size = 130.0
			stub.paper_color = way[1]
			stub.trim_color = way[2]
			stub.cheek_color = way[3]
			stub.backdrop_color = PANEL
			stub.hop_height = 0.0
			stub.tilt_degrees = 0.0
			stub.position = ORIGIN + Vector2(col * CELL.x, row * CELL.y)
			add_child(stub)
	for col in COLORWAYS.size():
		_label(COLORWAYS[col][0], Vector2(ORIGIN.x + col * CELL.x - 70.0, 40.0), 18)
	for i in 3:
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "stub_classic.png"))
	print("wrote stub_classic.png")
	get_tree().quit()


func _label(text: String, at: Vector2, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.86))
	add_child(label)
