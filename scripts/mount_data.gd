class_name MountData
extends Resource
## Stats for one mount type. One .tres per mount in res://resources/mounts/.
## Balance changes happen here in the Inspector, not in mount scripts.

@export var mount_name: String = ""
## Matches the shop's upgrade id for this mount (&"wolf", &"horse", ...), so
## upgrades that target a mount type (Wolf Fang) find it. Don't rename after release.
@export var mount_id: StringName = &""

@export_group("Combat")
## How far the sweep reaches outward from the mount, in pixels. 0 = no sweep.
@export_range(0.0, 1000.0, 1.0, "or_greater", "suffix:px") var sweep_range: float = 0.0
## Width of the sweep in degrees (a wedge centered on the carousel). 0 = a line.
## A wider wedge reaches enemies sooner, not more often (each is hit once per pass).
@export_range(0.0, 360.0, 1.0, "suffix:°") var sweep_arc: float = 0.0
## Damage per hit. Fixed per hit: faster spin means more hits per minute (GDD v1.4).
@export_range(0.0, 100.0, 0.05, "or_greater") var base_damage: float = 0.0
## Sound Game plays when this mount's hit deals damage (an id in the sound bank).
@export var hit_sfx: StringName = &"wolf_hit"

@export_group("All-rounder")
## Gold paid once per full turn of the carousel (Panda). 0 = none.
@export_range(0.0, 1000.0, 0.1, "or_greater") var gold_per_turn: float = 0.0
## Carousel health restored when this mount lands a killing hit (Panda). 0 = none.
@export_range(0.0, 100.0, 0.1, "or_greater") var heal_per_kill: float = 0.0

@export_group("Status")
## Slowing mounts (Sloth): speed multiplier on enemies it passes (0.5 = half speed).
@export_range(0.0, 1.0, 0.05) var slow_multiplier: float = 1.0
## How long the slow lasts, in seconds. 0 = no slow.
@export_range(0.0, 30.0, 0.1, "suffix:s") var slow_seconds: float = 0.0

@export_group("Economy")
## Gold per trigger (booth pass or sweep). Fixed per trigger: faster spin means
## more triggers per minute, not more Gold per trigger (GDD v1.4).
@export_range(0.0, 1000.0, 0.1, "or_greater") var base_gold_bonus: float = 0.0

@export_group("Levels")
## What each level of this type's track adds (GDD v1.17, Mount Levels and
## Stars), for every mount of the type. Damage is flat per hit; the others are
## fractions of the base value (0.15 = +15% per level). 0 = unchanged.
@export_range(0.0, 100.0, 0.05, "or_greater") var level_damage_bonus: float = 0.0
@export_range(0.0, 1.0, 0.01) var level_reach_bonus: float = 0.0
@export_range(0.0, 1.0, 0.01) var level_arc_bonus: float = 0.0
@export_range(0.0, 1.0, 0.01) var level_gold_bonus: float = 0.0
@export_range(0.0, 1.0, 0.01) var level_slow_seconds_bonus: float = 0.0
@export_range(0.0, 1.0, 0.01) var level_heal_bonus: float = 0.0

@export_group("Star 2")
## What the ★2 star-up multiplies, for every mount of the type
## (GameState.get_mount_* apply them). 1 = unchanged.
@export_range(0.1, 10.0, 0.05) var star2_damage_multiplier: float = 1.0
@export_range(0.1, 10.0, 0.05) var star2_reach_multiplier: float = 1.0
@export_range(0.1, 10.0, 0.05) var star2_arc_multiplier: float = 1.0
@export_range(0.1, 10.0, 0.05) var star2_gold_multiplier: float = 1.0
@export_range(0.1, 10.0, 0.05) var star2_slow_seconds_multiplier: float = 1.0
@export_range(0.1, 10.0, 0.05) var star2_heal_multiplier: float = 1.0

@export_group("Placeholder Visuals")
## Fill color of the code-drawn placeholder polygon.
@export var placeholder_color: Color = Color.WHITE
## Vertex count of the placeholder polygon.
@export_range(3, 32, 1) var placeholder_points: int = 6
## Radius of the placeholder polygon, in pixels.
@export_range(1.0, 128.0, 1.0, "suffix:px") var placeholder_size: float = 16.0
## Real sprite. Leave empty to draw the placeholder polygon instead.
@export var texture: Texture2D = null
## The sprite's silhouette grown a few pixels, in white, drawn behind it so the
## mount stands out from the canopy (built by tools/make_mount_outlines.gd).
@export var outline_texture: Texture2D = null
## Outline tint: a dark shade of the animal, like the enemy tier outlines.
## Alpha 0 = no outline.
@export var outline_color: Color = Color(0.1, 0.08, 0.12, 1.0)
