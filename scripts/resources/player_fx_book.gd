## PlayerFXBook — "สมุดเอฟเฟกต์ของผู้เล่น" (รอบ 103)
##
##   ┌─ สมุดเอฟเฟกต์ผู้เล่น ────────────────────────────────┐
##   │  ท่าที่กำลังปรับ   [ Attack 1 (ไม้แรก)        ▾ ]   │  ← ดรอปดาวน์เลือกท่า
##   │  ─────────────────────────────────────────────────  │
##   │  ★ Attack 1 (ไม้แรก) ★                              │
##   │  ใช้ค่าจากสมุดนี้    [x]                             │
##   │  ภาพชุด             [ 5 ]                           │
##   │  เล่นย้อนเฟรม       [ ]                             │
##   │  องศาที่ชี้          [ 45 ]                          │
##   │  ขนาด (px)          [ 250 ]                         │
##   │  จุดเกิด            [ 86 , −22 ]                     │
##   │  พุ่งไปข้างหน้า      [ 34 ]                           │
##   └─────────────────────────────────────────────────────┘
##
## ★★ ทำงานยังไง ★★
## Inspector ปกติจะโชว์ทุกช่องพร้อมกัน (11 ท่า × 15 ช่อง = 165 ช่อง เลื่อนหาไม่ไหว)
## ไฟล์นี้ใช้ `_get_property_list()` + `_get()/_set()` สร้าง "ช่องเงา" ขึ้นมาเฉพาะท่าที่เลือก
## แล้วอ่าน/เขียนทะลุไปที่ `PlayerSkillFX` ของท่านั้นจริง ๆ
## → เห็นทีละท่า แต่ค่าถูกเก็บครบทุกท่าในไฟล์เดียว
##
## ★★ ท่าไหนใช้ระบบไหน ★★
##   · Attack 1/2/3     → ภาพชุด Alternative 3 (รอบ 101) — โชว์ช่อง ภาพชุด/องศา/ขนาด/พุ่ง
##   · สกิลที่มี .tres   → SkillEffect เดิม — โชว์ช่อง SpriteFrames/สูง/สเกล/ความเร็ว/หน่วง/ชั้น
## สมุดโชว์เฉพาะชุดที่ตรงกับท่าที่เลือก
##
## ★★ เพิ่มท่าใหม่ ★★ เติม 1 บรรทัดใน `SLOTS` ข้างล่าง (สกิลใหม่ใช้ kind = KIND_SKILL
## แล้วใส่ id ให้ตรงกับชื่อไฟล์ใน data/skills/) — ดรอปดาวน์จะมีให้เลือกเองทันที
##
## ★★ ต้องเป็น @tool ★★ ไม่งั้น Inspector จะไม่เรียก `_get_property_list()` เลย
## (สคริปต์ธรรมดาทำงานแค่ตอนเล่นเกม) — ดรอปดาวน์กับช่องเงาจะไม่โผล่
@tool
class_name PlayerFXBook
extends Resource

const KIND_COMBO := "combo"     # ไม้ 1/2/3 — ระบบภาพชุด
const KIND_SKILL := "skill"     # สกิลที่มี .tres — ระบบ SkillEffect

## ★ รายชื่อท่าในดรอปดาวน์ ★ (เรียงตามที่อยากให้โชว์)
const SLOTS := [
	{"key": &"attack_1", "label": "Attack 1 (ไม้แรก)",  "kind": KIND_COMBO, "step": 0},
	{"key": &"attack_2", "label": "Attack 2 (ไม้สอง)",  "kind": KIND_COMBO, "step": 1},
	{"key": &"attack_3", "label": "Attack 3 (ไม้สาม)",  "kind": KIND_COMBO, "step": 2},
	{"key": &"magnum_break", "label": "Rending Wave (คลื่นดาบเปิดแผล)", "kind": KIND_SKILL},
	{"key": &"slash",        "label": "Slash (พุ่งฟัน)",           "kind": KIND_SKILL},
	{"key": &"bash",         "label": "Bash (ฟันแรง)",             "kind": KIND_SKILL},
	{"key": &"battle_cry",   "label": "Battle Cry (คำรามศึก)",     "kind": KIND_SKILL},
	{"key": &"endure",       "label": "Endure (อดทน)",             "kind": KIND_SKILL},
	{"key": &"first_aid",    "label": "First Aid (ปฐมพยาบาล)",     "kind": KIND_SKILL},
	{"key": &"hp_recovery",  "label": "HP Recovery (ฟื้นฟูร่างกาย)", "kind": KIND_SKILL},
	{"key": &"sword_mastery", "label": "Sword Mastery (เชี่ยวชาญดาบ)", "kind": KIND_SKILL},
]

