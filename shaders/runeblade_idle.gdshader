shader_type canvas_item;
uniform sampler2D next_frame : source_color, filter_linear_mipmap;
uniform vec2 current_anchor;
uniform vec2 next_anchor;
uniform float height_ratio = 1.0;
uniform float blend = 0.0;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
    vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
    vec2 next_uv = ((UV * size - current_anchor) * height_ratio + next_anchor) / size;
    vec4 a = texture(TEXTURE, UV);
    vec4 b = texture(next_frame, next_uv);
    float t = smoothstep(0.0, 1.0, blend);
    float alpha = mix(a.a, b.a, t);
    vec3 rgb = mix(a.rgb * a.a, b.rgb * b.a, t) / max(alpha, 0.00001);
    COLOR = vec4(rgb, alpha) * vertex_tint;
}
