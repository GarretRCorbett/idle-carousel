extends GdUnitTestSuite
## Enemy scenes and their Sprite layer (Phase 3 Step 3e): textures, size,
## tier tint vs hit flash, squash on the Sprite, and the placeholder fallback.

const SCENES: Array[String] = [
	"res://scenes/enemies/Leaf.tscn",
	"res://scenes/enemies/Stick.tscn",
	"res://scenes/enemies/Rock.tscn",
]


func _spawn(path: String, data_override: EnemyData = null) -> EnemyBase:
	var enemy := (load(path) as PackedScene).instantiate() as EnemyBase
	if data_override != null:
		enemy.data = data_override
	var tier := TierData.new()
	tier.tier_id = &"test"
	tier.tint = Color(0.3, 0.5, 1.0)
	enemy.configure(tier, 1.0)
	add_child(enemy)
	auto_free(enemy)
	return enemy


func test_every_enemy_scene_shows_its_sprite_at_its_size() -> void:
	for path in SCENES:
		var enemy := _spawn(path)
		var sprite := enemy.get_node("Visual/Sprite") as Sprite2D
		assert_object(enemy.data.texture).override_failure_message(path).is_not_null()
		assert_bool(sprite.visible).is_true()
		assert_object(sprite.texture).is_same(enemy.data.texture)
		# Longest side drawn = the placeholder's diameter.
		var drawn := sprite.texture.get_size() * sprite.scale
		assert_float(maxf(drawn.x, drawn.y)).is_equal_approx(2.0 * enemy.data.placeholder_size, 0.001)


func test_stick_and_rock_use_their_own_data() -> void:
	assert_str(String(_spawn(SCENES[1]).data.id)).is_equal("stick")
	assert_str(String(_spawn(SCENES[2]).data.id)).is_equal("rock")


func test_tint_on_the_sprite_survives_the_flash_and_squash_recovers() -> void:
	var enemy := _spawn(SCENES[0])
	var sprite := enemy.get_node("Visual/Sprite") as Sprite2D
	var visual := enemy.get_node("Visual") as Node2D
	var rest_scale := sprite.scale
	assert_object(sprite.self_modulate).is_equal(Color(0.3, 0.5, 1.0))
	enemy.take_damage(0.5)
	assert_object(visual.modulate).is_equal(enemy.hit_flash_modulate)
	assert_object(sprite.self_modulate).is_equal(Color(0.3, 0.5, 1.0))
	assert_vector(sprite.scale).is_equal_approx(rest_scale * enemy.hit_squash_scale, Vector2(0.0001, 0.0001))
	enemy._process(enemy.hit_flash_seconds)
	assert_object(visual.modulate).is_equal(Color.WHITE)
	assert_object(sprite.self_modulate).is_equal(Color(0.3, 0.5, 1.0))
	assert_vector(sprite.scale).is_equal_approx(rest_scale, Vector2(0.0001, 0.0001))


func test_no_texture_falls_back_to_the_placeholder() -> void:
	var data := (load("res://resources/enemies/leaf.tres") as EnemyData).duplicate() as EnemyData
	data.texture = null
	var enemy := _spawn(SCENES[0], data)
	assert_bool((enemy.get_node("Visual/Sprite") as Sprite2D).visible).is_false()
	assert_object((enemy.get_node("Visual") as Node2D).self_modulate).is_equal(Color(0.3, 0.5, 1.0))


## Sticks rock side to side while flying in (within sway_degrees) and hold
## still once latched.
func test_stick_sways_while_approaching_and_stops_at_the_rim() -> void:
	var stick := _spawn(SCENES[1]) as EnemyStick
	stick.position = Vector2(300.0, 0.0)
	stick.setup(Vector2.ZERO, 100.0)
	var visual := stick.get_node("Visual") as Node2D
	var angles: Array[float] = []
	for i in 60:
		stick.advance(1.0 / 60.0)
		angles.append(visual.rotation)
		assert_float(absf(visual.rotation)).is_less_equal(deg_to_rad(stick.sway_degrees) + 0.0001)
	assert_float(angles.max() - angles.min()).is_greater(0.1)  # it actually moved
	stick.advance(100.0)  # reaches the rim
	var held := visual.rotation
	stick.advance(0.5)
	assert_float(visual.rotation).is_equal(held)


## Tiers with an outline color (Charcoal) show a light edge behind the sprite,
## same scale and squash; tiers without one don't.
func test_outline_shows_only_in_tiers_that_have_one() -> void:
	var plain := _spawn(SCENES[2])
	assert_bool((plain.get_node("Visual/Outline") as Sprite2D).visible).is_false()
	var charcoal := load("res://resources/tiers/tier_catalog.tres").get_tier(5) as TierData
	assert_float(charcoal.outline_color.a).is_greater(0.0)
	var enemy := (load(SCENES[2]) as PackedScene).instantiate() as EnemyBase
	enemy.configure(charcoal, 1.0)
	add_child(enemy)
	auto_free(enemy)
	var outline := enemy.get_node("Visual/Outline") as Sprite2D
	var sprite := enemy.get_node("Visual/Sprite") as Sprite2D
	assert_bool(outline.visible).is_true()
	assert_object(outline.self_modulate).is_equal(charcoal.outline_color)
	assert_vector(outline.scale).is_equal(sprite.scale)
	# The outline is bigger than the sprite on every side.
	assert_bool(outline.texture.get_width() > sprite.texture.get_width()).is_true()
	enemy.take_damage(0.5)
	assert_vector(outline.scale).is_equal(sprite.scale)
