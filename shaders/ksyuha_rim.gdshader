shader_type canvas_item;

// Мягкий холодный свет только внутри тёмного края кошки, без белой обводки.
uniform vec4 rim_color : source_color = vec4(0.55, 0.70, 0.78, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.48;
uniform float radius : hint_range(1.0, 24.0) = 12.0;

void fragment() {
    vec4 pixel = texture(TEXTURE, UV) * COLOR;
    vec2 d = TEXTURE_PIXEL_SIZE * radius;
    float near_alpha = min(min(texture(TEXTURE, UV + vec2(d.x, 0.0)).a,
                               texture(TEXTURE, UV - vec2(d.x, 0.0)).a),
                           min(texture(TEXTURE, UV + vec2(0.0, d.y)).a,
                               texture(TEXTURE, UV - vec2(0.0, d.y)).a));
    float edge = (1.0 - near_alpha) * smoothstep(0.05, 0.8, pixel.a);
    float darkness = 1.0 - smoothstep(0.15, 0.65, dot(pixel.rgb, vec3(0.299, 0.587, 0.114)));
    pixel.rgb = mix(pixel.rgb, rim_color.rgb, edge * darkness * strength);
    COLOR = pixel;
}
