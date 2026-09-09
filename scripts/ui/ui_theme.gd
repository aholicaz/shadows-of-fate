## UITheme — สีและสไตล์กลางของหน้าต่างทั้งหมด
## อยากเปลี่ยนหน้าตา UI ทั้งเกม แก้ที่ไฟล์นี้ไฟล์เดียว
##
## ★★ รอบ 98 — ธีม "Petrol" ตามชุด petrol_ui_kit_godot4 + ภาพตัวอย่างของผู้ใช้ ★★
## พื้นเขียวเข้มอมน้ำเงิน (#102725) · ขอบทองเหลือง 1 px (#B5A16C) · ตัวหนังสืองาช้าง (#ECE7D8) · รอง (#81958A)
## ไอคอนเมนูจาก res://Sprites/ui/petrol/icons/<id>.svg · กรอบช่อง/ปุ่มวงกลมจาก components/
## ไอคอนเล็ก ๆ อื่น ๆ (เหรียญ หัวใจ ดาบ ฯลฯ) ดูที่ PetrolWidgets.glyph() — ถ้ายังไม่มีไฟล์จะวาดด้วยโค้ดให้ก่อน
class_name UITheme
extends RefCounted

# ---------- จานสี Petrol ----------
const INK := Color("#102725")            # พื้นหลักของชุด
const BG := Color("#0b1c1b")             # พื้นหน้าต่าง (เข้มกว่า INK นิดหน่อยให้ตัวหนังสือเด่น)
const PANEL := Color("#0f2422")          # แผงย่อยในหน้าต่าง
const PANEL_LIGHT := Color("#173430")    # ช่อง/ปุ่มปกติ
const PANEL_HOVER := Color("#243c34")    # ปุ่มตอนชี้ (จากชุด)
const PANEL_PRESSED := Color("#34483b")  # ปุ่มตอนกด (จากชุด)
const BORDER := Color("#3f5a52")         # ขอบธรรมดา (SAGE จาง)
const BORDER_SOFT := Color("#81958a73")  # ขอบช่องว่าง (SAGE 45%)
const SAGE := Color("#81958a")
const ACCENT := Color("#b5a16c")         # ทองเหลือง — ขอบทอง / แท็บที่เลือก / ตัวเลขเน้น
const GOLD_BRIGHT := Color("#e0cc93")    # ทองสว่าง (หัวข้อ)
const TEXT := Color("#ece7d8")           # งาช้าง
const TEXT_DIM := Color("#81958a")
const HP := Color("#c9463c")
const SP := Color("#3f8fc4")
const EXP := Color("#b5a16c")
## สีหลอดค่าประสบการณ์อาชีพ (Job)
const JOB := Color("#c58cf0")
const GOOD := Color("#7fe39a")
const BAD := Color("#ff7b6b")
## สีระดับความหายาก (ป้ายใต้ชื่อไอเทม)
const RARITY_COMMON := Color("#c7c2b4")
const RARITY_RARE := Color("#4fa3e0")
const RARITY_EPIC := Color("#b57cff")
const RARITY_LEGEND := Color("#ffb347")

const ICON_DIR := "res://Sprites/ui/petrol/icons/"
const COMPONENT_DIR := "res://Sprites/ui/petrol/components/"
const GLYPH_DIR := "res://Sprites/ui/petrol/glyphs/"
## ไอคอนเก่าที่ผู้เล่นเคยวางไว้ (รอบ 27) — ใช้เป็นตัวสำรองถ้าไม่มี SVG
const LEGACY_ICON_DIR := "res://Sprites/ui_icons/"


# =========================================================
# ไอคอน
# =========================================================
static var _icon_cache: Dictionary = {}

## ไอคอนเมนู 8 ตัวจากชุด: status · equipment · inventory · skills · cards · quests · map · system
static func icon(id: String) -> Texture2D:
	if _icon_cache.has(id):
		return _icon_cache[id]
	var tex: Texture2D = null
	for path in [ICON_DIR + id + ".svg", ICON_DIR + id + ".png", LEGACY_ICON_DIR + id + ".png"]:
		if ResourceLoader.exists(path):
			tex = load(path) as Texture2D
			if tex != null:
				break
	_icon_cache[id] = tex
	return tex


