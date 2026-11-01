shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D scene_color : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D wipe_mask : hint_default_white, filter_linear;
uniform bool wipers_on = true;
uniform float sweep_angle = -0.9;
uniform float wetness : hint_range(0.0, 1.0) = 0.2;
uniform float rain : hint_range(0.0, 1.0) = 1.0;
uniform float speed = 0.0;
uniform vec4 drop_radii = vec4(0.0016, 0.0022, 0.003, 0.0038);
uniform vec4 drop_travel = vec4(0.0);
uniform vec4 drop_speed = vec4(0.0);
uniform float runner_radius = 0.0055;
uniform float runner_speed = 0.0;
uniform float runner_down = 0.0;
uniform float runner_up = 0.0;
uniform float film_travel = 0.0;
uniform vec4 sky_glow : source_color = vec4(0.204, 0.278, 0.333, 1.0);
uniform vec2 glass_size = vec2(2.12, 1.08);
uniform float blade_speed = 0.0;
uniform float stroke_progress = 0.0;
uniform float dump = 0.0;
uniform float wiper_cycles = 0.0;
uniform float wiper_park = -1.55;
uniform float wiper_sweep = 1.72;
uniform vec4 wiper_pivots = vec4(-0.8, -0.51, 0.14, -0.51);
uniform vec4 wiper_spans = vec4(0.15, 0.85, 0.185, 0.735);

const float RUN_LANE = 0.06;
const float RUN_EPOCH = 0.5;
const float BEAD_STEP = 0.011;
const float BLADE_HALF = 0.0105;
const float RIDGE_WIDTH = 0.014;
const float STREAK_BAND = 0.006;
const float ARM_HALF = 0.007;
const float SHUTTER = 0.02;
const vec3 BLADE_TINT = vec3(0.012);

#include "rain_drops.gdshaderinc"

float stroke_index(vec2 rel) {
	float swept = (-atan(rel.x, rel.y) - wiper_park) / wiper_sweep;
	if (swept < 0.0 || swept > 1.0) {
		return -1.0;
	}
	float turn = acos(clamp(1.0 - 2.0 * swept, -1.0, 1.0)) / TAU;
	float cycle = floor(wiper_cycles);
	float phase = wiper_cycles - cycle;
	if (phase >= 1.0 - turn) {
		return cycle * 2.0 + 1.0;
	}
	return phase >= turn ? cycle * 2.0 : cycle * 2.0 - 1.0;
}

float wipe_seed(vec2 metres, float cell, vec2 offset) {
	vec2 centre = (floor((metres + offset) / cell) + 0.5) * cell - offset;
	float latest = -1.0;
	for (int index = 0; index < 2; index++) {
		vec2 pivot = index == 0 ? wiper_pivots.xy : wiper_pivots.zw;
		vec2 span = index == 0 ? wiper_spans.xy : wiper_spans.zw;
		vec2 rel = centre - pivot;
		float reach = length(rel);
		if (reach >= span.x && reach <= span.y) {
			latest = max(latest, stroke_index(rel));
		}
	}
	return latest < 0.0 ? 0.0 : fract(latest * 0.618034 + 0.37) * 97.0;
}

