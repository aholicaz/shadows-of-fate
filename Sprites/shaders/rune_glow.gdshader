shader_type canvas_item;
render_mode blend_add, unshaded;
uniform bool warm_ink = false;
uniform vec2 uv_origin = vec2(0.0);
uniform vec2 uv_size = vec2(1.0);
uniform float phase = 0.0;
varying vec4 tint;
void vertex() { tint=COLOR; }
void fragment() {
	vec4 source=texture(TEXTURE,UV);
	vec2 local_uv=(UV-uv_origin)/uv_size;
	float contrast=warm_ink ? source.r-source.b : source.b-source.r;
	float mask=smoothstep(0.025,0.16,contrast)*smoothstep(0.12,0.45,max(source.r,source.b));
	float radius=length((local_uv-vec2(0.5,0.3))*vec2(1.0,1.2));
	float flow=0.55+0.45*pow(0.5+0.5*sin(radius*32.0+TIME*1.5+phase),4.0);
	float edge=smoothstep(0.0,0.04,local_uv.x)*smoothstep(0.0,0.04,1.0-local_uv.x)
		*smoothstep(0.0,0.04,local_uv.y)*smoothstep(0.0,0.04,1.0-local_uv.y);
	COLOR=vec4(tint.rgb,mask*flow*edge*tint.a);
}
