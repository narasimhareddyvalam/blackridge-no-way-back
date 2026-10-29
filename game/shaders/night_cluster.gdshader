shader_type canvas_item;

// How much the dashboard changes at night
uniform float night_amount : hint_range(0.0, 1.0) = 0.0;

// Warm amber dashboard light
uniform vec4 night_color : source_color = vec4(1.0, 0.55, 0.20, 1.0);

// How bright the gauges stay at night
uniform float night_brightness : hint_range(0.1, 1.0) = 0.55;

void fragment() {
	// Blend between normal and night lighting
	COLOR.rgb = mix(COLOR.rgb, COLOR.rgb * night_color.rgb * night_brightness, night_amount);
}
