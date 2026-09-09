## TouchControls — ปุ่มบนจอ: วงโจมตี/สกิล/พุ่งหลบ + ช่องยา Q/R (ทุกเครื่อง) และปุ่มเดินซ้าย-ขวา (จอสัมผัส)
##
## ★★ รอบ 98 — โฉม Petrol ตามภาพตัวอย่าง ★★
## · "กลุ่มสู้" (โจมตี J · สกิล 1-4 · DASH · ยา Q/R) โชว์ **ทุกเครื่อง** — คอมก็เห็นและคลิกได้ (เหมือนภาพ)
## · "กลุ่มเดิน" (◀ ▶ ▼ + คุย/เก็บ) โชว์เฉพาะเครื่องจอสัมผัส (หรือเปิดเองที่ระบบ → ปุ่มจอสัมผัส: เปิดตลอด)
## · บนมือถือปุ่มทั้งหมดใหญ่ขึ้น TOUCH_SCALE เท่า นิ้วจะได้กดถูก
##
## ★ ทำไมต้องเขียนเอง ไม่ใช้ปุ่มธรรมดา ★
## Godot แปลง "นิ้วแรก" เป็นเมาส์ให้เท่านั้น ถ้าใช้ Button ปกติจะกดได้ทีละปุ่ม
## (เดินไปตีไปไม่ได้) ไฟล์นี้เลยอ่าน InputEventScreenTouch เองแยกตามนิ้ว (multi-touch)
## เมาส์บนคอมก็กดได้ (นิ้วหมายเลข -1)
##
## ★ ปุ่มส่งเป็น "action" ★ เกมทั้งเกมเลยไม่ต้องแก้อะไรเลย
## กดปุ่มบนจอ = เหมือนกดคีย์บอร์ด (ทั้งแบบ polling และแบบรับ event)
##
## ★ เปิด/ปิดกลุ่มเดิน ★  UI.touch.set_mode(TouchControls.Mode.AUTO / ON / OFF)
## AUTO = โผล่เองเมื่อเครื่องมีจอสัมผัส หรือเมื่อมีการแตะจอครั้งแรก
## ค่าที่เลือกถูกจำไว้ใน user://ui_layout.cfg
class_name TouchControls
extends Control

enum Mode { AUTO, ON, OFF }

const LAYOUT_PATH := "user://ui_layout.cfg"

## ---------- ขนาดปุ่ม (ที่จอ 1280×720 — วัดจากภาพตัวอย่าง) ----------
const D_ATTACK := 106.0       # วงโจมตีใหญ่ (J)
const D_SKILL := 66.0         # วงสกิล 1-4
const D_DASH := 66.0          # วงพุ่งหลบ
const D_POTION := 48.0        # ช่องยา Q / R (สี่เหลี่ยม)
const D_WALK := 118.0         # ปุ่มเดิน ◀ ▶ (จอสัมผัส)
const D_DOWN := 84.0          # ปุ่มลง ▼ (จอสัมผัส)
const D_INTERACT := 84.0      # คุย/เก็บของ (จอสัมผัส)
## มุมขวาล่างของวงโจมตี ห่างขอบขวา / ขอบล่างเท่าไหร่
const EDGE_RIGHT := 47.0
const EDGE_BOTTOM := 69.0
const EDGE_LEFT := 26.0
const RING_R := 128.0         # รัศมีวงสกิลรอบปุ่มโจมตี
## วงสกิลเรียงจาก 12 นาฬิกา (ช่อง 1) ทวนเข็มไปถึง 8 นาฬิกา (ช่อง 4) — ภาพตัวอย่างมี 3 ช่อง (12→9) เรามี 4 เลยกางเพิ่ม
const SKILL_CLOCK_START := 12.0
const SKILL_CLOCK_END := 8.7
## ★ มือถือ: ขยายปุ่มทุกปุ่มเท่านี้ ★
const TOUCH_SCALE := 1.35

