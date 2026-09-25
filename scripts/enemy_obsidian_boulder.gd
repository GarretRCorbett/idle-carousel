class_name EnemyObsidianBoulder
extends EnemyBoss
## The last tier boss (Charcoal): a big dark Rock that flies in and latches.
## Two stages (Garret, Q20): when it dies it splits into Rocks of the tier
## below (split_tier = Red), and every piece must die for the win.

@export_range(1, 6, 1) var split_count: int = 2
@export var split_scene: PackedScene = preload("res://scenes/enemies/Rock.tscn")
@export var split_data: EnemyData = preload("res://resources/enemies/rock.tres")
## Angle between the split Rocks, around where it was.
@export_range(0.0, 60.0, 1.0, "suffix:°") var split_spacing_deg: float = 16.0


func make_death_split() -> Array[EnemyBase]:
	var pieces: Array[EnemyBase] = []
	var offset := position - _center
	var bearing := offset.angle()
	var distance := maxf(offset.length(), _stop_distance)
	for i in split_count:
		var rock := split_scene.instantiate() as EnemyBase
		rock.data = split_data
		var angle := bearing + deg_to_rad(split_spacing_deg) * (i - (split_count - 1) / 2.0)
		rock.position = _center + Vector2.from_angle(angle) * distance
		pieces.append(rock)
	return pieces
