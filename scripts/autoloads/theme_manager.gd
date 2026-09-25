extends Node
## Holds the current ParkTheme and answers "how does this look now?":
## enemy skins, boss names, scenery colors. The first theme is the normal
## park. Themes change looks only, never stats (see ParkTheme).
## Debug builds: F4 in the game cycles themes (the Winter and Halloween tests).

signal theme_changed(theme: ParkTheme)

var _themes: Array[ParkTheme] = [
	preload("res://resources/themes/park.tres"),
	preload("res://resources/themes/winter_test.tres"),
	preload("res://resources/themes/halloween_test.tres"),
]
var _current: ParkTheme = _themes[0]
## Default skins, built once per EnemyData.
var _default_skins: Dictionary[EnemyData, EnemySkin] = {}


func get_theme() -> ParkTheme:
	return _current


func get_themes() -> Array[ParkTheme]:
	return _themes


## Switches to the theme with this id. False if there's none.
func set_theme(id: StringName) -> bool:
	for theme in _themes:
		if theme.id == id:
			use_theme(theme)
			return true
	return false


## Switches to `theme` (tests may pass one that isn't in the list).
func use_theme(theme: ParkTheme) -> void:
	if theme == null or theme == _current:
		return
	_current = theme
	theme_changed.emit(theme)


## The next (step 1) or previous (-1) theme in the list.
func cycle(step: int) -> void:
	var index := maxi(0, _themes.find(_current))
	use_theme(_themes[posmod(index + step, _themes.size())])


## How `data` looks in the current theme.
func skin_for(data: EnemyData) -> EnemySkin:
	var skin := _current.get_skin(data.id)
	if skin != null:
		return skin
	if not _default_skins.has(data):
		_default_skins[data] = EnemySkin.from_data(data)
	return _default_skins[data]


## The boss's name key in the current theme.
func boss_name_key(boss: BossData) -> String:
	return _current.boss_name_keys.get(boss.boss_id, boss.name_key)


## Sets `node`'s themed properties for `role` (see ParkTheme.scenery): first
## back to the node's own values, then the current theme's overrides. The
## node's own values are remembered the first time, so switching back works.
func apply_scenery(node: Object, role: StringName) -> void:
	var defaults: Dictionary = node.get_meta(&"theme_defaults", {})
	for theme in _themes + ([_current] if not _themes.has(_current) else []):
		for property in theme.scenery.get(role, {}):
			if not defaults.has(property) and property in node:
				defaults[property] = node.get(property)
	node.set_meta(&"theme_defaults", defaults)
	for property in defaults:
		node.set(property, defaults[property])
	var overrides: Dictionary = _current.scenery.get(role, {})
	for property in overrides:
		if property in node:
			node.set(property, overrides[property])
