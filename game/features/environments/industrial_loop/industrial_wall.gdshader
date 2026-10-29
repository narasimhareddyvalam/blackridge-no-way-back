shader_type spatial;

uniform vec4 base_color : source_color = vec4(0.22, 0.25, 0.26, 1.0);
uniform bool brick = false;
varying vec3 world_position;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(43.3, 91.7))) * 43758.5453);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec2 p = vec2(abs(world_normal.x) > 0.5 ? world_position.z : world_position.x,
		world_position.y);
	float flute = sin(p.x * 36.0);
	float rib = smoothstep(0.70, 0.96, flute);
	float streak = sin(p.x * 4.3) * sin(p.x * 23.1) * 0.05;
	float grain = hash(floor(p * 320.0)) * 0.045;
	vec3 color = base_color.rgb * (0.84 + rib * 0.15 + streak + grain);
	float height = flute * 0.10;
	if (brick) {
		float row = floor(p.y / 0.24);
		vec2 brick_uv = vec2(p.x / 0.65 + mod(row, 2.0) * 0.5, p.y / 0.24);
		vec2 cell = fract(brick_uv);
		float mortar = smoothstep(0.015, 0.065, cell.x)
			* smoothstep(0.025, 0.10, cell.y);
		color *= mix(0.50, 0.87 + hash(floor(brick_uv)) * 0.24, mortar);
		height = mortar * 0.04;
	}
	float damp = mix(0.54, 1.0, smoothstep(0.0, 2.8, world_position.y));
	ALBEDO = color * damp;
	ROUGHNESS = brick ? 0.87 : 0.56;
	METALLIC = brick ? 0.0 : 0.32;
	NORMAL_MAP = normalize(vec3(-dFdx(height) * 5.0, -dFdy(height) * 5.0, 1.0))
		* 0.5 + 0.5;
}
