class_name EnemyBase
extends Node2D
## Base for every enemy. Lives in World/EnemyLayer (world space, never on the
## carousel). Flies straight at the carousel, stops at the rim, and dies once.
## Game moves it each tick with advance() and decides what its signals mean.
## Health is a runtime copy: the shared EnemyData .tres is never changed.

## Reached the rim this tick. Emitted once.
signal reached_rim(enemy: EnemyBase)
## Health hit zero. Emitted exactly once, after the enemy stops taking hits.
## killer is the mount that landed the lethal hit, or null (a click, or no source).
signal died(enemy: EnemyBase, killer: Node)

## DEAD: killed, about to be removed. REMOVED: Game is taking it out of the
## world (killed or cleared). Neither can move, latch, be hit, or die again.
enum State { APPROACHING, AT_RIM, DEAD, REMOVED }

@export var data: EnemyData

@export_group("Hit Flash")
## Visual tint right after a hit, fading back to normal.
@export var hit_flash_modulate: Color = Color(2.0, 2.0, 2.0)
@export_range(0.01, 1.0, 0.01, "suffix:s") var hit_flash_seconds: float = 0.12
## Shape size right after a hit, springing back to full over the flash.
@export_range(0.3, 1.5, 0.01) var hit_squash_scale: float = 0.75

@export_group("Health Bar")
## Gap between the top of the enemy and its health bar.
@export_range(0.0, 32.0, 1.0, "suffix:px") var health_bar_gap: float = 4.0

## Kill Gold is data.gold_drop times this (1.5 for early-sent waves).
var gold_multiplier: float = 1.0

var _state: State = State.APPROACHING
var _health: float = 0.0
var _center: Vector2 = Vector2.ZERO
## Distance from the center where the enemy's edge touches the rim.
var _stop_distance: float = 0.0
## Seconds left in the hit flash. _process runs only while this is above 0.
var _flash_left: float = 0.0

@onready var _visual: Node2D = $Visual
@onready var _health_bar: EnemyHealthBar = $HealthBar


func _ready() -> void:
	_health = data.base_health
	_health_bar.visible = false
	_health_bar.position = Vector2(0.0, -data.hitbox_radius - health_bar_gap)
	set_process(false)
	_visual.draw.connect(_draw_placeholder)
	_visual.queue_redraw()


## Called by Game after adding the enemy. `center` is the carousel center and
## `rim_radius` its edge, both in World space.
func setup(center: Vector2, rim_radius: float) -> void:
	_center = center
	_stop_distance = rim_radius + data.hitbox_radius


## Moves one tick toward the carousel. Stops exactly at the rim, never past it.
func advance(delta: float) -> void:
	if _state != State.APPROACHING or delta <= 0.0:
		return
	var offset := position - _center
	var distance := offset.length()
	var travel := data.move_speed * delta
	if distance - travel > _stop_distance:
		position -= offset / distance * travel
		return
	position = _center + offset.normalized() * _stop_distance
	_state = State.AT_RIM
	reached_rim.emit(self)


## Applies damage from `source` (a mount, or null for a click). Returns true
## only for the hit that kills it; hits after that (even in the same frame) do nothing.
func take_damage(amount: float, source: Node = null) -> bool:
	if not is_active() or not is_finite(amount) or amount <= 0.0:
		return false
	_health = maxf(0.0, _health - amount)
	if _health <= 0.0:
		# Removed this tick, so skip the bar and flash.
		_state = State.DEAD
		died.emit(self, source)
		return true
	_health_bar.set_fraction(_health / data.base_health)
	_health_bar.visible = true
	_flash()
	return false


## Still in play: approaching or latched. Everything that acts on an enemy
## (moving, sweeps, clicks, damage) checks this first.
func is_active() -> bool:
	return _state == State.APPROACHING or _state == State.AT_RIM


## Game calls this first when it takes the enemy out of the world, before
## anything else (latch signals, freeing) can reach it. Returns false if it was
## already removed, so a second removal does nothing.
func mark_removed() -> bool:
	if _state == State.REMOVED:
		return false
	_state = State.REMOVED
	return true


func is_removed() -> bool:
	return _state == State.REMOVED


func is_at_rim() -> bool:
	return _state == State.AT_RIM


func get_health() -> float:
	return _health


## Starts (or restarts) the hit flash. A countdown instead of a new Tween per
## hit, which adds up with hundreds of enemies being hit.
func _flash() -> void:
	_flash_left = hit_flash_seconds
	_visual.modulate = hit_flash_modulate
	_visual.queue_redraw()
	set_process(true)


## Runs only while flashing. Subclasses that need _process must call super.
func _process(delta: float) -> void:
	_flash_left = maxf(0.0, _flash_left - delta)
	_visual.queue_redraw()  # the squash is drawn, so it doesn't fight transform smoothing
	if _flash_left <= 0.0:
		_visual.modulate = Color.WHITE
		set_process(false)
		return
	_visual.modulate = Color.WHITE.lerp(hit_flash_modulate, _flash_left / hit_flash_seconds)


## Drawn on Visual, so the shape turns with it while the health bar stays upright.
func _draw_placeholder() -> void:
	if data.texture != null:
		return
	var size := data.placeholder_size * get_squash()
	var points := PackedVector2Array()
	for i in data.placeholder_points:
		points.append(Vector2.from_angle(TAU * i / data.placeholder_points) * size)
	_visual.draw_colored_polygon(points, data.placeholder_color)


## 1 normally; hit_squash_scale right after a hit, easing back to 1.
func get_squash() -> float:
	if hit_flash_seconds <= 0.0:
		return 1.0
	return lerpf(1.0, hit_squash_scale, _flash_left / hit_flash_seconds)
