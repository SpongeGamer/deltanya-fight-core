shader_type canvas_item;
uniform float strength : hint_range(0, 1) = 0.0;
uniform float glitch : hint_range(0, 0.5) = 0.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);

    // Глитч — смещение каналов
    if (glitch > 0.0) {
        float r_offset = sin(UV.y * 100.0) * glitch * 0.1;
        float g_offset = cos(UV.y * 120.0) * glitch * 0.1;
        float b_offset = sin(UV.y * 80.0) * glitch * 0.1;

        float r = texture(TEXTURE, UV + vec2(r_offset, 0)).r;
        float g = texture(TEXTURE, UV + vec2(g_offset, 0)).g;
        float b = texture(TEXTURE, UV + vec2(b_offset, 0)).b;
        col = vec4(r, g, b, 1.0);
    }

    // Инверсия
    if (strength > 0.0) {
        col.rgb = mix(col.rgb, 1.0 - col.rgb, strength);
    }

    COLOR = col;
}