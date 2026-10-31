// Pixel FX Starter: pixelate
// Screen-space pixelate. Put it on a ColorRect that covers the screen, inside a
// CanvasLayer (pixelates what is drawn below it) or inside a SubViewport.
// Set `use_screen` to false to pixelate the node's own texture instead
// (for example a TextureRect that shows a SubViewport).
// Apache-2.0. See addons/pixel_fx/LICENSE and addons/pixel_fx/NOTICE.
shader_type canvas_item;

// In fragment(), Godot's COLOR already holds the (filtered) texture colour,
// so the node's modulate is carried in from vertex() instead.
varying vec4 modulate;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
// Size of one big pixel, in screen pixels (or texture pixels when use_screen is false).
uniform int pixel_size : hint_range(1, 64) = 4;
// true: read the screen behind the node. false: read the node's own texture.
uniform bool use_screen = true;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	int s = max(pixel_size, 1);
	if (use_screen) {
		vec2 px = floor(SCREEN_UV / SCREEN_PIXEL_SIZE);
		vec2 cell = floor(px / float(s)) * float(s);
		vec2 uv = (cell + 0.5) * SCREEN_PIXEL_SIZE;
		COLOR = texture(screen_texture, uv);
	} else {
		ivec2 size = textureSize(TEXTURE, 0);
		ivec2 p = ivec2(floor(UV * vec2(size)));
		ivec2 cell = (p / s) * s;
		COLOR = texelFetch(TEXTURE, cell, 0) * modulate;
	}
}
