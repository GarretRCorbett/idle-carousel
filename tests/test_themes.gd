extends GdUnitTestSuite
## Themes (planning/phase3/theming_plan.md): stable enemy ids, sound theme
## data, skins that change looks but never combat, boss renames, and scenery
## that recolors and switches back.


func after_test() -> void:
	ThemeManager.set_theme(&"park")


func _enemy_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for file in DirAccess.get_files_at("res://resources/enemies/"):
		if file.ends_with(".tres"):
			ids.append((load("res://resources/enemies/" + file) as EnemyData).id)
	return ids


func _spawn(path: String) -> EnemyBase:
	var enemy := (load(path) as PackedScene).instantiate() as EnemyBase
	add_child(enemy)
	auto_free(enemy)
	return enemy


func test_every_enemy_has_a_unique_id() -> void:
	var ids := _enemy_ids()
	assert_bool(ids.has(&"")).override_failure_message("an enemy has no id").is_false()
	for id in ids:
		assert_int(ids.count(id)).override_failure_message("id '%s' is used twice" % id).is_equal(1)


func test_themes_are_sound_and_the_park_comes_first() -> void:
	var themes := ThemeManager.get_themes()
	assert_str(String(themes[0].id)).is_equal("park")
	assert_array(themes[0].enemy_skins).is_empty()
	var ids := _enemy_ids()
	for theme in themes:
		assert_array(theme.get_problems(ids)).is_empty()


## The test themes dress every enemy, so none looks out of place.
func test_test_themes_skin_every_enemy() -> void:
	for theme_id in [&"winter_test", &"halloween_test"]:
		assert_bool(ThemeManager.set_theme(theme_id)).is_true()
		for id in _enemy_ids():
			assert_object(ThemeManager.get_theme().get_skin(id)).override_failure_message(
					"%s has no skin for %s" % [theme_id, id]).is_not_null()


## A skin changes looks only: the same Leaf under Winter keeps its stats,
## hitbox and click radius, and draws a shape instead of the sprite.
func test_skin_changes_looks_but_not_combat() -> void:
	var normal := _spawn("res://scenes/enemies/Leaf.tscn")
	ThemeManager.set_theme(&"winter_test")
	var themed := _spawn("res://scenes/enemies/Leaf.tscn")
	assert_float(themed.get_max_health()).is_equal(normal.get_max_health())
	assert_float(themed.get_move_speed()).is_equal(normal.get_move_speed())
	assert_float(themed.get_hitbox_radius()).is_equal(normal.get_hitbox_radius())
	assert_float(themed.get_click_radius()).is_equal(normal.get_click_radius())
	assert_float(themed.get_kill_gold()).is_equal(normal.get_kill_gold())
	var skin := ThemeManager.get_theme().get_skin(&"leaf")
	assert_float(themed.get_visual_size()).is_equal(skin.visual_size)
	assert_bool((themed.get_node("Visual/Sprite") as Sprite2D).visible).is_false()
	assert_bool((normal.get_node("Visual/Sprite") as Sprite2D).visible).is_true()


## Enemies already out switch look when the theme changes, and back.
func test_refresh_look_follows_the_theme() -> void:
	var enemy := _spawn("res://scenes/enemies/Rock.tscn")
	var sprite := enemy.get_node("Visual/Sprite") as Sprite2D
	ThemeManager.set_theme(&"winter_test")
	enemy.refresh_look()
	assert_bool(sprite.visible).is_false()
	ThemeManager.set_theme(&"park")
	enemy.refresh_look()
	assert_bool(sprite.visible).is_true()
	assert_object(sprite.texture).is_same(enemy.data.texture)


## A theme can rename a boss; bosses it doesn't name keep their own name.
func test_theme_can_rename_a_boss() -> void:
	var boss := load("res://resources/bosses/leaf_storm.tres") as BossData
	var other := load("res://resources/bosses/stick_giant.tres") as BossData
	var renamed := ParkTheme.new()
	renamed.id = &"rename_test"
	renamed.boss_name_keys = {boss.boss_id: "BOSS_STICK_GIANT"}
	ThemeManager.use_theme(renamed)
	assert_str(ThemeManager.boss_name_key(boss)).is_equal("BOSS_STICK_GIANT")
	assert_str(ThemeManager.boss_name_key(other)).is_equal(other.name_key)


## Scenery takes the theme's colors and gets its own back afterwards.
func test_scenery_recolors_and_switches_back() -> void:
	var park := ParkBackground.new()
	add_child(park)
	auto_free(park)
	var pavement := park.pavement_color
	var roofs := park.roof_colors.duplicate()
	ThemeManager.set_theme(&"halloween_test")
	var overrides: Dictionary = ThemeManager.get_theme().scenery[&"park_background"]
	assert_that(park.pavement_color).is_equal(overrides["pavement_color"])
	assert_that(park.roof_colors).is_equal(overrides["roof_colors"])
	ThemeManager.set_theme(&"winter_test")
	assert_that(park.roof_colors).is_equal(roofs)  # Winter keeps the park's roofs
	ThemeManager.set_theme(&"park")
	assert_that(park.pavement_color).is_equal(pavement)
