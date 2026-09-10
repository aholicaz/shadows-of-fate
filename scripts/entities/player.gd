## Player — ตัวละครผู้เล่น
##
## โครงสร้าง Scene ที่ต้องมี:
##   Player (CharacterBody2D)  <- ใส่สคริปต์นี้
##   ├── AnimatedSprite2D      (อนิเมชัน: Idle, Run, Attack, Hit, Death, Jump)
##   └── CollisionShape2D
##
## ค่าพลังทั้งหมดดึงจาก PlayerState ไม่ต้องแก้ในไฟล์นี้
extends CharacterBody2D

const JUMP_VELOCITY := -420.0
const KNOCKBACK_DECAY := 900.0

# =========================================================
# ★★ พุ่งหลบ (Dash) — รอบ 29 ★★
#
# ปุ่มเดิมของ "กระโดด" (W / Space / ลูกศรขึ้น / ปุ่มบนจอมือถือ) เปลี่ยนมาเป็น
# ★ พุ่งไปข้างหน้าเพื่อหลบการโจมตี ★
#
#   · พุ่งไปทางที่กดค้างอยู่ (ไม่ได้กดทิศ = พุ่งไปทางที่หันหน้า)
#   · ระหว่างพุ่งมี "ช่วงอมตะ" สั้น ๆ โดนตีไม่เข้า ขึ้นคำว่า "หลบ!" แทนดาเมจ
#   · ระหว่างพุ่งไม่ตกลงพื้น (ลอยตรง) พุ่งข้ามหลุมได้
#   · มีคูลดาวน์ กันกดรัว
#
# อยากได้ "กระโดด" กลับมาด้วย เปิดช่อง Can Jump ในกลุ่ม "การกระโดด" ได้เลย
# (ใช้ปุ่มเดียวกัน ถ้าเปิดทั้งคู่ ปุ่มจะเป็นพุ่งหลบก่อน)
# =========================================================
@export_group("พุ่งหลบ (Dash)")
## เปิด/ปิดการพุ่งหลบ
@export var dodge_enabled: bool = true
## พุ่งไปไกลกี่พิกเซล
@export var dodge_distance: float = 260.0
## ความเร็วตอนพุ่ง (พิกเซล/วินาที) — เวลาที่ใช้พุ่ง = ระยะ ÷ ความเร็ว
@export var dodge_speed: float = 1100.0
## ★ ช่วงอมตะ ★ กี่วินาทีนับจากเริ่มพุ่ง (0 = ไม่มีช่วงอมตะ พุ่งเฉย ๆ)
@export_range(0.0, 1.0) var dodge_invincible: float = 0.28
## รอกี่วินาทีถึงพุ่งได้อีก (นับหลังพุ่งจบ)
@export_range(0.0, 3.0) var dodge_cooldown: float = 0.55
## เสีย SP ต่อการพุ่ง 1 ครั้ง (0 = ฟรี)
@export_range(0, 50) var dodge_sp_cost: int = 0
## ชนกำแพงแล้วหยุดพุ่งทันที
@export var dodge_stop_on_wall: bool = true
## ★ ชื่อท่าตอนพุ่ง ★ ไม่มีท่านี้ในชุดภาพ จะยืม "เฟรมลอยกลางอากาศ" ของท่ากระโดดมาใช้ให้
@export var dodge_anim: StringName = &"Dash"

# =========================================================
# ★★ การกระโดด (รอบ 27 · ปรับซ้ำรอบ 28 · ปิดไว้ตั้งแต่รอบ 29) ★★
#
# ท่ากระโดด 6 เฟรมของโปรเจกต์นี้แบ่งเป็น 3 ช่วง:
#   เฟรม 0-2 = ย่อตัวถีบพื้น (บนพื้น) · เฟรม 3-4 = ลอยกลางอากาศ · เฟรม 5 = ลงพื้น
# ระบบเลยเล่นแยกช่วง ไม่เอาทั้งชีทไปผูกกับความเร็วรวดเดียว (ไม่งั้นเฟรมเดินถอยหลัง)
# บอกช่วงได้ที่ช่อง Jump Takeoff Frames / Jump Land Frames
#
# ★ ตอนนี้ปุ่มกระโดดถูกเปลี่ยนไปเป็น "พุ่งหลบ" แล้ว ★ ค่ากลุ่มนี้ยังใช้ได้ถ้าเปิด Can Jump
# และเฟรม "ลอยกลางอากาศ" ยังถูกยืมไปใช้เป็นท่าพุ่งหลบด้วย
# =========================================================
@export_group("การกระโดด")
## ★ ปิดการกระโดดไว้ (รอบ 29 เปลี่ยนปุ่มไปเป็นพุ่งหลบแทน) ★
## เปิดกลับได้ถ้าอยากให้มีทั้งกระโดดและพุ่งหลบ — แต่ใช้ปุ่มเดียวกัน พุ่งหลบจะมาก่อน
@export var can_jump: bool = false
## แรงกระโดด (ยิ่งมากยิ่งสูง)
@export var jump_power: float = 420.0
## ★ ตกเร็วกว่าตอนพุ่งขึ้นกี่เท่า ★ 1.0 = เท่ากัน (ลอยนาน), 1.3-1.6 = กระโดดหนึบ ตกไว
@export_range(1.0, 3.0) var fall_gravity_mult: float = 1.35
## ★ ปล่อยปุ่มกลางอากาศ = กระโดดเตี้ยลง ★ (0.45 = ตัดแรงขึ้นเหลือ 45%)
@export_range(0.0, 1.0) var jump_cut_mult: float = 0.45
## ★ เดินตกขอบแล้วยังกดกระโดดทันได้กี่วินาที ★ (coyote time — ทำให้รู้สึก "ไม่หลุด")
@export_range(0.0, 0.4) var coyote_time: float = 0.10
## ★ กดกระโดดก่อนแตะพื้นกี่วินาที ระบบจะจำไว้ให้ ★ (ทำให้กระโดดต่อเนื่องลื่น)
@export_range(0.0, 0.4) var jump_buffer_time: float = 0.12
## ★ ให้เฟรมท่ากระโดดเดินตามฟิสิกส์จริง ★ (แก้อาการเฟรมไม่เชื่อมกัน)
@export var jump_anim_follow_physics: bool = true
## ★ เฟรมแรก ๆ ที่เป็นช่วง "ย่อตัวถีบพื้น" มีกี่เฟรม ★ (ของชุดนี้ = 3 · ไม่มีให้ใส่ 0)
@export_range(0, 8) var jump_takeoff_frames: int = 3
## เล่นช่วงย่อตัวให้จบภายในกี่วินาที (สั้น ๆ พอ ไม่งั้นจะเห็นย่อตัวกลางอากาศ)
@export_range(0.02, 0.5) var jump_takeoff_time: float = 0.12
## ★ เฟรมท้าย ๆ ที่เป็นช่วง "ลงพื้น" มีกี่เฟรม ★ (ของชุดนี้ = 1 · ไม่มีให้ใส่ 0)
@export_range(0, 8) var jump_land_frames: int = 1
## ค้างท่าลงพื้นไว้กี่วินาทีก่อนกลับไปยืน/วิ่ง (0 = ตัดทันทีแบบเดิม)
@export_range(0.0, 0.5) var land_time: float = 0.14

@export_group("ท่าโดนตี")
## ★ ล็อกท่าโดนตีไว้กี่วินาที ★ 0 = คิดจากจำนวนเฟรมของท่านั้นให้อัตโนมัติ
@export_range(0.0, 1.0) var hit_anim_time: float = 0.0
## ท่าโดนตีนานสุดเท่าไหร่ (กันสไปรท์ที่ตั้ง FPS ช้ามากจนค้าง)
@export_range(0.1, 1.5) var hit_anim_max: float = 0.6

## สไปรท์ต้นฉบับหันหน้าไปทางซ้ายหรือเปล่า (ตามที่ทำไว้เดิม = จริง)
@export var sprite_faces_left: bool = true
## ★ ระยะโจมตีปกติ ★ วัดจาก "กลางตัวเรา" ไปถึง "ขอบตัวมอน" (ไม่ใช่กลางตัวมอน)
## มอนตัวใหญ่อย่างบอสเลยตีโดนตั้งแต่ขอบตัว ไม่ต้องเดินไปประชิดกลางตัว
@export var attack_range_x: float = 150.0
## ดาบเอื้อมขึ้นไปเหนือปลายเท้าได้สูงเท่าไหร่ (ครอบทั้งตัวขึ้นไปบนหัว)
@export var attack_range_y: float = 200.0
## ★ เอื้อมไปข้างหลังได้เท่าไหร่ ★ สำหรับตัวที่ยืนทับ/เราเหยียบอยู่ ให้ฟันโดนด้วย
@export var attack_back_reach: float = 55.0
## ★ ฟันต่ำกว่าปลายเท้าลงไปได้เท่าไหร่ ★ สำหรับตัวที่เราเหยียบหัวอยู่
@export var attack_reach_down: float = 40.0
## จังหวะที่ดาบฟันโดน (วินาทีหลังเริ่มอนิเมชัน)
@export var attack_windup: float = 0.15

# ---------- ★ รอบ 81 — ท่าฟันไวตาม ASPD ★ ----------
## เปิด/ปิดการเร่งอนิเมชันท่าโจมตีตามความเร็วโจมตี (ASPD)
## ปิด = ท่าฟันเล่นความเร็วเดิมเสมอ (ASPD สูง ๆ จะเห็นตัวละครค้างรอ)
@export var attack_anim_follow_aspd: bool = true
## ให้ท่าฟันจบภายในกี่ % ของช่วงเวลาระหว่างการตี 1 ครั้ง
## 0.9 = ฟันจบแล้วเหลือช่องว่างนิดเดียวก่อนตีครั้งถัดไป (ดูลื่น ไม่ค้าง)
@export_range(0.5, 1.0, 0.01) var attack_anim_fit: float = 0.9
## เร่งได้มากสุดกี่เท่า (กันภาพกระตุกจนดูไม่ออกตอน ASPD สูงมาก)
@export_range(1.0, 12.0, 0.1) var attack_anim_max_speed: float = 8.0
## ★ รอบ 97 ★ ASPD ต่ำ: ยอมให้ท่าฟัน "ช้าลง" ได้ถึงเท่านี้เพื่อเติมช่วงตีให้เต็ม (1.0 = ไม่ยอมช้ากว่าปกติ)
## ค่า 0.7 = ท่ายืดได้ถึง ~1.4 เท่าของความยาวปกติ · ช่วงตีที่ยาวกว่านั้นจะกลับท่ายืนรอ (ขาดช่วงตามธรรมชาติ)
@export_range(0.2, 1.0, 0.05) var attack_anim_min_speed: float = 0.7
## ★ รอบ 97 ★ ท่าโจมตีเล่น "ครั้งเดียว" เสมอ — ชีทเก่าบางท่า (Attack_Blade_bash / Katana / falchion) ตั้ง loop ไว้
## ทำให้ ASPD ต่ำแล้วท่าวนซ้ำเองระหว่างรอคูลดาวน์ · เปิดไว้ = ปิด loop ให้ตอนเล่น (ไม่แก้ไฟล์)
@export var attack_anim_no_loop: bool = true

# ---------- ★★ รอบ 93 — ฟัน 3 จังหวะ (คอมโบโจมตีปกติ) ★★ ----------
## คลิกแต่ละครั้งเปลี่ยนท่าไปเรื่อย ๆ 1 → 2 → 3 แล้ววนกลับ · จังหวะสุดท้ายแรงขึ้น
@export_group("Combo (ฟัน 3 จังหวะ)")
@export var combo_enabled: bool = true
## ต้องคลิกครั้งถัดไปภายในกี่วินาที "หลังท่าก่อนหน้าจบ" ถึงจะนับต่อ — เกินนี้กลับไปจังหวะ 1
@export_range(0.1, 3.0, 0.05) var combo_window: float = 0.7
## คลิกซ้ำระหว่างที่ยังฟันอยู่ = จำไว้แล้วต่อจังหวะถัดไปทันทีที่ท่าจบ (คอมโบไหลลื่น ไม่ต้องจับจังหวะเป๊ะ)
@export var combo_buffer_input: bool = true
## ★ รอบ 95 ★ คลิกก่อนถึง % นี้ของท่า จะไม่ถูกจำไว้
## กันคลิกรัว/ดับเบิลคลิกตอนเริ่มท่า ไปสั่งฟันต่อโดยที่ผู้เล่นไม่ได้ตั้งใจ
@export_range(0.0, 0.9, 0.05) var combo_buffer_from: float = 0.35
## ★ รอบ 95 ★ จบจังหวะสุดท้ายแล้ว ให้วนกลับไปจังหวะ 1 เองจากคลิกที่จำไว้ไหม
## ปิดไว้ = ครบ 3 ไม้แล้วหยุด ต้องกดใหม่ถึงจะเริ่มคอมโบรอบต่อไป (ไม่มีไม้ที่ 4 โผล่มาเอง)
@export var combo_wrap_from_buffer: bool = false

## ★★ รอบ 96 ★★ กดปุ่มโจมตี "ค้างไว้" = ฟันต่อเนื่องเอง ไม่ต้องคลิกทีละครั้ง
## คลิกทีละครั้งยังใช้ได้เหมือนเดิมทุกอย่าง · คอมโบยังวน 1→2→3→1 ตามปกติ
## ปิด = ต้องกด/คลิกทีละครั้งแบบก่อนรอบ 96
@export var attack_hold_repeat: bool = true
## ตัวคูณดาเมจของแต่ละจังหวะ (จำนวนช่อง = จำนวนจังหวะ) — ค่าเริ่มต้น จังหวะ 3 แรงขึ้น 25%
@export var combo_damage_mults: PackedFloat32Array = [1.0, 1.0, 1.25]
## ท่าของแต่ละจังหวะ = ท่าโจมตีของอาวุธ + คำต่อท้ายนี้ (เช่น Attack_Blade + "_2" = Attack_Blade_2)
## ★ วาดท่าใหม่แล้วตั้งชื่อตามนี้ ระบบจะหยิบไปใช้เอง ★  ช่องแรกว่าง = ท่าพื้นฐาน
@export var combo_anim_suffixes: PackedStringArray = ["", "_2", "_3"]
## ถ้ายังไม่มีท่าตามชื่อข้างบน ให้ยืมท่าไหนแทน (คั่นด้วย , ลองตามลำดับ) — ยืมท่าสกิลไปก่อนจนกว่าจะวาด
@export var combo_fallback_suffixes: PackedStringArray = ["", "_slash,_bash", "_bash,_slash"]
## เอฟเฟกต์ดาบของจังหวะสุดท้ายใหญ่ขึ้นกี่เท่า (1.0 = เท่าเดิม)
@export_range(1.0, 2.0, 0.05) var combo_finisher_fx_scale: float = 1.25

