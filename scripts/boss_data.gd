class_name BossData
extends Resource
## One tier boss. One .tres per boss in res://resources/bosses/, linked from
## its tier (TierData.boss). The fight itself is run by BossEncounter; the
## boss's own behavior is its scene's script (e.g. EnemyLeafStorm).

@export var boss_id: StringName = &""
## Boss name as a localization key (shown in the boss strip).
@export var name_key: String = ""
## The boss body.
@export var scene: PackedScene
## Kills in this boss's tier before the first Challenge (the kill gate).
## Once beaten, it can be re-challenged any time.
@export_range(0, 10000, 1) var kills_required: int = 60
## The attempt ends (no penalty but time) when this runs out.
@export_range(10.0, 600.0, 1.0, "suffix:s") var time_limit_seconds: float = 90.0
## Paid on the first win of the run (with the unlocks)...
@export_range(0.0, 1000000.0, 1.0, "or_greater") var first_clear_gold: float = 200.0
## ...and on every later win.
@export_range(0.0, 1000000.0, 1.0, "or_greater") var repeat_clear_gold: float = 50.0


func get_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	if boss_id == &"":
		problems.append("boss_id is empty")
	if scene == null:
		problems.append("%s: no scene" % boss_id)
	if not is_finite(time_limit_seconds) or time_limit_seconds <= 0.0:
		problems.append("%s: time_limit_seconds must be above 0" % boss_id)
	if repeat_clear_gold > first_clear_gold:
		problems.append("%s: a repeat win shouldn't pay more than the first" % boss_id)
	return problems
