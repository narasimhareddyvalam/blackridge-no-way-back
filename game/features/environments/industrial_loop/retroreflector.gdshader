shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

uniform vec3 sheeting : source_color = vec3(0.9, 0.9, 0.88);
uniform vec3 stripe_colour : source_color = vec3(0.02, 0.02, 0.02);
uniform float stripe_width = 0.0;
uniform float stripe_slope = 1.0;
uniform float return_peak = 1000.0;
uniform float return_spread = 0.0061;

varying vec2 face;

void vertex() {
	face = VERTEX.xy;
}

void fragment() {
	vec3 colour = sheeting;
	if (stripe_width > 0.0) {
		float band = fract((face.x * stripe_slope - face.y) / (stripe_width * 2.0 * sqrt(2.0)));
		colour = band < 0.5 ? sheeting : stripe_colour;
	}
	ALBEDO = colour;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}

void light() {
	float facing = max(dot(NORMAL, LIGHT), 0.0);
	float observation = length(cross(LIGHT, VIEW));
	float spread = observation / return_spread;
	float returned = return_peak / (1.0 + spread * spread);
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * facing * (1.0 + returned) / PI;
}
