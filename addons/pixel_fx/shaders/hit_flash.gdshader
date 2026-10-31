// Pixel FX Starter: hit_flash
// Flashes a sprite one colour. Drive `flash_amount` from code or an AnimationPlayer.
// Apache-2.0. See addons/pixel_fx/LICENSE and addons/pixel_fx/NOTICE.
shader_type canvas_item;

// In fragment(), Godot's COLOR already holds the (filtered) texture colour,
// so the node's modulate is carried in from vertex() instead.
varying vec4 modulate;

// The flash colour. Its alpha scales how strong the flash can get.
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// 0 = normal sprite, 1 = full flash colour.
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
// true: snap to all-or-nothing at 0.5, so no in-between colours appear.
uniform bool hard_flash = false;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	ivec2 size = textureSize(TEXTURE, 0);
	vec4 c = texelFetch(TEXTURE, ivec2(floor(UV * vec2(size))), 0);
	float amount = clamp(flash_amount, 0.0, 1.0);
	if (hard_flash) {
		amount = step(0.5, amount);
	}
	c.rgb = mix(c.rgb, flash_color.rgb, amount * flash_color.a);
	COLOR = c * modulate;
}
