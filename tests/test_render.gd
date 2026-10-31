extends "res://tests/test_case.gd"
## Pixel-exact render tests. They draw each shader on a GPU and read the
## pixels back. They need a real renderer (a desktop, or Xvfb with Mesa);
## under --headless they are counted as skipped.

const DIR := "res://addons/pixel_fx/shaders/"
const RED := Color(1, 0, 0)
const GREEN := Color(0, 1, 0)
const BLUE := Color(0, 0, 1)
const YELLOW := Color(1, 1, 0)
const CYAN := Color(0, 1, 1)
const WHITE := Color(1, 1, 1)
const GRAY := Color8(128, 128, 128)
const EDGE := Color8(255, 140, 26)


## 8x8, transparent, red block from (2,2) to (5,5).
func fixture() -> Image:
	return block_image(Vector2i(8, 8), Vector2i(2, 2), Vector2i(5, 5), RED)


func outline(params: Dictionary) -> Material:
	var p := {"outline_color": GREEN}
	p.merge(params, true)
	return shader_material(DIR + "outline.gdshader", p)


# --- outline ---------------------------------------------------------------

func test_outline_outer_plus_shape() -> void:
	if not needs_renderer(): return
	var img := await render(fixture(), outline({"width": 1}), Vector2i(8, 8))
	for y in range(2, 6):
		check_pixel(img, 1, y, GREEN, "left outline")
		check_pixel(img, 6, y, GREEN, "right outline")
	check_pixel(img, 3, 1, GREEN, "top outline")
	check_pixel(img, 1, 1, BG, "corner stays empty without diagonals")
	check_pixel(img, 0, 3, BG, "width 1 stops at 1 pixel")
	check_pixel(img, 3, 3, RED, "sprite pixel kept")


func test_outline_outer_with_diagonals() -> void:
	if not needs_renderer(): return
	var img := await render(fixture(), outline({"width": 1, "diagonals": true}), Vector2i(8, 8))
	check_pixel(img, 1, 1, GREEN, "corner filled with diagonals")
	check_pixel(img, 6, 6, GREEN, "far corner filled with diagonals")


func test_outline_width_two() -> void:
	if not needs_renderer(): return
	var img := await render(fixture(), outline({"width": 2}), Vector2i(8, 8))
	check_pixel(img, 0, 3, GREEN, "second ring")
	check_pixel(img, 1, 1, GREEN, "plus shape at distance 2")
	check_pixel(img, 0, 0, BG, "outside the plus shape")


func test_outline_inner() -> void:
	if not needs_renderer(): return
	var img := await render(fixture(), outline({"width": 1, "inner": true}), Vector2i(8, 8))
	check_pixel(img, 2, 3, GREEN, "edge pixel becomes outline")
	check_pixel(img, 3, 3, RED, "centre pixel kept")
	check_pixel(img, 1, 3, BG, "nothing drawn outside")


func test_outline_width_zero_changes_nothing() -> void:
	if not needs_renderer(): return
	var img := await render(fixture(), outline({"width": 0}), Vector2i(8, 8))
	check_pixel(img, 1, 3, BG, "no outline")
	check_pixel(img, 2, 2, RED, "sprite kept")


func test_outline_grow_draws_outside_the_texture() -> void:
	if not needs_renderer(): return
	var full := block_image(Vector2i(4, 4), Vector2i.ZERO, Vector2i(3, 3), RED)
	var cut := await render(full, outline({"width": 1}), Vector2i(8, 8), Vector2(2, 2))
	check_pixel(cut, 1, 3, BG, "without grow the outline is cut off")
	var grown := await render(full, outline({"width": 1, "grow": true}), Vector2i(8, 8), Vector2(2, 2))
	check_pixel(grown, 1, 3, GREEN, "grow: left outline")
	check_pixel(grown, 6, 3, GREEN, "grow: right outline")
	check_pixel(grown, 3, 1, GREEN, "grow: top outline")
	check_pixel(grown, 2, 2, RED, "grow: sprite still in place")
	check_pixel(grown, 1, 1, BG, "grow: corner empty")


# --- hit_flash -------------------------------------------------------------

func test_hit_flash_zero_changes_nothing() -> void:
	if not needs_renderer(): return
	var mat := shader_material(DIR + "hit_flash.gdshader", {"flash_color": BLUE, "flash_amount": 0.0})
	var img := await render(fixture(), mat, Vector2i(8, 8))
	check_pixel(img, 3, 3, RED, "sprite kept")


