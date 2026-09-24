## BossSkillSet — ★ รอบ 158 ★ บอสบท 5-7 มีสกิล 3 ท่า (หมุนเวียน ท่า 1 → 2 → 3 → 1 …)
##
## ท่า 1 = สกิลเดิมที่ตั้งใน MonsterData (.tres) — ไม่แตะ
## ท่า 2-3 = ตามตาราง SETS:
##   "zones"   → วงเตือนสี่เหลี่ยมบนพื้นแล้วฟาดตามเวลา (scripts/entities/boss_zone_skill.gd)
##               pattern: pillars3 · inout · rain · gap3 · escape · pendulum · eruption · stomp3 · judgment
##   "variant" → ใช้ระบบสกิลเดิม แต่เปลี่ยนค่าบางช่องชั่วคราว (เช่น จำนวนสายฟ้า) — ใส่ชื่อฟิลด์ MonsterData ใน "set"
## ดาเมจทุกท่า = skill_damage_mult ของบอส (บท 5 ×5 · บท 6 ×5.5 · บท 7 ×6) × "mult" ของท่า (ค่าเริ่ม 1.0)
## เลือด < 50% = ท่า zones เร็วขึ้น 12% · บอสบท 1-4 ผู้ใช้ทำเองแล้ว ไม่อยู่ในตารางนี้
## หอร้อยชั้น (data มี meta tower_source) ไม่ใช้ตารางนี้ — หอคุมจังหวะสกิลเอง
class_name BossSkillSet
extends RefCounted

const SETS := {
	&"light_forsaken": [
		{"type": "zones", "pattern": "pillars3", "name": "ลำแสงลืมตัวตน", "color": "c9a8ff", "style": "light"},
		{"type": "zones", "pattern": "inout", "name": "ทุ่งแห่งการลืมเลือน", "color": "b18cff", "style": "light"},
	],
	&"radiant_alfr": [
		{"type": "zones", "pattern": "rain", "name": "ฝนแสงรุ่งอรุณ", "color": "ffe9a0", "style": "light"},
		{"type": "zones", "pattern": "gap3", "name": "วงแหวนเรืองรอง", "color": "fff1bb", "style": "light"},
	],
	&"false_judge": [
		{"type": "zones", "pattern": "escape", "name": "โทษประหารสามคราว", "color": "ff9a6b", "style": "light"},
		{"type": "zones", "pattern": "pendulum", "name": "ตราชั่งแห่งเฮล", "color": "ffc46b", "style": "light"},
	],
	&"chained_garm": [
		{"type": "variant", "name": "เขี้ยวสายฟ้าเจ็ดคม",
			"set": {"skill_bolt_count": 7, "skill_bolt_spacing": 130.0, "skill_bolt_interval": 0.10, "skill_bolt_start": 110.0}},
		{"type": "zones", "pattern": "inout", "name": "หอนแห่งเฮล", "color": "8fd8ff", "style": "light"},
	],
	&"kiln_sentinel": [
		{"type": "zones", "pattern": "eruption", "name": "ลาวาทะลักจากเบ้า", "color": "ff8a3a", "style": "fire"},
		{"type": "zones", "pattern": "stomp3", "name": "ค้อนทั่งสามจังหวะ", "color": "ffb060", "style": "fire"},
	],
	&"oath_warden": [
		{"type": "zones", "pattern": "judgment", "name": "คำสาบานตรึงพื้น", "color": "e0b0ff", "style": "light"},
		{"type": "zones", "pattern": "gap3", "name": "วงล้อมคำสั่ง", "color": "c4b0ff", "style": "fire"},
	],
}


## มอนตัวนี้ใช้สกิลหมุนเวียน 3 ท่าไหม
static func has_set(actor: Node) -> bool:
	if actor == null or actor.get("data") == null:
		return false
	var d: MonsterData = actor.data
	if String(d.get_meta("tower_source", "")) != "":
		return false
	return SETS.has(d.id)


## ท่าที่ slot (1 หรือ 2) ของบอสตัวนี้ ({} = ไม่มี)
static func skill_of(id: StringName, slot: int) -> Dictionary:
	var list: Array = SETS.get(id, [])
	if slot < 1 or slot > list.size():
		return {}
	return list[slot - 1]


## ชื่อสกิลทั้ง 3 ท่า (ใช้โชว์/ทดสอบ)
static func names_of(d: MonsterData) -> Array[String]:
	var out: Array[String] = [d.skill_name]
	for s: Dictionary in SETS.get(d.id, []):
		out.append(String(s.get("name", "")))
	return out
