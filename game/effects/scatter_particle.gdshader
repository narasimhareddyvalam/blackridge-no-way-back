shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D scene_color : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D scene_depth : hint_depth_texture, filter_nearest, repeat_disable;
uniform bool face_camera = true;
uniform float tail : hint_range(0.0, 1.0) = 0.0;
uniform float thread_life : hint_range(0.0, 1.0) = 0.0;
uniform float min_pixels : hint_range(0.0, 4.0) = 0.0;
uniform float forward_scatter : hint_range(0.0, 0.95) = 0.7;
uniform float scatter : hint_range(0.0, 200.0) = 1.0;
uniform float diffuse : hint_range(0.0, 1.0) = 0.3;
uniform float glint : hint_range(0.0, 4.0) = 0.0;
uniform float glint_sharpness : hint_range(8.0, 2000.0) = 400.0;
uniform vec4 sky_glow : source_color = vec4(0.204, 0.278, 0.333, 1.0);
uniform float sky : hint_range(0.0, 8.0) = 0.0;
uniform vec3 catch_from = vec3(-0.35, 0.55, 0.75);
uniform float catch_light : hint_range(0.0, 4.0) = 0.0;
uniform float refraction : hint_range(0.0, 1.0) = 0.0;
uniform float ground_reach : hint_range(0.0, 1.0) = 0.0;
uniform float ripple : hint_range(0.0, 0.1) = 0.0;
uniform float lens_blur : hint_range(0.0, 5.0) = 1.0;
uniform float rim_dark : hint_range(0.0, 1.0) = 0.4;
uniform float still_fade : hint_range(0.0, 1.0) = 0.0;

varying float coverage;
varying float aspect;
varying float shape_ratio;
varying float life;
varying vec2 across;
varying vec2 along;
varying vec3 side_axis;
varying vec3 up_axis;
varying vec3 out_axis;

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
	vec2 side = MODELVIEW_MATRIX[0].xy;
	vec2 up = MODELVIEW_MATRIX[1].xy;
	across = length(side) > 0.000001 ? normalize(vec2(side.x, -side.y)) : vec2(1.0, 0.0);
	along = length(up) > 0.000001 ? normalize(vec2(up.x, -up.y)) : vec2(0.0, -1.0);
	side_axis = normalize(MODELVIEW_MATRIX[0].xyz);
	up_axis = normalize(MODELVIEW_MATRIX[1].xyz);
	out_axis = normalize(cross(side_axis, up_axis));
	life = INSTANCE_CUSTOM.y;
	bool comet = tail > 0.0 && !face_camera;
	float width = 2.0 * abs(VERTEX.x) * length(MODELVIEW_MATRIX[0].xyz);
	float span = 2.0 * abs(VERTEX.y) * length(MODELVIEW_MATRIX[1].xyz);
	shape_ratio = span / max(width, 0.000001);
	float grow = 1.0;
	if (min_pixels > 0.0) {
		float depth = max(-(MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).z, 0.001);
		float pixel = 2.0 * depth / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
		grow = max(1.0, min_pixels * pixel / max(width, 0.000001));
	}
	float stretch = face_camera ? grow : 1.0;
	if (comet) {
		stretch = max(1.0, width * grow / max(span, 0.000001));
	}
	aspect = span * stretch / max(width * grow, 0.000001);
	coverage = 1.0 / (grow * stretch);
	VERTEX.x *= grow;
	VERTEX.y *= stretch;
	if (comet) {
		VERTEX.y -= abs(VERTEX.y);
	}
}

