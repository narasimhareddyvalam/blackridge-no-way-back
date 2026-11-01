shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform sampler2D display : source_color, filter_linear, repeat_disable;
uniform bool mirrored = false;
uniform vec2 crop = vec2(1.0);

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
	ALBEDO = sum / float(TAPS * TAPS);
}