vec4 blade_water(vec2 metres, float age) {
	vec4 best = vec4(0.0);
	float moving = smoothstep(0.2, 0.8, abs(blade_speed));
	float lead = blade_speed > 0.0 ? -1.0 : 1.0;
	float blade = -sweep_angle;
	float top = -(wiper_park + wiper_sweep);
	float fresh = 1.0 - smoothstep(0.0, 0.4, age);
	for (int index = 0; index < 2; index++) {
		vec2 pivot = index == 0 ? wiper_pivots.xy : wiper_pivots.zw;
		vec2 span = index == 0 ? wiper_spans.xy : wiper_spans.zw;
		vec2 rel = metres - pivot;
		float reach = length(rel);
		if (reach < span.x || reach > span.y) {
			continue;
		}
		float side = float(index);
		float angle = atan(rel.x, rel.y);
		vec2 across = vec2(cos(angle), -sin(angle));
		float lumps = mix(0.45, 1.35, noise(vec2(reach * 38.0,
			side * 9.0 + floor(wiper_cycles * 2.0))));
		float width = RIDGE_WIDTH * mix(0.35, 1.0, stroke_progress) * lumps * moving;
		float ahead = (angle - blade) * reach * lead - BLADE_HALF;
		if (width > 0.0005 && ahead > 0.0 && ahead < width) {
			float u = ahead / width * 2.0 - 1.0;
			best = strongest(best, vec4(across * u * lead,
				(1.0 - smoothstep(0.7, 1.0, abs(u))) * 0.95, 0.014));
		}
		float pile = RIDGE_WIDTH * lumps;
		float beyond = (top - angle) * reach - BLADE_HALF;
		if (dump > 0.02 && beyond > 0.0 && beyond < pile) {
			float u = beyond / pile * 2.0 - 1.0;
			float beads = step(1.0 - dump, noise(vec2(reach * 70.0, side * 4.0 + 1.7)));
			best = strongest(best, vec4(-across * u,
				(1.0 - smoothstep(0.6, 1.0, abs(u))) * beads * 0.9, 0.012));
		}
		float band = floor(reach / STREAK_BAND);
		if (fresh > 0.0 && hash(vec2(band, side * 31.0 + 4.0)) > 0.84) {
			float u = (fract(reach / STREAK_BAND) - 0.5) / 0.16;
			float dashed = step(0.42, noise(vec2(angle * reach * 55.0, band)));
			float line = (1.0 - smoothstep(0.6, 1.0, abs(u))) * dashed * fresh;
			best = strongest(best, vec4(vec2(0.0), line * 0.4, 0.0));
		}
	}
	return best;
}

float blade_blur(vec2 metres) {
	float blade = -sweep_angle;
	float trail = blade + blade_speed * SHUTTER;
	float from = min(blade, trail);
	float to = max(blade, trail);
	if (to - from < 0.002) {
		return 0.0;
	}
	float darkest = 0.0;
	for (int index = 0; index < 2; index++) {
		vec2 pivot = index == 0 ? wiper_pivots.xy : wiper_pivots.zw;
		vec2 span = index == 0 ? wiper_spans.xy : wiper_spans.zw;
		vec2 rel = metres - pivot;
		float reach = length(rel);
		float angle = atan(rel.x, rel.y);
		if (reach > span.y || angle < from || angle > to) {
			continue;
		}
		float width = reach >= span.x ? BLADE_HALF * 2.0 : ARM_HALF * 2.0;
		float behind = abs(angle - blade) / (to - from);
		darkest = max(darkest, min(width / ((to - from) * reach), 1.0) * (1.0 - behind) * 0.9);
	}
	return darkest;
}

vec4 runner(vec2 metres, float odometer, float direction, float phase, float shown,
		inout float track) {
	float column = floor(metres.x / RUN_LANE);
	float salt = hash(vec2(column, phase * 13.7 + direction * 3.1));
	float pace = mix(0.6, 1.5, hash(vec2(salt, 8.4)));
	float shifted = odometer * pace / RUN_EPOCH + salt;
	float epoch = floor(shifted);
	float progress = fract(shifted);
	float id = hash(vec2(column + epoch * 31.0, phase + direction * 7.0));
	if (id > 0.55 || shown <= 0.0) {
		return vec4(0.0);
	}
	float start = (hash(vec2(id, 5.1)) - 0.5) * glass_size.y;
	float length_run = mix(0.08, 0.45, hash(vec2(id, 6.3)));
	float moved = min(slip(progress * RUN_EPOCH, id * 40.0), length_run);
	float fade = (1.0 - smoothstep(0.85, 1.0, progress)) * shown;
	float lane = (column + 0.5 + (hash(vec2(id, 7.7)) - 0.5) * 0.4) * RUN_LANE;
	float path = lane + (noise(vec2(metres.y * 9.0, id * 50.0)) - 0.5) * 0.02;
	float radius = runner_radius * mix(0.85, 1.35, hash(vec2(id, 9.9)));
	float sliding = step(moved, length_run - 0.002);
	float stretch = 1.0 + min(abs(runner_speed) * pace * 6.0, 1.5) * sliding;
	float head = start + direction * moved;
	vec2 rel = vec2(metres.x - path, metres.y - head);
	vec2 shape = rel / vec2(radius, radius * 1.15 * stretch);
	float body = (1.0 - smoothstep(0.8, 1.0, length(shape))) * fade;
	float along = (metres.y - start) * direction;
	float travelled = step(0.0, along) * step(along, moved - radius * 0.6);
	track = max(track, travelled * (1.0 - smoothstep(radius * 0.8, radius * 1.2, abs(rel.x)))
		* fade);
	float segment = floor(along / BEAD_STEP);
	vec2 bead_at = vec2(path + (hash(vec2(segment, id)) - 0.5) * 0.004,
		start + direction * (segment + 0.5) * BEAD_STEP);
	float bead_size = mix(0.0006, 0.0016, hash(vec2(segment, id * 3.0)));
	vec2 bead_shape = (metres - bead_at) / bead_size;
	float bead = step(0.45, hash(vec2(id * 17.0, segment))) * travelled * fade
		* (1.0 - smoothstep(0.75, 1.0, length(bead_shape)));
	if (body >= bead) {
		return vec4(shape, body, 0.022);
	}
	return vec4(bead_shape, bead * 0.9, 0.006);
}

