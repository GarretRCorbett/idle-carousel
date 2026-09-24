class_name UpgradeData
extends Resource
## One buyable upgrade. One .tres per upgrade in res://resources/upgrades/,
## listed in upgrade_catalog.tres (which also sets the shop order).
## All upgrades cost Gold and are bought once.

enum EffectType {
	ADD_SPIN_BONUS,    ## effect_value is added to the spin bonus (0.2 = +20% of base speed)
	ADD_CLICK_DAMAGE,  ## Step 6
	ADD_MOUNT_SLOT,    ## Step 10
	UNLOCK_MOUNT,      ## Step 10
}

## Internal key. Never shown to the player; don't rename after release.
@export var id: StringName = &""
## Shop name and description (Garret's text).
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_range(0.0, 1000000.0, 1.0, "or_greater") var cost_gold: float = 0.0
## Must be bought first. Empty = no prerequisite.
@export var prerequisite_id: StringName = &""
@export var effect_type: EffectType = EffectType.ADD_SPIN_BONUS
@export var effect_value: float = 0.0


func get_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	if id == &"":
		problems.append("id is empty")
	if not is_finite(cost_gold) or cost_gold < 0.0:
		problems.append("%s: cost_gold must be a finite number >= 0" % id)
	if not is_finite(effect_value):
		problems.append("%s: effect_value must be finite" % id)
	if prerequisite_id == id and id != &"":
		problems.append("%s: can't be its own prerequisite" % id)
	return problems
