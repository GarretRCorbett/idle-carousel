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

@export_group("Latches and Health")
## A new latch deals no damage for this long (its drag applies right away).
@export_range(0.0, 30.0, 0.1, "suffix:s") var latch_grace_seconds: float = 2.0
## Health regained per second once nothing has been latched for regen_delay_seconds.
@export_range(0.0, 1000.0, 0.1, "or_greater") var regen_per_second: float = 2.0
@export_range(0.0, 60.0, 0.1, "suffix:s") var regen_delay_seconds: float = 2.0

@export_group("Stall (TEMPORARY)")
## TEMPORARY Phase 2 rule; the real fail state is DECISION PENDING (GDD).
## At 0 health the carousel stops. Clearing every latch restarts it at this
## fraction of max health (0.25 = 25%).
@export_range(0.01, 1.0, 0.01) var stall_recovery_fraction: float = 0.25
## While stalled, Boost fills a crank meter instead: this many presses...
@export_range(1, 100, 1) var crank_presses: int = 10
## ...or holding Boost this long fills it.
@export_range(0.1, 60.0, 0.1, "suffix:s") var crank_hold_seconds: float = 4.0
## A full crank restarts at this fraction of max health, with enemies still latched...
@export_range(0.01, 1.0, 0.01) var crank_restart_fraction: float = 0.15
## ...and no latch damage for this long, so the first sweep can happen.
@export_range(0.0, 30.0, 0.1, "suffix:s") var crank_protection_seconds: float = 3.0
## Stalled this long: every enemy is removed (no Gold) and it restarts at
## stall_recovery_fraction. A safety net for walking away.
@export_range(1.0, 600.0, 1.0, "suffix:s") var stall_timeout_seconds: float = 60.0

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
## The boost counts as "maxed" when the bar reaches this fraction...
@export_range(0.0, 1.0, 0.01) var boost_maxed_on_fraction: float = 0.99
## ...and stays maxed until it drops below this (so dips between presses don't count).
@export_range(0.0, 1.0, 0.01) var boost_maxed_off_fraction: float = 0.8

@export_group("Overdrive")
## Keep the boost maxed this long to trigger Overdrive...
@export_range(0.0, 60.0, 0.5, "suffix:s") var overdrive_hold_seconds: float = 5.0
## ...which multiplies speed by this until the boost is no longer maxed.
@export_range(1.0, 10.0, 0.1) var overdrive_multiplier: float = 2.0

@export_group("Clicking")
## Damage per enemy click before Click Damage upgrades.
@export_range(0.0, 1000.0, 0.1, "or_greater") var base_click_damage: float = 1.0

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
	if boost_maxed_off_fraction > boost_maxed_on_fraction:
		problems.append("boost_maxed_off_fraction must be <= boost_maxed_on_fraction")
	if not is_finite(overdrive_multiplier) or overdrive_multiplier < 1.0:
		problems.append("overdrive_multiplier must be >= 1")
	if boost_presses_to_fill < 1:
		problems.append("boost_presses_to_fill must be at least 1")
	if not is_finite(base_click_damage) or base_click_damage < 0.0:
		problems.append("base_click_damage must be a finite number >= 0")
	if not is_finite(stall_recovery_fraction) or stall_recovery_fraction <= 0.0 or stall_recovery_fraction > 1.0:
		problems.append("stall_recovery_fraction must be in (0, 1]")
	if not is_finite(crank_restart_fraction) or crank_restart_fraction <= 0.0 or crank_restart_fraction > 1.0:
		problems.append("crank_restart_fraction must be in (0, 1]")
	if not is_finite(crank_hold_seconds) or crank_hold_seconds <= 0.0:
		problems.append("crank_hold_seconds must be a finite number > 0")
	if crank_presses < 1:
		problems.append("crank_presses must be at least 1")
	for value: float in [latch_grace_seconds, regen_per_second, regen_delay_seconds, crank_protection_seconds]:
		if not is_finite(value) or value < 0.0:
			problems.append("latch grace, regen, and crank protection must be finite numbers >= 0")
			break
	if not is_finite(stall_timeout_seconds) or stall_timeout_seconds <= 0.0:
		problems.append("stall_timeout_seconds must be a finite number > 0")
	if starting_booths < 1:
		problems.append("starting_booths must be at least 1")
	if not is_finite(click_boost_cap) or click_boost_cap < 0.0:
		problems.append("click_boost_cap must be a finite number >= 0")
	if not is_finite(click_boost_decay_seconds) or click_boost_decay_seconds <= 0.0:
		problems.append("click_boost_decay_seconds must be a finite number > 0")
	return problems
