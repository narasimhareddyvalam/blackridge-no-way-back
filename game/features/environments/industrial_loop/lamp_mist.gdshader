shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_front, fog_disabled,
	shadows_disabled;

uniform sampler2D scene_depth : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec3 light_colour = vec3(1.0, 0.36, 0.05);
uniform vec3 half_size = vec3(10.0, 10.0, 3.8);
uniform float spot_cutoff = 0.57;
uniform float spot_falloff = 1.5;
uniform float light_range = 15.0;
uniform float light_decay = 2.0;
uniform float scattering = 0.004;
uniform float extinction = 0.0045;
uniform float forward_g : hint_range(0.0, 0.99) = 0.75;
uniform float forward_share : hint_range(0.0, 1.0) = 0.5;
uniform float side_g : hint_range(0.0, 0.99) = 0.2;
uniform float closest = 0.6;
uniform float fade_begin = 65.0;
uniform float fade_length = 25.0;

const int SAMPLES = 10;

float phase(float g, float cosine) {
	float g2 = g * g;
	return (1.0 - g2) / (4.0 * PI * pow(1.0 + g2 - 2.0 * g * cosine, 1.5));
}

void fragment() {
	vec3 eye = CAMERA_POSITION_WORLD;
	vec3 far_side = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float far_distance = length(far_side - eye);
	vec3 ray = (far_side - eye) / far_distance;
	float depth = texture(scene_depth, SCREEN_UV).r;
	vec4 surface = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float end = min(far_distance, length(surface.xyz / surface.w));
	mat3 turn = mat3(MODEL_MATRIX);
	vec3 local_eye = transpose(turn) * (eye - MODEL_MATRIX[3].xyz);
	vec3 local_ray = transpose(turn) * ray;
	vec3 safe = mix(local_ray, vec3(1e-5), vec3(lessThan(abs(local_ray), vec3(1e-5))));
	vec3 first = (-half_size - local_eye) / safe;
	vec3 second = (half_size - local_eye) / safe;
	vec3 entry = min(first, second);
	float start = max(max(max(entry.x, entry.y), entry.z), 0.0);
	vec3 lamp = (MODEL_MATRIX * vec4(0.0, 0.0, half_size.z, 1.0)).xyz;
	vec3 axis = -normalize(MODEL_MATRIX[2].xyz);
	float fade = 1.0 - smoothstep(fade_begin, fade_begin + fade_length, length(lamp - eye));
	if (end <= start || fade <= 0.0) {
		discard;
	}
	float middle = dot(lamp - eye, ray);
	float reach = max(length(eye + ray * middle - lamp), closest);
	float low = atan((start - middle) / reach);
	float high = atan((end - middle) / reach);
	float gathered = 0.0;
	for (int index = 0; index < SAMPLES; index++) {
		float angle = mix(low, high, (float(index) + 0.5) / float(SAMPLES));
		float t = middle + reach * tan(angle);
		vec3 point = eye + ray * t;
		vec3 outward = point - lamp;
		float span = max(length(outward), closest);
		vec3 heading = outward / span;
		float rim = max(0.0001, (1.0 - max(dot(heading, axis), spot_cutoff)) / (1.0 - spot_cutoff));
		float cone = 1.0 - pow(rim, spot_falloff);
		float window = max(1.0 - pow(span / light_range, 4.0), 0.0);
		float turn_back = dot(heading, -ray);
		float lobes = mix(phase(side_g, turn_back), phase(forward_g, turn_back), forward_share);
		gathered += cone * window * window * lobes * pow(span, 2.0 - light_decay)
			* exp(-extinction * t);
	}
	gathered *= (high - low) / reach / float(SAMPLES);
	ALBEDO = light_colour * scattering * gathered * fade;
}
