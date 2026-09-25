class_name EnemyStatus
extends RefCounted
## Timed effects on one enemy. Today: slow (the Sloth). A freeze (Deep Sleep,
## Phase 4) will be a slow with multiplier 0. Time counts in game ticks
## (advance), so it pauses with the game and is exact in tests.

var _slow_multiplier: float = 1.0
var _slow_left: float = 0.0


## Slows to `multiplier` of normal speed for `seconds`. A second slow never
## stacks: the stronger multiplier and the longer time left win.
func apply_slow(multiplier: float, seconds: float) -> void:
	if not is_finite(multiplier) or not is_finite(seconds) or seconds <= 0.0:
		return
	multiplier = clampf(multiplier, 0.0, 1.0)
	if is_slowed():
		_slow_multiplier = minf(_slow_multiplier, multiplier)
		_slow_left = maxf(_slow_left, seconds)
	else:
		_slow_multiplier = multiplier
		_slow_left = seconds


## Counts effects down by one tick.
func advance(delta: float) -> void:
	if _slow_left <= 0.0:
		return
	_slow_left = maxf(0.0, _slow_left - delta)
	if _slow_left <= 0.0:
		_slow_multiplier = 1.0


## 1.0 normally; the slow's multiplier while slowed.
func get_speed_factor() -> float:
	return _slow_multiplier if is_slowed() else 1.0


func is_slowed() -> bool:
	return _slow_left > 0.0


func get_slow_seconds_left() -> float:
	return _slow_left