## ★★ รอบ 94 ★★ ดาเมจออกตอน "ดาบฟาดถึง" ของแต่ละท่า ไม่ใช่เวลาคงที่
##
## เดิมใช้ Attack Windup 0.15 วิ เท่ากันทุกท่า — แต่ท่าคอมโบยาวไม่เท่ากันและจังหวะฟาดคนละที่
## วัดจากภาพจริงของท่าชุดใหม่: ดาบฟาดถึงราวเฟรม 57-83% ของท่า แต่ดาเมจออกตั้งแต่ ~15%
## = ตีโดนตั้งแต่ดาบยังไม่เหวี่ยง ("จังหวะดาเมจแปลก ๆ")
##
## เปิดไว้ = หาเฟรมที่ "ปลายดาบยื่นไปข้างหน้าไกลสุด" เองจากภาพ (วาดท่าใหม่ก็ยังตรงเอง)
@export var attack_hit_auto: bool = true
## ใส่เลขเฟรมเองต่อจังหวะ (−1 = ให้ระบบหาเอง) · เว้นว่าง = ให้ระบบหาเองทุกจังหวะ
@export var combo_hit_frames: PackedInt32Array = PackedInt32Array()
## ★ รอบ 95 ★ ดาเมจต้องออกไม่เกินกี่ % ของท่า
## บางท่าดาบยื่นไปเรื่อย ๆ จนเฟรมสุดท้าย ระบบจะเลือกเฟรมท้าย = "ฟันไปแล้วดาเมจค่อยตามมา"
@export_range(0.2, 1.0, 0.05) var attack_hit_max_fraction: float = 0.6
@export_group("")

## ★ รอบ 94 ★ ให้ทุกท่ามี "ลำตัว" สูงเท่ากันบนจอ โดยยึดขนาดจากท่าอ้างอิง
## ปิด = กลับไปคิดสเกลจากความสูงรวม (รวมดาบที่ชูขึ้น) แบบก่อนรอบ 94
@export var fit_uniform_body: bool = true
## ท่าที่ใช้เป็นตัวตั้งขนาด (ปกติคือท่ายืน) — ขนาดตัวละครโดยรวมจะเท่ากับท่านี้เสมอ
## ★ ระบบจะไล่ตามลำดับท่าสำรองเหมือนตอนเล่นจริง ★ ถือดาบอยู่ก็ใช้ Idle_blade เป็นตัวตั้งให้เอง
@export var fit_reference_anim: StringName = &"Idle"
## เพดานกันพัง: แก้ขนาดได้มากสุดกี่เท่าจากสเกลเดิม (2.5 = กว้างมาก)
## ★ ไม่ใช่ปุ่มปรับความสวย ★ มีไว้กันกรณีวัดลำตัวเพี้ยนจนสเกลพุ่งผิดปกติเท่านั้น
## ตั้งกว้างไว้เพราะท่าที่ "วาดมาคนละสเกล" ต้องแก้ได้เป็นเท่าตัวจริง ๆ
## ถ้าท่าไหนไม่อยากให้ระบบยุ่ง ให้ใส่ชื่อใน Fit Uniform Body Skip แทน
@export_range(1.0, 4.0, 0.05) var fit_body_max_adjust: float = 2.5
## ท่าที่ไม่ต้องจัดขนาดให้เท่าท่ายืน (ใช้สเกลแบบเดิม) — ใส่ชื่อท่า เทียบแบบไม่สนตัวพิมพ์
## ท่าพุ่ง (Dash) ตัวเอนไปข้างหน้าเกือบนอน ลำตัวจึงวัดได้สั้นผิดปกติ ปล่อยให้ใช้ค่าเดิมดีกว่า
@export var fit_uniform_body_skip: PackedStringArray = ["Dash"]

## จังหวะที่จะฟัน "ครั้งถัดไป" (0 = จังหวะ 1) · เวลาที่คอมโบจะหมดอายุ · คลิกที่จำไว้
## ★ รอบ 94 ★ ความสูงลำตัวเป้าหมายบนจอ (คิดครั้งเดียวจากท่าอ้างอิง)
var _body_target: float = 0.0
## ชื่อท่าที่ใช้คิด _body_target ไว้ (ว่าง = ยังไม่ได้คิด) — เปลี่ยนอาวุธแล้วค่านี้จะไม่ตรง = คิดใหม่
var _body_target_anim: String = ""

var combo_step: int = 0
var _combo_expire_ms: int = 0
var _combo_queued: bool = false
## เวลาที่เริ่มฟันไม้ปัจจุบัน + ความยาวไม้นั้น (วินาที) — ใช้ดูว่าคลิกมาตอนกี่ % ของท่า
var _attack_started_ms: int = 0
var _attack_span: float = 0.0
## ★ รอบ 100 ★ วินาทีที่ "ดาเมจจะออก" ของไม้ที่กำลังฟันอยู่ (คิดรวม ASPD แล้ว)
## รอยฟันแบบเชดเดอร์ใช้ค่านี้เป็นจุดที่ภาพสว่างสุด — เก็บไว้ให้เทสต์/ดีบักตรวจได้ด้วย
var _attack_windup: float = 0.0
## ★ รอบ 97 ★ เลขลำดับการฟัน — coroutine ของไม้เก่าที่ยังรอ timer อยู่ ต้องไม่มายุ่งกับไม้ใหม่
var _attack_seq: int = 0
## ไม้ที่ยังไม่ได้ "ปิดจังหวะ" (_combo_finish_step) — ถ้าไม้ใหม่เริ่มก่อน ให้ปิดไม้เก่าให้ก่อน
var _attack_open_step: int = -1
## ส่งทุกครั้งที่เริ่มฟันจังหวะใหม่ (step เริ่มที่ 0 · anim = ชื่อท่าที่เล่นจริง · mult = ตัวคูณดาเมจ)
signal combo_step_started(step: int, anim: String, mult: float)
## ระยะที่เก็บไอเทมได้ (แนวนอน) — วัดจาก "ปลายเท้า" ไม่ใช่จุดกำเนิด
@export var pickup_range: float = 90.0
## ระยะที่เก็บไอเทมได้ (แนวตั้ง) เผื่อของตกอยู่ต่างระดับเล็กน้อย
@export var pickup_range_y: float = 90.0

# =========================================================
# ปรับขนาดตัวละครอัตโนมัติ
# ใช้ตอนไฟล์ภาพแต่ละท่าขนาดไม่เท่ากัน (เช่น Idle 300x300 แต่ Run 50x90)
# ระบบจะย่อ/ขยายให้ตัวละคร "สูงเท่ากันบนจอ" เสมอ และจัดเท้าให้อยู่ระดับพื้น
# =========================================================
@export_group("ขนาดตัวละคร")
## ★ อยากให้ตัวละครสูงกี่พิกเซลบนจอ ★ (0 = ปิดระบบนี้ ใช้ค่า Scale ที่ตั้งใน Scene แทน)
@export var auto_fit_height: float = 240.0:
	set(value):
		auto_fit_height = value
		_fit_cache.clear()
		_body_target = 0.0
		_collision_synced = false
## จัดเท้าให้อยู่ระดับล่างของกล่องชนเสมอ
@export var auto_fit_align_feet: bool = true
## ปรับขนาดกล่องชนตาม Auto Fit Height ให้อัตโนมัติ (จะได้แก้ตัวเลขเดียวจบ)
@export var auto_fit_collision: bool = true
## ความกว้างของกล่องชน เทียบกับความสูง (0.16 = ผอม, 0.25 = อ้วน)
@export_range(0.08, 0.45) var collision_width_ratio: float = 0.17

# =========================================================
# ★ ท่าตัวละคร — แยกตามอาวุธที่ถือ และแยกตามสกิล ★
#
# ★★ ทุกท่าใช้กฎเดียวกัน ★★  ท่าไหนก็ได้ ไม่ใช่แค่ท่าโจมตี
#   ท่า + "_" + ชื่ออาวุธ   ->  ถ้ามีจะใช้อันนี้ก่อนเสมอ
#
#   ถือ falchion:  Idle_falchion · Run_falchion · Jump_falchion
#                  Attack_falchion · Attack_falchion_bash · Hit_falchion · Death_falchion
#   ไม่มีท่าไหน ก็ถอยไปใช้ท่าธรรมดา (Idle / Run / Attack ...) ให้เอง
#
# "ชื่ออาวุธ" มาจากช่อง Attack Animation ของไอเทม ("Attack_Falchion" -> "Falchion")
# ถ้าไม่ได้ตั้งไว้ จะใช้ id ของไอเทมแทน (falchion -> "falchion")
# ตัวพิมพ์เล็ก-ใหญ่ไม่สำคัญ (Attack_Falchion = attack_falchion)
#
# ทำอาวุธใหม่ = วาดเฉพาะท่าที่อยากให้เปลี่ยน ไม่ต้องวาดครบทุกท่า
# ไม่ต้องแก้โค้ดเลย
# =========================================================
# =========================================================
# ★ เอฟเฟกต์รอยฟันตอนโจมตีปกติ (รอบ 44) ★
# ภาพเสี้ยวแสงโผล่ข้างหน้าตัวละครทุกครั้งที่ตี สลับ "ฟันลง" / "ฟันสวนขึ้น"
# ไม่ทำดาเมจเอง (ดาเมจยังคิดจากกรอบ Attack Range เหมือนเดิม) — แค่ภาพ
# ว่างไว้ = ใช้ res://data/sprites/fx_attack.tres อัตโนมัติ · อยากปิดให้ติ๊ก Attack Effect Enabled ออก
# =========================================================
@export_group("เอฟเฟกต์โจมตีปกติ")
@export var attack_effect_enabled: bool = true
@export var attack_effect_frames: SpriteFrames
## ชื่อท่าที่จะสลับกันเล่น (ว่าง = ทุกท่าในไฟล์) — ท่าที่ 2, 4, ... จะถูกพลิกแนวตั้ง (ฟันสวนขึ้น)
@export var attack_effect_anims: Array[StringName] = [&"slash", &"slash2"]
## จุดเกิดเทียบกับตัวละคร (x = ข้างหน้า)
@export var attack_effect_offset: Vector2 = Vector2(78, -28)
## ความสูงของภาพบนจอ (0 = ใช้ Scale)
@export var attack_effect_height: float = 230.0
@export var attack_effect_scale: float = 1.0
## โผล่หลังกดตีกี่วิ (ให้ตรงจังหวะดาบเหวี่ยง)
## ★★ รอบ 100 — รอยฟันแบบเชดเดอร์ (ส่วนโค้งเรืองแสง) ★★
## เปิด = ใช้เชดเดอร์ · ปิด = กลับไปใช้เอฟเฟกต์ชีทภาพเดิมทุกประการ
@export var slash_shader_enabled: bool = true
## เปิดพร้อมกับเอฟเฟกต์ชีทภาพเดิมด้วยไหม (ปิดไว้ = ใช้เชดเดอร์อย่างเดียว ไม่ซ้อนกันมั่ว)
@export var slash_shader_replaces_sprite: bool = true
## ขนาดรอยฟันบนจอ (px) · ตำแหน่งเทียบตัวละคร
@export var slash_size: float = 300.0
@export var slash_offset: Vector2 = Vector2(76, -30)
## ★ องศาการวางส่วนโค้งของแต่ละไม้ ★ (ไม้ 1 ฟันลง · ไม้ 2 สวนขึ้น · ไม้ 3 ฟันลงเต็มแรง)
@export var slash_rotations: PackedFloat32Array = PackedFloat32Array([205.0, 25.0, 195.0])
## ตัวคูณขนาดของแต่ละไม้
## (ไม้สุดท้ายไม่ต้องใส่ตัวคูณเพิ่ม — ได้ combo_finisher_fx_scale คูณให้อยู่แล้ว ไม่งั้นใหญ่เกิน)
@export var slash_step_scales: PackedFloat32Array = PackedFloat32Array([1.0, 0.95, 1.0])
## ความเรืองแสงของแต่ละไม้
@export var slash_step_emission: PackedFloat32Array = PackedFloat32Array([1.0, 1.0, 1.5])
## ตารางสีของแต่ละไม้ (ว่าง = ใช้ฟ้าเริ่มต้น · ไม้สุดท้ายใช้โทนไฟ)
@export var slash_color_ramps: Array[Texture2D] = []
## เวลาที่รอยฟัน "จางหาย" หลังดาเมจออก (วินาที) — หารด้วยความเร็วท่าตาม ASPD เหมือนกัน
@export_range(0.04, 0.6, 0.01) var slash_tail: float = 0.16
## ย่อ/ขยายส่วนโค้ง (เลขน้อย = โค้งใหญ่)
@export_range(0.2, 1.5, 0.01) var slash_zoom: float = 0.6

## ★★ รอบ 101 — รอยฟันแบบ "ภาพชุด Alternative 3" (ลำแสงพุ่งไปข้างหน้า) ★★
##
## รอบ 100 ใช้เชดเดอร์วาดส่วนโค้งรอบตัว = ดูเป็นวงกลม ทิศไม่ตรงกับดาบ
## รอบนี้เปลี่ยนมาใช้ภาพชุดที่เป็น "ลำแสงเส้นตรง" แล้วหมุนให้ตรงทิศดาบของแต่ละไม้
## เปิด = ใช้ภาพชุด · ปิด = ถอยไปใช้เชดเดอร์รอบ 100 (ถ้า slash_shader_enabled ยังเปิดอยู่)
@export var slash_sheet_enabled: bool = true
## ★ ใช้ภาพชุดไหนของแต่ละไม้ ★ (1-5 · ชุด 1-3 เป็นวงโค้ง · ชุด 4-5 เป็นลำแสงเส้นตรง)
## ★ รอบ 101 รอบสอง — ผู้ใช้เลือกเอง: ไม้ 1 = ชุด 5 · ไม้ 2 = ชุด 2 ย้อนเฟรม · ไม้ 3 = ชุด 4 ★
@export var slash_sheet_sets: PackedInt32Array = PackedInt32Array([5, 2, 4])
## ★ เล่นเฟรมจากท้ายมาหน้าไหม ★ (1 = ย้อน · 0 = ปกติ)
## ชุด 2 ไล่ปกติคือวงโค้ง "หุบเข้า" · ย้อนแล้วเป็น "กางออก" ตามดาบที่เหวี่ยง
@export var slash_sheet_reversed: PackedInt32Array = PackedInt32Array([0, 1, 0])
## ★ หมุนภาพยังไง ★ องศาบนจอตอนหันขวา
## · ชุด 4-5 (ลำแสงเส้นตรง) = "ลำแสงชี้ไปทางมุมนี้" (0 = นอนราบ · บวก = ก้มลง · ลบ = เชิดขึ้น)
## · ชุด 1-3 (วงโค้ง) = "หมุนเพิ่มจากภาพต้นฉบับกี่องศา" (0 = ใช้ตามที่วาดมา)
##   เพราะวงโค้งพวกนี้หมุนเปลี่ยนทิศไปเรื่อย ๆ ระหว่างเฟรมอยู่แล้ว ไม่มีมุมประจำตัว
@export var slash_sheet_aims: PackedFloat32Array = PackedFloat32Array([45.0, 0.0, 55.0])
## ขนาดลำแสงบนจอของแต่ละไม้ (px)
@export var slash_sheet_sizes: PackedFloat32Array = PackedFloat32Array([250.0, 300.0, 340.0])
## จุดเกิดเทียบตัวละคร (x = ข้างหน้า) ของแต่ละไม้ — ว่าง = ใช้ slash_offset
@export var slash_sheet_offsets: Array[Vector2] = [
	Vector2(86.0, -22.0), Vector2(70.0, -40.0), Vector2(116.0, 2.0)
]
## ★ พุ่งออกไปข้างหน้ากี่ px หลังดาเมจออก ★ (0 = อยู่กับที่) — นี่คือสิ่งที่ทำให้ "ไม่วนรอบตัว"
@export var slash_sheet_travel: float = 34.0
## สีคูณของแต่ละไม้ (ว่าง = ขาว = สีไฟตามภาพต้นฉบับ)
@export var slash_sheet_tints: PackedColorArray = PackedColorArray()
## บวกแสงลงฉาก (เรืองแสง) หรือวาดทับปกติ
@export var slash_sheet_additive: bool = true

