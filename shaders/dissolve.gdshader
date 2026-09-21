shader_type canvas_item;

uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(0.0, 1.0, 1.0, 1.0); // циановый как у персонажа
uniform float edge_width : hint_range(0.0, 0.1) = 0.02;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    
    // Простой noise через sin/cos без внешней текстуры
    vec2 uv = UV * 10.0;
    float noise = fract(sin(dot(uv, vec2(127.1, 311.7))) * 43758.5453);
    
    if (noise < dissolve_amount) {
        discard;
    } else if (noise < dissolve_amount + edge_width) {
        COLOR = edge_color;
        COLOR.a = tex.a;
    } else {
        COLOR = tex;
    }
}