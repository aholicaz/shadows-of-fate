## GameData — คลังข้อมูลกลาง (Autoload ชื่อ "GameData")
## โหลดไฟล์ .tres ทั้งหมดจากโฟลเดอร์ res://data/ ตอนเปิดเกม
## เพิ่มไอเทม/มอน/สกิลใหม่ = แค่วางไฟล์ .tres ในโฟลเดอร์ ไม่ต้องแก้โค้ดนี้
## หมายเหตุ: ไฟล์นี้ห้ามใส่ class_name เพราะจะชนกับชื่อ Autoload
extends Node

const ITEM_DIR := "res://data/items"
const MONSTER_DIR := "res://data/monsters"
const SKILL_DIR := "res://data/skills"
const JOB_DIR := "res://data/jobs"
const CARD_DIR := "res://data/cards"
const QUEST_DIR := "res://data/quests"

var items: Dictionary = {}      # StringName -> ItemData
var monsters: Dictionary = {}   # StringName -> MonsterData ★ รอบ 90: แคชเฉพาะตัวที่ถูกเรียกใช้แล้ว ★
var skills: Dictionary = {}     # StringName -> SkillData
var jobs: Dictionary = {}       # StringName -> JobData
var cards: Dictionary = {}      # StringName -> CardData (เป็นสับเซ็ตของ items)
var quests: Dictionary = {}     # StringName -> QuestData

# =========================================================
# ★★ รอบ 90 — มอนสเตอร์โหลดตอนใช้จริง ไม่ใช่ตอนเปิดเกม ★★
#
# เดิม `_load_dir(MONSTER_DIR, monsters)` เรียก load() ไฟล์มอนทั้ง 30 ตัวตอนเปิดเกม
# ไฟล์มอนแต่ละตัวอ้าง SpriteFrames ซึ่งอ้างชีทภาพ → **ชีทมอนทุกตัวถูกโหลดขึ้นหน่วยความจำหมด**
# วัดจริงในโปรเจกต์ทดสอบ: หน่วยความจำภาพตอนเปิดเกม 1,511 MB · ปล่อยมอนออก 30 ตัวเหลือ 118 MB
# (โปรเจกต์จริงหนักกว่านั้น — ชีทมอนรวม 319 ล้านพิกเซล = 1,623 MB)
#
# ตอนนี้เก็บแค่ "ชื่อไฟล์" ไว้ก่อน แล้วโหลดตอน get_monster() ถูกเรียกครั้งแรก
# ชื่อไฟล์ต้องตรงกับ id (data/monsters/<id>.tres) — ถ้าไม่ตรงมีทางถอยไล่โหลดทั้งโฟลเดอร์ให้เอง
# =========================================================
var _monster_paths: Dictionary = {}   # StringName -> path
var _monsters_all_loaded := false


func _ready() -> void:
	_load_dir(ITEM_DIR, items)
	_index_monsters()
	_load_dir(SKILL_DIR, skills)
	_load_dir(JOB_DIR, jobs)
	_load_dir(QUEST_DIR, quests)
	# การ์ดสืบทอดจาก ItemData จึงเก็บไว้ในคลังไอเทมด้วย
	_load_dir(CARD_DIR, items)
	for item in items.values():
		if item is CardData:
			cards[StringName(item.id)] = item
	print("[GameData] items=%d (การ์ด %d) monsters=%d (รอเรียก) skills=%d jobs=%d เควส=%d"
		% [items.size(), cards.size(), _monster_paths.size(), skills.size(), jobs.size(), quests.size()])


