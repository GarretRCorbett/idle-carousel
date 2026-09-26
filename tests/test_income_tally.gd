extends GdUnitTestSuite
## Booth Gold shows as one combined "+X" at most every interval.


func test_first_payment_shows_right_away() -> void:
	var tally := IncomeTally.new(0.5)
	tally.add(5.0)
	assert_float(tally.advance(1.0 / 60.0)).is_equal(5.0)


func test_nothing_paid_shows_nothing() -> void:
	var tally := IncomeTally.new(0.5)
	assert_float(tally.advance(10.0)).is_equal(0.0)


func test_fast_passes_combine_into_one_pop_per_interval() -> void:
	var tally := IncomeTally.new(0.45)
	var shown: Array[float] = []
	# 10 passes a second for 1 s, 60 ticks a second.
	for tick in 60:
		if tick % 6 == 0:
			tally.add(5.0)
		var amount := tally.advance(1.0 / 60.0)
		if amount > 0.0:
			shown.append(amount)
	# One at once, then one every 0.45 s (ticks 0, 27, 54): three pops, and no Gold lost.
	assert_int(shown.size()).is_equal(3)
	var total := 0.0
	for amount in shown:
		total += amount
	assert_float(total + tally.advance(1.0)).is_equal_approx(50.0, 0.00001)


func test_slow_passes_each_get_their_own_pop() -> void:
	var tally := IncomeTally.new(0.5)
	tally.add(5.0)
	assert_float(tally.advance(0.01)).is_equal(5.0)
	tally.advance(2.0)
	tally.add(5.0)
	assert_float(tally.advance(0.01)).is_equal(5.0)


func test_ignores_bad_amounts() -> void:
	var tally := IncomeTally.new(0.5)
	tally.add(-3.0)
	tally.add(0.0)
	tally.add(INF)
	tally.add(NAN)
	assert_float(tally.advance(1.0)).is_equal(0.0)
