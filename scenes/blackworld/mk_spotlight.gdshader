shader_type canvas_item;
uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 0.8;
uniform float softness = 0.16;
uniform float darkness = 0.0;
uniform float aspect = 1.3333;
void fragment() {
	vec2 p = (UV - center) * vec2(aspect, 1.0);
	float mask = smoothstep(radius, radius + max(softness, 0.001), length(p));
	COLOR = vec4(0.0, 0.0, 0.0, mask * darkness);
}
