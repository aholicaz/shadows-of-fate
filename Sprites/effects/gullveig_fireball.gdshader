shader_type canvas_item;
render_mode unshaded;
uniform vec4 orb_color : source_color = vec4(1.0,0.37,0.025,1.0);
uniform bool orb_style = false;

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
	vec2 p=UV*vec2(2.5,1.0);
	vec2 core=vec2(0.65,0.5);
	float t=TIME*4.0;
	float n=noise(p*12.0-vec2(t*2.0,t*.6));
	float n2=noise(p*25.0-vec2(t*3.0,-t));
	float r=length((p-core)*vec2(1.05,1.0));
	float orb=1.0-smoothstep(.16,.31+(n-.5)*.07,r);
	float tx=clamp((p.x-core.x)/1.6,0.0,1.0);
	float wave=sin(p.x*13.0-t*3.0)*.04*tx;
	float width=(.29*(1.0-tx))*(.65+n*.65);
	float tail=(1.0-smoothstep(width*.35,width,abs(p.y-.5-wave))) * smoothstep(.50,.72,p.x) * (1.0-smoothstep(1.95,2.4,p.x));
	float flame=max(orb,tail*.9);
	float heat=clamp((1.0-r/.30)*1.25,0.0,1.0);
	heat=max(heat,tail*(1.0-tx)*(.35+n2*.4));
	vec3 ember=vec3(.9,.08,.015), orange=vec3(1.0,.37,.025), gold=vec3(1.0,.86,.28), white=vec3(1.0,.98,.80);
	vec3 color=mix(ember,orange,smoothstep(0.0,.35,heat));
	color=mix(color,gold,smoothstep(.25,.75,heat));
	color=mix(color,white,smoothstep(.65,.95,heat));
	if (orb_style) {
		float bands = sin(r*70.0-t*3.0+n*2.0)*0.5+0.5;
		color = mix(orb_color.rgb*0.32,orb_color.rgb,clamp(heat+bands*.3,0.0,1.0));
		color = mix(color,vec3(1.0),pow(heat,3.0)*.85);
	}
	float halo=exp(-r*r*13.0)*.28;
	float alpha=clamp(flame+halo,0.0,1.0);
	alpha*=smoothstep(0.0,.05,UV.x)*(1.0-smoothstep(.94,1.0,UV.x))*smoothstep(0.0,.08,UV.y)*(1.0-smoothstep(.92,1.0,UV.y));
	COLOR=vec4(color,alpha)*COLOR;
}
