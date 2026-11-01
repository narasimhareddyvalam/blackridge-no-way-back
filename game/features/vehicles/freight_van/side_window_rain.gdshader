shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D scene_color : hint_screen_texture, filter_linear_mipmap;
uniform float rain : hint_range(0.0, 1.0) = 0.8;
uniform float wetness : hint_range(0.0, 1.0) = 0.75;
uniform float water_roughness : hint_range(0.0, 1.0) = 0.22;
uniform vec4 sky_glow : source_color = vec4(0.204, 0.278, 0.333, 1.0);
uniform float speed = 0.0;
uniform vec2 flow_dir = vec2(0.0, -1.0);
uniform vec4 drop_radii = vec4(0.0016, 0.0022, 0.003, 0.0038);
uniform vec4 travel_x = vec4(0.0);
uniform vec4 travel_y = vec4(0.0);
uniform float runner_radius = 0.0055;
uniform float runner_travel = 0.0;
uniform float runner_speed = 0.0;
uniform float seed = 0.0;
uniform vec2 glass_size = vec2(1.48, 0.9);

#include "rain_drops.gdshaderinc"

vec4 runner_layer(vec2 flow_space, vec2 across, vec2 flow, float wind) {
	float width = mix(0.075, 0.035, wind);
	float column = floor(flow_space.x / width);
	float pick = hash(vec2(column, seed + 4.2));
	if (pick < mix(0.62, 0.3, wind)) {
		return vec4(0.0);
	}
	float span = length(glass_size) + 0.4;
	float pace = mix(0.8, 1.25, hash(vec2(column, seed + 8.4)));
	float head = fract(pick * 7.3 + runner_travel * pace / span) * span - span * 0.5;
	float stretch = 1.0 + min(abs(runner_speed) * 4.0, 1.5);
	float sway = sin(flow_space.y * 9.0 + pick * 20.0) * 0.006;
	vec2 rel = vec2(flow_space.x - (column + 0.5) * width - sway, flow_space.y - head);
	vec2 drop = rel / vec2(runner_radius * mix(1.0, 0.7, wind), runner_radius * 1.2 * stretch);
	float body = 1.0 - smoothstep(0.8, 1.0, length(drop));
	float behind = -rel.y;
	float reach = mix(0.2, 0.45, wind);
	float trail_mask = step(0.0, behind) * (1.0 - smoothstep(0.05, reach, behind));
	float beads = step(mix(0.55, 0.3, wind), hash(vec2(column, floor(behind / 0.012))));
	float trail = trail_mask * beads * (1.0 - smoothstep(0.002, 0.004, abs(rel.x)));
	float coverage = max(body, trail * 0.8);
	vec2 slope = body > trail ? across * drop.x + flow * drop.y : across * (rel.x / 0.004);
	return vec4(slope, coverage, 0.016);
}

vec4 bin_layer(vec2 metres, vec2 travel, float radius, float salt) {
	float cell = 0.02;
	float size = radius / cell;
	return drop_layer(metres - travel, cell, 0.3, vec2(size * 0.9, size * 1.1), 0.01, salt,
		vec2(1.0, 1.12));
}

void fragment() {
	vec2 metres = vec2((UV.x - 0.5) * glass_size.x, (0.5 - UV.y) * glass_size.y);
	float wind = smoothstep(3.0, 15.0, speed);
	vec2 flow = normalize(flow_dir);
	vec2 across = vec2(-flow.y, flow.x);
	vec2 flow_space = vec2(dot(metres, across), dot(metres, flow));
	vec4 drop = drop_layer(metres, 0.006, 1.0, vec2(0.12, 0.3), 0.004, seed + 1.7,
		vec2(1.0, 1.12));
	vec4 first = bin_layer(metres, vec2(travel_x.x, travel_y.x), drop_radii.x, seed + 11.3);
	vec4 second = bin_layer(metres + vec2(0.31, 0.0), vec2(travel_x.y, travel_y.y),
		drop_radii.y, seed + 23.9);
	vec4 third = bin_layer(metres + vec2(0.0, 0.29), vec2(travel_x.z, travel_y.z),
		drop_radii.z, seed + 51.3);
	vec4 fourth = bin_layer(metres + vec2(0.17, 0.43), vec2(travel_x.w, travel_y.w),
		drop_radii.w, seed + 63.9);
	vec4 runner = runner_layer(flow_space, across, flow, wind);
	drop = strongest(strongest(strongest(drop, first), strongest(second, third)),
		strongest(fourth, runner));
	vec4 glass = wet_glass(drop, wetness, 0.0, vec2(0.0), SCREEN_UV,
		vec3(0.3, 0.55, 0.75));
	vec2 slope = drop.xy * smoothstep(0.0, 0.3, drop.z);
	vec3 surface = vec3(slope, 0.3 + sqrt(max(0.0, 1.0 - dot(slope, slope))));
	ALBEDO = vec3(0.0);
	EMISSION = glass.rgb + sky_glow.rgb * sky_view(drop);
	NORMAL_MAP = normalize(surface) * 0.5 + 0.5;
	ROUGHNESS = water_roughness;
	SPECULAR = 0.35;
	ALPHA = glass.a;
}
