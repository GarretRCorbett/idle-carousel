class_name TierData
extends Resource
## One color tier (Grey ... Red). One .tres per tier in res://resources/tiers/,
## listed in tier_catalog.tres. Enemies spawned in a tier multiply their base
## EnemyData stats by these once, at spawn (EnemyBase.configure). Each tier
## stores its own multipliers, so one tier can be tuned without touching the others.

@export var tier_id: StringName = &""
## 0 = Grey ... 5 = Red. Matches the tier's place in the catalog.
@export_range(0, 5, 1) var rank: int = 0
## Tier name as a localization key (shown by the Step 6 tier picker).
@export var name_key: String = ""
## Enemy color in this tier. Multiplies the (light grey) enemy art.
@export var tint: Color = Color.WHITE
## Light edge around enemies in this tier, for dark tints that would vanish on
## the grass (Charcoal). Alpha 0 = no outline.
@export var outline_color: Color = Color(1.0, 1.0, 1.0, 0.0)

@export_group("Enemy multipliers")
@export_range(0.01, 100.0, 0.01, "or_greater") var health_multiplier: float = 1.0
@export_range(0.01, 10.0, 0.01, "or_greater") var speed_multiplier: float = 1.0
@export_range(0.0, 10.0, 0.01, "or_greater") var drag_multiplier: float = 1.0
@export_range(0.0, 100.0, 0.01, "or_greater") var latch_dps_multiplier: float = 1.0
@export_range(0.0, 100.0, 0.01, "or_greater") var gold_multiplier: float = 1.0

## How this tier's waves are made (interval, size, directions, enemy mix).
@export var waves: WaveProfile


func get_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	if tier_id == &"":
		problems.append("tier_id is empty")
	for value: float in [health_multiplier, speed_multiplier]:
		if not is_finite(value) or value <= 0.0:
			problems.append("%s: health and speed multipliers must be above 0" % tier_id)
	for value: float in [drag_multiplier, latch_dps_multiplier, gold_multiplier]:
		if not is_finite(value) or value < 0.0:
			problems.append("%s: drag, latch damage and Gold multipliers must be 0 or more" % tier_id)
	if waves == null:
		problems.append("%s: no wave profile" % tier_id)
	else:
		for problem in waves.get_problems():
			problems.append("%s waves: %s" % [tier_id, problem])
	return problems
