extends GdUnitTestSuite
## Main menu: it builds, and its buttons take clicks.


func test_menu_has_working_buttons() -> void:
	var menu := auto_free((load("res://scenes/MainMenu.tscn") as PackedScene).instantiate()) as MainMenu
	for path in ["Center/Column/Buttons/PlayButton", "Center/Column/Buttons/QuitButton"]:
		var button := menu.get_node(path) as Button
		assert_object(button).is_not_null()
		assert_int(button.mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)


func test_play_goes_to_the_game_scene() -> void:
	assert_bool(ResourceLoader.exists(MainMenu.GAME_SCENE)).is_true()
