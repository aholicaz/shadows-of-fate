## InventoryWindow — หน้ากระเป๋า (กด I) — โฉม Petrol รอบ 98 ตามภาพตัวอย่างของผู้ใช้
##
##  ┌ ตัวละคร ─────────┐ ┌ ทั้งหมด · อาวุธ · เกราะ · ของใช้ · วัตถุดิบ ────────┐ ┌ รายละเอียด ───────┐
##  │ ชื่ออาชีพ Lv.20     │ │ [🔍 ค้นหา...............]  [เรียง ▾]              │ │   (รูปใหญ่)         │
##  │ [ช่อง] ตัวละคร [ช่อง]│ │ ▢ ▢ ▢ ▢ ▢ ▢                                      │ │  ชื่อไอเทม           │
##  │ [ช่อง]  (ยืน)  [ช่อง]│ │ ▢ ▢ ▢ ▢ ▢ ▢  (6 คอลัมน์ เลื่อนลงได้)             │ │  ความหายาก           │
##  │ [ช่อง]         [ช่อง]│ │ ▢ ▢ ▢ ▢ ▢                                        │ │  ⚔ โจมตี        96  │
##  │ [ช่อง]         [ช่อง]│ │ ▢ ▢ ▢ ▢ ▢                                        │ │  ★ คริ        +4.5% │
##  │ ♥ HP  541          │ │                                                   │ │  คำอธิบาย...        │
##  │ ● MP  195 …        │ │  👜 54 / 200        ⬤ 12,055                      │ │ [   สวมใส่ (ทอง)  ] │
##  └───────────────────┘ └───────────────────────────────────────────────────┘ │ [   เปรียบเทียบ   ] │
##                                                                              └───────────────────┘
## · ลากของจากกระเป๋าไปวางช่องสวมใส่ = ใส่ · ลากช่องสวมใส่มาวางกระเป๋า = ถอด (DragSlot เดิมรอบ 45)
## · อยู่ในหน้าต่างรวม (MenuShell) แท็บ "กระเป๋า" — หัวเรื่อง/กรอบของตัวเองถูกซ่อน
class_name InventoryWindow
extends GameWindow

## ★ รอบ 102 ★ แถวละ 6 ช่อง (เดิม 5)
const COLUMNS := 6
## ขนาดช่องขั้นต่ำ (ใช้ตอนหน้าต่างแคบมาก) — ขนาดจริงคำนวณจากความกว้างที่มีใน _fit_grid()
const SLOT_SIZE := Vector2(58, 58)
## ★ รอบ 102 (รอบสอง) ★ ช่องไอเทม "ยืดเต็มระยะ" ไม่เหลือที่ว่างข้าง Scroll
## เดิมช่องขนาดตายตัว → กริดกว้างไม่ถึงขอบ เหลือช่องโล่งกองอยู่ข้าง ๆ
## ตอนนี้คำนวณขนาดช่องจากความกว้างจริงของกล่องเลื่อนทุกครั้งที่หน้าต่างเปลี่ยนขนาด
const SLOT_MIN := 56.0
const SLOT_MAX := 140.0
const GRID_SEP := 8
## เผื่อที่ให้แถบเลื่อนแนวตั้ง (ไม่เผื่อ = พอมีของเต็มกระเป๋าแล้วแถบเลื่อนโผล่ กริดจะล้นออกข้าง)
const SCROLLBAR_ROOM := 16.0
const EQUIP_SLOT := Vector2(54, 54)
## ความกว้างคงที่ของแผงรายละเอียดด้านขวา (ตรึงไว้ กริดกระเป๋าจะได้ไม่ขยับตามความยาวข้อความ)
const DETAIL_WIDTH := 268.0

# ---- สี (ค้างชื่อเดิมไว้ หน้าต่างอื่นอ้างถึง) ----
const C_BG := Color("#0b1c1bf2")
const C_BORDER := UITheme.ACCENT
const C_BAR := UITheme.PANEL
const C_SLOT := Color("#102725e6")
const C_SLOT_EDGE := UITheme.BORDER_SOFT
const C_SLOT_SEL := Color("#253c34")
const C_SEL_EDGE := UITheme.ACCENT
const C_TEXT := UITheme.TEXT
const C_TEXT_DIM := UITheme.TEXT_DIM
const C_COUNT := UITheme.TEXT
const C_COUNT_OUTLINE := Color.BLACK
const C_GOLD := UITheme.ACCENT
const C_BTN := Color(0.06, 0.15, 0.14, 0.75)
const C_BTN_HOVER := UITheme.PANEL_HOVER
const C_BTN_DISABLED := Color(0.06, 0.12, 0.11, 0.5)
const C_FIELD := Color("#0a1817")
const C_FIELD_FOCUS := UITheme.PANEL_LIGHT
const C_ZENY_BG := UITheme.PANEL
const C_ZENY_TEXT := UITheme.GOLD_BRIGHT
const C_FRAME := UITheme.PANEL
const C_INNER := Color("#0f2422b3")

## หมวด (แท็บบนกริด) — id · ชื่อ · ไอคอน
const CATEGORIES := [
	{"id": "all",         "label": "ทั้งหมด",  "glyph": "all"},
	{"id": "weapons",     "label": "อาวุธ",    "glyph": "weapons"},
	{"id": "armor",       "label": "เกราะ",    "glyph": "armor"},
	{"id": "consumables", "label": "ของใช้",   "glyph": "consumables"},
	{"id": "materials",   "label": "วัตถุดิบ", "glyph": "materials"},
	{"id": "quest",       "label": "ไอเทมเควส", "glyph": "quest"},   # ★ รอบ 155 ★ ไม่กินช่อง ไม่โชว์ในทั้งหมด
]
const SORT_MODES := ["ล่าสุด", "ชื่อ", "ชนิด", "ราคา"]
const LEFT_SLOTS := [Equipment.EquipSlot.WEAPON, Equipment.EquipSlot.HEAD, Equipment.EquipSlot.ARMOR, Equipment.EquipSlot.GARMENT]
const RIGHT_SLOTS := [Equipment.EquipSlot.OFFHAND, Equipment.EquipSlot.SHOES, Equipment.EquipSlot.ACCESSORY_1, Equipment.EquipSlot.ACCESSORY_2]
const SLOT_GLYPH := {
	Equipment.EquipSlot.WEAPON: "slot_weapon", Equipment.EquipSlot.HEAD: "slot_head",
	Equipment.EquipSlot.ARMOR: "slot_armor", Equipment.EquipSlot.GARMENT: "slot_garment",
	Equipment.EquipSlot.OFFHAND: "slot_offhand", Equipment.EquipSlot.SHOES: "slot_shoes",
	Equipment.EquipSlot.ACCESSORY_1: "slot_accessory", Equipment.EquipSlot.ACCESSORY_2: "slot_accessory",
}

var _category := "all"
var _quest_sel := -1   # ★ รอบ 155 ★ ไอเทมเควสที่เลือก (ลำดับใน inventory.quest_items)
var _sort := 0
var _search := ""
var _cat_buttons: Dictionary = {}     # id -> Button
var _search_edit: LineEdit
var _sort_button: OptionButton
var _grid: GridContainer
var _slot_buttons: Array[Button] = []
var _slot_icons: Array[TextureRect] = []
var _slot_counts: Array[Label] = []
var _slot_empties: Array[Control] = []
## ช่องที่โชว์ตำแหน่ง i ชี้ไปช่องจริงไหนในกระเป๋า (-1 = ว่าง)
var _display_to_slot: Array[int] = []
var _capacity_label: Label
var _zeny_label: Label
## ซ้าย: ตัวละคร
var _hero_name: Label
var _preview: Control
var _equip_buttons: Dictionary = {}   # EquipSlot -> DragSlot
var _equip_icons: Dictionary = {}     # EquipSlot -> TextureRect
var _equip_glyphs: Dictionary = {}    # EquipSlot -> Control
var _stat_values: Dictionary = {}     # key -> Label
## ขวา: รายละเอียด
var _grid_scroll: ScrollContainer
var _cell_size := 0.0
var _detail_scroll: ScrollContainer
var _detail_art: TextureRect
var _detail_name: Label
var _detail_rarity: Label
var _detail_stats: VBoxContainer
var _detail_desc: Label
var _use_button: Button
var _compare_button: Button
var _drop_button: Button
var _potion_row: HBoxContainer
var _set_q_button: Button
var _set_r_button: Button
var _hotbar_row: HBoxContainer          # ★ รอบ 168 ★ ใส่ของกินลงแถบลัด 1-8
var _hotbar_btns: Array[Button] = []
var _detail_empty: Label

