shader_type canvas_item;
render_mode unshaded;
uniform float seed = 0.0;
varying vec4 tint;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { tint=COLOR; }
void fragment() {
	vec2 p=UV*vec2(4.0,2.0)+vec2(TIME*0.08+seed,-TIME*0.05);
	float cloud=noise(p)*0.6+noise(p*2.1)*0.28+noise(p*4.2)*0.12;
	float edge=pow(sin(UV.x*3.14159)*sin(UV.y*3.14159),0.8);
	COLOR=vec4(tint.rgb, smoothstep(0.3,0.8,cloud)*edge*tint.a);
}
