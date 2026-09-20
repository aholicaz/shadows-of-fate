## CraftWindow — หน้าต่างคราฟต์ของช่างเหล็ก (★ รอบ 132 ★ ดีไซน์ A «วงคราฟต์» — ดู _docs/mockup_รอบ131_คราฟต์_A.png)
##
## ซ้าย = รายการสูตรแยกตามบท (สีเขียว = วัตถุดิบครบ) · กลาง = ของที่จะได้อยู่กลางวง วัตถุดิบเรียงรอบวง
## (กรอบเขียว = ครบ · กรอบแดง = ขาด · เลข มี/ต้องใช้) · ขวา = รายละเอียดของ + โบนัสสุ่ม + ที่หาวัตถุดิบ
## คลิกวัตถุดิบ = กล่องรายละเอียดไอเทม · ปุ่มล่าง = คราฟต์ (บอกเลยว่าขาดอะไรกี่ชิ้น)
## เปิดจาก Events.craft_npc_opened (เมนู «คราฟต์» ของช่างเหล็กทุกเมือง) · สูตรอยู่ data/recipes/*.tres
class_name CraftWindow
extends GameWindow

const LIST_W := 236.0
const DETAIL_W := 236.0
const RING_SIZE := Vector2(520, 430)
const RING_R := 146.0
const SLOT := 74.0
const CENTER_D := 124.0
const CHAPTER_NAMES := {1: "บท 1 มิดการ์ด", 2: "บท 2 นิดาเวลลิร์", 3: "บท 3 วานาเฮม", 4: "บท 4 โยตุนเฮม", 5: "บท 5 อัลฟ์เฮม", 6: "บท 6 นิฟล์เฮม", 7: "บท 7 มุสเปลเฮม"}

var _list: VBoxContainer
var _ring: Control
var _ring_draw: RingDraw
var _center_btn: Button
var _center_icon: TextureRect
var _center_name: Label
var _center_sub: Label
var _slots: Array = []            # {btn, art, count, name}
var _zeny_label: Label
var _craft_btn: Button
var _detail_title: Label
var _detail_text: RichTextLabel
var _detail_sources: VBoxContainer
var _selected: StringName = &""
var _npc_hint: Label


func _init() -> void:
	window_title = "ตีเหล็ก — คราฟต์"


