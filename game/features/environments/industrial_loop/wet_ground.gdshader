// The wet ground of Blackridge's rainy night (#270-#275): asphalt and concrete in heavy rain, as the
// author's photos show them, from Sebastien Lagarde's physically based wet surfaces ("Water drop 3b",
// 2013) and his rain ripples ("Water drop 2b"):
// - the whole surface under a film of water (drenched, as in heavy rain): its diffuse colour
//   darkened by its porosity, lerp(1, 0.2, porosity), its roughness lowered toward water's, its
//   small bumps mostly drowned, the tops of its stones still a little rough;
// - puddles where water really lies, fading out through a damp margin: on a road along its two
//   edges (its crown falls about 2% to each side), in each lane's two wheel paths in stretches and
//   in a few sunken patches; on a slab toward its drain, along its saw-cut joints and in shallow
//   dips. A puddle is still water: roughness 0.02, F0 0.02 (water's IOR 1.33), its normal flat;
// - rain ripples on the puddles, and fainter on the film, from a data texture of rings in four
//   layers that come in as the rain grows heavier, adapted from Rain Puddles V3 (below);
// - reflections from Rain Puddles V3's own screen-space ray march (the author's choices, #277,
//   "Combine them", and #278, "Whole wet surface"): sharp in the puddles and across the whole wet
//   film blurred by its roughness, given as the light the water returns (emission) with water's
//   Fresnel, F0 0.02, so a lamp's reflection keeps its brightness even where the ground is dark;
// - the road's crossing paint and cracks as before.
// A road passes its place across itself in COLOR.r (0 its left edge, 1 its right) and its half
// width in COLOR.g (metres / 8); a slab sets `slab` and its drain.
//
// The ripple functions (ripple, the layers' time offsets, weights and UV offsets, and combining
// four normals) and the screen-space reflection march (get_uv_from_view_position,
// get_view_position_from_uv, the screen border's fade and get_ssr_color) are adapted from "Rain
// Puddle Shader v3" by GloriousGlider8, https://godotshaders.com/shader/rain-puddles-v1/, whose
// reflection logic is taken from marcelb's GodotSSRWater, https://github.com/marcelb/GodotSSRWater,
// both under the MIT licence:
//
// Copyright (c) 2023 - present Marcel Bankmann.
// Copyright 2026 GloriousGlider8 (as YourSoftware Foundation, https://yoursoftware.org)
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
// associated documentation files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute,
// sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
// NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
shader_type spatial;
render_mode specular_schlick_ggx, depth_draw_always;

uniform sampler2D aggregate_color : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D aggregate_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D aggregate_arm : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D rain_ripples : filter_linear, repeat_enable;
uniform vec3 dry_color : source_color = vec3(0.85, 0.85, 0.85);
uniform float texture_scale = 0.45;
uniform float arm_roughness : hint_range(0.0, 1.0) = 1.0;
uniform float porosity : hint_range(0.0, 1.0) = 0.7;
uniform float wetness : hint_range(0.0, 1.0) = 1.0;
uniform float rain_intensity : hint_range(0.0, 1.0) = 0.85;
uniform float puddle_amount : hint_range(0.0, 1.0) = 0.6;
// The film's and the puddles' roughness: the film's water over the aggregate, the puddles' still
// water (rain's ripples roughen both).
uniform float film_roughness : hint_range(0.0, 1.0) = 0.12;
uniform float puddle_roughness : hint_range(0.0, 1.0) = 0.08;
uniform bool puddle_reflections = true;
// The film reflects too, as a wet road does in heavy rain, blurred by its roughness.
uniform bool film_reflections = true;
uniform float ssr_resolution : hint_range(0.01, 10.0, 0.1) = 1.0;
uniform float ssr_max_travel : hint_range(0.0, 200.0, 0.1) = 30.0;
uniform float ssr_max_diff : hint_range(0.1, 10.0, 0.1) = 4.0;
uniform float ssr_screen_border_fadeout : hint_range(0.0, 1.0, 0.1) = 0.3;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform bool slab = false;
uniform vec4 drain = vec4(0.0, 0.0, 1.0, 0.0);
uniform float drain_reach = 0.0;
uniform float joint_spacing = 0.0;
uniform float crack_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec2 crossing_centre = vec2(0.0);
uniform vec2 crossing_along = vec2(1.0, 0.0);
uniform vec2 crossing_size = vec2(0.0);
uniform float crossing_wear : hint_range(0.0, 1.0) = 0.45;
varying vec3 world_position;
varying vec2 road_place;

