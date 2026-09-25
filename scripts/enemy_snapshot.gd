class_name EnemySnapshot
extends RefCounted
## Where every live enemy is this tick, measured once from the carousel center.
## Game rebuilds it each tick after enemies move and before the carousel turns;
## every sweeping mount reads it instead of scanning the enemy layer and
## redoing the same square roots and angles itself.
##
## An entry can go stale within the tick (an earlier mount killed it), so
## readers recheck the enemy before acting on it.

var enemies: Array[EnemyBase] = []
## Direction from the center, radians, unwrapped (see EnemyBase.update_bearing),
## so a sweep's pass numbers stay the same when an enemy crosses ±180°.
var bearings := PackedFloat64Array()
## Distance from the center, pixels.
var distances := PackedFloat64Array()
## Hitbox radius, pixels.
var radii := PackedFloat64Array()
## The carousel center these were measured from, World space.
var center: Vector2 = Vector2.ZERO


## Measures every live enemy in `layer` from `from_center`.
func rebuild(layer: Node, from_center: Vector2) -> void:
	center = from_center
	# Sized once for every child, then trimmed: cheaper than growing four
	# arrays one enemy at a time, every tick.
	var children := layer.get_children()
	enemies.resize(children.size())
	bearings.resize(children.size())
	distances.resize(children.size())
	radii.resize(children.size())
	var count := 0
	for child in children:
		var enemy := child as EnemyBase
		if enemy == null or not enemy.is_active():
			continue
		var offset := enemy.global_position - center
		enemies[count] = enemy
		bearings[count] = enemy.update_bearing(offset.angle())
		distances[count] = offset.length()
		radii[count] = enemy.get_hitbox_radius()
		count += 1
	enemies.resize(count)
	bearings.resize(count)
	distances.resize(count)
	radii.resize(count)


func size() -> int:
	return enemies.size()
