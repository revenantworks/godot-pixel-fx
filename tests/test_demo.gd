extends "res://tests/test_case.gd"
## The demo scene loads, wires every node, has a control for every number
## and toggle uniform, and its animation moves the uniforms. Runs headless.

const DEMO := "res://demo/demo.tscn"
const SHADER_FOR := {
	"Outline": "outline", "HitFlash": "hit_flash", "PaletteSwap": "palette_swap",
	"Dissolve": "dissolve", "Pixelate": "pixelate",
}


func add_demo() -> Control:
	var demo: Control = (load(DEMO) as PackedScene).instantiate()
	tree.root.add_child(demo)
	await tree.process_frame
	return demo


func test_demo_scene_loads_with_five_effect_sprites() -> void:
	var demo := await add_demo()
	var sprites := demo.get_node("Stage").get_children().filter(func(n: Node) -> bool: return n is Sprite2D)
	check_eq(sprites.size(), 5, "effect sprites")
	for path in ["Panels", "Footer/Animate", "Footer/WholeScreen", "ScreenPixelate/Overlay"]:
		check(demo.has_node(path), "missing node " + path)
	demo.queue_free()


func test_each_sprite_uses_its_own_shader() -> void:
	var demo := await add_demo()
	for node_name: String in SHADER_FOR:
		var sprite := demo.get_node("Stage/" + node_name) as Sprite2D
		var mat := sprite.material as ShaderMaterial
		check(mat != null and mat.shader != null, node_name + " has no shader material")
		if mat and mat.shader:
			check_eq(mat.shader.resource_path.get_file(), SHADER_FOR[node_name] + ".gdshader", node_name + " shader")
		check(sprite.texture != null, node_name + " has no texture")
	demo.queue_free()


func test_every_number_and_toggle_uniform_has_a_control() -> void:
	var demo := await add_demo()
	var total := 0
	for effect: Dictionary in demo.EFFECTS:
		var mat: ShaderMaterial = demo.material_of(effect)
		var fixed: Array = demo.FIXED_UNIFORMS.get(effect.title, [])
		var wanted := []
		for u in mat.shader.get_shader_uniform_list():
			if u.type in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL] and not fixed.has(u.name):
				wanted.append(u.name)
		wanted.sort()
		var listed := []
		for p: Dictionary in effect.params:
			listed.append(p.name)
			check(demo.controls.has(effect.title + "/" + p.name), "no control for " + effect.title + "/" + p.name)
		listed.sort()
		check_eq(listed, wanted, effect.title + " controls")
		total += listed.size()
	check_eq(demo.controls.size(), total, "control count")
	demo.queue_free()


func test_animation_moves_the_dissolve_and_palette() -> void:
	var demo := await add_demo()
	# Drive the demo clock by hand so the result does not depend on frame rate.
	demo.set_process(false)
	var dissolve: ShaderMaterial = demo.material_of(demo.EFFECTS[3])
	var palette: ShaderMaterial = demo.material_of(demo.EFFECTS[2])
	var flash: ShaderMaterial = demo.material_of(demo.EFFECTS[1])
	var rows_seen := {}
	var flashed := false
	for i in 25:
		demo._process(0.1)
		rows_seen[palette.get_shader_parameter("palette_row")] = true
		flashed = flashed or float(flash.get_shader_parameter("flash_amount")) > 0.0
	check(float(dissolve.get_shader_parameter("progress")) > 0.0, "dissolve progress did not move")
	check_eq(rows_seen.size(), 3, "palette rows seen in 2.5 seconds")
	check(flashed, "hit flash did not fire")
	demo.animate_toggle.button_pressed = false
	check(not demo.animate, "animate toggle did not stop animation")
	demo.queue_free()
