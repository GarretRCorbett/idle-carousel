extends Node
## Developer-only renders of the Park Guide (Phase 4 Step 8): the real game
## with its pause menu open on the Guide tab. Discovers a handful of entries
## and buys a Wolf so both "met" and "???" pages show. Writes PNGs to
## planning/phase4/guide/. Needs a display (xvfb-run in a cloud session):
##   xvfb-run -a "$GODOT" --path . --audio-driver Dummy res://tools/_render/GuideRender.tscn
## It also works under --write-movie (each frame is written as well).

const OUT := "res://planning/phase4/guide/"
const GAME_SCENE := "res://scenes/Game.tscn"
## What the render pretends has been met.
const MET: Array[String] = ["mount:wolf", "enemy:leaf", "enemy:stick", "tier:grey", "tier:green",
		"boss:leaf_storm", "event:speed_surge", "mechanic:latch"]
## Pages to capture: [file, entry kind, entry id].
const SHOTS: Array[Array] = [
	["guide_wolf.png", GuideEntry.Kind.MOUNT, &"wolf"],
	["guide_unknown.png", GuideEntry.Kind.MOUNT, &"elephant"],
]


func _ready() -> void:
	TranslationServer.set_locale("en")
	LocaleFonts.apply("en")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var game := (load(GAME_SCENE) as PackedScene).instantiate() as Game
	add_child(game)
	await _frames(3)
	for id in MET:
		SaveManager.discover(id)
	GameState.add_gold(100000.0)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"wolf")
	UpgradeManager.purchase(&"wolf_level")
	await _frames(30)
	var menu := game.find_child("OptionsMenu", true, false) as OptionsMenu
	var tabs := game.find_child("OptionsTabs", true, false) as TabContainer
	menu.open()
	var guide: ParkGuide
	for i in tabs.get_tab_count():
		if tabs.get_tab_control(i) is ParkGuide:
			tabs.current_tab = i
			guide = tabs.get_tab_control(i) as ParkGuide
	for shot in SHOTS:
		var entries := guide.get_entries()
		for i in entries.size():
			if entries[i].kind == shot[1] and entries[i].id == shot[2]:
				guide.get_entry_buttons()[i].grab_focus()
		await _frames(3)
		var image := get_viewport().get_texture().get_image()
		image.save_png(ProjectSettings.globalize_path(OUT + shot[0]))
		print("wrote ", OUT + shot[0])
	get_tree().paused = false
	get_tree().quit()


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
