extends Control
## Pixel FX Starter demo. Each shader runs on one sprite, with a slider or
## toggle for every number and on/off setting it has.
## Keys: Space = hit flash, P = pixelate the whole screen, A = animate on/off.

## One entry per effect. "node" is the Sprite2D under Stage. Every int, float
## and bool uniform of the shader has a row in "params" (tests check this).
const EFFECTS: Array[Dictionary] = [
	{"node": "Outline", "title": "outline", "params": [
		{"name": "width", "kind": "int", "min": 0, "max": 4},
		{"name": "inner", "kind": "bool"},
		{"name": "diagonals", "kind": "bool"},
		{"name": "grow", "kind": "bool"},
		{"name": "alpha_cutoff", "kind": "float", "min": 0.0, "max": 1.0},
	]},
	{"node": "HitFlash", "title": "hit_flash", "params": [
		{"name": "flash_amount", "kind": "float", "min": 0.0, "max": 1.0},
		{"name": "hard_flash", "kind": "bool"},
	]},
	{"node": "PaletteSwap", "title": "palette_swap", "params": [
		{"name": "palette_row", "kind": "int", "min": 0, "max": 3},
		{"name": "tolerance", "kind": "float", "min": 0.0, "max": 0.1},
	]},
	{"node": "Dissolve", "title": "dissolve", "params": [
		{"name": "progress", "kind": "float", "min": 0.0, "max": 1.0},
		{"name": "edge_width", "kind": "float", "min": 0.0, "max": 0.5},
		{"name": "block_size", "kind": "int", "min": 1, "max": 4},
		{"name": "seed", "kind": "int", "min": 0, "max": 9},
	]},
	{"node": "Pixelate", "title": "pixelate", "params": [
		{"name": "pixel_size", "kind": "int", "min": 1, "max": 8},
	]},
]

## Uniforms the demo sets itself instead of with a control.
const FIXED_UNIFORMS := {"pixelate": ["use_screen"]}

const COLUMN_WIDTH := 128
const SPRITE_Y := 84
const CONTROLS_Y := 136

var animate := true
var _time := 0.0
var _flash_left := 0.0
## Control for each "effect/uniform" key, so animation can move its slider.
var controls := {}

@onready var stage: Node2D = $Stage
@onready var panels: Control = $Panels
@onready var screen_pixelate: ColorRect = $ScreenPixelate/Overlay
@onready var animate_toggle: CheckBox = $Footer/Animate
@onready var screen_toggle: CheckBox = $Footer/WholeScreen


func _ready() -> void:
	for i in EFFECTS.size():
		_build_panel(i, EFFECTS[i])
	animate_toggle.button_pressed = animate
	animate_toggle.toggled.connect(func(on: bool) -> void: animate = on)
	screen_toggle.button_pressed = screen_pixelate.visible
	screen_toggle.toggled.connect(func(on: bool) -> void: screen_pixelate.visible = on)


func material_of(effect: Dictionary) -> ShaderMaterial:
	return (stage.get_node(effect.node) as Sprite2D).material as ShaderMaterial


func _build_panel(index: int, effect: Dictionary) -> void:
	var x := index * COLUMN_WIDTH
	var sprite := stage.get_node(effect.node) as Sprite2D
	sprite.position = Vector2(x + COLUMN_WIDTH / 2, SPRITE_Y)
	var title := Label.new()
	title.text = effect.title
	title.position = Vector2(x + 8, 28)
	title.size = Vector2(COLUMN_WIDTH - 16, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panels.add_child(title)
	var box := VBoxContainer.new()
	box.position = Vector2(x + 8, CONTROLS_Y)
	box.size = Vector2(COLUMN_WIDTH - 16, 0)
	box.add_theme_constant_override("separation", 0)
	panels.add_child(box)
	var mat := material_of(effect)
	for param: Dictionary in effect.params:
		box.add_child(_make_row(effect, mat, param))


func _make_row(effect: Dictionary, mat: ShaderMaterial, param: Dictionary) -> Control:
	var key: String = effect.title + "/" + param.name
	var value: Variant = mat.get_shader_parameter(param.name)
	if param.kind == "bool":
		var check := CheckBox.new()
		check.text = param.name
		check.button_pressed = bool(value)
		check.toggled.connect(func(on: bool) -> void:
			animate_toggle.button_pressed = false
			_set_uniform(effect, param.name, on))
		controls[key] = check
		return check
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var label := Label.new()
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = param.min
	slider.max_value = param.max
	slider.step = 1.0 if param.kind == "int" else 0.01
	slider.value = float(value)
	slider.custom_minimum_size = Vector2(COLUMN_WIDTH - 16, 10)
	row.add_child(slider)
	label.text = _label_text(param, slider.value)
	slider.value_changed.connect(func(v: float) -> void:
		label.text = _label_text(param, v)
		if slider.has_meta("by_code"):
			return
		animate_toggle.button_pressed = false
		_set_uniform(effect, param.name, int(v) if param.kind == "int" else v))
	slider.set_meta("label", label)
	controls[key] = slider
	return row


func _label_text(param: Dictionary, v: float) -> String:
	if param.kind == "int":
		return "%s: %d" % [param.name, int(v)]
	return "%s: %.2f" % [param.name, v]


func _set_uniform(effect: Dictionary, uniform: String, value: Variant) -> void:
	material_of(effect).set_shader_parameter(uniform, value)
	if effect.title == "pixelate":
		(screen_pixelate.material as ShaderMaterial).set_shader_parameter(uniform, value)


## Sets a uniform from code and moves its slider without turning animation off.
func drive(title: String, uniform: String, value: Variant) -> void:
	for effect in EFFECTS:
		if effect.title == title:
			_set_uniform(effect, uniform, value)
	var slider := controls.get(title + "/" + uniform) as HSlider
	if slider:
		slider.set_meta("by_code", true)
		slider.value = float(value)
		slider.remove_meta("by_code")


func flash() -> void:
	_flash_left = 0.18


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_SPACE:
			flash()
		KEY_P:
			screen_toggle.button_pressed = not screen_toggle.button_pressed
		KEY_A:
			animate_toggle.button_pressed = not animate_toggle.button_pressed


func _process(delta: float) -> void:
	if animate:
		_time += delta
		if fmod(_time, 1.5) < delta:
			flash()
		var phase := fmod(_time / 3.0, 2.0)
		drive("dissolve", "progress", snappedf(phase if phase < 1.0 else 2.0 - phase, 0.01))
		drive("palette_swap", "palette_row", int(_time) % 4)
	if _flash_left > 0.0:
		_flash_left -= delta
		drive("hit_flash", "flash_amount", 1.0 if _flash_left > 0.0 else 0.0)
