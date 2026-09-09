## MapAtlas — สมุดแผนที่โลก (รอบ 102)
##
## ที่เดียวที่บอกว่า "แมพไหนอยู่บทไหน · ติดกับแมพไหน · มีมอนอะไร · เลเวลประมาณเท่าไหร่"
## ใช้ 2 ที่:
##   1. หน้า World Map (แท็บ "แผนที่") — โชว์แมพทั้งบท คลิกแล้วเห็นรายชื่อมอน
##   2. เสาวาป — เช็คว่าวาปไปแมพไหนได้ · ไกลกี่ทอด · ค่าวาปเท่าไหร่
##
## ★★ เพิ่มบทใหม่ (บท 4-9) ทำยังไง ★★
## 1. เพิ่ม id แมพใน `Game.MAPS` + `Game.MAP_NAMES` เหมือนเดิม
## 2. เพิ่ม 1 บรรทัดใน `MAPS` ข้างล่างนี้: chapter · kind · level · monsters · links
## 3. เพิ่มชื่อบทใน `CHAPTER_NAMES`
## เท่านั้น — หน้าแผนที่จะแบ่งหน้าให้เองตามจำนวนบท และเสาวาปจะคิดระยะ/ราคาให้เอง
##
## ★ ข้อมูลนี้มาจากไฟล์ฉากจริง ★ (ตัวสร้างมอนใน scenes/maps/*.tscn และประตูวาปในนั้น)
## ถ้าแก้ฉากแล้วมอน/ประตูเปลี่ยน ให้มาแก้ตารางนี้ตามด้วย
## (เทสต์ r102 มีข้อที่เตือนถ้าตารางกับ Game.MAPS ไม่ตรงกัน)
class_name MapAtlas
extends RefCounted

## ชนิดแมพ — ใช้เลือกสี/ไอคอนบนแผนที่โลก
const KIND_TOWN := "town"       # เมือง (ไม่มีมอน · ร้านค้า/NPC)
const KIND_FIELD := "field"     # ทุ่ง/ป่า/ถ้ำ ปกติ
const KIND_BOSS := "boss"       # ลานบอส
const KIND_HIDDEN := "hidden"   # ห้องทดสอบ ไม่โชว์บนแผนที่โลก

const CHAPTER_NAMES := {
	1: "บทที่ 1 — มิดการ์ด",
	2: "บทที่ 2 — สวาร์ทัลฟ์เฮม",
	3: "บทที่ 3 — วานาเฮม",
}