const float BAR_PITCH = 1.2;
const float BAR_HALF = 0.3;
const float WHEEL_TRACK = 0.85;
const vec3 PAINT_COLOR = vec3(0.7, 0.7, 0.67);
const float STONE_ROUGHNESS = 0.32;
const float FILM_FLAT = 0.82;
const float FILM_RIPPLES = 0.2;
const float EDGE_WATER = 0.45;
const float RUT_WIDE = 0.32;
const float JOINT_WIDE = 0.006;
const float POOL_FROM = 0.42;
const float POOL_TO = 0.58;
const float RIPPLE_SCALE = 0.7;
const float WATER_SPECULAR = 0.25;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

float crossing_paint(vec2 p) {
	if (crossing_size.x <= 0.0) {
		return 0.0;
	}
	vec2 rel = p - crossing_centre;
	float along = dot(rel, crossing_along);
	float across = dot(rel, vec2(-crossing_along.y, crossing_along.x));
	vec2 half_size = crossing_size * 0.5;
	if (abs(along) > half_size.x + 0.05 || abs(across) > half_size.y) {
		return 0.0;
	}
	float edge = 0.012;
	float from_bar = abs(fract(across / BAR_PITCH) - 0.5) * BAR_PITCH;
	float bar = 1.0 - smoothstep(BAR_HALF - edge, BAR_HALF + edge, from_bar);
	bar *= 1.0 - smoothstep(half_size.x - edge, half_size.x + edge, abs(along));
	float track = 1.0 - smoothstep(0.15, 0.45, abs(abs(across) - WHEEL_TRACK));
	float speckle = noise(p * 9.0) * 0.6 + noise(p * 31.0) * 0.4;
	float wear = track * crossing_wear + smoothstep(0.55, 0.9, speckle) * 0.5;
	return bar * clamp(1.0 - wear, 0.0, 1.0);
}

// How deep water lies here, 0 dry high ground to 1 a full puddle.
float water_depth(vec2 p) {
	float dips = smoothstep(0.62, 0.86, noise(p * 0.09) * 0.65 + noise(p * 0.37 + 4.1) * 0.35);
	if (slab) {
		vec2 along = normalize(drain.zw);
		float to_drain = abs(dot(p - drain.xy, vec2(-along.y, along.x)));
		float toward = drain_reach > 0.0 ? 1.0 - smoothstep(0.0, drain_reach, to_drain) : 0.0;
		float joint = 0.0;
		if (joint_spacing > 0.0) {
			vec2 cell = abs(fract(p / joint_spacing) - 0.5) * joint_spacing;
			float near = min(joint_spacing * 0.5 - cell.x, joint_spacing * 0.5 - cell.y);
			joint = 1.0 - smoothstep(0.0, 0.05, near);
		}
		float patchy = noise(p * 0.6 + 2.3);
		return clamp(max(max(dips * 0.9, toward * mix(0.55, 1.0, patchy)), joint * 0.62), 0.0, 1.0);
	}
	float half_width = road_place.y;
	float from_centre = (road_place.x * 2.0 - 1.0) * half_width;
	float to_edge = half_width - abs(from_centre);
	float edge = 1.0 - smoothstep(0.0, EDGE_WATER, to_edge);
	float lane_middle = half_width * 0.5;
	float rut = 0.0;
	for (int side = -1; side <= 1; side += 2) {
		for (int wheel = -1; wheel <= 1; wheel += 2) {
			float path = float(side) * lane_middle + float(wheel) * WHEEL_TRACK;
			rut = max(rut, exp(-pow((from_centre - path) / RUT_WIDE, 2.0)));
		}
	}
	float stretches = smoothstep(0.45, 0.75, noise(p * 0.11 + 9.7));
	float edges = edge * mix(0.6, 1.0, noise(p * 0.21 + 1.3));
	return clamp(max(max(edges, rut * stretches * 0.85), dips * 0.8), 0.0, 1.0);
}

vec3 ripple(float time, vec2 uv, float weight) {
	vec4 tex = texture(rain_ripples, uv);
	time = fract(time + tex.a);
	float pathway_1 = clamp(weight * 0.8 + 0.2 - time, 0.0, 1.0);
	float pathway_2 = sin(clamp((time - 1.0 + tex.r) * 20.0, 0.0, 5.0) * PI) * pathway_1;
	return normalize(vec3((tex.gb * 2.0 - 1.0) * pathway_2 * 0.35, 1.0));
}

