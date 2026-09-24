class_name MainMenu
extends Control
## Title screen: a slowly spinning carousel, Play, Settings (with Controls), and Quit.
## Player-facing text is set in the scene (placeholder until Garret replaces it).

const GAME_SCENE := "res://scenes/Game.tscn"

## Spin of the decorative carousel.
@export_range(0.0, 360.0, 1.0, "suffix:°/s") var carousel_spin_deg_s: float = 20.0

@onready var _carousel: Carousel = %MenuCarousel
@onready var _carousel_spot: Control = %CarouselSpot
@onready var _play_button: Button = %PlayButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _options: OptionsMenu = %OptionsMenu


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_settings_button.pressed.connect(func() -> void:
		AudioManager.play_sfx(&"click")
		_options.open())
	_options.closed.connect(_play_button.grab_focus)
	_carousel_spot.resized.connect(_center_carousel)
	_center_carousel()
	_play_button.grab_focus.call_deferred()


func _process(delta: float) -> void:
	_carousel.advance_rotation(delta, deg_to_rad(carousel_spin_deg_s))


func _center_carousel() -> void:
	_carousel.position = _carousel_spot.size / 2.0


func _on_play_pressed() -> void:
	AudioManager.play_sfx(&"click")
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit_pressed() -> void:
	AudioManager.play_sfx(&"click")
	get_tree().quit()
