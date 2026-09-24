extends Node
## File I/O. For now: player settings (volume, fullscreen), kept in their own
## file so they survive new runs. Run saves and offline progress come in Phase 4.

signal setting_changed(key: StringName, value: Variant)

const SECTION := "settings"
## Volumes are 0..1 (linear); 0 mutes the bus.
const DEFAULTS: Dictionary[StringName, Variant] = {
	&"master_volume": 0.8,
	&"sfx_volume": 0.8,
	&"music_volume": 0.8,
	&"fullscreen": false,
}
## Which audio bus each volume setting drives.
const VOLUME_BUSES: Dictionary[StringName, StringName] = {
	&"master_volume": &"Master",
	&"sfx_volume": &"SFX",
	&"music_volume": &"Music",
}

## Tests point this somewhere else so the player's file is never touched.
var settings_path: String = "user://settings.cfg"
var _settings: Dictionary[StringName, Variant] = {}


func _ready() -> void:
	load_settings()


## Reads the settings file (missing or bad values fall back to defaults) and applies them.
func load_settings() -> void:
	_settings = DEFAULTS.duplicate()
	var file := ConfigFile.new()
	if file.load(settings_path) == OK:
		for key in DEFAULTS:
			var value: Variant = file.get_value(SECTION, key, DEFAULTS[key])
			if typeof(value) == typeof(DEFAULTS[key]) or (DEFAULTS[key] is float and value is int):
				_settings[key] = value
	for key in _settings:
		_apply(key)


func get_setting(key: StringName) -> Variant:
	return _settings.get(key, DEFAULTS.get(key))


## Changes, applies, and saves one setting.
func set_setting(key: StringName, value: Variant) -> void:
	if not DEFAULTS.has(key):
		push_error("Unknown setting %s" % key)
		return
	if DEFAULTS[key] is float:
		value = clampf(float(value), 0.0, 1.0)
	_settings[key] = value
	_apply(key)
	_save()
	setting_changed.emit(key, value)


func _save() -> void:
	var file := ConfigFile.new()
	for key in _settings:
		file.set_value(SECTION, key, _settings[key])
	file.save(settings_path)


func _apply(key: StringName) -> void:
	var value: Variant = _settings[key]
	if VOLUME_BUSES.has(key):
		var bus := AudioServer.get_bus_index(VOLUME_BUSES[key])
		if bus >= 0:
			AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(float(value), 0.0001)))
			AudioServer.set_bus_mute(bus, float(value) <= 0.0)
	elif key == &"fullscreen" and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED)