## ป้ายของช่อง "ใช้ค่าจากสมุดนี้"
const USE_BOOK_LABEL := "★ ใช้ค่าจากสมุดนี้ ★"

## ช่องที่โชว์ของท่าแบบ "ไม้คอมโบ" — [ชื่อตัวแปรใน PlayerSkillFX, ป้าย, ชนิด, hint, hint_string]
const COMBO_FIELDS := [
	["crescent_enabled", "เสี้ยวแสงและประกาย", TYPE_BOOL, PROPERTY_HINT_NONE, ""],
	["crescent_span", "ความกว้างวงกวาด", TYPE_FLOAT, PROPERTY_HINT_RANGE, "0.7,1.6,0.05"],
	["crescent_width", "ความหนาเสี้ยวแสง", TYPE_FLOAT, PROPERTY_HINT_RANGE, "0.5,2,0.05"],
	["crescent_direction", "ทิศกวาด (-1 หรือ 1)", TYPE_FLOAT, PROPERTY_HINT_RANGE, "-1,1,2"],
	["white_mask", "รอยฟันสีขาว", TYPE_BOOL, PROPERTY_HINT_NONE, ""],
	["track_animation", "ท่าที่ผูกเฟรมดาบ", TYPE_STRING_NAME, PROPERTY_HINT_NONE, ""],
	["blade_positions", "ตำแหน่งใบดาบรายเฟรม", TYPE_PACKED_VECTOR2_ARRAY, PROPERTY_HINT_NONE, ""],
	["blade_angles", "มุมใบดาบรายเฟรม", TYPE_PACKED_FLOAT32_ARRAY, PROPERTY_HINT_NONE, ""],
	["blade_opacity", "ความเข้มรายเฟรม", TYPE_PACKED_FLOAT32_ARRAY, PROPERTY_HINT_NONE, ""],
	# ★★ 3 ช่องแรก = "เอาภาพมาจากไหน" ★★ ใส่อันบนสุดที่มีค่า (SpriteFrames > โฟลเดอร์ > ภาพชุด)
	["frames", "★ ใส่ภาพเอฟเฟกต์เอง (SpriteFrames) ★", TYPE_OBJECT,
		PROPERTY_HINT_RESOURCE_TYPE, "SpriteFrames"],
	["custom_dir", "★ หรือชี้โฟลเดอร์ภาพเอง ★", TYPE_STRING, PROPERTY_HINT_DIR, ""],
	["anim", "ชื่อท่าใน SpriteFrames (เว้นว่าง = ท่าแรก)", TYPE_STRING_NAME, PROPERTY_HINT_NONE, ""],
	["sheet_set", "ภาพชุดที่แถมมา (1-5)", TYPE_INT, PROPERTY_HINT_RANGE, "1,5,1"],
	["sheet_reversed", "เล่นย้อนเฟรม", TYPE_BOOL, PROPERTY_HINT_NONE, ""],
	["aim_deg", "องศาที่ชี้ (บวก = ก้มลง)", TYPE_FLOAT, PROPERTY_HINT_RANGE, "-180,180,1"],
	["size_px", "ขนาดบนจอ (px)", TYPE_FLOAT, PROPERTY_HINT_RANGE, "40,600,1"],
	["offset", "จุดเกิด (x = ข้างหน้า)", TYPE_VECTOR2, PROPERTY_HINT_NONE, ""],
	["travel", "พุ่งไปข้างหน้า (px)", TYPE_FLOAT, PROPERTY_HINT_RANGE, "0,200,1"],
	["tint", "สีคูณ", TYPE_COLOR, PROPERTY_HINT_NONE, ""],
	["additive", "บวกแสงลงฉาก (เรืองแสง)", TYPE_BOOL, PROPERTY_HINT_NONE, ""],
]

