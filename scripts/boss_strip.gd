class_name BossStrip
extends PanelContainer
## The slim strip above the carousel (Garret, memo Q option A). While farming:
## the selected tier's boss, its kill gate, and Challenge. During a fight: the
## timer, the boss's health (or the split Leaves remaining), and a two-step
## Give up. On the right, six numbered tier pips: click an unlocked tier to
## farm it. It asks through signals; Game decides.

signal challenge_requested
signal give_up_requested
signal tier_selected(rank: int)

## Tiers for the pips and each tier's boss.
@export var tier_catalog: TierCatalog = preload("res://resources/tiers/tier_catalog.tres")

@export_group("Wording")
@export var challenge_key: String = "BOSS_CHALLENGE"
@export var give_up_key: String = "BOSS_GIVE_UP"
@export var beaten_key: String = "BOSS_BEATEN"
@export var kills_key: String = "BOSS_KILLS"
@export var remaining_key: String = "BOSS_REMAINING"
@export var no_boss_key: String = "BOSS_NONE"

@export_group("Pips")
@export_range(12.0, 48.0, 1.0, "suffix:px") var pip_size: float = 24.0
@export var selected_border_color: Color = Color.WHITE
## Locked tiers are dimmed to this.
@export var locked_modulate: Color = Color(1.0, 1.0, 1.0, 0.3)
@export_range(12, 32, 1) var pip_font_size: int = 13

@onready var _boss_name: Label = %BossName
@onready var _progress: Label = %Progress
@onready var _bar: ProgressBar = %Bar
@onready var _action: TwoStepButton = %ActionButton
@onready var _pips_box: HBoxContainer = %Pips

var _pips: Array[Button] = []
var _fighting: bool = false
var _time_left: float = 0.0
var _remaining: int = -1


func _ready() -> void:
	for label: Label in [_boss_name, _progress]:
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_action.confirmed.connect(func() -> void:
		AudioManager.play_sfx(&"click")
		if _fighting:
			give_up_requested.emit()
		else:
			challenge_requested.emit())
	_build_pips()
	GameState.selected_tier_changed.connect(func(_rank: int) -> void: refresh())
	# Kills come often (every enemy); they only change the gate text and bar.
	GameState.tier_kills_changed.connect(func(_rank: int, _kills: int) -> void: _on_kills_changed())
	GameState.boss_beaten.connect(func(_rank: int, _first: bool) -> void: refresh())
	GameState.boss_active_changed.connect(_on_boss_active_changed)
	GameState.run_reset.connect(refresh)
	GameState.debug_unlocks_changed.connect(refresh)
	ThemeManager.theme_changed.connect(_on_theme_changed)
	refresh()


## A theme may rename the boss.
func _on_theme_changed(_theme: ParkTheme) -> void:
	refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		refresh()


## Every piece has a fixed width (set in BossStrip.tscn; long text is cut
## with "..."), so switching tiers or starting a fight never shifts the strip.

## Game forwards the fight's timer (seconds left) every tick. (Setting the
## same text again is free: Label ignores it.)
func set_fight_time(seconds_left: float) -> void:
	_time_left = seconds_left
	if _fighting and _remaining < 0:
		var shown := ceili(seconds_left)
		_progress.text = "%d:%02d" % [shown / 60, shown % 60]


## The boss's health, 0..1.
func set_boss_health(fraction: float) -> void:
	if _fighting:
		_bar.value = fraction


## After the boss dies: split Leaves still to kill.
func set_remaining(count: int) -> void:
	_remaining = count
	if _fighting:
		_progress.text = tr(remaining_key).format([count])


func _on_boss_active_changed(active: bool) -> void:
	_fighting = active
	_remaining = -1
	_progress.text = ""
	_action.disarm()
	refresh()


func _on_kills_changed() -> void:
	if _fighting or not is_node_ready():
		return
	var tier := tier_catalog.get_tier(GameState.get_selected_tier())
	_update_gate(tier, tier.boss if tier != null else null)
	_action.disabled = not BossEncounter.can_challenge(tier)


## Rebuilds everything from GameState (cheap; runs on changes only).
func refresh() -> void:
	if not is_node_ready():
		return
	var tier := tier_catalog.get_tier(GameState.get_selected_tier())
	var boss := tier.boss if tier != null else null
	_boss_name.text = tr(ThemeManager.boss_name_key(boss)) if boss != null else tr(no_boss_key)
	if _fighting:
		_bar.theme_type_variation = &"HealthBar"
		_action.requires_confirm = true
		_action.set_idle_text(tr(give_up_key))
		_action.theme_type_variation = &"CrankButton"
		_action.disabled = false
		if _remaining >= 0:
			_progress.text = tr(remaining_key).format([_remaining])
	else:
		_bar.theme_type_variation = &""
		_action.requires_confirm = false
		_action.set_idle_text(tr(challenge_key))
		_action.theme_type_variation = &""
		_action.disabled = not BossEncounter.can_challenge(tier)
		_update_gate(tier, boss)
	_update_pips()


func _update_gate(tier: TierData, boss: BossData) -> void:
	# The bar stays (empty) when there's no boss, so nothing in the strip moves.
	if boss == null:
		_progress.text = ""
		_bar.value = 0.0
		return
	if GameState.is_boss_beaten(tier.rank):
		_progress.text = tr(beaten_key)
		_bar.value = 1.0
		return
	var kills := mini(GameState.get_tier_kills(tier.rank), boss.kills_required)
	_progress.text = tr(kills_key).format([NumberFormat.gold(kills), NumberFormat.gold(boss.kills_required)])
	_bar.value = float(kills) / maxf(1.0, boss.kills_required)


func _build_pips() -> void:
	for tier in tier_catalog.tiers:
		var pip := Button.new()
		pip.text = str(tier.rank + 1)
		pip.tooltip_text = tier.name_key
		pip.focus_mode = Control.FOCUS_NONE
		pip.custom_minimum_size = Vector2(pip_size, pip_size)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pip.add_theme_font_size_override(&"font_size", pip_font_size)
		# Dark numbers on light tiers, light numbers on the dark ones.
		var dark_text := tier.tint.get_luminance() > 0.45
		var number_color := Color(0.1, 0.08, 0.07) if dark_text else Color.WHITE
		for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_disabled_color"]:
			pip.add_theme_color_override(state, number_color)
		var rank := tier.rank
		pip.pressed.connect(func() -> void:
			AudioManager.play_sfx(&"click")
			tier_selected.emit(rank))
		_pips_box.add_child(pip)
		_pips.append(pip)


func _update_pips() -> void:
	for i in _pips.size():
		var tier := tier_catalog.get_tier(i)
		var pip := _pips[i]
		var unlocked := GameState.is_tier_unlocked(i)
		pip.disabled = not unlocked or _fighting
		pip.modulate = Color.WHITE if unlocked else locked_modulate
		var style := StyleBoxFlat.new()
		style.bg_color = tier.tint
		style.set_corner_radius_all(int(pip_size / 2.0))
		if i == GameState.get_selected_tier():
			style.set_border_width_all(3)
			style.border_color = selected_border_color
		elif tier.outline_color.a > 0.0:
			style.set_border_width_all(2)
			style.border_color = tier.outline_color
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
			pip.add_theme_stylebox_override(state, style)
