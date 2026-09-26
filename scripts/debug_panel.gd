class_name DebugPanel
extends ScrollContainer
## Debug builds only: a "Debug" tab in the Esc menu with testing shortcuts
## (Gold, tiers, waves, healing, game speed, themes). Built in code; its text
## is for developers, so it isn't localized. Game adds it with itself as
## `game`; the main menu adds one without a game (themes only).

const SPEEDS: Array[float] = [1.0, 2.0, 4.0]

var _game: Game
var _theme_button: Button
var _speed_button: Button


func _init(game: Game = null) -> void:
	_game = game
	name = "Debug"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# A ScrollContainer has no size of its own; this keeps the tab usable.
	custom_minimum_size = Vector2(480.0, 400.0)
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED


func _ready() -> void:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 8)
	add_child(column)
	if _game != null:
		_section(column, "Gold")
		var gold := _grid(column)
		_button(gold, "+5,000 Gold (F5)", func() -> void: _game.debug_add_gold(5000.0))
		_button(gold, "+50,000 Gold", func() -> void: _game.debug_add_gold(50000.0))
		_section(column, "Tiers and bosses")
		var tiers := _grid(column)
		_button(tiers, "Previous tier (F2)", func() -> void: _game.debug_step_tier(-1))
		_button(tiers, "Next tier (F3)", func() -> void: _game.debug_step_tier(1))
		_button(tiers, "Fill this tier's kill gate", func() -> void: _game.debug_fill_kill_gate())
		_button(tiers, "Unlock every tier", func() -> void: _game.debug_unlock_all_tiers())
		_section(column, "Fight")
		var fight := _grid(column)
		_button(fight, "Send 5 waves", func() -> void: _game.debug_send_waves(5))
		_button(fight, "Heal carousel", func() -> void: GameState.debug_full_heal())
		_speed_button = _button(fight, "", _next_speed)
		_update_speed_text()
		_section(column, "Random events")
		var events := _grid(column)
		for event in _game.event_list:
			_button(events, String(event.id).capitalize(), _game.debug_spawn_event.bind(event.id))
	_section(column, "Look")
	var look := _grid(column)
	_theme_button = _button(look, "", func() -> void: ThemeManager.cycle(1))
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.get_theme())


func _section(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.add_theme_color_override(&"font_color", Color("7aa2ff"))
	parent.add_child(label)


func _grid(parent: Control) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 8)
	grid.add_theme_constant_override(&"v_separation", 8)
	parent.add_child(grid)
	return grid


func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.custom_minimum_size = Vector2(230.0, 0.0)
	button.pressed.connect(func() -> void:
		AudioManager.play_sfx(&"click")
		action.call())
	parent.add_child(button)
	return button


func _next_speed() -> void:
	var index := SPEEDS.find(Engine.time_scale)
	Engine.time_scale = SPEEDS[(index + 1) % SPEEDS.size()]
	_update_speed_text()


func _update_speed_text() -> void:
	_speed_button.text = "Game speed: %dx" % roundi(Engine.time_scale)


func _on_theme_changed(theme: ParkTheme) -> void:
	_theme_button.text = "Theme: %s (F4)" % theme.dev_name
