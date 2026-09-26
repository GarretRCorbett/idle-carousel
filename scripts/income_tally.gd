class_name IncomeTally
extends RefCounted
## Adds up Gold paid in one place (a ticket booth) so it can be shown as one
## combined "+X" at most every `interval` seconds, never one pop per pass: at
## high spin a booth is passed many times a second (GDD v1.17, income pops).
## A payment after a quiet spell shows at once, so a slow carousel still shows
## every pass.

var interval: float = 0.5
var _pending: float = 0.0
var _since_shown: float = INF


func _init(seconds: float = 0.5) -> void:
	interval = seconds


func add(amount: float) -> void:
	if is_finite(amount) and amount > 0.0:
		_pending += amount


## Advances time. Returns the Gold to show now (and starts a new tally), or 0.
func advance(delta: float) -> float:
	_since_shown += delta
	if _pending <= 0.0 or _since_shown < interval:
		return 0.0
	var shown := _pending
	_pending = 0.0
	_since_shown = 0.0
	return shown
