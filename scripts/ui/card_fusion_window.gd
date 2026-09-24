## CardFusionWindow — ★ รอบ 154 ★ ย่อยการ์ด (ดีไซน์ A «วงห้าแฉก» — _docs/mockup_รอบ154_2_ย่อยการ์ด_A.png)
##
## ซ้าย = การ์ดในกระเป๋าแยกตามเกรด (คลิก = ใส่ช่องถัดไป · ปุ่มใส่อัตโนมัติเลือกใบซ้ำก่อน)
## กลาง = 5 ช่องรอบการ์ดปริศนา (คลิกช่อง = เอาออก) · ขวา = เงื่อนไข · เพดาน Lv · รายชื่อการ์ดที่อาจได้ + % · ปุ่มย่อย
## กติกาอยู่ที่ CardAlbum (เกรด 1-4 · Lv ผลลัพธ์ ≤ Lv สูงสุดที่ใส่ · การ์ดบอส/หอไม่สุ่มออก)
## เปิดจาก Events.card_fusion_opened (เมนู «ย่อยการ์ด» ของพ่อค้าทุกเมือง)
class_name CardFusionWindow
extends GameWindow

const LIST_W := 250.0
const DETAIL_W := 250.0
const RING_SIZE := Vector2(460, 440)
const RING_R := 160.0
const SLOT_SIZE := Vector2(74, 104)
const CENTER_SIZE := Vector2(92, 128)
const GRADE_NAMES := {1: "ธรรมดา", 2: "ไม่ธรรมดา", 3: "หายาก", 4: "หายากมาก"}

var _grade := 1
var _picked: Array[StringName] = []
var _grade_btns: Dictionary = {}
var _bag_grid: GridContainer
var _ring: Control
var _ring_draw: _FusionRing
var _slot_btns: Array[Button] = []
var _center: PanelContainer
var _center_art: TextureRect
var _center_mark: Label
var _status: Label
var _fee_label: Label
var _fuse_btn: Button
var _info: RichTextLabel


func _init() -> void:
	window_title = "ย่อยการ์ด"


func _build_content() -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 10)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(columns)

	# ---------- ซ้าย: การ์ดในกระเป๋า ----------
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", UITheme.inner_style(UITheme.PANEL, 6, 8.0))
	left.custom_minimum_size = Vector2(LIST_W, RING_SIZE.y + 60)
	columns.add_child(left)
	var lbox := VBoxContainer.new()
	lbox.add_theme_constant_override("separation", 6)
	left.add_child(lbox)
	lbox.add_child(UITheme.make_label("การ์ดในกระเป๋า", 13, UITheme.TEXT_DIM))
	var tabs := GridContainer.new()
	tabs.columns = 2
	tabs.add_theme_constant_override("h_separation", 4)
	tabs.add_theme_constant_override("v_separation", 4)
	lbox.add_child(tabs)
	for g in GRADE_NAMES.keys():
		var b := UITheme.make_button(GRADE_NAMES[g], 110)
		b.pressed.connect(_set_grade.bind(g))
		tabs.add_child(b)
		_grade_btns[g] = b
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbox.add_child(scroll)
	_bag_grid = GridContainer.new()
	_bag_grid.columns = 3
	_bag_grid.add_theme_constant_override("h_separation", 6)
	_bag_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_bag_grid)
	var auto := UITheme.make_button("ใส่อัตโนมัติ (ใบซ้ำก่อน)")
	auto.pressed.connect(_auto_fill)
	lbox.add_child(auto)
	var clear := UITheme.make_button("เอาออกทั้งหมด")
	clear.pressed.connect(func():
		_picked.clear()
		refresh())
	lbox.add_child(clear)

	# ---------- กลาง: วงห้าแฉก ----------
	var mid_panel := PanelContainer.new()   # พื้นทึบกลางวง (ไม่ให้ข้อความข้างหลังโผล่)
	mid_panel.add_theme_stylebox_override("panel", UITheme.inner_style(UITheme.PANEL, 6, 4.0))
	columns.add_child(mid_panel)
	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 6)
	mid_panel.add_child(mid)
	_ring = Control.new()
	_ring.custom_minimum_size = RING_SIZE
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(_ring)
	_ring_draw = _FusionRing.new()
	_ring_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ring_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.add_child(_ring_draw)
	var center := RING_SIZE * 0.5
	var positions: Array = []
	for i in range(CardAlbum.FUSION_COUNT):
		var a := -PI * 0.5 + TAU * float(i) / float(CardAlbum.FUSION_COUNT)
		var p := center + Vector2(cos(a), sin(a)) * RING_R
		positions.append(p)
		var btn := Button.new()
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = SLOT_SIZE
		btn.size = SLOT_SIZE
		btn.position = p - SLOT_SIZE * 0.5
		btn.pressed.connect(_unpick.bind(i))
		UITheme.make_slot_icon(btn, 3.0)
		_ring.add_child(btn)
		_slot_btns.append(btn)
	_ring_draw.center = center
	_ring_draw.positions = positions
	_center = PanelContainer.new()
	_center.custom_minimum_size = CENTER_SIZE
	_center.size = CENTER_SIZE
	_center.position = center - CENTER_SIZE * 0.5
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.add_child(_center)
	_center_art = TextureRect.new()
	_center_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_center_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_center_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center.add_child(_center_art)
	_center_mark = UITheme.make_label("?", 56, UITheme.GOLD_BRIGHT)
	_center_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_center_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center.add_child(_center_mark)
	_status = UITheme.make_label("", 13, UITheme.TEXT_DIM)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.custom_minimum_size.x = RING_SIZE.x
	mid.add_child(_status)

	# ---------- ขวา: เงื่อนไข + ผลที่อาจได้ ----------
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", UITheme.inner_style(UITheme.PANEL, 6, 8.0))
	right.custom_minimum_size = Vector2(DETAIL_W, 0)
	columns.add_child(right)
	var rbox := VBoxContainer.new()
	rbox.add_theme_constant_override("separation", 8)
	right.add_child(rbox)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.fit_content = false
	_info.scroll_active = true
	_info.custom_minimum_size = Vector2(DETAIL_W - 16, 330)
	_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info.add_theme_font_size_override("normal_font_size", 13)
	_info.add_theme_color_override("default_color", UITheme.TEXT)
	rbox.add_child(_info)
	_fee_label = UITheme.make_label("", 13, UITheme.TEXT)
	rbox.add_child(_fee_label)
	_fuse_btn = UITheme.make_gold_button("ย่อยการ์ด")
	_fuse_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fuse_btn.custom_minimum_size.y = 40
	_fuse_btn.pressed.connect(_on_fuse_pressed)
	rbox.add_child(_fuse_btn)

	Events.inventory_changed.connect(refresh)
	Events.zeny_changed.connect(func(_z): refresh())