## ภาพประกอบจาก components/ (slot · slot-selected · action · action-pressed · close)
static func component(id: String) -> Texture2D:
	var key := "component:" + id
	if _icon_cache.has(key):
		return _icon_cache[key]
	var tex: Texture2D = null
	for path in [COMPONENT_DIR + id + ".svg", COMPONENT_DIR + id + ".png"]:
		if ResourceLoader.exists(path):
			tex = load(path) as Texture2D
			if tex != null:
				break
	_icon_cache[key] = tex
	return tex


## ไอคอนเล็ก (glyph) ที่ผู้ใช้วางเพิ่มได้เองที่ res://Sprites/ui/petrol/glyphs/<id>.svg|png — null = ยังไม่มี
static func glyph_texture(id: String) -> Texture2D:
	var key := "glyph:" + id
	if _icon_cache.has(key):
		return _icon_cache[key]
	var tex: Texture2D = null
	for path in [GLYPH_DIR + id + ".svg", GLYPH_DIR + id + ".png"]:
		if ResourceLoader.exists(path):
			tex = load(path) as Texture2D
			if tex != null:
				break
	_icon_cache[key] = tex
	return tex


# =========================================================
# สไตล์
# =========================================================
## กรอบหน้าต่าง/แผง: ขอบทอง 1 px มุม 4 px (ตามชุด)
static func panel_style(bg: Color = PANEL, border: Color = ACCENT, radius: int = 4,
		border_width: int = 1, margin: float = 8.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s


## แผงย่อยในหน้าต่าง (ขอบ SAGE จาง ๆ)
static func inner_style(bg: Color = PANEL, radius: int = 4, margin: float = 8.0) -> StyleBoxFlat:
	return panel_style(bg, BORDER_SOFT, radius, 1, margin)


## ช่องไอเทม: ปกติ = พื้น INK 90% ขอบ SAGE 45% · เลือก = พื้น #253C34 ขอบทอง 2 px (ตาม components/slot*.svg)
static func slot_style(highlight: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#253c34") if highlight else Color(INK, 0.9)
	s.border_color = ACCENT if highlight else BORDER_SOFT
	s.set_border_width_all(2 if highlight else 1)
	s.set_corner_radius_all(4)
	return s


## แถบหลอดพลัง
static func bar_bg_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#091816")
	s.border_color = Color(SAGE, 0.6)
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	return s


static func bar_fill_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(6)
	return s


## ★ ใส่รูปในช่องไอเทม/การ์ดให้อยู่ "กึ่งกลางเป๊ะ" ★
##
## ไม่ใช้ `button.icon` เพราะ Godot จะวางรูปชิดมุมเวลาเปิด expand_icon
## วิธีนี้ใช้ TextureRect ซ้อนเต็มปุ่มแทน แล้วให้มันจัดกึ่งกลาง + คงสัดส่วนภาพเอง
## คืน [TextureRect (รูป), Label (จำนวน มุมขวาล่าง)]
static func make_slot_icon(button: Button, margin: float = 5.0) -> Array:
	var art := TextureRect.new()
	art.name = "SlotIcon"
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# ต้องใช้ and_offsets ไม่งั้นจะได้กรอบขนาด 0 (ดูหัวข้อ ConfirmDialog)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_left = margin
	art.offset_top = margin
	art.offset_right = -margin
	art.offset_bottom = -margin
	button.add_child(art)

	var count := Label.new()
	count.name = "SlotCount"
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	count.offset_right = -3
	count.offset_bottom = -1
	count.add_theme_font_size_override("font_size", 11)
	count.add_theme_color_override("font_color", TEXT)
	count.add_theme_color_override("font_outline_color", Color.BLACK)
	count.add_theme_constant_override("outline_size", 4)
	button.add_child(count)

	return [art, count]


static func make_label(text: String, size: int = 14, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## ปุ่มธรรมดา: พื้นโปร่ง ขอบ SAGE จาง · ชี้ = ขอบทอง · กด = พื้น #34483b ขอบงาช้าง (ตามชุด)
static func make_button(text: String, min_width: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(TEXT_DIM, 0.6))
	b.add_theme_stylebox_override("normal", _btn_style(Color(0.06, 0.15, 0.14, 0.75), BORDER_SOFT))
	b.add_theme_stylebox_override("hover", _btn_style(PANEL_HOVER, ACCENT))
	b.add_theme_stylebox_override("pressed", _btn_style(PANEL_PRESSED, TEXT))
	b.add_theme_stylebox_override("disabled", _btn_style(Color(0.06, 0.12, 0.11, 0.5), Color(BORDER_SOFT, 0.25)))
	if min_width > 0.0:
		b.custom_minimum_size.x = min_width
	return b


## ★ ปุ่มทอง ★ (EQUIP ในภาพตัวอย่าง) — พื้นทองเหลือง ตัวหนังสือเข้ม
static func make_gold_button(text: String, min_width: float = 0.0) -> Button:
	var b := make_button(text, min_width)
	b.add_theme_color_override("font_color", Color("#1a2a22"))
	b.add_theme_color_override("font_hover_color", Color("#0d1a14"))
	b.add_theme_color_override("font_pressed_color", Color("#0d1a14"))
	b.add_theme_stylebox_override("normal", _btn_style(ACCENT, GOLD_BRIGHT))
	b.add_theme_stylebox_override("hover", _btn_style(GOLD_BRIGHT, Color.WHITE))
	b.add_theme_stylebox_override("pressed", _btn_style(Color("#8f7d4f"), GOLD_BRIGHT))
	b.add_theme_stylebox_override("disabled", _btn_style(Color("#4a4636"), Color("#6b6350")))
	return b


static func _btn_style(bg: Color, border: Color = BORDER) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


static func make_bar(fill_color: Color, height: float = 16.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = height
	bar.max_value = 100
	bar.value = 100
	bar.add_theme_stylebox_override("background", bar_bg_style())
	bar.add_theme_stylebox_override("fill", bar_fill_style(fill_color))
	return bar


static func separator() -> HSeparator:
	var sep := HSeparator.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(ACCENT, 0.45)
	s.content_margin_top = 1
	sep.add_theme_stylebox_override("separator", s)
	return sep


## สีป้ายความหายาก — คืน [ชื่อ, สี] เสมอ (ห้ามคืน null · หน้ากระเป๋าอ่าน rar[0]/rar[1] ตรง ๆ)
##
## ★★ รอบ 99 ★★ การ์ดมีระบบความหายากของตัวเองอยู่แล้ว (CardData.rarity 1-5)
## ใช้ชื่อ/สีเดียวกับกรอบการ์ดในอัลบั้ม (`rarity_name()` / `rarity_color()`) จะได้ไม่ขัดกัน
##
## ★ กับดัก ★ ห้ามเรียก String(ค่าที่ไม่รู้ชนิด) — `String(int)` ไม่มี constructor ใน Godot 4
## จะเป็น runtime error แล้วฟังก์ชัน "หยุดกลางคัน คืน null" (บั๊กการ์ดคลิกแล้วแผงว่างของรอบ 98)
static func rarity_of(d: ItemData) -> Array:
	if d == null:
		return ["ธรรมดา", RARITY_COMMON]
	if d is CardData:
		var c := d as CardData
		return [c.rarity_name(), c.rarity_color()]

	# ไอเทมทั่วไป — ถ้าไฟล์ไอเทมมีช่อง rarity เมื่อไหร่ (ยังไม่มี) รองรับทั้งข้อความและตัวเลข
	var r: Variant = d.get("rarity") if "rarity" in d else null
	match typeof(r):
		TYPE_STRING, TYPE_STRING_NAME:
			match String(r).to_lower():
				"common": return ["ธรรมดา", RARITY_COMMON]
				"uncommon": return ["ไม่ธรรมดา", GOOD]
				"rare": return ["หายาก", RARITY_RARE]
				"epic": return ["ล้ำค่า", RARITY_EPIC]
				"legend", "legendary": return ["ตำนาน", RARITY_LEGEND]
		TYPE_INT:
			match int(r):
				1: return ["ธรรมดา", RARITY_COMMON]
				2: return ["ไม่ธรรมดา", GOOD]
				3: return ["หายาก", RARITY_RARE]
				4: return ["หายากมาก", RARITY_EPIC]
				5: return ["ระดับตำนาน", RARITY_LEGEND]

	# ไม่มีช่อง rarity → เดาจากเลเวลที่ต้องใช้ / ราคาขาย
	var lv: int = int(d.required_level) if "required_level" in d else 0
	var price: int = int(d.sell_price) if "sell_price" in d else 0
	if lv >= 40 or price >= 20000:
		return ["ตำนาน", RARITY_LEGEND]
	if lv >= 25 or price >= 5000:
		return ["ล้ำค่า", RARITY_EPIC]
	if lv >= 10 or price >= 800:
		return ["หายาก", RARITY_RARE]
	return ["ธรรมดา", RARITY_COMMON]
