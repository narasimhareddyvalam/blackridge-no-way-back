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
varying vec3 world_position;

const float BAR_PITCH = 1.2;
const float BAR_HALF = 0.3;
const float WHEEL_TRACK = 0.85;
const vec3 PAINT_COLOR = vec3(0.7, 0.7, 0.67);

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

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_position.xz;
	float broad = noise(p * 0.18) * 0.6 + noise(p * 0.71) * 0.4;
	float puddle = smoothstep(0.44, 0.70, broad) * wetness;
	vec2 crack_uv = p * 0.31;
	crack_uv.x += noise(p * 0.83) * 0.6;
	float crack = 1.0 - smoothstep(0.009, 0.035, abs(sin(crack_uv.x * 3.14159)));
	crack *= smoothstep(0.36, 0.65, noise(p * 0.33)) * crack_amount;
	vec2 uv = p * texture_scale;
	vec3 aggregate = texture(aggregate_color, uv).rgb;
	float paint = crossing_paint(p);
	vec3 asphalt = aggregate * dry_color * mix(1.0, 0.45, puddle) * (1.0 - crack * 0.65);
	ALBEDO = mix(asphalt, PAINT_COLOR * mix(1.0, 0.82, puddle), paint);
	float dry_roughness = mix(0.83, texture(aggregate_arm, uv).g, arm_roughness);
	dry_roughness *= mix(1.0, 0.45, damp_gloss * wetness);
	ROUGHNESS = mix(mix(dry_roughness, 0.075, puddle), mix(0.35, 0.14, wetness), paint);
	SPECULAR = 0.5;
	vec3 small_normal = texture(aggregate_normal, uv).rgb;
	float ripple = sin(length(fract(p * 2.0) - 0.5) * 72.0 - TIME * 15.0);
	small_normal.xy += vec2(ripple, -ripple) * 0.012 * puddle;
	NORMAL_MAP = mix(mix(small_normal, vec3(0.5, 0.5, 1.0), puddle * 0.8), vec3(0.5, 0.5, 1.0),
		paint * 0.7);
	NORMAL_MAP_DEPTH = 0.65;
}
