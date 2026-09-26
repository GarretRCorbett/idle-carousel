class_name GuideCatalog
extends RefCounted
## Builds the Park Guide's entries from the data the game already has
## (Phase 4 Step 8): mounts from the shop's mount rows, enemies from the
## tiers' wave mixes, the tiers and their bosses from the tier catalog, and
## the random events Game uses. Only the mechanics are listed here, since
## they have no data file of their own.
##
## Text keys follow one pattern, so a new id only needs its rows in
## strings.csv: GUIDE_<KIND>_<ID>_BODY for every body; titles reuse the
## existing name keys (mount rows, tiers, bosses, events) and are
## GUIDE_<KIND>_<ID> only where none exists (enemies, mechanics). Tiers share
## one body and show their own multipliers.

## Mechanics, in order, and which are known from the very start.
const MECHANICS: Array[StringName] = [&"boost", &"auto_boost", &"overdrive", &"latch", &"stall"]
const STARTING_MECHANICS: Array[StringName] = [&"boost", &"auto_boost"]
## The mount the player starts with (known from the start).
const STARTING_MOUNT: StringName = &"horse"
const TIER_BODY_KEY := "GUIDE_TIER_BODY"


## Every entry, grouped in GuideEntry.Group order.
static func build(tiers: TierCatalog, events: Array[EventData]) -> Array[GuideEntry]:
	var entries: Array[GuideEntry] = []
	entries.append_array(_mounts())
	entries.append_array(_enemies(tiers))
	entries.append_array(_tiers(tiers))
	entries.append_array(_bosses(tiers))
	entries.append_array(_events(events))
	entries.append_array(_mechanics())
	return entries


static func body_key(kind: String, id: StringName) -> String:
	return "GUIDE_%s_%s_BODY" % [kind, String(id).to_upper()]


static func title_key(kind: String, id: StringName) -> String:
	return "GUIDE_%s_%s" % [kind, String(id).to_upper()]


## The `data` a scene's root node is given (mount, enemy and boss scenes all
## set their data resource there). Read from the scene file, not instantiated.
static func scene_data(scene: PackedScene) -> Resource:
	if scene == null:
		return null
	var state := scene.get_state()
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == &"data":
			return state.get_node_property_value(0, i) as Resource
	return null


static func _mounts() -> Array[GuideEntry]:
	var entries: Array[GuideEntry] = []
	var definitions := UpgradeManager.get_definitions()
	for upgrade in definitions:
		if upgrade.mount_scene == null:
			continue
		var entry := GuideEntry.new()
		entry.kind = GuideEntry.Kind.MOUNT
		entry.group = GuideEntry.Group.MOUNTS
		entry.id = upgrade.id
		entry.title_key = upgrade.display_name
		entry.body_key = body_key("MOUNT", upgrade.id)
		entry.known_from_start = upgrade.id == STARTING_MOUNT
		entry.data = scene_data(upgrade.mount_scene)
		entry.mount_upgrade = upgrade
		for other in definitions:
			if other.target_mount == upgrade.id and other.star_cost > 0.0:
				entry.level_upgrade = other
		entries.append(entry)
	return entries


## Each enemy type the waves use, in the order the tiers first bring them in.
static func _enemies(tiers: TierCatalog) -> Array[GuideEntry]:
	var entries: Array[GuideEntry] = []
	var seen: Dictionary[StringName, bool] = {}
	for tier in tiers.tiers:
		if tier.waves == null:
			continue
		for wave_entry in tier.waves.entries:
			var enemy := scene_data(wave_entry.enemy_scene) as EnemyData
			if enemy == null or seen.has(enemy.id):
				continue
			seen[enemy.id] = true
			var entry := GuideEntry.new()
			entry.kind = GuideEntry.Kind.ENEMY
			entry.group = GuideEntry.Group.ENEMIES
			entry.id = enemy.id
			entry.title_key = title_key("ENEMY", enemy.id)
			entry.body_key = body_key("ENEMY", enemy.id)
			entry.data = enemy
			entries.append(entry)
	return entries


static func _tiers(tiers: TierCatalog) -> Array[GuideEntry]:
	var entries: Array[GuideEntry] = []
	for tier in tiers.tiers:
		var entry := GuideEntry.new()
		entry.kind = GuideEntry.Kind.TIER
		entry.group = GuideEntry.Group.ENEMIES
		entry.id = tier.tier_id
		entry.title_key = tier.name_key
		entry.body_key = TIER_BODY_KEY
		entry.data = tier
		entries.append(entry)
	return entries


static func _bosses(tiers: TierCatalog) -> Array[GuideEntry]:
	var entries: Array[GuideEntry] = []
	for tier in tiers.tiers:
		if tier.boss == null:
			continue
		var entry := GuideEntry.new()
		entry.kind = GuideEntry.Kind.BOSS
		entry.group = GuideEntry.Group.BOSSES
		entry.id = tier.boss.boss_id
		entry.title_key = tier.boss.name_key
		entry.body_key = body_key("BOSS", tier.boss.boss_id)
		entry.data = tier.boss
		entry.tier = tier
		entry.boss_body = scene_data(tier.boss.scene) as EnemyData
		entries.append(entry)
	return entries


static func _events(events: Array[EventData]) -> Array[GuideEntry]:
	var entries: Array[GuideEntry] = []
	for event in events:
		if event == null:
			continue
		var entry := GuideEntry.new()
		entry.kind = GuideEntry.Kind.EVENT
		entry.group = GuideEntry.Group.EVENTS
		entry.id = event.id
		entry.title_key = event.name_key
		entry.body_key = body_key("EVENT", event.id)
		entry.data = event
		entries.append(entry)
	return entries


static func _mechanics() -> Array[GuideEntry]:
	var entries: Array[GuideEntry] = []
	for id in MECHANICS:
		var entry := GuideEntry.new()
		entry.kind = GuideEntry.Kind.MECHANIC
		entry.group = GuideEntry.Group.EVENTS
		entry.id = id
		entry.title_key = title_key("MECHANIC", id)
		entry.body_key = body_key("MECHANIC", id)
		entry.known_from_start = id in STARTING_MECHANICS
		entries.append(entry)
	return entries