var _selected := -1          # ช่องจริงในกระเป๋า
## ★ รอบ 140 ★ ช่องสวมใส่ที่เลือกดูอยู่ (-1 = ไม่ได้เลือก) — คลิกซ้ายช่องสวมใส่ = ดูรายละเอียด ไม่ถอดแล้ว
var _selected_equip := -1
## ★ รอบ 140 ★ โหมดใส่การ์ด (แบบ B): เลือกการ์ดแล้วคลิกอุปกรณ์ที่เรืองแสง
var _card_mode := false
var _card_pick: StringName = &""
var _equip_menu: PopupMenu
var _menu_slot := -1
## โหมดขาย: กดของแล้วขายทันที (ร้านค้าเป็นคนเปิด)
var sell_mode := false
## ★ เทียบกับของที่สวมอยู่ (กด "เปรียบเทียบ") ★
var _comparing := false


func _ready() -> void:
	window_title = "กระเป๋า"
	super._ready()
	Events.inventory_changed.connect(refresh)
	Events.equipment_changed.connect(refresh)
	Events.stats_changed.connect(_refresh_stats)
	Events.zeny_changed.connect(func(_z): refresh())


static func _style(bg: Color, border: Color, radius: int = 4, margin: float = 6.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s


func _slot_box(selected: bool = false) -> StyleBoxFlat:
	return UITheme.slot_style(selected)


func _cream_button(text: String, min_width: float = 0.0) -> Button:
	return UITheme.make_button(text, min_width)


func _label(text: String, size: int = 14, color: Color = C_TEXT) -> Label:
	return UITheme.make_label(text, size, color)


# =========================================================
func _build_content() -> void:
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(cols)

	cols.add_child(_build_left())
	cols.add_child(_build_middle())
	cols.add_child(_build_right())


# ---------------------------------------------------------
# ซ้าย: ตัวละคร + ช่องสวมใส่ + ค่าพลัง
# ---------------------------------------------------------
func _build_left() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.inner_style(C_INNER, 4, 10.0))
	panel.custom_minimum_size.x = 252
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	_hero_name = _label("นักดาบ", 18, C_TEXT)
	_hero_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_hero_name)
	var lv_rule := PetrolWidgets.ornament(160.0, UITheme.ACCENT, 3.0)
	lv_rule.custom_minimum_size = Vector2(160, 10)
	lv_rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(lv_rule)

	# [ช่อง 4] ตัวละคร [ช่อง 4]
	var doll := HBoxContainer.new()
	doll.add_theme_constant_override("separation", 6)
	doll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(doll)
	doll.add_child(_equip_column(LEFT_SLOTS))
	var mid := DragSlot.new()
	mid.kind = "any"
	mid.text = ""
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.custom_minimum_size = Vector2(110, 236)
	mid.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	mid.add_theme_stylebox_override("hover", UITheme.slot_style(true))
	mid.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	mid.can_drop_func = func(data: Dictionary, _t: DragSlot) -> bool:
		return String(data.get("kind", "")) == "inventory"
	mid.drop_func = func(data: Dictionary, _t: DragSlot) -> bool:
		return _equip_from(int(data.get("slot", -1)), -1)
	_preview = preload("res://scripts/ui/equipment_character_preview.gd").new()
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_preview.offset_left = 2
	_preview.offset_top = 2
	_preview.offset_right = -2
	_preview.offset_bottom = -2
	mid.add_child(_preview)
	doll.add_child(mid)
	doll.add_child(_equip_column(RIGHT_SLOTS))

	var st_rule := PetrolWidgets.ornament(200.0, UITheme.ACCENT, 3.0)
	st_rule.custom_minimum_size = Vector2(200, 10)
	st_rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(st_rule)

	# ค่าพลัง
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 3)
	box.add_child(stats)
	for row in [["hp", "HP", "hp"], ["sp", "SP", "sp"], ["atk", "โจมตี", "attack"], ["def", "ป้องกัน", "defense"],
			["speed", "ความเร็ว", "speed"], ["crit", "อัตราคริ", "crit"]]:
		var r := PetrolWidgets.stat_row(String(row[2]), String(row[1]), "-", C_TEXT, 13)
		stats.add_child(r)
		_stat_values[String(row[0])] = r.get_node("Value")
	return panel


func _equip_column(slots: Array) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	for slot in slots:
		col.add_child(_make_equip_slot(int(slot)))
	return col


func _make_equip_slot(slot: int) -> DragSlot:
	var btn := DragSlot.new()
	btn.kind = "equip"
	btn.slot_index = slot
	btn.text = ""
	btn.custom_minimum_size = EQUIP_SLOT
	btn.clip_contents = true
	btn.tooltip_text = String(Equipment.SLOT_NAMES.get(slot, ""))
	btn.add_theme_stylebox_override("normal", _slot_box())
	btn.add_theme_stylebox_override("hover", _slot_box(true))
	btn.add_theme_stylebox_override("pressed", _slot_box(true))
	btn.pressed.connect(func(): _on_equip_pressed(slot))
	btn.gui_input.connect(func(ev: InputEvent): _on_equip_gui_input(ev, slot))   # ★ รอบ 140 ★ คลิกขวา = เมนู ดู/ถอด
	btn.drag_icon_func = func() -> Texture2D:
		var inst := PlayerState.equipment.get_item(slot)
		if inst == null or inst.data() == null:
			return null
		return inst.data().icon
	btn.can_drop_func = func(data: Dictionary, _t: DragSlot) -> bool:
		return String(data.get("kind", "")) == "inventory"
	btn.drop_func = func(data: Dictionary, _t: DragSlot) -> bool:
		# ★ รอบ 140 ★ ลากการ์ดมาวางบนของที่สวมอยู่ = ใส่การ์ด
		var src := PlayerState.inventory.get_slot(int(data.get("slot", -1)))
		if src != null and src.data() != null and src.data().is_card():
			return _socket_into(PlayerState.equipment.get_item(slot), src.item_id)
		return _equip_from(int(data.get("slot", -1)), slot)
	var g := PetrolWidgets.glyph(String(SLOT_GLYPH.get(slot, "slot_weapon")), 26.0, C_TEXT_DIM)
	g.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	g.offset_left = -13
	g.offset_top = -13
	g.offset_right = 13
	g.offset_bottom = 13
	btn.add_child(g)
	_equip_glyphs[slot] = g
	var parts := UITheme.make_slot_icon(btn, 6.0)
	_equip_icons[slot] = parts[0]
	_equip_buttons[slot] = btn
	return btn


