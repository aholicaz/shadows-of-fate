## EquipSets — ★ รอบ 158 ★ ชุดเซ็ตอุปกรณ์ (บทละ 1 ชุด · 4 ชิ้น · ใส่ครบ 2/3/4 ชิ้นได้โบนัสเพิ่ม)
##
## ตามแผนรอบ 128: โบนัสลดลงครึ่งหนึ่งจากร่างแรก · ไม่มีดูดเลือด/ดูดมานา
## ชิ้น ★ = ชิ้นที่คราฟต์ได้ที่ช่างเหล็ก (ปิดเซ็ต) · ชิ้นอื่นดรอป/ร้านตามเดิม
## คีย์โบนัสใช้ชุดเดียวกับ CardAlbum (atk def mdef hit flee crit max_hp max_sp str agi vit int dex luk
##   + *_percent) — รวมเข้า PlayerState.refresh() · แก้ตัวเลขที่ตาราง SETS ที่เดียว
## โบนัสขั้นสูงรวมขั้นต่ำด้วย (ใส่ 4 ชิ้น = ได้ทั้งโบนัส 2 + 3 + 4)
class_name EquipSets
extends RefCounted

const SETS := [
	{"id": &"set_c1_wolf", "chapter": 1, "name": "ชุดนักล่าหมาป่า",
		"pieces": [&"leather_cap", &"leather_jacket", &"wolf_cloak", &"boots"],
		"bonus": {2: {&"flee": 3}, 3: {&"agi": 2, &"aspd_percent": 2.0}, 4: {&"atk": 8, &"max_hp": 80}}},
	{"id": &"set_c2_forge", "chapter": 2, "name": "ชุดช่างเหล็กคนแคระ",
		"pieces": [&"iron_helm", &"chain_mail", &"iron_greaves", &"belt"],
		"bonus": {2: {&"def": 4}, 3: {&"vit": 2, &"max_hp": 120}, 4: {&"skill_damage_percent": 3.0, &"def_percent": 3.0}}},
	{"id": &"set_c3_vanir", "chapter": 3, "name": "ชุดรากวานีร์",
		"pieces": [&"bark_armor", &"mist_cloak", &"root_boots", &"thorn_shield"],
		"bonus": {2: {&"max_hp": 150}, 3: {&"agi": 3, &"flee": 6}, 4: {&"atk": 15, &"aspd_percent": 3.0}}},
	{"id": &"set_c4_jotun", "chapter": 4, "name": "ชุดยักษ์น้ำแข็ง",
		"pieces": [&"jotun_helm", &"frost_wolf_coat", &"mammoth_wool_cloak", &"troll_boots"],
		"bonus": {2: {&"str": 2}, 3: {&"vit": 3, &"max_hp": 300}, 4: {&"atk": 25, &"crit_damage_percent": 4.0}}},
	{"id": &"set_c5_ljosalf", "chapter": 5, "name": "ชุดแสงลโยซาลฟ์",
		"pieces": [&"ljosalf_circlet", &"elven_plate", &"moth_wing_cape", &"silent_step"],
		"bonus": {2: {&"max_sp": 60}, 3: {&"agi": 3, &"crit": 3}, 4: {&"atk": 35, &"skill_damage_percent": 4.0}}},
	{"id": &"set_c6_ferry", "chapter": 6, "name": "ชุดผู้ข้ามฝั่งเฮล",
		"pieces": [&"drowned_crown", &"hel_half_plate", &"mist_shroud", &"river_walker"],
		"bonus": {2: {&"mdef": 8}, 3: {&"vit": 4, &"max_hp": 500}, 4: {&"atk": 45, &"def_percent": 5.0}}},
	{"id": &"set_c7_oathbreak", "chapter": 7, "name": "ชุดผู้ก้าวพ้นคำสั่ง",
		"pieces": [&"c7_oracle_circlet", &"c7_ash_plate", &"cinderward_coat", &"oathstep_boots"],
		"bonus": {2: {&"max_hp": 300}, 3: {&"str": 4, &"dex": 4}, 4: {&"atk": 60, &"skill_damage_percent": 5.0, &"crit_damage_percent": 5.0}}},
]
## ชิ้นที่คราฟต์ได้ (★) — ใช้โชว์ในรายละเอียด
const CRAFT_PIECES := [&"wolf_cloak", &"iron_greaves", &"belt", &"root_boots", &"thorn_shield",
	&"mammoth_wool_cloak", &"elven_plate", &"mist_shroud", &"hel_half_plate", &"oathstep_boots"]


## เซ็ตที่ไอเทมนี้อยู่ ({} = ไม่อยู่ในเซ็ตไหน)
static func set_of(item_id: StringName) -> Dictionary:
	for s: Dictionary in SETS:
		if (s["pieces"] as Array).has(item_id):
			return s
	return {}


## id ไอเทมที่สวมอยู่ทั้งหมด (ของซ้ำนับครั้งเดียว)
static func equipped_ids(equipment: Equipment) -> Dictionary:
	var out: Dictionary = {}
	if equipment == null:
		return out
	for slot in equipment.slots.keys():
		var inst: ItemInstance = equipment.slots[slot]
		if inst != null:
			out[inst.item_id] = true
	return out


## ใส่ชิ้นของเซ็ตนี้อยู่กี่ชิ้น
static func count_worn(s: Dictionary, worn: Dictionary) -> int:
	var n := 0
	for pid in s["pieces"]:
		if worn.has(pid):
			n += 1
	return n


## รวมโบนัสเซ็ตทั้งหมดจากของที่สวมอยู่
static func total(equipment: Equipment) -> Dictionary:
	var out: Dictionary = {}
	var worn := equipped_ids(equipment)
	for s: Dictionary in SETS:
		var n := count_worn(s, worn)
		var bonus: Dictionary = s["bonus"]
		for need in bonus.keys():
			if n >= int(need):
				var b: Dictionary = bonus[need]
				for k in b.keys():
					out[k] = float(out.get(k, 0.0)) + float(b[k])
	return out


## ข้อความ BBCode สำหรับหน้ารายละเอียดไอเทม (ว่าง = ไม่ใช่ชิ้นเซ็ต)
static func describe_for_item(item_id: StringName, equipment: Equipment) -> String:
	var s := set_of(item_id)
	if s.is_empty():
		return ""
	var worn := equipped_ids(equipment)
	var n := count_worn(s, worn)
	var pieces: Array = s["pieces"]
	var lines: Array[String] = []
	lines.append("[color=#e0cc93]◆ %s (%d/%d ชิ้น)[/color]" % [String(s["name"]), n, pieces.size()])
	var names: Array[String] = []
	for pid in pieces:
		var nm := GameData.item_name(pid)
		if pid in CRAFT_PIECES:
			nm += "★"
		names.append(("[color=#7dffa8]%s[/color]" if worn.has(pid) else "[color=#7b8496]%s[/color]") % nm)
	lines.append("  " + " · ".join(names))
	var bonus: Dictionary = s["bonus"]
	var keys := bonus.keys()
	keys.sort()
	for need in keys:
		var on := n >= int(need)
		lines.append("  [color=%s]%d ชิ้น : %s%s[/color]" % ["#7dffa8" if on else "#7b8496", int(need), CardAlbum.describe(bonus[need]), "  ✓" if on else ""])
	return "\n".join(lines)