## ★★ รอบ 103 — สมุดเอฟเฟกต์ผู้เล่น (PlayerFXBook) ★★
##
## ที่เดียวที่คุมเอฟเฟกต์ของทุกท่า: Attack 1/2/3 · Magnum Break · Slash · Bash · บัฟต่าง ๆ
## เปิดไฟล์ `data/sprites/player_fx.tres` แล้วเลือกท่าจากดรอปดาวน์ในหน้าต่าง Inspector
##
## · ท่าไหน "ใช้ค่าจากสมุดนี้" ไม่ติ๊ก → ท่านั้นใช้ค่าเดิมของมันเหมือนเดิมทุกประการ
##   (ไม้ 1-3 ใช้ช่อง slash_sheet_* ข้างบน · สกิลใช้ค่าใน .tres ของตัวเอง)
## · เว้นช่องนี้ว่าง = ไม่ใช้สมุดเลย เกมทำงานเหมือนก่อนรอบ 103 ทุกอย่าง
@export var fx_book: PlayerFXBook

@export var attack_effect_delay: float = 0.06
@export var attack_effect_z: int = 40
const ATTACK_FX_PATH := "res://data/sprites/fx_attack.tres"
var _attack_fx_turn := 0

@export_group("ท่าโจมตี")
## ชื่อท่าตอนมือเปล่า
@export var unarmed_attack_anim: StringName = &"Attack"
## รูปแบบชื่อท่าตามชนิดอาวุธ ({type} = weapon_type ของอาวุธ)
@export var weapon_attack_anim_format: String = "Attack_{type}"
## ★ รอบ 97 ★ ท่าโจมตี "ตัวแทนของชนิดอาวุธ" — อาวุธที่ยังไม่มีท่าของตัวเอง (เช่น rapier / claymore / flame_sword)
## จะยืมท่านี้แทนที่จะตกไปท่ามือเปล่า (ต่อย) · ตั้งเป็น {ชนิดอาวุธ: ชื่อท่า}
@export var weapon_type_default_attack: Dictionary = {"sword": "Attack_Blade"}
## ★ รูปแบบชื่อท่าสกิลที่แยกตามอาวุธ ★
## {attack} = ชื่อท่าโจมตีของอาวุธที่ถืออยู่ · {skill} = id ของสกิล
## เช่น ถือดาบมือใหม่ (Attack_Blade) ใช้สกิล bash -> "Attack_Blade_bash"
@export var skill_weapon_anim_format: String = "{attack}_{skill}"
## รูปแบบชื่อท่าสกิลกลาง (ใช้ตอนอาวุธชิ้นนั้นยังไม่มีท่าเฉพาะ)
@export var skill_anim_format: String = "Attack_{skill}"

# =========================================================
# ★ ปุ่มเมาส์ ★
#   คลิกซ้าย = โจมตีปกติ (เหมือนกดปุ่มโจมตี)
#   คลิกขวา  = ใช้สกิลช่องลัดที่ตั้งไว้ (ปกติคือช่อง 1)
# คลิกโดนหน้าต่าง/ปุ่มบนจอ จะไม่ทำให้ตัวละครโจมตี (UI กินคลิกไปก่อนแล้ว)
# =========================================================
@export_group("ปุ่มเมาส์")
## คลิกซ้าย = โจมตีปกติ
@export var mouse_attack: bool = true
## คลิกขวา = ใช้สกิลช่องลัดนี้ (1-4) · ใส่ 0 = ปิด
@export_range(0, 4) var mouse_skill_slot: int = 1
## คลิกแล้วให้ตัวละครหันไปทางที่คลิกก่อนฟัน
@export var mouse_turns_facing: bool = true

var _fit_cache: Dictionary = {}
var _collision_synced := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var facing: int = 1              # 1 = ขวา, -1 = ซ้าย
var is_attacking := false
var attack_cooldown := 0.0
var knockback := Vector2.ZERO
var _hurt_flash := 0.0
var _dead := false

# ★ สถานะการกระโดด ★
var _coyote := 0.0          # เดินตกขอบแล้วยังกระโดดทันได้อีกกี่วินาที
var _jump_buffer := 0.0     # กดกระโดดค้างไว้รอแตะพื้น
var _jump_rising := false   # กำลังพุ่งขึ้นอยู่ (ใช้ตัดแรงตอนปล่อยปุ่ม)
var _was_on_floor := true
var _land_left := 0.0       # เหลือเวลาค้างท่าลงพื้น
var _jump_anim := ""        # ชื่อท่ากระโดดที่กำลังเล่นอยู่จริง
var _air_time := 0.0        # ลอยอยู่กลางอากาศมากี่วินาทีแล้ว
var _jump_kick := false     # ★ ลอยเพราะ "กดกระโดด" ★ (ไม่ใช่เดินตกขอบ) = ต้องเล่นท่าย่อตัว

# ★ สถานะพุ่งหลบ ★
var _dodge_time := 0.0      # เหลือเวลาพุ่งอีกกี่วินาที (0 = ไม่ได้พุ่งอยู่)
var _dodge_cd := 0.0        # รออีกกี่วินาทีถึงพุ่งได้ใหม่
var _iframe := 0.0          # ★ ช่วงอมตะ ★ เหลืออีกกี่วินาที
# ★ สถานะท่าโดนตี ★ ล็อกไว้ไม่ให้ Idle/Run มาทับก่อนเล่นจบ
var _hit_left := 0.0

# ★ สถานะตอนพุ่ง (สกิล ACTIVE_DASH เช่น Slash) ★
var _dash_time := 0.0          # เหลือเวลาพุ่งอีกกี่วินาที
var _dash_speed := 0.0
var _dash_range_x := 110.0
var _dash_range_y := 90.0
var _dash_mult := 1.0
var _dash_use_matk := false
var _dash_max_targets := 0
var _dash_stop_on_wall := true
var _dash_hits: Array = []     # มอนที่โดนไปแล้วในการพุ่งครั้งนี้

# ★★ รอบ 56 — ตาข่ายกันตกแมพ ★★
# ถ้าหลุดออกไปใต้แมพ (พุ่งข้ามหน้าผา · ทะลุพื้น · ตำแหน่งเพี้ยน) จะถูกพากลับ
# ที่ยืนล่าสุดที่ปลอดภัยแทนที่จะร่วงไปเรื่อย ๆ จนต้องปิดเกม
var _safe_pos: Vector2 = Vector2.ZERO      # ที่ยืนล่าสุดที่ปลอดภัย
var _safe_timer := 0.0
var _rescue_cd := 0.0

# คลิกเมาส์ที่รับมาแล้วรอให้ _handle_input() เอาไปใช้ในเฟรมถัดไป
var _click_attack := false
var _click_skill := false
## ★ รอบ 96 ★ ปุ่มซ้ายยังถูกกดค้างอยู่ไหม (เริ่มกดนอกพื้นที่ UI)
var _click_attack_held := false
var _click_pos := Vector2.ZERO


func _ready() -> void:
	add_to_group("player")
	Events.player_died.connect(_on_died)
	Events.level_up.connect(_on_level_up)
	Events.job_level_up.connect(_on_job_level_up)
	_dead = PlayerState.is_dead()


# =========================================================
# PHYSICS
# =========================================================
func _physics_process(delta: float) -> void:
	if _dead:
		velocity.x = move_toward(velocity.x, 0.0, KNOCKBACK_DECAY * delta)
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if _hurt_flash > 0.0:
		_hurt_flash -= delta
		if _hurt_flash <= 0.0:
			sprite.modulate = Color.WHITE

	_tick_jump_timers(delta)
	_track_safe_ground(delta)

	if _dodge_cd > 0.0:
		_dodge_cd -= delta
	if _iframe > 0.0:
		_iframe -= delta

	# ★ กำลังพุ่งหลบอยู่ ★ ทำแค่พุ่งอย่างเดียว ไม่รับคำสั่งอื่น
	if _dodge_time > 0.0:
		_dodge_step(delta)
		return

	# แรงกระเด็น
	if knockback.length() > 1.0:
		knockback = knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)

	# ★ แรงโน้มถ่วง ★ ตอนตกใช้แรงมากกว่าตอนพุ่งขึ้น = กระโดดหนึบ ไม่ลอยค้าง
	if not is_on_floor():
		var g := get_gravity()
		if velocity.y > 0.0:
			g *= fall_gravity_mult
		velocity += g * delta
		# ปล่อยปุ่มกลางอากาศตอนยังพุ่งขึ้น = ตัดแรงให้กระโดดเตี้ยลง (คุมความสูงได้)
		if _jump_rising and velocity.y < 0.0 and not _jump_held():
			velocity.y *= jump_cut_mult
			_jump_rising = false
		elif velocity.y >= 0.0:
			_jump_rising = false

	_handle_input()

	# ★ กำลังพุ่งอยู่ ★ เดินหน้าต่อแล้วฟันทุกตัวที่ขวางทาง
	if _dash_time > 0.0:
		_dash_step(delta)
		return

	if is_attacking:
		velocity.x = knockback.x
		move_and_slide()
		return

	# ★★ พุ่งหลบ ★★ — ปุ่มเดิมของกระโดด (W / Space / ลูกศรขึ้น / ปุ่มบนจอ)
	if dodge_enabled and _jump_buffer > 0.0 and _dodge_cd <= 0.0:
		_start_dodge()
		return

	# ★ กระโดด ★ — ปิดไว้เป็นค่าเริ่มต้น (เปิดที่ช่อง Can Jump)
	# ใช้ทั้ง coyote time (เพิ่งตกขอบก็ยังกระโดดได้) และ buffer (กดก่อนถึงพื้นก็จำไว้ให้)
	if can_jump and _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = -absf(jump_power)
		_jump_buffer = 0.0
		_coyote = 0.0
		_jump_rising = true
		_land_left = 0.0
		_jump_anim = ""
		_air_time = 0.0
		_jump_kick = true   # กระโดดเอง = ต้องเล่นท่าย่อตัวถีบพื้นก่อน

	# เดิน — A / D (หรือลูกศรซ้าย-ขวา)
	var speed := PlayerState.stats.move_speed
	var direction := Input.get_axis("move_left", "move_right")
	if direction == 0.0:
		direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0.0:
		velocity.x = direction * speed + knockback.x
		facing = 1 if direction > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, knockback.x, speed)

	_update_facing()
	_update_animation()
	move_and_slide()


func _process(_delta: float) -> void:
	_apply_auto_fit()


# =========================================================
# ★★ ตัวจับเวลาของการกระโดด ★★
# =========================================================
func _tick_jump_timers(delta: float) -> void:
	var on_floor := is_on_floor()

	# เพิ่งแตะพื้นเฟรมนี้ = เริ่มนับเวลาค้างท่าลงพื้น
	if on_floor and not _was_on_floor:
		_land_left = land_time
		_jump_rising = false
		_jump_kick = false
		# ปลดล็อกท่ากระโดดที่หยุดเฟรมไว้ ให้ท่าถัดไปเล่นต่อได้ปกติ
		if _jump_anim != "" and land_time <= 0.0:
			_jump_anim = ""
	elif not on_floor and _was_on_floor:
		# เพิ่งลอยขึ้น (กระโดด หรือเดินตกขอบ)
		_land_left = 0.0
	_was_on_floor = on_floor

	# นับเวลาที่ลอยอยู่ ใช้กะจังหวะเฟรมช่วงย่อตัวถีบพื้น
	if on_floor:
		_air_time = 0.0
	else:
		_air_time += delta

	if on_floor:
		_coyote = coyote_time
	else:
		_coyote = maxf(0.0, _coyote - delta)

	var pressed := Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept")
	if not pressed and InputMap.has_action("move_up"):
		pressed = Input.is_action_just_pressed("move_up")
	if pressed:
		_jump_buffer = jump_buffer_time
	else:
		_jump_buffer = maxf(0.0, _jump_buffer - delta)

	if _land_left > 0.0:
		_land_left -= delta
		if _land_left <= 0.0:
			_jump_anim = ""
	if _hit_left > 0.0:
		_hit_left -= delta


# =========================================================
# ★★ พุ่งหลบ (Dash) ★★
# =========================================================
## พุ่งได้ตอนนี้ไหม (ใช้เช็คก่อนโชว์คูลดาวน์บนปุ่มก็ได้)
func can_dodge() -> bool:
	if not dodge_enabled or _dead or is_attacking or _dodge_time > 0.0 or _dodge_cd > 0.0:
		return false
	return dodge_sp_cost <= 0 or PlayerState.stats.sp >= dodge_sp_cost


## กำลังอมตะอยู่ไหม (ระหว่างพุ่งหลบ) — มอนตีมาก็ไม่เข้า
func is_invincible() -> bool:
	return _iframe > 0.0


func is_dodging() -> bool:
	return _dodge_time > 0.0


func _start_dodge() -> void:
	if not can_dodge():
		_jump_buffer = 0.0
		return

	# ทิศที่พุ่ง: ตามปุ่มที่กดค้างอยู่ · ไม่ได้กดทิศ = พุ่งไปทางที่หันหน้า
	var dir := Input.get_axis("move_left", "move_right")
	if dir == 0.0:
		dir = Input.get_axis("ui_left", "ui_right")
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
		_update_facing()

	if dodge_sp_cost > 0:
		PlayerState.spend_sp(dodge_sp_cost)

	_dodge_time = dodge_distance / maxf(50.0, dodge_speed)
	_dodge_cd = _dodge_time + dodge_cooldown
	_iframe = dodge_invincible
	_jump_buffer = 0.0
	_hit_left = 0.0
	_land_left = 0.0
	_jump_anim = ""
	knockback = Vector2.ZERO
	velocity.y = 0.0
	_play_dodge()


func _dodge_step(delta: float) -> void:
	_dodge_time -= delta
	velocity.x = facing * dodge_speed
	velocity.y = 0.0          # ลอยตรง ไม่ตกระหว่างพุ่ง (ข้ามหลุมได้)
	move_and_slide()

	if dodge_stop_on_wall and is_on_wall():
		_dodge_time = 0.0
	if _dodge_time <= 0.0:
		_dodge_time = 0.0
		velocity.x = 0.0


## ท่าตอนพุ่ง — มีท่า Dash ก็ใช้เลย ไม่มีก็ยืม "เฟรมลอยกลางอากาศ" ของท่ากระโดด
func _play_dodge() -> void:
	if sprite.sprite_frames == null:
		return
	if _has_anim(String(dodge_anim)):
		var real := _play(String(dodge_anim))
		if real != "":
			sprite.frame = 0
			sprite.play(real)
		return

	# ไม่มีท่า Dash — ยืมเฟรมลอยของท่ากระโดดมาค้างไว้ (ท่าตัวพุ่งไปข้างหน้าพอดี)
	var jump_real := _play("Jump")
	if jump_real == "":
		return
	_jump_anim = jump_real
	var count := sprite.sprite_frames.get_frame_count(jump_real)
	if count <= 1:
		return
	if sprite.is_playing():
		sprite.pause()
	sprite.frame = _jump_frame_ranges(count)[1]   # เฟรมแรกของช่วง "ลอย"


