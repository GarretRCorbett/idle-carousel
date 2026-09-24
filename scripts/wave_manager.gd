class_name WaveManager
extends Node
## Sends waves of enemies. A wave is one cluster from a random direction,
## spread a little sideways and staggered outward so they arrive one after
## another. It only creates enemies; Game adds them to the world and wires them.

signal enemy_spawned(enemy: EnemyBase)

@export var enemy_scene: PackedScene

@export_group("Wave Shape")
@export_range(1, 50, 1) var min_group: int = 3
@export_range(1, 50, 1) var max_group: int = 5
## Distance from the carousel center where enemies appear (just off-screen).
@export_range(100.0, 2000.0, 1.0, "suffix:px") var spawn_radius: float = 380.0
## Each enemy's direction is within ± this of the wave's direction.
@export_range(0.0, 180.0, 1.0, "suffix:°") var cluster_spread_deg: float = 20.0
## Each enemy starts up to this much further out, so they don't arrive stacked.
@export_range(0.0, 500.0, 1.0, "suffix:px") var cluster_depth_px: float = 60.0

@export_group("Debug")
## Debug builds only: this key sends a wave right away.
@export var debug_wave_key: Key = KEY_N

## Where the carousel center is, in World space. Set by Game.
var center: Vector2 = Vector2.ZERO
var rng := RandomNumberGenerator.new()


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == debug_wave_key:
		spawn_wave()
		get_viewport().set_input_as_handled()


## Creates one wave and announces each enemy. Returns how many were sent.
func spawn_wave() -> int:
	var positions := plan_wave(rng, center, min_group, max_group,
			spawn_radius, deg_to_rad(cluster_spread_deg), cluster_depth_px)
	for spawn_position in positions:
		var enemy := enemy_scene.instantiate() as EnemyBase
		enemy.position = spawn_position
		enemy_spawned.emit(enemy)
	return positions.size()


## Start positions for one wave: min..max enemies clustered around one random
## direction. Pure math, so tests can check it with a seeded RNG.
static func plan_wave(random: RandomNumberGenerator, wave_center: Vector2,
		group_min: int, group_max: int, radius: float,
		spread_rad: float, depth: float) -> PackedVector2Array:
	var positions := PackedVector2Array()
	var count := random.randi_range(mini(group_min, group_max), maxi(group_min, group_max))
	var bearing := random.randf_range(-PI, PI)
	for i in count:
		var direction := bearing + random.randf_range(-spread_rad, spread_rad)
		var distance := radius + random.randf_range(0.0, depth)
		positions.append(wave_center + Vector2.from_angle(direction) * distance)
	return positions
