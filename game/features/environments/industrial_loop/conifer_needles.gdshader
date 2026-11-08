shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_lambert_wrap, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic, repeat_disable;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.35;
uniform float wind_strength : hint_range(0.0, 0.5) = 0.08;
uniform float wind_speed : hint_range(0.0, 3.0) = 0.8;
uniform float tree_height = 20.0;
uniform vec3 backlight_colour : source_color = vec3(0.10, 0.14, 0.08);

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float reach = clamp(length(VERTEX.xz) / 3.0, 0.0, 1.0);
	float rise = clamp(VERTEX.y / tree_height, 0.0, 1.0);
	float phase = dot(origin.xz, vec2(0.13, 0.17));
	float gust = sin(TIME * wind_speed + phase) * 0.6
		+ sin(TIME * wind_speed * 2.3 + phase * 1.7) * 0.4;
	float sway = gust * wind_strength * (reach * 0.7 + rise * 0.3);
	VERTEX.x += sway;
	VERTEX.z += sway * 0.6;
}

void fragment() {
	vec4 texel = texture(albedo_texture, UV);
	ALBEDO = texel.rgb * COLOR.rgb;
	ALPHA = texel.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cutoff;
	NORMAL_MAP = texture(normal_texture, UV).rgb;
	NORMAL_MAP_DEPTH = 0.6;
	ROUGHNESS = 0.7;
	SPECULAR = 0.35;
	BACKLIGHT = backlight_colour;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
