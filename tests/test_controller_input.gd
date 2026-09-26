extends GdUnitTestSuite
## Controller support helpers: which device is in use, and which button an
## action is really bound to (so prompts follow remaps).


func after_test() -> void:
	InputMap.load_from_project_settings()  # undo any remap a test made
	ControllerInput.set_using_controller(false)


func test_every_player_control_is_an_action_with_a_controller_binding() -> void:
	for action: StringName in [&"boost", &"send_wave", &"pause_menu", &"grab_pickup", &"strike", &"shop_prev_tab", &"shop_next_tab"]:
		assert_bool(InputMap.has_action(action)).override_failure_message(String(action)).is_true()
		var bound := ControllerInput.get_joy_button(action) >= 0 or ControllerInput.get_joy_axis(action) >= 0
		assert_bool(bound).override_failure_message("%s has no controller binding" % action).is_true()


func test_grab_is_the_top_face_button_and_boost_the_right_trigger() -> void:
	assert_int(ControllerInput.get_joy_button(&"grab_pickup")).is_equal(JOY_BUTTON_Y)
	assert_int(ControllerInput.get_joy_axis(&"boost")).is_equal(JOY_AXIS_TRIGGER_RIGHT)


func test_the_lookup_follows_a_remap() -> void:
	InputMap.action_erase_events(&"grab_pickup")
	var remapped := InputEventJoypadButton.new()
	remapped.button_index = JOY_BUTTON_X
	InputMap.action_add_event(&"grab_pickup", remapped)
	assert_int(ControllerInput.get_joy_button(&"grab_pickup")).is_equal(JOY_BUTTON_X)


func test_unknown_or_unbound_actions_have_no_button() -> void:
	assert_int(ControllerInput.get_joy_button(&"no_such_action")).is_equal(-1)
	assert_int(ControllerInput.get_joy_axis(&"grab_pickup")).is_equal(-1)


func test_the_last_device_used_decides() -> void:
	var changes: Array = []
	ControllerInput.device_changed.connect(func(on: bool) -> void: changes.append(on))
	var press := InputEventJoypadButton.new()
	press.button_index = JOY_BUTTON_A
	press.pressed = true
	ControllerInput._input(press)
	assert_bool(ControllerInput.using_controller).is_true()
	var drift := InputEventJoypadMotion.new()
	drift.axis = JOY_AXIS_LEFT_X
	drift.axis_value = 0.1
	ControllerInput._input(InputEventMouseButton.new())
	ControllerInput._input(drift)  # a resting stick's drift doesn't count
	assert_bool(ControllerInput.using_controller).is_false()
	assert_array(changes).is_equal([true, false])
