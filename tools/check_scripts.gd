extends SceneTree
## Compiles every project GDScript and loads every scene with autoload singletons
## and global classes registered, so references like GameState resolve. Run it via
## tools/check.sh or tools/check.bat rather than directly.

const SKIP_DIRS: PackedStringArray = ["res://.godot", "res://addons"]


func _initialize() -> void:
	# Autoloads are registered but not yet in the tree. Detach them so their
	# _ready() never runs; the check should compile code, not execute it.
	for child in root.get_children():
		root.remove_child(child)
		child.free()

	var own_path: String = get_script().resource_path
	var failed := 0
	for path in _find_files("res://", "gd"):
		if path == own_path:
			continue
		var script := ResourceLoader.load(path, "GDScript", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		if script == null or not script.can_instantiate():
			printerr("CHECK FAIL: %s" % path)
			failed += 1
	# Scenes load even with unknown node types or bad parent paths; those only
	# error on instantiate. Build each scene outside the tree (no _ready) and
	# free it. The wrappers fail on any ERROR: line this prints.
	for path in _find_files("res://", "tscn"):
		var scene := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		var node: Node = scene.instantiate() if scene != null and scene.can_instantiate() else null
		if node == null:
			printerr("CHECK FAIL: %s" % path)
			failed += 1
			continue
		# A node with a bad parent path only warns and gets moved under the root,
		# so confirm every node the file defines ended up where it says.
		var state := scene.get_state()
		for i in state.get_node_count():
			var node_path := state.get_node_path(i)
			if node.get_node_or_null(node_path) == null:
				printerr("CHECK FAIL: %s node '%s' is not at its parent path" % [path, node_path])
				failed += 1
		node.free()
	quit(1 if failed > 0 else 0)


func _find_files(dir_path: String, extension: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub in DirAccess.get_directories_at(dir_path):
		var sub_path := dir_path.path_join(sub)
		if sub_path not in SKIP_DIRS:
			found.append_array(_find_files(sub_path, extension))
	for file in DirAccess.get_files_at(dir_path):
		if file.get_extension() == extension:
			found.append(dir_path.path_join(file))
	return found
