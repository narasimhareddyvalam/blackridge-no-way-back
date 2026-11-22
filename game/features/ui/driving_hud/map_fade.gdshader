// The mission map's picture faded into the screen at its edges (#356, "Frameless 3D"): its alpha
// falls off over `soft` (a share of its size) toward a rounded rectangle's border, more at the top,
// where it reaches farthest, so no hard frame shows.
shader_type canvas_item;

uniform float soft = 0.16;
uniform float top_soft = 0.22;
uniform float corner = 0.12;
uniform float strength = 0.97;

void fragment() {
	vec4 picture = texture(TEXTURE, UV);
	vec2 from_edge = min(UV, 1.0 - UV);
	float side = smoothstep(0.0, soft, from_edge.x);
	float bottom = smoothstep(0.0, soft * 0.6, 1.0 - UV.y);
	float top = smoothstep(0.0, top_soft, UV.y);
	vec2 inner = clamp(UV, vec2(corner), vec2(1.0 - corner));
	float rounded = 1.0 - smoothstep(corner * 0.4, corner, length((UV - inner) * vec2(1.0, 1.4)));
	COLOR = vec4(picture.rgb, picture.a * side * bottom * top * rounded * strength);
}
