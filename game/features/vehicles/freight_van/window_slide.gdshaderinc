uniform bool slides = false;
uniform float lowered = 0.0;
uniform float pane_split = 0.52;
uniform float sill[32];
uniform vec2 sill_span = vec2(0.0, 1.0);

varying vec3 rest_position;
varying float sliding;

float pane_slides(vec3 rest) {
	return slides && rest.z > pane_split ? 1.0 : 0.0;
}

float sill_at(float z) {
	float along = clamp((z - sill_span.x) / max(sill_span.y - sill_span.x, 0.001), 0.0, 1.0)
		* 31.0;
	int below = min(int(floor(along)), 30);
	return mix(sill[below], sill[below + 1], along - float(below));
}

bool below_sill(vec3 rest, float moving) {
	return moving > 0.5 && rest.y - lowered < sill_at(rest.z) - 0.004;
}