# ---------------------------------------------------------
# กลาง: หมวด + ค้นหา + เรียง + กริด + แถบล่าง
# ---------------------------------------------------------
func _build_middle() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.inner_style(C_INNER, 4, 10.0))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	# ---------- หมวด ----------
	var cats := HBoxContainer.new()
	cats.add_theme_constant_override("separation", 4)
	box.add_child(cats)
	for c in CATEGORIES:
		var id := String(c.id)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 38)
		b.add_theme_font_size_override("font_size", 1)
		var inner := HBoxContainer.new()
		inner.add_theme_constant_override("separation", 6)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 12
		inner.offset_right = -12
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		var gl := PetrolWidgets.glyph(String(c.glyph), 15.0, C_TEXT)
		gl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		inner.add_child(gl)
		var lbl := _label(String(c.label), 12, C_TEXT)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(lbl)
		b.add_child(inner)
		b.custom_minimum_size.x = 96 if id != "all" else 80
		b.pressed.connect(func():
			_category = id
			_selected = -1
			_quest_sel = -1
			_selected_equip = -1
			UI.hide_item_popup()
			refresh())
		cats.add_child(b)
		_cat_buttons[id] = b

	# ---------- ค้นหา + เรียง ----------
	var find_row := HBoxContainer.new()
	find_row.add_theme_constant_override("separation", 8)
	box.add_child(find_row)
	var field := PanelContainer.new()
	field.add_theme_stylebox_override("panel", _style(C_FIELD, C_SLOT_EDGE, 4, 4))
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	find_row.add_child(field)
	var fbox := HBoxContainer.new()
	fbox.add_theme_constant_override("separation", 6)
	field.add_child(fbox)
	var sg := PetrolWidgets.glyph("search", 16.0, C_TEXT_DIM)
	sg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fbox.add_child(sg)
	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "ค้นหาไอเทม..."
	_search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_edit.add_theme_font_size_override("font_size", 13)
	_search_edit.add_theme_color_override("font_color", C_TEXT)
	_search_edit.add_theme_color_override("font_placeholder_color", Color(C_TEXT_DIM, 0.7))
	_search_edit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_search_edit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_search_edit.text_changed.connect(func(t: String):
		_search = t.strip_edges()
		refresh())
	fbox.add_child(_search_edit)

	_sort_button = OptionButton.new()
	_sort_button.focus_mode = Control.FOCUS_NONE
	for m in SORT_MODES:
		_sort_button.add_item("เรียง: %s" % m)
	_sort_button.custom_minimum_size = Vector2(150, 0)
	_sort_button.add_theme_font_size_override("font_size", 13)
	_sort_button.add_theme_color_override("font_color", C_TEXT)
	_sort_button.add_theme_stylebox_override("normal", _style(C_FIELD, C_SLOT_EDGE, 4, 5))
	_sort_button.add_theme_stylebox_override("hover", _style(C_BTN_HOVER, C_BORDER, 4, 5))
	_sort_button.add_theme_stylebox_override("pressed", _style(C_SLOT_SEL, C_SEL_EDGE, 4, 5))
	_sort_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_sort_button.item_selected.connect(func(i: int):
		_sort = i
		refresh())
	find_row.add_child(_sort_button)

	# ---------- กริดช่องไอเทม (เลื่อนลงได้) ----------
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_grid_scroll = scroll
	scroll.resized.connect(_fit_grid)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", GRID_SEP)
	_grid.add_theme_constant_override("v_separation", GRID_SEP)
	# ขนาดช่องคำนวณให้พอดีความกว้างอยู่แล้ว เศษที่เหลือ (< 6 px) แบ่งซ้าย-ขวาเท่ากัน
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.add_child(_grid)

	for i in range(PlayerState.INVENTORY_SIZE):
		var btn := DragSlot.new()
		btn.kind = "inventory"
		btn.custom_minimum_size = SLOT_SIZE
		btn.focus_mode = Control.FOCUS_NONE
		btn.clip_text = true
		var display_index := i
		btn.drag_icon_func = func() -> Texture2D:
			return _drag_icon_of(display_index)
		btn.can_drop_func = func(data: Dictionary, _t: DragSlot) -> bool:
			var k := String(data.get("kind", ""))
			return k == "equip" or (k == "inventory" and not sell_mode)
		btn.drop_func = func(data: Dictionary, _t: DragSlot) -> bool:
			return _on_drop(data, display_index)
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", C_TEXT)
		btn.add_theme_stylebox_override("normal", _slot_box())
		btn.add_theme_stylebox_override("hover", _slot_box(true))
		btn.add_theme_stylebox_override("pressed", _slot_box(true))
		var index := i
		btn.pressed.connect(func(): _on_slot_pressed(index))
		_grid.add_child(btn)
		_slot_buttons.append(btn)
		# ถุงจาง ๆ ในช่องว่าง (ตามภาพ)
		var empty := PetrolWidgets.glyph("bag_empty", 30.0, C_TEXT_DIM)
		empty.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		empty.offset_left = -15
		empty.offset_top = -15
		empty.offset_right = 15
		empty.offset_bottom = 15
		btn.add_child(empty)
		# ★ ต้องปิด IGNORE ตรงนี้ ★ ถุงจาง ๆ อยู่ใต้ไอคอนของจริงเสมอ ไม่กินคลิก
		_slot_empties.append(empty)
		var parts := UITheme.make_slot_icon(btn, 7.0)
		_slot_icons.append(parts[0])
		var cnt: Label = parts[1]
		cnt.add_theme_font_size_override("font_size", 12)
		cnt.add_theme_color_override("font_color", C_COUNT)
		cnt.add_theme_color_override("font_outline_color", C_COUNT_OUTLINE)
		cnt.add_theme_constant_override("outline_size", 4)
		_slot_counts.append(cnt)
		_display_to_slot.append(-1)

	# ---------- แถบล่าง: จำนวนช่อง + ซีนี ----------
	box.add_child(UITheme.separator())
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(foot)
	var bag := PetrolWidgets.glyph("bag_empty", 18.0, C_TEXT)
	bag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(bag)
	_capacity_label = _label("0 / 40", 14, C_TEXT)
	foot.add_child(_capacity_label)
	var sep := Control.new()
	sep.custom_minimum_size.x = 40
	foot.add_child(sep)
	var coin := PetrolWidgets.glyph("coin", 18.0)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(coin)
	_zeny_label = _label("0", 15, C_ZENY_TEXT)
	foot.add_child(_zeny_label)
	return panel


## ★★ รอบ 102 (รอบสอง) — ช่องไอเทมยืดเต็มความกว้าง ★★
##
## เรียกทุกครั้งที่กล่องเลื่อนเปลี่ยนขนาด (ย่อ/ขยายหน้าต่าง · เข้าเต็มจอ)
## ขนาดช่อง = (ความกว้างที่มี − ช่องไฟรวม) ÷ จำนวนคอลัมน์  แล้ว clamp กันเล็ก/ใหญ่เกิน
## ไอคอนในช่องยึด PRESET_FULL_RECT อยู่แล้ว (ดู UITheme.make_slot_icon) → โตตามช่องเอง
func _fit_grid() -> void:
	if _grid == null or _grid_scroll == null:
		return
	var avail: float = _grid_scroll.size.x - SCROLLBAR_ROOM
	if avail <= 0.0:
		return
	var cell: float = floorf((avail - float(COLUMNS - 1) * float(GRID_SEP)) / float(COLUMNS))
	cell = clampf(cell, SLOT_MIN, SLOT_MAX)
	if absf(cell - _cell_size) < 0.5:
		return
	_cell_size = cell
	var r: float = cell * 0.26        # ถุงจาง ๆ ในช่องว่าง โตตามช่องด้วย
	for i in range(_slot_buttons.size()):
		_slot_buttons[i].custom_minimum_size = Vector2(cell, cell)
		if i < _slot_empties.size():
			var e: Control = _slot_empties[i]
			e.offset_left = -r
			e.offset_top = -r
			e.offset_right = r
			e.offset_bottom = r


