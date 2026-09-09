## IconMenuBar — แถบเมนูมุมขวาบน (โฉม Petrol รอบ 98)
##
##   [ตัวละคร] [กระเป๋า] [สกิล] [เควส] [แผนที่] [ระบบ]   ← ไอคอน 26 px + ชื่อใต้ไอคอน ไม่มีพื้นหลัง (ตามภาพ)
##   ตัวละครมีป้ายแดง "1" เมื่อมีแต้มสเตตัส/สกิลค้างอยู่
##
## ไอคอนมาจากชุด petrol: res://Sprites/ui/petrol/icons/<id>.svg (สำรอง: Sprites/ui_icons/<id>.png · วาดเองถ้าไม่มีทั้งคู่)
## กดแล้วเปิด "หน้าต่างรวม" (MenuShell) ที่แท็บนั้น
class_name IconMenuBar
extends Control

const BTN_W := 72.0
const BTN_H := 62.0
const ICON := 28.0
const MARGIN := 12.0

## รายการปุ่ม — เพิ่ม/ลด/สลับลำดับได้ตามใจ (tab = แท็บในหน้าต่างรวม)
const ITEMS := [
	{"id": "status",    "tab": "status",    "key": "C",   "label": "ตัวละคร"},
	{"id": "inventory", "tab": "inventory", "key": "I",   "label": "กระเป๋า"},
	{"id": "skills",    "tab": "skills",    "key": "K",   "label": "สกิล"},
	{"id": "quests",    "tab": "quests",    "key": "U",   "label": "เควส"},
	{"id": "map",       "tab": "map",       "key": "M",   "label": "แผนที่"},
	{"id": "system",    "tab": "system",    "key": "Tab", "label": "ระบบ"},
]

## (เก็บไว้ให้โค้ดเก่าที่อ้างถึง — แถบเมนูรอบ 98 ไม่ผูกกับมินิแมพแล้ว)
var minimap: Minimap

var _buttons: Dictionary = {}     # id -> Button
var _badges: Dictionary = {}      # id -> Label
var _timer := 0.0


func _ready() -> void:
	name = "MenuBar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	for entry in ITEMS:
		var btn := _make_button(entry)
		row.add_child(btn)
		_buttons[entry.id] = btn

	get_viewport().size_changed.connect(place)
	place.call_deferred()


func _make_button(entry: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(BTN_W, BTN_H)
	btn.focus_mode = Control.FOCUS_NONE
	btn.flat = true
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	# ฟอนต์ 1 px — ข้อความจริงอยู่ที่ป้ายซ้อนข้างใน
	btn.add_theme_font_size_override("font_size", 1)
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("focus", empty)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(UITheme.TEXT, 0.06)
	hover.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(UITheme.ACCENT, 0.18)
	pressed.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.tooltip_text = "%s  (%s)" % [entry.label, entry.key]

	# ---------- ไอคอน ----------
	var tex := UITheme.icon(String(entry.id))
	var art: Control
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		art = tr
	else:
		art = PetrolWidgets.glyph(String(entry.id), ICON)
	art.name = "Art"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	art.offset_left = -ICON * 0.5
	art.offset_right = ICON * 0.5
	art.offset_top = 8
	art.offset_bottom = 8 + ICON
	btn.add_child(art)

	# ---------- ชื่อใต้ไอคอน ----------
	var cap := UITheme.make_label(String(entry.label), 11, UITheme.TEXT)
	cap.name = "Caption"
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	cap.offset_top = -20
	cap.offset_bottom = -4
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cap.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	cap.add_theme_constant_override("outline_size", 3)
	btn.add_child(cap)

	# ---------- ป้ายแดงมุมขวาบนของไอคอน ----------
	var badge := Label.new()
	badge.name = "Badge"
	badge.text = "1"
	badge.visible = false
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color.WHITE)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color("#d1382e")
	bs.set_corner_radius_all(99)
	bs.content_margin_left = 4
	bs.content_margin_right = 4
	badge.add_theme_stylebox_override("normal", bs)
	badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	badge.offset_left = ICON * 0.5 - 6
	badge.offset_right = ICON * 0.5 + 10
	badge.offset_top = 2
	badge.offset_bottom = 18
	btn.add_child(badge)
	_badges[entry.id] = badge

	var tab := String(entry.tab)
	btn.pressed.connect(func(): Events.toggle_window.emit(StringName(tab)))
	return btn


# =========================================================
# ตำแหน่ง — มุมขวาบนเสมอ
# =========================================================
func place() -> void:
	var screen := get_viewport_rect().size
	var row := get_node_or_null("Row") as Control
	var w: float = BTN_W * ITEMS.size()
	var h: float = BTN_H
	if row != null:
		row.reset_size()
		w = maxf(row.size.x, row.get_combined_minimum_size().x)
		h = maxf(row.size.y, row.get_combined_minimum_size().y)
	size = Vector2(w, h)
	position = Vector2(screen.x - w - MARGIN, MARGIN)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		place()


# =========================================================
# ปุ่มของแท็บที่เปิดอยู่ = สว่างขึ้น · ป้ายแดงเมื่อมีแต้มค้าง
# =========================================================
func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = 0.2
	var current: String = ""
	if UI.shell != null and UI.shell.visible:
		current = UI.shell.current_tab
	for entry in ITEMS:
		var btn: Button = _buttons.get(entry.id)
		if btn == null:
			continue
		var on: bool = current != "" and (String(entry.tab) == current \
			or (String(entry.tab) == "status" and current == "equipment"))
		btn.modulate = Color(1.3, 1.22, 0.9) if on else Color.WHITE
	# ป้ายแดง: แต้มสเตตัส/สกิลที่ยังไม่ได้ใช้
	var st := PlayerState.stats
	if st != null:
		var stat_pts: int = int(st.stat_points) if "stat_points" in st else 0
		var skill_pts: int = int(st.skill_points) if "skill_points" in st else 0
		_set_badge("status", stat_pts)
		_set_badge("skills", skill_pts)


func _set_badge(id: String, n: int) -> void:
	var b: Label = _badges.get(id)
	if b == null:
		return
	b.visible = n > 0
	b.text = str(mini(n, 99))
