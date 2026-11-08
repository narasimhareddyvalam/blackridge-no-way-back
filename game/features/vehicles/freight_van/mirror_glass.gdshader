shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform sampler2D reflection : filter_linear, repeat_disable;
uniform float gain = 1.0;

const int TAPS = 4;

void fragment() {
	vec2 across = dFdx(UV);
	vec2 down = dFdy(UV);
	vec3 sum = vec3(0.0);
	for (int i = 0; i < TAPS; i++) {
		for (int j = 0; j < TAPS; j++) {
			vec2 offset = (vec2(float(i), float(j)) + 0.5) / float(TAPS) - 0.5;
			sum += texture(reflection, UV + across * offset.x + down * offset.y).rgb;
		}
	}
	ALBEDO = sum / float(TAPS * TAPS) * gain;
}