func _build_content() -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 10)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(columns)

	# ---------- ซ้าย: รายการสูตร ----------
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", UITheme.inner_style(UITheme.PANEL, 6, 6.0))
	left.custom_minimum_size = Vector2(LIST_W, RING_SIZE.y + 96)
	columns.add_child(left)
	var lbox := VBoxContainer.new()
	lbox.add_theme_constant_override("separation", 4)
	left.add_child(lbox)
	lbox.add_child(UITheme.make_label("สูตร", 13, UITheme.TEXT_DIM))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbox.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	# ---------- กลาง: วงคราฟต์ ----------
	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 6)
	columns.add_child(mid)
	_ring = Control.new()
	_ring.custom_minimum_size = RING_SIZE
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(_ring)
	_ring_draw = RingDraw.new()
	_ring_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ring_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.add_child(_ring_draw)

	# ของกลางวง
	_center_btn = Button.new()
	_center_btn.flat = true
	_center_btn.custom_minimum_size = Vector2(CENTER_D, CENTER_D)
	_center_btn.size = Vector2(CENTER_D, CENTER_D)
	_center_btn.add_theme_stylebox_override("normal", _round_style(Color("#243c34"), UITheme.ACCENT, 3))
	_center_btn.add_theme_stylebox_override("hover", _round_style(Color("#2e4a40"), UITheme.GOLD_BRIGHT, 3))
	_center_btn.add_theme_stylebox_override("pressed", _round_style(Color("#34483b"), UITheme.GOLD_BRIGHT, 3))
	_center_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_center_btn.pressed.connect(_on_center_pressed)
	_ring.add_child(_center_btn)
	var pair := UITheme.make_slot_icon(_center_btn, 14.0)
	_center_icon = pair[0]
	(pair[1] as Label).visible = false
	_center_name = UITheme.make_label("", 18, UITheme.GOLD_BRIGHT)
	_center_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.add_child(_center_name)
	_center_sub = UITheme.make_label("", 12, UITheme.TEXT_DIM)
	_center_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.add_child(_center_sub)

	var foot := VBoxContainer.new()
	foot.add_theme_constant_override("separation", 6)
	mid.add_child(foot)
	_zeny_label = UITheme.make_label("", 14, UITheme.TEXT)
	_zeny_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_child(_zeny_label)
	_craft_btn = UITheme.make_gold_button("คราฟต์", 320.0)
	_craft_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_craft_btn.pressed.connect(_on_craft_pressed)
	foot.add_child(_craft_btn)

	# ---------- ขวา: รายละเอียด ----------
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", UITheme.inner_style(UITheme.PANEL, 6, 8.0))
	right.custom_minimum_size = Vector2(DETAIL_W, 0)
	columns.add_child(right)
	var rbox := VBoxContainer.new()
	rbox.add_theme_constant_override("separation", 6)
	right.add_child(rbox)
	_detail_title = UITheme.make_label("", 16, UITheme.GOLD_BRIGHT)
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rbox.add_child(_detail_title)
	_detail_text = RichTextLabel.new()
	_detail_text.bbcode_enabled = true
	_detail_text.fit_content = false          # ห้ามยืดตามเนื้อหา — หน้าต่างจะล้นจอ (กับดักรอบ 124)
	_detail_text.scroll_active = true
	_detail_text.custom_minimum_size = Vector2(DETAIL_W - 16, 170)
	_detail_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_text.add_theme_font_size_override("normal_font_size", 13)
	_detail_text.add_theme_color_override("default_color", UITheme.TEXT)
	rbox.add_child(_detail_text)
	rbox.add_child(UITheme.make_label("ที่หาวัตถุดิบ", 13, UITheme.GOLD_BRIGHT))
	_detail_sources = VBoxContainer.new()
	_detail_sources.add_theme_constant_override("separation", 2)
	rbox.add_child(_detail_sources)
	_npc_hint = UITheme.make_label("", 12, UITheme.TEXT_DIM)
	_npc_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rbox.add_child(_npc_hint)

	Events.inventory_changed.connect(refresh)
	Events.zeny_changed.connect(func(_z): refresh())


# =========================================================
# ข้อมูล
# =========================================================
## ช่างเหล็กเมืองบท N เห็นสูตรบท 1..N (อยู่นอกเมือง/ห้อง GM = เห็นทั้งหมด)
func _chapter_limit() -> int:
	var ch := MapAtlas.chapter_of(PlayerState.current_map_id)
	return ch if ch > 0 else 99


func _visible_recipes() -> Array:
	var limit := _chapter_limit()
	var out: Array = []
	for r: RecipeData in GameData.all_recipes():
		if r.chapter > limit:
			continue
		if r.required_flag != &"" and not PlayerState.has_flag(r.required_flag):
			continue
		if r.result() == null:
			continue
		out.append(r)
	return out


func refresh() -> void:
	if _list == null:
		return
	if not is_visible_in_tree():
		return   # ★ รอบ 131 ★ ซ่อนอยู่ไม่ต้องสร้างใหม่
	var recipes := _visible_recipes()
	var ids: Array = []
	for r: RecipeData in recipes:
		ids.append(r.id)
	if _selected == &"" or not ids.has(_selected):
		_selected = recipes[0].id if not recipes.is_empty() else &""
	_rebuild_list(recipes)
	_rebuild_ring()
	_rebuild_detail()


