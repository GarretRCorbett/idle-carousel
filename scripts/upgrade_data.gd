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
	MOUNT_TIER,        ## unused since Phase 4 (replaced by MOUNT_LEVEL); kept so the numbers don't shift
	AUTO_BOOST,        ## Auto-Boost: each level holds the bar higher (RunConfig.auto_boost_holds)
	MOUNT_LEVEL,       ## target_mount's track (GDD v1.17): levels 1-3, the ★2 star-up, levels 4-6
}

## A MOUNT_LEVEL track's 4th buy is the ★2 star-up (after levels 1-3).
const STAR_BUY := 3

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
## ADD_MOUNT_DAMAGE / MOUNT_LEVEL: which mount type it affects (MountData.mount_id, e.g. &"wolf").
@export var target_mount: StringName = &""

@export_group("Price and Levels")
## Price of the first level.
@export_range(0.0, 1000000.0, 1.0, "or_greater") var cost_gold: float = 0.0
## Each level costs this much more than the last (1.5 = +50% per level).
@export_range(1.0, 10.0, 0.01) var cost_growth: float = 1.5
## How many times it can be bought. 1 = one-time.
@export_range(1, 100, 1) var max_level: int = 1
## MOUNT_LEVEL only: the ★2 star-up's price (the 4th buy). 0 = priced like a level.
@export_range(0.0, 1000000.0, 1.0, "or_greater") var star_cost: float = 0.0
## MOUNT_LEVEL only: what the star-up does (a translation key).
@export var star_description: String = ""
## Must have at least one level of this first. Empty = no prerequisite.
@export var prerequisite_id: StringName = &""
## Needs this many *different* mount types at ★2 (not counting this row's own
## mount). The Panda needs 3. 0 = no requirement.
@export_range(0, 6, 1) var required_star2_types: int = 0
## Can't be bought at all until this many tier bosses are beaten (the
## Giraffe waits for Leaf Storm). 0 = open from the start.
@export_range(0, 6, 1) var required_bosses: int = 0
## Highest level you can buy after 0, 1, 2... bosses beaten, e.g. [3, 10]:
## levels 1-3 now, the rest after the first boss. Empty = no boss cap.
@export var level_cap_by_bosses: PackedInt32Array = PackedInt32Array()


## Highest level buyable with `bosses_beaten` bosses beaten.
func get_level_cap(bosses_beaten: int) -> int:
	if bosses_beaten < required_bosses:
		return 0
	if level_cap_by_bosses.is_empty():
		return max_level
	return mini(max_level, level_cap_by_bosses[clampi(bosses_beaten, 0, level_cap_by_bosses.size() - 1)])


## Bosses that must be beaten before level `owned_levels + 1` can be bought,
## or -1 if no number of bosses allows it.
func get_bosses_needed(owned_levels: int) -> int:
	for bosses in range(0, 7):
		if get_level_cap(bosses) > owned_levels:
			return bosses
	return -1


## Price of the next level when `owned_levels` are already bought.
## A mount track's star-up has its own price (star_cost); the levels after it
## carry on the level curve.
func get_cost_for_level(owned_levels: int) -> float:
	if effect_type == EffectType.MOUNT_LEVEL and star_cost > 0.0:
		if owned_levels == STAR_BUY:
			return roundf(star_cost)
		if owned_levels > STAR_BUY:
			return roundf(cost_gold * pow(cost_growth, owned_levels - 1))
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
	if effect_type in [EffectType.ADD_MOUNT_DAMAGE, EffectType.MOUNT_TIER, EffectType.MOUNT_LEVEL] and target_mount == &"":
		problems.append("%s: needs a target_mount" % id)
	return problems