const PLATE_ALPHA := 0.85
## ไอคอนสกิลตอนคูลดาวน์: เทาเท่าไหร่ (0 = ดำ · 1 = สีปกติ) แล้วไล่กลับมา 1.0 เมื่อคูลดาวน์ครบ
const CD_GRAY := 0.34

var mode: Mode = Mode.AUTO

## รายการปุ่มทั้งหมด: {id, action, group, size, node, rect, ...}
var _zones: Array = []
## นิ้วไหนกดปุ่มไหนอยู่ (index ของนิ้ว -> id ปุ่ม) · เมาส์ = -1
var _fingers: Dictionary = {}
var _shown := false
## กลุ่มเดินโชว์อยู่ไหม (= เครื่องจอสัมผัส)
var walk_visible := false
## ★ เส้นประดับสองข้างช่องยา ★
var _ornaments: Array = []


func _ready() -> void:
	name = "TouchControls"
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 190
	# ปุ่มพวกนี้ไม่กินเมาส์ผ่านระบบ Control — เราอ่านการแตะ/คลิกเองใน _input()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_define_zones()
	_build()
	_load_mode()
	get_viewport().size_changed.connect(_layout)
	_refresh_visible()
	_layout()


## สเกลปุ่มตอนนี้ (มือถือใหญ่กว่า)
func ui_scale() -> float:
	return TOUCH_SCALE if walk_visible else 1.0


# =========================================================
# รายการปุ่ม
# =========================================================
func _define_zones() -> void:
	_zones = [
		# ---------- กลุ่มเดิน (จอสัมผัสเท่านั้น) ----------
		{"id": "left",    "action": "move_left",  "group": "walk", "arrow": "left",  "size": D_WALK},
		{"id": "right",   "action": "move_right", "group": "walk", "arrow": "right", "size": D_WALK},
		{"id": "down",    "action": "move_down",  "group": "walk", "arrow": "down",  "size": D_DOWN},
		{"id": "interact","action": "interact",   "group": "walk", "label": "คุย/เก็บ", "size": D_INTERACT},

		# ---------- กลุ่มสู้ (ทุกเครื่อง) ----------
		{"id": "attack",  "action": "attack", "group": "fight", "size": D_ATTACK, "glyph": "swords", "key": "J"},
		{"id": "skill_1", "action": "skill_1", "group": "fight", "size": D_SKILL, "skill": 0, "key": "1"},
		{"id": "skill_2", "action": "skill_2", "group": "fight", "size": D_SKILL, "skill": 1, "key": "2"},
		{"id": "skill_3", "action": "skill_3", "group": "fight", "size": D_SKILL, "skill": 2, "key": "3"},
		{"id": "skill_4", "action": "skill_4", "group": "fight", "size": D_SKILL, "skill": 3, "key": "4"},
		{"id": "dash",    "action": "jump",    "group": "fight", "size": D_DASH, "glyph": "dash", "key": "DASH"},
		{"id": "potion",  "action": "quick_potion",    "group": "fight", "size": D_POTION, "item": 0, "key": "Q", "square": true},
		{"id": "sp",      "action": "quick_sp_potion", "group": "fight", "size": D_POTION, "item": 1, "key": "R", "square": true},
	]


