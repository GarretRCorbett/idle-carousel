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
## Direction from the center, radians.
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
	enemies.clear()
	bearings.clear()
	distances.clear()
	radii.clear()
	for child in layer.get_children():
		var enemy := child as EnemyBase
		if enemy == null or not enemy.is_active():
			continue
		var offset := enemy.global_position - center
		enemies.append(enemy)
		bearings.append(offset.angle())
		distances.append(offset.length())
		radii.append(enemy.data.hitbox_radius)


func size() -> int:
	return enemies.size()
