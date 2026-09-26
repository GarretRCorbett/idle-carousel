extends GdUnitTestSuite
## Random events (Phase 4 Step 7): the timing window, no events in boss fights
## or stalls, refresh-not-stack, each effect, and grabbing a pickup.

var _config: RunConfig


func before_test() -> void:
	_config = RunConfig.new()
	_config.event_min_seconds = 100.0
	_config.event_max_seconds = 200.0
	GameState.reset_run(_config)


func after_test() -> void:
	GameState.reset_run()


func _event(effect: EventData.Effect, strength: float, duration: float, kind: EventData.Kind) -> EventData:
	var event := EventData.new()
	event.id = StringName("test_%d" % effect)
	event.kind = kind
	event.effect = effect
	event.strength = strength
	event.duration = duration
	return event


func _director(events: Array[EventData]) -> EventDirector:
	var director := EventDirector.new()
	director.events = events
	add_child(director)
	auto_free(director)
	director.setup(_config, 7)
	return director


func test_the_first_event_waits_inside_the_window() -> void:
	var director := _director([_event(EventData.Effect.SPEED, 2.0, 10.0, EventData.Kind.PICKUP)])
	assert_float(director.get_seconds_until_next()).is_between(100.0, 200.0)
	var requested: Array = []
	director.pickup_requested.connect(func(e: EventData) -> void: requested.append(e))
	director.advance(99.0)
	assert_array(requested).is_empty()
	director.advance(101.0)
	assert_int(requested.size()).is_equal(1)
	assert_float(director.get_seconds_until_next()).is_between(100.0, 200.0)


func test_no_events_during_a_boss_fight_the_clock_waits() -> void:
	var director := _director([_event(EventData.Effect.SPEED, 2.0, 10.0, EventData.Kind.PICKUP)])
	var before := director.get_seconds_until_next()
	GameState.set_boss_active(true)
	var requested: Array = []
	director.pickup_requested.connect(func(e: EventData) -> void: requested.append(e))
	director.advance(500.0)
	assert_array(requested).is_empty()
	assert_float(director.get_seconds_until_next()).is_equal(before)
	GameState.set_boss_active(false)


func test_visitors_start_by_themselves() -> void:
	var booth := _event(EventData.Effect.EXTRA_BOOTH, 1.0, 45.0, EventData.Kind.VISITOR)
	var director := _director([booth])
	director.advance(director.get_seconds_until_next() + 0.1)
	assert_int(director.get_extra_booths()).is_equal(1)
	assert_float(director.get_time_left(booth.id)).is_greater(40.0)


func test_speed_surge_multiplies_speed_then_ends() -> void:
	var surge := _event(EventData.Effect.SPEED, 2.0, 10.0, EventData.Kind.PICKUP)
	var director := _director([surge])
	var speed := GameState.get_effective_spin_speed_rad_s()
	director.start(surge)
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal_approx(speed * 2.0, 0.0001)
	director.advance(10.1)
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal_approx(speed, 0.0001)


func test_the_same_event_refreshes_instead_of_stacking() -> void:
	var surge := _event(EventData.Effect.SPEED, 2.0, 10.0, EventData.Kind.PICKUP)
	var director := _director([surge])
	var speed := GameState.get_effective_spin_speed_rad_s()
	director.start(surge)
	director.advance(8.0)
	director.start(surge)
	assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal_approx(speed * 2.0, 0.0001)
	assert_float(director.get_time_left(surge.id)).is_equal_approx(10.0, 0.0001)


func test_golden_hour_multiplies_booth_gold() -> void:
	var hour := _event(EventData.Effect.BOOTH_GOLD, 2.0, 20.0, EventData.Kind.PICKUP)
	var director := _director([hour])
	director.start(hour)
	assert_float(GameState.get_booth_gold_multiplier()).is_equal(2.0)
	director.advance(21.0)
	assert_float(GameState.get_booth_gold_multiplier()).is_equal(1.0)


func test_lucky_ticket_pays_minutes_of_booth_income() -> void:
	var ticket := _event(EventData.Effect.FLAT_GOLD, 120.0, 0.0, EventData.Kind.PICKUP)
	var director := _director([ticket])
	var paid: Array[float] = []
	director.event_started.connect(func(_e: EventData, amount: float) -> void: paid.append(amount))
	var gold := GameState.get_gold()
	director.start(ticket)
	var expected := GameState.get_normal_booth_income_per_second() * 120.0
	assert_float(GameState.get_gold() - gold).is_equal_approx(expected, 0.0001)
	assert_float(paid[0]).is_equal_approx(expected, 0.0001)


func test_a_new_run_ends_running_events() -> void:
	var surge := _event(EventData.Effect.SPEED, 2.0, 10.0, EventData.Kind.PICKUP)
	var director := _director([surge])
	director.start(surge)
	director.clear()
	assert_float(GameState.get_speed_modifier_multiplier()).is_equal(1.0)
	assert_dict(director.get_active()).is_empty()


func test_game_spawns_grabs_and_adds_a_popup_booth() -> void:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	auto_free(game)
	var booths := GameState.get_booth_count()
	game.debug_spawn_event(&"popup_booth")
	assert_int(game.get_node("World").find_children("*", "TicketBooth", true, false).size()).is_equal(booths + 1)
	assert_int(GameState.get_booth_count()).is_equal(booths)  # never bought or saved
	game.debug_spawn_event(&"speed_surge")
	var layer := game.get_node("World/PickupLayer")
	assert_int(layer.get_child_count()).is_equal(1)
	var grab := InputEventAction.new()
	grab.action = &"grab_pickup"
	grab.pressed = true
	game._unhandled_input(grab)
	assert_float(game.get_events().get_time_left(&"speed_surge")).is_greater(0.0)


func test_real_events_are_valid() -> void:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	auto_free(game)
	assert_int(game.event_list.size()).is_equal(4)
	for event in game.event_list:
		assert_array(event.get_problems()).override_failure_message(String(event.id)).is_empty()
