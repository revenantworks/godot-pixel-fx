// Pixel FX Starter: dissolve
// A noise dissolve that removes whole pixels (or whole blocks), with an edge colour.
// Apache-2.0. See addons/pixel_fx/LICENSE and addons/pixel_fx/NOTICE.
shader_type canvas_item;

// In fragment(), Godot's COLOR already holds the (filtered) texture colour,
// so the node's modulate is carried in from vertex() instead.
varying vec4 modulate;

// 0 = whole sprite, 1 = fully gone.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Colour of the pixels about to disappear.
uniform vec4 edge_color : source_color = vec4(1.0, 0.55, 0.1, 1.0);
// Share of the noise range painted with the edge colour.
uniform float edge_width : hint_range(0.0, 0.5) = 0.08;
// Size of one dissolve block, in texture pixels.
uniform int block_size : hint_range(1, 16) = 1;
// Change this for a different dissolve pattern.
uniform int seed = 0;

// Integer hash (no sin()), so the pattern is the same on every GPU.
float hash(ivec2 p, int s) {
	uint h = uint(p.x) * 374761393u + uint(p.y) * 668265263u + uint(s) * 2246822519u;
	h = (h ^ (h >> 13u)) * 1274126177u;
	h = h ^ (h >> 16u);
	return float(h & 0x00FFFFFFu) / 16777216.0;
}

void vertex() {
	modulate = COLOR;
}

void fragment() {
	ivec2 size = textureSize(TEXTURE, 0);
	ivec2 p = ivec2(floor(UV * vec2(size)));
	vec4 c = texelFetch(TEXTURE, p, 0);
	int b = max(block_size, 1);
	float n = hash(p / b, seed);
	float t = clamp(progress, 0.0, 1.0);
	if (t >= 1.0 || n < t) {
		c.a = 0.0;
	} else if (t > 0.0 && n < t + edge_width) {
		c.rgb = edge_color.rgb;
		c.a *= edge_color.a;
	}
	COLOR = c * modulate;
}
