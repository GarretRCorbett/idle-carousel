class_name Game
extends Node2D
## Root of the play scene. Starts a fresh run and keeps the world centered.
## This is the single place that drives the simulation each tick, so the order
## is explicit: GameState first (boost decay, income window, later latch damage),
## then enemies move, then the carousel moves at the resulting speed.

@onready var _world: Node2D = $World
@onready var _carousel: Carousel = $World/Carousel
@onready var _hud: Hud = $HUD
@onready var _mount_slots: Node2D = $World/Carousel/MountSlots
## The booth placed in the scene; extra booths are copies of it.
@onready var _first_booth: TicketBooth = $World/TicketBooth
@onready var _enemy_layer: Node2D = $World/EnemyLayer
@onready var _click_router: ClickRouter = $World/ClickRouter
@onready var _wave_manager: WaveManager = $WaveManager

var _booths: Array[TicketBooth] = []
var _horses: Array[MountHorse] = []
## Booth distance from the carousel center, taken from the scene's booth.
var _booth_radius: float = 0.0


func _ready() -> void:
	_booth_radius = (_first_booth.position - _carousel.position).length()
	_booths.append(_first_booth)
	_hud.boost_requested.connect(GameState.add_click_boost)
	_click_router.enemy_clicked.connect(_on_enemy_clicked)
	_wave_manager.center = _carousel.position
	_wave_manager.enemy_spawned.connect(_on_enemy_spawned)
	GameState.booth_count_changed.connect(_layout_booths)
	_setup_mounts()
	GameState.reset_run()
	_layout_booths(GameState.get_booth_count())
	get_viewport().size_changed.connect(_center_world)
	_center_world()


func _physics_process(delta: float) -> void:
	GameState.advance_simulation(delta)
	for enemy: EnemyBase in _enemy_layer.get_children():
		enemy.advance(delta)
	_carousel.advance_rotation(delta, GameState.get_effective_spin_speed_rad_s())
	_carousel.set_boost_state(GameState.is_boost_maxed(), GameState.is_overdrive_active())


func _setup_mounts() -> void:
	for slot in _mount_slots.get_children():
		for mount in slot.get_children():
			if mount is MountBase:
				mount.setup(_carousel)
			if mount is MountHorse:
				_horses.append(mount)
				mount.booth_passed.connect(_on_booth_passed)


## Makes exactly `count` booths, evenly spaced starting at the top. Moving a
## booth is a jump, not travel, so it never pays Gold.
func _layout_booths(count: int) -> void:
	while _booths.size() < count:
		var booth := _first_booth.duplicate() as TicketBooth
		_first_booth.get_parent().add_child(booth)
		_booths.append(booth)
	while _booths.size() > count and _booths.size() > 1:
		_booths.pop_back().queue_free()
	var bearings: Array[float] = []
	for i in _booths.size():
		var bearing := -PI / 2.0 + TAU * i / _booths.size()
		# Whole pixels: from_angle(-PI/2) gives x ≈ 1e-14, not 0, which would sit a
		# hair off a Horse starting at the top and pay on the very first tick.
		_booths[i].position = (_carousel.position + Vector2.from_angle(bearing) * _booth_radius).round()
		_booths[i].reset_physics_interpolation()
		# Read the bearing back from the position, exactly as mounts read slot angles.
		bearings.append((_booths[i].position - _carousel.position).angle())
	for horse in _horses:
		horse.set_booth_bearings(bearings)


func _on_booth_passed(horse: MountHorse, booth_index: int, pass_count: int) -> void:
	GameState.add_gold(horse.data.base_gold_bonus * pass_count)
	_booths[booth_index].pop()


func _on_enemy_spawned(enemy: EnemyBase) -> void:
	_enemy_layer.add_child(enemy)
	enemy.setup(_carousel.position, _carousel.radius)
	# Appearing is a jump, not travel: don't interpolate in from the origin.
	enemy.reset_physics_interpolation()
	enemy.died.connect(_on_enemy_died)
	_click_router.register_enemy(enemy)


func _on_enemy_clicked(enemy: EnemyBase) -> void:
	enemy.take_damage(GameState.get_click_damage())


## Runs once per enemy (EnemyBase guarantees it), so the kill pays once.
func _on_enemy_died(enemy: EnemyBase) -> void:
	GameState.add_gold(enemy.data.gold_drop)
	_click_router.unregister_enemy(enemy)
	enemy.queue_free()


func _center_world() -> void:
	_world.position = get_viewport_rect().get_center()
	# A deliberate jump, not motion: don't let physics interpolation slide it.
	_world.reset_physics_interpolation()
