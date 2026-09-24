## SystemWindow — ★ รอบ 166 ★ หน้า «ระบบ» แบบ C «เมนูหยุดเกม» (ผู้ใช้เลือกจาก `_docs/mockup_รอบ164_หน้าระบบ_C.png`)
##
## ซ้าย  = สรุปตัวละคร: รูปหน้าใหญ่ + ตราขั้นกิลด์ · Lv/อาชีพ · ขั้นกิลด์ + ส่วนลด + หลอดไปขั้นถัดไป · แมพ · เวลาเล่น · ซีนี · เควส · สมุดการ์ด
## กลาง = เมนูตัวใหญ่ (ชี้/↑↓ = ดูแผงขวา · คลิก/Enter = ใช้) : กลับเข้าเกม · บันทึกเกม · โหลดเกม · เสียง · ภาษา · การควบคุม · กลับหน้าหลัก · ออกจากเกม
## ขวา  = แผงของเมนูที่เลือก (ช่องเซฟมีรูปหน้า + ตราขั้นกิลด์ของเซฟนั้น · Lv · อาชีพ · แมพ · วันเวลา · เวลาเล่น)
## ของเดิมคงไว้: _do_save/_do_load/_do_delete/_do_new_game/_do_go_title · สไลเดอร์เสียง · ปุ่มจอสัมผัส · ปุ่มภาษา · _slot_rows (โหลด)
class_name SystemWindow
extends GameWindow

const LEFT_W := 300.0
const MENU_W := 270.0
const MENU_ITEMS := [
	["resume", "กลับเข้าเกม"], ["save", "บันทึกเกม"], ["load", "โหลดเกม"],
	["", ""], ["sound", "เสียง"], ["language", "ภาษา / Language"], ["controls", "การควบคุม"],
	["", ""], ["title", "กลับหน้าหลัก"], ["quit", "ออกจากเกม"],
]
const PANE_TITLES := {
	"resume": "กลับเข้าเกม", "save": "บันทึกเกม — เลือกช่อง", "load": "โหลดเกม — เลือกช่อง",
	"sound": "เสียง", "language": "ภาษา / Language", "controls": "การควบคุม",
	"title": "กลับหน้าหลัก", "quit": "ออกจากเกม",
}
const KEY_ROWS := [
	["move_left", "เดินซ้าย"], ["move_right", "เดินขวา"], ["attack", "โจมตี"], ["interact", "คุย / ใช้"],
	["pickup", "เก็บของ"], ["skill_1", "แถบลัด 1"], ["skill_2", "แถบลัด 2"], ["skill_3", "แถบลัด 3"], ["skill_4", "แถบลัด 4"],
	["skill_5", "แถบลัด 5"], ["skill_6", "แถบลัด 6"], ["skill_7", "แถบลัด 7"], ["skill_8", "แถบลัด 8"], ["hotbar_page", "สลับหน้าแถบลัด"],
	["quick_potion", "ยาด่วน"], ["toggle_menu", "เปิดเมนู"], ["quick_save", "เซฟด่วน"], ["close_windows", "ปิดหน้าต่าง"],
]

var _slot_rows: Array = []      # แผงโหลด: [{info, load, del, sub, rank, title}]
var _save_rows: Array = []      # แผงบันทึก: [{title, sub, rank, btn}]
var _status: Label
var _touch_btn: Button
var _music_slider: HSlider
var _music_label: Label
var _music_btn: Button
var _sfx_slider: HSlider
var _sfx_label: Label
var _sfx_btn: Button
var _voice_slider: HSlider
var _voice_label: Label
var _voice_btn: Button

var _current := "save"
var _menu_btns: Dictionary = {}
var _panes: Dictionary = {}
var _pane_title: Label
var _auto_note: Label
# สรุปตัวละคร
var _sum_rank: TextureRect
var _sum_name: Label
var _sum_job: Label
var _sum_guild: Label
var _sum_disc: Label
var _sum_bar: ProgressBar
var _sum_vals: Dictionary = {}


