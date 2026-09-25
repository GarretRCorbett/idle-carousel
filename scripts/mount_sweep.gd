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
func collect(enemies: Array[EnemyBase], center: Vector2, start_angle: float, delta_angle: float) -> Array[EnemyBase]:
	var found: Array[EnemyBase] = []
	if delta_angle <= 0.0:
		return found
	for enemy in enemies:
		var window := _window_of(enemy, center)
		if window.y < 0.0:
			continue
		var passes := RotationMath.sweep_passes(start_angle, delta_angle, window.x, window.y)
		var id := enemy.get_instance_id()
		var first := maxi(passes.x, _last_hit_pass.get(id, passes.x - 1) + 1)
		for pass_index in range(first, passes.y + 1):
			_last_hit_pass[id] = pass_index
			found.append(enemy)
	return found


## Anything under the sweep at `angle` counts as already hit on this pass, so
## placing or moving a mount gives no free hit. Earlier memory is kept.
func rebase(enemies: Array[EnemyBase], center: Vector2, angle: float) -> void:
	for enemy in enemies:
		var window := _window_of(enemy, center)
		if window.y < 0.0:
			continue
		var pass_index := roundi((angle - window.x) / TAU)
		if absf(angle - window.x - pass_index * TAU) <= window.y:
			_last_hit_pass[enemy.get_instance_id()] = pass_index


## Drops what's remembered about a removed enemy, so the memory doesn't grow forever.
func forget(id: int) -> void:
	_last_hit_pass.erase(id)


## Vector2(bearing, half_width) of an enemy as seen from the center;
## half_width is -1 if the sweep can't touch it.
func _window_of(enemy: EnemyBase, center: Vector2) -> Vector2:
	var offset := enemy.global_position - center
	var half := line_half_window(offset.length(), enemy.data.hitbox_radius, inner_radius, inner_radius + reach)
	if half < 0.0:
		return Vector2(0.0, -1.0)
	return Vector2(offset.angle(), half + half_arc)


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
