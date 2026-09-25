class_name UpgradeData
extends Resource
## One upgrade in the shop. One .tres per upgrade in res://resources/upgrades/,
## listed in upgrade_catalog.tres (which also sets the shop order).
## Upgrades have levels: max_level 1 = a one-time purchase. Each level costs
## cost_gold × cost_growth^(levels already bought) and adds effect_value again.

enum EffectType {
	ADD_SPIN_BONUS,    ## effect_value added to the permanent spin bonus (0.2 = +20% of base speed)
	ADD_BOOST_CAP,     ## effect_value added to the max boost (0.1 = +10%)
	ADD_TICKET_BOOTH,  ## one more ticket booth per level
	ADD_CLICK_DAMAGE,  ## effect_value added to click damage per level
	ADD_MOUNT_SLOT,    ## one more mount slot per level
	BUY_MOUNT,         ## one mount_scene per level, placed in the next free slot
	ADD_MOUNT_DAMAGE,  ## effect_value added to target_mount's damage per hit, per level
	MOUNT_TIER,        ## raises target_mount's tier by one per level (every mount of that type)
}

## Which shop tab the row appears on.
enum Tab { CAROUSEL, COMBAT, MOUNTS }

## Internal key. Never shown to the player; don't rename after release.
@export var id: StringName = &""
## Shop name and description: translation keys (localization/strings.csv).
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var effect_type: EffectType = EffectType.ADD_SPIN_BONUS
## Added once per level.
@export var effect_value: float = 0.0
@export var tab: Tab = Tab.CAROUSEL

@export_group("Mounts")
## BUY_MOUNT: the mount scene each level adds.
@export var mount_scene: PackedScene
## BUY_MOUNT: selling one back refunds this fraction of the last level's price.
## 0 = can't be sold.
@export_range(0.0, 1.0, 0.05) var sell_refund_fraction: float = 0.0
## ADD_MOUNT_DAMAGE / MOUNT_TIER: which mount type it affects (MountData.mount_id, e.g. &"wolf").
@export var target_mount: StringName = &""

@export_group("Price and Levels")
## Price of the first level.
@export_range(0.0, 1000000.0, 1.0, "or_greater") var cost_gold: float = 0.0
## Each level costs this much more than the last (1.5 = +50% per level).
@export_range(1.0, 10.0, 0.01) var cost_growth: float = 1.5
## How many times it can be bought. 1 = one-time.
@export_range(1, 100, 1) var max_level: int = 1
## Must have at least one level of this first. Empty = no prerequisite.
@export var prerequisite_id: StringName = &""


## Price of the next level when `owned_levels` are already bought.
func get_cost_for_level(owned_levels: int) -> float:
	return roundf(cost_gold * pow(cost_growth, owned_levels))


func get_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	if id == &"":
		problems.append("id is empty")
	if not is_finite(cost_gold) or cost_gold < 0.0:
		problems.append("%s: cost_gold must be a finite number >= 0" % id)
	if not is_finite(cost_growth) or cost_growth < 1.0:
		problems.append("%s: cost_growth must be >= 1" % id)
	if max_level < 1:
		problems.append("%s: max_level must be at least 1" % id)
	if not is_finite(effect_value):
		problems.append("%s: effect_value must be finite" % id)
	if prerequisite_id == id and id != &"":
		problems.append("%s: can't be its own prerequisite" % id)
	if effect_type == EffectType.BUY_MOUNT and mount_scene == null:
		problems.append("%s: BUY_MOUNT needs a mount_scene" % id)
	if effect_type in [EffectType.ADD_MOUNT_DAMAGE, EffectType.MOUNT_TIER] and target_mount == &"":
		problems.append("%s: needs a target_mount" % id)
	return problems
