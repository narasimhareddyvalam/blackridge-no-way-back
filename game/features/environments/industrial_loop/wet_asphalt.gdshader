shader_type spatial;
render_mode specular_schlick_ggx;

uniform sampler2D aggregate_color : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D aggregate_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec3 dry_color : source_color = vec3(0.38, 0.41, 0.43);
uniform float wetness : hint_range(0.0, 1.0) = 0.86;
uniform sampler2D aggregate_arm : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float arm_roughness : hint_range(0.0, 1.0) = 0.0;
uniform float damp_gloss : hint_range(0.0, 1.0) = 0.0;
uniform float texture_scale = 0.68;
uniform float crack_amount : hint_range(0.0, 1.0) = 1.0;
uniform vec2 crossing_centre = vec2(0.0);
uniform vec2 crossing_along = vec2(1.0, 0.0);
uniform vec2 crossing_size = vec2(0.0);
uniform float crossing_wear : hint_range(0.0, 1.0) = 0.45;
uniform float rain_rings : hint_range(0.0, 1.0) = 1.0;
varying vec3 world_position;

const float BAR_PITCH = 1.2;
const float BAR_HALF = 0.3;
const float WHEEL_TRACK = 0.85;
const vec3 PAINT_COLOR = vec3(0.7, 0.7, 0.67);
const float RING_CELL = 0.25;
const float RING_EVERY = 0.5;
const float RING_LIFE = 0.36;
const float RING_SPEED = 0.3;
const float RING_WAVE = 0.012;
const float RING_SLOPE = 0.5;
const float PUDDLE_LEVEL = 0.62;
const float FILM_ROUGHNESS = 0.16;
const float WET_STONE_ROUGHNESS = 0.22;
const float FILM_RINGS = 0.45;
const float DANCE_SLOPE = 0.05;
const float DANCE_RATE = 5.0;
const int RING_LAYERS = 4;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

float crossing_paint(vec2 p) {
	if (crossing_size.x <= 0.0) {
		return 0.0;
	}
	vec2 rel = p - crossing_centre;
	float along = dot(rel, crossing_along);
	float across = dot(rel, vec2(-crossing_along.y, crossing_along.x));
	vec2 half_size = crossing_size * 0.5;
	if (abs(along) > half_size.x + 0.05 || abs(across) > half_size.y) {
		return 0.0;
	}
	float edge = 0.012;
	float from_bar = abs(fract(across / BAR_PITCH) - 0.5) * BAR_PITCH;
	float bar = 1.0 - smoothstep(BAR_HALF - edge, BAR_HALF + edge, from_bar);
	bar *= 1.0 - smoothstep(half_size.x - edge, half_size.x + edge, abs(along));
	float track = 1.0 - smoothstep(0.15, 0.45, abs(abs(across) - WHEEL_TRACK));
	float speckle = noise(p * 9.0) * 0.6 + noise(p * 31.0) * 0.4;
	float wear = track * crossing_wear + smoothstep(0.55, 0.9, speckle) * 0.5;
	return bar * clamp(1.0 - wear, 0.0, 1.0);
}

vec2 ring_slope(vec2 p, float layer, float wave, float time) {
	vec2 grid = p / RING_CELL + vec2(0.37, 0.71) * layer;
	vec2 cell = floor(grid);
	float clock = time / RING_EVERY + hash(cell + 13.1 * layer);
	float drop = floor(clock);
	float age = fract(clock) * RING_EVERY;
	if (age > RING_LIFE) {
		return vec2(0.0);
	}
	vec2 jitter = vec2(hash(cell + drop * 0.73 + 3.1), hash(cell + drop * 1.37 + 7.7)) - 0.5;
	vec2 from_centre = grid - cell - 0.5;
	vec2 rel = (from_centre - jitter * 0.2) * RING_CELL;
	float r = max(length(rel), 0.0001);
	float behind = RING_SPEED * age - r;
	float packet = exp(-pow(behind / (1.6 * wave) - 1.0, 2.0))
		* smoothstep(-0.3 * wave, 0.3 * wave, behind);
	float fade = 1.0 - age / RING_LIFE;
	float inside = 1.0 - smoothstep(0.42, 0.5, max(abs(from_centre.x), abs(from_centre.y)));
	float slope = RING_SLOPE * (RING_WAVE / wave) * fade * fade * packet * inside
		* cos(6.2831853 * behind / wave);
	return slope * rel / r;
}