func test_hit_flash_full_paints_only_the_sprite() -> void:
	if not needs_renderer(): return
	var mat := shader_material(DIR + "hit_flash.gdshader", {"flash_color": BLUE, "flash_amount": 1.0})
	var img := await render(fixture(), mat, Vector2i(8, 8))
	check_pixel(img, 3, 3, BLUE, "sprite flashed")
	check_pixel(img, 0, 0, BG, "transparent pixels stay transparent")


func test_hit_flash_hard_snaps_at_half() -> void:
	if not needs_renderer(): return
	var low := shader_material(DIR + "hit_flash.gdshader", {"flash_color": BLUE, "flash_amount": 0.4, "hard_flash": true})
	var high := shader_material(DIR + "hit_flash.gdshader", {"flash_color": BLUE, "flash_amount": 0.6, "hard_flash": true})
	check_pixel(await render(fixture(), low, Vector2i(8, 8)), 3, 3, RED, "0.4 snaps to off")
	check_pixel(await render(fixture(), high, Vector2i(8, 8)), 3, 3, BLUE, "0.6 snaps to on")


# --- palette_swap ----------------------------------------------------------

## Row 0: red, yellow. Row 1: blue, cyan. Row 2: green, white.
func palette_texture() -> ImageTexture:
	var pal := Image.create_empty(2, 3, false, Image.FORMAT_RGBA8)
	for entry in [[0, 0, RED], [1, 0, YELLOW], [0, 1, BLUE], [1, 1, CYAN], [0, 2, GREEN], [1, 2, WHITE]]:
		pal.set_pixel(entry[0], entry[1], entry[2])
	return ImageTexture.create_from_image(pal)


## The red fixture with one yellow pixel at (3,3) and one gray pixel at (4,4).
func palette_fixture() -> Image:
	var img := fixture()
	img.set_pixel(3, 3, YELLOW)
	img.set_pixel(4, 4, GRAY)
	return img


func swap(row: int) -> Material:
	return shader_material(DIR + "palette_swap.gdshader", {"palette": palette_texture(), "palette_row": row})


func test_palette_swap_row_one_and_unmatched_colours() -> void:
	if not needs_renderer(): return
	var img := await render(palette_fixture(), swap(1), Vector2i(8, 8))
	check_pixel(img, 2, 2, BLUE, "red to blue")
	check_pixel(img, 3, 3, CYAN, "yellow to cyan")
	check_pixel(img, 4, 4, GRAY, "colour not in the palette is kept")
	check_pixel(img, 0, 0, BG, "transparent kept")


func test_palette_swap_row_two() -> void:
	if not needs_renderer(): return
	var img := await render(palette_fixture(), swap(2), Vector2i(8, 8))
	check_pixel(img, 2, 2, GREEN, "red to green")
	check_pixel(img, 3, 3, WHITE, "yellow to white")


func test_palette_swap_row_zero_keeps_the_original() -> void:
	if not needs_renderer(): return
	var img := await render(palette_fixture(), swap(0), Vector2i(8, 8))
	check_pixel(img, 2, 2, RED, "red kept")
	check_pixel(img, 3, 3, YELLOW, "yellow kept")


# --- dissolve --------------------------------------------------------------

func full_red(size: int) -> Image:
	return block_image(Vector2i(size, size), Vector2i.ZERO, Vector2i(size - 1, size - 1), RED)


func dissolve(params: Dictionary) -> Material:
	var p := {"edge_color": EDGE, "edge_width": 0.0}
	p.merge(params, true)
	return shader_material(DIR + "dissolve.gdshader", p)


func count_color(img: Image, color: Color) -> int:
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			if same_color(img.get_pixel(x, y), color):
				n += 1
	return n


func test_dissolve_zero_changes_nothing() -> void:
	if not needs_renderer(): return
	var img := await render(full_red(16), dissolve({"progress": 0.0, "edge_width": 0.2}), Vector2i(16, 16))
	check_eq(count_color(img, RED), 256, "red pixels at progress 0")


func test_dissolve_one_removes_everything() -> void:
	if not needs_renderer(): return
	var img := await render(full_red(16), dissolve({"progress": 1.0, "edge_width": 0.2}), Vector2i(16, 16))
	check_eq(count_color(img, BG), 256, "empty pixels at progress 1")


func test_dissolve_half_removes_about_half() -> void:
	if not needs_renderer(): return
	var img := await render(full_red(32), dissolve({"progress": 0.5}), Vector2i(32, 32))
	var gone := count_color(img, BG)
	check(gone > 1024 * 0.4 and gone < 1024 * 0.6, "removed %d of 1024, expected 40 to 60 percent" % gone)
	check_eq(gone + count_color(img, RED), 1024, "every pixel is either gone or untouched")


