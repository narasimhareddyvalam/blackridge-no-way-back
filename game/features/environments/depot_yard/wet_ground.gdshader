shader_type spatial;

uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D arm_map : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float texture_metres = 3.0;
uniform vec3 tint : source_color = vec3(1.0);
uniform float wetness : hint_range(0.0, 1.0) = 0.55;
uniform float puddle_amount : hint_range(0.0, 1.0) = 0.38;
uniform float puddle_metres = 9.0;

varying vec3 world_position;

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 local = fract(point);
	vec2 curve = local * local * (3.0 - 2.0 * local);
	float bottom = mix(hash(cell), hash(cell + vec2(1.0, 0.0)), curve.x);
	float top = mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), curve.x);
	return mix(bottom, top, curve.y);
}

float fbm(vec2 point) {
	float total = 0.0;
	float weight = 0.5;
	for (int octave = 0; octave < 4; octave++) {
		total += weight * value_noise(point);
		point *= 2.03;
		weight *= 0.5;
	}
	return total;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 near_uv = world_position.xz / texture_metres;
	vec2 far_uv = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * near_uv * 0.37 + 0.21;
	float layer = smoothstep(0.35, 0.65, fbm(world_position.xz * 0.05));
	vec3 albedo = mix(texture(albedo_map, near_uv).rgb, texture(albedo_map, far_uv).rgb, layer);
	vec3 arm = mix(texture(arm_map, near_uv).rgb, texture(arm_map, far_uv).rgb, layer);
	vec3 normal = mix(texture(normal_map, near_uv).rgb, texture(normal_map, far_uv).rgb, layer);
	float variation = mix(0.78, 1.12, fbm(world_position.xz * 0.11 + 9.0));
	float height = dot(albedo, vec3(0.333));
	float field = fbm(world_position.xz / puddle_metres + 3.7) - height * 0.25;
	float threshold = 0.62 - puddle_amount * 0.35;
	float puddle = smoothstep(threshold, threshold + 0.035, field);
	float damp = max(wetness * smoothstep(threshold - 0.18, threshold, field), wetness * 0.45);
	ALBEDO = albedo * tint * variation * mix(1.0, 0.5, max(damp, puddle));
	ROUGHNESS = mix(mix(arm.g, arm.g * 0.42, damp), 0.04, puddle);
	METALLIC = 0.0;
	SPECULAR = 0.5;
	AO = arm.r;
	NORMAL_MAP = mix(normal, vec3(0.5, 0.5, 1.0), puddle * 0.92);
}
