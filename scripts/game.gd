class_name Game
extends Node2D
## Root of the play scene. Starts a fresh run and keeps the world centered.
## This is the single place that drives the simulation each tick, so the order
## is explicit: GameState first (boost decay, income window, later latch damage),
## then enemies move, then the carousel moves at the resulting speed.

## Distance of mounts from the carousel center. Mounts space themselves evenly
## around this circle, the first one at the top (where the first booth is).
@export_range(10.0, 400.0, 1.0, "suffix:px") var mount_radius: float = 75.0

@export_group("Pops")
## Ring on a click that doesn't kill, and on enemies removed without Gold
## (Emergency Clear, the stall safety net).
@export var hit_pop_color: Color = Color(1.0, 0.97, 0.85, 0.9)
## Ring on every kill (click or mount), so kills read differently from hits.
@export var kill_pop_color: Color = Color(0.95, 0.22, 0.18, 0.95)
## Kill rings grow this much bigger than hit rings.
@export_range(0.5, 3.0, 0.05) var kill_pop_scale: float = 1.3
## At most this many rings at once (a mass clear can't flood the screen).
@export_range(1, 500, 1) var max_live_pops: int = 40

@onready var _world: Node2D = $World
@onready var _carousel: Carousel = $World/Carousel
@onready var _hud: Hud = $HUD
@onready var _mount_slots: Node2D = $World/Carousel/MountSlots
## The booth placed in the scene; extra booths are copies of it.
@onready var _first_booth: TicketBooth = $World/TicketBooth
@onready var _enemy_layer: Node2D = $World/EnemyLayer
@onready var _click_router: ClickRouter = $World/ClickRouter
@onready var _wave_manager: WaveManager = $WaveManager
@onready var _options: OptionsMenu = $OptionsLayer/OptionsMenu

var _booths: Array[TicketBooth] = []
var _booth_bearings: Array[float] = []
## Mount nodes in roster order, and the roster ids they were built from.
var _mounts: Array[MountBase] = []
var _mount_ids: Array[StringName] = []
## Booth distance from the carousel center, taken from the scene's booth.
var _booth_radius: float = 0.0
var _live_pops: int = 0


func _ready() -> void:
	_booth_radius = (_first_booth.position - _carousel.position).length()
	_booths.append(_first_booth)
	_hud.boost_requested.connect(GameState.add_click_boost)
	_click_router.enemy_clicked.connect(_on_enemy_clicked)
	_wave_manager.center = _carousel.position
	_wave_manager.enemy_layer = _enemy_layer
	_wave_manager.enemy_spawned.connect(_on_enemy_spawned)
	_wave_manager.countdown_changed.connect(_hud.set_wave_countdown)
	_wave_manager.auto_changed.connect(_hud.set_auto_wave)
	_wave_manager.send_available_changed.connect(_hud.set_send_available)
	_wave_manager.set_auto(SaveManager.get_setting(&"auto_wave"))
	_hud.set_auto_wave(_wave_manager.is_auto())
	_hud.send_wave_requested.connect(_wave_manager.send_wave_now)
	_hud.auto_wave_toggled.connect(func(on: bool) -> void:
		_wave_manager.set_auto(on)
		SaveManager.set_setting(&"auto_wave", on))
	_hud.emergency_clear_requested.connect(GameState.try_emergency_clear)
	GameState.emergency_cleared.connect(_on_emergency_cleared)
	GameState.stall_timed_out.connect(_on_stall_timed_out)
	_hud.boost_held_changed.connect(GameState.set_boost_held)
	GameState.booth_count_changed.connect(_layout_booths)
	GameState.mounts_changed.connect(_sync_mounts)
	GameState.reset_run()
	_layout_booths(GameState.get_booth_count())
	_sync_mounts(GameState.get_mount_roster())
	get_viewport().size_changed.connect(_center_world)
	_center_world()
	_wave_manager.start()


## Esc opens Settings (which pauses the game; Esc again closes it).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and not _options.visible:
		_options.open()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	GameState.advance_simulation(delta)
	for enemy: EnemyBase in _enemy_layer.get_children():
		# The stall safety net may have just removed it; a removed enemy must
		# not reach the rim and latch (nothing would be left to kill).
		if not enemy.is_queued_for_deletion():
			enemy.advance(delta)
	_carousel.advance_rotation(delta, GameState.get_effective_spin_speed_rad_s())
	_carousel.set_boost_state(GameState.is_boost_maxed(), GameState.is_overdrive_active())


## Makes the mounts on the carousel match GameState's roster. Existing mounts
## are kept (so a Wolf keeps its hit memory); new ones are created and sold ones
## removed. Then everything is re-spaced evenly.
func _sync_mounts(roster: Array[StringName]) -> void:
	var spare_mounts := _mounts.duplicate()
	var spare_ids := _mount_ids.duplicate()
	var mounts: Array[MountBase] = []
	for id in roster:
		var index := spare_ids.find(id)
		if index >= 0:
			mounts.append(spare_mounts[index])
			spare_mounts.remove_at(index)
			spare_ids.remove_at(index)
		else:
			var mount := _create_mount(id)
			if mount != null:
				mounts.append(mount)
	for mount: MountBase in spare_mounts:
		mount.teardown()
		_mount_slots.remove_child(mount)
		mount.queue_free()
	_mounts = mounts
	_mount_ids = roster.duplicate()
	_layout_mounts()


func _create_mount(id: StringName) -> MountBase:
	var upgrade := UpgradeManager.get_definition(id)
	if upgrade == null or upgrade.mount_scene == null:
		push_error("No mount scene for %s" % id)
		return null
	var mount := upgrade.mount_scene.instantiate() as MountBase
	_mount_slots.add_child(mount)
	mount.setup(_carousel)
	# Every mount is wired the same way; a mount that never emits costs nothing.
	mount.booth_passed.connect(_on_booth_passed)
	mount.enemy_swept.connect(_on_enemy_swept)
	mount.set_enemy_layer(_enemy_layer)
	return mount


