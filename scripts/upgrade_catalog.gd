class_name UpgradeCatalog
extends Resource
## Every upgrade in the game, in shop order. Edit in the Inspector:
## res://resources/upgrades/upgrade_catalog.tres

@export var upgrades: Array[UpgradeData] = []


func get_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	var ids := {}
	for upgrade in upgrades:
		if upgrade == null:
			problems.append("catalog has an empty entry")
			continue
		problems.append_array(upgrade.get_problems())
		if ids.has(upgrade.id):
			problems.append("duplicate id %s" % upgrade.id)
		ids[upgrade.id] = true
	for upgrade in upgrades:
		if upgrade != null and upgrade.prerequisite_id != &"" and not ids.has(upgrade.prerequisite_id):
			problems.append("%s: prerequisite %s isn't in the catalog" % [upgrade.id, upgrade.prerequisite_id])
	return problems
