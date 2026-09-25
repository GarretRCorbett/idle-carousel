extends SceneTree
## Dev tool: rebuilds resources/themes/*.tres (the normal park, plus the Winter
## and Halloween test themes that prove a full reskin works; see
## planning/phase3/theming_plan.md). Shapes are drawn in code (EnemySkin), so no
## new art files. Each skin keeps its enemy's normal size.
##   "$GODOT" --headless --path . -s res://tools/make_test_themes.gd

const OUT := "res://resources/themes/"

## enemy id -> [shape, color, points]
const WINTER := {
	&"leaf": [EnemySkin.Shape.STAR, Color("ffffff"), 6],
	&"storm_leaf": [EnemySkin.Shape.STAR, Color("ffffff"), 6],
	&"stick": [EnemySkin.Shape.SHARD, Color("e4f2ff"), 4],
	&"rock": [EnemySkin.Shape.ROUND, Color("ffffff"), 16],
	&"boulder_grip": [EnemySkin.Shape.ROUND, Color("ffffff"), 16],
	&"leaf_storm": [EnemySkin.Shape.STAR, Color("ffffff"), 8],
	&"gilded_gale": [EnemySkin.Shape.STAR, Color("fff6d8"), 8],
	&"stick_giant": [EnemySkin.Shape.SHARD, Color("e4f2ff"), 4],
	&"boulder": [EnemySkin.Shape.ROUND, Color("ffffff"), 16],
	&"ancient_log": [EnemySkin.Shape.SHARD, Color("d6e8f7"), 4],
	&"obsidian_boulder": [EnemySkin.Shape.ROUND, Color("d3dceb"), 16],
}
const HALLOWEEN := {
	&"leaf": [EnemySkin.Shape.PUMPKIN, Color("f0a050"), 0],
	&"storm_leaf": [EnemySkin.Shape.PUMPKIN, Color("f0a050"), 0],
	&"stick": [EnemySkin.Shape.SHARD, Color("f2ecdf"), 4],
	&"rock": [EnemySkin.Shape.ROUND, Color("c9b6e4"), 16],
	&"boulder_grip": [EnemySkin.Shape.ROUND, Color("c9b6e4"), 16],
	&"leaf_storm": [EnemySkin.Shape.PUMPKIN, Color("f0a050"), 0],
	&"gilded_gale": [EnemySkin.Shape.PUMPKIN, Color("f5c060"), 0],
	&"stick_giant": [EnemySkin.Shape.SHARD, Color("f2ecdf"), 4],
	&"boulder": [EnemySkin.Shape.ROUND, Color("c9b6e4"), 16],
	&"ancient_log": [EnemySkin.Shape.SHARD, Color("e6dcc8"), 4],
	&"obsidian_boulder": [EnemySkin.Shape.ROUND, Color("a58fc4"), 16],
}


func _initialize() -> void:
	var park := ParkTheme.new()
	park.id = &"park"
	park.dev_name = "Park"
	_save(park, "park")

	var winter := _theme(&"winter_test", "Winter (test)", WINTER)
	winter.scenery = {
		&"park_background": {
			"pavement_color": Color("eef2f7"), "slab_joint_color": Color(0.35, 0.45, 0.6, 0.1),
			"lawn_color": Color("e3ebf5"), "curb_color": Color("ffffff"), "clearing_color": Color("d8dfe9"),
			"tree_tint": Color(0.8, 0.9, 1.0), "bloom_colors": _colors([Color("ffffff"), Color("cfe0f5"), Color("b6c9e6")]),
			"nook_color": Color("dde4ee"),
		},
		&"park_scenery": {
			"pavement_color": Color("eef2f7"), "lawn_color": Color("e3ebf5"),
			"bloom_colors": _colors([Color("ffffff"), Color("cfe0f5")]),
		},
	}
	_save(winter, "winter_test")

	var halloween := _theme(&"halloween_test", "Halloween (test)", HALLOWEEN)
	halloween.scenery = {
		&"park_background": {
			"pavement_color": Color("b9ad98"), "lawn_color": Color("6f7f52"), "clearing_color": Color("a39987"),
			"lamp_glow_color": Color(1.0, 0.55, 0.15, 0.35), "tree_tint": Color(0.95, 0.75, 0.55),
			"bloom_colors": _colors([Color("f0a050"), Color("9b7fbf"), Color("2b2233")]),
			"roof_colors": _colors([Color("6b4f8a"), Color("d9822b"), Color("4a3a60"), Color("d9822b")]),
			"nook_color": Color("a89d88"),
		},
		&"park_scenery": {
			"pavement_color": Color("b9ad98"), "lawn_color": Color("6f7f52"),
			"roof_colors": _colors([Color("6b4f8a"), Color("d9822b"), Color("4a3a60")]),
			"bloom_colors": _colors([Color("f0a050"), Color("9b7fbf")]),
			"lamp_glow_color": Color(1.0, 0.55, 0.15, 0.4),
		},
	}
	_save(halloween, "halloween_test")
	quit()


func _theme(id: StringName, dev_name: String, looks: Dictionary) -> ParkTheme:
	var theme := ParkTheme.new()
	theme.id = id
	theme.dev_name = dev_name
	var skins: Array[EnemySkin] = []
	for enemy_id: StringName in looks:
		var data := load("res://resources/enemies/%s.tres" % enemy_id) as EnemyData
		var look: Array = looks[enemy_id]
		var skin := EnemySkin.new()
		skin.enemy_id = enemy_id
		skin.visual_size = data.placeholder_size
		skin.shape = look[0]
		skin.color = look[1]
		skin.points = maxi(3, look[2])
		skins.append(skin)
	theme.enemy_skins = skins
	return theme


## Typed, so it can replace an exported Array[Color].
func _colors(colors: Array) -> Array[Color]:
	var typed: Array[Color] = []
	typed.assign(colors)
	return typed


func _save(theme: ParkTheme, file: String) -> void:
	var error := ResourceSaver.save(theme, OUT + file + ".tres")
	print("%s: %s" % [file, "saved" if error == OK else error_string(error)])