func _load_dir(path: String, target: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("[GameData] ไม่พบโฟลเดอร์: " + path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if dir.current_is_dir():
			_load_dir(path.path_join(file_name), target)
		else:
			# ตอน export เกม .tres จะกลายเป็น .tres.remap
			var clean := file_name.trim_suffix(".remap")
			if clean.ends_with(".tres") or clean.ends_with(".res"):
				var res := load(path.path_join(clean))
				if res != null and "id" in res:
					target[StringName(res.id)] = res
		file_name = dir.get_next()

	dir.list_dir_end()


# =========================================================
# ตัวช่วยดึงข้อมูล
# =========================================================

func get_item(id: StringName) -> ItemData:
	return items.get(id, null)


func get_quest(id: StringName) -> QuestData:
	return quests.get(id, null)


## เควสทั้งหมด เรียงตามเลเวลที่ต้องใช้
func all_quests() -> Array[QuestData]:
	var out: Array[QuestData] = []
	for q in quests.values():
		out.append(q)
	out.sort_custom(func(a, b): return a.required_level < b.required_level)
	return out


# =========================================================
# ★ มอนสเตอร์ — โหลดตอนใช้จริง (รอบ 90)
# =========================================================

## จำแค่ชื่อไฟล์ ยังไม่ load() — ไม่มีชีทภาพไหนถูกดึงขึ้นหน่วยความจำ
func _index_monsters() -> void:
	var dir := DirAccess.open(MONSTER_DIR)
	if dir == null:
		push_warning("[GameData] ไม่พบโฟลเดอร์: " + MONSTER_DIR)
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir():
			var clean := f.trim_suffix(".remap")
			if clean.ends_with(".tres") or clean.ends_with(".res"):
				_monster_paths[StringName(clean.get_basename())] = MONSTER_DIR.path_join(clean)
		f = dir.get_next()
	dir.list_dir_end()


func get_monster(id: StringName) -> MonsterData:
	if monsters.has(id):
		return monsters[id]
	var path: String = _monster_paths.get(id, "")
	if path == "":
		return null
	var res := load(path)
	if res is MonsterData:
		var m: MonsterData = res
		# ★ กฎของโปรเจกต์: ชื่อไฟล์ต้องเท่ากับ id ★
		# ไม่มี "ทางถอยไล่โหลดทั้งโฟลเดอร์" โดยตั้งใจ — ทางถอยแบบนั้นจะดึงชีทมอนขึ้นมา 1.6 GB
		# ในพริบตาเดียว (เว็บแท็บเด้งทันที) แค่เพราะพิมพ์ id ผิดตัวเดียว
		if m.id != id:
			push_error("[GameData] ชื่อไฟล์ไม่ตรงกับ id: %s.tres มี id = %s → เปลี่ยนชื่อไฟล์เป็น %s.tres"
				% [id, m.id, m.id])
			return null
		monsters[id] = m
		return m
	return null


## บังคับโหลดมอนทุกตัว — ใช้เฉพาะหน้าที่ต้องแสดงรายชื่อทั้งหมด (ห้อง GM · Codex)
## ★ กินหน่วยความจำภาพหลักพัน MB ★ อย่าเรียกตอนเปิดเกม
func load_all_monsters() -> Dictionary:
	if _monsters_all_loaded:
		return monsters
	for mid: StringName in _monster_paths.keys():
		if monsters.has(mid):
			continue
		var res := load(_monster_paths[mid])
		if res is MonsterData:
			var m: MonsterData = res
			monsters[StringName(m.id)] = m
	_monsters_all_loaded = true
	return monsters


## รหัสมอนทุกตัวที่มีไฟล์อยู่ (ไม่ต้องโหลดไฟล์)
func monster_ids() -> Array:
	var out: Array = _monster_paths.keys()
	out.sort()
	return out


## คืนหน่วยความจำของมอนที่ไม่ได้ใช้ในแมพนี้ — เรียกตอนเปลี่ยนแมพ
## keep = รหัสมอนที่แมพใหม่ใช้ (ตัวอื่นจะถูกปล่อย ถ้าไม่มีใครถืออยู่ Godot จะคืนหน่วยความจำให้เอง)
func release_monsters_except(keep: Array) -> int:
	var keep_set := {}
	for k in keep:
		keep_set[StringName(k)] = true
	var dropped := 0
	for mid: StringName in monsters.keys():
		if not keep_set.has(mid):
			monsters.erase(mid)
			dropped += 1
	if dropped > 0:
		_monsters_all_loaded = false
	return dropped


func get_skill(id: StringName) -> SkillData:
	return skills.get(id, null)


func get_job(id: StringName) -> JobData:
	return jobs.get(id, null)


func get_card(id: StringName) -> CardData:
	return cards.get(id, null)


## การ์ดทั้งหมด เรียงตามเลเวลมอนสเตอร์
func all_cards() -> Array[CardData]:
	var out: Array[CardData] = []
	for c: CardData in cards.values():
		out.append(c)
	# ★ รอบ 90 ★ เรียงด้วย sort_level() ไม่ใช่ a.monster().level
	# ของเดิมเรียกไฟล์มอนทุกใบ = เปิดสมุดการ์ดทีเดียวโหลดชีทมอนครบ 30 ตัว (1.6 GB → เว็บเด้ง)
	out.sort_custom(func(a: CardData, b: CardData) -> bool:
		var la: int = a.sort_level()
		var lb: int = b.sort_level()
		if la != lb:
			return la < lb
		return String(a.id) < String(b.id)
	)
	return out


## การ์ดที่ดรอปจากมอนตัวนี้ (ถ้ามี)
func card_of_monster(monster_id: StringName) -> CardData:
	for c: CardData in cards.values():
		if c.monster_id == monster_id:
			return c
	return null


func item_name(id: StringName) -> String:
	var d := get_item(id)
	return d.display_name if d != null else String(id)


## รายชื่อสกิลทั้งหมดของอาชีพหนึ่ง
func skills_for_job(job_id: StringName) -> Array[SkillData]:
	var out: Array[SkillData] = []
	var job := get_job(job_id)
	if job != null and not job.skill_ids.is_empty():
		for sid in job.skill_ids:
			var s := get_skill(sid)
			if s != null:
				out.append(s)
		return out
	# ถ้า JobData ไม่ได้ระบุไว้ ให้กรองจาก SkillData.job_ids แทน
	for s: SkillData in skills.values():
		if s.job_ids.is_empty() or job_id in s.job_ids:
			out.append(s)
	return out
