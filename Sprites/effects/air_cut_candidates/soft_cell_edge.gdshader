shader_type canvas_item;

// Fade each atlas cell's margin, preserving the source artwork and alpha.
void fragment() {
	vec2 cell_uv = fract(UV * vec2(4.0, 2.0));
	vec2 edge = min(cell_uv, vec2(1.0) - cell_uv);
	float fade = smoothstep(0.005, 0.065, min(edge.x, edge.y));
	COLOR *= texture(TEXTURE, UV);
	COLOR.a *= fade;
}
