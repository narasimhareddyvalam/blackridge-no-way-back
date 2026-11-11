shader_type spatial;
render_mode cull_disabled;

uniform vec3 wire_colour : source_color = vec3(0.6, 0.62, 0.62);
uniform float wire_roughness : hint_range(0.0, 1.0) = 0.42;
uniform float zinc_reflectance : hint_range(0.0, 1.0) = 0.12;
uniform float mesh_opening = 0.05;
uniform float wire_diameter = 0.003;

varying vec2 face;
varying vec3 wire_a;
varying vec3 wire_b;

void vertex() {
	face = VERTEX.xy;
	wire_a = (MODELVIEW_MATRIX * vec4(0.70710678, -0.70710678, 0.0, 0.0)).xyz;
	wire_b = (MODELVIEW_MATRIX * vec4(0.70710678, 0.70710678, 0.0, 0.0)).xyz;
}

float wires(float along) {
	float spacing = mesh_opening + wire_diameter;
	float distance_to_wire = abs(fract(along / spacing + 0.5) - 0.5) * spacing;
	float footprint = max(fwidth(along), 1e-5);
	float sharp = clamp((wire_diameter * 0.5 - distance_to_wire) / footprint + 0.5, 0.0, 1.0);
	float blur = clamp(footprint / spacing * 2.0, 0.0, 1.0);
	return mix(sharp, wire_diameter / spacing, blur);
}

void fragment() {
	float rising = (face.x + face.y) * 0.70710678;
	float falling = (face.x - face.y) * 0.70710678;
	float cover_a = wires(rising);
	float cover_b = wires(falling);
	ALBEDO = wire_colour;
	ROUGHNESS = wire_roughness;
	ALPHA = 1.0 - (1.0 - cover_a) * (1.0 - cover_b);
}

float round_wire(vec3 along, vec3 towards) {
	float lined = dot(normalize(along), towards);
	return sqrt(max(1.0 - lined * lined, 0.0));
}

void light() {
	vec3 halfway = normalize(LIGHT + VIEW);
	float rough = 1.0 - wire_roughness;
	float shine = mix(4.0, 160.0, rough * rough);
	float lit = 0.5 * (round_wire(wire_a, LIGHT) + round_wire(wire_b, LIGHT));
	float glint = 0.5 * (pow(round_wire(wire_a, halfway), shine)
		+ pow(round_wire(wire_b, halfway), shine));
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * lit * (1.0 - zinc_reflectance) / PI;
	SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * glint * zinc_reflectance * (shine + 2.0)
		/ (2.0 * PI);
}
