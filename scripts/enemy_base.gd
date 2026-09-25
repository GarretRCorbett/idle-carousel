class_name EnemyBase
extends Node2D
## Base for every enemy. Lives in World/EnemyLayer (world space, never on the
## carousel). Flies straight at the carousel, stops at the rim, and dies once.
## Game moves it each tick with advance() and decides what its signals mean.
## Health is a runtime copy: the shared EnemyData .tres is never changed.
## Stats are fixed at spawn by configure() (base × tier multiplier); nothing
## reads tier-scaled numbers from `data` after that, so switching tier only
## changes enemies spawned afterwards.

## Reached the rim this tick. Emitted once.
signal reached_rim(enemy: EnemyBase)
## Health hit zero. Emitted exactly once, after the enemy stops taking hits.
## killer is the mount that landed the lethal hit, or null (a click, or no source).
signal died(enemy: EnemyBase, killer: Node)

## DEAD: killed, about to be removed. REMOVED: Game is taking it out of the
## world (killed or cleared). Neither can move, latch, be hit, or die again.
enum State { APPROACHING, AT_RIM, DEAD, REMOVED }

## What part it plays in a boss fight. Anything but NONE pays no Gold and
## gives no kill credit (so a boss can't be farmed). REQUIRED ones must die
## for the win and are never cleared by Emergency Clear.
enum EncounterRole { NONE, BOSS, SUMMON, REQUIRED }

@export var data: EnemyData

## Set by BossEncounter before the enemy joins; normal enemies stay NONE.
var encounter_role: EncounterRole = EncounterRole.NONE

@export_group("Hit Flash")
## Visual tint right after a hit, fading back to normal.
@export var hit_flash_modulate: Color = Color(2.0, 2.0, 2.0)
@export_range(0.01, 1.0, 0.01, "suffix:s") var hit_flash_seconds: float = 0.12
## Shape size right after a hit, springing back to full over the flash.
@export_range(0.3, 1.5, 0.01) var hit_squash_scale: float = 0.75

@export_group("Health Bar")
## Gap between the top of the enemy and its health bar.
@export_range(0.0, 32.0, 1.0, "suffix:px") var health_bar_gap: float = 4.0

var _state: State = State.APPROACHING
var _health: float = 0.0
var _center: Vector2 = Vector2.ZERO
## Distance from the center where the enemy's edge touches the rim.
var _stop_distance: float = 0.0
## Seconds left in the hit flash. _process runs only while this is above 0.
var _flash_left: float = 0.0
## Direction from the carousel center, but "unwrapped": it doesn't jump from
## +180° to -180° on the left of the screen, so an enemy moving sideways across
## that line (the Stick Giant's zigzag) never looks like a new sweep pass.
var _unwrapped_bearing: float = 0.0
var _has_bearing: bool = false

# Effective stats, set once by configure().
var _configured: bool = false
var _tier_rank: int = 0
var _max_health: float = 0.0
var _move_speed: float = 0.0
var _latch_drag: float = 0.0
var _latch_dps: float = 0.0
var _kill_gold: float = 0.0
var _tint: Color = Color.WHITE
var _outline_color: Color = Color(1.0, 1.0, 1.0, 0.0)
## The Sprite's scale with no squash (fits the texture to data.placeholder_size).
var _sprite_scale: Vector2 = Vector2.ONE
## Slow (and later freeze): timed effects that change how it moves.
var _status := EnemyStatus.new()

## Hit flash (modulate) and tumble (rotation). Tier tint and squash are on Sprite.
@onready var _visual: Node2D = $Visual
@onready var _sprite: Sprite2D = $Visual/Sprite
@onready var _outline: Sprite2D = $Visual/Outline
@onready var _health_bar: EnemyHealthBar = $HealthBar
@onready var _slow_icon: EnemySlowIcon = $SlowIcon


func _ready() -> void:
	if not _configured:
		configure(null, 1.0)  # Grey stats
	_health = _max_health
	_health_bar.visible = false
	_health_bar.position = Vector2(0.0, -get_hitbox_radius() - health_bar_gap)
	_slow_icon.position = Vector2(get_hitbox_radius() * 0.5, -get_hitbox_radius() - health_bar_gap - 6.0)
	_slow_icon.visible = false
	set_process(false)
	_setup_sprite()
	_apply_tint()
	_visual.draw.connect(_draw_placeholder)
	_visual.queue_redraw()


## Fixes this enemy's stats for `tier` (null = Grey, all ×1). Kill Gold also
## gets reward_multiplier (the early-send bonus). Called once, before it's
## added to the world; WaveManager does it when it creates the enemy.
func configure(tier: TierData, reward_multiplier: float) -> void:
	_configured = true
	_tier_rank = tier.rank if tier != null else 0
	_max_health = data.base_health * (tier.health_multiplier if tier != null else 1.0)
	_move_speed = data.move_speed * (tier.speed_multiplier if tier != null else 1.0)
	_latch_drag = data.latch_drag * (tier.drag_multiplier if tier != null else 1.0)
	_latch_dps = data.damage_per_second * (tier.latch_dps_multiplier if tier != null else 1.0)
	_kill_gold = data.gold_drop * (tier.gold_multiplier if tier != null else 1.0) * reward_multiplier
	_tint = tier.tint if tier != null else Color.WHITE
	_outline_color = tier.outline_color if tier != null else Color(1.0, 1.0, 1.0, 0.0)
	if is_node_ready():
		_apply_tint()