## เปิดใหม่ทุกครั้ง = เริ่มเกรดที่มีการ์ดพอ (ถ้าไม่มีเลยก็ธรรมดา)
func reset_for_open() -> void:
	_picked.clear()
	_grade = 1
	for g in GRADE_NAMES.keys():
		if _bag_count_of_grade(g) >= CardAlbum.FUSION_COUNT:
			_grade = g
			break


func _set_grade(g: int) -> void:
	if g == _grade:
		return
	_grade = g
	_picked.clear()
	refresh()


## การ์ดเกรดนี้ในกระเป๋า — [[CardData, จำนวน], ...] เรียงตาม Lv
func _bag_cards(g: int) -> Array:
	var counts: Dictionary = {}
	var inv := PlayerState.inventory
	for i in range(inv.size):
		var s := inv.get_slot(i)
		if s == null:
			continue
		var d := s.data()
		if d is CardData and (d as CardData).rarity == g:
			counts[s.item_id] = int(counts.get(s.item_id, 0)) + s.count
	var out: Array = []
	for cid in counts.keys():
		out.append([GameData.get_card(cid), int(counts[cid])])
	out.sort_custom(func(a, b): return (a[0] as CardData).sort_level() < (b[0] as CardData).sort_level())
	return out


func _bag_count_of_grade(g: int) -> int:
	var n := 0
	for pair in _bag_cards(g):
		n += int(pair[1])
	return n


func _picked_count(cid: StringName) -> int:
	var n := 0
	for p in _picked:
		if p == cid:
			n += 1
	return n


func _pick(cid: StringName) -> void:
	if _picked.size() >= CardAlbum.FUSION_COUNT:
		Events.say("ใส่ครบ %d ใบแล้ว — คลิกช่องเพื่อเอาออก" % CardAlbum.FUSION_COUNT)
		return
	if _picked_count(cid) >= PlayerState.inventory.count_of(cid):
		return
	_picked.append(cid)
	refresh()


func _unpick(index: int) -> void:
	if index < _picked.size():
		_picked.remove_at(index)
		refresh()


## ใบซ้ำ (มีเยอะ) ก่อน แล้วใบ Lv ต่ำก่อน
func _auto_fill() -> void:
	var cards := _bag_cards(_grade)
	cards.sort_custom(func(a, b):
		if int(a[1]) != int(b[1]):
			return int(a[1]) > int(b[1])
		return (a[0] as CardData).sort_level() < (b[0] as CardData).sort_level())
	for pair in cards:
		var c: CardData = pair[0]
		while _picked.size() < CardAlbum.FUSION_COUNT and _picked_count(c.id) < int(pair[1]):
			_picked.append(c.id)
	refresh()


