class_name EnemyAncientLog
extends EnemyBoss
## The Red boss: a huge, slow log. Immune to slow (EnemyData.immune_to_slow)
## and its bark blunts the first few hits: each of the first `armor_hits`
## hits (click or mount) does only `armor_damage_multiplier` of its damage
## (Garret, Q18). Rings drawn on it show the hits left. Latches like a Stick.

@export_range(0, 10, 1) var armor_hits: int = 3
@export_range(0.0, 1.0, 0.05) var armor_damage_multiplier: float = 0.25
@export var bark_ring_color: Color = Color(0.95, 0.85, 0.6, 0.9)

var _armor_left: int = 0


func _ready() -> void:
	super._ready()
	_armor_left = armor_hits


func take_damage(amount: float, source: Node = null) -> bool:
	if _armor_left > 0 and is_active() and is_finite(amount) and amount > 0.0:
		_armor_left -= 1
		amount *= armor_damage_multiplier
		queue_redraw()
	return super.take_damage(amount, source)


func get_armor_left() -> int:
	return _armor_left


## One ring per blunted hit still to come.
func _draw() -> void:
	var size := data.placeholder_size if data != null else 40.0
	for i in _armor_left:
		draw_arc(Vector2.ZERO, size * (0.55 + 0.14 * i), 0.0, TAU, 32, bark_ring_color, 2.5, true)