func _build() -> void:
	# เส้นประดับสองข้างช่องยา (─────◆─────)
	for i in range(2):
		var o := PetrolWidgets.ornament(70.0)
		add_child(o)
		_ornaments.append(o)

	for z in _zones:
		var panel := PanelContainer.new()
		panel.name = "Btn_%s" % z.id
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override("panel", _pad_style(z, false))
		add_child(panel)
		z["node"] = panel

		if not z.has("square"):
			panel.add_child(PetrolWidgets.inner_ring(float(z.size)))

		if z.has("arrow"):
			var arrow := _Arrow.new()
			arrow.dir = String(z.arrow)
			panel.add_child(arrow)
		elif z.has("glyph"):
			var g := PetrolWidgets.glyph(String(z.glyph), float(z.size) * 0.5, UITheme.TEXT)
			g.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			var half := float(z.size) * 0.25
			g.offset_left = -half
			g.offset_top = -half
			g.offset_right = half
			g.offset_bottom = half
			panel.add_child(g)
			z["glyph_node"] = g
		else:
			# ★ ปุ่มสกิล/ยา มีไอคอนข้างใน ★
			if z.has("skill") or z.has("item"):
				var art := TextureRect.new()
				art.name = "SkillIcon"
				art.mouse_filter = Control.MOUSE_FILTER_IGNORE
				art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
				art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				var m: float = float(z.size) * (0.12 if z.has("square") else 0.2)
				art.offset_left = m
				art.offset_top = m
				art.offset_right = -m
				art.offset_bottom = -m
				panel.add_child(art)
				z["icon"] = art
				if z.has("skill"):
					var veil := _CooldownVeil.new()
					veil.name = "Cooldown"
					panel.add_child(veil)
					z["veil"] = veil
			var lbl := UITheme.make_label(String(z.get("label", "")), 15, Color.WHITE)
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_color_override("font_outline_color", Color.BLACK)
			lbl.add_theme_constant_override("outline_size", 4)
			panel.add_child(lbl)
			z["label_node"] = lbl
			if z.has("skill") or z.has("item"):
				# จำนวนยา / ชื่อสกิลย่อ มุมขวาล่าง
				lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
				lbl.offset_left = -34
				lbl.offset_top = -22
				lbl.offset_right = -4
				lbl.offset_bottom = -2
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				lbl.add_theme_font_size_override("font_size", 13)

		# ★ ป้ายปุ่ม (J / 1 / DASH / Q) เม็ดเล็ก ๆ ใต้ปุ่ม ตามภาพ ★
		if z.has("key"):
			var pill := PanelContainer.new()
			pill.name = "Key_%s" % z.id
			pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pill.add_theme_stylebox_override("panel", _pill_style())
			var kl := UITheme.make_label(String(z.key), 11, UITheme.TEXT)
			kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			kl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pill.add_child(kl)
			add_child(pill)
			z["pill"] = pill

	if Events.has_signal("skills_changed"):
		Events.skills_changed.connect(refresh_skill_icons)
	if Events.has_signal("inventory_changed"):
		Events.inventory_changed.connect(refresh_item_icons)
	refresh_skill_icons()
	refresh_item_icons()


static func _pill_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(UITheme.INK, 0.9)
	s.border_color = Color(UITheme.ACCENT, 0.8)
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.content_margin_left = 7
	s.content_margin_right = 7
	s.content_margin_top = 1
	s.content_margin_bottom = 1
	return s


## ★ อัพเดตไอคอนสกิลบนปุ่มตามช่องลัด 1-4 ★
func refresh_skill_icons() -> void:
	if PlayerState == null or PlayerState.skills == null:
		return
	for z in _zones:
		if not z.has("skill") or not z.has("icon"):
			continue
		var sid: StringName = PlayerState.skills.hotkey_at(int(z.skill))
		var sk := GameData.get_skill(sid) if sid != &"" else null
		var art: TextureRect = z.icon
		art.texture = sk.icon if sk != null else null
		var lbl: Label = z.get("label_node", null)
		if lbl != null:
			if art.texture != null:
				lbl.text = ""
			elif sk != null:
				lbl.text = sk.display_name.substr(0, 6)
			else:
				lbl.text = ""
		var node: Control = z.node
		node.tooltip_text = ("%s\n%s" % [sk.display_name, sk.description]) if sk != null \
			else "ยังไม่ได้ตั้งสกิล (เปิดหน้าสกิลด้วย K)"


