shader_type canvas_item;

// Animate luminous blue runes or orange flame without deforming the stone.
uniform bool warm_light = false;
uniform float cycle_seconds = 3.0;
uniform float preview_phase = -1.0;

void fragment() {
	vec4 source = COLOR;
	float phase = preview_phase >= 0.0 ? preview_phase : TIME / cycle_seconds;
	float pulse = 0.5 - 0.5 * cos(phase * 6.28318530718);
	float peak = max(source.r, max(source.g, source.b));
	float chroma = peak - min(source.r, min(source.g, source.b));
	float hue_mask = warm_light
		? smoothstep(0.18, 0.55, source.r - source.b)
		: smoothstep(0.10, 0.45, source.b - source.r);
	float luminous = hue_mask * smoothstep(0.4, 0.85, peak) * smoothstep(0.12, 0.4, chroma);
	source.rgb *= 1.0 + luminous * (0.05 + 0.30 * pulse);
	COLOR = source;
}
