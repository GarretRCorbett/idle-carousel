class_name RunConfig
extends Resource
## Starting values and tuning for one run. The live copy is
## res://resources/config/run_config.tres; edit it in the Inspector.
## GameState reads it on reset_run(), so changes apply to the next run.

@export_group("Economy")
## Gold the player has when a run starts.
@export_range(0.0, 1000000.0, 1.0, "or_greater") var starting_gold: float = 0.0
## Gold/sec on the HUD is actual Gold earned over the last
## (income_bucket_count × income_bucket_seconds) seconds, about 10 s.
@export_range(0.1, 10.0, 0.1, "suffix:s") var income_bucket_seconds: float = 1.0
@export_range(1, 120, 1) var income_bucket_count: int = 10

@export_group("Carousel")
## Carousel health when a run starts (and its maximum).
@export_range(1.0, 100000.0, 1.0, "or_greater") var max_health: float = 100.0

@export_group("Spin")
## Base spin before upgrades, boost, and drag. 45 = one turn every 8 seconds.
@export_range(1.0, 720.0, 1.0, "or_greater", "suffix:°/s") var base_spin_speed_deg_s: float = 45.0
## Max boost before Boost Power upgrades (0.5 = +50% speed at a full bar).
@export_range(0.0, 10.0, 0.01) var click_boost_cap: float = 0.50
## Presses from empty to a full boost bar. Each press adds cap / this, so
## Boost Power makes each press stronger without changing how many it takes.
@export_range(1, 100, 1) var boost_presses_to_fill: int = 10
## After the latest press, the bonus fades to zero over this many seconds.
## Holding the bar full takes about presses_to_fill / this presses per second.
@export_range(0.05, 30.0, 0.05, "suffix:s") var click_boost_decay_seconds: float = 4.0

@export_group("Ticket Booths")
## Booths at the start of a run (more are bought in the shop).
@export_range(1, 8, 1) var starting_booths: int = 1


## Returns a list of problems; empty means the config is usable.
func get_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	if not is_finite(starting_gold) or starting_gold < 0.0:
		problems.append("starting_gold must be a finite number >= 0")
	if not is_finite(income_bucket_seconds) or income_bucket_seconds <= 0.0:
		problems.append("income_bucket_seconds must be a finite number > 0")
	if income_bucket_count < 1:
		problems.append("income_bucket_count must be at least 1")
	if not is_finite(max_health) or max_health <= 0.0:
		problems.append("max_health must be a finite number > 0")
	if not is_finite(base_spin_speed_deg_s) or base_spin_speed_deg_s < 0.0:
		problems.append("base_spin_speed_deg_s must be a finite number >= 0")
	if boost_presses_to_fill < 1:
		problems.append("boost_presses_to_fill must be at least 1")
	if starting_booths < 1:
		problems.append("starting_booths must be at least 1")
	if not is_finite(click_boost_cap) or click_boost_cap < 0.0:
		problems.append("click_boost_cap must be a finite number >= 0")
	if not is_finite(click_boost_decay_seconds) or click_boost_decay_seconds <= 0.0:
		problems.append("click_boost_decay_seconds must be a finite number > 0")
	return problems
