extends GdUnitTestSuite
## HUD: speed readout, boost bar, shop row states, and a guard that the HUD
## never swallows clicks meant for the world.

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.base_spin_speed_deg_s = 45.0
	_config.click_boost_increment = 0.1
	_config.click_boost_cap = 0.5
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


func test_speed_multiplier_is_relative_to_base() -> void:
	assert_float(GameState.get_speed_multiplier()).is_equal_approx(1.0, 0.00001)
	GameState.add_click_boost()
	assert_float(GameState.get_speed_multiplier()).is_equal_approx(1.1, 0.00001)


func test_speed_multiplier_includes_upgrades() -> void:
	GameState.add_gold(30.0)
	UpgradeManager.purchase(&"spin_speed_1")
	assert_float(GameState.get_speed_multiplier()).is_equal_approx(1.2, 0.00001)


func test_boost_fraction_fills_toward_cap() -> void:
	assert_float(GameState.get_click_boost_fraction()).is_equal(0.0)
	GameState.add_click_boost()
	assert_float(GameState.get_click_boost_fraction()).is_equal_approx(0.2, 0.00001)
	for i in 10:
		GameState.add_click_boost()
	assert_float(GameState.get_click_boost_fraction()).is_equal_approx(1.0, 0.00001)


# --- Shop row states --------------------------------------------------------------

func test_row_states_follow_gold_and_prerequisites() -> void:
	assert_int(UpgradeShop.get_row_state(&"spin_speed_1")).is_equal(UpgradeShop.RowState.SAVING)
	assert_int(UpgradeShop.get_row_state(&"spin_speed_2")).is_equal(UpgradeShop.RowState.LOCKED)
	GameState.add_gold(30.0)
	assert_int(UpgradeShop.get_row_state(&"spin_speed_1")).is_equal(UpgradeShop.RowState.AFFORDABLE)
	UpgradeManager.purchase(&"spin_speed_1")
	assert_int(UpgradeShop.get_row_state(&"spin_speed_1")).is_equal(UpgradeShop.RowState.BOUGHT)
	assert_int(UpgradeShop.get_row_state(&"spin_speed_2")).is_equal(UpgradeShop.RowState.SAVING)


func test_locked_row_stays_locked_even_with_enough_gold() -> void:
	GameState.add_gold(1000.0)
	assert_int(UpgradeShop.get_row_state(&"spin_speed_2")).is_equal(UpgradeShop.RowState.LOCKED)


# --- Click blocking -----------------------------------------------------------------

## Every HUD Control must IGNORE the mouse unless it's a button or a STOP panel
## (or inside one). A full-screen Control left catching the mouse would
## silently eat clicks meant for the world, like clicking a Leaf in Step 6.
func test_hud_never_blocks_world_clicks() -> void:
	var game: Node = auto_free((load("res://scenes/Game.tscn") as PackedScene).instantiate())
	var offenders := PackedStringArray()
	_collect_blockers(game.get_node("HUD"), false, offenders)
	assert_array(offenders).override_failure_message(
			"These HUD Controls catch the mouse outside a panel or button: %s" % ", ".join(offenders)).is_empty()


func test_panels_and_boost_button_take_clicks() -> void:
	var game: Node = auto_free((load("res://scenes/Game.tscn") as PackedScene).instantiate())
	var columns := "HUD/HUDRoot/ScreenMargin/Columns/"
	for path in ["LeftColumn/StatsPanel", "ShopPanel", "PlayColumn/BoostCenter/BoostColumn/BoostButton"]:
		var control := game.get_node(columns + path) as Control
		assert_int(control.mouse_filter).override_failure_message(
				"%s should STOP clicks" % path).is_equal(Control.MOUSE_FILTER_STOP)


func _collect_blockers(node: Node, covered: bool, offenders: PackedStringArray) -> void:
	var control := node as Control
	var now_covered := covered
	if control != null:
		var is_panel := control is PanelContainer and control.mouse_filter == Control.MOUSE_FILTER_STOP
		if is_panel or control is BaseButton:
			now_covered = true
		elif not covered and control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			offenders.append(String(control.name))
	for child in node.get_children():
		_collect_blockers(child, now_covered, offenders)
