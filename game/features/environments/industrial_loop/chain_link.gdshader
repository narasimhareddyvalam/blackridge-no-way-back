shader_type spatial;
render_mode cull_disabled;

uniform vec3 wire_colour : source_color = vec3(0.56, 0.58, 0.58);
uniform float metallic_amount : hint_range(0.0, 1.0) = 0.65;
uniform float wire_roughness : hint_range(0.0, 1.0) = 0.42;
uniform float mesh_opening = 0.05;
uniform float wire_diameter = 0.003;

varying vec2 face;

void vertex() {
	face = VERTEX.xy;
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
	METALLIC = metallic_amount;
	ROUGHNESS = wire_roughness;
	ALPHA = 1.0 - (1.0 - cover_a) * (1.0 - cover_b);
	ALPHA_HASH_SCALE = 1.0;
}