func refresh() -> void:
	if _bag_grid == null or not is_visible_in_tree():
		return
	# ใบที่เลือกไว้แต่หายจากกระเป๋าแล้ว → ตัดออก
	var fixed: Array[StringName] = []
	for p in _picked:
		if _picked_count_in(fixed, p) < PlayerState.inventory.count_of(p):
			fixed.append(p)
	_picked = fixed
	for g in _grade_btns.keys():
		var b: Button = _grade_btns[g]
		b.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT if g == _grade else UITheme.TEXT_DIM)
		b.text = "%s (%d)" % [GRADE_NAMES[g], _bag_count_of_grade(g)]
	_rebuild_bag()
	_rebuild_slots()
	_rebuild_info()


static func _picked_count_in(arr: Array[StringName], cid: StringName) -> int:
	var n := 0
	for p in arr:
		if p == cid:
			n += 1
	return n


func _rebuild_bag() -> void:
	GameWindow.clear_container(_bag_grid)
	var cards := _bag_cards(_grade)
	if cards.is_empty():
		var l := UITheme.make_label("ไม่มีการ์ดเกรด\n%s ในกระเป๋า" % GRADE_NAMES[_grade], 12, UITheme.TEXT_DIM)
		_bag_grid.add_child(l)
		return
	for pair in cards:
		var c: CardData = pair[0]
		var left := int(pair[1]) - _picked_count(c.id)
		var btn := Button.new()
		btn.flat = false
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(66, 92)
		btn.add_theme_stylebox_override("normal", _card_style(c.rarity_color(), false))
		btn.add_theme_stylebox_override("hover", _card_style(UITheme.GOLD_BRIGHT, true))
		btn.add_theme_stylebox_override("pressed", _card_style(UITheme.GOLD_BRIGHT, true))
		btn.tooltip_text = "%s · Lv %d\n%s" % [c.display_name, c.sort_level(), c.describe()]
		btn.disabled = left <= 0
		btn.modulate = Color.WHITE if left > 0 else Color(0.45, 0.45, 0.5)
		var pair2 := UITheme.make_slot_icon(btn, 3.0)
		(pair2[0] as TextureRect).texture = CardView.card_texture(c)
		(pair2[1] as Label).text = "×%d" % left
		btn.pressed.connect(_pick.bind(c.id))
		_bag_grid.add_child(btn)


func _rebuild_slots() -> void:
	for i in range(_slot_btns.size()):
		var btn := _slot_btns[i]
		var art: TextureRect = btn.get_node("SlotIcon")
		var cnt: Label = btn.get_node("SlotCount")
		cnt.text = ""
		if i < _picked.size():
			var c := GameData.get_card(_picked[i])
			art.texture = CardView.card_texture(c)
			btn.tooltip_text = "%s · Lv %d\n(คลิกเพื่อเอาออก)" % [c.display_name, c.sort_level()]
			btn.add_theme_stylebox_override("normal", _card_style(c.rarity_color(), false))
			btn.add_theme_stylebox_override("hover", _card_style(UITheme.BAD, true))
		else:
			art.texture = null
			var next := i == _picked.size()
			btn.tooltip_text = "คลิกการ์ดทางซ้ายเพื่อใส่"
			btn.add_theme_stylebox_override("normal", _card_style(UITheme.GOLD_BRIGHT if next else UITheme.BORDER, next, true))
			btn.add_theme_stylebox_override("hover", _card_style(UITheme.GOLD_BRIGHT, true, true))
			cnt.text = "+" if next else ""
			cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cnt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			cnt.add_theme_font_size_override("font_size", 26 if next else 11)
			cnt.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
		if i < _picked.size():
			cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			cnt.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			cnt.add_theme_font_size_override("font_size", 11)
	var col: Color = _grade_color(_grade)
	_center.add_theme_stylebox_override("panel", _card_style(col, true))
	_center_mark.add_theme_color_override("font_color", col)
	_ring_draw.accent = col
	_ring_draw.queue_redraw()