## ยังกดปุ่มกระโดดค้างอยู่ไหม (ใช้ตัดสินว่าจะกระโดดสูงหรือเตี้ย)
func _jump_held() -> bool:
	if Input.is_action_pressed("jump") or Input.is_action_pressed("ui_accept"):
		return true
	return InputMap.has_action("move_up") and Input.is_action_pressed("move_up")


## ★ ตำแหน่งในจังหวะกระโดด ★ 0 = พุ่งขึ้นสุด · 0.5 = จุดสูงสุด · 1 = กำลังตกเต็มที่
func _jump_progress() -> float:
	var span: float = maxf(80.0, absf(jump_power))
	return clampf((velocity.y + span) / (span * 2.0), 0.0, 1.0)


## ★ แบ่งเฟรมท่ากระโดดเป็น 3 ช่วง ★ คืน [จำนวนเฟรมย่อตัว, เฟรมลอยแรก, เฟรมลอยสุดท้าย]
func _jump_frame_ranges(count: int) -> Array:
	var takeoff: int = clampi(jump_takeoff_frames, 0, maxi(0, count - 2))
	var land: int = clampi(jump_land_frames, 0, maxi(0, count - takeoff - 1))
	var air_first: int = takeoff
	var air_last: int = maxi(air_first, count - 1 - land)
	return [takeoff, air_first, air_last]


## เล่นท่ากระโดดโดยเลือกเฟรมเอง — ย่อตัวถีบพื้น -> ลอย (ตามความเร็วจริง)
func _play_jump() -> void:
	if _jump_anim == "" or sprite.animation != StringName(_jump_anim):
		_jump_anim = _play("Jump")
	if _jump_anim == "":
		return
	if not jump_anim_follow_physics:
		return
	var count := sprite.sprite_frames.get_frame_count(_jump_anim)
	if count <= 1:
		return
	if sprite.is_playing():
		sprite.pause()

	var r := _jump_frame_ranges(count)
	var takeoff: int = r[0]
	var air_first: int = r[1]
	var air_last: int = r[2]

	# ---------- ★ ช่วงย่อตัวถีบพื้น ★ ----------
	# เล่นรวดเดียวตอนเพิ่งกดกระโดด · เดินตกขอบเฉย ๆ ไม่ต้องเล่น (ไม่ได้ถีบพื้น)
	if _jump_kick and takeoff > 0 and _air_time < jump_takeoff_time:
		var t: float = _air_time / maxf(0.01, jump_takeoff_time)
		sprite.frame = clampi(int(t * takeoff), 0, takeoff - 1)
		return

	# ---------- ★ ช่วงลอยกลางอากาศ ★ ----------
	# 0 = พุ่งขึ้นสุด · 0.5 = จุดสูงสุด · 1 = ตกเต็มที่
	var span: int = air_last - air_first
	if span <= 0:
		sprite.frame = air_first
		return
	sprite.frame = air_first + clampi(int(round(_jump_progress() * span)), 0, span)


## ★ ช่วงลงพื้น ★ ไล่เฟรมท้าย ๆ ของท่ากระโดดให้จบพอดีกับเวลา land_time
func _play_land_frames() -> void:
	if _jump_anim == "" or sprite.sprite_frames == null:
		return
	var count := sprite.sprite_frames.get_frame_count(_jump_anim)
	if count <= 1:
		return
	if sprite.is_playing():
		sprite.pause()
	var air_last: int = _jump_frame_ranges(count)[2]
	if air_last >= count - 1:
		sprite.frame = count - 1     # ไม่ได้แยกเฟรมลงพื้นไว้ ก็ค้างเฟรมสุดท้าย
		return
	var first: int = air_last + 1
	var t: float = 1.0 - clampf(_land_left / maxf(0.01, land_time), 0.0, 1.0)
	sprite.frame = clampi(first + int(t * (count - first)), first, count - 1)


## ความยาวของอนิเมชันนั้นเป็นวินาที (นับ frame duration ของ Godot 4 ด้วย)
func _anim_length(real: String) -> float:
	var frames := sprite.sprite_frames
	if frames == null or real == "" or not frames.has_animation(real):
		return 0.0
	var fps: float = maxf(0.1, frames.get_animation_speed(real))
	var total := 0.0
	for i in range(frames.get_frame_count(real)):
		total += frames.get_frame_duration(real, i)
	return total / fps


## ท่านี้เป็น "ท่าโดนตี" จริงหรือแค่ตัวสำรอง (Idle) ที่ไหลมาตามลำดับ fallback
static func _is_hit_anim(real: String) -> bool:
	var t := real.to_lower()
	return t.begins_with("hit") or t.contains("hurt") or t.contains("damage")


# =========================================================
# ★ คลิกเมาส์ ★
# ใช้ _unhandled_input เพราะถ้าคลิกโดนหน้าต่าง/ปุ่มบนจอ
# ตัว UI จะกินคลิกนั้นไปก่อน คลิกจะไม่ไหลมาถึงตรงนี้ = ไม่เผลอฟันลม
# =========================================================
func _unhandled_input(event: InputEvent) -> void:
	if _dead or get_tree().paused:
		return
	var mb := event as InputEventMouseButton
	# ★ รอบ 96 ★ ปล่อยปุ่มซ้าย = เลิกฟันต่อเนื่อง
	if mb != null and not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_click_attack_held = false
		return
	if mb == null or not mb.pressed or mb.is_echo():
		return
	# คลิกทับหน้าต่าง/แผงบนจอ = ไม่นับเป็นการโจมตี
	if UI != null and UI.is_point_over_ui(mb.position):
		return

	if mouse_attack and mb.button_index == MOUSE_BUTTON_LEFT:
		_click_attack = true
		_click_attack_held = true
	elif mouse_skill_slot > 0 and mb.button_index == MOUSE_BUTTON_RIGHT:
		_click_skill = true
	else:
		return

	# แปลงจุดที่คลิกบนจอ -> พิกัดในโลก (เผื่อกล้องเลื่อนอยู่)
	_click_pos = get_viewport().get_canvas_transform().affine_inverse() * mb.position
	get_viewport().set_input_as_handled()


## หันหน้าไปทางที่คลิก (ถ้าเปิดใช้)
func _face_click() -> void:
	if not mouse_turns_facing:
		return
	var dx := _click_pos.x - global_position.x
	if absf(dx) < 8.0:
		return
	facing = 1 if dx > 0.0 else -1
	_update_facing()


func _handle_input() -> void:
	# ---------- รับคลิกเมาส์ที่ค้างไว้ ----------
	var click_attack := _click_attack
	var click_skill := _click_skill
	_click_attack = false
	_click_skill = false

	# โจมตีปกติ — ปุ่มโจมตี หรือ คลิกซ้าย
	var attack_pressed := Input.is_action_just_pressed("attack") or click_attack
	# ★ รอบ 96 ★ กดค้าง = ฟันรัวต่อเนื่องเอง (คลิกทีละครั้งยังทำงานเหมือนเดิม)
	var mouse_held := _mouse_attack_held()
	var attack_held: bool = attack_hold_repeat and (Input.is_action_pressed("attack") or mouse_held)
	if (attack_pressed or attack_held) and not is_attacking and attack_cooldown <= 0.0:
		# กดค้างด้วยเมาส์: อัปเดตจุดเล็งทุกครั้ง จะได้หันตามเคอร์เซอร์ระหว่างฟันรัว
		if mouse_held and not click_attack:
			_click_pos = get_viewport().get_canvas_transform().affine_inverse() \
				* get_viewport().get_mouse_position()
		if click_attack or mouse_held:
			_face_click()
		start_attack()
		return
	# ★ รอบ 93 ★ คลิกซ้ำระหว่างฟัน = จำไว้ ต่อจังหวะถัดไปทันทีที่ท่าจบ
	# ★ รอบ 95 ★ ต้องคลิกหลังท่าเดินไปแล้ว combo_buffer_from (35%) ถึงจะนับ
	# ไม่งั้นคลิกรัว 2 ทีตอนเริ่มไม้ 3 จะกลายเป็นสั่งฟันไม้ที่ 4 ทั้งที่ผู้เล่นไม่ได้ตั้งใจ
	if attack_pressed and is_attacking and combo_enabled and combo_buffer_input \
			and _attack_progress() >= combo_buffer_from:
		_combo_queued = true

	# คลิกขวา = สกิลช่องลัดที่ตั้งไว้
	if click_skill and mouse_skill_slot > 0:
		var msid := PlayerState.skills.hotkey_at(mouse_skill_slot - 1)
		if msid != &"":
			_face_click()
			use_skill(msid)
		return

	# สกิลปุ่มลัด 1-4
	for i in range(SkillBook.HOTKEY_COUNT):
		if Input.is_action_just_pressed("skill_%d" % (i + 1)):
			var sid := PlayerState.skills.hotkey_at(i)
			if sid != &"":
				use_skill(sid)
			return

	# เก็บไอเทม — กด F (หรือ Z)
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("pickup"):
		pickup_nearby()

	# ยาด่วน — Q = ช่องยาเลือด · R = ช่องยามานา (เลือกยาเองได้ในกระเป๋า)
	if Input.is_action_just_pressed("quick_potion"):
		PlayerState.use_item_hotkey(0)
	elif InputMap.has_action("quick_sp_potion") \
			and Input.is_action_just_pressed("quick_sp_potion"):
		PlayerState.use_item_hotkey(1)


func _update_facing() -> void:
	if sprite_faces_left:
		sprite.flip_h = facing > 0
	else:
		sprite.flip_h = facing < 0


func _update_animation() -> void:
	if is_attacking or sprite.sprite_frames == null:
		return

	# ★ รอบ 81 ★ ออกจากท่าฟันแล้วคืนความเร็วภาพเป็นปกติ (กันท่า Idle/Run วิ่งเร็วค้าง)
	if not is_equal_approx(sprite.speed_scale, 1.0):
		sprite.speed_scale = 1.0

	# ★ กำลังพุ่งหลบ ★ ท่าถูกตั้งไว้แล้วตอนเริ่มพุ่ง อย่าให้อะไรมาทับ
	if _dodge_time > 0.0:
		return

	# ★ โดนตีอยู่ ★ ปล่อยให้ท่า Hit เล่นจนจบก่อน ไม่ให้ Idle/Run มาทับ
	if _hit_left > 0.0:
		return

	# ★ ลอยอยู่กลางอากาศ ★ เฟรมเดินตามความเร็วจริง
	if not is_on_floor():
		if _has_anim("Jump"):
			_play_jump()
		elif absf(velocity.x) > 10.0:
			_play("Run")
		else:
			_play("Idle")
		return

	# ★ เพิ่งแตะพื้น ★ เล่นเฟรมช่วงลงพื้นต่อจากช่วงลอย ภาพเลยไหลต่อกัน ไม่กระตุก
	if _land_left > 0.0:
		if _has_anim("Land"):
			_play("Land")
		elif _jump_anim != "" and jump_anim_follow_physics:
			_play_land_frames()
		else:
			_play("Idle")
		return

	_jump_anim = ""
	if absf(velocity.x) > 10.0:
		_play("Run")
	else:
		_play("Idle")


## ★ ชื่ออนิเมชันที่ระบบยอมรับ ★
## ตั้งชื่อแบบไหนก็ได้ในลิสต์ และ "ตัวพิมพ์เล็ก-ใหญ่ไม่สำคัญ" (Die = die = DIE)
## ถ้าไม่มีชื่อไหนเลย จะไล่ลงไปใช้ตัวสำรองท้ายลิสต์แทน (กันตัวละครค้าง/หาย)
const ANIM_FALLBACK := {
	"Idle": ["Idle", "Stand"],
	"Run": ["Run", "Walk", "Move", "Jump", "Idle"],
	"Jump": ["Jump", "Hop", "Run", "Idle"],
	"Attack": ["Attack", "Atk", "Attact", "Idle"],
	"Hit": ["Hit", "Hurt", "Damage", "Idle"],
	"Death": ["Death", "Die", "Dead", "Dying", "Hit", "Idle"],
}

var _anim_lookup: Dictionary = {}   # ชื่อตัวพิมพ์เล็ก -> ชื่อจริงใน SpriteFrames


## ★ คำต่อท้ายของอาวุธที่ถืออยู่ ★ เช่น "Blade", "falchion"  ("" = มือเปล่า)
## เอามาจากช่อง Attack Animation ของไอเทม ("Attack_Falchion" -> "Falchion")
## ถ้าไม่ได้ตั้งไว้ ใช้ id ของไอเทมแทน (falchion -> "falchion")
func weapon_suffix() -> String:
	var weapon := PlayerState.equipment.weapon()
	if weapon == null:
		return ""
	var d := weapon.data()
	if d == null:
		return ""
	if d.attack_animation != &"":
		var t := String(d.attack_animation)
		return t.substr(7) if t.begins_with("Attack_") else t
	return String(d.id)


## ลำดับท่าสำรอง
## 1) ท่าเฉพาะอาวุธที่ถืออยู่  เช่น Idle_falchion / Run_falchion / Attack_falchion
## 2) ท่าปกติของท่านั้น        เช่น Idle / Run / Attack
## 3) ตัวสำรองอื่น ๆ
func _fallback_chain(anim: String) -> Array:
	var chain: Array = []

	# ท่าเฉพาะอาวุธ — ทำให้เปลี่ยนอาวุธแล้วภาพตัวละครเปลี่ยนตามได้ทุกท่า
	var suffix := weapon_suffix()
	if suffix != "" and not anim.to_lower().contains("_" + suffix.to_lower()):
		chain.append("%s_%s" % [anim, suffix])

	if ANIM_FALLBACK.has(anim):
		chain.append_array(ANIM_FALLBACK[anim])
		return chain

	chain.append(anim)
	if anim.begins_with("Attack"):
		chain.append(String(unarmed_attack_anim))
		chain.append("Attack")
	chain.append("Idle")
	return chain


## หาชื่ออนิเมชันจริง โดยไม่สนตัวพิมพ์เล็ก-ใหญ่
func _real_anim(anim_name: String) -> String:
	if sprite.sprite_frames == null:
		return ""
	if sprite.sprite_frames.has_animation(anim_name):
		return anim_name
	if _anim_lookup.is_empty():
		for a in sprite.sprite_frames.get_animation_names():
			_anim_lookup[String(a).to_lower()] = String(a)
	return _anim_lookup.get(anim_name.to_lower(), "")