## Evenly spaced, first at the top. Moving is a jump, so it never pays Gold,
## and each mount rebases so moving onto an enemy isn't a free hit.
func _layout_mounts() -> void:
	for i in _mounts.size():
		_mounts[i].place(-PI / 2.0 + TAU * i / _mounts.size(), mount_radius)
	for mount in _mounts:
		mount.set_booth_bearings(_booth_bearings)
		mount.rebase()


## Makes exactly `count` booths, evenly spaced starting at the top. Moving a
## booth is a jump, not travel, so it never pays Gold.
func _layout_booths(count: int) -> void:
	while _booths.size() < count:
		var booth := _first_booth.duplicate() as TicketBooth
		_first_booth.get_parent().add_child(booth)
		_booths.append(booth)
	while _booths.size() > count and _booths.size() > 1:
		_booths.pop_back().queue_free()
	_booth_bearings.clear()
	for i in _booths.size():
		var bearing := -PI / 2.0 + TAU * i / _booths.size()
		# Whole pixels: from_angle(-PI/2) gives x ≈ 1e-14, not 0, which would sit a
		# hair off a Horse starting at the top and pay on the very first tick.
		_booths[i].position = (_carousel.position + Vector2.from_angle(bearing) * _booth_radius).round()
		_booths[i].reset_physics_interpolation()
		# Read the bearing back from the position, exactly as mounts read slot angles.
		_booth_bearings.append((_booths[i].position - _carousel.position).angle())
	for mount in _mounts:
		mount.set_booth_bearings(_booth_bearings)


func _on_booth_passed(mount: MountBase, booth_index: int, pass_count: int) -> void:
	GameState.add_gold(mount.data.base_gold_bonus * pass_count)
	_booths[booth_index].pop()
	AudioManager.play_sfx(&"coin")


func _on_enemy_spawned(enemy: EnemyBase) -> void:
	_enemy_layer.add_child(enemy)
	enemy.setup(_carousel.position, _carousel.radius)
	# Appearing is a jump, not travel: don't interpolate in from the origin.
	enemy.reset_physics_interpolation()
	enemy.reached_rim.connect(_on_enemy_reached_rim)
	enemy.died.connect(_on_enemy_died)
	_click_router.register_enemy(enemy)


func _on_enemy_clicked(enemy: EnemyBase) -> void:
	AudioManager.play_sfx(&"hit")
	# A killing click gets the kill pop from _on_enemy_died instead.
	if not enemy.take_damage(GameState.get_click_damage()):
		_spawn_pop(enemy.global_position, false)


## A ring where something happened: kill (red, bigger) or hit/clear (cream).
func _spawn_pop(global_point: Vector2, kill: bool) -> void:
	if _live_pops >= max_live_pops:
		return
	var pop := ClickPop.new()
	pop.color = kill_pop_color if kill else hit_pop_color
	if kill:
		pop.start_radius *= kill_pop_scale
		pop.end_radius *= kill_pop_scale
	pop.position = _world.to_local(global_point)
	_live_pops += 1
	pop.tree_exiting.connect(func() -> void: _live_pops -= 1)
	_world.add_child(pop)
	pop.reset_physics_interpolation()


## Damage first (from GameState, so upgrades count), then whatever else this
## mount's contact does. A mount with no damage (the Sloth, later) only gets
## apply_sweep().
func _on_enemy_swept(mount: MountBase, enemy: EnemyBase) -> void:
	var damage := GameState.get_mount_damage(mount.data)
	if damage > 0.0:
		AudioManager.play_sfx(&"wolf_hit")
		enemy.take_damage(damage)
	if enemy.can_receive_click():
		mount.apply_sweep(enemy)


## Latching: the enemy stays where it is in the world (the carousel turns
## underneath it) and GameState adds its drag and damage.
func _on_enemy_reached_rim(enemy: EnemyBase) -> void:
	AudioManager.play_sfx(&"latch")
	GameState.register_latch(enemy.get_instance_id(), enemy.data.latch_drag, enemy.data.damage_per_second)


## Runs once per enemy (EnemyBase guarantees it), so the kill pays once.
func _on_enemy_died(enemy: EnemyBase) -> void:
	GameState.add_gold(enemy.data.gold_drop * enemy.gold_multiplier)
	AudioManager.play_sfx(&"pop")
	_spawn_pop(enemy.global_position, true)
	_remove_enemy(enemy)


## TEMPORARY safety net: stalled too long, so every enemy is removed (no Gold).
## Waves keep coming.
func _on_stall_timed_out() -> void:
	for enemy: EnemyBase in _enemy_layer.get_children():
		_spawn_pop(enemy.global_position, false)
		_remove_enemy(enemy)


## Emergency Clear: every latched enemy is removed, with no Gold. Enemies still
## flying in stay.
func _on_emergency_cleared() -> void:
	AudioManager.play_sfx(&"restart")
	for enemy: EnemyBase in _enemy_layer.get_children():
		if enemy.is_at_rim():
			_spawn_pop(enemy.global_position, false)
			_remove_enemy(enemy)


func _remove_enemy(enemy: EnemyBase) -> void:
	GameState.unregister_latch(enemy.get_instance_id())
	_click_router.unregister_enemy(enemy)
	for mount in _mounts:
		mount.forget_enemy(enemy.get_instance_id())
	enemy.queue_free()


func _center_world() -> void:
	_world.position = get_viewport_rect().get_center()
	# A deliberate jump, not motion: don't let physics interpolation slide it.
	_world.reset_physics_interpolation()
