class_name MountSweep
extends RefCounted
## The hit math for a mount that sweeps a line (or later a wedge) round with
## the carousel. It only finds contacts; the mount decides what they do.
## Owned by each sweeping mount (composition, not a superclass), so a mount
## that doesn't deal damage (the Sloth) can use it too.
##
## A pass is one trip of the line across an enemy. Pass k is the window around
## bearing + k·TAU (RotationMath.sweep_passes), so each enemy is found once per
## pass even when a pass spans two ticks, and many times in one very long tick.

## Where the line starts: the mount's distance from the carousel center.
var inner_radius: float = 0.0
## How far the line reaches past inner_radius (MountData.sweep_range).
var reach: float = 0.0
## Extra half-width in radians on each side of the line. 0 = a line (Wolf);
## the Elephant's wedge will use it.
var half_arc: float = 0.0

## The last pass each enemy was found on, by instance ID.
var _last_hit_pass: Dictionary[int, int] = {}


## Every new pass the sweep makes across a live enemy while turning from
## start_angle by delta_angle (carousel angles, unwrapped, plus the slot angle).
## One entry per pass, so an enemy can be listed twice in a very long tick.
func collect(snapshot: EnemySnapshot, start_angle: float, delta_angle: float) -> Array[EnemyBase]:
	var found: Array[EnemyBase] = []
	if delta_angle <= 0.0:
		return found
	var outer := inner_radius + reach
	var distances := snapshot.distances
	var radii := snapshot.radii
	for i in snapshot.size():
		# Most enemies are outside this mount's ring: reject them before any
		# function call (this loop runs for every mount, every tick).
		var d := distances[i]
		var r := radii[i]
		if d + r < inner_radius or d - r > outer or d <= r:
			continue
		# Most of the rest are nowhere near the line this tick. `bound` is at
		# least the real half-window (asin(x) <= x·PI/2, and the tips are
		# narrower still), so this skips the trig without ever dropping a hit.
		var bound := r / d * (PI / 2.0) + half_arc
		var span := delta_angle + 2.0 * bound
		if span < TAU and fposmod(snapshot.bearings[i] - start_angle + bound, TAU) > span:
			continue
		var half := _half_window_at(snapshot, i)
		if half < 0.0:
			continue
		var enemy := snapshot.enemies[i]
		# An earlier mount this tick may have killed or removed it.
		if not is_instance_valid(enemy) or not enemy.is_active():
			continue
		var passes := RotationMath.sweep_passes(start_angle, delta_angle, snapshot.bearings[i], half)
		var id := enemy.get_instance_id()
		var first := maxi(passes.x, _last_hit_pass.get(id, passes.x - 1) + 1)
		for pass_index in range(first, passes.y + 1):
			_last_hit_pass[id] = pass_index
			found.append(enemy)
	return found


## Anything under the sweep at `angle` counts as already hit on this pass, so
## placing or moving a mount gives no free hit. Earlier memory is kept.
func rebase(snapshot: EnemySnapshot, angle: float) -> void:
	for i in snapshot.size():
		var half := _half_window_at(snapshot, i)
		if half < 0.0 or not is_instance_valid(snapshot.enemies[i]):
			continue
		var bearing := snapshot.bearings[i]
		var pass_index := roundi((angle - bearing) / TAU)
		if absf(angle - bearing - pass_index * TAU) <= half:
			_last_hit_pass[snapshot.enemies[i].get_instance_id()] = pass_index


## Drops what's remembered about a removed enemy, so the memory doesn't grow forever.
func forget(id: int) -> void:
	_last_hit_pass.erase(id)


## Half-width (radians) of snapshot entry i's window, or -1 if the sweep can't
## touch it. line_half_window checks distance first, which is cheap, so the
## many enemies outside this mount's ring skip the angle math.
func _half_window_at(snapshot: EnemySnapshot, i: int) -> float:
	var half := line_half_window(snapshot.distances[i], snapshot.radii[i], inner_radius, inner_radius + reach)
	return half + half_arc if half >= 0.0 else -1.0


## How far (radians) the line from inner to outer can turn away from an enemy's
## bearing and still touch it: the enemy is a circle of radius r at distance d.
## -1 if it can never touch, or if the enemy covers the center (d <= r).
## For the middle of the line this is asin(r / d). Near the tips the touch
## point is the line's end, so the window is narrower (law of cosines at q).
static func line_half_window(d: float, r: float, inner: float, outer: float) -> float:
	if d + r < inner or d - r > outer or d <= r:
		return -1.0
	# Where along the line the circle is touched at the widest angle.
	var q := clampf(sqrt(d * d - r * r), inner, outer)
	if q <= 0.0:
		return PI
	var cos_angle := (d * d + q * q - r * r) / (2.0 * d * q)
	return acos(clampf(cos_angle, -1.0, 1.0))
