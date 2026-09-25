class_name EnemyBoulder
extends EnemyBoss
## The Yellow boss: a big Rock that rolls faster as it nears the carousel.
## When it reaches the rim it breaks into 3 grips: three ordinary enemies
## latched side by side, each with a third of the health it had left (hits on
## the way in count) and a third of its drag, so the drag drops as each grip
## breaks. All three must die for the win (Garret, Q19). Three plain latches
## instead of one enemy latched at three points: every rule already works.

## Near the rim it rolls up to this many times its tier speed...
@export_range(1.0, 5.0, 0.1) var roll_max_multiplier: float = 2.5
## ...ramping up over this last stretch before the rim.
@export_range(10.0, 400.0, 1.0, "suffix:px") var roll_ramp_px: float = 200.0
@export var grip_scene: PackedScene = preload("res://scenes/enemies/Rock.tscn")
## A grip's own stats (its drag and latch damage are a third of the Boulder's).
@export var grip_data: EnemyData = preload("res://resources/enemies/boulder_grip.tres")
@export_range(1, 6, 1) var grip_count: int = 3
## Angle between neighbouring grips on the rim.
@export_range(0.0, 45.0, 1.0, "suffix:°") var grip_spacing_deg: float = 13.0

## Health left when it broke, shared by the grips.
var _health_at_break: float = 0.0


## Rolls toward the rim; instead of latching, breaks into its grips.
func advance(delta: float) -> void:
	if not is_active() or delta <= 0.0:
		return
	var speed_factor := _advance_status(delta)
	var offset := position - _center
	var distance := offset.length()
	var travel := get_move_speed() * speed_factor * _speed_multiplier() * delta
	_visual.rotation += travel / maxf(1.0, get_hitbox_radius())
	if distance - travel > _stop_distance:
		position -= offset / distance * travel
		return
	position = _center + offset.normalized() * _stop_distance
	_break_into_grips()


func _speed_multiplier() -> float:
	var distance := (position - _center).length()
	var closeness := clampf(1.0 - (distance - _stop_distance) / roll_ramp_px, 0.0, 1.0)
	return lerpf(1.0, roll_max_multiplier, closeness)


## The body's part ends here: it "dies" into its grips (no reward, no kill
## credit, like every boss piece), and BossEncounter adds them as REQUIRED.
func _break_into_grips() -> void:
	_health_at_break = get_health()
	take_damage(get_health(), self)


func make_death_split() -> Array[EnemyBase]:
	var grips: Array[EnemyBase] = []
	# Killed before it reached the rim: nothing left to grip with.
	if _health_at_break <= 0.0:
		return grips
	var bearing := (position - _center).angle()
	var rim := _stop_distance - get_hitbox_radius()
	for i in grip_count:
		var grip := grip_scene.instantiate() as EnemyBase
		grip.data = grip_data
		grip.max_health_override = _health_at_break / grip_count
		var angle := bearing + deg_to_rad(grip_spacing_deg) * (i - (grip_count - 1) / 2.0)
		grip.position = _center + Vector2.from_angle(angle) * (rim + grip_data.hitbox_radius)
		grips.append(grip)
	return grips


func get_health_at_break() -> float:
	return _health_at_break
