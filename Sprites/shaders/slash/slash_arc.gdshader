// ★★ รอบ 100 — เอฟเฟกต์ฟันเป็นส่วนโค้ง (พอร์ตจากเชดเดอร์ 3D ที่ผู้ใช้ส่งมา) ★★
//
// ต้นฉบับเป็น `shader_type spatial` (3D) — เกมนี้เป็น 2D จึงพอร์ตเป็น `canvas_item`
// สิ่งที่เปลี่ยนจากต้นฉบับ (เท่าที่จำเป็น · ตรรกะรูปทรงเหมือนเดิมทุกบรรทัด):
//   · render_mode specular_toon,diffuse_toon,cull_disabled  →  blend_add, unshaded
//     (2D ไม่มีแสง/ไม่มีหน้า-หลัง · เกมนี้ไม่มี WorldEnvironment glow เลยใช้ "บวกแสง" ให้เรืองเอง)
//   · ALBEDO + EMISSION  →  รวมเป็น COLOR.rgb ตัวเดียว (2D ไม่มีช่อง emission)
//   · ALPHA              →  COLOR.a
//   · เพิ่ม repeat_enable ให้ผืนที่ถูกเลื่อน/หมุน (ต้นฉบับพึ่งค่า repeat เริ่มต้นของ 3D)
//   · COLOR ขาเข้าคือ modulate ของโหนด → ยังเปลี่ยนสี/ความจางจาก Godot ได้ตามปกติ
//
// ใช้กับ Sprite2D ที่ใส่ผืน quad_white.png (ผืนขาวล้วน มีหน้าที่กำหนดขนาดกับ UV เท่านั้น)
shader_type canvas_item;
render_mode blend_add, unshaded;

group_uniforms ANIMATION;
uniform float progress : hint_range(0.0, 1.0, 0.01) = 0.0;
// ค่านี้คือตัวเล่นแอนิเมชัน เมื่อ derive_progress = 0 (สคริปต์ SlashArcFX เป็นคนป้อนให้)

uniform float derive_progress : hint_range(-1.0, 1.0, 1.0) = 0.0;
// 0.0 = ใช้ progress (โค้ด/AnimationPlayer ป้อนให้)
// -1.0 = ใช้ TIME (วนลูปเอง)
// 1.0 = ใช้ LIFETIME (พาร์ทิเคิล)

uniform float ease_progress : hint_range(-1.0, 1.0, 1.0) = 0.0;
// 0.0 ไม่ผ่อน · -1.0 Expo In · 1.0 Expo Out

uniform float time_scale : hint_range(0.0, 8.0, 0.01) = 1.0;
uniform float anim_rot_amt : hint_range(0.0, 1.0, 0.01) = 1.0;
// เชดเดอร์จะหมุนภาพหลักไปเรื่อย ๆ ตาม progress · ใส่ 0 เพื่อปิด
group_uniforms;

group_uniforms SHAPE;
uniform sampler2D base_noise : hint_default_white, filter_linear_mipmap, repeat_enable;
// รูปทรงหลักที่ดูหยาบ ๆ มาจากผืนนี้ (แกน x = รัศมี · แกน y = มุม)

// สองอันนี้ควรเป็น GradientTexture1D
uniform sampler2D width_gradient_mask : hint_default_transparent, repeat_enable;
// ตัด "ความกว้าง" ของรอยฟัน — ขาว = ตัดทิ้ง · ดำ = เก็บไว้
uniform sampler2D length_gradient_mask : hint_default_transparent, repeat_enable;
// ตัด "ความยาว" และคุมการกวาด — ใช้ไล่สี ขาว -> ดำ -> ขาว
uniform sampler2D highlight : source_color, hint_default_transparent, repeat_enable;
// วางทับรูปทรงหลัก · ถูก LENGTH_GRADIENT_MASK ตัดด้วย จะได้กวาดพร้อมกัน

uniform float zoom : hint_range(0.0, 2.0, 0.01) = 0.6;      // ย่อ/ขยายภาพสุดท้าย (เลขน้อย = ใหญ่)
uniform float rotate_all : hint_range(0.0, 360.0, 0.1) = 0.0; // หมุนภาพสุดท้ายกี่องศา
group_uniforms;

group_uniforms COLORING;
uniform float emission_strength : hint_range(0.0, 4.0, 0.05) = 1.0;
// ความเรืองแสง (2D: คูณความสว่างตรง ๆ แล้วบวกลงฉาก)

uniform float mix_strength : hint_range(0.0, 2.0, 0.01) = 1.0;
// คุมว่า COLOR_LOOKUP ถูกใช้แรงแค่ไหน

uniform sampler2D color_lookup : source_color, hint_default_white, repeat_enable;

// ★ เพิ่มจากต้นฉบับ ★ ตัดขอบผืนกันเห็นเป็นสี่เหลี่ยม (2D ไม่มี mesh มาตัดให้เหมือน 3D)
uniform float edge_fade : hint_range(0.0, 0.5, 0.01) = 0.06;
// ★ เพิ่มจากต้นฉบับ ★ ความนุ่มของขอบรอยฟัน (ดูหมายเหตุ smoothstep ใน fragment)
uniform float soft_edge : hint_range(0.001, 0.3, 0.001) = 0.03;
// ★ เพิ่มจากต้นฉบับ ★ 1 = โชว์ค่ากลาง prefinal เป็นขาวดำ (ไว้ไล่หาปัญหาเวลาภาพไม่ขึ้น)
uniform float debug_view : hint_range(0.0, 1.0, 1.0) = 0.0;

varying float LIFETIME;

