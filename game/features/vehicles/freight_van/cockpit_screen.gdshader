shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform sampler2D display : source_color, filter_linear, repeat_disable;
uniform bool mirrored = false;
uniform vec2 crop = vec2(1.0);
uniform float power = 1.0;
uniform vec2 border = vec2(0.0);
uniform float black_level = 0.0;
uniform float view_falloff = 0.0;

const int TAPS = 6;

void fragment() {
	vec2 uv = vec2(mirrored ? 1.0 - UV.x : UV.x, UV.y);
	uv = 0.5 + (uv - 0.5) * crop;
	vec2 across = dFdx(uv);
	vec2 down = dFdy(uv);
	vec3 sum = vec3(0.0);
	for (int i = 0; i < TAPS; i++) {
		for (int j = 0; j < TAPS; j++) {
			vec2 offset = (vec2(float(i), float(j)) + 0.5) / float(TAPS) - 0.5;
			sum += texture(display, uv + across * offset.x + down * offset.y).rgb;
		}
	}
	vec3 colour = sum / float(TAPS * TAPS);
	if (border.x > 0.0 || border.y > 0.0) {
		vec2 edge = min(UV, 1.0 - UV);
		vec2 feather = fwidth(UV);
		float lit = smoothstep(border.x, border.x + feather.x, edge.x)
			* smoothstep(border.y, border.y + feather.y, edge.y);
		colour = max(colour, vec3(black_level)) * lit;
	}
	colour *= mix(1.0 - view_falloff, 1.0, abs(dot(NORMAL, VIEW)));
	ALBEDO = colour * power;
}
