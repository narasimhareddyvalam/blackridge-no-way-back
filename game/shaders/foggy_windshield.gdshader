shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

// Fog settings
group_uniforms Fog;

uniform float fog_amount : hint_range(0.0, 1.0) = 0.25;
uniform float fog_opacity : hint_range(0.0, 1.0) = 0.45;
uniform vec4 fog_tint : source_color = vec4(0.82, 0.87, 0.90, 1.0);

// Fog shape settings
group_uniforms Shape;

uniform float clear_center : hint_range(0.0, 0.9) = 0.65;
uniform float edge_softness : hint_range(0.01, 0.5) = 0.20;

// Small moisture details
group_uniforms Detail;

uniform float normal_strength : hint_range(0.0, 2.0) = 0.5;
uniform float texture_scale : hint_range(0.5, 4.0) = 1.0;

group_uniforms;

// Fog textures
uniform sampler2D fog_color : source_color, filter_linear, repeat_enable;
uniform sampler2D fog_normal : hint_normal, filter_linear, repeat_enable;
uniform sampler2D fog_data : filter_linear, repeat_enable;

void fragment() {
	// Read the three textures
	vec2 fog_uv = UV * texture_scale;
	vec3 color_sample = texture(fog_color, fog_uv).rgb;
	vec3 normal_sample = texture(fog_normal, fog_uv).rgb;
	float fog_thickness = texture(fog_data, fog_uv).r;

	// Find how close this pixel is to the glass edges
	vec2 center_distance = abs(UV - vec2(0.5)) * 2.0;
	float edge_distance = max(center_distance.x, center_distance.y);

	// Control how far the fog spreads inward
	float fog_start = mix(
		1.0 + edge_softness,
		clear_center,
		fog_amount
	);

	// Make the fog fade smoothly near the edges
	float edge_mask = smoothstep(
		fog_start - edge_softness,
		fog_start,
		edge_distance
	);

	// Combine the edge shape with the fog texture
	float fog_mask = clamp(edge_mask * fog_thickness, 0.0, 1.0);

	// Give the fog its colour
	ALBEDO = color_sample * fog_tint.rgb;

	// Add small moisture details
	NORMAL_MAP = normal_sample;
	NORMAL_MAP_DEPTH = normal_strength;

	// Control how transparent the fog is
	ALPHA = fog_mask * fog_opacity;

	// Keep the fog surface soft
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}