## เล่นท่านี้ แล้วคืนชื่อท่าที่ได้เล่นจริง ("" = ไม่มีท่าไหนใช้ได้เลย)
## restart = true → เริ่มท่าใหม่จากเฟรม 0 เสมอ (ใช้ตอนฟัน — ฟันซ้ำท่าเดิมต้องเริ่มใหม่ ไม่ใช่เล่นต่อ)
func _play(anim: String, restart: bool = false) -> String:
	if sprite.sprite_frames == null:
		return ""
	for candidate in _fallback_chain(anim):
		var real := _real_anim(String(candidate))
		if real != "" and sprite.sprite_frames.get_frame_count(real) > 0:
			var switched := false
			if restart:
				sprite.play(real)
				sprite.set_frame_and_progress(0, 0.0)
				switched = true
			# ★ ต้องเช็ค is_playing ด้วย ★ ตอนกระโดดเราสั่ง pause() ค้างเฟรมไว้
			# ถ้าเช็คแค่ชื่อท่า พอลงพื้นแล้วชื่อท่าเดิม ภาพจะค้างไม่เล่นต่อ
			elif sprite.animation != real or not sprite.is_playing():
				sprite.play(real)
				switched = true
			# ★★ รอบ 97 ★★ จัดสเกล/ตำแหน่งให้ท่าใหม่ "ทันทีในเฟรมเดียวกัน"
			#
			# _apply_auto_fit() เดิมทำงานใน _process() แต่ sprite.play() เกิดใน _physics_process()
			# → เฟรมแรกของท่าใหม่ถูกวาดด้วย "สเกลของท่าเก่า"
			# ท่ายืนสเกล 0.406 ส่วนท่าฟัน 0.663 = ไม้แรกกะพริบเล็กลง 39% ทุกครั้งที่เริ่มฟันจากท่ายืน
			# (ไม้ 2-3 ไม่เห็นเพราะสเกลใกล้กัน 0.663 → 0.696 → 0.676)
			# เป็นบั๊กเดียวกับที่มอนเจอตอนรอบ 88 — ฝั่งผู้เล่นเพิ่งได้แก้
			if switched:
				_apply_auto_fit()
			return real
	return ""


# =========================================================
# ปรับขนาด/ตำแหน่งภาพให้เท่ากันทุกท่า
# =========================================================
func _apply_auto_fit() -> void:
	if auto_fit_height <= 0.0 or sprite.sprite_frames == null:
		return

	if auto_fit_collision and not _collision_synced:
		_collision_synced = true
		_sync_collision()
	var info: Dictionary = _fit_info(sprite.animation)
	if info.is_empty():
		return

	var k: float = info.scale
	sprite.scale = Vector2(k, k)

	var list: Array = info.frames
	if list.is_empty():
		return
	var fd: Dictionary = list[clampi(sprite.frame, 0, list.size() - 1)]

	# แนวนอน: จัดให้ตัวละครอยู่กึ่งกลาง (สลับข้างตอนหันกลับ)
	sprite.offset.x = fd.dx_use if sprite.flip_h else -fd.dx_use

	# แนวตั้ง: ให้ปลายเท้าแตะระดับพื้นของกล่องชน
	# ★ รอบ 39: ใช้ bottom_use (ค่ากลางของท่า) แทนค่าดิบรายเฟรม ★
	# เดิมจัดเท้ารายเฟรม → ขอบล่างของภาพต่างกันเฟรมละ 1-3 px (เงา/ขอบเบลอ)
	# ทำให้ทั้งตัวถูกดันขึ้น-ลงตามจังหวะเฟรม = "ยืน idle แล้วตัวเด้ง" ที่ผู้ใช้เห็น
	if auto_fit_align_feet:
		sprite.offset.y = (_feet_y() - sprite.position.y) / k - fd.bottom_use


## ปรับกล่องชนให้พอดีกับขนาดตัวละคร
func _sync_collision() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		return
	var cap := CapsuleShape2D.new()
	cap.height = auto_fit_height
	cap.radius = maxf(4.0, auto_fit_height * collision_width_ratio * 0.5)
	col.shape = cap


# =========================================================
# ★★ ตาข่ายกันตกแมพ (รอบ 56) ★★
#
# ปัญหา: ใช้สกิลพุ่ง (Slash) แล้วพุ่งข้ามขอบพื้น/ตกร่อง = ร่วงลงไปเรื่อย ๆ
# ไม่ตาย ไม่หยุด กล้องตามไม่ทัน เล่นต่อไม่ได้
#
# ตอนนี้: จำ "ที่ยืนล่าสุดที่ปลอดภัย" ไว้ตลอด ถ้าร่วงต่ำกว่าขอบล่างของแมพ
# จะพากลับมาที่นั่นให้เอง (ไม่เสียเลือด แค่เตือน)
# =========================================================
## ร่วงต่ำกว่าขอบล่างของแมพเท่านี้ = ถือว่าตกแมพ (พิกเซล)
const FALL_RESCUE_MARGIN := 260.0
## เก็บจุดปลอดภัยทุกกี่วินาที
const SAFE_POINT_INTERVAL := 0.35
## กันช่วยซ้ำถี่ ๆ (วินาที)
const RESCUE_COOLDOWN := 0.6


func _track_safe_ground(delta: float) -> void:
	if _rescue_cd > 0.0:
		_rescue_cd -= delta

	var map_rect := _map_bounds()
	# ---------- จำที่ยืนล่าสุดที่ปลอดภัย ----------
	_safe_timer -= delta
	if is_on_floor() and _dash_time <= 0.0 and _dodge_time <= 0.0 and _safe_timer <= 0.0:
		if map_rect.size == Vector2.ZERO or map_rect.has_point(global_position):
			_safe_pos = global_position
			_safe_timer = SAFE_POINT_INTERVAL

	# ---------- ตกแมพหรือยัง ----------
	if map_rect.size == Vector2.ZERO:
		return
	var limit: float = map_rect.position.y + map_rect.size.y + FALL_RESCUE_MARGIN
	if global_position.y > limit and _rescue_cd <= 0.0:
		_rescue_from_fall(map_rect)


func _rescue_from_fall(map_rect: Rect2) -> void:
	_rescue_cd = RESCUE_COOLDOWN
	_dash_time = 0.0
	_dodge_time = 0.0
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO

	var target := _safe_pos
	if target == Vector2.ZERO or not map_rect.has_point(target):
		# ไม่มีที่ปลอดภัยที่จำไว้ → กลับจุดเกิดของแมพ
		var map := get_tree().get_first_node_in_group("map")
		if map != null and map.has_method("_find_spawn_position"):
			target = map._find_spawn_position()
		else:
			target = map_rect.position + Vector2(map_rect.size.x * 0.5, map_rect.size.y * 0.4)
	global_position = target
	_safe_pos = target
	Events.floating_text(global_position + Vector2(0, -170),
		"พากลับขึ้นมาแล้ว", Color("#8ad6ff"), 20, 0)
	push_warning("[Player] ตกแมพ — พากลับที่ %s" % str(target))


## ขอบเขตแมพตอนนี้ (คืน Rect2() ถ้าหาไม่เจอ)
func _map_bounds() -> Rect2:
	var map := get_tree().get_first_node_in_group("map")
	if map != null and "map_bounds" in map:
		return map.map_bounds
	return Rect2()


## ตำแหน่งเท้าในโลก — ใช้เทียบระนาบกับมอนสเตอร์
func foot_position() -> Vector2:
	return global_position + Vector2(0.0, _feet_y())


## ระดับพื้นของกล่องชน (เท้าควรอยู่ตรงนี้)
func _feet_y() -> float:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null or col.shape == null:
		return 0.0
	var shape := col.shape
	if shape is CapsuleShape2D:
		return col.position.y + (shape as CapsuleShape2D).height * 0.5
	if shape is RectangleShape2D:
		return col.position.y + (shape as RectangleShape2D).size.y * 0.5
	if shape is CircleShape2D:
		return col.position.y + (shape as CircleShape2D).radius
	return col.position.y


## วัดขนาดตัวละครจริงในแต่ละท่า (ไม่นับพื้นที่โปร่งใส) แล้วจำไว้
func _fit_info(anim: StringName) -> Dictionary:
	if _fit_cache.has(anim):
		return _fit_cache[anim]

	var frames := sprite.sprite_frames
	if frames == null or not frames.has_animation(anim):
		return {}

	# ★ รอบ 44 — วัดผ่าน SpriteFit (จำไว้ตรงกลางทั้งเกม ไม่วัดซ้ำทุกครั้งที่ถูกสร้างใหม่) ★
	# get_image() คือการดึงภาพกลับจากการ์ดจอ ช้ามาก — เดิมทำใหม่หลังเปลี่ยนแมพทุกครั้ง = กระตุก
	# ค่ากลาง (median) กันตัวเด้งของรอบ 39 ย้ายไปอยู่ใน SpriteFit แล้ว (SNAP 12 px)
	var base: Dictionary = SpriteFit.measure(frames, anim, {}, fit_uniform_body)
	if base.is_empty():
		return {}
	var tallest: float = base.tallest

	# ★★ รอบ 94 ★★ ขนาดตัวละครยึดจาก "ลำตัว" ของท่าอ้างอิง ไม่ใช่ความสูงรวมของท่านั้น ๆ
	# ความสูงรวมนับดาบที่ชูขึ้นด้วย ท่าที่ชูสูงเลยถูกย่อทั้งตัว = ตัวโต/เล็กสลับกันระหว่างคอมโบ
	# ตอนนี้: หา "ลำตัวสูงกี่ px บนจอ" จากท่ายืนก่อน แล้วบังคับให้ทุกท่าได้เท่ากัน
	var k: float = auto_fit_height / maxf(1.0, tallest)
	if fit_uniform_body and not _fit_skips(String(anim)):
		var target := _body_on_screen_target()
		var body_med: float = float(base.get("body_med", 0.0))
		if target > 0.0 and body_med > 0.0:
			# ★ รอบ 95 ★ กันแก้เกินจริง — ท่าที่ตัวหมอบ/พุ่งไปข้างหน้า (Dash) ลำตัวสั้นลงจริง
			# ถ้าดันให้สูงเท่าท่ายืนจะกลายเป็นตัวโตผิดปกติ จึงจำกัดไม่ให้ต่างจากสเกลเดิมเกิน
			# fit_body_max_adjust (ยืมแนวคิด fit_max_overshoot ของมอน รอบ 86)
			var want := target / body_med
			var cap: float = maxf(1.0, fit_body_max_adjust)
			k = clampf(want, k / cap, k * cap)

	var info := {
		"scale": k,
		"frames": base.frames,
		"tallest": tallest,
		"body_med": float(base.get("body_med", 0.0)),
		"reach_max": float(base.get("reach_max", 0.0)),
	}
	_fit_cache[anim] = info
	return info


## ★ รอบ 94 ★ "ลำตัวควรสูงกี่พิกเซลบนจอ" — คิดจากท่าอ้างอิงครั้งเดียวแล้วจำไว้
## ยึดสเกลเดิมของท่าอ้างอิง (auto_fit_height ÷ ความสูงรวม) เพื่อให้ขนาดตัวละครเท่าเดิมเป๊ะ
## เปลี่ยนแค่ "ท่าอื่นถูกดึงมาให้เท่าท่านี้" ไม่ใช่ทำให้ตัวละครโตขึ้นทั้งเกม
func _body_on_screen_target() -> float:
	# ★ รอบ 95 ★ เปลี่ยนอาวุธ = ท่าอ้างอิงเปลี่ยน (Idle → Idle_blade) ต้องคิดใหม่
	# จำชื่อท่าที่ใช้คิดไว้ด้วย จะได้หมดอายุเองโดยไม่ต้องรอใครมาสั่งล้างแคช
	if _body_target > 0.0 and _body_target_anim == _resolve_anim(String(fit_reference_anim)):
		return _body_target
	var frames := sprite.sprite_frames
	if frames == null:
		return 0.0
	# ★★ รอบ 95 ★★ ต้องใช้ "ท่าที่เล่นจริง" เป็นตัวตั้ง ไม่ใช่ชื่อดิบ
	# ถือดาบอยู่ ท่ายืนที่เห็นคือ Idle_blade ไม่ใช่ Idle — เดิมไปวัด Idle (ตัวเปล่า)
	# ซึ่งวาดมาคนละสเกล ทำให้ทุกท่าถูกขยายราว 11% และท่าพุ่ง (Dash) โตถึง 18%
	var ref := _resolve_anim(String(fit_reference_anim))
	if ref == "":
		return 0.0
	var m: Dictionary = SpriteFit.measure(frames, StringName(ref), {}, true)
	var body_med: float = float(m.get("body_med", 0.0))
	var tall: float = float(m.get("tallest", 0.0))
	if body_med <= 0.0 or tall <= 0.0:
		return 0.0
	_body_target = body_med * (auto_fit_height / tall)
	_body_target_anim = ref
	return _body_target


## ท่านี้อยู่ในรายการยกเว้นไหม (เทียบแบบไม่สนตัวพิมพ์ใหญ่เล็ก)
func _fit_skips(anim: String) -> bool:
	var low := anim.to_lower()
	for sk in fit_uniform_body_skip:
		if sk != "" and low == String(sk).to_lower():
			return true
	return false


## หาชื่อท่าที่ "จะถูกเล่นจริง" ตามลำดับท่าสำรองเดียวกับ _play() (คิดอาวุธที่ถืออยู่ด้วย)
func _resolve_anim(anim: String) -> String:
	if sprite.sprite_frames == null:
		return ""
	for candidate in _fallback_chain(anim):
		var real := _real_anim(String(candidate))
		if real != "" and sprite.sprite_frames.get_frame_count(real) > 0:
			return real
	return ""


## เรียกเมื่อเปลี่ยนชุดภาพตัวละคร
func clear_fit_cache() -> void:
	_fit_cache.clear()
	_anim_lookup.clear()
	_body_target = 0.0
	_body_target_anim = ""


# =========================================================
# ★★ เสียงเอฟเฟกต์ตอนโจมตี (รอบ 57) ★★
#
# วางไฟล์เสียงที่ Sprites/sfx/<ชื่อ>.ogg แล้วมันเล่นเอง (ไม่มีไฟล์ = เงียบ ไม่ error)
# ไล่หาจาก "เฉพาะเจาะจง → ทั่วไป":
#   ท่า Attack_Katana → attack_katana → attack_blade → attack
# ★ เลยใส่แค่ attack_blade ไฟล์เดียว ดาบทุกเล่มก็มีเสียงครบ ★
# =========================================================
## เสียงสำรองตัวสุดท้าย (ดาบทุกเล่มใช้ร่วมกัน)
const SFX_ATTACK_FALLBACK := ["attack_blade", "attack"]


## ไล่ชื่อไฟล์เสียงจากชื่อท่า เช่น "Attack_Blade_bash" → [attack_blade_bash, attack_blade, attack]
func _sfx_keys_for_anim(anim: String) -> Array:
	var keys: Array = []
	var low := anim.to_lower()
	if low != "":
		keys.append(low)
		var parts := low.split("_", false)
		if parts.size() > 2:
			keys.append("%s_%s" % [parts[0], parts[1]])       # attack_blade
	for k in SFX_ATTACK_FALLBACK:
		if not keys.has(k):
			keys.append(k)
	return keys


func _play_attack_sfx(anim: String) -> void:
	if Game.sfx == null:
		return
	Game.sfx.play_first(_sfx_keys_for_anim(anim))