vec2 dance_at(vec2 p, float size, float time) {
	vec2 cell = floor(p / size);
	float clock = time * DANCE_RATE + hash(cell) * 7.0;
	float tick = floor(clock);
	vec2 before = vec2(hash(cell + tick * 0.37), hash(cell + tick * 0.91 + 5.0));
	vec2 after = vec2(hash(cell + (tick + 1.0) * 0.37), hash(cell + (tick + 1.0) * 0.91 + 5.0));
	return mix(before, after, smoothstep(0.0, 1.0, fract(clock))) - 0.5;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_position.xz;
	vec2 uv = p * texture_scale;
	vec3 aggregate = texture(aggregate_color, uv).rgb;
	float broad = noise(p * 0.18) * 0.6 + noise(p * 0.71) * 0.4;
	float stones = dot(aggregate, vec3(0.333)) - 0.5;
	float water = smoothstep(-0.008, 0.008, broad - PUDDLE_LEVEL - stones * 0.06);
	float puddle = water * wetness;
	float film = smoothstep(0.35, 0.7, noise(p * 0.25 + 7.3) * 0.65 + noise(p * 0.9 + 1.9) * 0.35);
	film = max(film, smoothstep(-0.06, 0.0, broad - PUDDLE_LEVEL)) * wetness;
	float stone_top = smoothstep(-0.26, -0.23, stones);
	vec2 crack_uv = p * 0.31;
	crack_uv.x += noise(p * 0.83) * 0.6;
	float crack = 1.0 - smoothstep(0.009, 0.035, abs(sin(crack_uv.x * 3.14159)));
	crack *= smoothstep(0.36, 0.65, noise(p * 0.33)) * crack_amount;
	float paint = crossing_paint(p);
	vec3 asphalt = aggregate * dry_color * mix(1.0, 0.75, film) * mix(1.0, 0.45, puddle)
		* (1.0 - crack * 0.65);
	ALBEDO = mix(asphalt, PAINT_COLOR * mix(1.0, 0.82, puddle), paint);
	float footprint = max(length(dFdx(p)), length(dFdy(p)));
	float wave = max(RING_WAVE, footprint * 2.5);
	float unresolved = smoothstep(RING_WAVE, RING_WAVE * 4.0, footprint);
	float dry_roughness = mix(0.83, texture(aggregate_arm, uv).g, arm_roughness);
	dry_roughness *= mix(1.0, 0.45, damp_gloss * wetness);
	float pool_roughness = mix(0.075, 0.075 + 0.1 * rain_rings, unresolved);
	float film_roughness = mix(FILM_ROUGHNESS, WET_STONE_ROUGHNESS, stone_top);
	float surface_roughness = mix(dry_roughness, film_roughness, film);
	ROUGHNESS = mix(mix(surface_roughness, pool_roughness, water), mix(0.35, 0.14, wetness), paint);
	SPECULAR = 0.5;
	vec3 small_normal = texture(aggregate_normal, uv).rgb;
	vec2 rings = vec2(0.0);
	float ringing = max(water, film * FILM_RINGS * (1.0 - stone_top));
	if (ringing > 0.01 && rain_rings > 0.0) {
		for (int layer = 0; layer < RING_LAYERS; layer++) {
			rings += ring_slope(p, float(layer), wave, TIME);
		}
		rings *= ringing * rain_rings;
		float lod = log2(max(footprint * 2.0, 0.01) / 0.01);
		float level = floor(lod);
		vec2 dance = mix(dance_at(p, 0.01 * exp2(level), TIME),
			dance_at(p, 0.01 * exp2(level + 1.0), TIME), lod - level);
		rings += dance * 2.0 * DANCE_SLOPE * unresolved * ringing * rain_rings;
	}
	vec3 tilt = vec3(-rings.x, 0.0, -rings.y);
	vec2 ring_xy = vec2(dot(tilt, (INV_VIEW_MATRIX * vec4(TANGENT, 0.0)).xyz),
		dot(tilt, (INV_VIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz));
	vec3 base_normal = mix(small_normal, vec3(0.5, 0.5, 1.0),
		max(water, film * (1.0 - stone_top)));
	base_normal.xy += ring_xy * 0.5 / 0.65;
	NORMAL_MAP = mix(base_normal, vec3(0.5, 0.5, 1.0), paint * 0.7);
	NORMAL_MAP_DEPTH = 0.65;
}
