## MenuShell — "หน้าต่างรวม" กลางจอ มีแถบแท็บด้านบน (โฉม Petrol รอบ 98 ตามภาพตัวอย่าง)
##
##   ┌─ สเตตัส · กระเป๋า · สกิล · การ์ด · เควส · แผนที่ · ระบบ ──────────────────── ✕ ┐
##   │  (หน้าของแท็บที่เลือก — คือ GameWindow เดิม ๆ ที่ถูกย้ายมาอยู่ข้างในแบบไม่มีหัวเรื่อง)   │
##   └───────────────────────────────────────────────────────────────────────────────┘
##        E ใช้/สวม   C เปรียบเทียบ   X ทิ้ง   Esc ปิด        ← คำใบ้ปุ่มของหน้านั้น
##
## หน้าต่างที่เป็นแท็บ: status/equipment (หน้าเดียวกัน) · inventory · skills · cards · quests · map · system
## หน้าต่างที่ NPC เปิด (ร้านค้า/ตีบวก/เจาะรู) และห้อง GM ยังลอยแยกเหมือนเดิม
class_name MenuShell
extends Control

## ★ รอบ 102 ★ ขยายกรอบให้กว้างขึ้น (เดิม 1000×572 = เนื้อหากองมุมซ้าย เหลือที่ว่างครึ่งจอ)
const FRAME_SIZE := Vector2(1180, 640)
const TABS := [
	# ★ รอบ 102 ★ เอาแท็บ "สวมใส่" ออก — มันชี้หน้าเดียวกับ "สเตตัส" อยู่แล้ว (ซ้ำซ้อน)
	# ปุ่ม C / คำสั่ง UI.toggle(&"equipment") ยังเปิดหน้านี้ได้เหมือนเดิม แค่ไม่มีแท็บซ้ำบนแถบ
	{"id": "status",    "label": "สเตตัส"},
	{"id": "inventory", "label": "กระเป๋า"},
	{"id": "skills",    "label": "สกิล"},
	{"id": "cards",     "label": "การ์ด"},
	{"id": "quests",    "label": "เควส"},
	{"id": "map",       "label": "แผนที่"},
	{"id": "system",    "label": "ระบบ"},
]
const DEFAULT_HINTS := [["Esc", "ปิด"]]

var current_tab: String = ""
var frame: PanelContainer
var page_area: Control
var hint_row: HBoxContainer
var _tab_buttons: Dictionary = {}     # id -> Button
var _tab_marks: Dictionary = {}       # id -> Control (ขีดทองใต้แท็บ)
var _pages: Dictionary = {}           # tab id -> GameWindow
var _dim: ColorRect


func _ready() -> void:
	name = "MenuShell"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	# ม่านมืดจาง ๆ ทับเกม (คลิกโดนม่าน = ไม่ทะลุไปตีมอน แต่ไม่ปิดหน้าต่าง)
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.35)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	frame = PanelContainer.new()
	frame.name = "Frame"
	frame.add_theme_stylebox_override("panel", UITheme.panel_style(Color(UITheme.BG, 0.95), UITheme.ACCENT, 4, 1, 0.0))
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	frame.clip_contents = true
	add_child(frame)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	frame.add_child(root)

	# ---------- แถบแท็บ ----------
	var strip := HBoxContainer.new()
	strip.name = "Tabs"
	strip.add_theme_constant_override("separation", 0)
	strip.custom_minimum_size.y = 50
	root.add_child(strip)
	# ★ รอบ 102 ★ แท็บกระจายกลางแถบ (เดิมชิดซ้ายด้วยช่องว่างคงที่ 60 px)
	var lead := Control.new()
	lead.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.add_child(lead)
	for t in TABS:
		var btn := _make_tab(t)
		strip.add_child(btn)
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.add_child(fill)
	var close := _make_close()
	strip.add_child(close)

	root.add_child(UITheme.separator())

	# ---------- พื้นที่หน้า ----------
	# ★★ รอบ 102 (รอบสาม) ★★ เดิมเป็น MarginContainer → **ขนาดขั้นต่ำของหน้าไหลขึ้นมาถึงกรอบ**
	# พอหน้าไหนมีของเยอะ (หรือมีตัวคำนวณขนาดช่องจากความกว้างจริง) กรอบจะโตตาม
	# แล้ววนซ้ำ: กรอบโต → กล่องเลื่อนโต → ช่องโต → ขนาดขั้นต่ำโต → กรอบโตอีก
	# (เจอจริง: หน้าระบบดันกรอบจาก 640 เป็น 1051 px จนทะลุออกนอกจอ)
	# → เปลี่ยนเป็น Control ธรรมดา ซึ่ง "ขนาดขั้นต่ำ = 0 เสมอ ไม่สนลูก"
	#   กรอบจึงคุมขนาดตัวเองได้เด็ดขาด · ระยะขอบย้ายไปเป็น offset ของหน้า (ดู GameWindow.set_embedded)
	page_area = Control.new()
	page_area.name = "Page"
	page_area.custom_minimum_size = Vector2.ZERO
	page_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_area.clip_contents = true
	page_area.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(page_area)

	# ---------- คำใบ้ปุ่ม (ใต้กรอบ) ----------
	hint_row = HBoxContainer.new()
	hint_row.name = "Hints"
	hint_row.add_theme_constant_override("separation", 22)
	hint_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hint_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint_row)

	# มุมประดับ 4 มุม
	frame.add_child(PetrolWidgets.corner_marks(5.0, 12.0))

	get_viewport().size_changed.connect(_layout)
	_layout.call_deferred()