func _rebuild_list(recipes: Array) -> void:
	GameWindow.clear_container(_list)
	var inv := PlayerState.inventory
	var last_ch := -1
	for r: RecipeData in recipes:
		if r.chapter != last_ch:
			last_ch = r.chapter
			var h := UITheme.make_label(String(CHAPTER_NAMES.get(r.chapter, "บท %d" % r.chapter)), 12, UITheme.TEXT_DIM)
			h.add_theme_constant_override("line_spacing", 0)
			_list.add_child(h)
		var lv_ok: bool = PlayerState.stats.level >= r.result().required_level   # ★ รอบ 137 ★
		var ready: bool = lv_ok and r.has_materials(inv) and PlayerState.zeny >= r.zeny
		var b := Button.new()
		b.text = r.display_name() if r.category == &"general" else "%s  · %s" % [r.display_name(), r.category_name()]   # ★ รอบ 134 ★
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 14)
		b.icon = UITheme.mipped(r.result().icon) if r.result().icon != null else null
		b.add_theme_constant_override("icon_max_width", 26)
		b.add_theme_constant_override("h_separation", 8)
		b.custom_minimum_size = Vector2(LIST_W - 28, 38)
		var on: bool = r.id == _selected
		b.add_theme_stylebox_override("normal", _round_style(Color("#243c34") if on else UITheme.PANEL_LIGHT, UITheme.ACCENT if on else UITheme.BORDER, 1, 4))
		b.add_theme_stylebox_override("hover", _round_style(UITheme.PANEL_HOVER, UITheme.ACCENT, 1, 4))
		b.add_theme_stylebox_override("pressed", _round_style(UITheme.PANEL_PRESSED, UITheme.GOLD_BRIGHT, 1, 4))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.add_theme_color_override("font_color", UITheme.GOOD if ready else (UITheme.TEXT if lv_ok else UITheme.TEXT_DIM))
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.tooltip_text = "วัตถุดิบครบ กดคราฟต์ได้เลย" if ready else ("ยังขาดวัตถุดิบ/ค่าแรง" if lv_ok else "ต้อง Lv %d" % r.result().required_level)
		var rid: StringName = r.id
		b.pressed.connect(func():
			_selected = rid
			refresh())
		_list.add_child(b)


