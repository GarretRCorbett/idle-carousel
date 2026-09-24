extends GdUnitTestSuite
## Horse + carousel together: passes are counted from real rotation.

var _carousel: Carousel
var _slot: Marker2D
var _horse: MountHorse
var _passes: Array = []


func before_test() -> void:
	_carousel = auto_free(Carousel.new())
	_slot = Marker2D.new()
	_slot.position = Vector2(0.0, -75.0)  # top of the carousel, where the booth is
	_carousel.add_child(_slot)
	_horse = MountHorse.new()
	_horse.data = load("res://resources/mounts/horse.tres")
	_slot.add_child(_horse)
	_horse.setup(_carousel)
	_horse.set_booth_bearing(Vector2(0.0, -130.0).angle())  # booth straight above
	_passes.clear()
	_horse.booth_passed.connect(func(_h: MountHorse, count: int) -> void: _passes.append(count))


func test_starting_at_the_booth_pays_after_one_full_turn() -> void:
	_carousel.advance_rotation(1.0, TAU * 0.5)
	assert_array(_passes).is_empty()  # leaving the booth doesn't pay
	_carousel.advance_rotation(1.0, TAU * 0.5)
	assert_array(_passes).is_equal([1])


func test_fast_tick_over_two_turns_pays_twice() -> void:
	_carousel.advance_rotation(1.0, TAU * 2.25)
	assert_array(_passes).is_equal([2])


func test_many_small_ticks_pay_once_per_turn() -> void:
	for i in 600:
		_carousel.advance_rotation(1.0 / 60.0, TAU * 0.5)  # 10 s at half a turn per second
	var total := 0
	for count in _passes:
		total += count
	assert_int(total).is_equal(5)


func test_moving_the_horse_to_another_slot_pays_nothing() -> void:
	_carousel.advance_rotation(1.0, TAU * 0.25)
	_slot.position = Vector2(0.0, 75.0)  # relocate across the booth line
	assert_array(_passes).is_empty()


func test_horse_payout_is_fixed_per_pass() -> void:
	assert_float(_horse.data.base_gold_bonus).is_equal(5.0)