void fragment() {
	vec2 metres = vec2((UV.x - 0.5) * glass_size.x, (0.5 - UV.y) * glass_size.y);
	float age = texture(wipe_mask, UV).r;
	float wet = smoothstep(0.4, 0.7, age);
	float falling = smoothstep(0.003, 0.03, -runner_speed) * wet;
	float climbing = smoothstep(0.003, 0.03, runner_speed) * wet;
	float track = 0.0;
	vec4 runners = strongest(
		strongest(runner(metres, runner_down, -1.0, 0.0, falling, track),
			runner(metres, runner_down, -1.0, 1.0, falling, track)),
		strongest(runner(metres, runner_up, 1.0, 0.0, climbing, track),
			runner(metres, runner_up, 1.0, 1.0, climbing, track)));
	float kept = 1.0 - track;
	vec4 drop = drop_layer(metres, 0.006, age * kept, vec2(0.14, 0.32), 0.004,
		1.7 + wipe_seed(metres, 0.006, vec2(0.0)), vec2(1.0, 1.12));
	vec4 fine = drop_layer(metres + vec2(0.21, 0.07), 0.008, age * kept, vec2(0.13, 0.3),
		0.005, 41.7 + wipe_seed(metres, 0.008, vec2(0.21, 0.07)), vec2(1.0, 1.12));
	vec4 settled = drop_layer(metres + vec2(0.13, 0.29), 0.014, age * kept, vec2(0.12, 0.23),
		0.008, 71.3 + wipe_seed(metres, 0.014, vec2(0.13, 0.29)), vec2(1.0, 1.12));
	vec4 medium = physical_layer(metres, 0.018, age * kept, drop_radii, drop_travel,
		drop_speed, 0.01, 11.3);
	vec4 large = physical_layer(metres + vec2(0.37, 0.11), 0.024, age * 0.8 * kept, drop_radii,
		drop_travel, drop_speed, 0.016, 23.9);
	vec4 drop_mix = strongest(strongest(drop, fine), strongest(settled, strongest(medium, large)));
	drop_mix = strongest(drop_mix, runners);
	vec4 water = blade_water(metres, age);
	drop_mix = strongest(drop_mix, water);
	float film = clamp(mix(0.08, 1.0, age) * wetness, 0.0, 1.0);
	float smear = 1.0 - smoothstep(0.0, 0.05, age);
	float shift = -film_travel * 14.0;
	vec2 ripple = vec2(noise(metres * 14.0 + vec2(0.0, shift)),
		noise(metres * 14.0 + vec2(5.2, shift + 1.3))) - 0.5;
	vec4 glass = wet_glass(drop_mix, film, smear, ripple * film * 0.012, SCREEN_UV,
		vec3(-0.35, 0.55, 0.75));
	float crest = water.z * pow(1.0 - min(length(water.xy), 1.0), 2.0);
	vec3 around = textureLod(scene_color, SCREEN_UV, 3.5).rgb;
	vec3 colour = glass.rgb + sky_glow.rgb * sky_view(drop_mix)
		+ (around * 0.9 + sky_glow.rgb * 0.35) * crest;
	float alpha = max(glass.a, crest * 0.8);
	float blur = blade_blur(metres);
	float covered = 1.0 - (1.0 - alpha) * (1.0 - blur);
	ALBEDO = (colour * alpha * (1.0 - blur) + BLADE_TINT * blur) / max(covered, 0.001);
	ALPHA = covered;
}
