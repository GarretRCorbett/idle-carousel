class_name EnemyData
extends Resource
## Base stats for one enemy type. One .tres per type in res://resources/enemies/.
## These are Grey-tier (tier 1) values; color tiers scale them later.

@export var enemy_name: String = ""

@export_group("Combat")
## Approach speed toward the carousel, in pixels per second.
@export_range(0.0, 1000.0, 1.0, "or_greater", "suffix:px/s") var move_speed: float = 50.0
## Hit points. A base_damage 1.0 hit removes 1.
@export_range(0.1, 10000.0, 0.1, "or_greater") var base_health: float = 1.0
## Carousel health lost per second while latched.
@export_range(0.0, 100.0, 0.1, "or_greater") var damage_per_second: float = 1.0
## Fraction of spin speed this enemy removes while latched (0.1 = 10% slower).
@export_range(0.0, 1.0, 0.01) var latch_drag: float = 0.1

@export_group("Economy")
## Gold awarded on kill.
@export_range(0.0, 10000.0, 0.1, "or_greater") var gold_drop: float = 1.0

@export_group("Placeholder Visuals")
## Fill color of the code-drawn placeholder polygon.
@export var placeholder_color: Color = Color.WHITE
## Vertex count of the placeholder polygon.
@export_range(3, 32, 1) var placeholder_points: int = 6
## Radius of the placeholder polygon, in pixels.
@export_range(1.0, 128.0, 1.0, "suffix:px") var placeholder_size: float = 12.0
## Real sprite. Leave empty to draw the placeholder polygon instead.
@export var texture: Texture2D = null
