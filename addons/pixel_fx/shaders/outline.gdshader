// Pixel FX Starter: outline
// A whole-pixel outline, outside or inside the sprite.
// Apache-2.0. See addons/pixel_fx/LICENSE and addons/pixel_fx/NOTICE.
shader_type canvas_item;

// In fragment(), Godot's COLOR already holds the (filtered) texture colour,
// so the node's modulate is carried in from vertex() instead.
varying vec4 modulate;

// Outline colour. The node's modulate alpha still fades it.
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// Width in whole texture pixels. 0 turns the outline off.
uniform int width : hint_range(0, 8) = 1;
// false: outline outside the sprite. true: outline on the sprite's own edge pixels.
uniform bool inner = false;
// true: corner neighbours count too (square outline). false: plus-shaped (rounder).
uniform bool diagonals = false;
// true: grow the quad by `width` pixels so an outer outline is not cut off
// by a sprite that has no transparent border. Only for a whole texture,
// not for a region or atlas frame.
uniform bool grow = false;
// A pixel counts as solid when its alpha is above this value.
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.01;

const int MAX_WIDTH = 8;

bool inside(ivec2 p, ivec2 size) {
	return p.x >= 0 && p.y >= 0 && p.x < size.x && p.y < size.y;
}

void vertex() {
	modulate = COLOR;
	if (grow && width > 0) {
		vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
		vec2 dir = UV * 2.0 - 1.0;
		VERTEX += dir * float(width);
		UV = (UV * tex_size + dir * float(width)) / tex_size;
	}
}

void fragment() {
	ivec2 size = textureSize(TEXTURE, 0);
	ivec2 p = ivec2(floor(UV * vec2(size)));
	vec4 c = inside(p, size) ? texelFetch(TEXTURE, p, 0) : vec4(0.0);
	bool solid = c.a > alpha_cutoff;
	int w = clamp(width, 0, MAX_WIDTH);
	bool edge = false;
	if (w > 0) {
		for (int dy = -MAX_WIDTH; dy <= MAX_WIDTH; dy++) {
			if (abs(dy) > w) { continue; }
			for (int dx = -MAX_WIDTH; dx <= MAX_WIDTH; dx++) {
				if (abs(dx) > w || (dx == 0 && dy == 0)) { continue; }
				if (!diagonals && abs(dx) + abs(dy) > w) { continue; }
				ivec2 q = p + ivec2(dx, dy);
				float a = inside(q, size) ? texelFetch(TEXTURE, q, 0).a : 0.0;
				bool n_solid = a > alpha_cutoff;
				if (inner ? (solid && !n_solid) : (!solid && n_solid)) {
					edge = true;
				}
			}
		}
	}
	if (edge) {
		COLOR = vec4(outline_color.rgb, outline_color.a * modulate.a);
	} else {
		COLOR = c * modulate;
	}
}
