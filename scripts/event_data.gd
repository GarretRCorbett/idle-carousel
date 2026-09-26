class_name EventData
extends Resource
## One random event (GDD "Random Events"). One .tres per event in
## res://resources/events/; new events are data, not code.

enum Kind {
	PICKUP,   ## a token to click (or grab with the controller) before it fades
	VISITOR,  ## just happens, with a banner
}
enum Effect {
	SPEED,        ## speed ×strength for duration
	BOOTH_GOLD,   ## booth-pass Gold ×strength for duration
	FLAT_GOLD,    ## Gold worth `strength` seconds of normal booth income, at once
	EXTRA_BOOTH,  ## one extra ticket booth for duration (never saved or bought)
}
## What the token looks like.
enum Shape { COIN, BOLT, TICKET }

## Stable id; never rename (saves and themes may refer to it).
@export var id: StringName = &""
@export var kind: Kind = Kind.PICKUP
@export var effect: Effect = Effect.SPEED
## ×multiplier for SPEED / BOOTH_GOLD, seconds of income for FLAT_GOLD.
@export_range(0.0, 1000.0, 0.1, "or_greater") var strength: float = 2.0
## How long it lasts (0 = instant).
@export_range(0.0, 600.0, 1.0, "suffix:s") var duration: float = 15.0
## Chance relative to the other events.
@export_range(0.0, 100.0, 0.5) var weight: float = 1.0
## Name on its chip (a translation key).
@export var name_key: String = ""
## Banner when it happens (a translation key; empty = none). {0} = an amount if any.
@export var banner_key: String = ""

@export_group("Look")
@export var shape: Shape = Shape.COIN
@export var color: Color = Color(1.0, 0.84, 0.22)


func get_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	if id == &"":
		problems.append("event id is empty")
	if not is_finite(strength) or strength <= 0.0:
		problems.append("%s: strength must be > 0" % id)
	if not is_finite(weight) or weight < 0.0:
		problems.append("%s: weight must be >= 0" % id)
	if effect in [Effect.SPEED, Effect.BOOTH_GOLD, Effect.EXTRA_BOOTH] and duration <= 0.0:
		problems.append("%s: timed effects need a duration" % id)
	return problems