func _ready() -> void:
	window_title = "เมนูระบบ"
	super._ready()
	custom_minimum_size = Vector2(900, 0)
	Events.stats_changed.connect(refresh)
	Events.zeny_changed.connect(func(_z): refresh())


# =========================================================
# สร้างหน้า
# =========================================================
func _build_content() -> void:
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 22)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(cols)
	cols.add_child(_build_summary())
	cols.add_child(_build_menu())
	cols.add_child(_build_pane_frame())
	_build_panes()
	_show_pane(_current)


func _build_summary() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = LEFT_W
	col.add_theme_constant_override("separation", 6)
	# รูปหน้าใหญ่ + ตราขั้นกิลด์
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(LEFT_W, 150)
	col.add_child(holder)
	var d := 140.0
	var x0 := (LEFT_W - d) * 0.5
	var ring := PetrolWidgets.portrait_ring(d)
	ring.position = Vector2(x0, 4)
	ring.size = Vector2(d, d)
	holder.add_child(ring)
	var pic := PetrolWidgets.circle_portrait(d, UITheme.glyph_texture("portrait"))
	pic.position = Vector2(x0, 4)
	pic.size = Vector2(d, d)
	holder.add_child(pic)
	_sum_rank = TextureRect.new()
	_sum_rank.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sum_rank.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sum_rank.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_sum_rank.position = Vector2(x0 - 10, d - 52)
	_sum_rank.size = Vector2(60, 60)
	holder.add_child(_sum_rank)

	_sum_name = UITheme.make_label("", 24, UITheme.GOLD_BRIGHT)
	_sum_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_sum_name)
	_sum_job = UITheme.make_label("", 14, UITheme.TEXT_DIM)
	_sum_job.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sum_job.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sum_job.custom_minimum_size.x = LEFT_W
	col.add_child(_sum_job)

	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.panel_style(Color("#0f2422cc"), UITheme.BORDER, 6, 1, 12.0))
	col.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	box.add_child(v)
	var grow := HBoxContainer.new()
	grow.add_theme_constant_override("separation", 8)
	v.add_child(grow)
	var gk := UITheme.make_label("ขั้นกิลด์", 14, UITheme.TEXT_DIM)
	gk.custom_minimum_size.x = 70
	grow.add_child(gk)
	_sum_guild = UITheme.make_label("", 14, UITheme.TEXT)
	_sum_guild.clip_text = true
	_sum_guild.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_sum_guild.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grow.add_child(_sum_guild)
	_sum_disc = UITheme.make_label("", 12, UITheme.GOLD_BRIGHT)
	grow.add_child(_sum_disc)
	_sum_bar = ProgressBar.new()
	_sum_bar.custom_minimum_size = Vector2(0, 8)
	_sum_bar.show_percentage = false
	_sum_bar.add_theme_stylebox_override("background", UITheme.bar_bg_style())
	_sum_bar.add_theme_stylebox_override("fill", UITheme.bar_fill_style(UITheme.ACCENT))
	v.add_child(_sum_bar)
	for pair in [["map", "อยู่ที่"], ["time", "เวลาเล่น"], ["zeny", "ซีนี"], ["quests", "เควสสำเร็จ"], ["cards", "สมุดการ์ด"]]:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 8)
		v.add_child(r)
		var k := UITheme.make_label(String(pair[1]), 14, UITheme.TEXT_DIM)
		k.custom_minimum_size.x = 70
		r.add_child(k)
		var val := UITheme.make_label("", 14, Color("#ffe9a0") if pair[0] == "zeny" else UITheme.TEXT)
		val.clip_text = true
		val.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(val)
		_sum_vals[pair[0]] = val
	return col


