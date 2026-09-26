extends GdUnitTestSuite
## Mount slots, buying and selling mounts (GameState rules, test fixtures).

var _config: RunConfig
var _slot: UpgradeData
var _horse: UpgradeData
var _wolf: UpgradeData


func before_test() -> void:
	_config = RunConfig.new()
	_config.starting_mount_slots = 1
	_config.starting_horses = 1
	GameState.reset_run(_config)
	_slot = _upgrade(&"slot", UpgradeData.EffectType.ADD_MOUNT_SLOT, 10.0, 2.0, 2)
	_horse = _upgrade(&"horse", UpgradeData.EffectType.BUY_MOUNT, 100.0, 1.5, 5)
	_horse.mount_scene = load("res://scenes/mounts/Horse.tscn")
	_horse.sell_refund_fraction = 0.5
	_wolf = _upgrade(&"wolf", UpgradeData.EffectType.BUY_MOUNT, 50.0, 1.5, 1)
	_wolf.mount_scene = load("res://scenes/mounts/Wolf.tscn")


func after_test() -> void:
	GameState.reset_run()


func _upgrade(id: StringName, effect: UpgradeData.EffectType, cost: float, growth: float, levels: int) -> UpgradeData:
	var upgrade := UpgradeData.new()
	upgrade.id = id
	upgrade.effect_type = effect
	upgrade.cost_gold = cost
	upgrade.cost_growth = growth
	upgrade.max_level = levels
	return upgrade


func test_run_starts_with_one_horse_and_no_free_slot() -> void:
	assert_array(GameState.get_mount_roster()).is_equal([&"horse"])
	assert_int(GameState.get_mount_slots()).is_equal(1)
	assert_bool(GameState.has_free_mount_slot()).is_false()


func test_mounts_need_a_free_slot() -> void:
	GameState.add_gold(1000.0)
	assert_bool(GameState.try_purchase_upgrade(_wolf)).is_false()
	assert_float(GameState.get_gold()).is_equal(1000.0)
	assert_bool(GameState.try_purchase_upgrade(_slot)).is_true()
	assert_bool(GameState.try_purchase_upgrade(_wolf)).is_true()
	assert_array(GameState.get_mount_roster()).is_equal([&"horse", &"wolf"])


func test_wolf_is_bought_once() -> void:
	GameState.add_gold(1000.0)
	GameState.try_purchase_upgrade(_slot)
	GameState.try_purchase_upgrade(_slot)
	assert_bool(GameState.try_purchase_upgrade(_wolf)).is_true()
	assert_bool(GameState.try_purchase_upgrade(_wolf)).is_false()


func test_slot_price_grows_by_its_growth() -> void:
	GameState.add_gold(1000.0)
	assert_float(GameState.get_upgrade_cost(_slot)).is_equal(10.0)
	GameState.try_purchase_upgrade(_slot)
	assert_float(GameState.get_upgrade_cost(_slot)).is_equal(20.0)


func test_selling_refunds_half_the_last_price_and_frees_the_slot() -> void:
	GameState.add_gold(1000.0)
	GameState.try_purchase_upgrade(_slot)
	GameState.try_purchase_upgrade(_horse)  # costs 100
	var gold := GameState.get_gold()
	var income := GameState.get_recent_gold_per_second()
	assert_float(GameState.get_sell_refund(_horse)).is_equal(50.0)
	assert_bool(GameState.try_sell_mount(_horse)).is_true()
	assert_float(GameState.get_gold()).is_equal(gold + 50.0)
	assert_float(GameState.get_recent_gold_per_second()).is_equal(income)  # a refund isn't income
	assert_array(GameState.get_mount_roster()).is_equal([&"horse"])
	assert_bool(GameState.has_free_mount_slot()).is_true()
	assert_float(GameState.get_upgrade_cost(_horse)).is_equal(100.0)  # rebuying costs the same


func test_starting_horse_cannot_be_sold() -> void:
	assert_bool(GameState.can_sell_mount(_horse)).is_false()
	assert_bool(GameState.try_sell_mount(_horse)).is_false()
	assert_array(GameState.get_mount_roster()).is_equal([&"horse"])


func test_mounts_without_a_refund_cannot_be_sold() -> void:
	GameState.add_gold(1000.0)
	GameState.try_purchase_upgrade(_slot)
	GameState.try_purchase_upgrade(_wolf)
	assert_bool(GameState.try_sell_mount(_wolf)).is_false()


func test_roster_signal_follows_buys_and_sells() -> void:
	var seen: Array = []
	GameState.mounts_changed.connect(func(r: Array[StringName]) -> void: seen.append(r.size()))
	GameState.add_gold(1000.0)
	GameState.try_purchase_upgrade(_slot)
	GameState.try_purchase_upgrade(_horse)
	GameState.try_sell_mount(_horse)
	assert_array(seen).is_equal([2, 1])


func test_real_mount_rows_are_on_the_mounts_tab() -> void:
	for id: StringName in [&"mount_slot", &"horse", &"wolf"]:
		var row := UpgradeManager.get_definition(id)
		assert_object(row).is_not_null()
		assert_int(row.tab).is_equal(UpgradeData.Tab.MOUNTS)
	assert_int(UpgradeManager.get_definition(&"click_damage").tab).is_equal(UpgradeData.Tab.UPGRADES)


func test_shop_says_a_mount_needs_a_slot() -> void:
	GameState.reset_run()
	GameState.add_gold(1000.0)
	assert_int(UpgradeShop.get_row_state(&"wolf")).is_equal(UpgradeShop.RowState.LOCKED)
	UpgradeManager.purchase(&"mount_slot")
	assert_int(UpgradeShop.get_row_state(&"wolf")).is_equal(UpgradeShop.RowState.AFFORDABLE)
