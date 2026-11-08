shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform bool face_camera = true;
uniform float min_pixels : hint_range(0.0, 4.0) = 0.0;
uniform float forward_scatter : hint_range(0.0, 0.95) = 0.7;
uniform float scatter : hint_range(0.0, 200.0) = 1.0;
uniform float diffuse : hint_range(0.0, 1.0) = 0.3;
uniform float glint : hint_range(0.0, 4.0) = 0.0;
uniform float glint_sharpness : hint_range(8.0, 2000.0) = 400.0;
uniform vec4 sky_glow : source_color = vec4(0.204, 0.278, 0.333, 1.0);
uniform float sky : hint_range(0.0, 8.0) = 0.0;

varying float coverage;

void vertex() {
	if (face_camera) {
		mat4 world = mat4(normalize(MAIN_CAM_INV_VIEW_MATRIX[0]),
			normalize(MAIN_CAM_INV_VIEW_MATRIX[1]), normalize(MAIN_CAM_INV_VIEW_MATRIX[2]),
			MODEL_MATRIX[3]);
		float turn = INSTANCE_CUSTOM.x;
		world = world * mat4(vec4(cos(turn), -sin(turn), 0.0, 0.0),
			vec4(sin(turn), cos(turn), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_MATRIX = VIEW_MATRIX * world * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
	coverage = 1.0;
	if (min_pixels > 0.0) {
		float depth = max(-(MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).z, 0.001);
		float pixel = 2.0 * depth / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
		float width = 2.0 * abs(VERTEX.x) * length(MODELVIEW_MATRIX[0].xyz);
		float grow = max(1.0, min_pixels * pixel / max(width, 0.000001));
		VERTEX.x *= grow;
		if (face_camera) {
			VERTEX.y *= grow;
			coverage = 1.0 / (grow * grow);
		} else {
			coverage = 1.0 / grow;
		}
	}
}

void fragment() {
	vec4 sprite = texture(albedo_texture, UV);
	vec2 p = UV * 2.0 - 1.0;
	ALBEDO = COLOR.rgb * sprite.rgb;
	ALPHA = clamp(COLOR.a * sprite.a * coverage, 0.0, 1.0);
	ROUGHNESS = 0.1;
	if (face_camera) {
		NORMAL = normalize(vec3(p.x, -p.y, sqrt(max(1.0 - dot(p, p), 0.0)) + 0.15));
	}
	float lower = smoothstep(-0.1, 0.95, p.y) * (1.0 - 0.6 * smoothstep(0.88, 1.0, length(p)));
	EMISSION = sky_glow.rgb * sky * (face_camera ? lower : 1.0);
}

void light() {
	float facing = dot(-LIGHT, VIEW);
	float g = forward_scatter;
	float phase = (1.0 - g * g) / (4.0 * PI * pow(1.0 + g * g - 2.0 * g * facing, 1.5));
	float lambert = max(dot(NORMAL, LIGHT), 0.0) / PI;
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * (diffuse * lambert + scatter * 4.0 * phase);
	if (glint > 0.0) {
		vec3 halfway = normalize(LIGHT + VIEW);
		float lobe = pow(max(dot(NORMAL, halfway), 0.0), glint_sharpness)
			* (glint_sharpness + 8.0) / (8.0 * PI);
		SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * glint * 0.04 * lobe
			* max(dot(NORMAL, LIGHT), 0.0);
	}
}
