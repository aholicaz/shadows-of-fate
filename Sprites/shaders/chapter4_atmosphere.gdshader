shader_type canvas_item;
render_mode unshaded;
uniform vec4 atmosphere_color : source_color = vec4(0.55,0.77,0.94,1.0);
uniform float mist_strength = 0.10;
uniform float aurora_strength = 0.035;
uniform float wind_speed = 0.12;
uniform float storm_strength = 0.0;
void fragment() {
	vec2 uv = UV;
	float t = TIME;
	float ribbons = pow(max(0.0,sin(uv.x*28.0+sin(uv.y*6.0+t*.10)*1.8)),5.0);
	float aurora = ribbons*(1.0-smoothstep(.04,.5,uv.y))*aurora_strength;
	float fog = exp(-pow((uv.y-.72)/.12,2.0))*(.5+.2*sin(uv.x*40.0-t*wind_speed)+.12*sin(uv.x*77.0+t*.07))*mist_strength;
	// Slow, low-contrast storm illumination, no full-screen flash.
	float storm = pow(.5+.5*sin(t*.7),18.0)*(1.0-smoothstep(.0,.6,uv.y))*storm_strength;
	COLOR = vec4(atmosphere_color.rgb,clamp(aurora+fog+storm,0.0,.16));
}
