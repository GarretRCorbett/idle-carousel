extends GdUnitTestSuite
## HUD: speed readout, boost bar, shop row states, and a guard that the HUD
## never swallows clicks meant for the world.

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.base_spin_speed_deg_s = 45.0
	_config.click_boost_cap = 0.5
	_config.boost_presses_to_fill = 5  # 0.1 per press
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


func test_speed_multiplier_is_relative_to_base() -> void:
	assert_float(GameState.get_speed_multiplier()).is_equal_approx(1.0, 0.00001)
	GameState.add_click_boost()
	assert_float(GameState.get_speed_multiplier()).is_equal_approx(1.1, 0.00001)


func test_speed_multiplier_includes_upgrades() -> void:
	GameState.add_gold(UpgradeManager.get_cost(&"carousel_speed"))
	UpgradeManager.purchase(&"carousel_speed")
	var bonus := UpgradeManager.get_definition(&"carousel_speed").effect_value
	assert_float(GameState.get_speed_multiplier()).is_equal_approx(1.0 + bonus, 0.00001)


func test_boost_fraction_fills_toward_cap() -> void:
	assert_float(GameState.get_click_boost_fraction()).is_equal(0.0)
	GameState.add_click_boost()
	assert_float(GameState.get_click_boost_fraction()).is_equal_approx(0.2, 0.00001)
	for i in 10:
		GameState.add_click_boost()
	assert_float(GameState.get_click_boost_fraction()).is_equal_approx(1.0, 0.00001)


# --- Shop row states --------------------------------------------------------------

func test_row_states_follow_gold_and_levels() -> void:
	assert_int(UpgradeShop.get_row_state(&"carousel_speed")).is_equal(UpgradeShop.RowState.SAVING)
	GameState.add_gold(UpgradeManager.get_cost(&"carousel_speed"))
	assert_int(UpgradeShop.get_row_state(&"carousel_speed")).is_equal(UpgradeShop.RowState.AFFORDABLE)
	UpgradeManager.purchase(&"carousel_speed")
	# Level 1 of 10 bought: still buyable, now saving toward level 2.
	assert_int(UpgradeShop.get_row_state(&"carousel_speed")).is_equal(UpgradeShop.RowState.SAVING)


func test_row_is_maxed_after_every_level() -> void:
	GameState.add_gold(1000000.0)
	GameState.debug_set_bosses_beaten(6)  # these tests buy boss-gated rows
	for i in 10:
		assert_bool(UpgradeManager.purchase(&"carousel_speed")).is_true()
	assert_int(UpgradeShop.get_row_state(&"carousel_speed")).is_equal(UpgradeShop.RowState.MAXED)
	assert_bool(UpgradeManager.purchase(&"carousel_speed")).is_false()


# --- Carousel glow ---------------------------------------------------------------

func test_carousel_glow_follows_boost_state() -> void:
	var carousel: Carousel = auto_free(Carousel.new())
	carousel.set_boost_state(false, false)
	assert_that(carousel.get_glow_target()).is_equal(Color.WHITE)
	carousel.set_boost_state(true, false)
	assert_that(carousel.get_glow_target()).is_equal(carousel.boost_glow_modulate)
	carousel.set_boost_state(true, true)
	assert_that(carousel.get_glow_target()).is_equal(carousel.overdrive_glow_modulate)


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
	for path in ["LeftColumn/StatsPanel", "ShopPanel", "PlayColumn/BoostCenter/BoostPanel",
			"PlayColumn/BoostCenter/BoostPanel/BoostMargin/BoostColumn/BoostButton"]:
		var control := game.get_node(columns + path) as Control
		assert_int(control.mouse_filter).override_failure_message(
				"%s should STOP clicks" % path).is_equal(Control.MOUSE_FILTER_STOP)


## Gold changes on every kill and booth pass; the shop rows rebuild at most
## once a frame instead of once per change.
func test_shop_refreshes_once_per_frame_on_gold_changes() -> void:
	var game: Node = auto_free((load("res://scenes/Game.tscn") as PackedScene).instantiate())
	add_child(game)
	var shop := game.get_node("HUD/HUDRoot/ScreenMargin/Columns/ShopPanel") as UpgradeShop
	shop._process(0.0)
	assert_bool(shop.is_processing()).is_false()
	GameState.add_gold(5.0)
	GameState.add_gold(5.0)
	assert_bool(shop._refresh_queued).is_true()
	assert_bool(shop.is_processing()).is_true()
	shop._process(0.0)
	assert_bool(shop._refresh_queued).is_false()
	assert_bool(shop.is_processing()).is_false()
	GameState.reset_run()


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


## Every shop tab scrolls, so even the 13-row Mounts tab never makes the HUD
## taller than the 1280x720 screen (Codex review, Step 6).
func test_shop_never_outgrows_the_screen() -> void:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	var tabs := game.find_child("ShopTabs", true, false) as TabContainer
	var shop := game.find_child("ShopPanel", true, false) as Control
	var screen_height := float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	for i in tabs.get_tab_count():
		tabs.current_tab = i
		assert_bool(tabs.get_tab_control(i) is ScrollContainer).is_true()
		assert_float(shop.get_combined_minimum_size().y).is_less(screen_height - 32.0)


## The whole HUD (left panel, boss strip, shop) fits the 1280 px screen. The
## boss strip's fixed widths once added up to more than the middle column.
func test_hud_fits_the_screen_width() -> void:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	var columns := game.find_child("Columns", true, false) as Control
	var screen_width := float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	assert_float(columns.get_combined_minimum_size().x).is_less_equal(screen_width - 32.0)
