shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float blur : hint_range(0.0, 6.0) = 3.0;
uniform float dim : hint_range(0.0, 1.0) = 0.45;

const int TAPS = 2;

void fragment() {
	vec2 spread = SCREEN_PIXEL_SIZE * exp2(blur) * 0.6;
	vec3 sum = vec3(0.0);
	for (int i = -TAPS; i <= TAPS; i++) {
		for (int j = -TAPS; j <= TAPS; j++) {
			sum += textureLod(screen, SCREEN_UV + vec2(float(i), float(j)) * spread, blur).rgb;
		}
	}
	float count = float((2 * TAPS + 1) * (2 * TAPS + 1));
	COLOR = vec4(sum / count * (1.0 - dim), 1.0);
}