## ★ รอบ 58 ★ ลำดับหาไฟล์เสียงของสกิล (แยกตามสกิล ไม่ปนกับเสียงฟันธรรมดา)
##   1) ช่อง Sound ในไฟล์สกิล (ถ้าตั้งไว้)
##   2) attack_<อาวุธ>_<สกิล>  เช่น attack_blade_slash   ← เสียงเฉพาะ "อาวุธนี้ + สกิลนี้"
##   3) skill_<สกิล>            เช่น skill_slash          ← เสียงของสกิลนี้ ใช้ได้ทุกอาวุธ
##   4) เสียงฟันของอาวุธ (attack_blade → attack)          ← สำรองสุดท้าย ไม่ให้เงียบ
func skill_sfx_keys(skill_id: StringName) -> Array:
	var s := GameData.get_skill(skill_id)
	var keys: Array = []
	if s != null and s.sound.strip_edges() != "":
		keys.append(s.sound.strip_edges().to_lower())
	var anim := skill_animation(skill_id).to_lower()
	var parts := anim.split("_", false)
	# ท่าสกิลเฉพาะอาวุธ (Attack_Blade_slash) — ถ้าท่าที่ได้เป็นแค่ท่าฟันธรรมดา ไม่นับเป็นเสียงสกิล
	if parts.size() > 2:
		keys.append(anim)
	keys.append("skill_%s" % String(skill_id).to_lower())
	if parts.size() >= 2:
		keys.append("%s_%s" % [parts[0], parts[1]])        # attack_blade
	for k in SFX_ATTACK_FALLBACK:
		if not keys.has(k):
			keys.append(k)
	return keys


func _play_skill_sfx(skill_id: StringName) -> void:
	if Game.sfx == null:
		return
	Game.sfx.play_first(skill_sfx_keys(skill_id))


## เสียงสกิลที่ไม่ใช่ท่าฟัน (บัฟ/ฮีล) — ไม่มีไฟล์ = เงียบ ไม่ถอยไปใช้เสียงดาบ
func _play_support_sfx(skill_id: StringName, kind: String) -> void:
	if Game.sfx == null:
		return
	var s := GameData.get_skill(skill_id)
	var keys: Array = []
	if s != null and s.sound.strip_edges() != "":
		keys.append(s.sound.strip_edges().to_lower())
	keys.append("skill_%s" % String(skill_id).to_lower())
	keys.append("skill_%s" % kind)                          # skill_heal / skill_buff
	Game.sfx.play_first(keys)


# =========================================================
# ท่าโจมตี
# =========================================================
## ชื่อท่าโจมตีที่ควรเล่นตอนนี้ (ดูจากอาวุธที่ถืออยู่)
func attack_animation() -> String:
	var weapon := PlayerState.equipment.weapon()
	if weapon != null:
		var d := weapon.data()
		if d != null:
			# 1) ท่าเฉพาะที่ตั้งไว้ในไอเทมชิ้นนั้น
			if d.attack_animation != &"" and _has_anim(String(d.attack_animation)):
				return String(d.attack_animation)
			# 2) ท่าตามชื่อไอเทม เช่น falchion -> "Attack_falchion" (ไม่ต้องตั้งค่าอะไรเลย)
			var by_id := "Attack_%s" % String(d.id)
			if _has_anim(by_id):
				return by_id
			# 3) ท่าตามชนิดอาวุธ เช่น Attack_sword
			if d.weapon_type != &"":
				var by_type := weapon_attack_anim_format.replace("{type}", String(d.weapon_type))
				if _has_anim(by_type):
					return by_type
				# 4) ★ รอบ 97 ★ ท่าตัวแทนของชนิดอาวุธ (rapier ไม่มี Attack_rapier → ยืม Attack_Blade)
				# ไม่งั้นถือดาบอยู่แต่ตกไปท่าต่อยมือเปล่า
				var by_default: String = String(weapon_type_default_attack.get(String(d.weapon_type), ""))
				if by_default != "" and _has_anim(by_default):
					return by_default
	# 5) ท่ามือเปล่า
	return String(unarmed_attack_anim)


## ★ ชื่อท่าที่ควรเล่นตอนใช้สกิลนี้ ★ (ดูจากอาวุธที่ถือ + สกิลที่ใช้)
## ไล่หาตามลำดับ: ท่าที่ตั้งไว้ในสกิล → ท่าอาวุธ+สกิล → ท่าสกิลกลาง → ท่าโจมตีของอาวุธ
func skill_animation(skill_id: StringName) -> String:
	var s := GameData.get_skill(skill_id)

	# 1) ท่าเฉพาะที่ตั้งไว้ในไฟล์สกิลเอง (ช่อง Animation)
	if s != null and s.animation != &"" and _has_anim(String(s.animation)):
		return String(s.animation)

	var base := attack_animation()
	var sid := String(skill_id)

	# 2) ท่าเฉพาะ "อาวุธนี้ + สกิลนี้"  เช่น Attack_Blade_bash
	var by_weapon := skill_weapon_anim_format.replace("{attack}", base).replace("{skill}", sid)
	if _has_anim(by_weapon):
		return by_weapon

	# 3) ท่าสกิลกลาง ใช้ได้กับทุกอาวุธ  เช่น Attack_bash
	var by_skill := skill_anim_format.replace("{skill}", sid)
	if _has_anim(by_skill):
		return by_skill

	# 4) ไม่มีท่าสกิลเลย ก็ใช้ท่าโจมตีปกติของอาวุธที่ถืออยู่
	return base


func _has_anim(name: String) -> bool:
	if sprite.sprite_frames == null:
		return false
	var real := _real_anim(name)
	return real != "" and sprite.sprite_frames.get_frame_count(real) > 0


# =========================================================
# โจมตีปกติ
# =========================================================
func start_attack() -> void:
	# ★★ รอบ 97 ★★ กันไม้เก่าทับไม้ใหม่ (บั๊ก "ASPD ต่ำแล้วท่าฟันไม่โผล่เลย")
	# ASPD ต่ำ → ท่าจบก่อนคูลดาวน์ → animation_finished ปลด is_attacking → ไม้ใหม่เริ่มได้ทันทีที่คูลดาวน์หมด
	# แต่ coroutine ของไม้เก่ายัง await อยู่ พอ timer มันหมด (ช้ากว่าไม่กี่ ms เพราะคนละนาฬิกากับ _physics_process)
	# มันจะสั่ง is_attacking = false + speed_scale = 1 + เลื่อนจังหวะคอมโบ → ไม้ใหม่โดนเตะกลับท่ายืนตั้งแต่เฟรมแรก
	_attack_seq += 1
	var seq := _attack_seq
	if _attack_open_step >= 0:
		var open := _attack_open_step
		_attack_open_step = -1
		_combo_finish_step(open, true)

	is_attacking = true
	attack_cooldown = PlayerState.stats.attack_interval()
	velocity.x = 0.0
	_hit_left = 0.0
	_jump_anim = ""

	# ★★ รอบ 93 — ฟัน 3 จังหวะ ★★
	# คลิกแต่ละครั้งเล่นท่าถัดไป (1→2→3→1) · จังหวะสุดท้ายดาเมจ x1.25 และเอฟเฟกต์ใหญ่ขึ้น
	# ถ้าเว้นนานเกิน combo_window หลังท่าก่อนจบ กลับไปเริ่มจังหวะ 1 ใหม่
	var step := _combo_begin_step()
	var mult := _combo_mult(step)
	var is_finisher := combo_enabled and step == _combo_steps() - 1 and _combo_steps() > 1
	var anim := combo_attack_animation(step)
	# ★ รอบ 97 ★ ฟันซ้ำท่าเดิม (กดค้างจนวนกลับไม้ 1) ต้องเริ่มภาพใหม่ ไม่ใช่เล่นต่อจากที่ค้างไว้
	var played := _play(anim, true)
	if attack_anim_no_loop and played != "" and sprite.sprite_frames.get_animation_loop(played):
		sprite.sprite_frames.set_animation_loop(played, false)
	combo_step_started.emit(step, played, mult)

	# ★★ รอบ 81 — เร่งท่าฟันตาม ASPD ★★
	# เดิมท่าฟันเล่นความเร็วคงที่ พออัพ ASPD สูง ๆ ช่วงเวลาระหว่างตีสั้นลงเรื่อย ๆ
	# แต่ภาพยังฟันช้าเท่าเดิม = ตีครั้งถัดไปมาก่อนที่ท่าจะจบ ภาพเลยกระตุก/ค้างครึ่งท่า
	# ตอนนี้คิดความเร็วให้ท่าฟัน "จบพอดี" ก่อนตีครั้งถัดไป และเลื่อนจังหวะดาบโดนตามไปด้วย
	var anim_speed := _attack_anim_speed(played)
	sprite.speed_scale = anim_speed
	_attack_started_ms = Time.get_ticks_msec()
	_attack_span = maxf(0.05, attack_cooldown)

	# ★★ รอบ 94 ★★ รอจนถึง "เฟรมที่ดาบฟาดถึง" ของท่านี้ แทนเวลาคงที่
	# ★★ รอบ 100 ★★ คิดก่อนสร้างเอฟเฟกต์ เพราะรอยฟันแบบเชดเดอร์ต้องรู้ว่า "ดาเมจออกกี่วินาที"
	# เพื่อเอาไปวางจุดที่ภาพสว่างสุดให้ตรงเฟรมนั้นเป๊ะ
	var windup: float = maxf(0.03, _attack_hit_time(played, step) / anim_speed)
	_attack_windup = windup

	_spawn_attack_effect(anim_speed, combo_finisher_fx_scale if is_finisher else 1.0, step, windup)
	_play_attack_sfx(anim)
	_attack_open_step = step
	await get_tree().create_timer(windup).timeout
	if not is_instance_valid(self) or _dead or seq != _attack_seq:
		return

	_deal_damage(attack_range_x, attack_range_y, mult, false, 0)

	# กลับสู่ท่าปกติหลังจบอนิเมชัน (เผื่อ signal ไม่ถูกต่อไว้)
	# ★★ รอบ 97 ★★ ต้องคิดจาก _attack_span (ช่วงตีเต็มที่จำไว้ตอนเริ่ม) ไม่ใช่ attack_cooldown
	# เพราะ attack_cooldown ถูก _physics_process หักลงทุกเฟรมระหว่างที่ await windup อยู่
	# → ค่าที่อ่านได้ตรงนี้ = ช่วงตี - windup แล้ว พอลบ windup ซ้ำอีกที เหลือ 0.03 วิ
	# → is_attacking หลุดที่ ~windup+0.03 = ท่าฟันโดนตัดกลางคัน (ท่า Attack_Blade 7 เฟรม เห็นแค่ 0-4
	#   เฟรมฟาดจริง 5-6 ไม่เคยโผล่) — บั๊กนี้มีมาตั้งแต่รอบ 81 แต่เพิ่งเห็นชัดตอนรอบ 94-95
	#   ทำให้ windup ยาวขึ้น (เดิม windup คงที่สั้น ๆ ตัดนิดเดียวเลยไม่มีใครสังเกต)
	var rest: float = maxf(0.03, _attack_span - windup)
	await get_tree().create_timer(rest).timeout
	if is_instance_valid(self) and seq == _attack_seq:
		is_attacking = false
		sprite.speed_scale = 1.0
		_attack_open_step = -1
		_combo_finish_step(step)


# =========================================================
# ★★ รอบ 93 — คอมโบฟัน 3 จังหวะ ★★
# =========================================================
func _combo_steps() -> int:
	return maxi(1, combo_damage_mults.size()) if combo_enabled else 1


## จังหวะที่จะใช้ในการฟันครั้งนี้ — ถ้าคอมโบหมดอายุแล้วเริ่มใหม่ที่ 0
func _combo_begin_step() -> int:
	if not combo_enabled:
		return 0
	if Time.get_ticks_msec() > _combo_expire_ms:
		combo_step = 0
	combo_step = clampi(combo_step, 0, _combo_steps() - 1)
	_combo_queued = false
	return combo_step


## ท่าจบแล้ว → เลื่อนไปจังหวะถัดไป (วนกลับ) และเปิดหน้าต่างเวลาให้คลิกต่อ
## ถ้ามีคลิกจำไว้ระหว่างฟัน ต่อจังหวะถัดไปทันที
## advance_only = true → แค่เลื่อนจังหวะ ไม่ยิงไม้ที่จำไว้ (ใช้ตอนไม้ใหม่เริ่มก่อนไม้เก่าปิดจังหวะ)
func _combo_finish_step(step: int, advance_only: bool = false) -> void:
	if not combo_enabled:
		return
	var was_last := step >= _combo_steps() - 1
	combo_step = (step + 1) % _combo_steps()
	_combo_expire_ms = Time.get_ticks_msec() + int(combo_window * 1000.0)
	if advance_only:
		return
	# ★ รอบ 95 ★ ครบไม้สุดท้ายแล้วไม่วนต่อเอง — ต้องกดใหม่ ไม่งั้นเหมือนมีไม้ที่ 4 โผล่มาเอง
	if was_last and not combo_wrap_from_buffer:
		_combo_queued = false
		return
	if _combo_queued and not _dead:
		_combo_queued = false
		# คูลดาวน์อาจเหลือเศษไม่กี่ ms (ตัวจับเวลากับ _physics_process เดินคนละนาฬิกา) — รอให้หมดก่อน
		if attack_cooldown > 0.0:
			await get_tree().create_timer(attack_cooldown).timeout
			if not is_instance_valid(self) or _dead or is_attacking:
				return
		start_attack()


func _combo_mult(step: int) -> float:
	if not combo_enabled or step < 0 or step >= combo_damage_mults.size():
		return 1.0
	return maxf(0.05, combo_damage_mults[step])


## ยกเลิกคอมโบ (ใช้สกิล / ตาย / เปลี่ยนอาวุธ) — ครั้งถัดไปเริ่มจังหวะ 1
func reset_combo() -> void:
	combo_step = 0
	_combo_expire_ms = 0
	_combo_queued = false


## ★ รอบ 96 ★ ปุ่มซ้ายยังกดค้างอยู่จริงไหม
## เช็คสถานะปุ่มจริงด้วย เผื่อจังหวะ "ปล่อยปุ่ม" ถูก UI กินไปจนไม่ถึง _unhandled_input
func _mouse_attack_held() -> bool:
	if not mouse_attack or not _click_attack_held:
		return false
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_click_attack_held = false
		return false
	return true


## ท่าฟันไม้ปัจจุบันเดินไปแล้วกี่ส่วน (0 = เพิ่งเริ่ม · 1 = จบ)
func _attack_progress() -> float:
	if not is_attacking or _attack_span <= 0.0:
		return 1.0
	return clampf(float(Time.get_ticks_msec() - _attack_started_ms) / (_attack_span * 1000.0), 0.0, 1.0)


## ★ ท่าของจังหวะนี้ ★ ไล่หา: ท่าอาวุธ+คำต่อท้าย (Attack_Blade_2) → ท่ายืม (Attack_Blade_slash) → ท่าพื้นฐาน
## วาดท่าใหม่ชื่อ Attack_Blade_2 / _3 เมื่อไหร่ ระบบจะสลับไปใช้ให้เองโดยไม่ต้องแก้อะไร
func combo_attack_animation(step: int) -> String:
	var base := attack_animation()
	if not combo_enabled or step <= 0:
		return base
	if step < combo_anim_suffixes.size() and combo_anim_suffixes[step] != "":
		var named := base + combo_anim_suffixes[step]
		if _has_anim(named):
			return named
	if step < combo_fallback_suffixes.size():
		for suf in combo_fallback_suffixes[step].split(",", false):
			var s := suf.strip_edges()
			if s == "":
				continue
			if _has_anim(base + s):
				return base + s
	return base


