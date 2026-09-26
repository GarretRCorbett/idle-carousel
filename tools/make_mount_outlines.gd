extends SceneTree
## Builds an _outline copy of every mount sprite: the silhouette grown by
## OUTLINE_PX, in white. MountBase draws it behind the sprite, tinted with
## MountData.outline_color, the same way tiers outline enemies.
## Run from the project folder:
##   "$GODOT" --headless --path . -s res://tools/make_mount_outlines.gd
## New outline files need mipmaps on in their .import (like the sprites).

const TierSprites := preload("res://tools/make_tier_sprites.gd")

## How far the outline reaches past the sprite's edge, in file pixels. Mounts
## draw at about a fifth of their file size, so 10 px is about 2 px on screen.
const OUTLINE_PX := 10
const MOUNTS: Array[String] = ["horse", "wolf", "giraffe", "sloth", "elephant", "panda"]


func _init() -> void:
	var failed := false
	for mount in MOUNTS:
		var source := "res://assets/sprites/mounts/%s.png" % mount
		var image := Image.load_from_file(ProjectSettings.globalize_path(source))
		if image == null or image.is_empty():
			push_error("Can't read %s" % source)
			failed = true
			continue
		image.convert(Image.FORMAT_RGBA8)
		var output := source.get_basename() + "_outline.png"
		var error := TierSprites.make_outline(image, OUTLINE_PX).save_png(output)
		if error != OK:
			push_error("Can't write %s (%s)" % [output, error_string(error)])
			failed = true
			continue
		print("%s -> %s" % [source, output])
	quit(1 if failed else 0)
