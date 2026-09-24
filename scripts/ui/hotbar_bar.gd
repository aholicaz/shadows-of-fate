## HotbarBar — ★ รอบ 168 ★ แถบลัดบนคอม แบบ A (ผู้ใช้เลือกจาก `_docs/mockup_รอบ167_ปุ่มสกิลPC_A.png`)
##
## ★ รอบ 174 ★ โทนขาวแบบ C (ผู้ใช้เลือกจาก `_docs/mockup_แถบลัดสีขาว_*.png`) — ไม่มีพื้นแถบ · ช่องขอบขาว + เงา เข้ากับไอคอนเมนู
## ★ รอบ 170 ★ ช่อง 50 px แนวเดียวกับปุ่มเมนูที่ย่อแล้ว (ซีนีออกจาก HUD · ป้ายเลเวลสั้นลง)
## ★ รอบ 169 ★ ย้ายขึ้นแถบบน (ระหว่างหลอด HP/SP กับปุ่มเมนู «ตัวละคร») ช่องเล็กลง 38 px · ไม่บังฉากเล่น
##   ตัดปุ่มกลมพุ่งหลบ/โจมตีออก (ผู้เล่นคอมใช้คีย์บอร์ด/เมาส์อยู่แล้ว — ปุ่มกลมมีเฉพาะมือถือ)
## [หน้า 1/2 · Shift] [ช่อง 1-8]
## · ช่องละ 1 สกิลหรือ 1 ไอเทม (ยา · ไอเทมบัพ · ปีกวาร์ป) — ข้อมูลอยู่ PlayerState.hotbar (16 ช่อง = 2 หน้า)
## · กดเลข 1-8 / คลิกซ้าย = ใช้ · คลิกขวา = เอาออก · ลากช่องไปวางอีกช่อง = สลับ · Shift = สลับหน้า
## · ใส่ของ: หน้าสกิล (K) เลือกสกิล → กดช่อง · กระเป๋า (I) เลือกไอเทม → «แถบลัด 1-8»
## · ไอเทมบัพที่บัพยังติด = กรอบทอง + เวลาที่เหลือ · ปีกวาร์ป = tooltip บอกเมืองปลายทาง
## · โชว์เฉพาะตอนไม่ได้ใช้ปุ่มจอสัมผัส (มือถือยังใช้วงปุ่มของ TouchControls เหมือนเดิม)
class_name HotbarBar
extends Control

const SLOT := 50.0         ## ★ รอบ 170 ★ ใหญ่ขึ้นเท่าปุ่มเมนูที่ย่อแล้ว
const GAP := 4.0
const PAD := 5.0
const PAGE_W := 20.0
const TOP_Y := 12.0           ## ★ รอบ 170 ★ แนวเดียวกับปุ่มเมนูขวาบน
const LEFT_MIN := 380.0       ## ขวาของกล่องรูปหน้า+หลอด (HUD.top_panel 18+360)
const GOLD := Color("#ffd86a")

var _frame: Panel
var _slots: Array = []
var _page_label: Label


func _ready() -> void:
	name = "HotbarBar"
	z_index = 185
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame = Panel.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	var st := StyleBoxFlat.new()
	# ★ รอบ 174 ★ แบบ C «ไร้กรอบ ขอบขาวรายช่อง» — ไม่มีพื้นแถบ (โปร่งทั้งหมด) · แต่ละช่องวาดขอบขาวเอง
	st.bg_color = Color(0, 0, 0, 0)
	st.set_border_width_all(0)
	_frame.add_theme_stylebox_override("panel", st)
	add_child(_frame)
	_page_label = UITheme.make_label("", 13, Color.WHITE)
	_page_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_page_label.add_theme_constant_override("outline_size", 4)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_page_label.tooltip_text = "หน้าแถบลัด — กด Shift (หรือ T) สลับหน้า 1/2 · รวม 16 ช่อง"
	_page_label.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			PlayerState.skills.switch_bank())
	_frame.add_child(_page_label)
	for k in range(PlayerState.HOTBAR_PAGE):
		var s := _Slot.new()
		s.key_index = k
		s.bar = self
		_frame.add_child(s)
		_slots.append(s)
	get_viewport().size_changed.connect(_layout)
	Events.skills_changed.connect(_refresh_page)
	_layout()
	_refresh_page()