func _rebuild_info() -> void:
	var chk := CardAlbum.check_fusion(_picked)
	var grade := _grade
	var max_level := int(chk.max_level)
	var t := "[color=#b5a16c]เงื่อนไข[/color]\n"
	t += "• การ์ดเกรด «%s» %d ใบ  (%d/%d)\n" % [GRADE_NAMES[grade], CardAlbum.FUSION_COUNT, _picked.size(), CardAlbum.FUSION_COUNT]
	t += "• ผลสุ่ม Lv ไม่เกิน Lv สูงสุดที่ใส่%s\n" % ("  → [b]Lv %d[/b]" % max_level if max_level > 0 else "")
	t += "• การ์ดบอส/หอร้อยชั้นไม่สุ่มออก · ระดับตำนานย่อยไม่ได้\n\n"
	if _picked.is_empty():
		t += "[color=#81958a]ใส่การ์ดเพื่อดูผลที่อาจได้[/color]"
	else:
		var pool: Array = chk.pool
		if pool.is_empty():
			pool = CardAlbum.fusion_pool(grade, max_level)
		if pool.is_empty():
			t += "[color=#ff7b6b]ไม่มีการ์ดเกรดนี้ที่ Lv ≤ %d ให้สุ่ม[/color]" % max_level
		else:
			var pct := 100.0 / float(pool.size())
			t += "[color=#b5a16c]อาจได้ (โอกาสเท่ากัน)[/color]\n"
			for c: CardData in pool:
				var mark := "" if PlayerState.card_known(c.id) else "  [color=#7fe39a]NEW[/color]"
				t += "%s Lv%d · %s%%%s\n" % [c.display_name.replace("การ์ด", ""), c.sort_level(), ("%.1f" % pct).trim_suffix(".0"), mark]
	_info.text = t
	var fee := CardAlbum.fusion_fee(grade)
	var enough := PlayerState.zeny >= fee
	_fee_label.text = "ค่าบริการ %s z · มี %s z" % [HUD._comma(fee), HUD._comma(PlayerState.zeny)]
	_fee_label.add_theme_color_override("font_color", UITheme.TEXT if enough else UITheme.BAD)
	var can_fuse: bool = bool(chk.ok) and enough
	_fuse_btn.disabled = not can_fuse
	if bool(chk.ok) and not enough:
		_fuse_btn.text = "เงินไม่พอ"
	elif bool(chk.ok):
		_fuse_btn.text = "ย่อย %d ใบ → สุ่ม 1 ใบ" % CardAlbum.FUSION_COUNT
	else:
		_fuse_btn.text = String(chk.reason) if String(chk.reason) != "" else "ย่อยการ์ด"
	_status.text = "ใส่ %d/%d ใบ · เกรด %s" % [_picked.size(), CardAlbum.FUSION_COUNT, GRADE_NAMES[grade]]


func _on_fuse_pressed() -> void:
	var ids: Array = []
	for p in _picked:
		ids.append(p)
	var res := PlayerState.fuse_cards(ids)
	if not bool(res.get("ok", false)):
		Events.say(String(res.get("reason", "ย่อยไม่ได้")))
		refresh()
		return
	_picked.clear()
	if Game.sfx != null:
		Game.sfx.play_first(["card_fusion", "craft_success", "refine_success"])
	var cid: StringName = res.card_id
	var card := GameData.get_card(cid)
	Events.say("[ย่อยการ์ด] ได้%s" % (card.display_name if card != null else String(cid)))
	# ใบใหม่ที่ไม่เคยมี → gain_item เปิดหน้า OBTAIN CARD ให้แล้ว · ใบที่เคยมี → เปิดเอง
	if not bool(res.get("first", false)) and UI.card_popup != null:
		UI.card_popup.show_card(cid)
	refresh()


static func _grade_color(g: int) -> Color:
	match g:
		1: return Color("#9aa7bd")
		2: return Color("#5ccf7a")
		3: return Color("#4c9ce6")
		4: return Color("#b96bff")
	return Color("#ffb43a")


static func _card_style(border: Color, strong: bool, dashed: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#0b1c1b") if dashed else Color("#102725")
	s.border_color = border if not dashed or strong else Color(border, 0.6)
	s.set_border_width_all(3 if strong else 2)
	s.set_corner_radius_all(6)
	if strong:
		s.shadow_color = Color(border, 0.35)
		s.shadow_size = 8
	return s


class _FusionRing extends Control:
	var center := Vector2.ZERO
	var positions: Array = []
	var accent := Color("#b5a16c")

	func _draw() -> void:
		draw_arc(center, CardFusionWindow.RING_R, 0.0, TAU, 96, Color(UITheme.BORDER, 0.9), 1.5, true)
		for p in positions:
			draw_line(center, p, Color(UITheme.BORDER, 0.8), 1.0, true)
		draw_circle(center, 82.0, Color(accent, 0.10))
		draw_arc(center, 82.0, 0.0, TAU, 72, Color(accent, 0.8), 2.0, true)
