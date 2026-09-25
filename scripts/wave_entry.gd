class_name WaveEntry
extends Resource
## One enemy type a tier's waves can contain, with its odds and limits.
## Lives inside a WaveProfile.

@export var enemy_scene: PackedScene
## Relative odds against the other entries that can still be picked (not a percentage).
@export_range(0.0, 1000.0, 0.1, "or_greater") var weight: float = 1.0
## At most this many per wave. 0 = no limit.
@export_range(0, 100, 1, "or_greater") var max_per_wave: int = 0
## Kills in this tier before this enemy can appear. 0 = from the start.
@export_range(0, 10000, 1, "or_greater") var unlock_after_kills: int = 0


## Can fill any number of slots from the start: unlocked, pickable, no cap.
func is_filler() -> bool:
	return unlock_after_kills == 0 and weight > 0.0 and max_per_wave == 0
