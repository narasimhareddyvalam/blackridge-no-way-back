// Rain Puddle Shader v3
// Changes from v2: Fixed some bugs and added refraction for AO map
// Changes from v1: Added albedo refraction

/*
Copyright 2026 GloriousGlider8 (as YourSoftware Foundation, https://yoursoftware.org)
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// SSR logic taken from https://github.com/marcelb/GodotSSRWater and modified.
// See https://github.com/marcelb/GodotSSRWater/blob/main/LICENSE.md for license.

/*
Parameters:
- Base Albedo, Normal, Roughness, Metallic, Emission, AOC, Specular:
	The base PBR material data.
- Puddle Noise
	512x512 seamless noise texture to determine where puddles are generated.
- Puddle Noise Cutoff
	Cutoff point of puddle generation - lower means smaller puddles, high means larger.
- Puddle Noise Scale
	Scale of puddle noise texture.
- Puddle UV Mask
	Puddle mask in UV space - make this the base material's heightmap.
- Puddle UV Mask Cutoff
	Cutoff point of puddle generation for UV mask.
- Puddle UV Mask GT-0, LT-1
	Set to 0 to have puddles generate in points where the UV mask is greater than the cutoff, and to
	1 for less than.
- Wind Normal Noise
	512x512 seamless noise normal map to be counter-scrolled for a wind effect.
- Wind Strength
	Controls the speed of the wind normal scrolling.
- Rain Ripples Data
	Data texture to control rain ripples:
	- R: Radial gradient for each ripple
	- G: X normal for each ripple.
	- B: Y normal for each ripple.
	- A: Time offset for each ripple.
	Must be losslessly compressed.
- Rain Ripples Intensity
	Controls the amount, and visibility of ripple layers.
- SSR Resolution
	Resolution of SSR effect - lower is better but slower.
- SSR Max Travel
	Max distance rays will march - higher is better but slower, 0 disables SSR.
- SSR Max Diff
	Max diff from geometry that is counted as a hit - low values might miss geometry, high values
	might create false positives, no perfomance impact.
- SSR Screen Border Fadeout
	Strength of fade-out effect on reflections close to the screen borders.
*/

shader_type spatial;
render_mode depth_draw_always;

const float EPSILON = 1e-5;

uniform sampler2D base_albedo : source_color, filter_linear_mipmap;
uniform sampler2D base_normal : source_color, hint_normal, filter_linear_mipmap;
uniform sampler2D base_roughness : hint_roughness_gray, filter_linear_mipmap;
uniform sampler2D base_metallic : hint_roughness_gray, filter_linear_mipmap;
uniform sampler2D base_emission : source_color, filter_linear_mipmap;
uniform sampler2D base_aoc : hint_roughness_gray, filter_linear_mipmap;
uniform sampler2D base_specular : hint_roughness_gray, filter_linear_mipmap;

uniform sampler2D puddle_noise : filter_linear_mipmap, hint_roughness_gray;
uniform float puddle_noise_cutoff : hint_range(0.0, 1.0) = 0.5;
uniform vec2 puddle_noise_scale = vec2(0.05, 0.05);
uniform sampler2D puddle_uv_mask : source_color, filter_linear_mipmap, hint_roughness_gray;
uniform float puddle_uv_mask_cutoff : hint_range(0.0, 1.0) = 0.5;
uniform float puddle_uv_mask_gt_0_lt_1 : hint_range(0.0, 1.0, 1.0) = 0.0;

uniform sampler2D wind_normal_noise : source_color, hint_normal, filter_linear_mipmap;
uniform float wind_strength : hint_range(0.0, 1.0) = 0.25;

uniform sampler2D rain_ripples_data : source_color, filter_linear_mipmap;

uniform float rain_ripples_intensity : hint_range(0.0, 1.0) = 0.5;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_nearest;

uniform float ssr_resolution : hint_range(0.01, 10.0, 0.1) = 1.0;
uniform float ssr_max_travel : hint_range(0.0, 200.0, 0.1) = 30.0;
uniform float ssr_max_diff : hint_range(0.1, 10.0, 0.1) = 4.0;
uniform float ssr_screen_border_fadeout : hint_range(0.0, 1.0, 0.1) = 0.3;

varying vec3 world_position;
varying vec3 face_normal;
varying vec3 v_tangent_view;
varying vec3 v_binormal_view;

float when_lt(float x, float y) {
	return max(sign(y - x), 0.0);
}

float when_eq(float x, float y) {
	return 1.0 - abs(sign(x - y));
}

float when_neq(float x, float y) {
	return abs(sign(x - y));
}

vec3 when_neq(vec3 x, vec3 y) {
	return abs(sign(x - y));
}

float when_gt(float x, float y) {
	return max(sign(x - y), 0.0);
}

vec3 ripple(float time, vec2 uv, float weight) {
	vec4 tex = texture(rain_ripples_data, uv).rgba;
	time += tex.a;
	time = fract(time);

	float pathway_1 = clamp(((weight * 0.8) + 0.2) - time, 0.0, 1.0);
	float pathway_2 = sin(clamp(((time - 1.0) + tex.r) * 20.0, 0.0, 5.0) * PI) * pathway_1;

	return normalize(vec3((tex.gb * 2.0 - 1.0) * pathway_2 * 0.35, 1.0));
}

