// Pixel FX Starter: palette_swap
// Swaps colours through a small palette texture.
// Palette layout: row 0 holds the source colours, one per pixel, left to right.
// Each row below it holds one replacement palette in the same column order.
// Apache-2.0. See addons/pixel_fx/LICENSE and addons/pixel_fx/NOTICE.
shader_type canvas_item;

// In fragment(), Godot's COLOR already holds the (filtered) texture colour,
// so the node's modulate is carried in from vertex() instead.
varying vec4 modulate;

uniform sampler2D palette : filter_nearest, repeat_disable;
// Which palette row to use. 0 keeps the original colours.
uniform int palette_row : hint_range(0, 63) = 1;
// How close a sprite colour must be to a source colour to match (0 to 1 per channel).
uniform float tolerance : hint_range(0.0, 0.1) = 0.004;

const int MAX_COLORS = 64;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	ivec2 size = textureSize(TEXTURE, 0);
	vec4 c = texelFetch(TEXTURE, ivec2(floor(UV * vec2(size))), 0);
	ivec2 pal_size = textureSize(palette, 0);
	int row = clamp(palette_row, 0, pal_size.y - 1);
	if (row > 0 && c.a > 0.0) {
		int count = min(pal_size.x, MAX_COLORS);
		for (int i = 0; i < MAX_COLORS; i++) {
			if (i >= count) { break; }
			vec4 src = texelFetch(palette, ivec2(i, 0), 0);
			vec3 d = abs(c.rgb - src.rgb);
			if (max(d.r, max(d.g, d.b)) <= tolerance) {
				c.rgb = texelFetch(palette, ivec2(i, row), 0).rgb;
				break;
			}
		}
	}
	COLOR = c * modulate;
}