## ★★ รอบ 94 ★★ ท่านี้ "ดาบฟาดถึง" ที่วินาทีที่เท่าไหร่ (นับจากเริ่มท่า ที่ความเร็วปกติ)
## ลำดับ: เลขเฟรมที่ตั้งเองต่อจังหวะ → หาเองจากภาพ → Attack Windup แบบเดิม
func _attack_hit_time(played_anim: String, step: int) -> float:
	if played_anim == "" or sprite.sprite_frames == null:
		return attack_windup
	var frame := -1
	if step >= 0 and step < combo_hit_frames.size():
		frame = combo_hit_frames[step]
	if frame < 0 and attack_hit_auto:
		frame = attack_hit_frame_of(played_anim)
	if frame < 0:
		return attack_windup
	return _anim_time_to_frame(played_anim, frame)


## ★ เฟรมที่ "ปลายดาบยื่นไปข้างหน้าไกลสุด" ★ = จังหวะที่ภาพฟาดโดนจริง
## ใช้ "เฟรมแรกที่ยื่นถึง 75% ของระยะไกลสุด" ไม่ใช่เฟรมที่ไกลที่สุด
## เพราะท่าที่ค้างดาบยื่นไว้หลายเฟรม จังหวะโดนคือตอนดาบ "มาถึง" ไม่ใช่ตอนสุดปลายทาง
func attack_hit_frame_of(anim: String) -> int:
	var real := _real_anim(anim)
	if real == "" or sprite.sprite_frames == null:
		return -1
	var m: Dictionary = SpriteFit.measure(sprite.sprite_frames, StringName(real), {}, true)
	var list: Array = m.get("frames", [])
	if list.size() < 2:
		return -1
	var lo := INF
	var hi := -INF
	for fd in list:
		lo = minf(lo, fd.reach)
		hi = maxf(hi, fd.reach)
	if hi <= 0.0 or hi - lo < 1.0:
		return -1
	var need: float = lo + (hi - lo) * 0.75
	var found := -1
	for i in range(list.size()):
		if list[i].reach >= need:
			found = i
			break
	if found < 0:
		return -1
	# ★ รอบ 95 ★ ไม่ให้ช้าเกิน — ท่าที่ดาบยื่นเพิ่มเรื่อย ๆ จะได้ไม่ไปออกดาเมจเอาเฟรมท้าย
	var latest: int = maxi(0, int(float(list.size()) * attack_hit_max_fraction))
	return mini(found, latest)


## เวลาตั้งแต่เริ่มท่าจนถึงต้นเฟรมที่ระบุ (ที่ความเร็วปกติ)
func _anim_time_to_frame(anim: String, frame: int) -> float:
	var real := _real_anim(anim)
	if real == "" or sprite.sprite_frames == null:
		return attack_windup
	var sf := sprite.sprite_frames
	var speed: float = maxf(0.01, sf.get_animation_speed(real))
	var n := sf.get_frame_count(real)
	var t := 0.0
	for i in range(mini(frame, n)):
		t += sf.get_frame_duration(real, i) / speed
	return t


## ★ รอบ 81 ★ ท่าฟันควรเล่นเร็วกี่เท่า ถึงจะจบทันก่อนตีครั้งถัดไป
## คืน 1.0 เสมอถ้าท่าเล่นจบทันอยู่แล้ว — เร่งอย่างเดียว ไม่มีการทำให้ช้าลง
func _attack_anim_speed(played_anim: String) -> float:
	if not attack_anim_follow_aspd or played_anim == "" or sprite.sprite_frames == null:
		return 1.0
	var natural := _anim_length(played_anim)
	if natural <= 0.0:
		return 1.0
	var target: float = maxf(0.08, attack_cooldown * attack_anim_fit)
	# ★ รอบ 97 ★ ASPD ต่ำ: ยอมช้าลงได้ถึง attack_anim_min_speed เพื่อไม่ให้ท่าจบแล้วยืนเฉยรอคูลดาวน์
	return clampf(natural / target, minf(1.0, attack_anim_min_speed), attack_anim_max_speed)



# =========================================================
# ใช้สกิล
# =========================================================
func use_skill(skill_id: StringName) -> void:
	if is_attacking or _dead:
		return
	var s := GameData.get_skill(skill_id)
	if s == null:
		return
	if not PlayerState.commit_skill_use(skill_id):
		return
	reset_combo()   # ★ รอบ 93 ★ ใช้สกิลแล้วคอมโบฟันปกติเริ่มนับใหม่

	var lv := PlayerState.skills.level_of(skill_id)

	match s.type:
		SkillData.SkillType.HEAL:
			var amount := s.heal_amount(lv, PlayerState.stats.total_int)
			PlayerState.heal_hp(amount)
			Events.floating_text(global_position, s.display_name, Color("#7ef0ff"), 20, 0)
			_play_support_sfx(skill_id, "heal")

		SkillData.SkillType.BUFF:
			PlayerState.apply_buff(skill_id)
			Events.floating_text(global_position, s.display_name, Color("#ffd54a"), 20, 0)
			_play_support_sfx(skill_id, "buff")

		SkillData.SkillType.ACTIVE_DASH:
			# ★ สกิลพุ่ง ★ ออกตัวไปข้างหน้าแล้วฟันทุกตัวที่ขวางทาง
			is_attacking = true
			attack_cooldown = maxf(PlayerState.stats.attack_interval(), s.cast_windup + 0.25)
			velocity.x = 0.0
			_play(skill_animation(skill_id))
			Events.floating_text(global_position, s.display_name, Color("#ffd54a"), 18, 0)
			_spawn_skill_effect(s, s.damage_mult(lv))
			_play_skill_sfx(skill_id)

			await get_tree().create_timer(s.cast_windup).timeout
			if not is_instance_valid(self) or _dead:
				return
			_start_dash(s, lv)

			# รอจนพุ่งจบจริง ๆ (เผื่อชนกำแพงแล้วหยุดก่อนกำหนด)
			while is_instance_valid(self) and _dash_time > 0.0:
				await get_tree().physics_frame
			await get_tree().create_timer(0.15).timeout
			if is_instance_valid(self):
				is_attacking = false

		_:
			is_attacking = true
			attack_cooldown = maxf(PlayerState.stats.attack_interval(), s.cast_windup + 0.15)
			velocity.x = 0.0
			# ★ ท่าสกิลแยกตามอาวุธที่ถือ ★ เช่น ถือดาบมือใหม่ใช้ bash -> Attack_Blade_bash
			_play(skill_animation(skill_id))
			Events.floating_text(global_position, s.display_name, Color("#ffd54a"), 18, 0)
			_spawn_skill_effect(s, s.damage_mult(lv))
			_play_skill_sfx(skill_id)

			# ★ เปิด Effect Damage ไว้ = ตัวเอฟเฟกต์เป็นคนทำดาเมจเอง ★
			# ไม่ต้องคิดดาเมจแบบกรอบรอบตัวซ้ำอีก ไม่งั้นมอนจะโดน 2 เด้ง
			if not s.effect_damage:
				for i in range(maxi(1, s.hit_count)):
					await get_tree().create_timer(s.cast_windup if i == 0 else 0.12).timeout
					if not is_instance_valid(self) or _dead:
						return
					var all_dir := s.type == SkillData.SkillType.ACTIVE_AOE
					_deal_damage(s.range_x, s.range_y, s.damage_mult(lv), s.use_matk,
						s.max_targets_at(lv), all_dir)
			else:
				# รอให้ท่าร่ายเล่นจบพอ ๆ กับแบบเดิม (เอฟเฟกต์ทำดาเมจไปเองแล้ว)
				await get_tree().create_timer(s.cast_windup).timeout

			await get_tree().create_timer(0.2).timeout
			if is_instance_valid(self):
				is_attacking = false


## ★ รอยฟันตอนโจมตีปกติ (รอบ 44) ★
func _spawn_attack_effect(anim_speed: float = 1.0, fx_scale: float = 1.0,
		step: int = 0, windup: float = 0.12) -> void:
	if not attack_effect_enabled:
		return

	# ★★ รอบ 100/101 ★★ รอยฟันพิเศษ — จังหวะสว่างสุดตรงเฟรมที่ดาเมจออก
	# ลำดับ: ภาพชุด Alternative 3 (รอบ 101) → เชดเดอร์ส่วนโค้ง (รอบ 100) → ไม่มี
	var used_shader := false
	if slash_shader_enabled:
		if slash_sheet_enabled:
			used_shader = _spawn_slash_sheet(step, fx_scale, windup, anim_speed) != null
		if not used_shader and SlashArcFX.available():
			_spawn_slash_arc(step, fx_scale, windup, anim_speed)
			used_shader = true
	if used_shader and slash_shader_replaces_sprite:
		return

	if attack_effect_frames == null and ResourceLoader.exists(ATTACK_FX_PATH):
		attack_effect_frames = load(ATTACK_FX_PATH)
	if attack_effect_frames == null:
		return
	var anims: Array = attack_effect_anims.duplicate()
	if anims.is_empty():
		for a in attack_effect_frames.get_animation_names():
			if String(a) != "default":
				anims.append(StringName(a))
	if anims.is_empty():
		return
	var idx: int = _attack_fx_turn % anims.size()
	_attack_fx_turn += 1
	SkillEffect.spawn_config({
		"frames": attack_effect_frames,
		"anim": anims[idx],
		"offset": attack_effect_offset,
		"height": attack_effect_height * fx_scale,
		# ★ รอบ 93 ★ จังหวะสุดท้ายของคอมโบ เอฟเฟกต์ใหญ่ขึ้น (fx_scale)
		"scale": attack_effect_scale * fx_scale,
		"follow": true,
		"delay": attack_effect_delay / anim_speed,
		"z": attack_effect_z,
		"name": "attack",
		"flip_v": idx % 2 == 1,
		"damage": false,
		# ★ รอบ 81 ★ ภาพฟันวิ่งเร็วเท่ากับท่าฟันของตัวละคร (ASPD สูง = ฟันไวทั้งคู่)
		"anim_speed": anim_speed,
	}, self, facing)


## ★ ไม้ที่ step ใช้ภาพชุดไหน ★ (เผื่อ slash_sheet_sets สั้นกว่าจำนวนไม้ → ใช้ตัวสุดท้าย)
func _slash_sheet_set(step: int) -> int:
	if slash_sheet_sets.is_empty():
		return 4
	var n := maxi(1, _combo_steps())
	var i := clampi(step, 0, n - 1)
	return slash_sheet_sets[mini(i, slash_sheet_sets.size() - 1)]


## ★★ รอบ 101 — รอยฟันแบบภาพชุดของไม้ที่ step ★★
##
## `windup` = เวลาจากกดฟัน → ดาเมจออก (วินาทีจริง คิดรวมความเร็วท่าตาม ASPD แล้ว)
## ส่งเข้าไปเป็น `peak` ตรง ๆ → SlashSheetFX จะวางเฟรมที่ 3 (ลำแสงยาวสุด) ไว้ที่วินาทีนั้นเป๊ะ
##
## ★ ทิศทาง ★ `slash_sheet_aims[i]` คือมุมที่ "อยากให้ลำแสงชี้" บนจอตอนหันขวา
## ภาพต้นฉบับวางตัวที่ −45° อยู่แล้ว จึงต้องหมุนเพิ่ม = aim − (−45) = aim + 45
## (คิดให้ด้วย SlashSheetFX.rotation_for() จะได้ไม่มีเลขวิเศษกระจายอยู่สองที่)
func _spawn_slash_sheet(step: int, fx_scale: float, windup: float, anim_speed: float) -> SlashSheetFX:
	var n := maxi(1, _combo_steps())
	var i := clampi(step, 0, n - 1)
	var aim: float = slash_sheet_aims[mini(i, slash_sheet_aims.size() - 1)] \
		if not slash_sheet_aims.is_empty() else 45.0
	var size: float = slash_sheet_sizes[mini(i, slash_sheet_sizes.size() - 1)] \
		if not slash_sheet_sizes.is_empty() else 260.0
	var off: Vector2 = slash_offset
	if not slash_sheet_offsets.is_empty():
		off = slash_sheet_offsets[mini(i, slash_sheet_offsets.size() - 1)]
	var tint := Color.WHITE
	if not slash_sheet_tints.is_empty():
		tint = slash_sheet_tints[mini(i, slash_sheet_tints.size() - 1)]
	var rev := false
	if not slash_sheet_reversed.is_empty():
		rev = slash_sheet_reversed[mini(i, slash_sheet_reversed.size() - 1)] != 0
	var set_no := _slash_sheet_set(step)
	var travel := slash_sheet_travel
	var additive := slash_sheet_additive
	# ★ รอบ 103 ★ ภาพที่ผู้ใช้ใส่เอง (SpriteFrames / โฟลเดอร์) — ว่าง = ใช้ภาพชุดที่แถมมา
	var own_frames: SpriteFrames = null
	var own_anim: StringName = &""
	var own_dir := ""

	# ★★ รอบ 103 ★★ ถ้าสมุดเอฟเฟกต์ติ๊ก "ใช้ค่าจากสมุดนี้" ไว้ ให้ค่าในสมุดชนะทั้งชุด
	var book_fx := _book_fx(PlayerFXBook.combo_key(i))
	if book_fx != null:
		set_no = book_fx.sheet_set
		rev = book_fx.sheet_reversed
		aim = book_fx.aim_deg
		size = book_fx.size_px
		off = book_fx.offset
		travel = book_fx.travel
		tint = book_fx.tint
		additive = book_fx.additive
		own_frames = book_fx.frames
		own_anim = book_fx.anim
		own_dir = book_fx.custom_dir

	# ★ ภาพต้นฉบับเอียงมากี่องศา ★ ภาพชุดที่แถมมารู้ค่าอยู่แล้ว (ชุด 4-5 เอียง −45)
	# แต่ภาพที่ผู้ใช้ใส่เองไม่รู้ → ถือว่า 0 แปลว่า "องศาที่ชี้" ที่ตั้งไว้ = องศาที่หมุนจริง ๆ
	var uses_own: bool = own_frames != null or own_dir.strip_edges() != "" or (book_fx != null and book_fx.crescent_enabled)
	var native: float = 0.0 if uses_own else SlashSheetFX.native_angle_of(set_no)

	return SlashSheetFX.spawn({
		"sprite": sprite,
		"track": book_fx,
		"set": set_no,
		"frames": own_frames,
		"anim": own_anim,
		"dir": own_dir,
		"native": native,
		"peak": windup,                       # ★ เฟรมลำแสงยาวสุด = เฟรมที่ดาเมจออก ★
		"tail": slash_tail / maxf(0.1, anim_speed),
		"size": size,
		"scale": fx_scale,
		"offset": off,
		"rotate": aim - native,
		"reversed": rev,
		"travel": travel,
		"modulate": tint,
		"additive": additive,
		"z": attack_effect_z + 5,
		"follow": true,
	}, self, facing)


