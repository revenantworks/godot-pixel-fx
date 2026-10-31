extends "res://tests/test_case.gd"
## Each shader compiles and exposes exactly the uniforms the README documents.
## Runs under --headless: the dummy renderer still compiles shader code.

const DIR := "res://addons/pixel_fx/shaders/"


func uniform_names(path: String) -> Array:
	var shader := load(path) as Shader
	if shader == null:
		fail("cannot load " + path)
		return []
	var names := []
	for u in shader.get_shader_uniform_list():
		names.append(u.name)
	names.sort()
	return names


func check_uniforms(file: String, expected: Array) -> void:
	expected.sort()
	var got := uniform_names(DIR + file)
	check_eq(got, expected, file + " uniforms (an empty list means it did not compile)")


func test_outline_compiles_with_its_uniforms() -> void:
	check_uniforms("outline.gdshader",
		["outline_color", "width", "inner", "diagonals", "grow", "alpha_cutoff"])


func test_hit_flash_compiles_with_its_uniforms() -> void:
	check_uniforms("hit_flash.gdshader", ["flash_color", "flash_amount", "hard_flash"])


func test_palette_swap_compiles_with_its_uniforms() -> void:
	check_uniforms("palette_swap.gdshader", ["palette", "palette_row", "tolerance"])


func test_dissolve_compiles_with_its_uniforms() -> void:
	check_uniforms("dissolve.gdshader",
		["progress", "edge_color", "edge_width", "block_size", "seed"])


func test_pixelate_compiles_with_its_uniforms() -> void:
	# Godot does not list hint_screen_texture uniforms, so screen_texture is absent.
	check_uniforms("pixelate.gdshader", ["pixel_size", "use_screen"])
