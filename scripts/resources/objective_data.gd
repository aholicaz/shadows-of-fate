## ObjectiveData — เงื่อนไข 1 ข้อของเควส (รอบ 30)
##
## ★ ทำไมต้องมี ★
## ของเดิมเควสทำได้อย่างเดียวคือ "ฆ่ามอนกี่ตัว" เขียนเควสเนื้อเรื่องไม่ได้เลย
## ตอนนี้เควส 1 อันมีได้หลายเงื่อนไข และมีได้หลายชนิด
##
## ★ วิธีสร้าง ★ ในหน้าต่าง Inspector ของไฟล์เควส (.tres)
##   ช่อง "เงื่อนไข (หลายข้อ)" -> กด + -> เลือก New ObjectiveData -> กรอกช่องข้างล่าง
##
## ★ ของเดิมยังใช้ได้ ★ เควสที่กรอก Kill Monster Id / Kill Count ไว้แบบเก่า
## ระบบจะแปลงให้เป็นเงื่อนไข KILL 1 ข้ออัตโนมัติ ไม่ต้องแก้ไฟล์เก่า
class_name ObjectiveData
extends Resource

## ชนิดของเงื่อนไข
enum Kind {
	KILL,     ## ฆ่ามอนสเตอร์ — Target = id ของมอน
	COLLECT,  ## มีไอเทมในกระเป๋า — Target = id ของไอเทม (นับสด ๆ จากกระเป๋า)
	TALK,     ## คุยกับ NPC — Target = "ชื่อ NPC" ที่โชว์บนหัว
	VISIT,    ## ไปให้ถึงแมพ — Target = map_id
	READ,     ## อ่าน/ตรวจของในแมพ — Target = id ของจุดนั้น (ตั้งเองได้)
	FLAG,     ## ธงเนื้อเรื่องถูกตั้งแล้ว — Target = ชื่อธง (นับสด ๆ)
	## ★ รอบ 105 ★ ตีมอนด้วยสกิล — Target = "id มอน|สกิล" เช่น "wall_shieldbearer|sunder"
	## ฝั่งสกิลใส่ id สกิล หรือชื่อกลุ่ม: sunder (สายหนัก) · edge (สายคริ) · ninth (สกิล Ninth Edge)
	## ใส่หลายอันคั่นด้วย , · ฝั่งมอนใส่ * = มอนตัวไหนก็ได้
	SKILL_HIT,
}

@export var kind: Kind = Kind.KILL
## ★ เป้าหมาย ★ ความหมายเปลี่ยนตามชนิด (ดูคำอธิบายของ Kind ข้างบน)
@export var target: StringName = &""
## ต้องกี่ครั้ง/กี่ชิ้น (TALK · VISIT · READ · FLAG ใช้ 1 ก็พอ)
@export var count: int = 1
## ★ ข้อความในสมุดเควส ★ เว้นว่าง = ระบบเขียนให้เอง
@export var text: String = ""
## COLLECT: ยึดของตอนส่งเควสไหม (ปิด = ให้ผู้เล่นเก็บของไว้)
@export var consume: bool = true


func need() -> int:
	return maxi(1, count)


## ★ เงื่อนไขนี้นับสดจากสถานะปัจจุบันไหม ★
## COLLECT อ่านจากกระเป๋า · FLAG อ่านจากธงเนื้อเรื่อง — ไม่ต้องเก็บตัวเลขไว้
func is_live() -> bool:
	return kind == Kind.COLLECT or kind == Kind.FLAG


## ทำไปแล้วเท่าไหร่ (เฉพาะชนิดที่นับสด) — ชนิดอื่นให้ QuestLog เก็บเอง
func live_progress() -> int:
	match kind:
		Kind.COLLECT:
			if PlayerState.inventory == null:
				return 0
			return PlayerState.inventory.count_of(target)
		Kind.FLAG:
			return 1 if PlayerState.has_flag(target) else 0
	return 0


## ข้อความที่โชว์ในสมุดเควส
func describe() -> String:
	if text != "":
		return text
	match kind:
		Kind.KILL:
			var m := GameData.get_monster(target)
			return "ล่า %s" % (m.display_name if m != null else String(target))
		Kind.COLLECT:
			var it := GameData.get_item(target)
			return "หา %s" % (it.display_name if it != null else String(target))
		Kind.TALK:
			return "คุยกับ %s" % String(target)
		Kind.VISIT:
			return "ไปที่ %s" % String(target)
		Kind.READ:
			return "ตรวจดู %s" % String(target)
		Kind.FLAG:
			return String(target)
		Kind.SKILL_HIT:
			var m2 := GameData.get_monster(skill_hit_monster())
			var who := "มอนตัวไหนก็ได้" if skill_hit_monster() == &"*" else (m2.display_name if m2 != null else String(skill_hit_monster()))
			return "ใช้%s โดน %s" % [skill_hit_label(), who]
	return String(target)


# =========================================================
# ★ รอบ 105 ★ SKILL_HIT — "ตีมอน X ด้วยสกิล Y"
# =========================================================
## กลุ่มสกิลที่เควสอ้างถึงได้ด้วยชื่อสั้น ๆ
const SKILL_GROUPS := {
	"sunder": [&"anvil_cleave", &"faultline", &"worldcleaver"],
	"edge": [&"rune_flurry", &"unbroken_edge", &"rune_echo"],
	"ninth": [&"erasing_cut", &"ninth_inscription", &"twin_inscription", &"twin_echo"],
}
const SKILL_GROUP_NAMES := {"sunder": "สกิลสาย Sunder (ดาบหนัก)", "edge": "สกิลสาย Edge (คม)", "ninth": "สกิล Ninth Edge"}


func skill_hit_monster() -> StringName:
	var s := String(target)
	return StringName(s.get_slice("|", 0).strip_edges()) if "|" in s else &"*"


func skill_hit_skills() -> Array:
	var s := String(target)
	var part := s.get_slice("|", 1) if "|" in s else s
	var out: Array = []
	for p in part.split(",", false):
		var k := String(p).strip_edges()
		if SKILL_GROUPS.has(k):
			out.append_array(SKILL_GROUPS[k])
		elif k != "":
			out.append(StringName(k))
	return out


func skill_hit_label() -> String:
	var s := String(target)
	var part := s.get_slice("|", 1) if "|" in s else s
	var names: Array[String] = []
	for p in part.split(",", false):
		var k := String(p).strip_edges()
		if SKILL_GROUP_NAMES.has(k):
			names.append(String(SKILL_GROUP_NAMES[k]))
		else:
			var sk := GameData.get_skill(StringName(k))
			names.append(sk.display_name if sk != null else k)
	return "/".join(names)


## เหตุการณ์ "สกิล skill_id โดนมอน monster_id" ตรงกับเงื่อนไขนี้ไหม
func matches_skill_hit(monster_id: StringName, skill_id: StringName) -> bool:
	if kind != Kind.SKILL_HIT:
		return false
	var m := skill_hit_monster()
	if m != &"*" and m != monster_id:
		return false
	return skill_id in skill_hit_skills()


## บรรทัดเต็มพร้อมตัวเลข เช่น "ล้ม โพริง  7/10"
func line(done: int) -> String:
	var n := need()
	if n <= 1:
		return "%s  %s" % [describe(), "[x]" if done >= 1 else "[ ]"]
	return "%s  %d/%d" % [describe(), mini(done, n), n]