## ★ ตารางหลัก ★  chapter · kind · level (ช่วงเลเวลมอน) · monsters · links (แมพที่ติดกัน)
const MAPS := {
	# ---------- บทที่ 1 — มิดการ์ด ----------
	&"prontera_town": {
		"chapter": 1, "kind": KIND_TOWN, "level": [0, 0], "monsters": [],
		"links": [&"prontera_field"],
	},
	&"prontera_field": {
		"chapter": 1, "kind": KIND_FIELD, "level": [1, 6],
		"monsters": [&"poring", &"drops", &"fabre"],
		"links": [&"prontera_town", &"asgard_forest_2"],
	},
	&"asgard_forest_2": {
		"chapter": 1, "kind": KIND_FIELD, "level": [6, 14],
		"monsters": [&"chonchon", &"drops", &"king_poring", &"wolf"],
		"links": [&"prontera_field", &"dark_forest"],
	},
	&"dark_forest": {
		"chapter": 1, "kind": KIND_FIELD, "level": [12, 20],
		"monsters": [&"lunatic", &"hornet", &"wolf"],
		"links": [&"asgard_forest_2", &"dark_forest_2", &"thunder_scar"],
	},
	&"thunder_scar": {
		"chapter": 1, "kind": KIND_BOSS, "level": [25, 30],
		"monsters": [&"stormscar"],
		"links": [&"dark_forest"],
	},
	&"dark_forest_2": {
		"chapter": 1, "kind": KIND_FIELD, "level": [20, 28],
		"monsters": [&"munak", &"orc_warrior", &"baphomet_jr", &"baphomet"],
		"links": [&"dark_forest", &"iron_road"],
	},

	# ---------- บทที่ 2 — สวาร์ทัลฟ์เฮม ----------
	&"iron_road": {
		"chapter": 2, "kind": KIND_FIELD, "level": [28, 34],
		"monsters": [&"pitman", &"steel_beetle"],
		"links": [&"dark_forest_2", &"nidavellir_town"],
	},
	&"nidavellir_town": {
		"chapter": 2, "kind": KIND_TOWN, "level": [0, 0], "monsters": [],
		"links": [&"iron_road", &"ember_mine"],
	},
	&"ember_mine": {
		"chapter": 2, "kind": KIND_FIELD, "level": [32, 38],
		"monsters": [&"ember_bat", &"magma_slug"],
		"links": [&"nidavellir_town", &"hall_of_silence"],
	},
	&"hall_of_silence": {
		"chapter": 2, "kind": KIND_FIELD, "level": [36, 44],
		"monsters": [&"forge_golem", &"rune_watcher", &"silent_wraith"],
		"links": [&"ember_mine", &"cold_forge"],
	},
	&"cold_forge": {
		"chapter": 2, "kind": KIND_BOSS, "level": [44, 50],
		"monsters": [&"forge_guardian"],
		"links": [&"hall_of_silence", &"root_road"],
	},

	# ---------- บทที่ 3 — วานาเฮม ----------
	&"root_road": {
		"chapter": 3, "kind": KIND_FIELD, "level": [39, 43],
		"monsters": [&"root_crawler", &"thorn_hound"],
		"links": [&"cold_forge", &"vanir_town"],
	},
	&"vanir_town": {
		"chapter": 3, "kind": KIND_TOWN, "level": [0, 0], "monsters": [],
		"links": [&"root_road", &"silver_marsh"],
	},
	&"silver_marsh": {
		"chapter": 3, "kind": KIND_FIELD, "level": [44, 48],
		"monsters": [&"mist_sprite", &"bog_lurker"],
		"links": [&"vanir_town", &"withered_grove"],
	},
	&"withered_grove": {
		"chapter": 3, "kind": KIND_FIELD, "level": [49, 54],
		"monsters": [&"withered_treant", &"vanir_sentinel"],
		"links": [&"silver_marsh", &"forgotten_battlefield"],
	},
	&"forgotten_battlefield": {
		"chapter": 3, "kind": KIND_FIELD, "level": [55, 58],
		"monsters": [&"war_wraith", &"thorn_matriarch"],
		"links": [&"withered_grove", &"spring_of_life"],
	},
	&"spring_of_life": {
		"chapter": 3, "kind": KIND_BOSS, "level": [60, 60],
		"monsters": [&"gullveig_ember"],
		"links": [&"forgotten_battlefield"],
	},

	# ---------- ไม่โชว์บนแผนที่โลก ----------
	&"gm_room": {
		"chapter": 0, "kind": KIND_HIDDEN, "level": [0, 0], "monsters": [], "links": [],
	},
}

# =========================================================
# ★★ ค่าวาปของเสาวาป ★★
# =========================================================
## ค่าวาปขั้นต้น (แมพที่ใกล้สุดเท่าที่วาปได้ = ห่าง 2 ทอด)
const WARP_BASE_COST := 2000
## ไกลขึ้นทุก 1 ทอด บวกเท่านี้
const WARP_COST_PER_HOP := 1600
## เพดานค่าวาป
const WARP_MAX_COST := 25000
## ★ ต้องห่างอย่างน้อยกี่ทอดถึงจะวาปได้ ★ 2 = "เว้นแมพที่ติดกัน" (เดินเอาสิ อยู่ข้าง ๆ เอง)
const WARP_MIN_HOPS := 2


static func has(map_id: StringName) -> bool:
	return MAPS.has(map_id)


static func info(map_id: StringName) -> Dictionary:
	return MAPS.get(map_id, {})


static func chapter_of(map_id: StringName) -> int:
	return int(info(map_id).get("chapter", 0))


static func kind_of(map_id: StringName) -> String:
	return String(info(map_id).get("kind", KIND_FIELD))


static func level_range(map_id: StringName) -> Array:
	var lv: Array = info(map_id).get("level", [0, 0])
	return lv if lv.size() >= 2 else [0, 0]


static func monsters_of(map_id: StringName) -> Array:
	return info(map_id).get("monsters", [])


static func links_of(map_id: StringName) -> Array:
	return info(map_id).get("links", [])


## บททั้งหมดที่มีแมพอยู่จริง เรียงจากน้อยไปมาก (ไม่รวมบท 0 = ห้องทดสอบ)
static func chapters() -> Array:
	var seen: Dictionary = {}
	for mid in MAPS.keys():
		var c := chapter_of(mid)
		if c > 0:
			seen[c] = true
	var out: Array = seen.keys()
	out.sort()
	return out


