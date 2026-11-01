float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(cell);
	float b = hash(cell + vec2(1.0, 0.0));
	float c = hash(cell + vec2(0.0, 1.0));
	float d = hash(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

vec4 drop_layer(vec2 metres, float cell, float age, vec2 size, float lens, float salt,
		vec2 shape) {
	vec2 grid = metres / cell;
	vec2 id = floor(grid);
	if (hash(id + salt) > age * rain) {
		return vec4(0.0);
	}
	vec2 centre = vec2(hash(id + salt + 3.1), hash(id + salt + 5.7)) * 0.56 + 0.22;
	vec2 local = (fract(grid) - centre) * shape;
	float radius = mix(size.x, size.y, hash(id + salt + 9.3));
	float body = 1.0 - smoothstep(radius * 0.8, radius, length(local));
	return vec4(local / radius, body, lens);
}

float slip(float x, float salt) {
	return x - 0.45 * sin(19.5 * x + salt) / 19.5 - 0.45 * sin(48.4 * x + salt * 1.7) / 48.4;
}

float by_bin(vec4 values, float pick) {
	return pick < 0.45 ? values.x : (pick < 0.75 ? values.y : (pick < 0.92 ? values.z : values.w));
}

vec4 physical_layer(vec2 metres, float cell, float age, vec4 radii, vec4 travel,
		vec4 speeds, float lens, float salt) {
	float column = floor(metres.x / cell);
	float pick = hash(vec2(column, salt + 2.9));
	float pace = mix(0.6, 1.4, hash(vec2(column, salt + 4.4)));
	float stretch = 1.0 + min(abs(by_bin(speeds, pick)) * pace * 8.0, 1.2);
	float moved_by = slip(by_bin(travel, pick) * pace, column * 0.37 + salt);
	vec2 moved = vec2(metres.x, (metres.y - moved_by) * 0.6);
	float radius = by_bin(radii, pick) / cell;
	return drop_layer(moved, cell, age, vec2(radius * 0.9, radius * 1.1), lens, salt,
		vec2(1.0, 1.12 / (0.6 * stretch)));
}

float sky_view(vec4 drop) {
	float edge = 1.0 - 0.6 * smoothstep(0.88, 1.0, length(drop.xy));
	return smoothstep(-0.1, 0.95, -drop.y) * edge * drop.z;
}

vec4 strongest(vec4 a, vec4 b) {
	return b.z > a.z ? b : a;
}

vec4 wet_glass(vec4 drop, float film, float smear, vec2 sheet, vec2 screen_uv,
		vec3 glint_from) {
	float coverage = drop.z;
	vec2 lens = -drop.xy * coverage * drop.w + sheet;
	float blur = mix(film * 1.4 + smear * 1.2, 0.6, coverage);
	vec3 behind = textureLod(scene_color, screen_uv + lens, blur).rgb;
	float rim = smoothstep(0.6, 1.0, length(drop.xy)) * coverage;
	vec3 normal = normalize(vec3(drop.xy, sqrt(max(0.0, 1.0 - dot(drop.xy, drop.xy)))));
	float glint = pow(max(dot(normal, normalize(glint_from)), 0.0), 40.0) * coverage;
	float brightness = dot(behind, vec3(0.2126, 0.7152, 0.0722));
	vec3 colour = behind * (1.0 - rim * 0.4) + behind * glint * 1.5
		+ vec3(glint * brightness * 0.6);
	float alpha = clamp(max(coverage * 0.95, max(film * 0.5, smear * 0.3)), 0.0, 0.96);
	return vec4(colour, alpha);
}
