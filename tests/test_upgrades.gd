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


func test_levels_cost_more_each_time() -> void:
	var speed := UpgradeManager.get_definition(&"carousel_speed")
	assert_float(UpgradeManager.get_cost(&"carousel_speed")).is_equal(30.0)
	GameState.add_gold(1000.0)
	UpgradeManager.purchase(&"carousel_speed")
	assert_int(UpgradeManager.get_level(&"carousel_speed")).is_equal(1)
	assert_float(UpgradeManager.get_cost(&"carousel_speed")).is_equal(45.0)
	UpgradeManager.purchase(&"carousel_speed")
	assert_float(UpgradeManager.get_cost(&"carousel_speed")).is_equal(roundf(30.0 * 1.5 * 1.5))
	assert_float(GameState.get_spin_upgrade_multiplier()).is_equal_approx(1.4, 0.00001)
	assert_int(speed.max_level).is_equal(10)


func test_boost_power_raises_the_cap_but_not_presses_to_fill() -> void:
	var cap_before := GameState.get_boost_cap()
	GameState.add_gold(1000.0)
	UpgradeManager.purchase(&"boost_power")
	assert_float(GameState.get_boost_cap()).is_equal_approx(cap_before + 0.1, 0.00001)
	for i in _config.boost_presses_to_fill:
		GameState.add_click_boost()
	assert_float(GameState.get_click_boost_fraction()).is_equal_approx(1.0, 0.00001)
	assert_float(GameState.get_click_boost()).is_equal_approx(cap_before + 0.1, 0.00001)


func test_ticket_booth_adds_a_booth_up_to_four() -> void:
	var counts: Array = []
	GameState.booth_count_changed.connect(func(c: int) -> void: counts.append(c))
	assert_int(GameState.get_booth_count()).is_equal(1)
	assert_float(UpgradeManager.get_cost(&"ticket_booth")).is_equal(500.0)
	GameState.add_gold(100000.0)
	for i in 3:
		assert_bool(UpgradeManager.purchase(&"ticket_booth")).is_true()
	assert_bool(UpgradeManager.purchase(&"ticket_booth")).is_false()
	assert_int(GameState.get_booth_count()).is_equal(4)
	assert_array(counts).is_equal([2, 3, 4])


func test_unknown_id_is_harmless() -> void:
	assert_bool(UpgradeManager.purchase(&"nope")).is_false()
	assert_bool(UpgradeManager.can_purchase(&"nope")).is_false()
	assert_object(UpgradeManager.get_definition(&"nope")).is_null()
