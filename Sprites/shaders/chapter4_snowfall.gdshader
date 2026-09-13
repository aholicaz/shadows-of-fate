shader_type canvas_item;
render_mode unshaded;
varying float world_y;
void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).y;
}
void fragment() {
	COLOR *= texture(TEXTURE,UV);
	COLOR.a *= 1.0-smoothstep(850.0,900.0,world_y);
}
