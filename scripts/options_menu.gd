class_name OptionsMenu
extends Control
## Settings (volumes, fullscreen) and a Controls list, shown over the main menu
## or the game. Settings save as soon as they change (SaveManager). In the game
## it pauses play while open. Esc or Back closes it.

signal closed

const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"

## Built by tools/build_ui_theme.gd: UI font plus every script's fallback.
const LANGUAGE_LIST_FONT: Font = preload("res://assets/fonts/language_list_font.tres")

## The game sets this so play stops while the menu is open.
@export var pause_game_while_open: bool = false

@onready var _master_slider: HSlider = %MasterSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _fullscreen_check: CheckButton = %FullscreenCheck
@onready var _language_option: OptionButton = %LanguageOption

## Locale codes in the same order as the Language list.
var _locales: PackedStringArray = []
@onready var _back_button: Button = %BackButton
@onready var _main_menu_button: Button = %MainMenuButton
@onready var _quit_button: Button = %QuitButton
@onready var _tabs: TabContainer = %OptionsTabs


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_bind_slider(_master_slider, &"master_volume")
	_bind_slider(_sfx_slider, &"sfx_volume")
	_bind_slider(_music_slider, &"music_volume")
	_fullscreen_check.button_pressed = SaveManager.get_setting(&"fullscreen")
	_fullscreen_check.toggled.connect(func(on: bool) -> void:
		SaveManager.set_setting(&"fullscreen", on)
		AudioManager.play_sfx(&"click"))
	_setup_language_list()
	_back_button.pressed.connect(close)
	# Only in the game (the main menu has its own Quit). No save system yet
	# (Phase 4), so leaving ends the run.
	_main_menu_button.visible = pause_game_while_open
	_quit_button.visible = pause_game_while_open
	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	# Keys: the tab bar translates titles itself.
	_tabs.set_tab_title(0, "OPT_TAB_SETTINGS")
	_tabs.set_tab_title(1, "OPT_TAB_CONTROLS")
	_tabs.tab_changed.connect(func(_tab: int) -> void: AudioManager.play_sfx(&"tab"))


## Adds a tab after the others (the Debug tab in debug builds).
func add_tab(control: Control, title: String) -> void:
	_tabs.add_child(control)
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, title)


func open() -> void:
	show()
	if pause_game_while_open:
		get_tree().paused = true
	_back_button.grab_focus.call_deferred()


func _on_main_menu_pressed() -> void:
	AudioManager.play_sfx(&"click")
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func close() -> void:
	if not visible:
		return
	hide()
	if pause_game_while_open:
		get_tree().paused = false
	AudioManager.play_sfx(&"click")
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Every loaded language, each shown in its own name (LANGUAGE_NATIVE_NAME in
## that language's column), so players can always find theirs.
func _setup_language_list() -> void:
	# Names are already in their own language; don't translate them again.
	_language_option.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	# Each name is in its own script, so one UI font can't draw them all.
	_language_option.add_theme_font_override(&"font", LANGUAGE_LIST_FONT)
	_language_option.get_popup().add_theme_font_override(&"font", LANGUAGE_LIST_FONT)
	_locales = TranslationServer.get_loaded_locales()
	_locales.sort()
	if _locales.is_empty():
		_locales.append("en")
	for locale in _locales:
		var translation := TranslationServer.get_translation_object(locale)
		var native: String = String(translation.get_message(&"LANGUAGE_NATIVE_NAME")) if translation != null else ""
		_language_option.add_item(native if native != "" else TranslationServer.get_locale_name(locale))
	var current := _locales.find(String(SaveManager.get_setting(&"language")))
	_language_option.select(maxi(current, 0))
	_language_option.item_selected.connect(func(index: int) -> void:
		SaveManager.set_setting(&"language", _locales[index])
		AudioManager.play_sfx(&"click"))


func _bind_slider(slider: HSlider, key: StringName) -> void:
	slider.value = SaveManager.get_setting(key)
	slider.value_changed.connect(func(value: float) -> void: SaveManager.set_setting(key, value))
	# A tick on release so you can hear the new sound-effects level.
	slider.drag_ended.connect(func(_changed: bool) -> void: AudioManager.play_sfx(&"click"))
