shader_type spatial;
render_mode world_vertex_coords, cull_disabled, diffuse_lambert_wrap, specular_schlick_ggx;

uniform vec2 wind_direction = vec2(1.0, 0.0);
uniform float wind_strength = 0.15;
uniform float gust_scale = 0.35;
uniform float gust_speed = 1.6;
uniform float flutter = 0.04;
uniform float wet_roughness : hint_range(0.0, 1.0) = 0.55;
uniform vec3 backlight_colour : source_color = vec3(0.09, 0.12, 0.04);

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float blade_height = length(MODEL_MATRIX[1].xyz);
	float travel = dot(origin.xz, wind_direction) * gust_scale - TIME * gust_speed;
	float gust = 0.55 + 0.3 * sin(travel) + 0.15 * sin(travel * 2.3 + origin.z * 0.7);
	float shake = sin(TIME * 9.0 + dot(origin.xz, vec2(12.9898, 78.233))) * flutter;
	vec2 push = wind_direction * gust * wind_strength + vec2(shake, shake * 0.6);
	VERTEX.xz += push * UV.y * UV.y * blade_height;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = wet_roughness;
	SPECULAR = 0.4;
	BACKLIGHT = backlight_colour;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
