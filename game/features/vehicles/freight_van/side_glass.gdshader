shader_type spatial;
render_mode blend_mix, cull_disabled;

#include "window_slide.gdshaderinc"

uniform vec4 tint : source_color = vec4(0.33, 0.5, 0.57, 0.14);
uniform float glass_roughness : hint_range(0.0, 1.0) = 0.09;

void vertex() {
	rest_position = VERTEX;
	sliding = pane_slides(VERTEX);
	VERTEX.y -= lowered * sliding;
}

void fragment() {
	if (below_sill(rest_position, sliding)) {
		discard;
	}
	ALBEDO = tint.rgb;
	ALPHA = tint.a;
	ROUGHNESS = glass_roughness;
}
