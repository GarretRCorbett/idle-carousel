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


## Enough Gold for the next level, ignoring prerequisites.
func can_afford(id: StringName) -> bool:
	return GameState.can_afford(get_cost(id))


## Everything needed to buy it right now.
func can_purchase(id: StringName) -> bool:
	return GameState.can_purchase_upgrade(get_definition(id))


func get_level(id: StringName) -> int:
	return GameState.get_upgrade_level(id)


func is_maxed(id: StringName) -> bool:
	return GameState.is_upgrade_maxed(get_definition(id))


## Price of the next level.
func get_cost(id: StringName) -> float:
	var upgrade := get_definition(id)
	return GameState.get_upgrade_cost(upgrade) if upgrade != null else INF


func purchase(id: StringName) -> bool:
	if not GameState.try_purchase_upgrade(get_definition(id)):
		return false
	upgrade_purchased.emit(id)
	return true
