shader_type spatial;
render_mode cull_disabled;

uniform vec3 wire_colour : source_color = vec3(0.6, 0.62, 0.62);
uniform float metallic_amount : hint_range(0.0, 1.0) = 0.5;
uniform float wire_roughness : hint_range(0.0, 1.0) = 0.45;
uniform float min_pixels = 1.0;

varying float coverage;

void vertex() {
	vec3 across = vec3(0.0, VERTEX.y, VERTEX.z);
	float half_width = max(length(across), 1e-5);
	vec3 centre = (MODELVIEW_MATRIX * vec4(VERTEX.x, 0.0, 0.0, 1.0)).xyz;
	float pixel = 2.0 * max(-centre.z, 0.01) / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
	float wanted = max(half_width, 0.5 * min_pixels * pixel);
	VERTEX = vec3(VERTEX.x, 0.0, 0.0) + across * (wanted / half_width);
	coverage = half_width / wanted;
}

void fragment() {
	ALBEDO = wire_colour;
	METALLIC = metallic_amount;
	ROUGHNESS = wire_roughness;
	ALPHA = coverage;
}