# ---------------------------------------------------------
# ขวา: รายละเอียดไอเทมที่เลือก
# ---------------------------------------------------------
func _build_right() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.inner_style(C_INNER, 4, 12.0))
	# ★ รอบ 102 ★ ตรึงความกว้างไว้ (min = max) ไม่งั้นคำอธิบายยาว ๆ จะดันแผงให้กว้างขึ้น
	# แล้วไปบีบกริดกระเป๋าให้แคบลง (นี่คืออาการ "ข้อมูลยาวไปแล้วช่องกระเป๋าเปลี่ยนขนาด")
	panel.custom_minimum_size.x = DETAIL_WIDTH
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.clip_contents = true
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var art_holder := CenterContainer.new()
	art_holder.custom_minimum_size = Vector2(0, 150)
	box.add_child(art_holder)
	var ring := PetrolWidgets.inner_ring(150.0, Color(UITheme.ACCENT, 0.35))
	ring.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	ring.offset_left = -75
	ring.offset_top = -75
	ring.offset_right = 75
	ring.offset_bottom = 75
	art_holder.add_child(ring)
	_detail_art = TextureRect.new()
	_detail_art.custom_minimum_size = Vector2(120, 120)
	_detail_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art_holder.add_child(_detail_art)

	# ★★ รอบ 102 ★★ เนื้อความตรงกลาง (ชื่อ · ความหายาก · ค่าพลัง · คำอธิบาย) อยู่ในกล่องเลื่อน
	# ของยาวแค่ไหนก็เลื่อนดูเอา ไม่ดันปุ่มด้านล่างหลุดจอ และไม่ไปบีบกริดกระเป๋า
	_detail_scroll = ScrollContainer.new()
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_detail_scroll)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# ★ กว้างเท่าแผงลบที่เผื่อแถบเลื่อน ★ ถ้าไม่ตรึง ข้อความ autowrap จะขอความกว้างไม่จำกัด
	inner.custom_minimum_size.x = DETAIL_WIDTH - 40.0
	_detail_scroll.add_child(inner)

	_detail_name = _label("", 19, C_TEXT)
	_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(_detail_name)
	_detail_rarity = _label("", 13, UITheme.RARITY_RARE)
	_detail_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(_detail_rarity)
	var rule := PetrolWidgets.ornament(180.0, UITheme.ACCENT, 3.0)
	rule.custom_minimum_size = Vector2(180, 10)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.add_child(rule)

	_detail_stats = VBoxContainer.new()
	_detail_stats.add_theme_constant_override("separation", 3)
	inner.add_child(_detail_stats)

	_detail_desc = _label("", 12, C_TEXT_DIM)
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(_detail_desc)

	_detail_empty = _label("เลือกไอเทมในกระเป๋า\nเพื่อดูรายละเอียด", 13, C_TEXT_DIM)
	_detail_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inner.add_child(_detail_empty)

	# ---------- ตั้งช่องยาด่วน (โผล่เฉพาะของกิน) ----------
	_potion_row = HBoxContainer.new()
	_potion_row.add_theme_constant_override("separation", 6)
	box.add_child(_potion_row)
	_set_q_button = _cream_button("ตั้งช่อง Q", 0)
	_set_q_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_q_button.pressed.connect(func(): _assign_potion(0))
	_potion_row.add_child(_set_q_button)
	_set_r_button = _cream_button("ตั้งช่อง R", 0)
	_set_r_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_r_button.pressed.connect(func(): _assign_potion(1))
	_potion_row.add_child(_set_r_button)
	_potion_row.hide()

	# ★ รอบ 168 ★ แถบลัด 1-8 (หน้าปัจจุบัน) — ยา · ไอเทมบัพ · ปีกวาร์ป
	_hotbar_row = HBoxContainer.new()
	_hotbar_row.add_theme_constant_override("separation", 6)
	box.add_child(_hotbar_row)
	var hl := _label("แถบลัด", 12, C_TEXT_DIM)
	hl.tooltip_text = "ใส่ไอเทมนี้ลงแถบลัดปุ่ม 1-8 (หน้าปัจจุบัน · Shift สลับหน้า)"
	_hotbar_row.add_child(hl)
	# ★ รอบ 175 ★ 2 แถว × 4 ปุ่ม — แถวเดียว 8 ปุ่มดันแผงรายละเอียดกว้างเกิน DETAIL_WIDTH (ปุ่มขวาโดนตัด)
	var hgrid := GridContainer.new()
	hgrid.columns = 4
	hgrid.add_theme_constant_override("h_separation", 4)
	hgrid.add_theme_constant_override("v_separation", 4)
	hgrid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hotbar_row.add_child(hgrid)
	for k in range(PlayerState.HOTBAR_PAGE):
		var hb := _cream_button(str(k + 1), 0)
		hb.custom_minimum_size = Vector2(0, 28)
		hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_theme_font_size_override("font_size", 13)
		for st in ["normal", "hover", "pressed", "disabled", "focus"]:
			var sb := hb.get_theme_stylebox(st)
			if sb != null:
				var s2 := sb.duplicate()
				s2.content_margin_left = 2.0
				s2.content_margin_right = 2.0
				hb.add_theme_stylebox_override(st, s2)
		hb.pressed.connect(_assign_hotbar.bind(k))
		hgrid.add_child(hb)
		_hotbar_btns.append(hb)
	_hotbar_row.hide()

	_use_button = UITheme.make_gold_button("สวมใส่")
	_use_button.custom_minimum_size.y = 40
	_use_button.pressed.connect(_use_selected)
	box.add_child(_use_button)
	_compare_button = _cream_button("เปรียบเทียบ")
	_compare_button.custom_minimum_size.y = 36
	_compare_button.pressed.connect(_toggle_compare)
	box.add_child(_compare_button)
	_drop_button = _cream_button("ทิ้ง")
	_drop_button.pressed.connect(_drop_selected)
	box.add_child(_drop_button)
	return panel


func shell_hints() -> Array:
	return [["E", "ใช้ / สวมใส่"], ["C", "เปรียบเทียบ"], ["X", "ทิ้ง"], ["คลิกขวา", "ถอดของที่สวม"], ["Esc", "ปิด"]]


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if _search_edit != null and _search_edit.has_focus():
		return
	var k := event as InputEventKey
	if _card_mode and k.keycode == KEY_ESCAPE:   # ★ รอบ 140 ★
		_exit_card_mode()
		get_viewport().set_input_as_handled()
		return
	match k.keycode:
		KEY_E:
			_use_selected()
		KEY_C:
			_toggle_compare()
		KEY_X:
			_drop_selected()
		_:
			return
	get_viewport().set_input_as_handled()


# =========================================================
## หมวดของไอเทม
static func _category_of(d: ItemData) -> String:
	if d == null:
		return "materials"
	match d.type:
		ItemData.Type.CONSUMABLE: return "consumables"
		ItemData.Type.WEAPON: return "weapons"
		ItemData.Type.ARMOR: return "armor"
	return "materials"


func _on_slot_pressed(display_index: int) -> void:
	var slot: int = _display_to_slot[display_index]
	if slot <= -2:   # ★ รอบ 155 ★ ไอเทมเควส (เข้ารหัส -2 - ลำดับ)
		if _card_mode:
			_exit_card_mode()
		_quest_sel = -2 - slot
		_selected = -1
		_selected_equip = -1
		UI.hide_item_popup()
		refresh()
		return
	if _card_mode:   # ★ รอบ 140 ★ โหมดใส่การ์ด: คลิกอุปกรณ์ในกระเป๋า = เป้า
		if slot >= 0:
			_card_mode_target(PlayerState.inventory.get_slot(slot))
		else:
			_exit_card_mode()
		return
	_selected_equip = -1
	if slot < 0:
		_selected = -1
		UI.hide_item_popup()
		refresh()
		return
	if sell_mode:
		PlayerState.sell_slot(slot, 1)
		refresh()
		return
	_selected = slot
	_comparing = false
	UI.hide_item_popup()
	refresh()


## ★ รอบ 140 ★ คลิกซ้ายช่องสวมใส่ = โชว์รายละเอียดที่แผงขวา (ไม่ถอด) · ถอด = ปุ่ม «ถอดออก» / คลิกขวา / ลากออก
func _on_equip_pressed(slot: int) -> void:
	var inst := PlayerState.equipment.get_item(slot)
	if _card_mode:
		if inst != null:
			_card_mode_target(inst)
		return
	if inst == null:
		Events.say("ช่องนี้ว่างอยู่ — ลากของจากกระเป๋ามาวางได้เลย")
		return
	UI.hide_item_popup()
	_selected = -1
	_selected_equip = slot
	_comparing = false
	refresh()


func _on_equip_gui_input(ev: InputEvent, slot: int) -> void:
	if not (ev is InputEventMouseButton) or not ev.pressed or ev.button_index != MOUSE_BUTTON_RIGHT:
		return
	if PlayerState.equipment.get_item(slot) == null or _card_mode:
		return
	if _equip_menu == null:
		_equip_menu = PopupMenu.new()
		_equip_menu.add_item("ดูรายละเอียด", 0)
		_equip_menu.add_item("ถอดออก", 1)
		_equip_menu.id_pressed.connect(_on_equip_menu)
		add_child(_equip_menu)
	_menu_slot = slot
	_equip_menu.position = Vector2i(get_viewport().get_mouse_position())
	_equip_menu.popup()
	get_viewport().set_input_as_handled()


func _on_equip_menu(id: int) -> void:
	if _menu_slot < 0:
		return
	if id == 0:
		_on_equip_pressed(_menu_slot)
	elif id == 1:
		_unequip_selected(_menu_slot)


func _unequip_selected(slot: int) -> void:
	if PlayerState.unequip(slot):
		if _selected_equip == slot:
			_selected_equip = -1
		UI.hide_item_popup()
		refresh()


## ★ ลาก-วาง ★
func _drag_icon_of(display_index: int) -> Texture2D:
	if display_index < 0 or display_index >= _display_to_slot.size():
		return null
	var slot: int = _display_to_slot[display_index]
	if slot < 0 or sell_mode:
		return null
	var inst := PlayerState.inventory.get_slot(slot)
	if inst == null or inst.data() == null:
		return null
	var d := inst.data()
	if d.icon != null:
		return d.icon
	if d.is_card():
		return CardView.card_texture(d as CardData)
	return null