vec4 ripple_time_offsets(float time) {
	return ((vec4(time) * vec4(1.0, 0.85, 0.93, 1.1)) + vec4(0.0, 2.0, 0.45, 0.7)) * 1.6;
}

vec4 ripple_weight_variations() {
	return clamp((vec4(rain_ripples_intensity) - vec4(0.0, 0.25, 0.5, 0.75)) * 4.0, 0.0, 1.0);
}

vec4 ripple_uv_offsets_1(vec2 uv) {
	return vec4(uv * 0.7, (uv + vec2(-0.55, 0.3)) * 0.75);
}

vec4 ripple_uv_offsets_2(vec2 uv) {
	return vec4((uv + vec2(0.6, 0.85)) * 0.65, (uv + vec2(0.5, -0.75)) * 0.72);
}

vec3 combine_4_normals(vec4 weights, vec3 a, vec3 b, vec3 c, vec3 d) {
	vec2 xy_components = (a.xy * weights.x) + (b.xy * weights.y) + (c.xy * weights.z) + (d.xy * weights.w);
	vec4 z_components = mix(vec4(1.0), vec4(a.z, b.z, c.z, d.z), weights);
	float z_component = z_components.x * z_components.y * z_components.z * z_components.w;
	return normalize(vec3(xy_components, z_component));
}

vec3 final_ripples() {
	vec4 ripple_weights = ripple_weight_variations();
	vec4 ripple_times = ripple_time_offsets(TIME);
	vec4 ripple_uvs_1 = ripple_uv_offsets_1(world_position.xz);
	vec4 ripple_uvs_2 = ripple_uv_offsets_2(world_position.xz);
	return combine_4_normals(ripple_weights, ripple(ripple_times.x, ripple_uvs_1.xy, ripple_weights.x),
		ripple(ripple_times.y, ripple_uvs_1.zw, ripple_weights.y),
		ripple(ripple_times.z, ripple_uvs_2.xy, ripple_weights.z),
		ripple(ripple_times.w, ripple_uvs_2.zw, ripple_weights.w));
}

vec3 final_wind() {
	float wind_strength_final = mix(0.2, 0.5, wind_strength);

	vec3 normal = texture(wind_normal_noise, world_position.xz + (TIME * 0.35 * wind_strength_final)).rgb;
	normal *= texture(wind_normal_noise, world_position.xz + vec2(TIME * 0.25 * wind_strength_final) * vec2(1.0, -0.5)).rgb;
	return normal;
}

vec3 unpack_normal(vec3 normal) {
	vec2 normal_xy = normal.rg * 2.0 - 1.0;
	float normal_z = sqrt(max(0.0, 1.0 - dot(normal_xy, normal_xy)));
	return vec3(normal_xy, normal_z);
}

vec2 get_uv_from_view_position(vec3 position_view_space, mat4 proj_m) {
	vec4 position_clip_space = proj_m * vec4(position_view_space.xyz, 1.0);
	vec2 position_ndc = position_clip_space.xy / position_clip_space.w;
	return position_ndc.xy * 0.5 + 0.5;
}

vec3 get_view_position_from_uv(vec2 uv, float depth_raw, mat4 inv_proj_m) {
	vec4 position_ndc = vec4(uv * 2.0 - 1.0, depth_raw * 2.0 - 1.0, (1.0 - depth_raw) * 2.0 - 1.0);
	vec4 view_position = inv_proj_m * position_ndc;
	return view_position.xyz / view_position.w;
}

bool is_within_screen_boundaries(vec2 position) {
	return position.x > 0.0 && position.x < 1.0 && position.y > 0.0 && position.y < 1.0;
}

float get_screen_border_alpha(vec2 screen_position) {
    vec2 shifted_screen_position = 4.0 * screen_position * (1.0 - screen_position);
	float mask = shifted_screen_position.x * shifted_screen_position.y;

	float offset = mix(0.0, 0.5, (clamp(ssr_screen_border_fadeout, 0.75, 1.0)-0.75) / 0.25);
	float alpha = clamp(smoothstep(0.0, 2.0 * ssr_screen_border_fadeout, mask) - offset, 0.0, 1.0);

	return mix(alpha, 1.0, when_lt(ssr_screen_border_fadeout, EPSILON));
}