func _build_menu() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = MENU_W
	col.add_theme_constant_override("separation", 2)
	var head := UITheme.make_label("หยุดเกมชั่วคราว", 13, UITheme.ACCENT)
	col.add_child(head)
	var gap0 := Control.new()
	gap0.custom_minimum_size.y = 6
	col.add_child(gap0)
	for item in MENU_ITEMS:
		var id := String(item[0])
		if id == "":
			var gap := Control.new()
			gap.custom_minimum_size.y = 12
			col.add_child(gap)
			continue
		var b := Button.new()
		b.text = String(item[1])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(MENU_W, 46)
		b.add_theme_font_size_override("font_size", 21)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.mouse_entered.connect(_show_pane.bind(id))
		b.pressed.connect(_activate.bind(id))
		col.add_child(b)
		_menu_btns[id] = b
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(sp)
	col.add_child(UITheme.make_label("↑↓ เลือก · Enter ยืนยัน · Esc กลับเข้าเกม", 12, UITheme.TEXT_DIM))
	_style_menu()
	return col


func _build_pane_frame() -> Control:
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", UITheme.panel_style(Color("#0b1c1bf0"), UITheme.ACCENT, 6, 1, 16.0))
	var v := VBoxContainer.new()
	v.name = "PaneBox"
	v.add_theme_constant_override("separation", 10)
	frame.add_child(v)
	_pane_title = UITheme.make_label("", 19, UITheme.GOLD_BRIGHT)
	v.add_child(_pane_title)
	v.add_child(UITheme.separator())
	_status = UITheme.make_label("", 13, UITheme.GOOD)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.x = 380
	v.set_meta("status", _status)
	return frame


func _pane_box() -> VBoxContainer:
	return (_pane_title.get_parent() as VBoxContainer)


func _new_pane(id: String) -> VBoxContainer:
	var p := VBoxContainer.new()
	p.name = "Pane_" + id
	p.add_theme_constant_override("separation", 8)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pane_box().add_child(p)
	_panes[id] = p
	return p


