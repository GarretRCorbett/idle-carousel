class_name Game
extends Node2D
## Root of the play scene. Starts a fresh run and keeps the world centered.
## This is the single place that drives the simulation each tick, so the order
## is explicit: spawns from last tick join first, then GameState (boost decay,
## income window, latch damage), then enemies move, then one snapshot of where they are, then the carousel
## turns at the resulting speed and mounts sweep against that snapshot.

## Distance of mounts from the carousel center. Mounts space themselves evenly
## around this circle, the first one at the top (where the first booth is).
@export_range(10.0, 400.0, 1.0, "suffix:px") var mount_radius: float = 75.0
## Every color tier. Waves come from the selected one (Grey until Step 6's picker).
@export var tier_catalog: TierCatalog = preload("res://resources/tiers/tier_catalog.tres")

@export_group("Dev keys")
## Debug builds only: previous / next tier, unlocking it if needed (the boss
## strip's tier pips are the real way to switch).
@export var previous_tier_key: Key = KEY_F2
@export var next_tier_key: Key = KEY_F3

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
## Every live enemy's bearing and distance, measured once per tick for all mounts.
var _snapshot := EnemySnapshot.new()
## Enemies spawned since the last tick. They join at the start of the next one,
## so an enemy spawned mid-tick (later: splits, summons) never moves, latches,
## or gets hit in the tick it appeared.
var _pending_spawns: Array[EnemyBase] = []
## Enemies in play (admitted and not removed). The Send limit counts these
## plus the queue.
var _live_enemy_count: int = 0
## Runs boss fights (created here; ticked in _physics_process).
var _encounter: BossEncounter


func _ready() -> void:
	_booth_radius = (_first_booth.position - _carousel.position).length()
	_booths.append(_first_booth)
	_hud.boost_requested.connect(GameState.add_click_boost)
	_click_router.enemy_clicked.connect(_on_enemy_clicked)
	_encounter = BossEncounter.new()
	_encounter.name = "BossEncounter"
	add_child(_encounter)
	_encounter.enemy_spawn_requested.connect(_on_enemy_spawned)
	_encounter.enemy_removal_requested.connect(_remove_encounter_enemy)
	_encounter.started.connect(func(_rank: int) -> void: _wave_manager.set_suspended(true))
	_encounter.ended.connect(func(_victory: bool, _first: bool) -> void: _wave_manager.set_suspended(false))
	GameState.run_reset.connect(_encounter.reset)
	_wave_manager.center = _carousel.position
	_wave_manager.tier = tier_catalog.get_tier(0)
	_wave_manager.tier_kills = func() -> int: return GameState.get_tier_kills(GameState.get_selected_tier())
	GameState.selected_tier_changed.connect(_on_selected_tier_changed)
	_wave_manager.live_enemy_count = get_live_enemy_count
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
	GameState.run_reset.connect(_discard_pending_spawns)
	GameState.upgrade_applied.connect(_on_upgrade_applied)
	GameState.reset_run()
	_layout_booths(GameState.get_booth_count())
	_sync_mounts(GameState.get_mount_roster())
	get_viewport().size_changed.connect(_center_world)
	_center_world()
	_wave_manager.start(GameState.get_run_seed())


## Esc opens Settings (which pauses the game; Esc again closes it).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and not _options.visible:
		_options.open()
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and OS.is_debug_build():
		var step := 0
		if key.keycode == previous_tier_key:
			step = -1
		elif key.keycode == next_tier_key:
			step = 1
		if step != 0:
			var rank := clampi(GameState.get_selected_tier() + step, 0, tier_catalog.tiers.size() - 1)
			GameState.debug_set_bosses_beaten(rank)  # dev keys may skip ahead
			GameState.set_selected_tier(rank)
			get_viewport().set_input_as_handled()


## New waves come from the selected tier; enemies already alive keep their stats.
func _on_selected_tier_changed(rank: int) -> void:
	var tier := tier_catalog.get_tier(rank)
	if tier != null:
		_wave_manager.tier = tier


func _exit_tree() -> void:
	_discard_pending_spawns()


func _physics_process(delta: float) -> void:
	_admit_pending_spawns()
	GameState.advance_simulation(delta)
	for enemy: EnemyBase in _enemy_layer.get_children():
		# The stall safety net may have just removed it; a removed enemy must
		# not reach the rim and latch (nothing would be left to kill).
		if enemy.is_active():
			enemy.advance(delta)
	_encounter.advance(delta)
	_snapshot.rebuild(_enemy_layer, _carousel.global_position)
	_carousel.advance_rotation(delta, GameState.get_effective_spin_speed_rad_s())
	_carousel.set_boost_state(GameState.is_boost_maxed(), GameState.is_overdrive_active())


## A mount tier can change reach or wedge width. Rebase every mount at once,
## so an enemy that just came into reach isn't a free hit.
func _on_upgrade_applied(id: StringName, _level: int) -> void:
	var upgrade := UpgradeManager.get_definition(id)
	if upgrade != null and upgrade.effect_type == UpgradeData.EffectType.MOUNT_TIER:
		_layout_mounts()


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
	mount.gold_earned.connect(_on_mount_gold_earned)
	mount.set_enemy_snapshot(_snapshot)
	return mount


