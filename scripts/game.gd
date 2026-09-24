class_name Game
extends Node2D
## Root of the play scene. Starts a fresh run and keeps the world centered.
## This is the single place that drives the simulation each tick, so the order
## is explicit: GameState first (boost decay, income window, later latch damage),
## then the carousel moves at the resulting speed.

@onready var _world: Node2D = $World
@onready var _carousel: Carousel = $World/Carousel
@onready var _hud: Hud = $HUD
@onready var _booth: TicketBooth = $World/TicketBooth
@onready var _mount_slots: Node2D = $World/Carousel/MountSlots


func _ready() -> void:
	GameState.reset_run()
	_hud.boost_requested.connect(_on_boost_requested)
	_setup_mounts()
	get_viewport().size_changed.connect(_center_world)
	_center_world()


func _physics_process(delta: float) -> void:
	GameState.advance_simulation(delta)
	_carousel.advance_rotation(delta, GameState.get_effective_spin_speed_rad_s())


func _setup_mounts() -> void:
	var booth_bearing := (_booth.position - _carousel.position).angle()
	for slot in _mount_slots.get_children():
		for mount in slot.get_children():
			if mount is MountBase:
				mount.setup(_carousel)
			if mount is MountHorse:
				mount.set_booth_bearing(booth_bearing)
				mount.booth_passed.connect(_on_booth_passed)


func _on_boost_requested() -> void:
	GameState.add_click_boost()
	_carousel.pulse()


func _on_booth_passed(horse: MountHorse, pass_count: int) -> void:
	GameState.add_gold(horse.data.base_gold_bonus * pass_count)
	_booth.pop()


func _center_world() -> void:
	_world.position = get_viewport_rect().get_center()
	# A deliberate jump, not motion: don't let physics interpolation slide it.
	_world.reset_physics_interpolation()
