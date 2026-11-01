shader_type spatial;
render_mode specular_schlick_ggx;

uniform sampler2D ground_color : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D ground_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D ground_arm : filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_color : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_arm : filter_linear_mipmap, repeat_enable;
uniform float ground_tile = 1.5;
uniform float rock_tile = 3.5;
uniform float rock_from : hint_range(0.0, 1.0) = 0.84;
uniform float rock_to : hint_range(0.0, 1.0) = 0.66;
uniform float ground_shade : hint_range(0.0, 1.0) = 0.58;
uniform float rock_shade : hint_range(0.0, 1.0) = 0.72;
uniform float wetness : hint_range(0.0, 1.0) = 0.7;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 unpack(vec3 sample_value) {
	return sample_value * 2.0 - 1.0;
}

void fragment() {
	vec3 n = normalize(world_normal);
	float rock = smoothstep(rock_from, rock_to, n.y);
	vec2 top_uv = world_position.xz / ground_tile;
	vec3 albedo = texture(ground_color, top_uv).rgb * ground_shade;
	vec3 arm = texture(ground_arm, top_uv).rgb;
	vec3 flat_normal = unpack(texture(ground_normal, top_uv).rgb);
	vec3 surface = normalize(vec3(flat_normal.x, flat_normal.z, -flat_normal.y) * 0.6 + n);
	if (rock > 0.001) {
		vec3 weights = pow(abs(n), vec3(4.0));
		weights /= dot(weights, vec3(1.0));
		vec2 uv_x = world_position.zy / rock_tile;
		vec2 uv_y = world_position.xz / rock_tile;
		vec2 uv_z = world_position.xy / rock_tile;
		vec3 rock_albedo = (texture(rock_color, uv_x).rgb * weights.x
			+ texture(rock_color, uv_y).rgb * weights.y
			+ texture(rock_color, uv_z).rgb * weights.z) * rock_shade;
		vec3 rock_arm_value = texture(rock_arm, uv_x).rgb * weights.x
			+ texture(rock_arm, uv_y).rgb * weights.y + texture(rock_arm, uv_z).rgb * weights.z;
		vec3 tx = unpack(texture(rock_normal, uv_x).rgb);
		vec3 ty = unpack(texture(rock_normal, uv_y).rgb);
		vec3 tz = unpack(texture(rock_normal, uv_z).rgb);
		tx = vec3(tx.xy + n.zy, abs(tx.z) * n.x);
		ty = vec3(ty.xy + n.xz, abs(ty.z) * n.y);
		tz = vec3(tz.xy + n.xy, abs(tz.z) * n.z);
		vec3 rock_surface = normalize(tx.zyx * weights.x + ty.xzy * weights.y + tz.xyz * weights.z);
		albedo = mix(albedo, rock_albedo, rock);
		arm = mix(arm, rock_arm_value, rock);
		surface = normalize(mix(surface, rock_surface, rock));
	}
	ALBEDO = albedo * (1.0 - 0.3 * wetness);
	AO = arm.r;
	ROUGHNESS = clamp(arm.g * (1.0 - 0.45 * wetness), 0.08, 1.0);
	NORMAL = normalize((VIEW_MATRIX * vec4(surface, 0.0)).xyz);
}