func _note(parent: Control, text: String) -> Label:
	var l := UITheme.make_label(text, 12, UITheme.TEXT_DIM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 380   # autowrap ต้องมีความกว้างตั้งต้น (กับดัก 185)
	parent.add_child(l)
	return l


func _build_panes() -> void:
	# ---------- กลับเข้าเกม ----------
	var p := _new_pane("resume")
	_note(p, "ปิดเมนูแล้วเล่นต่อจากตรงนี้")
	var rb := UITheme.make_gold_button("กลับเข้าเกม")
	rb.custom_minimum_size = Vector2(220, 42)
	rb.pressed.connect(hide_window)
	p.add_child(rb)

	# ---------- บันทึก ----------
	p = _new_pane("save")
	for slot in range(SaveManager.SLOT_COUNT):
		_save_rows.append(_slot_card(p, slot, true))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.add_child(sp)
	_auto_note = _note(p, "")

	# ---------- โหลด ----------
	p = _new_pane("load")
	for slot in range(SaveManager.SLOT_COUNT + 1):
		_slot_rows.append(_slot_card(p, slot, false))
	_note(p, "โหลดแล้วความคืบหน้าที่ยังไม่ได้บันทึกจะหายไป")

	# ---------- เสียง ----------
	p = _new_pane("sound")
	var r := _sound_row(p, "เพลง", _on_music_volume, _toggle_music)
	_music_label = r[0]; _music_slider = r[1]; _music_btn = r[2]
	_note(p, "เพลงเปลี่ยนตามแมพเอง — วางไฟล์ Sprites/music/<ชื่อแมพ>.mp3 แล้วเล่นได้เลย")
	r = _sound_row(p, "เสียงเอฟเฟกต์", _on_sfx_volume, _toggle_sfx)
	_sfx_label = r[0]; _sfx_slider = r[1]; _sfx_btn = r[2]
	r = _sound_row(p, "เสียงพากย์ NPC", _on_voice_volume, _toggle_voice)
	_voice_label = r[0]; _voice_slider = r[1]; _voice_btn = r[2]
	_refresh_music()
	_refresh_sfx()
	_refresh_voice()
	visibility_changed.connect(_refresh_music)
	visibility_changed.connect(_refresh_sfx)
	visibility_changed.connect(_refresh_voice)

	# ---------- ภาษา ----------
	p = _new_pane("language")
	var lang_row := HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 8)
	p.add_child(lang_row)
	var lang_group := ButtonGroup.new()
	for code in Loc.LOCALES:
		var lb := UITheme.make_button(String(Loc.LOCALE_NAMES[code]), 130)
		lb.custom_minimum_size.y = 40
		lb.toggle_mode = true
		lb.button_group = lang_group
		lb.button_pressed = Loc.current() == code
		lb.pressed.connect(func():
			Loc.set_locale(code)   # ★ รอบ 162 ★ ปุ่มเปิด/ปิดเปลี่ยนภาษาตาม
			_refresh_voice()
			_refresh_sfx()
			_refresh_music())
		lang_row.add_child(lb)
	_note(p, "English: แปลทั้งเกมแล้ว · ถ้าเจอข้อความไทยค้าง เกมจะจดไว้ที่ user://untranslated_en.txt")

	# ---------- การควบคุม ----------
	p = _new_pane("controls")
	var touch_row := HBoxContainer.new()
	touch_row.add_theme_constant_override("separation", 8)
	p.add_child(touch_row)
	var tl := UITheme.make_label("ปุ่มจอสัมผัส (มือถือ)", 15, UITheme.TEXT)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	touch_row.add_child(tl)
	_touch_btn = UITheme.make_button("", 150)
	_touch_btn.pressed.connect(_cycle_touch_mode)
	touch_row.add_child(_touch_btn)
	_refresh_touch_button()
	# ★ รอบ 166 ★ UI.touch ถูกสร้างหลังหน้าต่างนี้ → ตอนสร้างปุ่มยังว่าง (ปุ่มเปล่าในภาพผู้ใช้) — อัปเดตทุกครั้งที่เปิด
	visibility_changed.connect(_refresh_touch_button)
	_note(p, "อัตโนมัติ = โผล่เองเมื่อเล่นบนจอสัมผัส · กดปุ่มนี้เพื่อลองบนคอมได้")
	p.add_child(UITheme.separator())
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 4)
	p.add_child(grid)
	for kr in KEY_ROWS:
		if not InputMap.has_action(StringName(kr[0])):
			continue
		var keys := _key_text(StringName(kr[0]))
		if keys == "":
			continue
		var kn := UITheme.make_label(String(kr[1]), 13, UITheme.TEXT_DIM)
		kn.custom_minimum_size.x = 80
		grid.add_child(kn)
		var kv := UITheme.make_label(keys, 13, UITheme.TEXT)
		kv.custom_minimum_size.x = 90
		grid.add_child(kv)

	# ---------- กลับหน้าหลัก ----------
	p = _new_pane("title")
	_note(p, "กลับไปหน้าแรกของเกม — ความคืบหน้าที่ยังไม่ได้บันทึกจะหายไป (เซฟอัตโนมัติจะช่วยเก็บไว้ทุก 3 นาที)")
	var tb := UITheme.make_button("กลับหน้าหลัก", 220)
	tb.custom_minimum_size.y = 42
	tb.pressed.connect(_do_go_title)
	p.add_child(tb)

	# ---------- ออกจากเกม ----------
	p = _new_pane("quit")
	if OS.has_feature("web"):
		_note(p, "เล่นบนเว็บ — ปิดแท็บเบราว์เซอร์เพื่อออกจากเกม")
	else:
		_note(p, "ปิดเกม — ความคืบหน้าที่ยังไม่ได้บันทึกจะหายไป")
		var qb := UITheme.make_button("ออกจากเกม", 220)
		qb.custom_minimum_size.y = 42
		qb.add_theme_color_override("font_color", UITheme.BAD)
		qb.pressed.connect(_do_quit)
		p.add_child(qb)

	_pane_box().add_child(_status)


