class_name MountData
extends Resource
## Stats for one mount type. One .tres per mount in res://resources/mounts/.
## Balance changes happen here in the Inspector, not in mount scripts.

@export var mount_name: String = ""
## Stationary mounts trigger once per rotation at a target point (Horse, Sloth).
## Sweeping mounts fire outward continuously as the carousel turns.
@export var is_stationary: bool = false

@export_group("Combat")
## How far the sweep reaches outward from the mount, in pixels. 0 = no sweep.
@export_range(0.0, 1000.0, 1.0, "or_greater", "suffix:px") var sweep_range: float = 0.0
## Width of the sweep in degrees. 0 = a single ray; wider arcs hit more enemies.
@export_range(0.0, 360.0, 1.0, "suffix:°") var sweep_arc: float = 0.0
## Damage per hit. Fixed per hit: faster spin means more hits per minute (GDD v1.4).
@export_range(0.0, 100.0, 0.05, "or_greater") var base_damage: float = 0.0

@export_group("Economy")
## Gold per trigger (booth pass or sweep). Fixed per trigger: faster spin means
## more triggers per minute, not more Gold per trigger (GDD v1.4).
@export_range(0.0, 1000.0, 0.1, "or_greater") var base_gold_bonus: float = 0.0
## Gold cost to unlock this mount. 0 = available from the start.
@export_range(0, 1000000, 1, "or_greater") var unlock_cost_gold: int = 0

@export_group("Placeholder Visuals")
## Fill color of the code-drawn placeholder polygon.
@export var placeholder_color: Color = Color.WHITE
## Vertex count of the placeholder polygon.
@export_range(3, 32, 1) var placeholder_points: int = 6
## Radius of the placeholder polygon, in pixels.
@export_range(1.0, 128.0, 1.0, "suffix:px") var placeholder_size: float = 16.0
## Real sprite. Leave empty to draw the placeholder polygon instead.
@export var texture: Texture2D = null
