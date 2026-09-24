class_name MountBase
extends Node2D
## Base for every mount. Lives under a slot marker on the carousel, so it
## rotates with it. The slot's +X axis points outward. Draws a code placeholder
## from its MountData until real art exists.

@export var data: MountData

var _carousel: Carousel


## Called by Game after the mount is in its slot.
func setup(carousel: Carousel) -> void:
	_carousel = carousel
	_carousel.rotation_advanced.connect(_on_rotation_advanced)


## This mount's angle on the carousel, in carousel space. Taken from the slot's
## position (not its rotation) so it's computed exactly like the booth bearing;
## rotation is stored in single precision and would sit a hair off the booth.
func get_slot_angle() -> float:
	var slot := get_parent() as Node2D
	return slot.position.angle() if slot != null else 0.0


## Override in mounts that react to rotation (Horse: booth passes; Wolf: sweeps).
func _on_rotation_advanced(_previous_angle: float, _delta_angle: float) -> void:
	pass


func _draw() -> void:
	if data == null or data.texture != null:
		return
	var points := PackedVector2Array()
	for i in data.placeholder_points:
		points.append(Vector2.from_angle(TAU * i / data.placeholder_points) * data.placeholder_size)
	draw_colored_polygon(points, data.placeholder_color)