## ★★ รอบ 100 — รอยฟันแบบเชดเดอร์ของไม้ที่ step ★★
##
## `windup` = เวลาจากกดฟัน → ดาเมจออก (วินาทีจริง คิดรวมความเร็วท่าตาม ASPD แล้ว)
## ส่งเข้าไปเป็น `peak` ตรง ๆ → SlashArcFX จะวาง progress = 0.5 (จุดที่ภาพสว่าง/กวาดกลางพอดี)
## ไว้ที่วินาทีนั้นเป๊ะ ไม่ว่า ASPD จะเท่าไหร่หรือไม้ไหนยาวสั้นแค่ไหน
func _spawn_slash_arc(step: int, fx_scale: float, windup: float, anim_speed: float) -> void:
	var n := maxi(1, _combo_steps())
	var i := clampi(step, 0, n - 1)
	var rot: float = slash_rotations[i] if i < slash_rotations.size() else 205.0
	var sc: float = slash_step_scales[i] if i < slash_step_scales.size() else 1.0
	var em: float = slash_step_emission[i] if i < slash_step_emission.size() else 1.0
	var ramp: Texture2D = null
	if i < slash_color_ramps.size():
		ramp = slash_color_ramps[i]
	if ramp == null:
		# ไม่ได้ตั้งเอง: ไม้สุดท้าย (ท่าจบคอมโบ) ใช้โทนไฟ · ไม้อื่นใช้โทนฟ้า
		var path := SlashArcFX.COLOR_EMBER_PATH if (i == n - 1 and n > 1) else SlashArcFX.COLOR_CYAN_PATH
		if ResourceLoader.exists(path):
			ramp = load(path)

	SlashArcFX.spawn({
		"peak": windup,                       # ★ จุดสว่างสุด = เฟรมที่ดาเมจออก ★
		"tail": slash_tail / maxf(0.1, anim_speed),
		"size": slash_size,
		"scale": sc * fx_scale,
		"offset": slash_offset,
		"rotate": rot,
		"zoom": slash_zoom,
		"emission": em,
		"color": ramp,
		"z": attack_effect_z + 5,
		"follow": true,
	}, self, facing)


## ★ เอฟเฟกต์สกิล ★ เกิดเป็นโหนดแยกในแมพ เลยใหญ่/ไกลเกินตัวละครได้
## ใส่ SpriteFrames ลงช่อง "Effect Frames" ของ SkillData แล้วมันทำงานเอง
func _spawn_skill_effect(s: SkillData, damage_mult: float = 1.0) -> void:
	if s == null:
		return
	# ★★ รอบ 103 ★★ สมุดเอฟเฟกต์ทับค่าของสกิลนี้ไหม
	var book_fx := _book_fx(s.id)
	if book_fx != null:
		SkillEffect.spawn_with_override(s, self, facing, damage_mult, book_fx)
		return
	if not s.has_effect():
		return
	SkillEffect.spawn(s, self, facing, damage_mult)


## ★ รอบ 103 ★ ค่าเอฟเฟกต์จากสมุดของท่านี้ (ไม่มีสมุด/ไม่ได้ติ๊กใช้ = null)
func _book_fx(key: StringName) -> PlayerSkillFX:
	if fx_book == null or key == &"":
		return null
	return fx_book.active(key)


# =========================================================
# ★ สกิลพุ่ง (Slash) ★
#
# ตัวละครพุ่งไปข้างหน้าด้วยความเร็วสูง มอนทุกตัวที่อยู่ในแนวพุ่งโดนดาเมจ
# ตัวเดิมโดนได้ครั้งเดียวต่อการพุ่ง 1 ครั้ง (ตั้งปิดได้ที่ Dash Hit Once)
# =========================================================
func _start_dash(s: SkillData, lv: int) -> void:
	var distance: float = s.dash_range(lv)
	_dash_speed = maxf(50.0, s.dash_speed)
	_dash_time = distance / _dash_speed
	_dash_range_x = s.range_x
	_dash_range_y = s.dash_range_y
	_dash_mult = s.damage_mult(lv)
	_dash_use_matk = s.use_matk
	_dash_max_targets = s.max_targets_at(lv)
	_dash_stop_on_wall = s.dash_stop_on_wall
	_dash_hits.clear()
	if not s.dash_hit_once:
		_dash_hits = []


func _dash_step(delta: float) -> void:
	_dash_time -= delta
	velocity.x = facing * _dash_speed
	velocity.y = minf(velocity.y, 0.0)   # ไม่ให้ร่วงระหว่างพุ่ง
	move_and_slide()
	_dash_damage()

	if _dash_stop_on_wall and is_on_wall():
		_dash_time = 0.0
	if _dash_time <= 0.0:
		velocity.x = 0.0


## ฟันทุกตัวที่อยู่ในแนวพุ่งตอนนี้ (ตัวที่โดนแล้วข้าม)
func _dash_damage() -> void:
	var my_foot := foot_position()
	# ระหว่างพุ่งฟันได้รอบตัว (ชนขอบก็นับ) เหมือนกรอบฟันปกติ
	var blade := attack_rect(_dash_range_x, _dash_range_y, true)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage_from_player"):
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		if enemy in _dash_hits:
			continue
		if not blade.intersects(enemy_rect(enemy), true):
			continue

		var enemy_foot: Vector2 = enemy.foot_position() if enemy.has_method("foot_position") \
			else enemy.global_position
		var offset: Vector2 = enemy_foot - my_foot
		enemy.take_damage_from_player(_dash_mult, _dash_use_matk,
			signi(int(offset.x)) if offset.x != 0.0 else facing)
		_dash_hits.append(enemy)

		if _dash_max_targets > 0 and _dash_hits.size() >= _dash_max_targets:
			_dash_time = 0.0
			return


func is_dashing() -> bool:
	return _dash_time > 0.0


# =========================================================
# ★★ กรอบการฟัน ★★
# เดิมวัด "จุดกึ่งกลางถึงจุดกึ่งกลาง" เลยมีปัญหา 3 อย่าง
#   1) มอนตัวใหญ่ (บอส) ต้องเดินเข้าไปประชิดกลางตัวถึงจะโดน
#   2) ตัวที่ยืนทับเรา/เราเหยียบอยู่ ไม่โดนเลย (อยู่ข้างหลังนิดเดียวก็ถูกตัดทิ้ง)
#   3) มอนที่กระโดดอยู่ (โพริง) ปลายเท้าลอย เลยหลุดเงื่อนไขแนวตั้ง
# ตอนนี้เปลี่ยนเป็น "กรอบฟัน" ชนกับ "กรอบตัวมอน" — ขอบชนขอบก็นับว่าโดน
# =========================================================

## กรอบดาบในพิกัดโลก
func attack_rect(range_x: float, range_y: float, all_directions: bool = false) -> Rect2:
	var f := foot_position()
	var forward: float = maxf(range_x, 10.0)
	var back: float = forward if all_directions else attack_back_reach
	var left: float = f.x - (back if facing > 0 else forward)
	var up: float = maxf(range_y, body_height() * 0.9)
	return Rect2(left, f.y - up, forward + back, up + attack_reach_down)


## ความสูงตัวผู้เล่นบนจอ (ใช้กะกรอบฟันแนวตั้ง)
func body_height() -> float:
	return auto_fit_height if auto_fit_height > 0.0 else 180.0


## กรอบตัวศัตรู — มอนบอกขนาดตัวเองได้ ถ้าไม่มีก็เดาให้
static func enemy_rect(enemy: Node) -> Rect2:
	if enemy.has_method("body_rect"):
		return enemy.body_rect()
	var f: Vector2 = enemy.foot_position() if enemy.has_method("foot_position") \
		else (enemy as Node2D).global_position
	return Rect2(f.x - 20.0, f.y - 60.0, 40.0, 60.0)


func _deal_damage(range_x: float, range_y: float, mult: float, use_matk: bool,
		max_targets: int, all_directions: bool = false) -> void:

	var enemies := get_tree().get_nodes_in_group("enemy")
	var hit_count := 0
	var blade := attack_rect(range_x, range_y, all_directions)
	var my_foot := foot_position()

	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage_from_player"):
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		if not blade.intersects(enemy_rect(enemy), true):
			continue

		var enemy_foot: Vector2 = enemy.foot_position() if enemy.has_method("foot_position") \
			else enemy.global_position
		var dx: float = enemy_foot.x - my_foot.x
		enemy.take_damage_from_player(mult, use_matk, signi(int(dx)) if dx != 0.0 else facing)
		hit_count += 1

		if max_targets > 0 and hit_count >= max_targets:
			return


# =========================================================
# รับดาเมจ
# =========================================================
func take_damage(amount: int, knockback_force: float = 0.0, from_direction: int = 0) -> void:
	if _dead:
		return

	# ★ โหมด GM อมตะ (รอบ 80) ★ เปิดจากหน้าต่าง GM — ทดสอบสกิลบอสได้โดยไม่ตาย
	if PlayerState.gm_god_mode:
		Events.floating_text(global_position + Vector2(0, -40), "GM", Color("#ffd54a"), 24, 0)
		return

	# ★★ ช่วงอมตะตอนพุ่งหลบ ★★ โดนตีไม่เข้า ขึ้นคำว่า "หลบ!" แทนเลขดาเมจ
	if is_invincible():
		Events.floating_text(global_position + Vector2(0, -40), "หลบ!",
			Color("#9be7ff"), 26, 0)
		return

	PlayerState.take_damage(amount)
	# ★ ดาเมจที่เราโดน — ตัวใหญ่ สีแดง ★
	Events.floating_text(global_position + Vector2(0, -40), str(amount), Color("#ff4040"), 32, 2)

	sprite.modulate = Color(1, 0.5, 0.5)
	_hurt_flash = 0.15

	if knockback_force > 0.0:
		var dir := from_direction if from_direction != 0 else -facing
		knockback = Vector2(dir * knockback_force, 0)
		if is_on_floor():
			velocity.y = -140.0

	# ★ ท่าโดนตี ★ เล่นแล้วล็อกไว้จนจบ ไม่ให้ Idle/Run มาทับในเฟรมถัดไป
	if PlayerState.stats.hp > 0 and not is_attacking:
		_play_hit()


## เล่นท่าโดนตี แล้วล็อกไม่ให้ท่าอื่นมาทับจนกว่าจะเล่นจบ
func _play_hit() -> void:
	var real := _play("Hit")
	if real == "" or not _is_hit_anim(real):
		return   # ชุดภาพนี้ยังไม่มีท่าโดนตี — ไม่ต้องล็อกอะไร
	# เริ่มใหม่ตั้งแต่เฟรมแรกทุกครั้งที่โดน
	sprite.frame = 0
	sprite.play(real)
	var length: float = hit_anim_time if hit_anim_time > 0.0 else _anim_length(real)
	_hit_left = clampf(length, 0.08, hit_anim_max)
	_jump_anim = ""


func _on_died() -> void:
	if _dead:
		return
	_dead = true
	is_attacking = false
	_hit_left = 0.0
	_click_attack_held = false   # ★ รอบ 96 ★ ตายแล้วเลิกฟันรัว
	reset_combo()   # ★ รอบ 93 ★
	_land_left = 0.0
	_jump_anim = ""
	velocity = Vector2.ZERO
	sprite.modulate = Color.WHITE
	sprite.speed_scale = 1.0   # ★ รอบ 81 ★ ตายกลางท่าฟันไว ๆ ต้องคืนความเร็วภาพก่อน

	# ท่าตายของผู้เล่น ตั้งชื่อ Death / Die / Dead ก็ได้ (พิมพ์เล็ก-ใหญ่ไม่สำคัญ)
	var played := _play("Death")
	var wait := 0.9
	if played != "" and String(played).to_lower() != "idle":
		sprite.frame = 0
		sprite.play(played)
		wait = clampf(_anim_length(played), 0.4, 2.0)

	await get_tree().create_timer(wait).timeout
	if not is_instance_valid(self):
		return

	# ★ ค้างเฟรมสุดท้ายของท่าตายไว้ ★ ไม่ให้วนลูปลุกขึ้นมาตายซ้ำ ๆ
	if played != "" and sprite.sprite_frames != null \
			and sprite.sprite_frames.has_animation(played):
		var count := sprite.sprite_frames.get_frame_count(played)
		if count > 0:
			sprite.pause()
			sprite.frame = count - 1

	# ★ popup ตอนตาย ★ ให้ผู้เล่นกดเองว่าจะเกิดใหม่ตอนไหน
	if UI != null and UI.death_popup != null:
		UI.death_popup.open()
	else:
		Game.respawn_in_town()


## ★ รอบ 48 — เลเวลอัพแบบ Ragnarok Online ★
## เสาแสงทอง + วงแสงที่เท้า + รัศมี + ประกายดาว + LEVEL UP! เด้งใหญ่ + จอวาบ (scripts/entities/level_up_effect.gd)
func _on_level_up(new_level: int) -> void:
	_play_level_up(LevelUpEffect.Kind.BASE, new_level)


func _on_job_level_up(new_job_level: int) -> void:
	_play_level_up(LevelUpEffect.Kind.JOB, new_job_level)


func _play_level_up(kind: int, level: int) -> void:
	# เลเวลกับจ๊อบมักขึ้นพร้อมกัน — ถ้ามีเอฟเฟกต์เล่นอยู่ ให้อันใหม่รอต่อคิว 1 วิ (ตัวหนังสือจะได้ไม่ทับกัน)
	for c in get_children():
		if c is LevelUpEffect and is_instance_valid(c):
			await get_tree().create_timer(1.0).timeout
			if not is_inside_tree():
				return
			break
	LevelUpEffect.spawn(self, Vector2(0.0, _feet_y()), kind, level)
	# ตัวละครเรืองแสงทองแล้วค่อย ๆ กลับปกติ (ไม่ใช้ _hurt_flash เพราะมันตัดกลับทันที)
	var glow := Color(1.7, 1.55, 1.0) if kind == LevelUpEffect.Kind.BASE else Color(1.5, 1.2, 1.8)
	sprite.modulate = glow
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


# =========================================================
# เก็บไอเทมที่ตกอยู่
# =========================================================
## เก็บของที่อยู่ใกล้ที่สุด
## ★ วัดจาก "ปลายเท้า" ★ เพราะจุดกำเนิดของผู้เล่นลอยอยู่กลางตัว (สูงจากพื้นครึ่งหนึ่งของกล่องชน)
## ถ้าวัดจากจุดกำเนิด ของที่วางอยู่แทบเท้าจะดูห่างเป็นร้อยพิกเซล จนเก็บไม่ได้
func pickup_nearby() -> bool:
	var item := nearest_pickup()
	if item == null:
		return false
	if item.has_method("collect"):
		item.collect()
	return true


## ของชิ้นที่ใกล้ที่สุดที่กด F แล้วเก็บได้ตอนนี้ (null = ไม่มี)
## ประตูวาปใช้ฟังก์ชันนี้เช็คด้วย จะได้ไม่แย่งปุ่ม F กัน
func nearest_pickup() -> Node:
	var my_foot := foot_position()
	var items := get_tree().get_nodes_in_group("dropped_item")
	items.sort_custom(func(a, b):
		return my_foot.distance_squared_to(a.global_position) \
			< my_foot.distance_squared_to(b.global_position))

	for item in items:
		if not is_instance_valid(item):
			continue
		var offset: Vector2 = item.global_position - my_foot
		if absf(offset.x) <= pickup_range and absf(offset.y) <= pickup_range_y:
			return item
	return null


# =========================================================
# ต่อ signal animation_finished ของ AnimatedSprite2D มาที่นี่ (ถ้าต้องการ)
# =========================================================
func _on_animated_sprite_2d_animation_finished() -> void:
	if String(sprite.animation).begins_with("Attack"):
		is_attacking = false
		_update_animation()
	elif _is_hit_anim(String(sprite.animation)) and not _dead:
		_hit_left = 0.0
		_update_animation()
