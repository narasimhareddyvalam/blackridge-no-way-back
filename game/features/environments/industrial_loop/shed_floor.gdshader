// The transfer shed's floor (docs/PHASE_BRIEF.md, step 5 of #253, part D; #294): a power-trowelled
// warehouse slab in Poly Haven's worn concrete floor (CC0), projected from above on its top and
// from the side on its edges, with what `shed_floor.gd` paints of its wear, read by world position
// over the shed's floor (`map_rect`):
// The normal map is imported as one (its x and y only), so its z is rebuilt from them.
// - sawn joints, filled with grey epoxy, drawn as lines of their true width (`joint_wide`) whose
//   cover is shared over a pixel's footprint, so far off they fade instead of shimmering;
// - grime: dark rubber from tyres and scuffs, and oil, toward a tyre's near-black;
// - gloss: the wheel paths burnished smoother and a little darker;
// - patch: grey epoxy where a joint's edge spalled, near the slab's own shade, smooth and flat;
// - wet: rain blown in at the open doors, as Lagarde's wet surfaces ("Water drop 3b", 2013) darken
//   a porous surface, lerp(1, 0.2, porosity), and lower its roughness toward water's, its small
//   bumps drowned.
shader_type spatial;
render_mode specular_schlick_ggx;

uniform sampler2D floor_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D floor_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D floor_arm : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grime_map : hint_default_black, filter_linear_mipmap_anisotropic;
uniform sampler2D gloss_map : hint_default_black, filter_linear_mipmap_anisotropic;
uniform sampler2D wet_map : hint_default_black, filter_linear_mipmap_anisotropic;
uniform sampler2D patch_map : hint_default_black, filter_linear_mipmap_anisotropic;
uniform vec4 map_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 joint_rect = vec4(0.0);
uniform float joint_x[12];
uniform int joint_x_count = 0;
uniform float joint_z[12];
uniform int joint_z_count = 0;
uniform float joint_wide = 0.006;
uniform float texture_scale = 2.5;
uniform float porosity : hint_range(0.0, 1.0) = 0.5;
uniform float wet_roughness : hint_range(0.0, 1.0) = 0.1;
uniform float burnish : hint_range(0.0, 1.0) = 0.45;
varying vec3 world_position;
varying vec3 world_normal;

const vec3 JOINT_COLOR = vec3(0.17, 0.17, 0.17);
const vec3 RUBBER = vec3(0.035, 0.035, 0.035);
const vec3 PATCH_SHADE = vec3(1.15, 1.15, 1.18);
const float RUBBER_MOST = 0.75;
const float PATCH_ROUGHNESS = 0.42;
const float JOINT_ROUGHNESS = 0.7;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// How much of this pixel the joints cover: each line `joint_wide` across, its cover spread over
// the pixel's footprint `pixel` on the floor.
float joint_cover(vec2 p, float pixel) {
	if (p.x < joint_rect.x || p.y < joint_rect.y || p.x > joint_rect.z || p.y > joint_rect.w) {
		return 0.0;
	}
	float near = 1000.0;
	for (int index = 0; index < joint_x_count; index++) {
		near = min(near, abs(p.x - joint_x[index]));
	}
	for (int index = 0; index < joint_z_count; index++) {
		near = min(near, abs(p.y - joint_z[index]));
	}
	float half_wide = max(joint_wide * 0.5, pixel * 0.5);
	float edge = 1.0 - smoothstep(half_wide - pixel * 0.5, half_wide + pixel * 0.5, near);
	return edge * min(1.0, joint_wide / pixel);
}

void fragment() {
	vec3 n = normalize(world_normal);
	bool top = n.y > 0.5;
	vec2 uv = top ? world_position.xz : (abs(n.x) > abs(n.z) ? world_position.zy
		: world_position.xy);
	uv /= texture_scale;
	vec3 albedo = texture(floor_color, uv).rgb;
	vec3 arm = texture(floor_arm, uv).rgb;
	float roughness = arm.g;
	vec3 bump = vec3(texture(floor_normal, uv).rg * 2.0 - 1.0, 0.0);
	bump.z = sqrt(max(1.0 - dot(bump.xy, bump.xy), 0.0));
	if (top) {
		vec2 map_uv = (world_position.xz - map_rect.xy) / map_rect.zw;
		float grime = texture(grime_map, map_uv).r;
		float gloss = texture(gloss_map, map_uv).r;
		float wet = texture(wet_map, map_uv).r;
		float repair = texture(patch_map, map_uv).r;
		float pixel = max(length(fwidth(world_position.xz)), 0.0001);
		float joint = joint_cover(world_position.xz, pixel);
		repair = smoothstep(0.3, 0.7, repair);
		albedo = mix(albedo, vec3(dot(albedo, vec3(0.333))) * PATCH_SHADE, repair);
		roughness = mix(roughness, PATCH_ROUGHNESS, repair);
		albedo *= 1.0 - 0.12 * gloss;
		roughness = mix(roughness, roughness * (1.0 - burnish), gloss);
		albedo = mix(albedo, RUBBER, min(grime, 1.0) * RUBBER_MOST);
		albedo = mix(albedo, JOINT_COLOR, joint);
		roughness = mix(roughness, JOINT_ROUGHNESS, joint);
		albedo *= mix(1.0, 1.0 - 0.8 * porosity, wet);
		roughness = mix(roughness, wet_roughness, wet);
		bump.xy *= 1.0 - max(max(repair, wet * 0.85), joint);
		bump.z = sqrt(max(1.0 - dot(bump.xy, bump.xy), 0.0));
		vec3 world_bump = normalize(vec3(bump.x, bump.z, -bump.y));
		NORMAL = normalize((VIEW_MATRIX * vec4(world_bump, 0.0)).xyz);
	} else {
		NORMAL_MAP = vec3(bump.xy * 0.5 + 0.5, 1.0);
	}
	ALBEDO = albedo;
	ROUGHNESS = clamp(roughness, 0.02, 1.0);
	METALLIC = 0.0;
	AO = arm.r;
}
