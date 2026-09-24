shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 sunlight : source_color = vec4(1.0, 0.88, 0.57, 0.28);
uniform float phase = 0.0;

void fragment() {
	float sway = sin(TIME * 0.22 + phase + UV.y * 1.6) * 0.018;
	float x = UV.x + sway;
	float broad = exp(-pow((x - 0.48) / 0.25, 2.0));
	float ribbons = 0.48 + 0.30 * pow(sin(x * 19.0 + phase), 2.0)
		+ 0.22 * pow(sin(x * 37.0 - TIME * 0.12), 2.0);
	float ends = smoothstep(0.0, 0.16, UV.y) * (1.0 - smoothstep(0.60, 1.0, UV.y));
	float breath = 0.90 + 0.10 * sin(TIME * 0.35 + phase);
	COLOR = vec4(sunlight.rgb, sunlight.a * broad * ribbons * ends * breath);
}