func _sound_row(parent: Control, title: String, on_value: Callable, on_toggle: Callable) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var l := UITheme.make_label(title, 15, UITheme.TEXT)
	l.custom_minimum_size.x = 170
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 100.0
	s.step = 5.0
	s.custom_minimum_size = Vector2(170, 20)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(on_value)
	row.add_child(s)
	var b := UITheme.make_button("", 70)
	b.pressed.connect(on_toggle)
	row.add_child(b)
	return [l, s, b]


## แถวช่องเซฟ: รูปหน้า + ตราขั้นกิลด์ · ชื่อช่อง/Lv/อาชีพ · แมพ/วันเวลา/เวลาเล่น · ปุ่ม
func _slot_card(parent: Control, slot: int, save_mode: bool) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_style(Color("#0f2422"), UITheme.BORDER, 5, 1, 8.0))
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var av := Control.new()
	av.custom_minimum_size = Vector2(50, 50)
	row.add_child(av)
	var ring := PetrolWidgets.portrait_ring(50)
	ring.size = Vector2(50, 50)
	av.add_child(ring)
	var pic := PetrolWidgets.circle_portrait(50, UITheme.glyph_texture("portrait"))
	pic.size = Vector2(50, 50)
	av.add_child(pic)
	var rk := TextureRect.new()
	rk.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rk.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rk.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rk.position = Vector2(-8, 24)
	rk.size = Vector2(28, 28)
	av.add_child(rk)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(tv)
	var title := UITheme.make_label("", 16, UITheme.TEXT)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tv.add_child(title)
	var sub := UITheme.make_label("", 12, UITheme.TEXT_DIM)
	sub.clip_text = true
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tv.add_child(sub)
	var s := slot
	var btn: Button
	if save_mode:
		btn = UITheme.make_button("บันทึก", 96)
		btn.pressed.connect(func(): _do_save(s))
	else:
		btn = UITheme.make_button("โหลด", 86)
		btn.pressed.connect(func(): _do_load(s))
	btn.custom_minimum_size.y = 38
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(btn)
	return {"panel": panel, "title": title, "sub": sub, "rank": rk, "btn": btn, "info": title, "load": btn, "del": null, "avatar": av}


static func _key_text(action: StringName) -> String:
	var parts: Array[String] = []
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			var k := ev as InputEventKey
			var code := k.physical_keycode if k.physical_keycode != 0 else k.keycode
			parts.append(OS.get_keycode_string(code))
		if parts.size() >= 2:
			break
	return " / ".join(parts)


