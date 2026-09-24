extends GdUnitTestSuite
## Click routing, and a guard that the HUD never blocks clicks on the world.


func _left_press(at: Vector2, pressed := true, button := MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = at
	return event


func test_play_area_click_requests_one_boost() -> void:
	var router: ClickRouter = auto_free(ClickRouter.new())
	var count := [0]
	router.play_area_click_requested.connect(func() -> void: count[0] += 1)
	router.route_world_click(Vector2(10, 10))
	assert_int(count[0]).is_equal(1)


func test_only_left_presses_count() -> void:
	var router: ClickRouter = ClickRouter.new()
	add_child(router)
	var count := [0]
	router.play_area_click_requested.connect(func() -> void: count[0] += 1)
	router._unhandled_input(_left_press(Vector2(5, 5), false))  # release
	router._unhandled_input(_left_press(Vector2(5, 5), true, MOUSE_BUTTON_RIGHT))
	router._unhandled_input(_left_press(Vector2(5, 5), true, MOUSE_BUTTON_WHEEL_UP))
	assert_int(count[0]).is_equal(0)
	router._unhandled_input(_left_press(Vector2(5, 5)))
	assert_int(count[0]).is_equal(1)
	router.queue_free()


## Every HUD Control must either IGNORE the mouse or sit inside a panel that
## STOPs it. A full-screen Control left on STOP/PASS would silently eat every
## click meant for the carousel. That bug is invisible in the editor.
func test_hud_never_blocks_world_clicks() -> void:
	var game: Node = auto_free((load("res://scenes/Game.tscn") as PackedScene).instantiate())
	var hud := game.get_node("HUD")
	var offenders := PackedStringArray()
	_collect_blockers(hud, false, offenders)
	assert_array(offenders).override_failure_message(
			"These HUD Controls catch the mouse outside a STOP panel: %s" % ", ".join(offenders)).is_empty()


func test_hud_panels_block_clicks() -> void:
	var game: Node = auto_free((load("res://scenes/Game.tscn") as PackedScene).instantiate())
	for path in ["HUD/HUDRoot/ScreenMargin/Columns/LeftColumn/StatsPanel",
			"HUD/HUDRoot/ScreenMargin/Columns/ShopPanel"]:
		var panel := game.get_node(path) as Control
		assert_int(panel.mouse_filter).override_failure_message(
				"%s should STOP clicks" % path).is_equal(Control.MOUSE_FILTER_STOP)


func _collect_blockers(node: Node, inside_stop_panel: bool, offenders: PackedStringArray) -> void:
	var control := node as Control
	var covered := inside_stop_panel
	if control != null:
		if control is PanelContainer and control.mouse_filter == Control.MOUSE_FILTER_STOP:
			covered = true
		elif not inside_stop_panel and control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			offenders.append(String(control.name))
	for child in node.get_children():
		_collect_blockers(child, covered, offenders)