## ช่องที่โชว์ของท่าแบบ "สกิล"
const SKILL_FIELDS := [
	["frames", "ภาพเอฟเฟกต์ (SpriteFrames)", TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "SpriteFrames"],
	["anim", "ชื่อท่าในภาพชุด", TYPE_STRING_NAME, PROPERTY_HINT_NONE, ""],
	["offset", "จุดเกิด (x = ข้างหน้า)", TYPE_VECTOR2, PROPERTY_HINT_NONE, ""],
	["height", "สูงบนจอ (px · 0 = ใช้สเกล)", TYPE_FLOAT, PROPERTY_HINT_RANGE, "0,900,1"],
	["scale", "สเกล", TYPE_FLOAT, PROPERTY_HINT_RANGE, "0.05,6,0.05"],
	["speed", "พุ่งออกไป (px/วินาที)", TYPE_FLOAT, PROPERTY_HINT_RANGE, "0,2000,10"],
	["follow", "เกาะไปกับตัวละคร", TYPE_BOOL, PROPERTY_HINT_NONE, ""],
	["life", "อยู่บนจอ (วินาที · 0 = จนจบท่า)", TYPE_FLOAT, PROPERTY_HINT_RANGE, "0,10,0.05"],
	["delay", "หน่วงก่อนโผล่ (วินาที)", TYPE_FLOAT, PROPERTY_HINT_RANGE, "0,5,0.01"],
	["z", "ชั้นการวาด", TYPE_INT, PROPERTY_HINT_RANGE, "-100,200,1"],
	["tint", "สีคูณ", TYPE_COLOR, PROPERTY_HINT_NONE, ""],
]

## ★ ตัวแปรจริงต้องขึ้นต้นด้วย _ ★
## ถ้าตั้งชื่อว่า `entries` / `editing` ตรง ๆ Godot จะเขียนลงตัวแปรนั้นเองโดย **ไม่เรียก `_set()`**
## → `notify_property_list_changed()` ไม่ถูกเรียก · เปลี่ยนดรอปดาวน์แล้วช่องข้างล่างไม่สลับตาม
## ค่าของทุกท่า: key -> PlayerSkillFX
var _entries: Dictionary = {}
## ท่าที่กำลังปรับอยู่ (index ใน SLOTS)
var _editing: int = 0


# =========================================================
# ตัวช่วยอ่านค่า (เกมเรียกใช้)
# =========================================================
static func slot_index(key: StringName) -> int:
	for i in range(SLOTS.size()):
		if SLOTS[i]["key"] == key:
			return i
	return -1


static func slot_labels() -> PackedStringArray:
	var out := PackedStringArray()
	for s in SLOTS:
		out.append(String(s["label"]))
	return out


## คีย์ของไม้คอมโบลำดับที่ step (0/1/2) — เกินจากนั้นคืน &""
static func combo_key(step: int) -> StringName:
	for s in SLOTS:
		if s["kind"] == KIND_COMBO and int(s.get("step", -1)) == step:
			return s["key"]
	return &""


## ค่าของท่านี้ (สร้างให้เองถ้ายังไม่มี) — ไม่เคยคืน null
func entry(key: StringName) -> PlayerSkillFX:
	var fx: PlayerSkillFX = _entries.get(key, null)
	if fx == null:
		fx = PlayerSkillFX.new()
		_apply_defaults(key, fx)
		_entries[key] = fx
	return fx


## ★ ค่าที่ "เปิดใช้" แล้วเท่านั้น ★ ไม่เปิด = คืน null (ผู้เรียกใช้ค่าเดิมของตัวเองต่อ)
func active(key: StringName) -> PlayerSkillFX:
	var fx: PlayerSkillFX = _entries.get(key, null)
	if fx != null and fx.use_book:
		return fx
	return null


func kind_of(key: StringName) -> String:
	var i := slot_index(key)
	return String(SLOTS[i]["kind"]) if i >= 0 else KIND_SKILL


## ค่าตั้งต้นตอนสร้างช่องใหม่ — ไม้คอมโบใช้ค่าเดียวกับที่ Player ตั้งไว้ในรอบ 101
func _apply_defaults(key: StringName, fx: PlayerSkillFX) -> void:
	match key:
		&"attack_1":
			fx.sheet_set = 5
			fx.aim_deg = 45.0
			fx.size_px = 250.0
			fx.offset = Vector2(86.0, -22.0)
		&"attack_2":
			fx.sheet_set = 2
			fx.sheet_reversed = true
			fx.aim_deg = 0.0
			fx.size_px = 300.0
			fx.offset = Vector2(70.0, -40.0)
		&"attack_3":
			fx.sheet_set = 4
			fx.aim_deg = 55.0
			fx.size_px = 340.0
			fx.offset = Vector2(116.0, 2.0)
		_:
			# สกิล: ดึงค่าเดิมจาก .tres ของมันมาเป็นจุดตั้งต้น จะได้ไม่ต้องกรอกใหม่ทั้งหมด
			# ★ โหลดจากพาธตรง ๆ ไม่ผ่าน GameData ★ เพราะโค้ดนี้รันใน editor ด้วย (@tool)
			# แต่ autoload อย่าง GameData ไม่ทำงานใน editor → เรียกแล้วพัง
			var path := "res://data/skills/%s.tres" % String(key)
			if ResourceLoader.exists(path):
				fx.copy_from_skill(load(path) as SkillData)


