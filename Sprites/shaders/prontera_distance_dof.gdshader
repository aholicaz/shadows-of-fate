shader_type canvas_item;
uniform float blur_pixels : hint_range(0.0, 4.0) = 1.2;
void fragment() {
	vec2 d = TEXTURE_PIXEL_SIZE * blur_pixels;
	vec4 c = texture(TEXTURE, UV) * 4.0;
	c += texture(TEXTURE, UV + vec2(d.x, 0.0)) * 2.0;
	c += texture(TEXTURE, UV - vec2(d.x, 0.0)) * 2.0;
	c += texture(TEXTURE, UV + vec2(0.0, d.y)) * 2.0;
	c += texture(TEXTURE, UV - vec2(0.0, d.y)) * 2.0;
	c += texture(TEXTURE, UV + d);
	c += texture(TEXTURE, UV - d);
	c += texture(TEXTURE, UV + vec2(d.x, -d.y));
	c += texture(TEXTURE, UV + vec2(-d.x, d.y));
	COLOR = c / 16.0;
}