func _layout() -> void:
	var vp := get_viewport_rect().size
	var n := PlayerState.HOTBAR_PAGE
	var fw := PAD * 2.0 + PAGE_W + GAP + n * SLOT + (n - 1) * GAP
	var fh := PAD * 2.0 + SLOT
	# วางกลางช่องว่างระหว่างกล่องหลอดเลือด (ซ้าย) กับแถบปุ่มเมนู (ขวา)
	var left := LEFT_MIN
	var right := vp.x - 470.0
	if UI.menu_bar != null and UI.menu_bar.is_inside_tree() and UI.menu_bar.size.x > 0.0:
		right = UI.menu_bar.get_global_rect().position.x - 10.0
	var fx := maxf(left, (left + right - fw) * 0.5)
	_frame.position = Vector2(roundf(fx), TOP_Y)
	_frame.size = Vector2(fw, fh)
	_page_label.position = Vector2(PAD, PAD)
	_page_label.size = Vector2(PAGE_W, SLOT)
	for k in range(n):
		var s: Control = _slots[k]
		s.position = Vector2(PAD + PAGE_W + GAP + k * (SLOT + GAP), PAD)
		s.size = Vector2(SLOT, SLOT)


func _refresh_page() -> void:
	if _page_label == null:
		return
	_page_label.text = "%d\n⇅" % (PlayerState.hotbar_page() + 1)
	for s in _slots:
		(s as Control).queue_redraw()


## โชว์ตอนเล่นบนคอม (ไม่ได้ใช้ปุ่มจอสัมผัส) และไม่มีหน้าต่าง/กล่องคุยเปิดอยู่
func should_show() -> bool:
	if not UI.in_game or UI.is_any_window_open() or UI.is_asking():
		return false
	return UI.touch == null or not UI.touch.walk_visible


func _process(_delta: float) -> void:
	var want := should_show()
	if want != visible:
		visible = want
	if visible:
		_layout()   # แถบเมนูขวาบนจัดตำแหน่งทีหลัง → วางตามทุกเฟรม (แค่ตั้งตำแหน่ง ไม่แพง)
		for s in _slots:
			(s as Control).queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("hotbar_page") and not event.is_echo():
		PlayerState.skills.switch_bank()
		get_viewport().set_input_as_handled()


func is_over(point: Vector2) -> bool:
	if not visible:
		return false
	return _frame.get_global_rect().has_point(point)


func slot_index(k: int) -> int:
	return PlayerState.hotbar_page() * PlayerState.HOTBAR_PAGE + k


func use_slot(k: int) -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p != null and p.has_method("use_hotbar_index"):
		p.use_hotbar_index(slot_index(k))