## ของถูกวางลงช่อง (display_index) — จากช่องสวมใส่ = ถอดมาไว้ช่องนี้ · จากช่องกระเป๋าอื่น = สลับที่
func _on_drop(data: Dictionary, display_index: int) -> bool:
	var kind := String(data.get("kind", ""))
	var target_slot: int = _display_to_slot[display_index] if display_index < _display_to_slot.size() else -1
	if kind == "equip":
		var eq_slot := int(data.get("slot", -1))
		var inst := PlayerState.equipment.get_item(eq_slot)
		if inst == null:
			return false
		if target_slot < 0:
			target_slot = PlayerState.inventory.first_empty()
		if target_slot < 0 or PlayerState.inventory.get_slot(target_slot) != null:
			return PlayerState.unequip(eq_slot)
		PlayerState.equipment.unequip(eq_slot)
		PlayerState.inventory.set_slot(target_slot, inst)
		PlayerState.refresh()
		UI.hide_item_popup()
		refresh()
		return true
	if kind == "inventory":
		var from_slot := int(data.get("slot", -1))
		if from_slot < 0 or from_slot == target_slot:
			return false
		# ★ รอบ 140 ★ ลากการ์ดไปวางบนอุปกรณ์ในกระเป๋าที่ใส่ได้ = ใส่การ์ด (ไม่สลับที่)
		var src := PlayerState.inventory.get_slot(from_slot)
		var dst := PlayerState.inventory.get_slot(target_slot) if target_slot >= 0 else null
		if src != null and dst != null and src.data() != null and src.data().is_card() \
				and dst.can_socket(GameData.get_card(src.item_id)):
			return _socket_into(dst, src.item_id)
		if target_slot < 0:
			target_slot = PlayerState.inventory.first_empty()
			if target_slot < 0:
				return false
		PlayerState.inventory.swap(from_slot, target_slot)
		_selected = target_slot
		refresh()
		return true
	return false


## ของจากกระเป๋าถูกลากมาวางช่องสวมใส่ (target_slot = -1 → วางที่ตัวละคร ให้ระบบเลือกช่องเอง)
func _equip_from(inv_slot: int, target_slot: int) -> bool:
	var inst := PlayerState.inventory.get_slot(inv_slot)
	if inst == null:
		return false
	var d := inst.data()
	if d == null or not d.is_equipment():
		Events.say("ไอเทมนี้สวมใส่ไม่ได้")
		return false
	if target_slot >= 0:
		var want := Equipment.slot_for(d, target_slot == Equipment.EquipSlot.ACCESSORY_2)
		if want != target_slot:
			Events.say("%s ใส่ช่อง%sไม่ได้" % [d.display_name, Equipment.SLOT_NAMES[target_slot]])
			return false
		if d.slot == ItemData.Slot.ACCESSORY:
			if PlayerState.stats.level < d.required_level:
				Events.say("ต้องเลเวล %d ขึ้นไปถึงจะใส่ %s ได้" % [d.required_level, d.display_name])
				return false
			PlayerState.inventory.set_slot(inv_slot, null)
			var old := PlayerState.equipment.equip(target_slot, inst)
			if old != null:
				PlayerState.inventory.set_slot(inv_slot, old)
			PlayerState.refresh()
			UI.hide_item_popup()
			refresh()
			return true
	var ok := PlayerState.equip_from_inventory(inv_slot)
	if ok:
		UI.hide_item_popup()
		refresh()
	return ok


func _assign_potion(slot: int) -> void:
	if _selected < 0:
		return
	var inst := PlayerState.inventory.get_slot(_selected)
	if inst == null:
		return
	var d := inst.data()
	if d == null or d.type != ItemData.Type.CONSUMABLE:
		Events.say("ตั้งได้เฉพาะของกิน/ยา")
		return
	PlayerState.set_item_hotkey(slot, inst.item_id)
	Events.say("ตั้ง %s ไว้ช่อง %s แล้ว" % [d.display_name, "Q" if slot == 0 else "R"])
	refresh()


## ★ รอบ 168 ★ ใส่ไอเทมที่เลือก (ของกินเท่านั้น) ลงแถบลัดช่อง k ของหน้าปัจจุบัน
func _assign_hotbar(k: int) -> void:
	if _selected < 0:
		return
	var inst := PlayerState.inventory.get_slot(_selected)
	if inst == null or inst.data() == null or inst.data().type != ItemData.Type.CONSUMABLE:
		Events.say("ใส่แถบลัดได้เฉพาะของกิน/ยา/ไอเทมบัพ/ปีกวาร์ป")
		return
	var slot := PlayerState.hotbar_page() * PlayerState.HOTBAR_PAGE + k
	PlayerState.set_hotbar_slot(slot, "item", inst.item_id)
	Events.say("ใส่ %s ไว้แถบลัดปุ่ม %d (หน้า %d) แล้ว" % [inst.data().display_name, k + 1, PlayerState.hotbar_page() + 1])
	refresh()


func _use_selected() -> void:
	if _card_mode:   # ★ รอบ 140 ★ ปุ่มเดียวกันกลายเป็น «ยกเลิก»
		_exit_card_mode()
		return
	if _selected_equip >= 0:   # ★ รอบ 140 ★ ของที่สวมอยู่ → ปุ่ม «ถอดออก»
		_unequip_selected(_selected_equip)
		return
	if _selected < 0:
		return
	var inst := PlayerState.inventory.get_slot(_selected)
	if inst != null and inst.data() != null and inst.data().is_card():
		_enter_card_mode(inst.item_id)   # ★ รอบ 140 ★ แบบ B — เดิมเปิดอัลบั้ม
		return
	PlayerState.use_item(_selected)
	refresh()


func _toggle_compare() -> void:
	if _selected_equip >= 0 or _card_mode:
		return
	if _selected >= 0:   # ★ รอบ 140 ★ การ์ด: ปุ่มนี้ = เปิดอัลบั้ม
		var ci := PlayerState.inventory.get_slot(_selected)
		if ci != null and ci.data() != null and ci.data().is_card():
			UI.open(&"cards")
			return
	if _selected < 0:
		return
	_comparing = not _comparing
	refresh()


func _drop_selected() -> void:
	if _selected < 0 or _selected_equip >= 0 or _card_mode:
		return
	var inst := PlayerState.inventory.get_slot(_selected)
	if inst == null:
		return
	var d := inst.data()
	if d != null and not d.can_drop:
		Events.say("ไอเทมนี้ทิ้งไม่ได้")
		return
	if d != null and d.type == ItemData.Type.QUEST:
		Events.say("ของสำคัญของเควส ทิ้งไม่ได้")
		return
	PlayerState.inventory.take_from_slot(_selected, inst.count)
	Events.say("ทิ้ง %s แล้ว" % inst.display_name())
	_selected = -1
	refresh()


# =========================================================
func refresh() -> void:
	if _grid == null:
		return
	if not is_visible_in_tree():
		return   # ★ รอบ 131 ★ ซ่อนอยู่ไม่ต้องสร้างใหม่ — show_window/open_tab จะ refresh ให้ตอนเปิด

	var inv := PlayerState.inventory
	_capacity_label.text = "%d / %d" % [inv.used_slots(), inv.size]
	_zeny_label.text = HUD._comma(PlayerState.zeny)
	set_title("กระเป๋า" + ("  [โหมดขาย — คลิกเพื่อขาย]" if sell_mode else ""))

	# ---------- ปุ่มหมวด: อันที่เลือกอยู่สว่าง ----------
	for id in _cat_buttons.keys():
		var b: Button = _cat_buttons[id]
		var on: bool = id == _category
		b.add_theme_stylebox_override("normal", _style(C_SLOT_SEL if on else C_BTN, C_SEL_EDGE if on else C_SLOT_EDGE, 4, 4))
		b.add_theme_stylebox_override("hover", _style(C_BTN_HOVER, C_SEL_EDGE if on else C_BORDER, 4, 4))
		b.add_theme_stylebox_override("pressed", _style(C_SLOT_SEL, C_SEL_EDGE, 4, 4))

	# ---------- กรองช่องตามหมวด + คำค้น แล้วเรียง ----------
	var q := _search.to_lower()
	if _category == "quest":   # ★ รอบ 155 ★ หน้าไอเทมเควสแยก
		_refresh_quest_grid(inv, q)
		_refresh_left()
		_apply_card_mode_visuals()
		_refresh_detail()
		return
	var shown: Array[int] = []
	for slot in range(inv.size):
		var inst := inv.get_slot(slot)
		if inst == null:
			continue
		if _category != "all" and _category_of(inst.data()) != _category:
			continue
		if q != "" and not inst.display_name().to_lower().contains(q):
			continue
		shown.append(slot)
	_sort_shown(shown, inv)

	for i in range(_slot_buttons.size()):
		var btn := _slot_buttons[i]
		var art: TextureRect = _slot_icons[i]
		var cnt: Label = _slot_counts[i]
		var empty: Control = _slot_empties[i]
		var slot: int = shown[i] if i < shown.size() else -1
		_display_to_slot[i] = slot
		if btn is DragSlot:
			(btn as DragSlot).slot_index = slot
		var inst := inv.get_slot(slot) if slot >= 0 else null

		if inst == null:
			btn.text = ""
			art.texture = null
			cnt.text = ""
			btn.tooltip_text = ""
			empty.visible = true
			btn.add_theme_stylebox_override("normal", _slot_box())
			continue

		empty.visible = false
		var d := inst.data()
		art.texture = d.icon if d != null and d.icon != null else null
		if art.texture == null and d != null and d.is_card():
			art.texture = CardView.card_texture(d as CardData)
			art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		btn.text = "" if art.texture != null else _short_name(inst)
		cnt.text = str(inst.count) if inst.count > 1 else ""
		btn.tooltip_text = _tooltip(inst)
		btn.add_theme_stylebox_override("normal", _slot_box(slot == _selected and not sell_mode))

	_refresh_left()
	_apply_card_mode_visuals()   # ★ รอบ 140 ★
	_refresh_detail()


