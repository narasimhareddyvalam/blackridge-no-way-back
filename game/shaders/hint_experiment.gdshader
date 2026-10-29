shader_type spatial;
render_mode unshaded;

// Same image, read in two different ways
uniform sampler2D color_read : source_color, filter_nearest;
uniform sampler2D data_read : filter_nearest;

// Switch between the two results
uniform bool show_data = false;

void fragment() {
	vec3 as_color = texture(color_read, UV).rgb;
	vec3 as_data = texture(data_read, UV).rgb;

	ALBEDO = show_data ? as_data : as_color;
}
