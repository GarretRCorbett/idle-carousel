extends Node
## File I/O: player settings (settings.cfg, survive new runs) and the run save
## (save_data.json, GDD "Save System"). Offline progress comes in Phase 4 Step 2.

signal setting_changed(key: StringName, value: Variant)
## The run was written to disk (the HUD flashes its save icon).
signal run_saved

## Bump when the save layout changes, and upgrade older files in _read_file().
const SAVE_VERSION := 1

const SECTION := "settings"
## Volumes are 0..1 (linear); 0 mutes the bus.
const DEFAULTS: Dictionary[StringName, Variant] = {
	&"master_volume": 0.8,
	&"sfx_volume": 0.8,
	&"music_volume": 0.8,
	&"fullscreen": false,
	## Waves arrive on their own; off = the countdown pauses until you send one.
	&"auto_wave": true,
	## Locale code, e.g. "en". Falls back to English if that language isn't loaded.
	&"language": "en",
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
## Tests point this somewhere else too. The previous save is kept beside it
## as .bak, and each save is written to .tmp first.
var run_save_path: String = "user://save_data.json"
## Run saving is on only for runs started from the main menu (Continue / New
## Run), so tests, the economy sim and render tools never touch the player's save.
var run_saves_enabled: bool = false
## The main menu asks for the saved run; Game loads it when it starts.
var continue_requested: bool = false
## A run was saved since the game started. Offline time only counts while the
## game was closed, so time spent on the main menu pays nothing (Garret).
var _saved_this_session: bool = false


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
	elif key == &"language":
		var locale := String(value)
		if not locale in TranslationServer.get_loaded_locales():
			locale = "en"
		# Font first, so the re-translate that set_locale triggers draws with it.
		LocaleFonts.apply(locale)
		TranslationServer.set_locale(locale)
	elif key == &"fullscreen" and DisplayServer.get_name() != "headless":
		# Exclusive fullscreen bypasses the Windows compositor, which gives the
		# smoothest frame pacing (borderless fullscreen can still judder).
		DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED)


# --- Run save ----------------------------------------------------------------------

func has_run_save() -> bool:
	return not _read_run_file().is_empty()


## Writes the run: to .tmp first, then the old save becomes .bak and .tmp takes
## its place, so a crash mid-write never leaves a broken save. Does nothing
## unless run saving is on.
func save_run() -> bool:
	if not run_saves_enabled:
		return false
	var data := {
		"version": SAVE_VERSION,
		"saved_at": int(Time.get_unix_time_from_system()),
		"permanent": {},  # prestige (Phase 5)
		"run": GameState.to_save_data(),
	}
	var tmp_path := run_save_path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("Can't write %s (%s)" % [tmp_path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(data, "	"))
	file.close()
	var backup_path := run_save_path + ".bak"
	if FileAccess.file_exists(run_save_path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)
		DirAccess.rename_absolute(run_save_path, backup_path)
	var error := DirAccess.rename_absolute(tmp_path, run_save_path)
	if error != OK:
		push_error("Can't replace %s (%s)" % [run_save_path, error_string(error)])
		return false
	_saved_this_session = true
	run_saved.emit()
	return true


## Loads the saved run into GameState. Returns false if there's no usable save.
func load_run() -> bool:
	var data := _read_run_file()
	if data.is_empty():
		return false
	return GameState.load_save_data(data["run"], UpgradeManager.get_definitions())


## Unix time of the last save, or 0 if there's none (offline progress, Step 2).
func get_run_saved_at() -> int:
	return int(_read_run_file().get("saved_at", 0))


## Seconds since the last save while the game was closed; 0 if it was saved
## during this session or the clock went backwards.
func get_offline_seconds() -> float:
	var saved_at := get_run_saved_at()
	if _saved_this_session or saved_at <= 0:
		return 0.0
	return maxf(0.0, Time.get_unix_time_from_system() - saved_at)


func delete_run_save() -> void:
	for path in [run_save_path, run_save_path + ".bak", run_save_path + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


## The save, or the backup if the save is missing or broken; {} if neither works.
func _read_run_file() -> Dictionary:
	for path in [run_save_path, run_save_path + ".bak"]:
		var data := _read_file(path)
		if not data.is_empty():
			return data
	return {}


func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed: Variant = json.data
	if not parsed is Dictionary or not parsed.get("run") is Dictionary:
		return {}
	var version := int(parsed.get("version", 0))
	if version < 1 or version > SAVE_VERSION:
		return {}  # from a newer build: leave it alone rather than misread it
	return parsed
