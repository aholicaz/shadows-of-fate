## RecipeData — สูตรคราฟต์ 1 สูตร (★ รอบ 132 ★)
##
## ★ เพิ่มสูตรใหม่ = สร้างไฟล์ .tres ในโฟลเดอร์ data/recipes/ ★ ไม่ต้องแก้โค้ด
## ช่างเหล็กทุกเมือง (NPC ที่มีเมนู «ตีบวก») จะเห็นสูตรของบทที่ ≤ บทของเมืองนั้น
class_name RecipeData
extends Resource

@export var id: StringName = &"recipe_id"
## ไอเทมที่จะได้ (id ของ ItemData) — ของสวมใส่จะสุ่มโบนัส % ให้ (ดู bonus_min/max)
@export var result_item_id: StringName = &""
@export var result_count: int = 1
## บทที่ปลดสูตร (ช่างเหล็กเมืองบท N เห็นสูตรบท 1..N)
@export var chapter: int = 1
## ★ รอบ 134 ★ กลุ่ม: general (ทั่วไป/ชิ้นเซ็ต) · boss_weapon (อาวุธบอส) · accessory (เครื่องประดับ)
@export var category: StringName = &"general"
## วัตถุดิบ: id ไอเทม → จำนวน (ใส่แร่ตีบวกด้วยได้)
@export var materials: Dictionary = {}
## ค่าแรงช่าง
@export var zeny: int = 0
## ช่วงโบนัส % ของของที่คราฟต์ (สุ่มแบบเฉลี่ยกลาง ๆ · เพดานแตะยาก) — ★ รอบ 133 ★ 25-45 (ของดรอป 5-30)
@export var bonus_min: float = 25.0
@export var bonus_max: float = 45.0
## ต้องมีธงเนื้อเรื่องนี้ก่อนถึงเห็นสูตร (ว่าง = ไม่ต้อง)
@export var required_flag: StringName = &""
@export_multiline var note: String = ""


func result() -> ItemData:
	return GameData.get_item(result_item_id)


func display_name() -> String:
	var d := result()
	return d.display_name if d != null else String(result_item_id)


## รายการวัตถุดิบเรียงตามที่ใส่ในไฟล์ — คืน Array ของ [item_id, need]
func material_list() -> Array:
	var out: Array = []
	for k in materials.keys():
		out.append([StringName(k), int(materials[k])])
	return out


## มีของครบไหม (ไม่รวม zeny)
func has_materials(inv: Inventory) -> bool:
	if inv == null:
		return false
	for pair in material_list():
		if inv.count_of(pair[0]) < pair[1]:
			return false
	return true


## วัตถุดิบตัวแรกที่ยังขาด — คืน [item_id, ขาดกี่ชิ้น] หรือ [] ถ้าครบ
func first_missing(inv: Inventory) -> Array:
	if inv == null:
		return [&"", 0]
	for pair in material_list():
		var have := inv.count_of(pair[0])
		if have < pair[1]:
			return [pair[0], pair[1] - have]
	return []


## สุ่มโบนัส % — ค่าเฉลี่ยกลางช่วง (≈35% ที่ 25-45 · รอบ 133) · ใกล้เพดานออกราว 4% ของครั้ง
func roll_bonus() -> float:
	var u := (randf() + randf()) * 0.5
	return roundf((bonus_min + (bonus_max - bonus_min) * u) * 10.0) / 10.0


const CATEGORY_ORDER := [&"general", &"boss_weapon", &"accessory"]
const CATEGORY_NAMES := {&"general": "ทั่วไป", &"boss_weapon": "อาวุธบอส", &"accessory": "เครื่องประดับ"}


func category_rank() -> int:
	var i := CATEGORY_ORDER.find(category)
	return i if i >= 0 else 99


func category_name() -> String:
	return String(CATEGORY_NAMES.get(category, String(category)))