vec3 combine_4_normals(vec4 weights, vec3 a, vec3 b, vec3 c, vec3 d) {
	vec2 xy = a.xy * weights.x + b.xy * weights.y + c.xy * weights.z + d.xy * weights.w;
	vec4 z = mix(vec4(1.0), vec4(a.z, b.z, c.z, d.z), weights);
	return normalize(vec3(xy, z.x * z.y * z.z * z.w));
}

vec3 rain_rings(vec2 p, float time) {
	vec4 weights = clamp((vec4(rain_intensity) - vec4(0.0, 0.25, 0.5, 0.75)) * 4.0, 0.0, 1.0);
	vec4 times = (vec4(time) * vec4(1.0, 0.85, 0.93, 1.1) + vec4(0.0, 2.0, 0.45, 0.7)) * 1.6;
	vec2 uv = p * RIPPLE_SCALE;
	return combine_4_normals(weights, ripple(times.x, uv * 0.7, weights.x),
		ripple(times.y, (uv + vec2(-0.55, 0.3)) * 0.75, weights.y),
		ripple(times.z, (uv + vec2(0.6, 0.85)) * 0.65, weights.z),
		ripple(times.w, (uv + vec2(0.5, -0.75)) * 0.72, weights.w));
}

vec2 get_uv_from_view_position(vec3 position_view_space, mat4 proj_m) {
	vec4 position_clip_space = proj_m * vec4(position_view_space, 1.0);
	return (position_clip_space.xy / position_clip_space.w) * 0.5 + 0.5;
}

vec3 get_view_position_from_uv(vec2 uv, float depth_raw, mat4 inv_proj_m) {
	vec4 position_ndc = vec4(uv * 2.0 - 1.0, depth_raw, 1.0);
	vec4 view_position = inv_proj_m * position_ndc;
	return view_position.xyz / view_position.w;
}

bool is_within_screen_boundaries(vec2 position) {
	return position.x > 0.0 && position.x < 1.0 && position.y > 0.0 && position.y < 1.0;
}

float get_screen_border_alpha(vec2 screen_position) {
	vec2 shifted = 4.0 * screen_position * (1.0 - screen_position);
	float mask = shifted.x * shifted.y;
	float offset = mix(0.0, 0.5, (clamp(ssr_screen_border_fadeout, 0.75, 1.0) - 0.75) / 0.25);
	float alpha = clamp(smoothstep(0.0, 2.0 * ssr_screen_border_fadeout, mask) - offset, 0.0, 1.0);
	return ssr_screen_border_fadeout < 1e-5 ? 1.0 : alpha;
}

// What the puddle reflects along its normal, marched across the screen: rgb, and in a how sure.
vec4 get_ssr_color(vec3 surface_view_position, vec3 normal_view_space, vec3 view_view_space,
		mat4 proj_m, mat4 inv_proj_m, float blur) {
	vec3 position = surface_view_position;
	vec3 reflect_vector = normalize(reflect(-view_view_space, normal_view_space));
	vec2 screen_position = vec2(0.0);
	vec3 result = vec3(-1.0);
	for (float travel = 0.0; result.x < 0.0 && travel < ssr_max_travel; travel += ssr_resolution) {
		position += reflect_vector * ssr_resolution;
		screen_position = get_uv_from_view_position(position, proj_m);
		float depth_raw = texture(depth_texture, screen_position).x;
		vec3 probe = get_view_position_from_uv(screen_position, depth_raw, inv_proj_m);
		float depth_diff = probe.z - position.z;
		vec3 colour = textureLod(screen_texture, screen_position, blur).rgb;
		result = (is_within_screen_boundaries(screen_position) && depth_diff >= 0.0
			&& depth_diff < ssr_max_diff) ? colour : vec3(-1.0);
	}
	if (result.x < 0.0) {
		return vec4(0.0);
	}
	return vec4(result, get_screen_border_alpha(screen_position));
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	road_place = vec2(COLOR.r, COLOR.g * 8.0);
}

