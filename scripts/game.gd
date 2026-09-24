class_name Game
extends Node2D
## Root of the play scene. Starts a fresh run and keeps the world centered.
## From Step 3 on, this is the single place that drives the simulation each tick.

@onready var _world: Node2D = $World


func _ready() -> void:
	GameState.reset_run()
	get_viewport().size_changed.connect(_center_world)
	_center_world()


func _center_world() -> void:
	_world.position = get_viewport_rect().get_center()