vec4 get_ssr_color(vec3 surface_view_position, vec3 normal_view_space, vec3 view_view_space, mat4 proj_m, mat4 inv_proj_m) {
	vec3 current_position_view_space = surface_view_position;
	vec3 view_direction_view_space = view_view_space * -1.0;
	vec3 reflect_vector_view_space = normalize(reflect(view_direction_view_space.xyz, normal_view_space.xyz));

	vec2 current_screen_position = vec2(0.0);

	vec3 resulting_color = vec3(-1.0);
	for (float travel=0.0; resulting_color.x < 0.0 && travel < ssr_max_travel; travel = travel + ssr_resolution) {
		current_position_view_space += reflect_vector_view_space * ssr_resolution;
		current_screen_position = get_uv_from_view_position(current_position_view_space, proj_m);

		float depth_texture_probe_raw = texture(DEPTH_TEXTURE, current_screen_position).x;
		vec3 depth_texture_probe_view_position = get_view_position_from_uv(current_screen_position, depth_texture_probe_raw, inv_proj_m);

		float depth_diff = depth_texture_probe_view_position.z - current_position_view_space.z;

		vec3 ssr_screen_color = textureLod(SCREEN_TEXTURE, current_screen_position.xy, 1.0).rgb;
		resulting_color = (is_within_screen_boundaries(current_screen_position) && depth_diff >= 0.0 && depth_diff < ssr_max_diff) ? ssr_screen_color : vec3(-1.0);
	}

	float alpha = get_screen_border_alpha(current_screen_position);
	return mix(vec4(resulting_color, alpha), vec4(0.0), when_lt(ssr_max_travel, EPSILON));
}

vec2 refraction(float strength, vec2 uv, vec3 normal, vec3 tangent, vec3 binormal) {
	vec3 ref_normal = mix(vec3(0.0, 1.0, 0.0), tangent * normal + binormal * normal + vec3(0.0, 1.0, 0.0)  * normal, 1.0);
	return uv - ref_normal.xy * strength;
}

vec4 ssr(vec2 screen_uv, mat4 inv_proj_matrix, vec4 frag_coord, vec3 normal, vec3 view, mat4 proj_matrix, vec3 tangent, vec3 binormal) {
	vec2 ref_ofs = refraction(0.5, screen_uv, normal, tangent, binormal);

	float surface_depth = frag_coord.z;
	vec3 surface_view_position = get_view_position_from_uv(ref_ofs, surface_depth, inv_proj_matrix);
	vec4 ssr_color = get_ssr_color(surface_view_position, normalize(normal), view, proj_matrix, inv_proj_matrix);

	if (ssr_color.r < 0.05 && ssr_color.g < 0.05 && ssr_color.b < 0.05) {
		return vec4(0.0);
	}

	return ssr_color;
}

vec3 fresnel(vec4 ssr_col, vec3 albedo, vec3 view, vec3 normal) {
	vec3 N = normalize(normal);
	vec3 V = normalize(-view);

	float ndotv = max(dot(N, V), 0.0);
	float fresnel = 0.02 + (1.0 - 0.02) * pow(1.0 - ndotv, 5.0);

	return mix(albedo, ssr_col.rgb, ssr_col.a * fresnel);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	face_normal = NORMAL;
	NORMAL *= MODEL_NORMAL_MATRIX;
	v_tangent_view = (MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz;
    v_binormal_view = (MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz;
}

void fragment() {
	float mask = when_lt(texture(puddle_noise, world_position.xz * puddle_noise_scale).r, puddle_noise_cutoff);
	mask *= mix(when_gt(texture(puddle_uv_mask, UV).r, puddle_uv_mask_cutoff), when_lt(texture(puddle_uv_mask, UV).r, puddle_uv_mask_cutoff), puddle_uv_mask_gt_0_lt_1);
	mask *= when_gt(face_normal.y, 0.95);

	vec3 normal = normalize(vec3(final_ripples().xy + final_wind().xy, 1.0));
	normal = mix(unpack_normal(texture(base_normal, UV).xyz), normal, mask);

	vec3 base_norm_tangent = unpack_normal(texture(base_normal, UV).xyz);
	vec3 final_tangent_normal = mix(base_norm_tangent, normal, mask);

	mat3 tbn_view = mat3(normalize(v_tangent_view), normalize(v_binormal_view), normalize(NORMAL));
	vec3 normal_view_space = normalize(tbn_view * final_tangent_normal);

	vec2 puddle_uv = refraction(0.5, UV, normal, TANGENT, BINORMAL);

	vec4 ssr_col = ssr(SCREEN_UV, INV_PROJECTION_MATRIX, FRAGCOORD, normal_view_space, VIEW, PROJECTION_MATRIX, TANGENT, BINORMAL);
	vec3 puddle_alb = texture(base_albedo, puddle_uv).rgb * 0.6;
	puddle_alb = fresnel(ssr_col, puddle_alb, VIEW, normal);

	float base_aoc_val = texture(base_aoc, mix(UV, puddle_uv, mask)).r;

	ALBEDO = mix(texture(base_albedo, UV).rgb, puddle_alb, mask);
	NORMAL = normal_view_space;
	AO = mix(base_aoc_val, base_aoc_val * 0.5, mask);
	ROUGHNESS = mix(texture(base_roughness, UV).g, 0.0, mask);
	METALLIC = mix(texture(base_metallic, UV).r, 0.0, mask);
	EMISSION = texture(base_emission, mix(UV, puddle_uv, mask)).rgb;
	SPECULAR = mix(texture(base_specular, UV).r, 0.255, mask);
}