## เรียงตามโหมดที่เลือก (ล่าสุด = ตามช่องจริง · ชื่อ · ชนิด · ราคา)
func _sort_shown(shown: Array[int], inv: Inventory) -> void:
	match _sort:
		1:
			shown.sort_custom(func(a, b): return inv.get_slot(a).display_name() < inv.get_slot(b).display_name())
		2:
			shown.sort_custom(func(a, b):
				var da := inv.get_slot(a).data()
				var db := inv.get_slot(b).data()
				var ta: int = int(da.type) if da != null else 99
				var tb: int = int(db.type) if db != null else 99
				return ta < tb if ta != tb else inv.get_slot(a).display_name() < inv.get_slot(b).display_name())
		3:
			shown.sort_custom(func(a, b):
				var da := inv.get_slot(a).data()
				var db := inv.get_slot(b).data()
				var pa: int = int(da.sell_price) if da != null else 0
				var pb: int = int(db.sell_price) if db != null else 0
				return pa > pb)


# ---------------------------------------------------------
func _refresh_left() -> void:
	var st := PlayerState.stats
	if st != null and _hero_name != null:
		_hero_name.text = "%s  Lv.%d" % [st.job().display_name, st.level]
	for slot in _equip_buttons.keys():
		var inst := PlayerState.equipment.get_item(slot)
		var art: TextureRect = _equip_icons[slot]
		var g: Control = _equip_glyphs[slot]
		var btn: Button = _equip_buttons[slot]
		if inst == null or inst.data() == null:
			art.texture = null
			g.visible = true
			btn.tooltip_text = "%s (ว่าง)" % String(Equipment.SLOT_NAMES.get(slot, ""))
			btn.remove_meta("armed")
		else:
			art.texture = inst.data().icon
			g.visible = art.texture == null
			btn.tooltip_text = "%s\n%s\nคลิกซ้าย = ดู · คลิกขวา/ลากออก = ถอด" % [String(Equipment.SLOT_NAMES.get(slot, "")), inst.display_name()]
		btn.add_theme_stylebox_override("normal", _slot_box(slot == _selected_equip))   # ★ รอบ 140 ★
	if _preview != null:
		_preview.refresh()
	_refresh_stats()


func _refresh_stats() -> void:
	var st := PlayerState.stats
	if st == null or _stat_values.is_empty():
		return
	_stat_values["hp"].text = str(st.max_hp)
	_stat_values["sp"].text = str(st.max_sp)
	_stat_values["atk"].text = str(st.atk)
	_stat_values["def"].text = str(st.def)
	_stat_values["speed"].text = "%d" % int(round(st.move_speed))
	_stat_values["crit"].text = "%.1f%%" % st.crit


func _refresh_detail() -> void:
	var inv := PlayerState.inventory
	var sel := _detail_target()   # ★ รอบ 140 ★ ของในกระเป๋า หรือของที่สวมอยู่
	var on_body := _selected_equip >= 0 and sel != null
	var has := sel != null and sel.data() != null
	_detail_empty.visible = not has
	_detail_art.visible = has
	_detail_name.visible = has
	_detail_rarity.visible = has
	_detail_stats.visible = has
	_detail_desc.visible = has
	_use_button.disabled = not has or sell_mode
	_use_button.tooltip_text = ""
	_compare_button.disabled = not has or on_body
	_drop_button.disabled = not has or on_body
	_potion_row.visible = false
	if _hotbar_row != null:
		_hotbar_row.visible = false
	if not has:
		_use_button.text = "สวมใส่"
		_compare_button.text = "เปรียบเทียบ"
		return

	var d := sel.data()
	_detail_art.texture = d.icon
	if _detail_art.texture == null and d.is_card():
		_detail_art.texture = CardView.card_texture(d as CardData)
	_detail_name.text = sel.display_name()
	# ★ รอบ 99 ★ กันไว้อีกชั้น: ถ้าวันหลัง rarity_of คืนของแปลก ๆ แผงต้องไม่ค้างครึ่ง ๆ กลาง ๆ
	var rar: Array = UITheme.rarity_of(d)
	if rar.size() >= 2:
		_detail_rarity.text = String(rar[0])
		_detail_rarity.add_theme_color_override("font_color", rar[1])
	else:
		_detail_rarity.text = ""
	# ★ รอบ 99 ★ การ์ด: โชว์คุณสมบัติที่ระบบสร้างให้จากค่าโบนัส (ไฟล์การ์ดส่วนใหญ่ไม่ได้เขียน description)
	var desc: String = d.description
	if d is CardData:
		var ctext: String = (d as CardData).describe()
		if ctext != "":
			desc = ctext if desc == "" else "%s\n%s" % [desc, ctext]
	_detail_desc.text = desc

	GameWindow.clear_container(_detail_stats)
	var equipped: ItemInstance = null
	if _comparing and d.is_equipment() and not on_body:
		equipped = PlayerState.equipment.get_item(Equipment.slot_for(d))
	if on_body:
		var where := _label("สวมอยู่ที่: %s" % String(Equipment.SLOT_NAMES.get(_selected_equip, "")), 11, C_TEXT_DIM)
		_detail_stats.add_child(where)
	if sel.card_slots() > 0:   # ★ รอบ 140 ★ ช่องการ์ด (ลาก/กดได้) — วางไว้บนค่าพลังให้เห็นทันทีไม่ต้องเลื่อน
		_detail_stats.add_child(_card_slots_panel(sel))
	for row in _stat_lines(sel, equipped):
		var r := PetrolWidgets.stat_row(String(row[0]), String(row[1]), String(row[2]), row[3], 13)
		_detail_stats.add_child(r)
	if _comparing and d.is_equipment():
		var note := _label("เทียบกับที่สวมอยู่: %s" % (equipped.display_name() if equipped != null else "(ว่าง)"), 11, C_TEXT_DIM)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail_stats.add_child(note)
	if d.sell_price > 0:
		_detail_stats.add_child(PetrolWidgets.stat_row("coin", "ราคาขาย", HUD._comma(d.sell_price), C_ZENY_TEXT, 12))

	if _card_mode:
		_use_button.text = "ยกเลิกการใส่การ์ด (Esc)"
		var hint := _label("คลิกอุปกรณ์ที่เรืองแสง (ในกระเป๋าหรือที่สวมอยู่) เพื่อใส่การ์ดใบนี้", 12, UITheme.GOLD_BRIGHT)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail_stats.add_child(hint)
	elif on_body:
		_use_button.text = "ถอดออก"
	elif d.is_card():
		_use_button.text = "ใส่การ์ดลงอุปกรณ์…"
		_use_button.disabled = PlayerState.sockets_for_card(sel.item_id).is_empty()
		if _use_button.disabled:
			_use_button.tooltip_text = "ยังไม่มี%sที่มีช่องว่าง" % (d as CardData).slot_name()
	elif d.is_equipment():
		_use_button.text = "สวมใส่"
	else:
		_use_button.text = "ใช้"
	if d.is_card():
		_compare_button.text = "เปิดอัลบั้มการ์ด"
		_compare_button.disabled = _card_mode
	else:
		_compare_button.text = "เลิกเปรียบเทียบ" if _comparing else "เปรียบเทียบ"
		_compare_button.disabled = not d.is_equipment() or on_body

	if d.type == ItemData.Type.QUEST:   # ★ รอบ 155 ★ ไอเทมเควส: ดูได้อย่างเดียว
		_use_button.text = "ไอเทมเควส"
		_use_button.disabled = true
		_compare_button.disabled = true
		_drop_button.disabled = true
		var qnote := _label("ของสำคัญของเควส — ไม่กินช่องกระเป๋า · ขาย/ทิ้งไม่ได้", 11, C_TEXT_DIM)
		qnote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail_stats.add_child(qnote)

	if d.type == ItemData.Type.CONSUMABLE:
		_potion_row.visible = true
		for i in range(PlayerState.ITEM_HOTKEY_COUNT):
			var btn: Button = _set_q_button if i == 0 else _set_r_button
			var base: String = "ตั้งช่อง Q" if i == 0 else "ตั้งช่อง R"
			btn.text = ("★ " + base) if PlayerState.item_hotkey_at(i) == sel.item_id else base
		if _hotbar_row != null:   # ★ รอบ 168 ★
			_hotbar_row.visible = true
			for k in range(_hotbar_btns.size()):
				var e := PlayerState.hotbar_slot(PlayerState.hotbar_page() * PlayerState.HOTBAR_PAGE + k)
				var mine := String(e.get("kind", "")) == "item" and StringName(e.get("id", &"")) == sel.item_id
				_hotbar_btns[k].text = ("★" if mine else "") + str(k + 1)
				_hotbar_btns[k].tooltip_text = "ปุ่ม %d: %s" % [k + 1, PlayerState.hotbar_tooltip(PlayerState.hotbar_page() * PlayerState.HOTBAR_PAGE + k).get_slice("\n", 0)]


