shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec4 sample_color = texture(TEXTURE, UV);
	// The supplied train crops have an opaque black background.
	if (max(sample_color.r, max(sample_color.g, sample_color.b)) < 0.004) {
		discard;
	}
	COLOR *= sample_color;
}