func test_dissolve_paints_the_edge_band() -> void:
	if not needs_renderer(): return
	var img := await render(full_red(32), dissolve({"progress": 0.4, "edge_width": 0.2}), Vector2i(32, 32))
	var edge := count_color(img, EDGE)
	check(edge > 1024 * 0.1 and edge < 1024 * 0.3, "edge pixels %d of 1024, expected 10 to 30 percent" % edge)
	check_eq(edge + count_color(img, BG) + count_color(img, RED), 1024, "only red, edge or empty pixels")


func test_dissolve_same_seed_same_pattern() -> void:
	if not needs_renderer(): return
	var a := await render(full_red(16), dissolve({"progress": 0.5, "seed": 3}), Vector2i(16, 16))
	var b := await render(full_red(16), dissolve({"progress": 0.5, "seed": 3}), Vector2i(16, 16))
	var c := await render(full_red(16), dissolve({"progress": 0.5, "seed": 4}), Vector2i(16, 16))
	check(a.get_data() == b.get_data(), "same seed gave a different pattern")
	check(a.get_data() != c.get_data(), "a new seed gave the same pattern")


func test_dissolve_blocks_are_whole() -> void:
	if not needs_renderer(): return
	var img := await render(full_red(16), dissolve({"progress": 0.5, "block_size": 4}), Vector2i(16, 16))
	for by in range(0, 16, 4):
		for bx in range(0, 16, 4):
			var first := img.get_pixel(bx, by)
			for y in range(by, by + 4):
				for x in range(bx, bx + 4):
					if not same_color(img.get_pixel(x, y), first):
						fail("block at (%d,%d) is split" % [bx, by])
						return


# --- pixelate --------------------------------------------------------------

## 8x8 where every pixel has its own colour.
func gradient() -> Image:
	var img := Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 8:
			img.set_pixel(x, y, Color8(x * 32, y * 32, 200))
	return img


func test_pixelate_texture_mode() -> void:
	if not needs_renderer(): return
	var mat := shader_material(DIR + "pixelate.gdshader", {"pixel_size": 2, "use_screen": false})
	var src := gradient()
	var img := await render(src, mat, Vector2i(8, 8))
	for y in 8:
		for x in 8:
			check_pixel(img, x, y, src.get_pixel(x - x % 2, y - y % 2), "block colour")
			if not failures.is_empty(): return


func test_pixelate_screen_mode() -> void:
	if not needs_renderer(): return
	var src := gradient()
	var vp := SubViewport.new()
	vp.size = Vector2i(8, 8)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(src)
	sprite.centered = false
	vp.add_child(sprite)
	var layer := CanvasLayer.new()
	var overlay := ColorRect.new()
	overlay.size = Vector2(8, 8)
	overlay.material = shader_material(DIR + "pixelate.gdshader", {"pixel_size": 4, "use_screen": true})
	layer.add_child(overlay)
	vp.add_child(layer)
	tree.root.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	vp.queue_free()
	for y in 8:
		for x in 8:
			check_pixel(img, x, y, src.get_pixel(x - x % 4, y - y % 4), "screen block colour")
			if not failures.is_empty(): return


# --- the pixel-art bar -----------------------------------------------------

func test_no_shader_blends_half_pixels_under_linear_filter() -> void:
	if not needs_renderer(): return
	# The node asks for linear filtering and a non-integer scale. Every shader
	# reads whole texels, so only exact source or effect colours may appear.
	var src := palette_fixture()
	var cases := [
		[outline({"width": 1}), [RED, YELLOW, GRAY, GREEN, BG]],
		[shader_material(DIR + "hit_flash.gdshader", {"flash_color": BLUE, "flash_amount": 1.0}), [BLUE, BG]],
		[swap(1), [BLUE, CYAN, GRAY, BG]],
		[dissolve({"progress": 0.3, "edge_width": 0.2}), [RED, YELLOW, GRAY, EDGE, BG]],
		[shader_material(DIR + "pixelate.gdshader", {"pixel_size": 2, "use_screen": false}), [RED, YELLOW, GRAY, BG]],
	]
	for entry in cases:
		var img := await render(src, entry[0], Vector2i(24, 24), Vector2(1, 1), Vector2(2.5, 2.5), CanvasItem.TEXTURE_FILTER_LINEAR)
		check_only_colors(img, entry[1], (entry[0] as ShaderMaterial).shader.resource_path.get_file())
