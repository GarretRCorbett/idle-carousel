extends GdUnitTestSuite
## Booth-pass counting: exact on the unwrapped angle, never double-counted.


func test_wrap_crosses_once() -> void:
	assert_int(RotationMath.count_crossings(deg_to_rad(359.0), deg_to_rad(2.0), 0.0)).is_equal(1)


func test_arrival_counts_and_departure_does_not() -> void:
	assert_int(RotationMath.count_crossings(-PI / 2.0, PI / 2.0, 0.0)).is_equal(1)
	assert_int(RotationMath.count_crossings(0.0, PI / 2.0, 0.0)).is_equal(0)


func test_one_tick_spanning_two_turns_counts_two() -> void:
	assert_int(RotationMath.count_crossings(PI / 4.0, 2.0 * TAU, 0.0)).is_equal(2)


func test_no_movement_no_crossing() -> void:
	assert_int(RotationMath.count_crossings(0.0, 0.0, 0.0)).is_equal(0)


func test_near_target_without_reaching_it() -> void:
	assert_int(RotationMath.count_crossings(-0.2, 0.1, 0.0)).is_equal(0)


func test_target_one_turn_away_is_the_same_target() -> void:
	assert_int(RotationMath.count_crossings(-0.1, 0.2, TAU)).is_equal(1)
	assert_int(RotationMath.count_crossings(-0.1, 0.2, -TAU)).is_equal(1)


func test_negative_unwrapped_start() -> void:
	assert_int(RotationMath.count_crossings(-3.0 * TAU - 0.1, 0.2, 0.0)).is_equal(1)


func test_reverse_travel() -> void:
	assert_int(RotationMath.count_crossings(PI / 2.0, -PI / 2.0, 0.0)).is_equal(1)
	assert_int(RotationMath.count_crossings(0.0, -PI / 2.0, 0.0)).is_equal(0)


## Counting tick by tick must equal counting the total travel once: nothing is
## double-counted or dropped at tick boundaries.
func test_ticks_add_up_to_the_whole_journey() -> void:
	var start := -PI / 2.0
	var angle := start
	var step := (PI / 2.0 + 3.0 * TAU) / 37.0
	var in_ticks := 0
	for i in 37:
		in_ticks += RotationMath.count_crossings(angle, step, 0.0)
		angle += step
	assert_int(in_ticks).is_equal(RotationMath.count_crossings(start, angle - start, 0.0))
	assert_int(in_ticks).is_between(3, 4)
