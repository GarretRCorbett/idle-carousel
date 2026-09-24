extends Node
## Owns the upgrade catalog and is the entry point for buying. GameState owns
## what's been bought and applies the effects, so nothing else needs to know
## about the Carousel or HUD.

signal upgrade_purchased(id: StringName)

const CATALOG: UpgradeCatalog = preload("res://resources/upgrades/upgrade_catalog.tres")

var _by_id: Dictionary[StringName, UpgradeData] = {}


func _ready() -> void:
	var problems := CATALOG.get_problems()
	for problem in problems:
		push_error("Upgrade catalog: %s" % problem)
	for upgrade in CATALOG.upgrades:
		if upgrade != null:
			_by_id[upgrade.id] = upgrade


## Every upgrade in shop order.
func get_definitions() -> Array[UpgradeData]:
	return CATALOG.upgrades.duplicate()


func get_definition(id: StringName) -> UpgradeData:
	return _by_id.get(id)


func is_purchased(id: StringName) -> bool:
	return GameState.is_upgrade_purchased(id)


## Enough Gold, ignoring prerequisites.
func can_afford(id: StringName) -> bool:
	var upgrade := get_definition(id)
	return upgrade != null and GameState.can_afford(upgrade.cost_gold)


## Everything needed to buy it right now.
func can_purchase(id: StringName) -> bool:
	return GameState.can_purchase_upgrade(get_definition(id))


## Whether it should appear in the shop: not bought yet, prerequisite met.
func is_visible_in_shop(id: StringName) -> bool:
	var upgrade := get_definition(id)
	if upgrade == null or is_purchased(id):
		return false
	return upgrade.prerequisite_id == &"" or is_purchased(upgrade.prerequisite_id)


func purchase(id: StringName) -> bool:
	if not GameState.try_purchase_upgrade(get_definition(id)):
		return false
	upgrade_purchased.emit(id)
	return true
