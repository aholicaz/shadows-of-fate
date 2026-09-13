shader_type canvas_item;
render_mode unshaded;
uniform vec4 tint : source_color = vec4(.9,.88,.7,.4);
uniform float strength = .045;
void fragment(){
	float mist=exp(-pow((UV.y-.68)/.16,2.0));
	float drift=.55+.18*sin(UV.x*19.0+TIME*.08)+.12*sin(UV.x*43.0-TIME*.05);
	COLOR=vec4(tint.rgb,clamp(mist*drift*strength,0.0,.09));
}
