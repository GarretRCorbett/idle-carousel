class_name RunConfig
extends Resource
## Starting values and tuning for one run. The live copy is
## res://resources/config/run_config.tres; edit it in the Inspector.
## GameState reads it on reset_run(), so changes apply to the next run.

@export_group("Economy")
## Gold the player has when a run starts.
@export_range(0.0, 1000000.0, 1.0, "or_greater") var starting_gold: float = 0.0

@export_group("Carousel")
## Carousel health when a run starts (and its maximum).
@export_range(1.0, 100000.0, 1.0, "or_greater") var max_health: float = 100.0


## Returns a list of problems; empty means the config is usable.
func get_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	if not is_finite(starting_gold) or starting_gold < 0.0:
		problems.append("starting_gold must be a finite number >= 0")
	if not is_finite(max_health) or max_health <= 0.0:
		problems.append("max_health must be a finite number > 0")
	return problems
