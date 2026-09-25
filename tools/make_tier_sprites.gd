extends SceneTree
## Rebuilds the light-grey enemy sprites from the untouched Kenney packs in
## ../kenney_assets/. Tier colors multiply the sprite, so the art has to be
## light grey: each picture's brightness is mapped into [MIN_LIGHT, MAX_LIGHT],
## keeping its shading, then trimmed to its visible pixels and scaled down.
## Each also gets an _outline copy: the silhouette grown by OUTLINE_PX, in
## white, drawn behind the sprite in tiers that need an outline (Charcoal).
## Run from the project folder:
##   "$GODOT" --headless --path . -s res://tools/make_tier_sprites.gd
## Then log any new file in assets/PROVENANCE.md.

## Darkest and lightest grey in the output (0..1).
const MIN_LIGHT := 0.55
const MAX_LIGHT := 1.0
## Longest side of each output, in pixels. Enemies draw at 20-32 px, so this
## leaves room for zoom and high-DPI screens; mipmaps handle the rest.
const OUTPUT_SIZE := 96
## How far the outline copy reaches past the sprite's edge, in output pixels.
## Enemies draw at about a third of OUTPUT_SIZE, so 5 px is about 1.5 px on screen.
const OUTLINE_PX := 5

## [source path inside ../kenney_assets/, output path]
const JOBS: Array = [
	["foliage-sprites/PNG/Shaded/sprite_0082.png", "res://assets/sprites/enemies/leaf.png"],
	["foliage-pack/PNG/Default size/foliagePack_022.png", "res://assets/sprites/enemies/stick.png"],
	["foliage-pack/PNG/Default size/foliagePack_055.png", "res://assets/sprites/enemies/rock.png"],
]


func _init() -> void:
	var kenney := ProjectSettings.globalize_path("res://").path_join("../kenney_assets")
	var failed := false
	for job in JOBS:
		var source: String = kenney.path_join(job[0])
		var image := Image.load_from_file(source)
		if image == null or image.is_empty():
			push_error("Can't read %s" % source)
			failed = true
			continue
		var output := make_light_grey(image)
		var error := output.save_png(job[1])
		if error != OK:
			push_error("Can't write %s (%s)" % [job[1], error_string(error)])
			failed = true
			continue
		var outline_path: String = String(job[1]).get_basename() + "_outline.png"
		error = make_outline(output).save_png(outline_path)
		if error != OK:
			push_error("Can't write %s (%s)" % [outline_path, error_string(error)])
			failed = true
		print("%s -> %s (%dx%d) + outline" % [job[0], job[1], output.get_width(), output.get_height()])
	quit(1 if failed else 0)


## Trimmed, scaled to OUTPUT_SIZE on its longest side, and mapped to light grey.
static func make_light_grey(source: Image) -> Image:
	var image := source.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	image = image.get_region(image.get_used_rect())
	var longest := maxi(image.get_width(), image.get_height())
	if longest > OUTPUT_SIZE:
		var factor := float(OUTPUT_SIZE) / longest
		image.resize(maxi(1, roundi(image.get_width() * factor)), maxi(1, roundi(image.get_height() * factor)),
				Image.INTERPOLATE_LANCZOS)
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			var light := lerpf(MIN_LIGHT, MAX_LIGHT, color.get_luminance())
			image.set_pixel(x, y, Color(light, light, light, color.a))
	return image


## The silhouette grown by OUTLINE_PX on every side, in white. It's
## 2 × OUTLINE_PX bigger than the sprite, so drawn centered at the same scale
## it sits evenly around it.
static func make_outline(sprite: Image) -> Image:
	var pad := OUTLINE_PX
	var outline := Image.create_empty(sprite.get_width() + 2 * pad, sprite.get_height() + 2 * pad, false, Image.FORMAT_RGBA8)
	for y in outline.get_height():
		for x in outline.get_width():
			var alpha := 0.0
			for dy in range(-pad, pad + 1):
				for dx in range(-pad, pad + 1):
					if dx * dx + dy * dy > pad * pad:
						continue
					var sx := x - pad + dx
					var sy := y - pad + dy
					if sx < 0 or sy < 0 or sx >= sprite.get_width() or sy >= sprite.get_height():
						continue
					alpha = maxf(alpha, sprite.get_pixel(sx, sy).a)
			outline.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return outline