# =========================================================
# ★★ หัวใจ — สร้าง "ช่องเงา" ให้ Inspector โชว์เฉพาะท่าที่เลือก ★★
# =========================================================
func _get_property_list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	# เก็บ entries ลงไฟล์ แต่ไม่ต้องโชว์เป็น Dictionary ดิบ
	out.append({
		"name": "entries", "type": TYPE_DICTIONARY,
		"usage": PROPERTY_USAGE_STORAGE,
	})

	out.append({
		"name": "สมุดเอฟเฟกต์ผู้เล่น", "type": TYPE_NIL,
		"usage": PROPERTY_USAGE_CATEGORY,
	})
	out.append({
		"name": "editing", "type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(Array(slot_labels())),
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE,
	})

	var slot := _current_slot()
	if slot.is_empty():
		return out
	var key: StringName = slot["key"]
	var kind := String(slot["kind"])

	out.append({
		"name": "★ %s ★" % String(slot["label"]), "type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP, "hint_string": "fx/",
	})
	# ★★ ป้ายเป็นภาษาไทย ★★ Inspector เอา "ชื่อ property" มาโชว์ตรง ๆ (แปลงเป็น Title Case)
	# → ถ้าตั้งชื่อว่า fx/sheet_set จะโชว์ "Sheet Set" อ่านไม่รู้เรื่อง
	# จึงตั้งชื่อ property เป็นข้อความไทยไปเลย แล้วค่อยแปลงกลับเป็นชื่อตัวแปรจริงใน _get/_set
	# (ช่องพวกนี้เป็น EDITOR อย่างเดียว ไม่ได้เก็บลงไฟล์ ชื่อจึงเปลี่ยนได้อิสระ)
	out.append({
		"name": "fx/" + USE_BOOK_LABEL, "type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_EDITOR,
	})

	for f in (COMBO_FIELDS if kind == KIND_COMBO else SKILL_FIELDS):
		out.append({
			"name": "fx/" + String(f[1]),
			"type": f[2],
			"hint": f[3],
			"hint_string": f[4],
			"usage": PROPERTY_USAGE_EDITOR,
		})
	return out


## แปลงป้ายไทยบน Inspector กลับเป็นชื่อตัวแปรจริงใน PlayerSkillFX (ไม่รู้จัก = "")
func _field_of(label: String) -> String:
	if label == USE_BOOK_LABEL:
		return "use_book"
	for f in COMBO_FIELDS:
		if String(f[1]) == label:
			return String(f[0])
	for f in SKILL_FIELDS:
		if String(f[1]) == label:
			return String(f[0])
	return ""


func _get(property: StringName) -> Variant:
	var name := String(property)
	if name == "entries":
		return _entries
	if name == "editing":
		return _editing
	if not name.begins_with("fx/"):
		return null
	var slot := _current_slot()
	if slot.is_empty():
		return null
	var field := _field_of(name.substr(3))
	if field == "":
		return null
	return entry(slot["key"]).get(field)


func _set(property: StringName, value: Variant) -> bool:
	var name := String(property)
	if name == "entries":
		_entries = value if value is Dictionary else {}
		return true
	if name == "editing":
		_editing = clampi(int(value), 0, SLOTS.size() - 1)
		# ★ ต้องสั่งให้ Inspector วาดใหม่ ★ ไม่งั้นเปลี่ยนดรอปดาวน์แล้วช่องข้างล่างยังเป็นของท่าเดิม
		notify_property_list_changed()
		return true
	if not name.begins_with("fx/"):
		return false
	var slot := _current_slot()
	if slot.is_empty():
		return false
	var field := _field_of(name.substr(3))
	if field == "":
		return false
	entry(slot["key"]).set(field, value)
	emit_changed()      # บอกว่าไฟล์เปลี่ยนแล้ว (Ctrl+S จะเซฟให้)
	return true


func _property_can_revert(property: StringName) -> bool:
	return String(property).begins_with("fx/")


func _property_get_revert(property: StringName) -> Variant:
	var slot := _current_slot()
	if slot.is_empty():
		return null
	var field := _field_of(String(property).substr(3))
	if field == "":
		return null
	var fresh := PlayerSkillFX.new()
	_apply_defaults(slot["key"], fresh)
	return fresh.get(field)


func _current_slot() -> Dictionary:
	var i := clampi(_editing, 0, SLOTS.size() - 1)
	return SLOTS[i] if i >= 0 and i < SLOTS.size() else {}