## Slows it to `multiplier` of its speed for `seconds` (the Sloth). Only
## affects an active enemy; refreshes rather than stacks.
func apply_slow(multiplier: float, seconds: float) -> void:
	if not is_active():
		return
	_status.apply_slow(multiplier, seconds)
	_slow_icon.visible = _status.is_slowed()


## Normal enemies pay Gold and count toward the tier's kill gate; encounter
## enemies don't.
func gives_rewards() -> bool:
	return encounter_role == EncounterRole.NONE


func is_slowed() -> bool:
	return _status.is_slowed()


## Current speed in px/s, with any slow applied.
func get_current_speed() -> float:
	return _move_speed * _status.get_speed_factor()


func get_tier_rank() -> int:
	return _tier_rank


func get_max_health() -> float:
	return _max_health


func get_move_speed() -> float:
	return _move_speed


func get_latch_drag() -> float:
	return _latch_drag


func get_latch_dps() -> float:
	return _latch_dps


func get_kill_gold() -> float:
	return _kill_gold


## Hitbox and click radius aren't scaled by tier; they read the data directly.
func get_hitbox_radius() -> float:
	return data.hitbox_radius


func get_click_radius() -> float:
	return data.click_radius


## Called by Game after adding the enemy. `center` is the carousel center and
## `rim_radius` its edge, both in World space.
func setup(center: Vector2, rim_radius: float) -> void:
	_center = center
	_stop_distance = rim_radius + get_hitbox_radius()
	_unwrapped_bearing = (position - center).angle()
	_has_bearing = true


## Takes this tick's plain bearing (-PI..PI) and returns the unwrapped one,
## moved by the shortest change since the last call. EnemySnapshot calls this
## once per tick, after all movement. Calling it twice without moving changes nothing.
func update_bearing(wrapped_bearing: float) -> float:
	if _has_bearing:
		_unwrapped_bearing += angle_difference(_unwrapped_bearing, wrapped_bearing)
	else:
		_unwrapped_bearing = wrapped_bearing
		_has_bearing = true
	return _unwrapped_bearing


func get_unwrapped_bearing() -> float:
	return _unwrapped_bearing


## Moves one tick toward the carousel. Stops exactly at the rim, never past it.
func advance(delta: float) -> void:
	if not is_active() or delta <= 0.0:
		return
	# This tick moves at the speed it started with, then effects count down,
	# so a 3 s slow covers exactly 3 s of movement.
	var speed_factor := _status.get_speed_factor()
	_status.advance(delta)
	if _slow_icon.visible and not _status.is_slowed():
		_slow_icon.visible = false
	if _state != State.APPROACHING:
		return
	var offset := position - _center
	var distance := offset.length()
	var travel := _move_speed * speed_factor * delta
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
	_health_bar.set_fraction(_health / _max_health)
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
	_update_squash()
	set_process(true)


## Runs only while flashing. Subclasses that need _process must call super.
func _process(delta: float) -> void:
	_flash_left = maxf(0.0, _flash_left - delta)
	_update_squash()
	if _flash_left <= 0.0:
		_visual.modulate = Color.WHITE
		set_process(false)
		return
	_visual.modulate = Color.WHITE.lerp(hit_flash_modulate, _flash_left / hit_flash_seconds)


## Shows data.texture on the Sprite, scaled so its longest side is the
## placeholder's diameter. No texture: the Sprite hides and Visual draws the
## placeholder polygon instead.
func _setup_sprite() -> void:
	_outline.visible = false
	if data.texture == null:
		_sprite.visible = false
		return
	var longest := maxf(data.texture.get_width(), data.texture.get_height())
	_sprite_scale = Vector2.ONE * (2.0 * data.placeholder_size / longest)
	_sprite.texture = data.texture
	_sprite.scale = _sprite_scale
	_sprite.visible = true
	# Drawn much smaller than the file: mipmaps stop it shimmering as it turns.
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# The squash changes scale every frame; smoothing would fight it. Its
	# parents still move smoothly.
	_sprite.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	# Same pixel scale as the sprite, so the bigger outline sits evenly round it.
	if data.outline_texture != null and _outline_color.a > 0.0:
		_outline.texture = data.outline_texture
		_outline.scale = _sprite_scale
		_outline.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_outline.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		_outline.visible = true


## The tier color, as self_modulate: it tints only that node's own drawing and
## never fights the hit flash, which uses Visual's modulate.
func _apply_tint() -> void:
	_sprite.self_modulate = _tint
	_outline.self_modulate = _outline_color
	_visual.self_modulate = _tint  # the placeholder polygon, when there's no texture


## The squash: the Sprite's scale, or the placeholder's drawn size.
func _update_squash() -> void:
	if _sprite.visible:
		_sprite.scale = _sprite_scale * get_squash()
		_outline.scale = _sprite.scale
	else:
		_visual.queue_redraw()


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
