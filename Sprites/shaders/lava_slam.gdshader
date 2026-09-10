shader_type canvas_item;
render_mode unshaded;
uniform float age = 0.0;
uniform float lifetime = 0.85;
uniform float seed = 0.0;
vec2 hash2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1,311.7)), dot(p, vec2(269.5,183.3)))) * 43758.5453);
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float t = clamp(age / lifetime, 0.0, 1.0);
	float growth = clamp(age / 0.12, 0.001, 1.0);
	float angle = atan(p.y,p.x);
	float rim = 0.87 + 0.065 * sin(angle*13.0+seed) + 0.035*sin(angle*23.0);
	float dist = length(p) / growth;
	float mask = 1.0-smoothstep(rim-0.10,rim,dist);
	vec2 cell = p * vec2(8.0,3.5) + seed;
	vec2 base = floor(cell), f = fract(cell);
	float nearest = 8.0, second = 8.0;
	for(int y=-1;y<=1;y++) for(int x=-1;x<=1;x++) {
		vec2 g=vec2(float(x),float(y));
		vec2 delta=g+hash2(base+g)-f;
		float d=dot(delta,delta);
		if(d<nearest){second=nearest;nearest=d;}else{second=min(second,d);}
	}
	float fissure = 1.0-smoothstep(0.015,0.18,second-nearest);
	float molten = max(fissure, (1.0-smoothstep(0.12,0.48,length(p))) * 0.95);
	float pulse = 0.83+0.17*sin(age*12.0+p.x*11.0+p.y*7.0);
	vec3 basalt=vec3(0.10,0.045,0.023)*(0.8+nearest*0.5);
	vec3 lava=mix(vec3(0.8,0.065,0.002),vec3(1.0,0.66,0.09),pow(molten,3.0))*pulse;
	vec3 color=mix(basalt,lava,molten);
	float shock=exp(-pow((dist-rim+0.04)*50.0,2.0))*max(0.0,1.0-age/0.3);
	color += vec3(1.0,0.6,0.12)*shock;
	COLOR=vec4(color,mask*pow(1.0-t,1.15));
}
