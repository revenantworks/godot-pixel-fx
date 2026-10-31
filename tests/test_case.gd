extends RefCounted
## Base class for Pixel FX Starter tests. A test is any method named test_*.
## A test may await. Call fail() or the check helpers to record a failure.
## A test that needs a real renderer calls needs_renderer() first; under
## --headless it is then counted as skipped, never as passed.

const BG := Color8(255, 0, 255)  # magenta: shows where nothing was drawn
const COLOR_TOLERANCE := 2.0 / 255.0

var tree: SceneTree
var failures: PackedStringArray = []
var skipped := false


func has_renderer() -> bool:
	return DisplayServer.get_name() != "headless"


func needs_renderer() -> bool:
	if not has_renderer():
		skipped = true
		return false
	return true


func fail(message: String) -> void:
	failures.append(message)


func check(condition: bool, message: String) -> void:
	if not condition:
		fail(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		fail("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func same_color(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) <= COLOR_TOLERANCE and absf(a.g - b.g) <= COLOR_TOLERANCE \
		and absf(a.b - b.b) <= COLOR_TOLERANCE and absf(a.a - b.a) <= COLOR_TOLERANCE


func check_pixel(img: Image, x: int, y: int, expected: Color, message: String) -> void:
	var got := img.get_pixel(x, y)
	if not same_color(got, expected):
		fail("%s at (%d,%d): expected %s, got %s" % [message, x, y, expected.to_html(), got.to_html()])


## A size x size image, transparent, with a solid block from `from` to `to` (inclusive).
func block_image(size: Vector2i, from: Vector2i, to: Vector2i, color: Color) -> Image:
	var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(from.y, to.y + 1):
		for x in range(from.x, to.x + 1):
			img.set_pixel(x, y, color)
	return img


func shader_material(path: String, params: Dictionary = {}) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load(path)
	for key: String in params:
		mat.set_shader_parameter(key, params[key])
	return mat


## Draws `texture_image` with `mat` into a fresh SubViewport over a magenta
## background and returns what the GPU drew. `offset` is the sprite's top-left
## corner; `scale` is the sprite's scale; `filter` is the node's texture filter.
func render(texture_image: Image, mat: Material, out_size: Vector2i,
		offset := Vector2.ZERO, scale := Vector2.ONE,
		filter := CanvasItem.TEXTURE_FILTER_NEAREST) -> Image:
	var vp := SubViewport.new()
	vp.size = out_size
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var bg := ColorRect.new()
	bg.color = BG
	bg.size = Vector2(out_size)
	vp.add_child(bg)
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(texture_image)
	sprite.centered = false
	sprite.position = offset
	sprite.scale = scale
	sprite.texture_filter = filter
	sprite.material = mat
	vp.add_child(sprite)
	tree.root.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	vp.queue_free()
	return img


## Every distinct colour in an image, as RGBA8 integers.
func colors_in(img: Image) -> Dictionary:
	var found := {}
	for y in img.get_height():
		for x in img.get_width():
			found[img.get_pixel(x, y).to_rgba32()] = true
	return found


## Fails when the image holds a colour that is not in `allowed`.
func check_only_colors(img: Image, allowed: Array, message: String) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var got := img.get_pixel(x, y)
			var ok := false
			for c: Color in allowed:
				if same_color(got, c):
					ok = true
					break
			if not ok:
				fail("%s: unexpected colour %s at (%d,%d)" % [message, got.to_html(), x, y])
				return