## แถวค่าพลังของไอเทม [glyph, ชื่อ, ค่า, สี] — ถ้าเทียบอยู่ ค่าจะเป็น "ของใหม่ (±ต่างจากที่ใส่)"
func _stat_lines(inst: ItemInstance, equipped: ItemInstance) -> Array:
	var d := inst.data()
	var out: Array = []
	var add := func(glyph: String, label: String, mine: float, theirs: float, fmt: String, is_pct: bool = false):
		if mine == 0.0 and (equipped == null or theirs == 0.0):
			return
		var text: String = CardData.percent_text(mine, true) if is_pct else fmt % mine
		var color: Color = C_TEXT
		if equipped != null:
			var diff := mine - theirs
			if absf(diff) > 0.001:
				text += "  (%s)" % (CardData.percent_text(diff, true) if is_pct else ("+" if diff > 0 else "") + str(int(diff)))
				color = UITheme.GOOD if diff > 0 else UITheme.BAD
		out.append([glyph, label, text, color])
	var eatk: float = float(equipped.total_atk()) if equipped != null else 0.0
	var edef: float = float(equipped.total_def()) if equipped != null else 0.0
	var ed: ItemData = equipped.data() if equipped != null else null
	if d.type == ItemData.Type.WEAPON or inst.total_atk() != 0:
		add.call("attack", "โจมตี", float(inst.total_atk()), eatk, "%d")
	if inst.total_def() != 0 or edef != 0.0:
		add.call("defense", "ป้องกัน", float(inst.total_def()), edef, "%d")
	for row in [["matk", "attack", "MATK"], ["mdef", "defense", "MDEF"], ["hit", "crit", "HIT"],
			["flee", "speed", "FLEE"], ["crit", "crit", "อัตราคริ"], ["max_hp", "hp", "MaxHP"], ["max_sp", "sp", "MaxSP"]]:
		add.call(String(row[1]), String(row[2]), float(inst.boosted(float(d.get(row[0])))),
			float(equipped.boosted(float(ed.get(row[0])))) if ed else 0.0, "+%d")
	add.call("speed", "ASPD", d.aspd_percent, ed.aspd_percent if ed else 0.0, "+%.0f%%", true)
	add.call("speed", "ความเร็ว", d.move_speed_percent if "move_speed_percent" in d else 0.0,
		(ed.move_speed_percent if ed != null and "move_speed_percent" in ed else 0.0), "+%.1f%%", true)
	for pair in [["skill_damage_percent", "ดาเมจสกิล"], ["crit_damage_percent", "ดาเมจคริ"],
			["cooldown_reduction_percent", "ลดคูลดาวน์"], ["hp_drain_percent", "ดูดเลือด"],
			["sp_drain_percent", "ดูดมานา"], ["hp_percent", "MaxHP"],
			["sp_percent", "MaxSP"], ["defense_percent", "ป้องกัน"], ["damage_percent", "ดาเมจ"]]:
		add.call("crit", String(pair[1]), float(d.get(pair[0])),
			float(ed.get(pair[0])) if ed else 0.0, "+%.2f%%", true)
	for pair in [["bonus_str", "STR"], ["bonus_agi", "AGI"], ["bonus_vit", "VIT"], ["bonus_int", "INT"], ["bonus_dex", "DEX"], ["bonus_luk", "LUK"]]:
		add.call("crit", String(pair[1]), float(inst.boosted(float(d.get(pair[0])))),
			float(equipped.boosted(float(ed.get(pair[0])))) if ed else 0.0, "+%d")
	if d.heal_hp != 0 or d.heal_hp_percent != 0.0:
		out.append(["hp", "ฟื้น HP", "%d (+%.0f%%)" % [d.heal_hp, d.heal_hp_percent], UITheme.GOOD])
	if d.heal_sp != 0 or d.heal_sp_percent != 0.0:
		out.append(["sp", "ฟื้น SP", "%d (+%.0f%%)" % [d.heal_sp, d.heal_sp_percent], UITheme.GOOD])
	if d.required_level > 1:
		out.append(["crit", "ต้องเลเวล", str(d.required_level),
			C_TEXT if PlayerState.stats.level >= d.required_level else UITheme.BAD])
	if d is CardData:
		var c := d as CardData
		out.append(["all", "ใส่ใน", c.slot_name(), C_TEXT])
	return out


func _short_name(inst: ItemInstance) -> String:
	var d := inst.data()
	var n: String = d.display_name if d != null else String(inst.item_id)
	return n.substr(0, 8)


func _tooltip(inst: ItemInstance) -> String:
	var d := inst.data()
	if d == null:
		return String(inst.item_id)
	var lines: Array[String] = [inst.display_name()]
	if d.description != "":
		lines.append(d.description)
	for row in _stat_lines(inst, null):
		lines.append("%s %s" % [row[1], row[2]])
	if d is CardData:
		lines.append((d as CardData).describe())
	if d.type == ItemData.Type.QUEST:
		lines.append("ของสำคัญ — ขาย/ทิ้งไม่ได้")
	return "\n".join(lines)


# =========================================================
# ★★ รอบ 140 ★★ การ์ดในหน้ากระเป๋า (แบบ A ลาก/กดช่อง + แบบ B เลือกการ์ดแล้วชี้เป้า) และช่องสวมใส่คลิกซ้าย = ดู
# =========================================================
## ของที่แผงขวากำลังโชว์: ของในกระเป๋า (_selected) หรือของที่สวมอยู่ (_selected_equip)
func _detail_target() -> ItemInstance:
	if _category == "quest":   # ★ รอบ 155 ★
		var qi: Array = PlayerState.inventory.quest_items
		return qi[_quest_sel] if _quest_sel >= 0 and _quest_sel < qi.size() else null
	if _selected_equip >= 0:
		return PlayerState.equipment.get_item(_selected_equip)
	return PlayerState.inventory.get_slot(_selected) if _selected >= 0 else null


## แถวช่องการ์ดของอุปกรณ์ชิ้นนี้ — ช่องละปุ่ม: ว่าง = «+» กดเลือกการ์ด/ลากการ์ดมาวาง · มีการ์ด = กดดู/ถอด
func _card_slots_panel(inst: ItemInstance) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var head := _label("ช่องการ์ด  %d / %d" % [inst.cards.size(), inst.card_slots()], 12, C_GOLD)
	box.add_child(head)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	for i in range(inst.card_slots()):
		var card: CardData = GameData.get_card(inst.cards[i]) if i < inst.cards.size() else null
		var btn := DragSlot.new()
		btn.kind = "cardslot"
		btn.slot_index = i
		btn.custom_minimum_size = Vector2(56, 70)
		btn.clip_contents = true
		btn.add_theme_stylebox_override("normal", _slot_box(card != null))
		btn.add_theme_stylebox_override("hover", _slot_box(true))
		btn.add_theme_stylebox_override("pressed", _slot_box(true))
		var target := inst
		var index := i
		btn.can_drop_func = func(data: Dictionary, _t: DragSlot) -> bool:
			if String(data.get("kind", "")) != "inventory" or card != null:
				return false
			var src := PlayerState.inventory.get_slot(int(data.get("slot", -1)))
			return src != null and src.data() != null and src.data().is_card() and target.can_socket(GameData.get_card(src.item_id))
		btn.drop_func = func(data: Dictionary, _t: DragSlot) -> bool:
			var src := PlayerState.inventory.get_slot(int(data.get("slot", -1)))
			return src != null and _socket_into(target, src.item_id)
		if card != null:
			var art := UITheme.make_slot_icon(btn, 4.0)[0] as TextureRect
			art.texture = CardView.card_texture(card)
			art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			btn.tooltip_text = "%s\n%s\nคลิก = ดู / ถอด" % [card.display_name, card.describe().replace("\n", " · ")]
			btn.pressed.connect(func(): _show_socketed_card(target, index, btn))
		else:
			btn.text = "+"
			btn.add_theme_font_size_override("font_size", 24)
			btn.add_theme_color_override("font_color", C_TEXT_DIM)
			btn.tooltip_text = "ช่องว่าง — ลากการ์ดมาวาง หรือกดเลือกจากการ์ดที่มี"
			btn.pressed.connect(func(): _open_card_picker(target, btn))
		row.add_child(btn)
	return box


