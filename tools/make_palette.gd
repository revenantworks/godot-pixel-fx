extends SceneTree
## Builds a palette texture for palette_swap.gdshader from a sprite.
## Row 0 gets every distinct opaque colour of the sprite (up to 64), sorted.
## Each row below it is the same colours with the hue turned further round.
##
## Run from the project folder:
##   godot --headless --path . -s res://tools/make_palette.gd -- res://demo/art/sprite.png res://demo/art/sprite_palette.png 3
## Arguments: sprite path, output path, number of replacement rows (default 3).

const MAX_COLORS := 64


static func build_palette(sprite: Image, rows: int) -> Image:
	var seen := {}
	for y in sprite.get_height():
		for x in sprite.get_width():
			var c := sprite.get_pixel(x, y)
			if c.a > 0.0:
				seen[c.to_rgba32()] = c
	var keys := seen.keys()
	keys.sort()
	keys = keys.slice(0, MAX_COLORS)
	var pal := Image.create_empty(max(keys.size(), 1), rows + 1, false, Image.FORMAT_RGBA8)
	for i in keys.size():
		var src: Color = seen[keys[i]]
		pal.set_pixel(i, 0, src)
		for r in range(1, rows + 1):
			var shifted := Color.from_hsv(fposmod(src.h + float(r) / float(rows + 1), 1.0), src.s, src.v, 1.0)
			pal.set_pixel(i, r, shifted)
	return pal


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("usage: -- <sprite.png> <palette.png> [rows]")
		quit(2)
		return
	var rows := int(args[2]) if args.size() > 2 else 3
	var sprite := Image.load_from_file(ProjectSettings.globalize_path(args[0]))
	if sprite == null or sprite.is_empty():
		push_error("cannot read " + args[0])
		quit(1)
		return
	sprite.convert(Image.FORMAT_RGBA8)
	var pal := build_palette(sprite, rows)
	var err := pal.save_png(ProjectSettings.globalize_path(args[1]))
	print("wrote ", args[1], " colours=", pal.get_width(), " rows=", rows, " err=", err)
	quit(0 if err == OK else 1)
