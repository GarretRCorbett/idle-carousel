class_name GuideIcon
extends Control
## The picture on a Park Guide page: the mount or enemy sprite (in the current
## theme), a tier's color, an event's token, or a small code-drawn sign for a
## mechanic. An entry not met yet is drawn as a dark silhouette (Hades style).

## Behind every icon.
@export var backdrop_color: Color = Color(0.0, 0.0, 0.0, 0.25)
## What an undiscovered entry is drawn in (alpha keeps the shape readable).
@export var silhouette_color: Color = Color(0.05, 0.04, 0.07, 0.9)
## Outlines on tier swatches and event tokens.
@export var ink_color: Color = Color(0.13, 0.1, 0.16, 1.0)
## Mechanic signs.
@export var mechanic_color: Color = Color(0.48, 0.64, 1.0, 1.0)
@export var overdrive_color: Color = Color(1.0, 0.82, 0.3, 1.0)
@export var danger_color: Color = Color(0.85, 0.35, 0.4, 1.0)
## How much of the box the picture fills.
@export_range(0.3, 1.0, 0.05) var fill: float = 0.8

var entry: GuideEntry:
	set(value):
		entry = value
		refresh()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	ThemeManager.theme_changed.connect(_on_theme_changed)


func _on_theme_changed(_theme: ParkTheme) -> void:
	queue_redraw()


## Redraws, as a silhouette if the entry hasn't been met (the same drawing,
## multiplied down to one dark color).
func refresh() -> void:
	self_modulate = Color.WHITE if entry == null or entry.is_discovered() else silhouette_color
	queue_redraw()


func _draw() -> void:
	var half := minf(size.x, size.y) * 0.5
	draw_circle(size * 0.5, half, backdrop_color, true, -1.0, true)
	if entry == null:
		return
	var radius := half * fill
	draw_set_transform(size * 0.5)
	match entry.kind:
		GuideEntry.Kind.MOUNT:
			_draw_mount(entry.data as MountData, radius)
		GuideEntry.Kind.ENEMY:
			_draw_enemy(entry.data as EnemyData, radius, Color.WHITE)
		GuideEntry.Kind.TIER:
			_draw_tier(entry.data as TierData, radius)
		GuideEntry.Kind.BOSS:
			_draw_enemy(entry.boss_body, radius, entry.tier.tint if entry.tier != null else Color.WHITE)
		GuideEntry.Kind.EVENT:
			EventPickup.draw_token(self, entry.data as EventData, radius * 0.75, ink_color)
		GuideEntry.Kind.MECHANIC:
			_draw_mechanic(entry.id, radius)
	draw_set_transform(Vector2.ZERO)


func _draw_mount(data: MountData, radius: float) -> void:
	if data == null:
		return
	if data.texture != null:
		_draw_texture_fit(data.texture, radius, Color.WHITE)
	else:
		_draw_polygon(data.placeholder_points, radius, data.placeholder_color)


## Its skin in the current theme; `tint` is the tier color (bosses), as in play.
func _draw_enemy(data: EnemyData, radius: float, tint: Color) -> void:
	if data == null:
		return
	var skin := ThemeManager.skin_for(data)
	if skin.texture != null:
		_draw_texture_fit(skin.texture, radius, tint)
	else:
		skin.draw_shape(self, radius)


func _draw_tier(tier: TierData, radius: float) -> void:
	if tier == null:
		return
	var edge := tier.outline_color if tier.outline_color.a > 0.0 else ink_color
	draw_circle(Vector2.ZERO, radius * 0.8, edge, true, -1.0, true)
	draw_circle(Vector2.ZERO, radius * 0.8 - 3.0, tier.tint, true, -1.0, true)


func _draw_mechanic(id: StringName, radius: float) -> void:
	var r := radius * 0.7
	match id:
		&"boost", &"auto_boost":
			for i in 2:
				var y := r * (0.35 - 0.6 * i)
				draw_polyline(PackedVector2Array([Vector2(-r * 0.6, y + r * 0.4), Vector2(0.0, y - r * 0.2),
						Vector2(r * 0.6, y + r * 0.4)]), mechanic_color, maxf(2.0, r * 0.2), true)
			if id == &"auto_boost":
				draw_arc(Vector2.ZERO, r * 1.2, -PI * 0.2, PI * 1.3, 32, mechanic_color, maxf(1.5, r * 0.1), true)
		&"overdrive":
			var bolt := PackedVector2Array([Vector2(0.15, -1.0), Vector2(-0.45, 0.1), Vector2(-0.05, 0.1),
					Vector2(-0.2, 1.0), Vector2(0.5, -0.2), Vector2(0.08, -0.2)])
			for i in bolt.size():
				bolt[i] *= r
			draw_colored_polygon(bolt, overdrive_color)
		&"latch":
			var width := maxf(2.0, r * 0.18)
			draw_arc(Vector2(-r * 0.35, 0.0), r * 0.45, 0.0, TAU, 24, mechanic_color, width, true)
			draw_arc(Vector2(r * 0.35, 0.0), r * 0.45, 0.0, TAU, 24, danger_color, width, true)
		&"stall":
			draw_rect(Rect2(-r * 0.55, -r * 0.7, r * 0.4, r * 1.4), danger_color)
			draw_rect(Rect2(r * 0.15, -r * 0.7, r * 0.4, r * 1.4), danger_color)


## `texture` scaled to fit a circle of `radius`, keeping its shape.
func _draw_texture_fit(texture: Texture2D, radius: float, tint: Color) -> void:
	var tex_size := texture.get_size()
	var scale_to := radius * 2.0 / maxf(tex_size.x, tex_size.y)
	var drawn := tex_size * scale_to
	draw_texture_rect(texture, Rect2(-drawn * 0.5, drawn), false, tint)


func _draw_polygon(points: int, radius: float, color: Color) -> void:
	var polygon := PackedVector2Array()
	for i in maxi(points, 3):
		polygon.append(Vector2.from_angle(TAU * i / maxi(points, 3) - PI * 0.5) * radius)
	draw_colored_polygon(polygon, color)