# =========================================================
# ช่อง 1 ช่อง
# =========================================================
class _Slot extends Control:
	var key_index := 0
	var bar: HotbarBar

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	func _entry() -> Dictionary:
		return PlayerState.hotbar_slot(bar.slot_index(key_index))

	func _get_tooltip(_at: Vector2) -> String:
		return PlayerState.hotbar_tooltip(bar.slot_index(key_index))

	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			if ev.button_index == MOUSE_BUTTON_LEFT and not ev.double_click:
				bar.use_slot(key_index)
				accept_event()
			elif ev.button_index == MOUSE_BUTTON_RIGHT:
				PlayerState.set_hotbar_slot(bar.slot_index(key_index), "", &"")
				accept_event()

	func _icon() -> Texture2D:
		var e := _entry()
		if e.is_empty():
			return null
		if String(e.kind) == "skill":
			var sk := GameData.get_skill(StringName(e.id))
			return sk.icon if sk != null else null
		var d := GameData.get_item(StringName(e.id))
		return d.icon if d != null else null

	func _get_drag_data(_at: Vector2) -> Variant:
		var tex := _icon()
		if tex == null:
			return null
		var pv := TextureRect.new()
		pv.texture = tex
		pv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pv.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pv.size = Vector2(48, 48)
		pv.position = Vector2(-24, -24)
		pv.modulate.a = 0.85
		var holder := Control.new()
		holder.add_child(pv)
		set_drag_preview(holder)
		return {"kind": "hotbar", "slot": bar.slot_index(key_index)}

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return data is Dictionary and String(data.get("kind", "")) == "hotbar"

	func _drop_data(_at: Vector2, data: Variant) -> void:
		PlayerState.swap_hotbar(int(data.slot), bar.slot_index(key_index))

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var e := _entry()
		var bg := StyleBoxFlat.new()
		# ★ รอบ 174 ★ แบบ C: พื้นเข้มโปร่ง 28% · ขอบขาว 2 px · เงาดำนุ่ม (ช่องว่าง = พื้นขาวจาง)
		bg.bg_color = Color(0.04, 0.08, 0.08, 0.28) if not e.is_empty() else Color(1, 1, 1, 0.12)
		bg.border_color = Color(1, 1, 1, 0.95)
		bg.set_border_width_all(2)
		bg.set_corner_radius_all(6)
		bg.shadow_color = Color(0, 0, 0, 0.35)
		bg.shadow_size = 4
		bg.shadow_offset = Vector2(0, 2)
		var buffed := false
		var font := get_theme_default_font()
		if e.is_empty():
			draw_style_box(bg, r)
			draw_string_outline(font, Vector2(0, size.y * 0.5 + 7), "+", HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, 4, Color(0, 0, 0, 0.6))
			draw_string(font, Vector2(0, size.y * 0.5 + 7), "+", HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color.WHITE)
		else:
			var id := StringName(e.id)
			var is_skill := String(e.kind) == "skill"
			var d: ItemData = null if is_skill else GameData.get_item(id)
			if d != null and d.buff_duration > 0.0 and PlayerState.active_buffs.has(StringName("item_" + String(id))):
				buffed = true
				bg.border_color = HotbarBar.GOLD
				bg.set_border_width_all(2)
				bg.shadow_color = Color(HotbarBar.GOLD, 0.45)
				bg.shadow_size = 6
			draw_style_box(bg, r)
			var tex := _icon()
			var inner := r.grow(-3)
			var tint := Color.WHITE
			var count := -1
			var cd_left := 0.0
			var cd_total := 0.0
			if is_skill:
				if not PlayerState.skills.is_learned(id):
					tint = Color(0.35, 0.35, 0.38)
				cd_left = PlayerState.skill_cooldown_left(id)
				var sk := GameData.get_skill(id)
				cd_total = float(sk.cooldown) if sk != null else 0.0
			else:
				count = PlayerState.inventory.count_of(id) if PlayerState.inventory != null else 0
				if count <= 0:
					tint = Color(0.35, 0.35, 0.38)
				cd_left = PlayerState.potion_cooldown_left_of_id(id)
				cd_total = maxf(cd_left, 1.0)
			if tex != null:
				draw_texture_rect(tex, inner, false, tint)
			if cd_left > 0.0:
				# ม่านคูลดาวน์พัดตามเข็ม + ตัวเลขวินาที
				var frac := clampf(cd_left / maxf(cd_total, 0.01), 0.0, 1.0)
				var c := inner.get_center()
				var rad := inner.size.x * 0.75
				var pts := PackedVector2Array([c])
				var steps := 24
				for s in range(steps + 1):
					var a := -PI * 0.5 + TAU * (1.0 - frac) + TAU * frac * float(s) / float(steps)
					pts.append(c + Vector2(cos(a), sin(a)) * rad)
				draw_set_transform(Vector2.ZERO)
				_clip_polygon(pts, inner)
				var txt := ("%.1f" % cd_left) if cd_left < 1.0 else str(int(ceil(cd_left)))
				draw_string_outline(font, Vector2(0, c.y + 6), txt, HORIZONTAL_ALIGNMENT_CENTER, size.x, 17, 4, Color.BLACK)
				draw_string(font, Vector2(0, c.y + 6), txt, HORIZONTAL_ALIGNMENT_CENTER, size.x, 17, Color.WHITE)
			if count >= 0:
				var ct := str(count)
				draw_string_outline(font, Vector2(0, size.y - 2), ct, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 2, 12, 3, Color.BLACK)
				draw_string(font, Vector2(0, size.y - 2), ct, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 2, 12, Color.WHITE if count > 0 else Color("#ff9c9c"))
			if buffed:
				var left := int(float(PlayerState.active_buffs[StringName("item_" + String(id))].get("time_left", 0.0)))
				var bt := "%d:%02d" % [int(left / 60.0), left % 60]
				draw_string_outline(font, Vector2(0, 11), bt, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 2, 9, 3, Color.BLACK)
				draw_string(font, Vector2(0, 11), bt, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 2, 9, HotbarBar.GOLD)
		var kt := str(key_index + 1)
		draw_string_outline(font, Vector2(3, 13), kt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color.BLACK)
		draw_string(font, Vector2(3, 13), kt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

	## ม่านคูลดาวน์ (โพลิกอนพัด) ตัดให้อยู่ในกรอบช่อง
	func _clip_polygon(pts: PackedVector2Array, box: Rect2) -> void:
		var boxp := PackedVector2Array([box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)])
		for poly in Geometry2D.intersect_polygons(pts, boxp):
			draw_colored_polygon(poly, Color(0, 0, 0, 0.62))