void fragment() {
	vec4 sprite = texture(albedo_texture, UV);
	vec2 p = UV * 2.0 - 1.0;
	ALBEDO = COLOR.rgb * sprite.rgb;
	ROUGHNESS = 0.1;
	float shape = sprite.a;
	float lens_shape = 1.0 - smoothstep(0.82, 1.0, length(p));
	float radius = face_camera ? length(p) : abs(p.x);
	vec2 toward = face_camera ? p : across * p.x;
	vec2 bend = toward;
	vec3 surface = normalize(side_axis * p.x
		+ out_axis * (sqrt(max(1.0 - p.x * p.x, 0.0)) + 0.15));
	if (face_camera) {
		NORMAL = normalize(vec3(p.x, -p.y, sqrt(max(1.0 - dot(p, p), 0.0)) + 0.15));
		surface = NORMAL;
	} else if (tail > 0.0) {
		float stretched = max(aspect, 1.0);
		float behind = (p.y + 1.0) * stretched;
		float head = length(vec2(p.x, behind - 1.0));
		float along_tail = clamp((behind - 1.0) / max(2.0 * stretched - 1.0, 0.0001), 0.0, 1.0);
		float half_width = mix(1.0, 0.18, along_tail);
		float body = abs(p.x) / half_width;
		float strength = thread_life > 0.0
			? mix(1.0, tail, smoothstep(0.0, thread_life, life)) : tail;
		float trail = behind > 1.0
			? strength * (1.0 - smoothstep(0.6, 1.0, body)) * pow(1.0 - along_tail, 1.5) : 0.0;
		shape = max(1.0 - smoothstep(0.82, 1.0, head), trail);
		lens_shape = shape;
		bool in_head = head < 1.0;
		radius = in_head ? head : body;
		vec3 local = in_head
			? vec3(p.x, 1.0 - behind, sqrt(max(1.0 - head * head, 0.0)) + 0.15)
			: vec3(p.x / half_width, 0.0, sqrt(max(1.0 - body * body, 0.0)) + 0.15);
		NORMAL = normalize(side_axis * local.x + up_axis * local.y + out_axis * local.z);
		surface = NORMAL;
		toward = in_head ? across * p.x + along * (1.0 - behind) : across * (p.x / half_width);
		bend = in_head ? toward : toward * 0.5;
	}
	ALPHA = clamp(COLOR.a * shape * coverage, 0.0, 1.0);
	float edge = 1.0 - 0.6 * smoothstep(0.88, 1.0, radius);
	EMISSION = sky_glow.rgb * sky * max(smoothstep(-0.1, 0.95, toward.y), 0.35) * edge;
	vec3 through = textureLod(scene_color, SCREEN_UV, lens_blur).rgb;
	if (refraction > 0.0) {
		vec2 offset = -bend * refraction * vec2(VIEWPORT_SIZE.y / VIEWPORT_SIZE.x, 1.0);
		if (ripple > 0.0) {
			offset += ripple * vec2(sin(UV.y * 23.0 + TIME * 7.0 + life * 31.0)
				+ 0.6 * sin(UV.x * 17.0 - TIME * 5.0), cos(UV.x * 19.0 + TIME * 6.0 + life * 17.0)
				+ 0.6 * cos(UV.y * 13.0 + TIME * 8.0));
		}
		vec2 uv = clamp(SCREEN_UV + offset, vec2(0.002), vec2(0.998));
		vec4 far = INV_PROJECTION_MATRIX * vec4(uv * 2.0 - 1.0, texture(scene_depth, uv).r, 1.0);
		if (-far.z / far.w < -VERTEX.z) {
			uv = SCREEN_UV;
		}
		through = textureLod(scene_color, uv, lens_blur).rgb;
		float upper = smoothstep(0.05, 0.9, -toward.y);
		if (ground_reach > 0.0 && upper > 0.0) {
			vec3 ground = vec3(0.0);
			float found = 0.0;
			for (int attempt = 1; attempt <= 3; attempt++) {
				vec2 down = clamp(SCREEN_UV + vec2(0.0, ground_reach * float(attempt) / 3.0),
					vec2(0.002), vec2(0.998));
				vec4 seen = INV_PROJECTION_MATRIX
					* vec4(down * 2.0 - 1.0, texture(scene_depth, down).r, 1.0);
				if (-seen.z / seen.w >= -VERTEX.z) {
					ground += textureLod(scene_color, down, 4.5).rgb;
					found += 1.0;
				}
			}
			if (found > 0.0) {
				through = mix(through, ground / found, upper);
			}
		}
		float rim = smoothstep(0.55, 1.0, radius);
		EMISSION += through * 0.95 * (1.0 - rim_dark * rim);
		ALBEDO *= 0.15;
		if (face_camera || tail > 0.0) {
			ALPHA = clamp(COLOR.a * lens_shape * coverage, 0.0, 1.0);
		}
	}
	ALPHA *= 1.0 - still_fade * (1.0 - smoothstep(2.0, 8.0, shape_ratio));
	float caught = pow(max(dot(surface, normalize(catch_from)), 0.0), 40.0) * catch_light;
	EMISSION += (through * 1.5 + vec3(dot(through, vec3(0.2126, 0.7152, 0.0722)) * 0.6)) * caught;
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
