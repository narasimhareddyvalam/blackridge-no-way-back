// #281's trial of a lit headlamp seen from the front: a reflector lamp (the 2014 Daily's H7
// reflector headlamps) behind clear polycarbonate. The filament's image is a small, very bright
// core at each lamp's centre; round it the reflector's facets each throw back a patch of the
// filament, so the bowl reads as cells of differing brightness falling off from the core; the
// rest of the lens glows faintly with light scattered inside the housing. The clear cover on top
// reflects the scene (low roughness, dielectric). Lamp centres come from the van's headlight
// positions: each half's front face's centre, in the lens mesh's own space.
shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec3 lamp_a = vec3(0.64, 1.15, -2.31);
uniform vec3 lamp_b = vec3(-0.64, 1.15, -2.31);
uniform vec3 light_colour : source_color = vec3(1.0, 0.94, 0.86);
uniform float core_energy = 25.0;
uniform float core_radius = 0.018;
uniform float bowl_energy = 2.0;
uniform float bowl_radius = 0.085;
uniform float facet_size = 0.018;
uniform float housing_energy = 0.12;
uniform float lit = 1.0;

varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

float hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

float lamp(vec3 centre) {
	vec2 offset = local_position.xy - centre.xy;
	float reach = length(offset);
	float core = exp(-pow(reach / core_radius, 2.0)) * core_energy;
	vec2 cell = floor(offset / facet_size);
	float facet = mix(0.45, 1.35, hash(cell + centre.xy * 37.0));
	float bowl = exp(-pow(reach / bowl_radius, 2.0)) * bowl_energy * facet;
	return core + bowl;
}

void fragment() {
	ALBEDO = vec3(0.03);
	ROUGHNESS = 0.06;
	METALLIC = 0.0;
	SPECULAR = 0.5;
	float glow = max(lamp(lamp_a), lamp(lamp_b)) + housing_energy;
	EMISSION = light_colour * glow * lit;
}
