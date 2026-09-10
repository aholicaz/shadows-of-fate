## PlayerSkillFX — ค่าเอฟเฟกต์ของ "หนึ่งท่า" ของผู้เล่น (รอบ 103)
##
## ไม่ต้องเปิดไฟล์นี้เอง — ทุกช่องถูกเอาไปโชว์ใน `PlayerFXBook` (สมุดเอฟเฟกต์) แล้ว
## เลือกท่าจากดรอปดาวน์ที่นั่นแล้วแก้ได้เลย ที่เดียวจบ
##
## มี 2 ชุดค่าอยู่ในไฟล์เดียวกัน เพราะท่าคนละแบบใช้คนละระบบ:
##   · ไม้ 1-2-3 (Attack 1/2/3) → ระบบ "ภาพชุด Alternative 3" ของรอบ 101
##   · สกิลที่มี .tres (Bash · Slash · Magnum Break · บัฟต่าง ๆ) → ระบบ SkillEffect เหมือนเดิม
## สมุดจะโชว์เฉพาะชุดที่ตรงกับท่าที่เลือก ไม่ต้องเลื่อนผ่านช่องที่ไม่เกี่ยว
class_name PlayerSkillFX
extends Resource

## ★ ใช้ค่าจากสมุดนี้ไหม ★
## ปิด = ปล่อยให้ท่านั้นใช้ค่าเดิมของมัน (สกิลใช้ค่าใน .tres ของตัวเอง · ไม้ 1-3 ใช้ค่าใน Player)
## → ติ๊กเฉพาะท่าที่อยากคุมเอง ท่าที่เหลือไม่กระทบเลย
@export var use_book: bool = false

# =========================================================
# ชุดที่ 1 — ไม้ 1/2/3 (ภาพชุด Alternative 3 · รอบ 101)
# =========================================================
## ★ โฟลเดอร์ภาพเอฟเฟกต์ของคุณเอง ★ ใส่แล้วจะใช้ภาพในโฟลเดอร์นี้แทน "ภาพชุด (1-5)"
## อ่านไฟล์ .png ทุกไฟล์ในโฟลเดอร์ **เรียงตามชื่อ** → ตั้งชื่อ 01,02,03... จะได้ลำดับถูก
## กี่เฟรมก็ได้ ไม่ต้อง 6 เฟรม (ถ้าใส่ SpriteFrames ไว้ด้วย SpriteFrames จะชนะ)
@export_dir var custom_dir: String = ""
## ใช้ภาพชุดไหน (1-5) — ชุด 1-3 เป็นวงโค้ง · ชุด 4-5 เป็นลำแสงเส้นตรง
## (มีผลเฉพาะตอนที่ไม่ได้ใส่ SpriteFrames และไม่ได้ชี้โฟลเดอร์เอง)
@export_range(1, 5, 1) var sheet_set: int = 4
## เล่นเฟรมจากท้ายมาหน้า (วงโค้งชุด 2 ต้องติ๊กอันนี้ถึงจะ "กางออก" ตามดาบ)
@export var sheet_reversed: bool = false
## ★ ลำแสงชี้ไปทางไหน ★ องศาบนจอตอนหันขวา (0 = นอนราบ · บวก = ก้มลง · ลบ = เชิดขึ้น)
## ชุด 1-3 (วงโค้ง) ค่านี้กลายเป็น "หมุนเพิ่มจากภาพต้นฉบับกี่องศา" (0 = ตามที่วาดมา)
@export_range(-180.0, 180.0, 1.0) var aim_deg: float = 45.0
## ขนาดบนจอ (px)
@export_range(40.0, 600.0, 1.0) var size_px: float = 250.0
## พุ่งออกไปข้างหน้ากี่ px หลังดาเมจออก (0 = อยู่กับที่)
@export_range(0.0, 200.0, 1.0) var travel: float = 34.0
## บวกแสงลงฉาก (เรืองแสง) หรือวาดทับปกติ
@export var additive: bool = true
## แปลงสีภาพเป็นขาวโดยรักษา alpha เดิม
@export var white_mask: bool = false
## เสี้ยวแสงสดพร้อมเส้นแสงและประกาย; ปิดเพื่อกลับไปใช้ภาพชุดเดิม
@export var crescent_enabled: bool = false
@export_range(0.7, 1.6, 0.05) var crescent_span: float = 1.25
@export_range(0.5, 2.0, 0.05) var crescent_width: float = 1.0
@export_range(-1.0, 1.0, 2.0) var crescent_direction: float = 1.0
## ชื่อ animation ที่วัดตำแหน่งดาบไว้ (ว่าง = ใช้เวลาเดิม)
@export var track_animation: StringName = &""
## จุดกึ่งกลางใบดาบในภาพต้นฉบับ เทียบศูนย์กลางเฟรม ก่อน flip/auto-fit
@export var blade_positions: PackedVector2Array = PackedVector2Array()
@export var blade_angles: PackedFloat32Array = PackedFloat32Array()
## ความเข้มรายเฟรม: 0 ซ่อนช่วงเตรียม/เก็บดาบ
@export var blade_opacity: PackedFloat32Array = PackedFloat32Array()

# =========================================================
# ชุดที่ 2 — สกิลที่มี .tres (ระบบ SkillEffect เดิม)
# =========================================================
## SpriteFrames ของเอฟเฟกต์
## · สกิล: เว้นว่าง = ใช้ของเดิมใน .tres ของสกิลนั้น
## · ★ ไม้ 1-3: ใส่แล้วจะใช้ภาพนี้แทนภาพชุด Alternative 3 (ลากไฟล์มาใส่ได้เลย) ★
@export var frames: SpriteFrames
## ชื่อท่าใน SpriteFrames นั้น (เว้นว่าง = ใช้ท่าแรกที่เจอ)
@export var anim: StringName = &""
## อยากให้เอฟเฟกต์สูงกี่พิกเซลบนจอ (0 = ใช้ Scale แทน)
@export var height: float = 0.0
@export var scale: float = 1.0
## พุ่งออกไปข้างหน้ากี่พิกเซล/วินาที (0 = อยู่กับที่)
@export var speed: float = 0.0
## เกาะไปกับตัวละครไหม (ใช้กับสกิลพุ่ง)
@export var follow: bool = false
## อยู่บนจอกี่วินาที (0 = จนกว่าอนิเมชันจะจบ)
@export var life: float = 0.0
## หน่วงกี่วินาทีหลังเริ่มร่ายถึงจะโผล่
@export var delay: float = 0.0
## ชั้นการวาด (มากกว่าตัวละคร = อยู่หน้า)
@export var z: int = 60

# =========================================================
# ใช้ร่วมกันทั้งสองชุด
# =========================================================
## เยื้องจากตัวละครกี่พิกเซล — x กลับข้างให้เองตามที่ตัวละครหัน
@export var offset: Vector2 = Vector2(90, -60)
## สีคูณ (ขาว = สีตามภาพต้นฉบับ)
@export var tint: Color = Color.WHITE


## ก๊อปปี้ค่าตั้งต้นจาก SkillData มาใส่ (ใช้ตอนกด "ดึงค่าเดิมของสกิลมาใส่" ในสมุด)
func copy_from_skill(s: SkillData) -> void:
	if s == null:
		return
	frames = s.effect_frames
	anim = s.effect_anim
	offset = s.effect_offset
	height = s.effect_height
	scale = s.effect_scale
	speed = s.effect_speed
	follow = s.effect_follow
	life = s.effect_life
	delay = s.effect_delay
	z = s.effect_z
