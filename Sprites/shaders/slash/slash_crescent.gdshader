shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float phase = 0.0;
uniform float arc_span = 1.25;
uniform float arc_width = 1.0;
uniform float sweep_direction = 1.0;
varying vec4 tint;

float hash(float n) { return fract(sin(n * 127.1) * 43758.5453); }
void vertex() { tint = COLOR; }
void fragment() {
	vec2 p = UV - vec2(0.18, 0.5);
	float r = length(p);
	float a = atan(p.y, p.x) * sweep_direction;
	float taper = pow(max(0.0, 1.0 - abs(a) / arc_span), 0.7);
	float radius = 0.34 + 0.008 * sin(a * 3.0 + phase * 5.0);
	float width = (0.0015 + 0.025 * taper) * arc_width;
	float edge = abs(r - radius);
	float core = (1.0 - smoothstep(width * 0.35, width, edge)) * taper;
	float glow = exp(-edge * 55.0) * taper * 0.3;
	float streaks = 0.0;
	for (int i = 0; i < 5; i++) {
		float n = float(i);
		float rr = radius - 0.035 - n * 0.012;
		float gate = smoothstep(-arc_span, -0.4 + n * 0.08, a)
			* (1.0 - smoothstep(0.4 + n * 0.12, arc_span, a));
		streaks += exp(-abs(r - rr) * (650.0 + n * 40.0)) * gate * (0.7 - n * 0.08);
	}
	float sparks = 0.0;
	for (int i = 0; i < 20; i++) {
		float n = float(i);
		float aa = (hash(n + 1.0) * 2.0 - 1.0) * arc_span;
		float age = fract(phase * 0.65 + hash(n + 20.0));
		float rr = 0.35 + age * 0.10;
		vec2 dir = vec2(cos(aa), sin(aa) * sweep_direction);
		vec2 delta = p - dir * rr;
		float along = dot(delta, dir);
		float across = dot(delta, vec2(-dir.y, dir.x));
		sparks += exp(-abs(across) * 1100.0 - abs(along) * 200.0)
			* sin(age * 3.14159) * 0.8;
	}
	float mask = smoothstep(0.0, 0.025, UV.x) * smoothstep(0.0, 0.025, UV.y)
		* smoothstep(0.0, 0.025, 1.0 - UV.y);
	float light = (core + glow + streaks + sparks) * mask;
	COLOR = vec4(vec3(1.0), min(light, 1.0)) * tint;
}
