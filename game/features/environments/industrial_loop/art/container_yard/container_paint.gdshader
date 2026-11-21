// A container's paint as a real box's is (the audit, #351): its livery from its instance colour,
// its markings painted on (ISO 6346): its owner code, serial and check digit and its size-type
// panel with its ratings on its right-hand door, its line's name along each side and its code at
// each side's top right corner, inked white on dark paint and black on light; and its wear, its
// own (INSTANCE_CUSTOM.b): rain streaks running down from the roof rail, dirt and rust along the
// bottom rail and at the corners, the roof grimier, each box a little faded its own way.
// INSTANCE_CUSTOM: r its code strip, g its line, b its wear seed. The mesh's frame: length along
// x, doors at +x, width along z, the origin the middle of the bottom (`build_containers.py`).
shader_type spatial;
render_mode cull_back;

uniform sampler2D codes : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D door_marks : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D line_names : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 code_grid = vec2(8.0, 16.0);
uniform float lines = 8.0;
uniform float panel_index = 0.0;
uniform float half_length = 3.029;
uniform float tall = 2.591;
uniform float half_width = 1.219;
uniform float roughness_paint = 0.55;
uniform float metallic_paint = 0.25;
uniform vec3 rust : source_color = vec3(0.32, 0.16, 0.08);
uniform vec3 grime : source_color = vec3(0.14, 0.13, 0.11);
// The right-hand door's panel between its two locking bars (at z -0.35 and -0.95).
const float DOOR_FROM = -0.39;
const float DOOR_WIDE = 0.52;
// Real boxes' paint seen under floods: deeper and more saturated than the livery's flat colour,
// and a film of road dirt over it, heavier toward the bottom.
const float DARKEN = 0.92;
const float SATURATE = 1.1;
const float GRIME = 0.8;

varying vec3 local;
varying vec3 local_normal;
varying vec3 tint;
varying vec3 custom;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	local = VERTEX;
	local_normal = NORMAL;
	tint = mix(COLOR.rgb / 12.92, pow((COLOR.rgb + 0.055) / 1.055, vec3(2.4)),
		step(0.04045, COLOR.rgb));
	custom = INSTANCE_CUSTOM.rgb;
}

// The mark's coverage (0..1) at `uv` (0..1 across the mark's rectangle) in a texture's cell.
float mark(sampler2D sheet, vec2 uv, vec2 cell, vec2 grid) {
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return 0.0;
	}
	return texture(sheet, (cell + uv) / grid).a;
}

void fragment() {
	float seed = custom.b;
	vec3 base = tint * DARKEN * (0.88 + 0.16 * hash(vec2(seed, 1.7)));
	float grey = dot(base, vec3(0.299, 0.587, 0.114));
	vec3 paint = mix(vec3(grey), base, SATURATE);
	float ink_dark = step(0.18, dot(tint, vec3(0.299, 0.587, 0.114)));
	vec3 ink = mix(vec3(0.93, 0.93, 0.9), vec3(0.06, 0.06, 0.06), ink_dark);
	vec2 code_cell = vec2(mod(custom.r, code_grid.x), floor(custom.r / code_grid.x));
	float painted = 0.0;
	float along = 0.0;
	float up = local.y / tall;
	bool door = local_normal.x > 0.7 && local.x > half_length - 0.03;
	bool side = abs(local.z) > half_width - 0.06 && (abs(local_normal.z) > 0.7
		|| (abs(local_normal.x) > 0.7 && abs(local.x) < half_length - 0.15));
	bool roof = local_normal.y > 0.7 && local.y > tall - 0.2;
	if (door) {
		along = local.z;
		vec2 code_uv = vec2((DOOR_FROM - local.z) / 0.9, (tall - 0.3 - local.y) / 0.11);
		painted = max(painted, mark(codes, code_uv, code_cell, code_grid));
		vec2 panel_uv = vec2((DOOR_FROM - local.z) / DOOR_WIDE, (tall - 0.42 - local.y)
			/ DOOR_WIDE);
		painted = max(painted, mark(door_marks, panel_uv, vec2(panel_index, 0.0),
			vec2(3.0, 1.0)));
	} else if (side) {
		along = local.x;
		float facing = sign(local.z);
		float x = local.x * facing;
		float wide = min(4.8, half_length * 1.1);
		vec2 name_uv = vec2((x + wide * 0.5) / wide, (tall * 0.62 - local.y) / (wide / 8.0)
			+ 0.5);
		painted = max(painted, mark(line_names, name_uv, vec2(0.0, custom.g), vec2(1.0, lines)));
		vec2 corner_uv = vec2((x - (half_length - 1.25)) / 0.95, (tall - 0.33 - local.y) / 0.12);
		painted = max(painted, mark(codes, corner_uv, code_cell, code_grid));
	}
	float streaks = 0.0;
	if (door || side) {
		float column = hash(vec2(floor(along * 30.0), seed * 31.0));
		float runs = smoothstep(0.66, 1.0, column);
		float length_down = 0.25 + 0.6 * hash(vec2(floor(along * 30.0), seed * 17.0 + 2.0));
		streaks = runs * smoothstep(1.0 - length_down, 1.0, up) * (0.4 + 0.6 * hash(vec2(seed,
			9.1)));
	}
	float low = 1.0 - smoothstep(0.0, 0.18, up);
	float post = max(1.0 - smoothstep(0.0, 0.14, half_length - abs(local.x)),
		1.0 - smoothstep(0.0, 0.1, half_width - abs(local.z)));
	float caster = post * max(low, smoothstep(0.85, 1.0, up));
	float spots = smoothstep(0.7, 0.9, noise(vec2(along * 14.0, local.y * 14.0) + seed * 13.0));
	float rusting = clamp(low * (0.25 + 0.75 * spots) * (0.4 + seed) + caster * 0.6 + spots
		* 0.12 * seed, 0.0, 1.0);
	vec3 colour = mix(paint, ink, painted * (0.88 + 0.12 * (1.0 - streaks)));
	float film = 0.18 + 0.22 * noise(vec2(along * 1.3, local.y * 0.9) + seed * 4.0)
		+ 0.3 * (1.0 - smoothstep(0.0, 0.45, up));
	colour = mix(colour, colour * 0.55 + grime * 0.45, film * GRIME);
	colour = mix(colour, colour * 0.5 + mix(grime, rust, 0.4) * 0.3, streaks * 0.75);
	colour = mix(colour, rust, rusting * 0.65);
	if (roof) {
		colour = mix(colour, grime, 0.35 + 0.25 * noise(local.xz * 1.5 + seed * 5.0));
	}
	ALBEDO = colour;
	ROUGHNESS = clamp(roughness_paint + 0.25 * streaks + 0.3 * rusting, 0.0, 1.0);
	METALLIC = metallic_paint * (1.0 - rusting);
}