# =========================================================
# เมนูกลาง
# =========================================================
func _style_menu() -> void:
	for id in _menu_btns.keys():
		var b: Button = _menu_btns[id]
		var on: bool = id == _current
		for st in ["normal", "hover", "pressed", "focus"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(UITheme.ACCENT, 0.24) if on else (Color(UITheme.ACCENT, 0.08) if st == "hover" else Color(0, 0, 0, 0))
			sb.border_color = UITheme.ACCENT
			sb.border_width_left = 3 if on else 0
			sb.content_margin_left = 16.0
			b.add_theme_stylebox_override(st, sb)
		var col: Color = UITheme.GOLD_BRIGHT if on else (UITheme.BAD if id == "quit" else UITheme.TEXT)
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(c, col)
		var label := String(PANE_TITLES.get(id, id)).get_slice(" — ", 0)
		for item in MENU_ITEMS:
			if item[0] == id:
				label = String(item[1])
		b.text = ("▸ " if on else "") + label


func _show_pane(id: String) -> void:
	if not _panes.has(id):
		return
	_current = id
	for k in _panes.keys():
		(_panes[k] as Control).visible = k == id
	_pane_title.text = String(PANE_TITLES.get(id, ""))
	_style_menu()


func _activate(id: String) -> void:
	_show_pane(id)
	match id:
		"resume":
			hide_window()
		"title":
			_do_go_title()
		"quit":
			_do_quit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var order: Array[String] = []
	for item in MENU_ITEMS:
		if String(item[0]) != "":
			order.append(String(item[0]))
	var i := order.find(_current)
	if event.is_action_pressed("ui_down"):
		_show_pane(order[wrapi(i + 1, 0, order.size())])
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_show_pane(order[wrapi(i - 1, 0, order.size())])
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and _current in ["resume", "title", "quit"]:
		_activate(_current)
		get_viewport().set_input_as_handled()


# =========================================================
# ปุ่มต่าง ๆ
# =========================================================
func _do_go_title() -> void:
	var ok: bool = await UI.ask("กลับหน้าหลัก", "กลับหน้าหลักหรือไม่?", "กลับ", "ยังก่อน")
	if ok:
		Game.go_title()


func _do_quit() -> void:
	var ok: bool = await UI.ask("ออกจากเกม", "ออกจากเกมหรือไม่?\nความคืบหน้าที่ยังไม่ได้บันทึกจะหายไป", "ออกเลย", "ยังก่อน")
	if ok:
		SaveManager.quit_game()


func _do_save(slot: int) -> void:
	PlayerState.current_map_id = _current_map_id()
	if SaveManager.save_game(slot):
		_say("บันทึกลงช่อง %d แล้ว" % (slot + 1))
	else:
		_say("บันทึกไม่สำเร็จ")
	refresh()


func _do_load(slot: int) -> void:
	if not SaveManager.has_save(slot):
		_say("ช่อง %d ยังไม่มีข้อมูลเซฟ" % (slot + 1))
		return
	var ok: bool = await UI.ask("โหลดเกม",
		"โหลดข้อมูลจาก%s?\nความคืบหน้าที่ยังไม่ได้เซฟจะหายไป" % ("เซฟอัตโนมัติ" if slot == SaveManager.AUTO_SLOT else "ช่อง %d" % (slot + 1)),
		"โหลดเลย", "ยกเลิก")
	if not ok:
		return
	if SaveManager.load_game(slot):
		hide_window()
		Game.change_map(PlayerState.current_map_id, &"default")
	else:
		_say("ไฟล์เซฟเสียหาย โหลดไม่ได้")


func _do_delete(slot: int) -> void:
	if not SaveManager.has_save(slot):
		return
	var ok: bool = await UI.ask("ลบเซฟ",
		"ลบข้อมูลในช่อง %d ทิ้ง?" % (slot + 1), "ลบเลย", "ยกเลิก")
	if ok:
		SaveManager.delete_save(slot)
		_say("ลบช่อง %d แล้ว" % (slot + 1))
		refresh()


func _do_new_game() -> void:
	var ok: bool = await UI.ask("เริ่มเกมใหม่",
		"เริ่มใหม่ตั้งแต่ต้น?\nตัวละคร ของ และความคืบหน้าปัจจุบันจะหายทั้งหมด\n(ไฟล์เซฟที่บันทึกไว้ยังอยู่)",
		"เริ่มใหม่", "ยกเลิก")
	if not ok:
		return
	hide_window()
	PlayerState.new_game()
	Game.change_map(PlayerState.current_map_id, &"default")
	Events.say("เริ่มเกมใหม่แล้ว")


func _current_map_id() -> StringName:
	var scene := get_tree().current_scene
	if scene != null and "map_id" in scene:
		return scene.map_id
	return PlayerState.current_map_id


func _say(text: String) -> void:
	if _status != null:
		_status.text = text
	Events.say(text)


# =========================================================
# อัปเดตข้อมูล
# =========================================================
func refresh() -> void:
	if _sum_name == null or not is_visible_in_tree():
		return
	_refresh_summary()
	_refresh_touch_button()
	for slot in range(_save_rows.size()):
		_fill_slot(_save_rows[slot], slot, true)
	for slot in range(_slot_rows.size()):
		_fill_slot(_slot_rows[slot], slot, false)
	if _auto_note != null:
		var auto := SaveManager.slot_info(SaveManager.AUTO_SLOT) if SaveManager.has_save(SaveManager.AUTO_SLOT) else {}
		_auto_note.text = "เซฟอัตโนมัติล่าสุด %s (ทุก 3 นาทีและหลังเหตุการณ์สำคัญ)" % _short_time(String(auto.get("saved_at", ""))) if not auto.is_empty() else "เซฟอัตโนมัติทุก 3 นาทีและหลังเหตุการณ์สำคัญ"


func _refresh_summary() -> void:
	var s := PlayerState.stats
	if s == null:
		return
	var job_name: String = s.job().display_name if s.job() != null else ""
	var short := job_name.get_slice(" — ", 0)
	_sum_name.text = "Lv.%d %s" % [s.level, short]
	_sum_job.text = job_name.get_slice(" — ", 1) if job_name.find(" — ") >= 0 else "Job Lv.%d" % s.job_level
	var b: BountyBoard = PlayerState.bounties
	if b != null:
		var idx := b.rank_index()
		_sum_rank.texture = GuildRankWindow.rank_icon(b.rank_letter())
		_sum_guild.text = "%s · %s" % [b.rank_letter(), b.rank_title()]
		_sum_disc.text = "ส่วนลด %d%%" % b.discount_percent()
		var next := b.next_rank_points()
		var lo := int(BountyBoard.RANKS[idx][1])
		_sum_bar.max_value = maxf(1.0, float(next - lo)) if next > 0 else 1.0
		_sum_bar.value = float(b.points - lo) if next > 0 else 1.0
		_sum_bar.tooltip_text = ("แต้มกิลด์ %d · อีก %d แต้มถึงขั้นถัดไป" % [b.points, next - b.points]) if next > 0 else "ขั้นสูงสุดแล้ว"
	_sum_vals["map"].text = Game.map_display_name(_current_map_id())
	_sum_vals["time"].text = PlayerState.play_time_text(PlayerState.play_time)
	_sum_vals["zeny"].text = "%s z" % HUD._comma(PlayerState.zeny)
	_sum_vals["quests"].text = "%d เควส" % (PlayerState.quests.completed.size() if PlayerState.quests != null else 0)
	_sum_vals["cards"].text = "%d / %d ใบ" % [PlayerState.cards_collected(), GameData.all_cards().size()]


func _fill_slot(row: Dictionary, slot: int, save_mode: bool) -> void:
	var has: bool = SaveManager.has_save(slot)
	var slot_name := "เซฟอัตโนมัติ" if slot == SaveManager.AUTO_SLOT else "ช่อง %d" % (slot + 1)
	var av: Control = row["avatar"]
	if has:
		var d: Dictionary = SaveManager.slot_info(slot)
		var job = GameData.get_job(StringName(String(d.get("job", ""))))
		var job_name: String = String(job.display_name).get_slice(" — ", 0) if job != null else String(d.get("job", ""))
		row["title"].text = "%s · Lv.%d %s" % [slot_name, int(d.get("level", 1)), job_name]
		row["title"].add_theme_color_override("font_color", UITheme.TEXT)
		var map_name := String(d.get("map_name", ""))
		if map_name == "":
			map_name = String(d.get("map", ""))
		var bits: Array[String] = [map_name, _short_time(String(d.get("saved_at", "")))]
		if float(d.get("play_time", 0.0)) > 0.0:
			bits.append("⏱ " + PlayerState.play_time_text(float(d.get("play_time", 0.0))))
		row["sub"].text = " · ".join(bits)
		row["rank"].texture = GuildRankWindow.rank_icon(String(d.get("rank", "F")))
		av.modulate = Color.WHITE
	else:
		row["title"].text = "%s — ว่าง" % slot_name
		row["title"].add_theme_color_override("font_color", UITheme.TEXT_DIM)
		row["sub"].text = "บันทึกที่นี่ได้" if save_mode else "ยังไม่มีข้อมูลเซฟ"
		row["rank"].texture = null
		av.modulate = Color(1, 1, 1, 0.3)
	var btn: Button = row["btn"]
	if save_mode:
		btn.text = "บันทึกทับ" if has else "บันทึก"
	else:
		btn.disabled = not has


## "2026-09-24T02:54:29" → "24 ก.ย. 02:54"
static func _short_time(stamp: String) -> String:
	const MONTHS := ["ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."]
	var parts := stamp.split("T")
	var d := parts[0].split("-")
	if d.size() < 3:
		return stamp
	return "%d %s %s" % [int(d[2]), MONTHS[clampi(int(d[1]) - 1, 0, 11)], parts[1].substr(0, 5) if parts.size() > 1 else ""]


# =========================================================
# ★ ปุ่มจอสัมผัส ★ อัตโนมัติ -> เปิดตลอด -> ปิด -> วนกลับ
# =========================================================
func _cycle_touch_mode() -> void:
	if UI.touch == null:
		return
	var next: int = (int(UI.touch.mode) + 1) % 3
	UI.touch.set_mode(next as TouchControls.Mode)
	_refresh_touch_button()
	Events.say("ปุ่มจอสัมผัส: %s" % UI.touch.mode_text())


# =========================================================
# ★ รอบ 52 — เพลง / เสียงเอฟเฟกต์ / เสียงพากย์ ★
# =========================================================
func _on_music_volume(v: float) -> void:
	if Game.music == null:
		return
	Game.music.set_volume(v / 100.0)
	_refresh_music()


func _toggle_music() -> void:
	if Game.music == null:
		return
	Game.music.set_enabled(not Game.music.enabled)
	_refresh_music()


func _on_sfx_volume(v: float) -> void:
	if Game.sfx != null:
		Game.sfx.set_volume(v / 100.0)
		Game.sfx.play_first(["attack_blade", "attack"])     # ให้ได้ยินตัวอย่างทันที
	_refresh_sfx()


func _toggle_sfx() -> void:
	if Game.sfx != null:
		Game.sfx.set_enabled(not Game.sfx.enabled)
	_refresh_sfx()


func _on_voice_volume(v: float) -> void:
	if Game.voice != null:
		Game.voice.set_volume(v / 100.0)
	_refresh_voice()


func _toggle_voice() -> void:
	if Game.voice != null:
		Game.voice.set_enabled(not Game.voice.enabled)
	_refresh_voice()


func _refresh_voice() -> void:
	if Game.voice == null or _voice_slider == null:
		return
	_voice_slider.set_block_signals(true)
	_voice_slider.value = Game.voice.volume_percent()
	_voice_slider.set_block_signals(false)
	_voice_btn.text = Loc.on_off(Game.voice.enabled)
	_voice_label.text = "เสียงพากย์ NPC  %d%%" % Game.voice.volume_percent()


func _refresh_sfx() -> void:
	if Game.sfx == null or _sfx_slider == null:
		return
	_sfx_slider.set_block_signals(true)
	_sfx_slider.value = Game.sfx.volume_percent()
	_sfx_slider.set_block_signals(false)
	_sfx_btn.text = Loc.on_off(Game.sfx.enabled)
	_sfx_label.text = "เสียงเอฟเฟกต์  %d%%" % Game.sfx.volume_percent()
	_sfx_label.tooltip_text = "" if Game.sfx.has_sound("attack_blade") else "ยังไม่มีไฟล์เสียง — วางไฟล์ Sprites/sfx/<ชื่อ>.ogg"


func _refresh_music() -> void:
	if Game.music == null or _music_slider == null:
		return
	_music_slider.set_block_signals(true)
	_music_slider.value = Game.music.volume_percent()
	_music_slider.set_block_signals(false)
	_music_btn.text = Loc.on_off(Game.music.enabled)
	_music_label.text = "เพลง  %d%%" % Game.music.volume_percent()
	var track := Game.music.current_track()
	_music_label.tooltip_text = ("กำลังเล่น: %s" % track) if track != "" and Game.music.enabled else ""


func _refresh_touch_button() -> void:
	if _touch_btn == null or UI.touch == null:
		return
	_touch_btn.text = UI.touch.mode_text()