void fragment() {
	vec2 p = world_position.xz;
	vec2 uv = p * texture_scale;
	vec3 aggregate = texture(aggregate_color, uv).rgb;
	vec3 arm = texture(aggregate_arm, uv).rgb;
	float stones = dot(aggregate, vec3(0.333)) - 0.5;
	float stone_top = smoothstep(-0.26, -0.23, stones);
	float depth = water_depth(p) * puddle_amount / 0.6;
	float pool = smoothstep(POOL_FROM, POOL_TO, depth + stones * 0.05) * wetness;
	float damp = smoothstep(POOL_FROM - 0.2, POOL_FROM, depth) * wetness;
	vec2 crack_uv = p * 0.31;
	crack_uv.x += noise(p * 0.83) * 0.6;
	float crack = 1.0 - smoothstep(0.009, 0.035, abs(sin(crack_uv.x * 3.14159)));
	crack *= smoothstep(0.36, 0.65, noise(p * 0.33)) * crack_amount;
	float joint = 0.0;
	if (slab && joint_spacing > 0.0) {
		vec2 cell = abs(fract(p / joint_spacing) - 0.5) * joint_spacing;
		float near = min(joint_spacing * 0.5 - cell.x, joint_spacing * 0.5 - cell.y);
		joint = 1.0 - smoothstep(JOINT_WIDE * 0.5, JOINT_WIDE, near);
	}
	float paint = crossing_paint(p);
	float soak = mix(1.0, mix(1.0, 0.2, porosity), wetness);
	soak = mix(soak, soak * 0.85, damp);
	vec3 ground = aggregate * dry_color * soak * (1.0 - crack * 0.65) * (1.0 - joint * 0.6);
	ALBEDO = mix(ground, PAINT_COLOR * mix(1.0, 0.8, wetness), paint);
	float dry_roughness = mix(0.83, arm.g, arm_roughness);
	float film = mix(film_roughness, STONE_ROUGHNESS, stone_top * (1.0 - damp));
	float surface = mix(dry_roughness, film, wetness);
	float footprint = max(length(dFdx(p)), length(dFdy(p)));
	float unresolved = smoothstep(0.004, 0.02, footprint);
	float pool_roughness = mix(puddle_roughness, 0.08, unresolved * rain_intensity);
	ROUGHNESS = mix(mix(surface, pool_roughness, pool), mix(0.3, 0.12, wetness), paint * (1.0 - pool));
	SPECULAR = mix(0.5, WATER_SPECULAR, pool);
	vec3 rings = vec3(0.0, 0.0, 1.0);
	float ringing = max(pool, damp * FILM_RIPPLES) * wetness * (1.0 - unresolved);
	if (ringing > 0.01 && rain_intensity > 0.0) {
		rings = rain_rings(p, TIME);
	}
	vec3 small = texture(aggregate_normal, uv).rgb * 2.0 - 1.0;
	vec3 drowned = normalize(mix(small, vec3(0.0, 0.0, 1.0), max(pool, FILM_FLAT * wetness)));
	vec3 rippled = normalize(vec3(drowned.xy + rings.xy * ringing, drowned.z));
	vec3 tangent_normal = normalize(mix(rippled, normalize(mix(small, vec3(0.0, 0.0, 1.0), 0.5)),
		paint * 0.7));
	NORMAL_MAP = tangent_normal * 0.5 + 0.5;
	float film_share = film_reflections ? (1.0 - pool) * wetness
		* (1.0 - smoothstep(0.0, 0.5, surface)) * (1.0 - paint) : 0.0;
	if (puddle_reflections && (pool > 0.01 || film_share > 0.01) && ssr_max_travel > 0.0) {
		vec3 normal_view = normalize(TANGENT * tangent_normal.x + BINORMAL * tangent_normal.y
			+ NORMAL * tangent_normal.z);
		vec3 surface_view = get_view_position_from_uv(SCREEN_UV, FRAGCOORD.z,
			INV_PROJECTION_MATRIX);
		float blur = mix(1.0, 1.0 + surface * 8.0, film_share / max(film_share + pool, 0.001));
		vec4 mirrored = get_ssr_color(surface_view, normal_view, VIEW, PROJECTION_MATRIX,
			INV_PROJECTION_MATRIX, blur);
		float facing = max(dot(normal_view, VIEW), 0.0);
		float fresnel = 0.02 + 0.98 * pow(1.0 - facing, 5.0);
		float share = mirrored.a * fresnel * (pool + film_share);
		EMISSION = mirrored.rgb * share;
		ALBEDO *= 1.0 - share;
	}
}
