shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D scene_color : hint_screen_texture, filter_linear;
uniform bool wipers_on = true;
uniform float sweep_angle = -0.9;
uniform float wetness : hint_range(0.0, 1.0) = 0.2;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float swept(vec2 p, vec2 origin) {
	vec2 delta = p - origin;
	float angle = atan(delta.x, delta.y);
	float area = step(length(delta), 0.81) * step(abs(angle), 1.0);
	float recent = 0.04 + clamp(abs(angle + sweep_angle), 0.0, 2.0) * 0.10;
	return mix(1.0, recent, area);
}

void fragment() {
	vec2 grid = UV * vec2(43.0, 25.0);
	vec2 cell = floor(grid);
	float seed = hash(cell);
	vec2 local = fract(grid) - vec2(0.5);
	local.x += (seed - 0.5) * 0.48;
	local.y += sin(TIME * 0.22 + seed * 8.0) * 0.16;
	vec2 shape = local * vec2(1.0, 0.68);
	float radius = 0.06 + seed * 0.105;
	float distance_to_drop = length(shape);
	float body = 1.0 - smoothstep(radius * 0.55, radius, distance_to_drop);
	body *= step(0.40, seed);
	float edge = smoothstep(radius * 0.34, radius * 0.65, distance_to_drop)
		* (1.0 - smoothstep(radius * 0.75, radius, distance_to_drop));
	float highlight = pow(max(0.0, dot(normalize(vec3(shape, 0.08)),
		normalize(vec3(-0.4, -0.6, 0.5)))), 12.0) * body;
	vec2 glass = vec2((UV.x - 0.5) * 2.12, (0.5 - UV.y) * 1.08);
	float clear = 1.0;
	if (wipers_on) {
		clear = min(swept(glass, vec2(-0.52, -0.51)),
			swept(glass, vec2(0.48, -0.51)));
	}
	float coverage = body * mix(0.35, 0.95, wetness) * clear;
	vec2 distortion = shape * coverage * 0.018;
	vec3 background = texture(scene_color, SCREEN_UV + distortion).rgb;
	ALBEDO = background * (1.0 - edge * 0.09) + vec3(highlight * 0.24);
	ALPHA = clamp(coverage * 0.85 + highlight * 0.12, 0.0, 0.92);
}