vec2 polar_coordinates(vec2 uv, vec2 center, float zoomm, float repeat) {
	vec2 dir = uv - center;
	float radius = length(dir) * 2.0;
	float angle = atan(dir.y, dir.x) * 1.0 / (3.1416 * 2.0);
	return mod(vec2(radius * zoomm, angle * repeat), 1.0);
}

vec2 rotate(vec2 uv, vec2 pivot, float angle) {
	mat2 rotation = mat2(vec2(sin(angle), -cos(angle)),
						vec2(cos(angle), sin(angle)));
	uv -= pivot;
	uv = uv * rotation;
	uv += pivot;
	return uv;
}

// Easing Functions Adapted From https://easings.net/

float easeOutExpo(float x) {
	return 1.0 - pow(2.0, -10.0 * x);
}

float easeInExpo(float x) {
	return pow(2.0, 10.0 * x - 10.0);
}

//Circ
float easeInOut(float x) {
	float result;
	if (x < 0.5) {result = (1.0 - sqrt(1.0 - pow(2.0 * x, 2.0))) / 2.0;}
	else {result = (sqrt(1.0 - pow(-2.0 * x + 2.0, 2.0)) + 1.0) / 2.0;}
	return result;
}

void vertex() {
	// 2D: INSTANCE_CUSTOM มีค่าจริงเฉพาะตอนใช้กับ GPUParticles2D / MultiMesh
	// ใช้กับ Sprite2D ธรรมดาจะเป็น 0 — ซึ่งไม่เป็นไรเพราะเราป้อน progress จากสคริปต์
	LIFETIME = INSTANCE_CUSTOM.y;
}

float get_progress() {
	float p;
	float final;
	if (derive_progress > 0.0) {p = LIFETIME;}
	else if (derive_progress < 0.0) {p = mod(TIME * time_scale, 1.0);}
	else {p = progress;}

	if (ease_progress > 0.0) {final = easeOutExpo(p);}
	else if (ease_progress < 0.0) {final = easeInExpo(p);}
	else {final = p;}

	return final;
}

void fragment() {
	// สีที่ติดมากับโหนด (modulate) — เก็บไว้ก่อนเขียนทับ
	vec3 tint = COLOR.rgb;
	float tint_a = COLOR.a;

	// Get Values
	float p = get_progress();
	vec2 aUV = polar_coordinates(rotate(UV, vec2(0.5), radians(rotate_all)), vec2(0.5), zoom, 1.0);
	vec4 b = texture(base_noise, aUV - vec2(0.0, p));
	vec4 wm = texture(width_gradient_mask, aUV);
	vec4 lm = texture(length_gradient_mask, rotate(aUV - vec2(0.0, easeInOut(p * anim_rot_amt)), vec2(0.5), radians(180.0)));

	// Combine Them
	vec4 prefinal = (b - wm) - lm;
	vec3 albe = vec3(1.0) * (texture(color_lookup, vec2(clamp(prefinal.r * UV.x, 0.0, 1.0), 0.0)).rgb * mix_strength);
	vec4 high = clamp(texture(highlight, aUV) - (lm), 0.0, 1.0);

	// Apply Them — 3D ใช้ ALBEDO + EMISSION แยกกัน · 2D รวมเป็นสีเดียวแล้วบวกลงฉาก
	vec3 rgb = clamp(albe + high.rgb, 0.0, 1.0);
	// 3D คูณ 3 แล้วให้ tonemap/glow ของ 3D จัดการต่อ · 2D บวกลงฉากตรง ๆ ถ้าคูณ 4 จะขาวโพลน
	COLOR.rgb = rgb * (0.7 + 1.3 * emission_strength) * tint;

	// ★★ ต้นฉบับเขียน smoothstep(start, end, x) โดยที่ start == end เป๊ะ ★★
	// GLSL: edge0 == edge1 คือหารศูนย์ = undefined — การ์ดจอบางตัวคืน NaN แล้วภาพหายทั้งใบ
	// (เจอจริงตอนเทสต์: ไม่ขึ้นอะไรเลยสักพิกเซล) จึงใส่ช่องไฟ soft_edge ให้ขอบนุ่มแทน
	// ผลลัพธ์เท่าเดิม (ตัดที่ระดับ thr เหมือนกัน) แต่ขอบไม่หยักและไม่พังบนการ์ดจอไหนเลย
	float thr = abs(cos(p * PI));
	// ★ ช่องไฟต้องอยู่ "ข้างบน" ของเกณฑ์เท่านั้น (thr → thr+se) ★
	// ถ้าคร่อมสองข้าง (thr-se → thr+se) ตอน thr = 0 ค่า 0 จะตกกลางช่องพอดี = ได้ 0.5
	// → ทั้งผืนจะจางเป็นสี่เหลี่ยมเทา (เจอจริงตอนเทสต์ที่ progress = 0.5)
	float se = max(soft_edge, 0.001);
	float a = clamp(smoothstep(thr, thr + se, prefinal.r)
		+ smoothstep(clamp(thr, 0.0, 0.2), clamp(thr, 0.0, 0.2) + se, (high.r * 0.2)), 0.0, 1.0);

	// จางขอบผืนกันเห็นเป็นกรอบสี่เหลี่ยม
	if (edge_fade > 0.0) {
		vec2 ef = smoothstep(vec2(0.0), vec2(edge_fade), UV) * smoothstep(vec2(0.0), vec2(edge_fade), vec2(1.0) - UV);
		a *= ef.x * ef.y;
	}

	COLOR.a = tint_a * a;

	if (debug_view > 0.5) {
		COLOR.rgb = vec3(clamp(prefinal.r, 0.0, 1.0), clamp(wm.r, 0.0, 1.0), clamp(lm.r, 0.0, 1.0));
		COLOR.a = 1.0;
	}
}