static func chapter_name(no: int) -> String:
	return String(CHAPTER_NAMES.get(no, "บทที่ %d" % no))


## แมพในบทนั้น (เรียงตามลำดับที่ประกาศไว้ใน MAPS = ลำดับการเดินทางจริง)
static func maps_of_chapter(no: int) -> Array:
	var out: Array = []
	for mid in MAPS.keys():
		if chapter_of(mid) == no and kind_of(mid) != KIND_HIDDEN:
			out.append(mid)
	return out


# =========================================================
# ระยะทาง (นับ "ทอด" = ต้องผ่านประตูกี่บาน) — BFS บนเส้นเชื่อมของแมพ
# =========================================================
## −1 = ไปไม่ถึง (คนละเกาะ)
static func hops(from_id: StringName, to_id: StringName) -> int:
	if from_id == to_id:
		return 0
	if not has(from_id) or not has(to_id):
		return -1
	var dist: Dictionary = {from_id: 0}
	var queue: Array = [from_id]
	var head := 0
	while head < queue.size():
		var cur: StringName = queue[head]
		head += 1
		var d: int = dist[cur]
		for nxt in links_of(cur):
			var n := StringName(nxt)
			if dist.has(n):
				continue
			dist[n] = d + 1
			if n == to_id:
				return d + 1
			queue.append(n)
	return -1


## ค่าวาปจาก a ไป b (บาท/เซนี) — 0 = วาปไม่ได้
static func warp_cost(from_id: StringName, to_id: StringName) -> int:
	var h := hops(from_id, to_id)
	if h < WARP_MIN_HOPS:
		return 0
	return mini(WARP_MAX_COST, WARP_BASE_COST + (h - WARP_MIN_HOPS) * WARP_COST_PER_HOP)


# =========================================================
# เงื่อนไขปลดล็อกปลายทาง
# =========================================================
## เคยไปแมพนี้แล้วหรือยัง (ธง visited_map_<id> ตั้งตอนเข้าแมพ — ดู MapBase._ready)
static func visited_flag(map_id: StringName) -> StringName:
	return StringName("visited_map_" + String(map_id))


static func is_visited(map_id: StringName) -> bool:
	return PlayerState.has_flag(visited_flag(map_id))


## ★ ฆ่ามอนในแมพนี้ครบทุกชนิดแล้วหรือยัง ★ (เมืองไม่มีมอน = ถือว่าเคลียร์แล้ว)
static func is_cleared(map_id: StringName) -> bool:
	var list: Array = monsters_of(map_id)
	if list.is_empty():
		return true
	for mid in list:
		if PlayerState.kill_count(StringName(mid)) <= 0:
			return false
	return true


## ฆ่าไปกี่ชนิดจากทั้งหมดกี่ชนิด (เอาไว้โชว์ "3/4" บนหน้าแผนที่)
static func clear_progress(map_id: StringName) -> Array:
	var list: Array = monsters_of(map_id)
	var got := 0
	for mid in list:
		if PlayerState.kill_count(StringName(mid)) > 0:
			got += 1
	return [got, list.size()]


## ★★ ปลายทางที่เสาวาปในแมพ from_id ยอมให้ไป ★★
## คืน Array ของ { id, name, hops, cost, ok, why }
##   ok = ไปได้เลย · why = เหตุผลที่ยังไปไม่ได้ (เอาไว้โชว์เป็นข้อความจาง ๆ)
static func warp_destinations(from_id: StringName) -> Array:
	var out: Array = []
	for mid in MAPS.keys():
		var id := StringName(mid)
		if id == from_id or kind_of(id) == KIND_HIDDEN:
			continue
		var h := hops(from_id, id)
		if h < WARP_MIN_HOPS:
			continue                      # ★ เว้นแมพที่ติดกัน ★ (และแมพที่ไปไม่ถึง h = −1)
		var cost := warp_cost(from_id, id)
		var why := ""
		if not is_visited(id):
			why = "ยังไม่เคยไปถึง"
		elif not is_cleared(id):
			var p := clear_progress(id)
			why = "ล่ามอนยังไม่ครบ (%d/%d ชนิด)" % [p[0], p[1]]
		elif PlayerState.zeny < cost:
			why = "เงินไม่พอ"
		out.append({
			"id": id, "name": Game.map_display_name(id),
			"hops": h, "cost": cost, "ok": why == "", "why": why,
		})
	out.sort_custom(func(a, b): return int(a["cost"]) < int(b["cost"]))
	return out
