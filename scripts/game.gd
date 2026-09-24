class_name Game
extends Node2D
## Root of the play scene. Starts a fresh run and keeps the world centered.
## This is the single place that drives the simulation each tick, so the order
## is explicit: GameState first (boost decay, later income and latch damage),
## then the carousel moves at the resulting speed.

@onready var _world: Node2D = $World
@onready var _carousel: Carousel = $World/Carousel
@onready var _click_router: ClickRouter = $World/ClickLayer


func _ready() -> void:
	GameState.reset_run()
	_click_router.play_area_click_requested.connect(GameState.add_click_boost)
	get_viewport().size_changed.connect(_center_world)
	_center_world()


func _physics_process(delta: float) -> void:
	GameState.advance_simulation(delta)
	_carousel.advance_rotation(delta, GameState.get_effective_spin_speed_rad_s())


func _center_world() -> void:
	_world.position = get_viewport_rect().get_center()
