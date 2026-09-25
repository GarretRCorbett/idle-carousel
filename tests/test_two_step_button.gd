extends GdUnitTestSuite
## TwoStepButton (memo R): asks once, then acts; a quick double-click doesn't
## count; it gives up waiting after confirm_seconds; refreshes can't hide it.

var _confirms: int = 0


func _button() -> TwoStepButton:
	var button := TwoStepButton.new()
	button.text = "Sell 40"
	add_child(button)
	auto_free(button)
	_confirms = 0
	button.confirmed.connect(func() -> void: _confirms += 1)
	return button


func test_second_press_confirms_once() -> void:
	var button := _button()
	button.pressed.emit()
	assert_bool(button.is_armed()).is_true()
	assert_str(button.text).is_not_equal("Sell 40")
	assert_int(_confirms).is_equal(0)
	button._process(0.5)
	button.pressed.emit()
	assert_int(_confirms).is_equal(1)
	assert_bool(button.is_armed()).is_false()
	assert_str(button.text).is_equal("Sell 40")


func test_quick_double_click_does_not_confirm() -> void:
	var button := _button()
	button.pressed.emit()
	button._process(0.05)
	button.pressed.emit()
	assert_int(_confirms).is_equal(0)
	assert_bool(button.is_armed()).is_true()


func test_it_stops_waiting_after_confirm_seconds() -> void:
	var button := _button()
	button.pressed.emit()
	button._process(button.confirm_seconds + 0.01)
	assert_bool(button.is_armed()).is_false()
	assert_str(button.text).is_equal("Sell 40")
	button.pressed.emit()  # starts over: asks again
	assert_int(_confirms).is_equal(0)


func test_refresh_while_waiting_keeps_the_question() -> void:
	var button := _button()
	button.pressed.emit()
	var asking := button.text
	button.set_idle_text("Sell 60")
	assert_str(button.text).is_equal(asking)
	button.disarm()
	assert_str(button.text).is_equal("Sell 60")


func test_confirm_can_be_turned_off() -> void:
	var button := _button()
	button.requires_confirm = false
	button.pressed.emit()
	assert_int(_confirms).is_equal(1)


## The shop's Sell button asks before selling.
func test_shop_sell_needs_two_presses() -> void:
	GameState.reset_run()
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	GameState.add_gold(10000.0)
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"horse")
	var shop := game.get_node("HUD").find_child("ShopPanel", true, false) as UpgradeShop
	shop._refresh()
	var sell := shop.find_child("horse", true, false).find_children("*", "TwoStepButton", true, false)[0] as TwoStepButton
	sell.pressed.emit()
	assert_int(GameState.get_mount_roster().size()).is_equal(2)
	sell._process(0.5)
	sell.pressed.emit()
	assert_int(GameState.get_mount_roster().size()).is_equal(1)
	GameState.reset_run()