func _rebuild_ring() -> void:
	for s in _slots:
		(s.btn as Node).queue_free()
		(s.name as Node).queue_free()
	_slots.clear()
	var r: RecipeData = GameData.get_recipe(_selected) if _selected != &"" else null
	var center := RING_SIZE * 0.5 + Vector2(0, 4)   # ★ รอบ 138 ★ เลื่อนลงให้ไอคอนบนสุดไม่ถูกขอบตัด
	_center_btn.position = center - Vector2(CENTER_D, CENTER_D) * 0.5
	_center_name.size = Vector2(300, 28)
	_center_name.position = center + Vector2(-150, CENTER_D * 0.5 + 4)
	_center_sub.size = Vector2(300, 18)
	_center_sub.position = center + Vector2(-150, CENTER_D * 0.5 + 30)
	if r == null:
		_center_icon.texture = null
		_center_name.text = "ยังไม่มีสูตร"
		_center_sub.text = ""
		_ring_draw.positions = []
		_ring_draw.center = center
		_ring_draw.queue_redraw()
		_zeny_label.text = ""
		_craft_btn.text = "คราฟต์"
		_craft_btn.disabled = true
		return
	var d := r.result()
	_center_icon.texture = UITheme.mipped(d.icon) if d.icon != null else null
	_center_name.text = d.display_name
	_center_sub.text = "โบนัสสุ่ม %d–%d%%" % [int(r.bonus_min), int(r.bonus_max)] if d.is_equipment() else ("ได้ %d ชิ้น" % r.result_count)
	var inv := PlayerState.inventory
	var mats := r.material_list()
	var n := mats.size()
	var positions: Array = []
	for i in range(n):
		var a := -PI * 0.5 + TAU * float(i) / float(maxi(1, n))
		var p := center + Vector2(cos(a), sin(a)) * RING_R
		positions.append(p)
		var iid: StringName = mats[i][0]
		var need: int = mats[i][1]
		var have := inv.count_of(iid)
		var ok := have >= need
		var it := GameData.get_item(iid)
		var btn := Button.new()
		btn.flat = true
		btn.custom_minimum_size = Vector2(SLOT, SLOT)
		btn.size = Vector2(SLOT, SLOT)
		btn.position = p - Vector2(SLOT, SLOT) * 0.5
		var edge := UITheme.GOOD if ok else UITheme.BAD
		btn.add_theme_stylebox_override("normal", _round_style(UITheme.PANEL_LIGHT, edge, 2, 8))
		btn.add_theme_stylebox_override("hover", _round_style(UITheme.PANEL_HOVER, UITheme.GOLD_BRIGHT, 2, 8))
		btn.add_theme_stylebox_override("pressed", _round_style(UITheme.PANEL_PRESSED, UITheme.GOLD_BRIGHT, 2, 8))
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.tooltip_text = "%s  %d/%d\n%s" % [it.display_name if it != null else String(iid), have, need, DropDirectory.describe(iid)]
		var pair := UITheme.make_slot_icon(btn, 8.0)
		(pair[0] as TextureRect).texture = UITheme.mipped(it.icon) if it != null and it.icon != null else null
		var cnt := pair[1] as Label
		cnt.text = "%d/%d" % [have, need]
		cnt.add_theme_font_size_override("font_size", 12)
		cnt.add_theme_color_override("font_color", edge)
		var mat_id := iid
		btn.pressed.connect(func():
			var data := GameData.get_item(mat_id)
			if data != null:
				UI.show_item_data(data, btn, "มี %d / ต้องใช้ %d\n%s" % [PlayerState.inventory.count_of(mat_id), need, DropDirectory.describe(mat_id)]))
		_ring.add_child(btn)
		var nm := UITheme.make_label(it.display_name if it != null else String(iid), 12, UITheme.TEXT if ok else UITheme.BAD)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.size = Vector2(140, 18)
		nm.position = p + Vector2(-70, SLOT * 0.5 + 2)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ring.add_child(nm)
		_slots.append({"btn": btn, "art": pair[0], "count": cnt, "name": nm})
	_ring_draw.center = center
	_ring_draw.positions = positions
	_ring_draw.queue_redraw()

	# ---------- ค่าแรง + ปุ่ม ----------
	var enough_zeny := PlayerState.zeny >= r.zeny
	_zeny_label.text = "ค่าแรงช่าง %s z  ·  มี %s z" % [HUD._comma(r.zeny), HUD._comma(PlayerState.zeny)]
	_zeny_label.add_theme_color_override("font_color", UITheme.TEXT if enough_zeny else UITheme.BAD)
	var missing := r.first_missing(inv)
	if PlayerState.stats.level < d.required_level:   # ★ รอบ 137 ★ ต้องเลเวลถึงของชิ้นนั้น
		_craft_btn.text = "ต้อง Lv %d (คุณ Lv %d)" % [d.required_level, PlayerState.stats.level]
		_craft_btn.disabled = true
	elif not missing.is_empty():
		var mi := GameData.get_item(missing[0])
		_craft_btn.text = "ขาด%s อีก %d" % [mi.display_name if mi != null else String(missing[0]), int(missing[1])]
		_craft_btn.disabled = true
	elif not enough_zeny:
		_craft_btn.text = "ค่าแรงไม่พอ (ขาด %s z)" % HUD._comma(r.zeny - PlayerState.zeny)
		_craft_btn.disabled = true
	else:
		_craft_btn.text = "คราฟต์ %s" % d.display_name
		_craft_btn.disabled = false


