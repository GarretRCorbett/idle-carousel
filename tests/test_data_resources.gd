extends GdUnitTestSuite
## Smoke tests for the mount and enemy .tres data files.

const MOUNT_DIR := "res://resources/mounts"
const ENEMY_DIR := "res://resources/enemies"


func test_leaf_gold_drop() -> void:
	var leaf := load(ENEMY_DIR.path_join("leaf.tres")) as EnemyData
	assert_object(leaf).is_not_null()
	assert_float(leaf.gold_drop).is_equal(2.0)


func test_all_mounts_load_as_mount_data() -> void:
	var files := _tres_files(MOUNT_DIR)
	assert_int(files.size()).is_equal(6)
	for file in files:
		assert_object(load(file) as MountData).override_failure_message(
				"%s is not a MountData" % file).is_not_null()


## Each mount's id matches its shop upgrade, so damage upgrades find it.
func test_mount_ids_match_their_shop_upgrades() -> void:
	for file in _tres_files(MOUNT_DIR):
		var data := load(file) as MountData
		assert_str(String(data.mount_id)).is_equal(file.get_file().get_basename())
	for upgrade in UpgradeManager.get_definitions():
		if upgrade.effect_type == UpgradeData.EffectType.BUY_MOUNT:
			var mount := upgrade.mount_scene.instantiate() as MountBase
			assert_str(String(mount.data.mount_id)).is_equal(String(upgrade.id))
			mount.free()


func test_mount_damage_upgrade_needs_a_target() -> void:
	var upgrade := UpgradeData.new()
	upgrade.id = &"fang"
	upgrade.effect_type = UpgradeData.EffectType.ADD_MOUNT_DAMAGE
	assert_bool(upgrade.get_problems().is_empty()).is_false()
	upgrade.target_mount = &"wolf"
	assert_bool(upgrade.get_problems().is_empty()).is_true()


func test_all_enemies_load_as_enemy_data() -> void:
	var files := _tres_files(ENEMY_DIR)
	assert_int(files.size()).is_equal(5)
	for file in files:
		assert_object(load(file) as EnemyData).override_failure_message(
				"%s is not an EnemyData" % file).is_not_null()


func _tres_files(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	for file in DirAccess.get_files_at(dir_path):
		if file.get_extension() == "tres":
			found.append(dir_path.path_join(file))
	return found
