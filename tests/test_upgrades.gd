extends GdUnitTestSuite
## Upgrade purchases: charging, prerequisites, effects, and no double charges.

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


func _spin(id: StringName, cost: float, bonus: float, prerequisite: StringName = &"") -> UpgradeData:
	var upgrade := UpgradeData.new()
	upgrade.id = id
	upgrade.cost_gold = cost
	upgrade.effect_type = UpgradeData.EffectType.ADD_SPIN_BONUS
	upgrade.effect_value = bonus
	upgrade.prerequisite_id = prerequisite
	return upgrade


func test_purchase_charges_exactly_the_cost() -> void:
	GameState.add_gold(10.0)
	assert_bool(GameState.try_purchase_upgrade(_spin(&"a", 8.0, 0.2))).is_true()
	assert_float(GameState.get_gold()).is_equal(2.0)
	assert_bool(GameState.is_upgrade_purchased(&"a")).is_true()


func test_cannot_buy_without_enough_gold() -> void:
	GameState.add_gold(7.0)
	assert_bool(GameState.try_purchase_upgrade(_spin(&"a", 8.0, 0.2))).is_false()
	assert_float(GameState.get_gold()).is_equal(7.0)
	assert_bool(GameState.is_upgrade_purchased(&"a")).is_false()


func test_cannot_buy_twice() -> void:
	var upgrade := _spin(&"a", 5.0, 0.2)
	GameState.add_gold(20.0)
	assert_bool(GameState.try_purchase_upgrade(upgrade)).is_true()
	assert_bool(GameState.try_purchase_upgrade(upgrade)).is_false()
	assert_float(GameState.get_gold()).is_equal(15.0)
	assert_float(GameState.get_spin_upgrade_multiplier()).is_equal_approx(1.2, 0.00001)


func test_prerequisite_is_enforced() -> void:
	GameState.add_gold(100.0)
	var second := _spin(&"b", 10.0, 0.3, &"a")
	assert_bool(GameState.try_purchase_upgrade(second)).is_false()
	assert_bool(GameState.try_purchase_upgrade(_spin(&"a", 10.0, 0.2))).is_true()
	assert_bool(GameState.try_purchase_upgrade(second)).is_true()


func test_spin_bonuses_add_up() -> void:
	GameState.add_gold(100.0)
	assert_float(GameState.get_spin_upgrade_multiplier()).is_equal(1.0)
	GameState.try_purchase_upgrade(_spin(&"a", 10.0, 0.2))
	assert_float(GameState.get_spin_upgrade_multiplier()).is_equal_approx(1.2, 0.00001)
	GameState.try_purchase_upgrade(_spin(&"b", 10.0, 0.3, &"a"))
	assert_float(GameState.get_spin_upgrade_multiplier()).is_equal_approx(1.5, 0.00001)


func test_unsupported_effect_is_rejected_without_charge() -> void:
	var slot := _spin(&"slot", 5.0, 1.0)
	slot.effect_type = UpgradeData.EffectType.ADD_MOUNT_SLOT  # arrives in Step 10
	GameState.add_gold(10.0)
	assert_bool(GameState.try_purchase_upgrade(slot)).is_false()
	assert_float(GameState.get_gold()).is_equal(10.0)


## A listener reacting to the charge sees the purchase already complete, and
## can't sneak in a second purchase of the same thing.
func test_listener_sees_committed_purchase_and_cannot_double_buy() -> void:
	var upgrade := _spin(&"a", 5.0, 0.2)
	GameState.add_gold(20.0)
	var seen: Array = []
	var listener := func(_balance: float, _delta: float) -> void:
		seen.append([GameState.is_upgrade_purchased(&"a"),
				GameState.get_spin_upgrade_multiplier(),
				GameState.try_purchase_upgrade(upgrade)])
	GameState.gold_changed.connect(listener)
	GameState.try_purchase_upgrade(upgrade)
	GameState.gold_changed.disconnect(listener)
	assert_int(seen.size()).is_equal(1)
	assert_bool(seen[0][0]).is_true()
	assert_float(seen[0][1]).is_equal_approx(1.2, 0.00001)
	assert_bool(seen[0][2]).is_false()
	assert_float(GameState.get_gold()).is_equal(15.0)


func test_reset_clears_purchases() -> void:
	GameState.add_gold(10.0)
	GameState.try_purchase_upgrade(_spin(&"a", 5.0, 0.2))
	GameState.reset_run(_config)
	assert_bool(GameState.is_upgrade_purchased(&"a")).is_false()
	assert_float(GameState.get_spin_upgrade_multiplier()).is_equal(1.0)


# --- The real catalog through UpgradeManager ---------------------------------------

func test_catalog_is_valid() -> void:
	var catalog := load("res://resources/upgrades/upgrade_catalog.tres") as UpgradeCatalog
	assert_array(catalog.get_problems()).is_empty()


func test_shop_flow_spin_1_then_spin_2() -> void:
	assert_bool(UpgradeManager.is_visible_in_shop(&"spin_speed_1")).is_true()
	assert_bool(UpgradeManager.is_visible_in_shop(&"spin_speed_2")).is_false()
	GameState.add_gold(30.0)
	assert_bool(UpgradeManager.purchase(&"spin_speed_1")).is_true()
	assert_float(GameState.get_gold()).is_equal(0.0)
	assert_bool(UpgradeManager.is_visible_in_shop(&"spin_speed_1")).is_false()
	assert_bool(UpgradeManager.is_visible_in_shop(&"spin_speed_2")).is_true()
	assert_bool(UpgradeManager.can_purchase(&"spin_speed_2")).is_false()
	GameState.add_gold(110.0)
	assert_bool(UpgradeManager.purchase(&"spin_speed_2")).is_true()
	assert_float(GameState.get_spin_upgrade_multiplier()).is_equal_approx(1.5, 0.00001)


func test_unknown_id_is_harmless() -> void:
	assert_bool(UpgradeManager.purchase(&"nope")).is_false()
	assert_bool(UpgradeManager.can_purchase(&"nope")).is_false()
	assert_object(UpgradeManager.get_definition(&"nope")).is_null()
