// The cutscenes' neo-noir film look (#357; the author's choice "C Neo-noir"), laid over the 3D
// view only while a cutscene plays: bright lamps streaked sideways in cool blue as an anamorphic
// lens streaks them, a soft bloom, colour pulled down toward grey, contrast raised and the blacks
// crushed with a cool cast in the shadows and a faint warmth in the lights, a vignette, and grain
// that moves; each shot may lift its exposure and its gamma (a colourist's per-shot grade). The
// world's own exposure and tone mapping are untouched.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float exposure = 1.0;
uniform float streak = 0.55;
uniform float bloom = 0.35;
uniform float saturation = 0.7;
uniform float contrast = 1.3;
uniform float gamma = 0.92;
uniform float vignette = 0.7;
uniform float grain = 0.018;
uniform vec3 shadow_cast = vec3(-0.03, -0.02, 0.0);
uniform vec3 light_cast = vec3(0.04, 0.0, 0.02);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 colour = texture(screen, SCREEN_UV).rgb * exposure;
	vec3 lens = vec3(0.0);
	for (int i = 1; i <= 12; i++) {
		float reach = float(i) * 0.012;
		for (int side = -1; side <= 1; side += 2) {
			vec3 tap = textureLod(screen, SCREEN_UV + vec2(reach * float(side), 0.0), 1.0).rgb;
			float bright = max(max(tap.r, tap.g), tap.b);
			lens += smoothstep(0.82, 1.0, bright) * (1.0 - float(i) / 13.0);
		}
	}
	colour += lens.r / 12.0 * vec3(0.35, 0.55, 1.0) * streak;
	vec3 soft = textureLod(screen, SCREEN_UV, 4.0).rgb;
	colour += max(soft - 0.75, vec3(0.0)) * bloom * 2.0;
	float luma = dot(colour, vec3(0.2126, 0.7152, 0.0722));
	colour = mix(vec3(luma), colour, saturation);
	colour = (colour - 0.5) * contrast + 0.5;
	colour = pow(clamp(colour, 0.0, 1.0), vec3(gamma));
	colour += (1.0 - luma) * (1.0 - luma) * shadow_cast + luma * luma * light_cast;
	vec2 centred = (SCREEN_UV - 0.5) * 2.0;
	colour *= 1.0 - vignette * pow(clamp(length(centred) - 0.45, 0.0, 1.0), 1.4);
	colour += (hash(SCREEN_UV * 1000.0 + TIME) - 0.5) * grain * 2.0;
	COLOR = vec4(colour, 1.0);
}