## Evenly spaced, first at the top. Moving is a jump, so it never pays Gold,
## and each mount rebases so moving onto an enemy isn't a free hit.
func _layout_mounts() -> void:
	# Rebase against where enemies are now, not where they were last tick.
	_snapshot.rebuild(_enemy_layer, _carousel.global_position)
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


func _on_mount_gold_earned(_mount: MountBase, amount: float) -> void:
	GameState.add_gold(amount)
	AudioManager.play_sfx(&"coin")


func _on_booth_passed(mount: MountBase, booth_index: int, pass_count: int) -> void:
	GameState.add_gold(GameState.get_mount_gold(mount.data) * pass_count)
	_booths[booth_index].pop()
	AudioManager.play_sfx(&"coin")


## Starts the selected tier's boss fight, if its kill gate is met (the
## strip's Challenge button). Returns false if it can't start now.
func challenge_boss() -> bool:
	return _encounter.start(tier_catalog.get_tier(GameState.get_selected_tier()))


## Ends a running boss fight (the strip's two-step Give up).
func give_up_boss() -> void:
	_encounter.give_up()


func get_encounter() -> BossEncounter:
	return _encounter


## Enemies in play plus those waiting to join. Given to WaveManager for the
## Send limit, so several presses within one tick can't get past it.
func get_live_enemy_count() -> int:
	return _live_enemy_count + _pending_spawns.size()


func _on_enemy_spawned(enemy: EnemyBase) -> void:
	_pending_spawns.append(enemy)


## Admits this tick's batch. Anything spawned while admitting waits for the next.
func _admit_pending_spawns() -> void:
	if _pending_spawns.is_empty():
		return
	var batch := _pending_spawns
	_pending_spawns = []
	for enemy in batch:
		_admit_enemy(enemy)


func _admit_enemy(enemy: EnemyBase) -> void:
	_live_enemy_count += 1
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
		AudioManager.play_sfx(mount.data.hit_sfx)
		enemy.take_damage(damage, mount)
	if enemy.is_active():
		mount.apply_sweep(enemy)


## Latching: the enemy stays where it is in the world (the carousel turns
## underneath it) and GameState adds its drag and damage.
func _on_enemy_reached_rim(enemy: EnemyBase) -> void:
	AudioManager.play_sfx(&"latch")
	# A boss fight's required enemies can't be removed by Emergency Clear.
	var protected := enemy.encounter_role == EnemyBase.EncounterRole.REQUIRED
	GameState.register_latch(enemy.get_instance_id(), enemy.get_latch_drag(), enemy.get_latch_dps(), protected)


## Runs once per enemy (EnemyBase guarantees it), so the kill pays once.
## killer is the mount that landed the lethal hit (null for a click): a
## healing mount (the Panda) heals only on its own kills.
func _on_enemy_died(enemy: EnemyBase, killer: Node) -> void:
	# Boss-fight enemies pay nothing and don't count toward the kill gate.
	if enemy.gives_rewards():
		GameState.add_gold(enemy.get_kill_gold())
		GameState.record_kill(enemy.get_tier_rank())
	var mount := killer as MountBase
	if mount != null and mount.data != null:
		GameState.heal_carousel(GameState.get_mount_heal(mount.data))
	AudioManager.play_sfx(&"pop")
	_spawn_pop(enemy.global_position, true)
	_remove_enemy(enemy)


## TEMPORARY safety net: stalled too long, so every enemy is removed (no Gold).
## Waves keep coming.
func _on_stall_timed_out() -> void:
	for enemy: EnemyBase in _enemy_layer.get_children():
		if not enemy.is_active():
			continue
		_spawn_pop(enemy.global_position, false)
		_remove_enemy(enemy)


## Emergency Clear: every latched enemy is removed, with no Gold. Enemies still
## flying in stay.
func _on_emergency_cleared() -> void:
	AudioManager.play_sfx(&"restart")
	for enemy: EnemyBase in _enemy_layer.get_children():
		if enemy.is_active() and enemy.is_at_rim() and not GameState.is_latch_protected(enemy.get_instance_id()):
			_spawn_pop(enemy.global_position, false)
			_remove_enemy(enemy)


## Takes an enemy out of the world. Marking it removed comes first, before the
## latch signals below can reach a listener that might touch it. A second call
## does nothing.
func _remove_enemy(enemy: EnemyBase) -> void:
	if not enemy.mark_removed():
		return
	_live_enemy_count -= 1
	GameState.unregister_latch(enemy.get_instance_id())
	_click_router.unregister_enemy(enemy)
	for mount in _mounts:
		mount.forget_enemy(enemy.get_instance_id())
	enemy.queue_free()


## A boss fight is over: its enemies leave with no rewards. One still waiting
## to join is just dropped.
func _remove_encounter_enemy(enemy: EnemyBase) -> void:
	var index := _pending_spawns.find(enemy)
	if index >= 0:
		_pending_spawns.remove_at(index)
		enemy.free()
		return
	if is_instance_valid(enemy) and enemy.is_inside_tree():
		_spawn_pop(enemy.global_position, false)
		_remove_enemy(enemy)


## Frees enemies that were waiting to join (a new run, or leaving the scene).
func _discard_pending_spawns() -> void:
	for enemy in _pending_spawns:
		if is_instance_valid(enemy):
			enemy.free()
	_pending_spawns.clear()


func _center_world() -> void:
	_world.position = get_viewport_rect().get_center()
	# A deliberate jump, not motion: don't let physics interpolation slide it.
	_world.reset_physics_interpolation()
