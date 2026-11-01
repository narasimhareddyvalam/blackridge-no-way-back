shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D pattern : source_color, filter_linear, repeat_disable;
uniform mat4 lamp_left = mat4(1.0);
uniform mat4 lamp_right = mat4(1.0);
uniform float beams : hint_range(0.0, 1.0) = 1.0;
uniform float reach = 120.0;
uniform float tan_half = 0.7002;
uniform float glow = 10.0;
uniform float fall_speed = 7.5;
uniform float slant = 0.0;
uniform float density : hint_range(0.0, 1.0) = 0.75;
uniform vec3 tint : source_color = vec3(0.92, 0.9, 0.84);
uniform sampler2D oncoming_pattern : source_color, filter_linear, repeat_disable;
uniform mat4 oncoming_left = mat4(1.0);
uniform mat4 oncoming_right = mat4(1.0);
uniform float oncoming = 0.0;
uniform float oncoming_reach = 120.0;
instance uniform float seed = 0.0;

const float COLUMN = 0.045;
const float SPACING = 0.85;
const float STREAK = 0.32;
const float THICKNESS = 0.0012;

varying vec3 world_position;
varying float across;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float lamp_light(sampler2D beam, mat4 lamp, vec3 point, float range) {
	vec3 local = (lamp * vec4(point, 1.0)).xyz;
	float ahead = -local.z;
	if (ahead < 0.1) {
		return 0.0;
	}
	vec2 spread = local.xy / (ahead * tan_half);
	vec2 uv = vec2(0.5 + 0.5 * spread.x, 0.5 - 0.5 * spread.y);
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
		return 0.0;
	}
	float distance_to_lamp = length(local);
	float fade = 1.0 - smoothstep(range * 0.6, range, distance_to_lamp);
	return texture(beam, uv).r * fade / max(distance_to_lamp, 1.0);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	across = VERTEX.x;
}

void fragment() {
	float light = (lamp_light(pattern, lamp_left, world_position, reach)
		+ lamp_light(pattern, lamp_right, world_position, reach)) * beams;
	if (oncoming > 0.0) {
		light += (lamp_light(oncoming_pattern, oncoming_left, world_position, oncoming_reach)
			+ lamp_light(oncoming_pattern, oncoming_right, world_position, oncoming_reach))
			* oncoming;
	}
	if (light < 0.0005) {
		discard;
	}
	float x = across + world_position.y * slant;
	float column = floor(x / COLUMN);
	float pace = mix(0.85, 1.2, hash(vec2(column, seed + 3.1)));
	float fallen = world_position.y + TIME * fall_speed * pace + hash(vec2(column, seed)) * SPACING;
	float row = floor(fallen / SPACING);
	float present = step(hash(vec2(column + row * 17.0, seed + 7.7)), density);
	float offset = (hash(vec2(column, row + seed * 3.0)) - 0.5) * COLUMN * 0.7;
	float width = max(THICKNESS, fwidth(x) * 0.75);
	float side = (fract(x / COLUMN) - 0.5) * COLUMN - offset;
	float along = fract(fallen / SPACING) * SPACING;
	float body = smoothstep(0.0, 0.03, along) * (1.0 - smoothstep(STREAK * 0.6, STREAK, along));
	float streak = exp(-(side * side) / (width * width)) * body * present * sqrt(THICKNESS / width);
	float size = mix(0.4, 1.0, hash(vec2(row, column + seed)));
	float far = smoothstep(10.0, 30.0, distance(world_position, CAMERA_POSITION_WORLD));
	ALBEDO = tint * light * glow * streak * size * mix(1.0, 0.35, far);
}
