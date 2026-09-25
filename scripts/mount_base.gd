class_name MountBase
extends Node2D
## Base for every mount. Lives under Carousel/MountSlots, so it rotates with the
## carousel. Game places it with place(); its +X axis points outward. Draws its
## MountData texture, or a code placeholder when there's none.
## Game talks to every mount only through the functions and signals below, so a
## new mount type never needs its own branch in Game. Each has a do-nothing
## default; a mount overrides the ones it uses.

## Passed a ticket booth (Horse). Game pays GameState.get_mount_gold() per pass.
signal booth_passed(mount: MountBase, booth_index: int, pass_count: int)
## Swept a live enemy on a new pass (Wolf). Game applies this mount's damage,
## then calls apply_sweep() for anything else the contact does.
signal enemy_swept(mount: MountBase, enemy: EnemyBase)

@export var data: MountData

@export_group("Sprite")
## Turns the sprite so the top of the animal's head points outward (90°).
@export_range(-180.0, 180.0, 1.0, "suffix:°") var texture_rotation_deg: float = 90.0

var _carousel: Carousel


func _ready() -> void:
	# Sprites are drawn ~4× smaller than their files. Mipmaps (enabled in the
	# .png import) stop them shimmering as they turn, most visible at low speed.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## Called by Game once the mount is under MountSlots.
func setup(carousel: Carousel) -> void:
	_carousel = carousel
	_carousel.rotation_advanced.connect(_on_rotation_advanced)


## Moves the mount to `angle` (carousel space, radians) at `radius` from the
## center. Moving is a jump, not travel, so it never counts as a booth pass or
## a sweep. Whole pixels, like the booths, so the top spot is exactly the top.
func place(angle: float, radius: float) -> void:
	position = (Vector2.from_angle(angle) * radius).round()
	rotation = angle
	reset_physics_interpolation()


## Stops reacting to the carousel; Game calls this before removing the mount.
func teardown() -> void:
	if _carousel != null and _carousel.rotation_advanced.is_connected(_on_rotation_advanced):
		_carousel.rotation_advanced.disconnect(_on_rotation_advanced)


## Each booth's direction from the carousel center, in World space. Game calls
## this whenever the booths or mounts move.
func set_booth_bearings(_bearings: Array[float]) -> void:
	pass


## The shared list of live enemies, rebuilt by Game every tick before the
## carousel turns. Game calls this once, after setup().
func set_enemy_snapshot(_snapshot: EnemySnapshot) -> void:
	pass


## Called after the mount is placed or moved: whatever is under it now counts
## as already hit, so moving never gives a free hit.
func rebase() -> void:
	pass


## An enemy is gone; drop anything remembered about it (by instance ID).
func forget_enemy(_id: int) -> void:
	pass


## What one sweep contact does besides damage (Game applies the damage first).
## The Sloth's slow will override this.
func apply_sweep(_enemy: EnemyBase) -> void:
	pass


## This mount's angle on the carousel, in carousel space. Taken from its
## position (not its rotation) so it's computed exactly like the booth bearing;
## rotation is stored in single precision and would sit a hair off the booth.
func get_slot_angle() -> float:
	return position.angle()


## Distance from the carousel center.
func get_slot_radius() -> float:
	return position.length()


## Override in mounts that react to rotation (Horse: booth passes; Wolf: sweeps).
func _on_rotation_advanced(_previous_angle: float, _delta_angle: float) -> void:
	pass


func _draw() -> void:
	if data == null:
		return
	if data.texture != null:
		# Scale so the larger side is the placeholder's diameter.
		var tex_size := data.texture.get_size()
		var draw_size := tex_size * (2.0 * data.placeholder_size / maxf(tex_size.x, tex_size.y))
		draw_set_transform(Vector2.ZERO, deg_to_rad(texture_rotation_deg))
		draw_texture_rect(data.texture, Rect2(-draw_size / 2.0, draw_size), false)
		draw_set_transform(Vector2.ZERO)
		return
	var points := PackedVector2Array()
	for i in data.placeholder_points:
		points.append(Vector2.from_angle(TAU * i / data.placeholder_points) * data.placeholder_size)
	draw_colored_polygon(points, data.placeholder_color)
