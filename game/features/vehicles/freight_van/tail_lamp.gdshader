// The Iveco's tail lamps lit as a real van's are (#343, #344): each lamp a clear glossy cover over
// a red prism lens and, in its middle, a clear section with a chrome reflector. The lens's own
// texture is kept, its prisms showing lit or not. By the masks of that texture
// (`tools/art/make_tail_lamp_mask.py`): the red lens glows in its own colours, its prisms showing
// as they do with its cover off (#344, the author's choice), a little deeper red, for the tail and
// stop (`red`, the stop five times the tail); the chrome reflector flashes amber for its
// own side's indicator (`amber_left`, `amber_right`, the lens mesh's own x telling the sides) and
// shines white in reverse (`reverse`). The reflector shows its own facets and bulb holders, not a
// black mirror, and with the tail on catches a little of the red lens's glow inside the housing
// (`red_bleed`), so the clear section reads as part of the lamp, not a gap (#344). The cover is
// nearly clear (`cover_alpha`), only its gloss showing, and takes no light of its own.
shader_type spatial;
render_mode depth_prepass_alpha, cull_disabled;

uniform sampler2D lens : source_color, filter_linear_mipmap;
uniform sampler2D masks : hint_default_black, filter_linear_mipmap;
uniform vec3 red_deepen = vec3(1.0, 0.55, 0.55);
uniform float red_gain = 3.0;
uniform float cover_alpha = 0.08;
uniform vec3 amber_colour : source_color = vec3(1.0, 0.42, 0.0);
uniform vec3 reverse_colour : source_color = vec3(1.0, 0.96, 0.9);
uniform float amber_energy = 1.6;
uniform float reverse_energy = 1.4;
uniform float cover_roughness = 0.06;
uniform float lens_roughness = 0.18;
uniform float chrome_roughness = 0.15;
uniform float chrome_metallic = 0.55;
uniform float chrome_roughness_detail = 0.35;
uniform vec3 red_bleed = vec3(0.6, 0.12, 0.08);
uniform float red = 0.0;
uniform float amber_left = 0.0;
uniform float amber_right = 0.0;
uniform float reverse = 0.0;

varying float side;

void vertex() {
	side = VERTEX.x;
}

void fragment() {
	vec4 colour = texture(lens, UV);
	vec3 mask = texture(masks, UV).rgb;
	float chrome = mask.g;
	float cover = 1.0 - step(0.5, colour.a);
	ALBEDO = colour.rgb;
	ALPHA = mix(colour.a, cover_alpha, cover);
	METALLIC = chrome * chrome_metallic;
	ROUGHNESS = mix(mix(lens_roughness, mix(chrome_roughness, chrome_roughness_detail,
		1.0 - colour.r), chrome), cover_roughness, cover);
	float amber = side < 0.0 ? amber_left : amber_right;
	EMISSION = colour.rgb * red_deepen * step(0.1, mask.r) * red * red_gain
		+ chrome * colour.rgb * red_bleed * red
		+ chrome * (amber_colour * amber * amber_energy
		+ reverse_colour * reverse * reverse_energy);
}
