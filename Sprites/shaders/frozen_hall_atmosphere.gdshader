shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 uv = UV;
	float t = TIME;
	float ribbons = sin(uv.x*32.0 + sin(uv.y*7.0+t*.12)*2.0+t*.08);
	float aurora = pow(max(0.0,ribbons),5.0)*(1.0-smoothstep(.04,.55,uv.y))*.065;
	float mist_band = exp(-pow((uv.y-.78)/.09,2.0));
	float mist = mist_band*(.5+.25*sin(uv.x*39.0-t*.12)+.2*sin(uv.x*73.0+t*.08))*.12;
	float shafts = pow(max(0.0,sin(uv.x*21.0+uv.y*2.4)),36.0);
	shafts *= (1.0-smoothstep(.15,.95,uv.y))*(.07+.02*sin(t*.25));
	vec3 color = mix(vec3(.18,.70,.78),vec3(.65,.84,1.0),clamp((mist+shafts)*8.0,0.0,1.0));
	COLOR = vec4(color,clamp(aurora+mist+shafts,0.0,.20));
}
