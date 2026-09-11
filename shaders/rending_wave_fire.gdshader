shader_type canvas_item;
render_mode unshaded;

uniform float phase = 0.0;
uniform float fade = 1.0;
varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

void fragment() {
	vec2 p = local_position;
	// Scroll and bend the interior upward/backward, like a breaking wave of liquid fire.
	vec2 flow = vec2(p.x * 0.020 + p.y * 0.010 + phase * 3.4,
		p.y * 0.028 + phase * 5.0);
	float n = noise(flow) * 0.7 + noise(flow * 2.3) * 0.3;
	float t = clamp((p.y + 159.0) / 307.0, 0.0, 1.0);
	float arc = pow(max(0.0, sin(t * 3.14159265)), 0.65);
	float edge = -20.0 + 84.0 * arc + (n - 0.5) * 10.0;
	float behind = edge - p.x;
	float width = (26.0 + 85.0 * t) * arc;
	float ripples = sin(p.y * 0.068 + phase * 9.0 + n * 5.0);
	float back = width + (n - 0.45) * 65.0 * arc + ripples * 12.0 * arc;
	float body_sdf = max(-behind, behind - back);
	body_sdf = max(body_sdf, max(-159.0 - p.y, p.y - 148.0));
	// Curl at the crest. The open left side reads as a wave, rather than a solid blade.
	vec2 curl_p = (p - vec2(-25.0, -108.0)) / vec2(45.0, 46.0);
	float angle = mod(atan(-curl_p.y, curl_p.x) + 6.2831853, 6.2831853);
	float curl_radius = 1.0 - angle * 0.13 + 0.035 * sin(angle * 2.0 + phase * 5.0);
	float curl_width = 9.0 * (1.0 - smoothstep(2.5, 4.8, angle));
	float curl_sdf = abs(length(curl_p) - curl_radius) * 43.0 - curl_width;
	curl_sdf = max(curl_sdf, (angle - 4.8) * 20.0);
	float shape = min(body_sdf, curl_sdf);
	// Long, low trailing surge that skims the ground, with rising fingers of flame.
	float base_t = clamp((p.x + 225.0) / 265.0, 0.0, 1.0);
	float base_y = 143.0 - 9.0 * sin(base_t * 3.14159265);
	float base_width = sin(base_t * 3.14159265) * (9.0 + n * 20.0);
	float base_sdf = abs(p.y - base_y) - base_width;
	base_sdf = max(base_sdf, max(-225.0 - p.x, p.x - 40.0));
	shape = min(shape, base_sdf);
	for (int i = 0; i < 4; i++) {
		float fi = float(i);
		float rise = clamp((146.0 - p.y) / (53.0 + fi * 12.0), 0.0, 1.0);
		float root_x = -148.0 + fi * 39.0;
		float path_x = root_x - 34.0 * rise * rise + sin(rise * 4.0 + phase * 8.0 + fi) * rise * 7.0;
		float finger = abs(p.x - path_x) - (1.0 - rise) * (9.0 + fi * 2.0);
		finger = max(finger, max(146.0 - (53.0 + fi * 12.0) - p.y, p.y - 146.0));
		shape = min(shape, finger);
	}
	float fill = 1.0 - smoothstep(-0.8, 1.5, shape);
	float rim = 1.0 - smoothstep(1.0, 8.0, -shape);
	// Bright cel-like gold with flowing orange channels and small negative spaces.
	float channel = noise(flow + vec2(n * 1.8, 0.0));
	float heat = smoothstep(0.18, 0.52, channel);
	vec3 color = mix(vec3(1.0, 0.25, 0.005), vec3(1.0, 0.86, 0.015), heat);
	color = mix(color, vec3(1.0, 0.98, 0.40), smoothstep(0.58, 0.79, channel));
	color = mix(color, vec3(1.0, 0.40, 0.01), rim * 0.65);
	float hollow = smoothstep(0.73, 0.84, noise(flow * vec2(1.0, 0.58) + 7.0));
	hollow *= smoothstep(16.0, 28.0, behind) * smoothstep(13.0, 26.0, back - behind);
	fill *= 1.0 - hollow;
	float glow = exp(-max(0.0, shape) * 0.16) * 0.23;
	float alpha = max(fill, glow) * fade;
	COLOR = vec4(color, alpha);
}