## ★ ไอคอนยา/มานาบนช่อง Q/R + จำนวนที่เหลือในกระเป๋า ★
func refresh_item_icons() -> void:
	if PlayerState == null:
		return
	for z in _zones:
		if not z.has("item") or not z.has("icon"):
			continue
		var iid: StringName = PlayerState.item_hotkey_at(int(z.item))
		var data := GameData.get_item(iid) if iid != &"" else null
		var art: TextureRect = z.icon
		art.texture = data.icon if data != null else null
		var n := 0
		if PlayerState.inventory != null and iid != &"":
			n = PlayerState.inventory.count_of(iid)
		art.modulate = Color.WHITE if n > 0 else Color(CD_GRAY, CD_GRAY, CD_GRAY)
		var lbl: Label = z.get("label_node", null)
		if lbl == null:
			continue
		if data != null:
			lbl.text = str(n)
			lbl.add_theme_color_override("font_color", Color.WHITE if n > 0 else Color("#ff9c9c"))
		else:
			lbl.text = ""
		var node: Control = z.node
		node.tooltip_text = ("%s (เหลือ %d)" % [data.display_name, n]) if data != null \
			else "ยังไม่ได้เลือกยา — เปิดกระเป๋า (I) แล้วกดตั้งช่อง %s" % String(z.key)


## ★ คูลดาวน์: ไอคอนสกิลเทาแล้วค่อย ๆ กลับมาสีสด + ม่านพัด · ยาโชว์เลขวินาที ★
func _tick_cooldowns() -> void:
	if PlayerState == null or PlayerState.skills == null:
		return
	for z in _zones:
		if z.has("skill") and z.has("icon"):
			var art: TextureRect = z.icon
			var veil = z.get("veil", null)
			var sid: StringName = PlayerState.skills.hotkey_at(int(z.skill))
			var t := 1.0
			if sid != &"":
				var left: float = PlayerState.skill_cooldown_left(sid)
				if left > 0.0:
					var sk := GameData.get_skill(sid)
					var total: float = maxf(0.0, float(sk.cooldown)) if sk != null else 0.0
					t = clampf(1.0 - left / total, 0.0, 1.0) if total > 0.0 else 0.0
			var g: float = lerpf(CD_GRAY, 1.0, t)
			art.modulate = Color(g, g, g)
			if veil != null:
				veil.set_progress(1.0 - t)
		elif z.has("item") and z.has("label_node"):
			var lbl: Label = z.label_node
			var left2: float = 0.0
			if PlayerState.has_method("potion_cooldown_left_of_id"):
				left2 = PlayerState.potion_cooldown_left_of_id(PlayerState.item_hotkey_at(int(z.item)))
			var node: Control = z.node
			if left2 > 0.0:
				node.modulate = Color(0.55, 0.55, 0.6)
				lbl.text = ("%.1f" % left2) if left2 < 1.0 else str(int(ceil(left2)))
			else:
				node.modulate = Color.WHITE


func _pad_style(z: Dictionary, pressed: bool) -> StyleBoxFlat:
	if z.has("square"):
		var st := UITheme.slot_style(pressed)
		st.bg_color = Color(UITheme.INK, PLATE_ALPHA)
		st.border_color = UITheme.ACCENT
		st.set_border_width_all(2 if pressed else 1)
		return st
	return PetrolWidgets.ring_style(pressed, PLATE_ALPHA)


