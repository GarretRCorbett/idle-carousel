class_name EventDirector
extends Node
## Random events (GDD "Random Events", Phase 4 Step 7). Every few minutes it
## picks an event by weight: a pickup asks Game for a token to grab, a visitor
## starts right away. Timed effects run until they end; the same event again
## refreshes its timer instead of stacking. No new events during a boss fight
## or a stall (the clock waits), and never offline. Game calls advance() once
## per tick, like BossEncounter, so it runs on game time.

## A pickup should appear (Game places the token; grabbing it calls start()).
signal pickup_requested(event: EventData)
## An event took effect. `amount` is the Gold paid for FLAT_GOLD (else 0).
signal event_started(event: EventData, amount: float)
signal event_ended(event: EventData)
## The number of extra (event) booths changed.
signal extra_booths_changed(count: int)

var events: Array[EventData] = []
var rng := RandomNumberGenerator.new()
var _config: RunConfig
## Seconds until the next event.
var _countdown: float = 0.0
## Running timed events: id -> seconds left.
var _active: Dictionary[StringName, float] = {}
var _by_id: Dictionary[StringName, EventData] = {}


## Starts a fresh run's clock (Game calls this after a reset or load).
func setup(config: RunConfig, seed_value: int) -> void:
	_config = config
	rng.seed = seed_value
	for event in events:
		_by_id[event.id] = event
	clear()
	_countdown = _next_wait()


## Ends every running event (a new run or a load).
func clear() -> void:
	var running := _active.keys()
	_active.clear()  # first, so each _end sees what's still running
	for id: StringName in running:
		_end(_by_id[id])


func advance(delta: float) -> void:
	for id in _active.keys():
		_active[id] -= delta
		if _active[id] <= 0.0:
			_active.erase(id)
			_end(_by_id[id])
	if _config == null or GameState.is_boss_active() or GameState.is_stalled():
		return
	_countdown -= delta
	if _countdown > 0.0:
		return
	_countdown = _next_wait()
	var event := pick()
	if event == null:
		return
	if event.kind == EventData.Kind.PICKUP:
		pickup_requested.emit(event)
	else:
		start(event)


## A weighted random event, or null if none can happen.
func pick() -> EventData:
	var total := 0.0
	for event in events:
		total += event.weight
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	for event in events:
		roll -= event.weight
		if roll < 0.0:
			return event
	return events.back()


## Applies an event (a grabbed pickup, or a visitor). Running again refreshes it.
func start(event: EventData) -> void:
	var amount := 0.0
	match event.effect:
		EventData.Effect.SPEED:
			GameState.set_speed_modifier(_source(event), event.strength)
		EventData.Effect.BOOTH_GOLD:
			GameState.set_booth_gold_modifier(_source(event), event.strength)
		EventData.Effect.FLAT_GOLD:
			amount = GameState.earn_gold(GameState.get_normal_booth_income_per_second() * event.strength)
		EventData.Effect.EXTRA_BOOTH:
			var was_running := _active.has(event.id)
			_active[event.id] = event.duration
			if not was_running:
				extra_booths_changed.emit(get_extra_booths())
	if event.duration > 0.0:
		_active[event.id] = event.duration
	event_started.emit(event, amount)


## Seconds left on a running event (0 if it isn't running).
func get_time_left(id: StringName) -> float:
	return _active.get(id, 0.0)


## Running events with their seconds left, in start order.
func get_active() -> Dictionary[StringName, float]:
	return _active.duplicate()


func get_event(id: StringName) -> EventData:
	return _by_id.get(id)


func get_extra_booths() -> int:
	var count := 0
	for id in _active:
		if _by_id[id].effect == EventData.Effect.EXTRA_BOOTH:
			count += 1
	return count


func get_seconds_until_next() -> float:
	return _countdown


func _end(event: EventData) -> void:
	match event.effect:
		EventData.Effect.SPEED:
			GameState.remove_speed_modifier(_source(event))
		EventData.Effect.BOOTH_GOLD:
			GameState.remove_booth_gold_modifier(_source(event))
		EventData.Effect.EXTRA_BOOTH:
			extra_booths_changed.emit(get_extra_booths())
	event_ended.emit(event)


func _source(event: EventData) -> StringName:
	return StringName("event_" + String(event.id))


func _next_wait() -> float:
	return rng.randf_range(_config.event_min_seconds, _config.event_max_seconds)
