extends GdUnitTestSuite
## Phase 4 Step 6: Carousel Health, Gilded Rims, Offline Efficiency, Click
## Range, and the shop's visibility rule (hidden until one boss away).

func before_test() -> void:
	GameState.reset_run()
	GameState.add_gold(10000000.0)


func after_test() -> void:
	GameState.reset_run()


func _upgrade(effect: UpgradeData.EffectType, value: float) -> UpgradeData:
	var upgrade := UpgradeData.new()
	upgrade.id = &"test_upgrade"
	upgrade.effect_type = effect
	upgrade.effect_value = value
	upgrade.max_level = 5
	return upgrade


func test_carousel_health_raises_max_and_arrives_full() -> void:
	var max_before := GameState.get_max_health()
	GameState.damage_carousel(10.0)
	var health := GameState.get_health()
	var events: Array = []
	GameState.health_changed.connect(func(current: float, maximum: float) -> void: events.append([current, maximum]))
	assert_bool(GameState.try_purchase_upgrade(_upgrade(UpgradeData.EffectType.ADD_MAX_HEALTH, 25.0))).is_true()
	assert_float(GameState.get_max_health()).is_equal(max_before + 25.0)
	assert_float(GameState.get_health()).is_equal(health + 25.0)
	assert_array(events).is_not_empty()


func test_gilded_rims_multiplies_earned_gold_only() -> void:
	GameState.try_purchase_upgrade(_upgrade(UpgradeData.EffectType.ADD_GOLD_BONUS, 0.1))
	GameState.try_purchase_upgrade(_upgrade(UpgradeData.EffectType.ADD_GOLD_BONUS, 0.1))
	var gold := GameState.get_gold()
	assert_float(GameState.earn_gold(100.0)).is_equal_approx(120.0, 0.0001)
	assert_float(GameState.get_gold() - gold).is_equal_approx(120.0, 0.0001)
	gold = GameState.get_gold()
	GameState.add_gold(100.0)  # refunds and debug Gold are as-is
	assert_float(GameState.get_gold() - gold).is_equal_approx(100.0, 0.0001)


func test_gilded_rims_raises_offline_gold_too() -> void:
	var before := GameState.get_offline_gold_per_second()
	GameState.try_purchase_upgrade(_upgrade(UpgradeData.EffectType.ADD_GOLD_BONUS, 0.1))
	assert_float(GameState.get_offline_gold_per_second()).is_equal_approx(before * 1.1, 0.0001)


func test_offline_efficiency_raises_the_offline_rate() -> void:
	var rate := GameState.get_offline_rate()
	var gold := GameState.get_offline_gold_per_second()
	GameState.try_purchase_upgrade(_upgrade(UpgradeData.EffectType.ADD_OFFLINE_RATE, 0.05))
	assert_float(GameState.get_offline_rate()).is_equal_approx(rate + 0.05, 0.0001)
	assert_float(GameState.get_offline_gold_per_second()).is_equal_approx(gold * (rate + 0.05) / rate, 0.0001)


func test_click_range_widens_clicks() -> void:
	var leaf := (load("res://scenes/enemies/Leaf.tscn") as PackedScene).instantiate() as EnemyBase
	add_child(leaf)
	auto_free(leaf)
	var enemies: Array[EnemyBase] = [leaf]
	var just_outside := leaf.global_position + Vector2(leaf.get_click_radius() * 1.1, 0.0)
	assert_object(ClickRouter.choose_target(just_outside, enemies)).is_null()
	GameState.try_purchase_upgrade(_upgrade(UpgradeData.EffectType.ADD_CLICK_RANGE, 0.25))
	assert_float(GameState.get_click_range_multiplier()).is_equal_approx(1.25, 0.0001)
	assert_object(ClickRouter.choose_target(just_outside, enemies, GameState.get_click_range_multiplier())).is_same(leaf)


func test_real_upgrades_are_in_the_catalog_with_sections() -> void:
	for id: StringName in [&"carousel_health", &"gilded_rims", &"offline_efficiency", &"click_range"]:
		var upgrade := UpgradeManager.get_definition(id)
		assert_object(upgrade).override_failure_message(String(id)).is_not_null()
		assert_int(upgrade.tab).is_equal(UpgradeData.Tab.UPGRADES)
		assert_int(upgrade.section).is_not_equal(UpgradeData.Section.NONE)


## A row appears once you're one boss from unlocking it.
func test_rows_hide_until_one_boss_away() -> void:
	# The Elephant needs two bosses (hidden), Gilded Rims one (shown, locked).
	assert_bool(UpgradeShop.is_row_hidden(&"gilded_rims")).is_false()
	assert_int(UpgradeShop.get_row_state(&"gilded_rims")).is_equal(UpgradeShop.RowState.LOCKED)
	var elephant := UpgradeManager.get_definition(&"elephant")
	var needed := elephant.get_bosses_needed(0)
	assert_bool(UpgradeShop.is_row_hidden(&"elephant")).is_equal(needed > 1)
	GameState.debug_set_bosses_beaten(maxi(1, needed - 1))
	assert_bool(UpgradeShop.is_row_hidden(&"elephant")).is_false()
	# Nothing available now is ever hidden.
	assert_bool(UpgradeShop.is_row_hidden(&"carousel_speed")).is_false()


func test_new_upgrades_survive_a_save() -> void:
	GameState.debug_set_bosses_beaten(3)
	for id: StringName in [&"carousel_health", &"gilded_rims", &"offline_efficiency", &"click_range"]:
		assert_bool(UpgradeManager.purchase(id)).override_failure_message(String(id)).is_true()
	var data := GameState.to_save_data()
	var health := GameState.get_max_health()
	var gold_multiplier := GameState.get_gold_multiplier()
	GameState.reset_run()
	GameState.load_save_data(data, UpgradeManager.get_definitions())
	assert_float(GameState.get_max_health()).is_equal(health)
	assert_float(GameState.get_gold_multiplier()).is_equal(gold_multiplier)
	assert_float(GameState.get_health()).is_equal(GameState.get_max_health())