# =========================================================
# วางตำแหน่งปุ่ม (ตามภาพตัวอย่าง · สเกลตามจอและมือถือ)
# =========================================================
func _layout() -> void:
	var vp := get_viewport_rect().size
	var s := ui_scale()

	# ---------- วงโจมตี มุมขวาล่าง ----------
	var attack_d := D_ATTACK * s
	var center := Vector2(vp.x - EDGE_RIGHT * s - attack_d * 0.5, vp.y - EDGE_BOTTOM * s - attack_d * 0.5)
	_set_rect("attack", center - Vector2.ONE * attack_d * 0.5, attack_d)

	# ---------- สกิล 1-4 เรียงบนวง 12 → 9 นาฬิกา ----------
	var ids := ["skill_1", "skill_2", "skill_3", "skill_4"]
	var n := ids.size()
	var ring := RING_R * s
	var skill_d := D_SKILL * s
	for i in range(n):
		var t: float = float(i) / float(maxi(1, n - 1))
		var clock: float = SKILL_CLOCK_START + (SKILL_CLOCK_END - SKILL_CLOCK_START) * t
		var ang: float = deg_to_rad(clock * 30.0)          # 12 นาฬิกา = 0° · ตามเข็ม
		var dir := Vector2(sin(ang), -cos(ang))
		_set_rect(ids[i], center + dir * ring - Vector2.ONE * skill_d * 0.5, skill_d)

	# ---------- DASH ซ้ายของวงสกิล ระดับเดียวกับวงโจมตี ----------
	var dash_d := D_DASH * s
	var dash_pos := Vector2(center.x - ring - skill_d * 0.5 - 22.0 * s - dash_d, center.y + 9.0 * s - dash_d * 0.5)
	_set_rect("dash", dash_pos, dash_d)

	# ---------- ยา Q / R กลางล่าง ----------
	var pot_d := D_POTION * s
	var gap := 22.0 * s
	var py := vp.y - 76.0 * s - pot_d
	_set_rect("potion", Vector2(vp.x * 0.5 - gap * 0.5 - pot_d, py), pot_d)
	_set_rect("sp", Vector2(vp.x * 0.5 + gap * 0.5, py), pot_d)
	if _ornaments.size() >= 2:
		var ow := 70.0 * s
		for i in range(2):
			var o: Control = _ornaments[i]
			o.custom_minimum_size = Vector2(ow, 12.0)
			o.size = Vector2(ow, 12.0)
			var x: float = (vp.x * 0.5 - gap * 0.5 - pot_d - 12.0 * s - ow) if i == 0 else (vp.x * 0.5 + gap * 0.5 + pot_d + 12.0 * s)
			o.position = Vector2(x, py + pot_d * 0.5 - 6.0)

	# ---------- กลุ่มเดิน (จอสัมผัส) ----------
	var walk_d := D_WALK * s
	var bottom := vp.y - EDGE_BOTTOM * s
	_set_rect("left", Vector2(EDGE_LEFT * s, bottom - walk_d), walk_d)
	_set_rect("right", Vector2(EDGE_LEFT * s + walk_d + 12.0 * s, bottom - walk_d), walk_d)
	var down_d := D_DOWN * s
	_set_rect("down", Vector2(EDGE_LEFT * s + (walk_d * 2.0 + 12.0 * s - down_d) * 0.5, bottom - walk_d - 12.0 * s - down_d), down_d)
	var it_d := D_INTERACT * s
	_set_rect("interact", Vector2(dash_pos.x + dash_d * 0.5 - it_d * 0.5, dash_pos.y - 16.0 * s - it_d), it_d)

	# ---------- ป้ายปุ่มใต้ปุ่ม ----------
	for z in _zones:
		if not z.has("pill") or not z.has("rect"):
			continue
		var pill: Control = z.pill
		var r: Rect2 = z.rect
		pill.reset_size()
		var pw: float = maxf(pill.size.x, pill.get_combined_minimum_size().x)
		var ph: float = maxf(pill.size.y, pill.get_combined_minimum_size().y)
		pill.position = Vector2(r.position.x + r.size.x * 0.5 - pw * 0.5, r.end.y - 4.0 * s)
		if z.has("square"):
			pill.position.y = r.end.y + 6.0 * s
		pill.size = Vector2(pw, ph)


func _set_rect(id: String, pos: Vector2, d: float) -> void:
	for z in _zones:
		if z.id != id:
			continue
		z["rect"] = Rect2(pos, Vector2(d, d))
		var node: Control = z.node
		node.position = pos
		node.size = Vector2(d, d)
		return


# =========================================================
# เปิด / ปิด
# =========================================================
func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_save_mode()
	_refresh_visible()


func mode_text() -> String:
	match mode:
		Mode.ON: return "เปิดตลอด"
		Mode.OFF: return "ปิด"
	return "อัตโนมัติ"


