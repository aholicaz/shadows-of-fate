shader_type canvas_item;
render_mode blend_add, unshaded;
uniform float seed = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	float height = 1.0 - UV.y;
	float sway = sin(height * 8.0 - TIME * 6.0 + seed) * 0.075 * height
		+ sin(height * 17.0 - TIME * 9.0 + seed) * 0.025;
	float width = mix(0.31, 0.015, pow(height, 0.65));
	float body = 1.0 - smoothstep(width * 0.35, width, abs(UV.x - 0.5 - sway));
	body *= smoothstep(0.0, 0.13, UV.y) * smoothstep(0.0, 0.12, 1.0 - UV.y);
	vec3 flame = mix(vec3(1.0, 0.28, 0.025), vec3(1.0, 0.92, 0.54), body * (1.0 - height * 0.65));
	COLOR = vec4(flame, body * 0.9) * tint;
}
