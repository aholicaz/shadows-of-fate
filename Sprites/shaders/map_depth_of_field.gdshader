shader_type canvas_item;

// A light Gaussian approximation for the far parallax artwork only.
uniform float blur_radius : hint_range(0.0, 0.004) = 0.0012;

void fragment() {
	vec2 d = vec2(blur_radius, blur_radius);
	vec4 sum = texture(TEXTURE, UV) * 0.36;
	sum += texture(TEXTURE, UV + vec2(d.x, 0.0)) * 0.12;
	sum += texture(TEXTURE, UV - vec2(d.x, 0.0)) * 0.12;
	sum += texture(TEXTURE, UV + vec2(0.0, d.y)) * 0.12;
	sum += texture(TEXTURE, UV - vec2(0.0, d.y)) * 0.12;
	sum += texture(TEXTURE, UV + vec2(d.x, d.y)) * 0.04;
	sum += texture(TEXTURE, UV + vec2(d.x, -d.y)) * 0.04;
	sum += texture(TEXTURE, UV + vec2(-d.x, d.y)) * 0.04;
	sum += texture(TEXTURE, UV - d) * 0.04;
	COLOR = sum * COLOR;
}
