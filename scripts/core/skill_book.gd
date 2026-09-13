## SkillBook — สกิลที่ตัวละครเรียนแล้ว + ปุ่มลัด
class_name SkillBook
extends RefCounted

const HOTKEY_COUNT := 4

static func profession_of(id: StringName) -> StringName:
	if id in NINTH_SKILLS: return &"ninth_edge"
	if id in RUNE_SKILLS: return &"runeblade"
	return &"swordsman"

## Skills of the secret profession are available after its promotion.
const NINTH_SKILLS := [&"ninth_vessel",&"named_edge",&"twin_inscription",&"wallbreaker_stance",&"erasing_cut",&"ninth_inscription"]
const RUNE_SKILLS := [&"runic_vessel",&"rune_guard",&"blade_rhythm",&"keen_inscription",&"rune_flurry", &"rune_lunge",&"unbroken_edge",&"tempered_might",&"anvil_cleave",&"faultline",&"worldcleaver",
	&"ninth_vessel",&"named_edge",&"twin_inscription",&"wallbreaker_stance",&"erasing_cut",&"ninth_inscription"]
## Each profession owns its Job EXP and skill-point bank (caps 50/80/100).
## และไม่มีเควสล็อกสกิล (rb_rune_5 / rb_rune_7 / ninth_inscription_unlocked เป็นธงเนื้อเรื่องอย่างเดียว)
## เงื่อนไขเรียน = อาชีพ + เลเวลตัวละคร + สกิลก่อนหน้า เหมือนสกิลนักดาบทุกประการ
const RUNE_SKILL_FLAGS := {}   # ว่างไว้ — โค้ดเก่าที่อ้างถึงยังทำงานได้

## Compatibility accessor for the current profession's spendable points.
func rune_point_cap() -> int:
	return PlayerState.stats.max_job_level() - 1

func rune_points() -> int:
	if not PlayerState.is_rune_job(): return 0
	return PlayerState.stats.skill_points

## Rune reset: free once, then 10,000 z; refunds go to each skill's profession.
func reset_runeblade() -> bool:
	if not PlayerState.is_rune_job() or not Game.is_town(PlayerState.current_map_id): return false
	var paid := PlayerState.has_flag(&"rb_reset_used")
	if paid and not PlayerState.spend_zeny(10000):
		Events.say("คืนแต้มฟรีครั้งแรก หลังจากนั้นใช้ 10,000 z")
		return false
	for id in RUNE_SKILLS:
		PlayerState.stats.add_skill_points(profession_of(id),level_of(id))
		learned.erase(id)
	for i in range(HOTKEY_COUNT):
		if hotkeys[i] in RUNE_SKILLS: hotkeys[i] = &""
	PlayerState.set_flag(&"rb_reset_used")
	PlayerState.refresh()
	Events.skills_changed.emit()
	return true

var learned: Dictionary = {}          # StringName -> int (เลเวลสกิล)
var hotkeys: Array = [&"", &"", &"", &""]


func level_of(skill_id: StringName) -> int:
	return int(learned.get(skill_id, 0))


func is_learned(skill_id: StringName) -> bool:
	return level_of(skill_id) > 0


## เช็คว่าเรียนสกิลนี้เพิ่มได้ไหม
func can_learn(skill_id: StringName, stats: PlayerStats) -> bool:
	var s := GameData.get_skill(skill_id)
	if s == null:
		return false
	if stats.points_for(profession_of(skill_id)) <= 0:
		return false
	if level_of(skill_id) >= s.max_level:
		return false
	if stats.level < s.required_level:
		return false
	if not stats.has_profession(profession_of(skill_id)):
		return false
	for req_id in s.required_skills.keys():
		if level_of(StringName(req_id)) < int(s.required_skills[req_id]):
			return false
	return true


## เหตุผลที่เรียนไม่ได้ (เอาไว้โชว์ใน UI)
func learn_blocker(skill_id: StringName, stats: PlayerStats) -> String:
	var s := GameData.get_skill(skill_id)
	if s == null:
		return "ไม่พบสกิล"
	if level_of(skill_id) >= s.max_level:
		return "เลเวลสูงสุดแล้ว"
	if stats.level < s.required_level:
		return "ต้องเลเวล %d" % s.required_level
	if not stats.has_profession(profession_of(skill_id)):
		return "อาชีพนี้เรียนไม่ได้"
	for req_id in s.required_skills.keys():
		var need := int(s.required_skills[req_id])
		if level_of(StringName(req_id)) < need:
			var rs := GameData.get_skill(StringName(req_id))
			var rname: String = rs.display_name if rs != null else String(req_id)
			return "ต้องมี %s เลเวล %d" % [rname, need]
	if stats.points_for(profession_of(skill_id)) <= 0:
		return "ไม่มีแต้มของอาชีพนี้ • แต้มแต่ละอาชีพใช้แทนกันไม่ได้"
	return ""


func learn(skill_id: StringName, stats: PlayerStats) -> bool:
	if not can_learn(skill_id, stats):
		return false
	learned[skill_id] = level_of(skill_id) + 1
	stats.add_skill_points(profession_of(skill_id),-1)
	Events.skills_changed.emit()
	return true


## รีเซ็ตสกิลทั้งหมด คืน skill point ให้ครบ
func reset(stats: PlayerStats) -> void:
	for id in learned:
		stats.add_skill_points(profession_of(id),int(learned[id]))
	learned.clear()
	hotkeys = [&"", &"", &"", &""]
	Events.skills_changed.emit()


func set_hotkey(index: int, skill_id: StringName) -> void:
	if index < 0 or index >= HOTKEY_COUNT:
		return
	# ถ้าสกิลนี้อยู่ปุ่มอื่นอยู่แล้ว ให้เอาออกก่อน
	for i in range(HOTKEY_COUNT):
		if hotkeys[i] == skill_id:
			hotkeys[i] = &""
	hotkeys[index] = skill_id
	Events.skills_changed.emit()


func hotkey_at(index: int) -> StringName:
	if index < 0 or index >= HOTKEY_COUNT:
		return &""
	return hotkeys[index]


## รวมโบนัสจากสกิลพาสซีฟทั้งหมด
func passive_bonus() -> Dictionary:
	var out := {}
	for skill_id in learned.keys():
		var s := GameData.get_skill(StringName(skill_id))
		if s == null or s.type != SkillData.SkillType.PASSIVE:
			continue
		var values := s.passive_values(level_of(StringName(skill_id)))
		for key in values.keys():
			out[StringName(key)] = float(out.get(StringName(key), 0.0)) + float(values[key])
	return out


func to_dict() -> Dictionary:
	var l := {}
	for k in learned.keys():
		l[String(k)] = learned[k]
	var h: Array = []
	for x in hotkeys:
		h.append(String(x))
	return {"learned": l, "hotkeys": h}


func from_dict(d: Dictionary) -> void:
	learned.clear()
	var l: Dictionary = d.get("learned", {})
	for k in l.keys():
		learned[StringName(k)] = int(l[k])
	hotkeys = [&"", &"", &"", &""]
	var h: Array = d.get("hotkeys", [])
	for i in range(mini(h.size(), HOTKEY_COUNT)):
		hotkeys[i] = StringName(h[i])
	Events.skills_changed.emit()
