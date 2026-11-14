// The Iveco's headlamps lit as real ones are (#282): the clear cover stays glass, so the housing
// and the indicator show through it, and only the lamps that are on glow behind it. Measured
// from the lens mesh (`Headlights`, its own space, each side mirrored): the low beam's projector
// lens, 24 mm in radius, and the high beam's reflector bowl, 65 mm, toward the outer corner.
// The low beam lights the projector, its glow spreading a few millimetres into the cover; the
// rest of the housing stays dark, as an unlit reflector does beside a lit projector. The high
// beam lights the bowl, brightest at its bulb and falling off toward its rim, each of the
// reflector's facets throwing back its own patch of the filament.
shader_type spatial;
render_mode depth_prepass_alpha;

uniform sampler2D glass_texture : source_color, filter_linear_mipmap;
uniform vec4 glass_colour : source_color = vec4(1.0);
uniform float glass_metallic = 1.0;
uniform float glass_roughness = 0.6;
uniform vec2 projector_centre = vec2(0.708, 1.006);
uniform float projector_radius = 0.024;
uniform vec2 reflector_centre = vec2(0.792, 1.077);
uniform float reflector_radius = 0.065;
uniform vec3 light_colour : source_color = vec3(1.0, 0.94, 0.86);
uniform float projector_energy = 30.0;
uniform float halo_energy = 0.4;
uniform float halo_spread = 1.4;
uniform float reflector_energy = 6.0;
uniform float facet_size = 0.015;
uniform float scattered = 0.002;
uniform float low_lit = 0.0;
uniform float high_lit = 0.0;

varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec4 glass = texture(glass_texture, UV) * glass_colour;
	vec2 at = vec2(abs(local_position.x), local_position.y);
	float to_projector = distance(at, projector_centre);
	float projector = 1.0 - smoothstep(projector_radius * 0.8, projector_radius, to_projector);
	float halo = exp(-pow(to_projector / (projector_radius * halo_spread), 2.0));
	float to_reflector = distance(at, reflector_centre);
	float bowl = 1.0 - smoothstep(reflector_radius * 0.85, reflector_radius, to_reflector);
	float bulb = 0.12 + 0.88 * exp(-pow(to_reflector / (reflector_radius * 0.5), 2.0));
	vec2 cell = floor((at - reflector_centre) / facet_size);
	float facet = mix(0.55, 1.25, fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453));
	float glow = low_lit * (projector * projector_energy + halo * halo_energy)
		+ bowl * bulb * facet * reflector_energy * max(high_lit, low_lit * scattered);
	ALBEDO = glass.rgb;
	METALLIC = glass_metallic;
	ROUGHNESS = glass_roughness;
	EMISSION = light_colour * glow;
	ALPHA = clamp(max(glass.a, glow), 0.0, 1.0);
}
