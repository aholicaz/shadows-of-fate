shader_type canvas_item;
render_mode blend_add, unshaded;
uniform float seed = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	float width = mix(0.12, 0.49, UV.y);
	float x = (UV.x - 0.5) / width;
	float cone = 1.0 - smoothstep(0.35, 1.0, abs(x));
	float rays = 0.68 + 0.16 * sin(x * 21.0 + seed + TIME * 0.10)
		+ 0.10 * sin(x * 47.0 - TIME * 0.07);
	float ends = smoothstep(0.0, 0.09, UV.y) * (1.0 - smoothstep(0.55, 1.0, UV.y));
	vec2 cell = vec2(UV.x * 37.0, UV.y * 65.0 + TIME * 0.22);
	vec2 id = floor(cell);
	float h = fract(sin(dot(id, vec2(127.1, 311.7)) + seed) * 43758.5453);
	float dust = exp(-length((fract(cell) - 0.5) * vec2(16.0, 28.0))) * step(0.94, h);
	COLOR = vec4(vec3(1.0), cone * ends * (rays + dust * 3.0)) * tint;
}