## เครื่องนี้ควรมีปุ่มเดินบนจอไหม
func should_show() -> bool:
	match mode:
		Mode.ON: return true
		Mode.OFF: return false
	if DisplayServer.is_touchscreen_available():
		return true
	return _shown   # เคยมีการแตะจอมาแล้ว


func _refresh_visible() -> void:
	var want_walk: bool = should_show()
	# ระหว่างเปิดหน้าต่าง/คุยกับ NPC/ตายอยู่ ให้ซ่อนทั้งหมด จะได้ไม่บังปุ่มในกล่อง
	var busy: bool = UI.is_any_window_open() or UI.is_asking()
	var want_all: bool = not busy and UI.in_game

	if want_walk != walk_visible:
		walk_visible = want_walk
		_layout()
	for z in _zones:
		var node: Control = z.node
		var on: bool = want_all and (String(z.group) != "walk" or walk_visible)
		node.visible = on
		if z.has("pill"):
			(z.pill as Control).visible = on
	for o in _ornaments:
		(o as Control).visible = want_all

	if want_all == visible:
		return
	visible = want_all
	if not want_all:
		_release_all()


func _process(_delta: float) -> void:
	_refresh_visible()
	if visible:
		_tick_cooldowns()


# =========================================================
# อ่านการแตะจอ (แยกตามนิ้ว = กดพร้อมกันหลายปุ่มได้) + เมาส์บนคอม
# =========================================================
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		# แตะจอครั้งแรก = เครื่องนี้มีจอสัมผัสจริง โผล่ปุ่มเดินให้เลย (โหมดอัตโนมัติ)
		if not _shown and mode == Mode.AUTO:
			_shown = true
			_refresh_visible()
		if not visible:
			return
		if t.pressed:
			_press_at(t.index, t.position)
		else:
			_release_finger(t.index)
	elif event is InputEventScreenDrag and visible:
		var d := event as InputEventScreenDrag
		# ลากนิ้วจากปุ่มหนึ่งไปอีกปุ่ม (เช่นสไลด์ซ้าย->ขวา) ให้เปลี่ยนปุ่มตาม
		var now := _zone_at(d.position)
		var was: String = String(_fingers.get(d.index, ""))
		var now_id: String = String(now.id) if not now.is_empty() else ""
		if now_id != was:
			_release_finger(d.index)
			if now_id != "":
				_press_at(d.index, d.position)
	elif event is InputEventMouseButton and visible:
		# ★ รอบ 98 ★ คอม: คลิกซ้ายบนปุ่มก็ใช้ได้ (นิ้วหมายเลข -1)
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			if _zone_at(mb.position).is_empty():
				return
			_press_at(-1, mb.position)
			get_viewport().set_input_as_handled()
		elif _fingers.has(-1):
			_release_finger(-1)
			get_viewport().set_input_as_handled()


func _press_at(index: int, pos: Vector2) -> void:
	var z := _zone_at(pos)
	if z.is_empty():
		return
	_fingers[index] = z.id
	_set_pressed(z, true)
	var action := String(z.get("action", ""))
	if action != "" and InputMap.has_action(action):
		# ส่งทั้ง 2 แบบ: action_press (โค้ดที่เช็คแบบ polling)
		# + InputEventAction (โค้ดที่เช็คใน _input/_unhandled_input เช่น NPC กด F)
		Input.action_press(action)
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = true
		Input.parse_input_event(ev)


func _release_finger(index: int) -> void:
	if not _fingers.has(index):
		return
	var id: String = String(_fingers[index])
	_fingers.erase(index)
	for z in _zones:
		if z.id != id:
			continue
		_set_pressed(z, false)
		var action := String(z.get("action", ""))
		if action != "" and InputMap.has_action(action):
			Input.action_release(action)
			var ev := InputEventAction.new()
			ev.action = action
			ev.pressed = false
			Input.parse_input_event(ev)
		if z.has("tap"):
			(z.tap as Callable).call()
		return


