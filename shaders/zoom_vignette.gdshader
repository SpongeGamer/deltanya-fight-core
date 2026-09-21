shader_type canvas_item;
uniform float zoom : hint_range(1.0, 3.0) = 1.0;
uniform float vignette : hint_range(0.0, 2.0) = 0.0;
uniform float darkness : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec2 uv = UV - 0.5;
    uv /= zoom;
    uv += 0.5;
    
    // Если вышли за границы — просто чёрный цвет
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        vec4 col = texture(TEXTURE, uv);
        
        // Виньетка
        float vig = 1.0 - length(UV - 0.5) * vignette;
        col.rgb *= clamp(vig, 0.0, 1.0);
        
        // Затемнение
        col.rgb = mix(col.rgb, vec3(0.0), darkness);
        
        COLOR = col;
    }
}