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
	assert_str(_spawn(SCENES[1]).data.enemy_name).is_equal("Stick")
	assert_str(_spawn(SCENES[2]).data.enemy_name).is_equal("Rock")


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
