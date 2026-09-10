shader_type canvas_item;
uniform vec2 uv_origin = vec2(0.0);
uniform vec2 uv_size = vec2(1.0);
// 0: water; 1: hanging cloth/foliage; 2: rising heat.
uniform int motion_kind = 0;
uniform float phase = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec2 p = (UV - uv_origin) / uv_size;
	float edge = smoothstep(0.0, 0.12, p.x) * smoothstep(0.0, 0.12, 1.0-p.x)
		* smoothstep(0.0, 0.12, p.y) * smoothstep(0.0, 0.12, 1.0-p.y);
	vec2 offset = vec2(0.0);
	if (motion_kind == 0) {
		offset.x = sin(p.y * 85.0 + TIME * 1.1 + phase) * 0.003 * edge;
	} else if (motion_kind == 1) {
		offset.x = sin(p.y * 5.0 - TIME * 1.4 + phase) * 0.012 * p.y * edge;
	} else {
		offset.x = (sin(p.y * 21.0 - TIME * 2.6 + phase) + sin(p.x * 17.0 + TIME)) * 0.003 * edge;
	}
	vec4 source = texture(TEXTURE, UV + offset * uv_size);
	if (motion_kind == 0) {
		float ripple = pow(max(0.0, sin(p.y * 110.0 + sin(p.x * 12.0 + TIME * 0.5) - TIME * 1.5)), 18.0);
		source.rgb += vec3(0.055, 0.075, 0.085) * ripple * edge;
	}
	COLOR = source * tint;
}