func _release_all() -> void:
	for index in _fingers.keys().duplicate():
		_release_finger(index)


func _set_pressed(z: Dictionary, on: bool) -> void:
	var node: Control = z.node
	node.add_theme_stylebox_override("panel", _pad_style(z, on))


## ปุ่มไหนอยู่ตรงจุดนี้ (เผื่อระยะนิ้วอ้วนไว้นิดหน่อย) — ปุ่มที่ซ่อนอยู่ไม่นับ
func _zone_at(pos: Vector2) -> Dictionary:
	for z in _zones:
		if not z.has("rect"):
			continue
		if not (z.node as Control).visible:
			continue
		if (z.rect as Rect2).grow(6.0).has_point(pos):
			return z
	return {}


## จุดนี้ทับปุ่มบนจอไหม (UI.is_point_over_ui เรียกใช้ กันคลิกทะลุไปตีมอน)
func is_over(point: Vector2) -> bool:
	if not visible:
		return false
	return not _zone_at(point).is_empty()


# =========================================================
# จำค่าที่เลือกไว้
# =========================================================
func _save_mode() -> void:
	var cfg := ConfigFile.new()
	cfg.load(LAYOUT_PATH)
	cfg.set_value("touch", "mode", int(mode))
	cfg.save(LAYOUT_PATH)


func _load_mode() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(LAYOUT_PATH) != OK:
		return
	var v = cfg.get_value("touch", "mode", int(Mode.AUTO))
	if typeof(v) == TYPE_INT and v >= 0 and v <= 2:
		mode = v as Mode


# =========================================================
# ลูกศรบนปุ่มเดิน (วาดเอง — ฟอนต์ไทยไม่มี glyph ลูกศร)
# =========================================================
class _Arrow extends Control:
	var dir := "left"

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var r: float = minf(size.x, size.y) * 0.24
		var pts := PackedVector2Array()
		match dir:
			"left":
				pts = PackedVector2Array([c + Vector2(r, -r), c + Vector2(r, r), c + Vector2(-r, 0)])
			"right":
				pts = PackedVector2Array([c + Vector2(-r, -r), c + Vector2(-r, r), c + Vector2(r, 0)])
			"down":
				pts = PackedVector2Array([c + Vector2(-r, -r * 0.6), c + Vector2(r, -r * 0.6),
					c + Vector2(0, r * 0.8)])
			_:
				pts = PackedVector2Array([c + Vector2(-r, r * 0.6), c + Vector2(r, r * 0.6),
					c + Vector2(0, -r * 0.8)])
		draw_colored_polygon(pts, Color(UITheme.TEXT, 0.92))

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()


# =========================================================
# ม่านคูลดาวน์บนปุ่มสกิล — "พัด" สีเข้มทับไอคอน กินพื้นที่เท่าสัดส่วนคูลดาวน์ที่เหลือ
# =========================================================
class _CooldownVeil extends Control:
	var progress := 0.0      # 1 = เพิ่งใช้ (บังทั้งวง) · 0 = พร้อมใช้ (ไม่บังเลย)

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_progress(v: float) -> void:
		var nv: float = clampf(v, 0.0, 1.0)
		if absf(nv - progress) < 0.004:
			return
		progress = nv
		visible = progress > 0.0
		queue_redraw()

	func _draw() -> void:
		if progress <= 0.0:
			return
		var c := size * 0.5
		var r: float = minf(size.x, size.y) * 0.5 - 3.0
		var steps: int = maxi(3, int(ceilf(progress * 48.0)))
		var pts := PackedVector2Array([c])
		for i in range(steps + 1):
			var ang: float = deg_to_rad(-90.0 + 360.0 * progress * (float(i) / float(steps)))
			pts.append(c + Vector2(cos(ang), sin(ang)) * r)
		draw_colored_polygon(pts, Color(0.03, 0.05, 0.09, 0.62))

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()