func _make_tab(t: Dictionary) -> Button:
	var id := String(t.id)
	var btn := Button.new()
	btn.text = String(t.label)
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(96, 50)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	btn.add_theme_color_override("font_hover_color", UITheme.TEXT)
	btn.add_theme_color_override("font_pressed_color", UITheme.GOLD_BRIGHT)
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(st, empty)
	btn.pressed.connect(func(): open_tab(id))
	# ขีดทอง + เพชรเล็กใต้แท็บที่เลือก
	var mark := PetrolWidgets.ornament(60.0, UITheme.ACCENT, 3.0)
	mark.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	mark.offset_left = 18
	mark.offset_right = -18
	mark.offset_top = -12
	mark.offset_bottom = -2
	mark.visible = false
	btn.add_child(mark)
	_tab_buttons[id] = btn
	_tab_marks[id] = mark
	return btn


func _make_close() -> Button:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(56, 50)
	btn.tooltip_text = "ปิด (Esc)"
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(st, empty)
	var tex := UITheme.component("close")
	if tex != null:
		var art := TextureRect.new()
		art.texture = tex
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		art.offset_left = -13
		art.offset_top = -13
		art.offset_right = 13
		art.offset_bottom = 13
		btn.add_child(art)
	else:
		btn.text = "✕"
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_color_override("font_color", UITheme.TEXT)
	btn.pressed.connect(close)
	return btn


# =========================================================
# ลงทะเบียนหน้า (UI เรียกตอนสร้าง)
# =========================================================
func register_page(tab_id: String, window: GameWindow) -> void:
	_pages[tab_id] = window
	if window.get_parent() != page_area:
		if window.get_parent() != null:
			window.get_parent().remove_child(window)
		page_area.add_child(window)
	window.set_embedded(true, tab_id)
	window.visible = false


func page_of(tab_id: String) -> GameWindow:
	return _pages.get(tab_id, null)


func is_tab(tab_id: String) -> bool:
	return _pages.has(tab_id)


# =========================================================
# เปิด / ปิด / สลับ
# =========================================================
func open_tab(tab_id: String) -> void:
	var page: GameWindow = _pages.get(tab_id, null)
	if page == null:
		return
	var was_open := visible and current_tab == tab_id
	# ซ่อนหน้าอื่น (หน้าเดียวกันอาจถูกใช้ 2 แท็บ เช่น status/equipment)
	for id in _pages.keys():
		var w: GameWindow = _pages[id]
		if w != page:
			w.visible = false
	current_tab = tab_id
	visible = true
	page.visible = true
	page.refresh()
	if page.has_method("on_shell_shown"):
		page.on_shell_shown(tab_id)
	UI.hide_item_popup()
	_refresh_tabs()
	_refresh_hints(page)
	_layout()
	if not was_open and page.has_signal("shell_opened"):
		page.shell_opened.emit()


func toggle_tab(tab_id: String) -> void:
	if visible and current_tab == tab_id:
		close()
	elif visible and _same_page(current_tab, tab_id):
		# แท็บคนละชื่อแต่หน้าเดียวกัน (สเตตัส/สวมใส่) → ปิดเหมือนกดซ้ำ
		close()
	else:
		open_tab(tab_id)


func _same_page(a: String, b: String) -> bool:
	return a != "" and b != "" and _pages.get(a, null) == _pages.get(b, null)


func close() -> void:
	if not visible:
		return
	for id in _pages.keys():
		(_pages[id] as GameWindow).visible = false
	visible = false
	current_tab = ""
	UI.hide_item_popup()


func is_showing(window: GameWindow) -> bool:
	return visible and current_tab != "" and _pages.get(current_tab, null) == window


func _refresh_tabs() -> void:
	for id in _tab_buttons.keys():
		var btn: Button = _tab_buttons[id]
		var on: bool = id == current_tab
		btn.add_theme_color_override("font_color", UITheme.TEXT if on else UITheme.TEXT_DIM)
		(_tab_marks[id] as Control).visible = on


func _refresh_hints(page: GameWindow) -> void:
	GameWindow.clear_container(hint_row)
	var hints: Array = page.shell_hints() if page.has_method("shell_hints") else []
	if hints.is_empty():
		hints = DEFAULT_HINTS
	for h in hints:
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 6)
		var key := PanelContainer.new()
		key.add_theme_stylebox_override("panel", TouchControls._pill_style())
		var kl := UITheme.make_label(String(h[0]), 11, UITheme.TEXT)
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key.add_child(kl)
		pair.add_child(key)
		pair.add_child(UITheme.make_label(String(h[1]), 12, UITheme.TEXT_DIM))
		hint_row.add_child(pair)


# =========================================================
# ตำแหน่ง/ขนาด — กลางจอ ย่อตามจอเล็ก
# =========================================================
func _layout() -> void:
	if frame == null:
		return
	var vp := get_viewport_rect().size
	var fsize := Vector2(minf(FRAME_SIZE.x, vp.x - 40.0), minf(FRAME_SIZE.y, vp.y - 90.0))
	frame.custom_minimum_size = fsize
	frame.size = fsize
	frame.position = ((vp - fsize) * 0.5 - Vector2(0, 12)).floor()
	hint_row.reset_size()
	var hw: float = maxf(hint_row.size.x, hint_row.get_combined_minimum_size().x)
	hint_row.position = Vector2(vp.x * 0.5 - hw * 0.5, frame.position.y + fsize.y + 14)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("close_windows") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
