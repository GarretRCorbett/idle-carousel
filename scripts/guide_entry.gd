class_name GuideEntry
extends RefCounted
## One Park Guide page (Phase 4 Step 8): what it's about, where its text is,
## and how to tell whether the player has met it. Built from the game's data
## by GuideCatalog, so a new mount, enemy, boss or event gets a page without
## new UI code (it only needs its GUIDE_* text keys).

## Where the entry is listed, in this order.
enum Group { MOUNTS, ENEMIES, BOSSES, EVENTS }
enum Kind { MOUNT, ENEMY, TIER, BOSS, EVENT, MECHANIC }

var kind: Kind = Kind.MOUNT
var group: Group = Group.MOUNTS
## Stable id of the thing itself (wolf, leaf, green, leaf_storm, overdrive...).
var id: StringName = &""
## The name (a translation key). Bosses: see get_title_key().
var title_key: String = ""
## 1-3 sentences (a translation key).
var body_key: String = ""
## Known before it's ever met (the Horse, Boost, Auto-Boost).
var known_from_start: bool = false
## The data behind it: MountData, EnemyData, TierData, BossData or EventData
## (nothing for a mechanic).
var data: Resource
## Mounts: the shop row that buys one, and its level track (for the stats).
var mount_upgrade: UpgradeData
var level_upgrade: UpgradeData
## Bosses: the tier they guard, and their body's look.
var tier: TierData
var boss_body: EnemyData


## Its discovery id (GuideDiscovery's "<kind>:<id>").
func get_discovery_id() -> String:
	match kind:
		Kind.MOUNT:
			return GuideDiscovery.mount_key(id)
		Kind.ENEMY:
			return GuideDiscovery.enemy_key(id)
		Kind.TIER:
			return GuideDiscovery.tier_key(id)
		Kind.BOSS:
			return GuideDiscovery.boss_key(id)
		Kind.EVENT:
			return GuideDiscovery.event_key(id)
	return GuideDiscovery.mechanic_key(id)


func is_discovered() -> bool:
	return known_from_start or SaveManager.is_discovered(get_discovery_id())


## A boss's name follows the current theme (ThemeManager.boss_name_key).
func get_title_key() -> String:
	if kind == Kind.BOSS and data is BossData:
		return ThemeManager.boss_name_key(data)
	return title_key