func _rebuild_detail() -> void:
	GameWindow.clear_container(_detail_sources)
	var r: RecipeData = GameData.get_recipe(_selected) if _selected != &"" else null
	if r == null:
		_detail_title.text = ""
		_detail_text.text = ""
		_npc_hint.text = "ช่างเหล็กเมืองนี้ยังไม่มีสูตร"
		return
	var d := r.result()
	_detail_title.text = "%s  [%s]" % [d.display_name, r.category_name()]   # ★ รอบ 134 ★
	# ★ รอบ 139 ★ บรรยายจากตัวอย่างของคราฟต์ (มีช่องการ์ดเท่าของดรอป) แทนแม่แบบ — เดิมขึ้น "ช่องการ์ด: ไม่มี" ทั้งที่ของคราฟต์ได้ช่องจริง
	var preview := ItemInstance.create(d.id, 1, 0, d.card_slots)
	var body := ItemInfoPopup.describe(d, preview, "", true)
	if d.card_slots > 0:
		body = body.replace("ช่องการ์ด :[/color] 0/%d" % d.card_slots, "ช่องการ์ด :[/color] %d ช่อง (ได้เหมือนของดรอป)" % d.card_slots)
	if d.is_equipment():
		body += "\n\n[color=#e0cc93]โบนัสสุ่มตอนคราฟต์[/color]\nค่าพลังทุกช่องของชิ้นนี้ +%d–%d%% (ของดรอปได้ %d–%d%%) · คราฟต์ซ้ำได้ไม่จำกัด สุ่มใหม่ทุกครั้ง" % [int(r.bonus_min), int(r.bonus_max), int(ItemInstance.DROP_BONUS_MIN), int(ItemInstance.DROP_BONUS_MAX)]
	if r.note != "":
		body += "\n[color=#81958a]%s[/color]" % r.note
	_detail_text.text = body
	for pair in r.material_list():
		var it := GameData.get_item(pair[0])
		var row := UITheme.make_label("%s — %s" % [it.display_name if it != null else String(pair[0]), DropDirectory.describe(pair[0], 2)], 11, UITheme.TEXT_DIM)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.custom_minimum_size.x = DETAIL_W - 20
		_detail_sources.add_child(row)
	var limit := _chapter_limit()
	_npc_hint.text = "ช่างเหล็กเมืองนี้รับสูตรถึงบท %d" % limit if limit < 99 else ""


# =========================================================
# การกระทำ
# =========================================================
func _on_center_pressed() -> void:
	var r: RecipeData = GameData.get_recipe(_selected) if _selected != &"" else null
	if r != null and r.result() != null:
		UI.show_item_data(r.result(), _center_btn)


func _on_craft_pressed() -> void:
	var r: RecipeData = GameData.get_recipe(_selected) if _selected != &"" else null
	if r == null:
		return
	var res: Dictionary = PlayerState.craft(r)
	if not bool(res.get("ok", false)):
		Events.say(String(res.get("reason", "คราฟต์ไม่ได้")))
		refresh()
		return
	var inst: ItemInstance = res.get("inst", null)
	if Game.sfx != null:
		Game.sfx.play_first(["craft_success", "refine_success"])
	if inst != null:
		Events.say("[คราฟต์] ได้ %s" % inst.display_name())
		UI.show_item(inst, _center_btn, "คราฟต์สำเร็จ!")
	refresh()


# =========================================================
# ตัวช่วยวาด
# =========================================================
static func _round_style(bg: Color, border: Color, width: int, radius: int = 62) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	return s


## วงกลม + เส้นโยงจากกลางไปยังวัตถุดิบ (วาดใต้ปุ่ม)
class RingDraw extends Control:
	var center := Vector2.ZERO
	var positions: Array = []

	func _draw() -> void:
		if positions.is_empty():
			return
		draw_arc(center, CraftWindow.RING_R, 0.0, TAU, 96, Color(UITheme.BORDER, 0.9), 1.5, true)
		draw_arc(center, CraftWindow.RING_R - 56.0, 0.0, TAU, 96, Color(UITheme.ACCENT, 0.35), 1.0, true)
		for p in positions:
			draw_line(center, p, Color(UITheme.BORDER, 0.8), 1.0, true)
		draw_circle(center, CraftWindow.CENTER_D * 0.5 + 10.0, Color(UITheme.ACCENT, 0.08))