## กดการ์ดที่ใส่อยู่ → กล่องรายละเอียด + ปุ่มถอด
func _show_socketed_card(inst: ItemInstance, index: int, anchor: Control) -> void:
	var card := GameData.get_card(inst.cards[index]) if index < inst.cards.size() else null
	if card == null:
		return
	UI.show_info(card.display_name, CardView.card_texture(card), card.describe(), anchor, card.rarity_color(),
		[{"text": "ถอดการ์ดออก", "on": _unsocket_from.bind(inst, index)}])


func _unsocket_from(inst: ItemInstance, index: int) -> void:
	UI.hide_item_popup()
	if PlayerState.inventory.is_full():
		Events.say("กระเป๋าเต็ม — เก็บของให้ว่างก่อนถอดการ์ด")
		return
	PlayerState.unsocket_card(inst, index)
	refresh()


## กด «+» ที่ช่องว่าง → เมนูการ์ดในกระเป๋าที่ใส่ชิ้นนี้ได้
func _open_card_picker(inst: ItemInstance, anchor: Control) -> void:
	var menu := PopupMenu.new()
	var ids: Array = []
	for i in range(PlayerState.inventory.size):
		var s := PlayerState.inventory.get_slot(i)
		if s == null or s.data() == null or not s.data().is_card() or ids.has(s.item_id):
			continue
		var card := GameData.get_card(s.item_id)
		if card == null or not inst.can_socket(card):
			continue
		ids.append(s.item_id)
		menu.add_item("%s ×%d — %s" % [card.display_name, PlayerState.inventory.count_of(s.item_id), card.describe().replace("\n", " · ")], ids.size() - 1)
	if ids.is_empty():
		Events.say("ยังไม่มีการ์ดที่ใส่ %s ได้ในกระเป๋า" % inst.display_name())
		menu.queue_free()
		return
	add_child(menu)
	menu.id_pressed.connect(func(id: int): _socket_into(inst, ids[id]))
	menu.popup_hide.connect(func(): menu.call_deferred("queue_free"))
	menu.position = Vector2i(anchor.global_position + Vector2(0, anchor.size.y))
	menu.popup()


## ใส่การ์ดลงของชิ้นนี้ (ทางเดียวที่ทุกวิธีเรียก) — คืน true ถ้าใส่ได้
func _socket_into(inst: ItemInstance, card_id: StringName) -> bool:
	if inst == null:
		return false
	var ok := PlayerState.socket_card(card_id, inst)
	if ok:
		UI.hide_item_popup()
		if _card_mode:   # ใส่เสร็จ 1 ใบ = จบโหมด (กดปุ่มใหม่ถ้าจะใส่อีก)
			_exit_card_mode()
		refresh()
	return ok


## ---------- แบบ B: โหมดใส่การ์ด ----------
func _enter_card_mode(card_id: StringName) -> void:
	if PlayerState.sockets_for_card(card_id).is_empty():
		var c := GameData.get_card(card_id)
		Events.say("ยังไม่มี%sที่มีช่องว่างให้ใส่การ์ดใบนี้" % (c.slot_name() if c != null else "อุปกรณ์"))
		return
	_card_mode = true
	_card_pick = card_id
	UI.hide_item_popup()
	Events.say("เลือกอุปกรณ์ที่เรืองแสงเพื่อใส่ %s (Esc ยกเลิก)" % GameData.item_name(card_id))
	refresh()


func _exit_card_mode() -> void:
	_card_mode = false
	_card_pick = &""
	refresh()


## คลิกเป้าในโหมดการ์ด → ถามยืนยัน → ใส่
func _card_mode_target(inst: ItemInstance) -> void:
	if inst == null or not _card_mode:
		return
	var card := GameData.get_card(_card_pick)
	if card == null:
		_exit_card_mode()
		return
	if not inst.can_socket(card):
		Events.say("%s ใส่การ์ดใบนี้ไม่ได้ — ต้องเป็น%sที่มีช่องว่าง" % [inst.display_name(), card.slot_name()])
		return
	_confirm_socket(inst, _card_pick)


func _confirm_socket(inst: ItemInstance, card_id: StringName) -> void:
	var card := GameData.get_card(card_id)
	var ok: bool = await UI.ask("ใส่การ์ด", "ใส่ %s ลงใน %s ?\n(ช่องว่าง %d/%d · ถอดออกทีหลังได้ที่แผงขวา)" % [card.display_name, inst.display_name(), inst.free_card_slots(), inst.card_slots()], "ใส่เลย", "ยกเลิก")
	if ok and is_instance_valid(self):
		_socket_into(inst, card_id)


## เรืองแสงของที่ใส่ได้ · หรี่ของที่ใส่ไม่ได้ (ทั้งกริดกระเป๋าและช่องสวมใส่)
func _apply_card_mode_visuals() -> void:
	var card: CardData = GameData.get_card(_card_pick) if _card_mode else null
	for i in range(_slot_buttons.size()):
		var btn := _slot_buttons[i]
		var slot: int = _display_to_slot[i] if i < _display_to_slot.size() else -1
		var inst := PlayerState.inventory.get_slot(slot) if slot >= 0 else null
		if card == null:
			btn.modulate = Color.WHITE
			continue
		var can: bool = inst != null and inst.can_socket(card)
		btn.modulate = Color.WHITE if can else Color(1, 1, 1, 0.35)
		if can:
			btn.add_theme_stylebox_override("normal", _hot_box())
	for slot in _equip_buttons.keys():
		var b: Button = _equip_buttons[slot]
		var e := PlayerState.equipment.get_item(slot)
		if card == null:
			b.modulate = Color.WHITE
			continue
		var can2: bool = e != null and e.can_socket(card)
		b.modulate = Color.WHITE if can2 else Color(1, 1, 1, 0.35)
		if can2:
			b.add_theme_stylebox_override("normal", _hot_box())


## กรอบทองเรืองสำหรับเป้าที่ใส่การ์ดได้
static func _hot_box() -> StyleBoxFlat:
	var s := UITheme.slot_style(true)
	s.border_color = UITheme.GOLD_BRIGHT
	s.set_border_width_all(2)
	s.shadow_color = Color(UITheme.GOLD_BRIGHT, 0.45)
	s.shadow_size = 6
	return s


## ★ รอบ 155 ★ กริดหน้า «ไอเทมเควส» — ใช้ปุ่มช่องชุดเดิม เข้ารหัสลำดับเป็น -2 - k (ลากไม่ได้)
func _refresh_quest_grid(inv: Inventory, q: String) -> void:
	var list: Array = []
	for k in range(inv.quest_items.size()):
		var it: ItemInstance = inv.quest_items[k]
		if q != "" and not it.display_name().to_lower().contains(q):
			continue
		list.append(k)
	if _quest_sel >= inv.quest_items.size():
		_quest_sel = -1
	for i in range(_slot_buttons.size()):
		var btn := _slot_buttons[i]
		var art: TextureRect = _slot_icons[i]
		var cnt: Label = _slot_counts[i]
		var empty: Control = _slot_empties[i]
		if btn is DragSlot:
			(btn as DragSlot).slot_index = -1
		if i >= list.size():
			_display_to_slot[i] = -1
			btn.text = ""
			art.texture = null
			cnt.text = ""
			btn.tooltip_text = ""
			empty.visible = true
			btn.add_theme_stylebox_override("normal", _slot_box())
			continue
		var k: int = list[i]
		var inst: ItemInstance = inv.quest_items[k]
		_display_to_slot[i] = -2 - k
		empty.visible = false
		var d := inst.data()
		art.texture = d.icon if d != null and d.icon != null else null
		btn.text = "" if art.texture != null else _short_name(inst)
		cnt.text = str(inst.count) if inst.count > 1 else ""
		btn.tooltip_text = _tooltip(inst)
		btn.add_theme_stylebox_override("normal", _slot_box(k == _quest_sel))
