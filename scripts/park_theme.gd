class_name ParkTheme
extends Resource
## A look for the whole game (a season or event): enemy skins, boss names and
## scenery colors. Only looks and names: every theme shares the same enemies,
## stats, bosses and waves. One .tres per theme in res://resources/themes/;
## ThemeManager applies the current one. See planning/phase3/theming_plan.md.

@export var id: StringName = &""
## Shown by the dev key only. A player-facing theme name needs a strings key
## (Garret approves player-facing text).
@export var dev_name: String = ""
## Skins by EnemyData.id. Enemies without one keep their normal look.
@export var enemy_skins: Array[EnemySkin] = []
## Boss name keys by BossData.boss_id (localization keys in strings.csv).
## Bosses without one keep their normal name.
@export var boss_name_keys: Dictionary[StringName, String] = {}
## Exported-property overrides for themed scenery, by role:
## &"park_background" (the play field) and &"park_scenery" (the title screen).
## Each maps a property name to its value, e.g. {"lawn_color": Color.WHITE}.
@export var scenery: Dictionary[StringName, Dictionary] = {}


func get_skin(enemy_id: StringName) -> EnemySkin:
	if enemy_id == &"":
		return null
	for skin in enemy_skins:
		if skin != null and skin.enemy_id == enemy_id:
			return skin
	return null


## Empty if the theme is sound; otherwise one line per problem.
func get_problems(known_enemy_ids: Array[StringName]) -> PackedStringArray:
	var problems := PackedStringArray()
	if id == &"":
		problems.append("theme id is empty")
	var seen: Array[StringName] = []
	for skin in enemy_skins:
		if skin == null:
			problems.append("%s: empty skin slot" % id)
			continue
		if not known_enemy_ids.has(skin.enemy_id):
			problems.append("%s: skin for unknown enemy '%s'" % [id, skin.enemy_id])
		if seen.has(skin.enemy_id):
			problems.append("%s: two skins for '%s'" % [id, skin.enemy_id])
		seen.append(skin.enemy_id)
	return problems
