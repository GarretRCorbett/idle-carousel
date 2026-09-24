extends SceneTree
## Compiles every project GDScript with autoload singletons and global classes
## registered, so references like GameState resolve. Run it via tools/check.sh or
## tools/check.bat rather than directly.

const SKIP_DIRS: PackedStringArray = ["res://.godot", "res://addons"]


func _initialize() -> void:
	# Autoloads are registered but not yet in the tree. Detach them so their
	# _ready() never runs; the check should compile code, not execute it.
	for child in root.get_children():
		root.remove_child(child)
		child.free()

	var own_path: String = get_script().resource_path
	var failed := 0
	for path in _find_scripts("res://"):
		if path == own_path:
			continue
		var script := ResourceLoader.load(path, "GDScript", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		if script == null or not script.can_instantiate():
			printerr("CHECK FAIL: %s" % path)
			failed += 1
	quit(1 if failed > 0 else 0)


func _find_scripts(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub in DirAccess.get_directories_at(dir_path):
		var sub_path := dir_path.path_join(sub)
		if sub_path not in SKIP_DIRS:
			found.append_array(_find_scripts(sub_path))
	for file in DirAccess.get_files_at(dir_path):
		if file.get_extension() == "gd":
			found.append(dir_path.path_join(file))
	return found
