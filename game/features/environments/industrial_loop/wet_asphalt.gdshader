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
varying vec3 world_position;

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
	ALBEDO = aggregate * dry_color * mix(1.0, 0.45, puddle) * (1.0 - crack * 0.65);
	float dry_roughness = mix(0.83, texture(aggregate_arm, uv).g, arm_roughness);
	dry_roughness *= mix(1.0, 0.45, damp_gloss * wetness);
	ROUGHNESS = mix(dry_roughness, 0.075, puddle);
	SPECULAR = 0.5;
	vec3 small_normal = texture(aggregate_normal, uv).rgb;
	float ripple = sin(length(fract(p * 2.0) - 0.5) * 72.0 - TIME * 15.0);
	small_normal.xy += vec2(ripple, -ripple) * 0.012 * puddle;
	NORMAL_MAP = mix(small_normal, vec3(0.5, 0.5, 1.0), puddle * 0.8);
	NORMAL_MAP_DEPTH = 0.65;
}
