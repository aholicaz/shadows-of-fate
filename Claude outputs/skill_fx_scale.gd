## SkillFxScale — ขนาด "ภาพ" สกิลมอนเทียบกับขนาดตัว ★ รอบ 167 ★
##
## ใช้ 2 ที่:
##   apply(d, k)   — ขยายภาพสกิลทั้งชุดตามตัว (มอนแชมเปี้ยนตัวใหญ่ขึ้น 1.3 เท่า → สกิลใหญ่ตาม)
##                   ช่องโดนคลื่น/สายฟ้ากว้างขึ้นตาม แต่ไม่เกิน HIT_CAP (ยังพุ่งหลบทะลุได้ — อมตะ 0.28 วิ)
##   report(d, body_h) — ความสูงภาพสกิลที่มองเห็นจริงเทียบกับตัว (ใช้ในเทสต์ + หา «ตัวใหญ่ สกิลเล็ก»)
## ค่าในไฟล์ .tres ของแต่ละตัวปรับไว้แล้วรอบ 167 (tools/round167/fx_table.json) — ตัวนี้ไม่แก้ไฟล์
class_name SkillFxScale
extends RefCounted

const HIT_CAP := 140.0          ## ครึ่งความกว้างช่องโดนสูงสุด (px)
const MIN_RATIO := 0.45         ## ภาพสกิลที่ต่ำกว่านี้เทียบความสูงตัว = «เล็กเกินตัว»

## สัดส่วน «ส่วนที่มีภาพ / ความสูงช่องเฟรม» ของชีทที่ใช้ร่วมกัน (วัดจากภาพจริงรอบ 167)
const FRAME_FILL := {
	"res://data/sprites/fx_dark_wave.tres": 1.0,
	"res://data/sprites/fx_thorn_wave.tres": 1.0,
	"res://data/sprites/fx_fire_wave.tres": 1.0,
	"res://data/sprites/fx_rending_wave.tres": 0.747,
	"res://data/sprites/fx_lightning.tres": 0.977,
	"res://Sprites/effects/hrungnir/runepillar_impact_frames.tres": 0.934,
}


static func apply(d: MonsterData, k: float) -> void:
	if d == null or is_equal_approx(k, 1.0):
		return
	d.skill_wave_height *= k
	d.skill_wave_hit_height *= k
	d.skill_wave_hit_width = _grow(d.skill_wave_hit_width, k)
	d.skill_bolt_height *= k
	d.skill_bolt_hit_width = _grow(d.skill_bolt_hit_width, k)
	if d.skill_effect_height > 0.0:
		d.skill_effect_height *= k
	else:
		d.skill_effect_scale *= k
	d.skill_effect_offset *= k
	d.skill_projectile_height *= k
	d.skill_projectile_offset *= k
	d.skill_explosion_height *= k
	d.projectile_height *= k
	d.projectile_offset *= k


static func _grow(v: float, k: float) -> float:
	if k < 1.0:
		return v * k
	return maxf(v, minf(v * k, HIT_CAP))


## ความสูงภาพที่มองเห็นจริงของแต่ละระบบสกิล → {"wave": px, "bolt": px, ...} (เฉพาะที่ตัวนี้ใช้)
static func report(d: MonsterData) -> Dictionary:
	var out := {}
	if d == null:
		return out
	if d.skill_wave_count > 0:
		var p := d.skill_wave_frames.resource_path if d.skill_wave_frames != null else "res://data/sprites/fx_dark_wave.tres"
		out["wave"] = d.skill_wave_height * float(FRAME_FILL.get(p, 1.0))
	if d.skill_bolt_count > 0:
		var p2 := d.skill_bolt_frames.resource_path if d.skill_bolt_frames != null else "res://data/sprites/fx_lightning.tres"
		out["bolt"] = d.skill_bolt_height * float(FRAME_FILL.get(p2, 1.0))
	if d.skill_projectile_texture != null:
		out["lob_explosion"] = d.skill_explosion_height
	return out
