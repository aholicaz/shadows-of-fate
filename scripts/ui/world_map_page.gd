## WorldMapPage — หน้า "แผนที่" ในหน้าต่างรวม (รอบ 102)
##
## เดิมแท็บนี้คือมินิแมพขยายใหญ่ (เห็นแค่แมพที่ยืนอยู่) → เปลี่ยนเป็น **แผนที่โลก**
##
##   ┌ บทที่ 1 · บทที่ 2 · บทที่ 3 ─────────────────────────────────── เก็บครบ 12/16 แมพ ┐
##   │  ┌ เมืองพรอนเทรา ┐──┌ ทุ่งวิหาร ┐──┌ ป่าแอสการ์ด 2 ┐──…      │ ชื่อแมพที่เลือก      │
##   │  │ เมือง         │  │ Lv.1-6    │  │ Lv.6-14       │        │ Lv. · เคลียร์ 3/4    │
##   │  └───────────────┘  └───────────┘  └───────────────┘        │ ─────────────────── │
##   │  (เส้นเชื่อม = เดินถึงกันได้)                                  │ 🗡 โพริง Lv.1        │
##   └──────────────────────────────────────────────────────────────┤   ของดรอป: ...      │
##                                                                  └─────────────────────┘
##
## · แบ่งหน้าเป็น "บท" — เพิ่มบท 4-9 ทีหลังแค่เติมข้อมูลใน MapAtlas แล้วปุ่มบทจะโผล่เอง
## · แมพที่ยังไม่เคยไป = ชื่อเป็น "???" และมอนถูกซ่อน (ไม่สปอยล์)
## · คลิกแมพ = ดูรายชื่อมอนในแมพนั้น เลเวล และของที่ดรอป
class_name WorldMapPage
extends GameWindow

## ขนาดขั้นต่ำของการ์ดแมพ — ขนาดจริงคำนวณจากพื้นที่ที่มีใน _fit_grid()
const CARD_SIZE := Vector2(190, 88)
const CARD_MAX := Vector2(420, 290)
const CARD_GAP := Vector2(24, 18)
## กี่แมพต่อแถวก่อนขึ้นบรรทัดใหม่ (บทหนึ่งมี 5-6 แมพ → ได้ 2 แถวสวย ๆ)
const PER_ROW := 3
## เผื่อที่ให้แถบเลื่อนแนวตั้ง
const SCROLLBAR_ROOM := 16.0

var _chapter := 1
var _selected: StringName = &""
var _chapter_row: HBoxContainer
var _grid: GridContainer
var _progress: Label
var _detail_title: Label
var _detail_sub: Label
var _detail_list: VBoxContainer
var _cards: Dictionary = {}          # map_id -> PanelContainer
var _grid_scroll: ScrollContainer
var _cell := Vector2.ZERO


func _ready() -> void:
	window_title = "แผนที่โลก"
	super._ready()
	Events.map_changed.connect(func(_id): refresh())


func _build_content() -> void:
	# ---------- แถวปุ่มบท ----------
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	content.add_child(head)
	_chapter_row = HBoxContainer.new()
	_chapter_row.add_theme_constant_override("separation", 8)
	head.add_child(_chapter_row)
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(fill)
	_progress = UITheme.make_label("", 14, UITheme.ACCENT)
	head.add_child(_progress)

	content.add_child(UITheme.separator())

	# ---------- ตัวแผนที่ + แผงรายละเอียด ----------
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(cols)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cols.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = PER_ROW
	_grid.add_theme_constant_override("h_separation", int(CARD_GAP.x))
	_grid.add_theme_constant_override("v_separation", int(CARD_GAP.y))
	# ★ รอบ 102 (รอบสาม) ★ การ์ดแมพยืดเต็มพื้นที่เหมือนหน้าสเตตัส/กระเป๋า
	# ไม่ใช้ CenterContainer แล้ว เพราะตอนนี้กริดกินพื้นที่เต็มอยู่แล้ว (ดู _fit_grid)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)
	_grid_scroll = scroll
	scroll.resized.connect(_fit_grid)

	cols.add_child(_build_detail())

	_build_chapter_buttons()


func _build_detail() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.inner_style(UITheme.PANEL, 4, 12.0))
	panel.custom_minimum_size.x = 300
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.clip_contents = true
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)

	_detail_title = UITheme.make_label("เลือกแมพเพื่อดูข้อมูล", 18, UITheme.GOLD_BRIGHT)
	_detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_detail_title)
	_detail_sub = UITheme.make_label("", 13, UITheme.TEXT_DIM)
	_detail_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_detail_sub)
	var rule := PetrolWidgets.ornament(220.0, UITheme.ACCENT, 3.0)
	rule.custom_minimum_size = Vector2(220, 10)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(rule)

	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(sc)
	_detail_list = VBoxContainer.new()
	_detail_list.add_theme_constant_override("separation", 8)
	_detail_list.custom_minimum_size.x = 258
	_detail_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_detail_list)
	return panel


func _build_chapter_buttons() -> void:
	GameWindow.clear_container(_chapter_row)
	for no in MapAtlas.chapters():
		var c := int(no)
		var b := UITheme.make_button(MapAtlas.chapter_name(c), 0)
		b.pressed.connect(func():
			_chapter = c
			_selected = &""
			refresh())
		_chapter_row.add_child(b)


# =========================================================
func on_shell_shown(_tab_id: String) -> void:
	# เปิดหน้ามาให้เด้งไปบทของแมพที่ยืนอยู่เลย
	var here := MapAtlas.chapter_of(PlayerState.current_map_id)
	if here > 0:
		_chapter = here
		_selected = PlayerState.current_map_id
	refresh()


func refresh() -> void:
	if _grid == null:
		return
	var chaps: Array = MapAtlas.chapters()
	if not chaps.has(_chapter) and not chaps.is_empty():
		_chapter = int(chaps[0])

	# ปุ่มบทที่เลือกอยู่ = ตัวหนังสือทอง
	for i in range(_chapter_row.get_child_count()):
		var b := _chapter_row.get_child(i) as Button
		if b == null:
			continue
		var on: bool = i < chaps.size() and int(chaps[i]) == _chapter
		b.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT if on else UITheme.TEXT_DIM)

	# ---------- การ์ดแมพ ----------
	GameWindow.clear_container(_grid)
	_cards.clear()
	var maps: Array = MapAtlas.maps_of_chapter(_chapter)
	for mid in maps:
		var card := _make_card(StringName(mid))
		_grid.add_child(card)
		_cards[StringName(mid)] = card

	# ---------- ความคืบหน้าทั้งโลก ----------
	var done := 0
	var total := 0
	for no in chaps:
		for mid in MapAtlas.maps_of_chapter(int(no)):
			if MapAtlas.monsters_of(StringName(mid)).is_empty():
				continue
			total += 1
			if MapAtlas.is_cleared(StringName(mid)):
				done += 1
	_progress.text = "ล่ามอนครบแล้ว %d / %d แมพ" % [done, total]

	if _selected == &"" and not maps.is_empty():
		_selected = StringName(maps[0])
	# ★ refresh() สร้างการ์ดใหม่ทุกครั้ง → ต้องคิดขนาดใหม่แล้วใส่ซ้ำ
	_cell = Vector2.ZERO
	_fit_grid()
	_refresh_detail()


## ★★ รอบ 102 (รอบสาม) — การ์ดแมพยืดเต็มพื้นที่ ★★
## กว้าง = แบ่งความกว้างที่มีตามจำนวนคอลัมน์ · สูง = แบ่งความสูงตามจำนวนแถวที่ใช้จริง
## (บทที่มี 6 แมพได้ 2 แถว · บทที่มี 5 แมพก็ 2 แถวเหมือนกัน การ์ดจะสูงเท่ากัน)
func _fit_grid() -> void:
	if _grid == null or _grid_scroll == null:
		return
	var n := _grid.get_child_count()
	if n <= 0:
		return
	var rows: int = int(ceil(float(n) / float(PER_ROW)))
	var avail := _grid_scroll.size - Vector2(SCROLLBAR_ROOM, 0.0)
	if avail.x <= 0.0 or avail.y <= 0.0:
		return
	var w: float = floorf((avail.x - float(PER_ROW - 1) * CARD_GAP.x) / float(PER_ROW))
	var h: float = floorf((avail.y - float(rows - 1) * CARD_GAP.y) / float(rows))
	var cell := Vector2(
		clampf(w, CARD_SIZE.x, CARD_MAX.x),
		clampf(h, CARD_SIZE.y, CARD_MAX.y))
	if _cell.distance_to(cell) < 0.5:
		return
	_cell = cell
	for c in _grid.get_children():
		var card := c as Control
		if card != null:
			card.custom_minimum_size = cell


func _make_card(mid: StringName) -> Control:
	var here: bool = mid == PlayerState.current_map_id
	var seen: bool = MapAtlas.is_visited(mid) or here
	var cleared: bool = MapAtlas.is_cleared(mid)
	var kind := MapAtlas.kind_of(mid)

	var edge: Color = UITheme.ACCENT if here else (UITheme.BORDER if seen else UITheme.BORDER_SOFT)
	var bg: Color = UITheme.PANEL_LIGHT if seen else Color(UITheme.PANEL, 0.6)

	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = CARD_SIZE
	btn.add_theme_stylebox_override("normal", UITheme.panel_style(bg, edge, 5, 2 if here else 1, 6.0))
	btn.add_theme_stylebox_override("hover", UITheme.panel_style(UITheme.PANEL_HOVER, UITheme.ACCENT, 5, 2, 6.0))
	btn.add_theme_stylebox_override("pressed", UITheme.panel_style(UITheme.PANEL_PRESSED, UITheme.ACCENT, 5, 2, 6.0))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(func():
		_selected = mid
		_refresh_detail())

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	# ★ การ์ดสูงขึ้นแล้ว ★ จัดข้อความกึ่งกลางแนวตั้ง ไม่งั้นกองอยู่ขอบบนแล้วดูโล่ง
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 8
	box.offset_right = -8
	box.offset_top = 6
	box.offset_bottom = -6
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(box)

	var title := UITheme.make_label(
		Game.map_display_name(mid) if seen else "???", 17,
		UITheme.GOLD_BRIGHT if here else (UITheme.TEXT if seen else UITheme.TEXT_DIM))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.clip_text = true
	box.add_child(title)

	var lv := MapAtlas.level_range(mid)
	var sub := ""
	if kind == MapAtlas.KIND_TOWN:
		sub = "เมือง"
	elif not seen:
		sub = "ยังไม่เคยไป"
	elif int(lv[0]) > 0:
		sub = "Lv.%d-%d" % [int(lv[0]), int(lv[1])]
	if kind == MapAtlas.KIND_BOSS and seen:
		sub += "  ★ บอส"
	var sub_l := UITheme.make_label(sub, 13, UITheme.TEXT_DIM)
	sub_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub_l)

	var foot := ""
	var foot_color := UITheme.TEXT_DIM
	if here:
		foot = "● อยู่ที่นี่"
		foot_color = UITheme.GOLD_BRIGHT
	elif seen and not MapAtlas.monsters_of(mid).is_empty():
		var p := MapAtlas.clear_progress(mid)
		foot = "ล่าครบแล้ว ✓" if cleared else "ล่าแล้ว %d/%d ชนิด" % [int(p[0]), int(p[1])]
		foot_color = UITheme.GOOD if cleared else UITheme.TEXT_DIM
	var foot_l := UITheme.make_label(foot, 12, foot_color)
	foot_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(foot_l)
	return btn


func _refresh_detail() -> void:
	if _detail_list == null:
		return
	GameWindow.clear_container(_detail_list)
	var mid := _selected
	if mid == &"" or not MapAtlas.has(mid):
		_detail_title.text = "เลือกแมพเพื่อดูข้อมูล"
		_detail_sub.text = ""
		return
	var seen: bool = MapAtlas.is_visited(mid) or mid == PlayerState.current_map_id
	_detail_title.text = Game.map_display_name(mid) if seen else "??? (ยังไม่เคยไป)"

	var bits: Array = []
	var lv := MapAtlas.level_range(mid)
	if int(lv[0]) > 0:
		bits.append("มอน Lv.%d-%d" % [int(lv[0]), int(lv[1])])
	var mons: Array = MapAtlas.monsters_of(mid)
	if not mons.is_empty():
		var p := MapAtlas.clear_progress(mid)
		bits.append("ล่าแล้ว %d/%d ชนิด" % [int(p[0]), int(p[1])])
	elif MapAtlas.kind_of(mid) == MapAtlas.KIND_TOWN:
		bits.append("เมือง — ไม่มีมอนสเตอร์")
	_detail_sub.text = "  ·  ".join(bits)

	if not seen:
		_detail_list.add_child(UITheme.make_label(
			"เดินไปให้ถึงก่อน แล้วข้อมูลมอนของแมพนี้จะโผล่มาเอง", 13, UITheme.TEXT_DIM))
		return
	if mons.is_empty():
		_detail_list.add_child(UITheme.make_label(
			"แมพนี้ไม่มีมอนสเตอร์", 13, UITheme.TEXT_DIM))
	for m in mons:
		_detail_list.add_child(_monster_block(StringName(m)))

	# ---------- เดินต่อไปไหนได้ ----------
	var links: Array = MapAtlas.links_of(mid)
	if not links.is_empty():
		_detail_list.add_child(UITheme.separator())
		var names: Array = []
		for l in links:
			var lid := StringName(l)
			names.append(Game.map_display_name(lid) if MapAtlas.is_visited(lid) else "???")
		var go := UITheme.make_label("เดินต่อไปได้: " + " · ".join(names), 12, UITheme.TEXT_DIM)
		go.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail_list.add_child(go)


## หนึ่งบล็อกมอน: ชื่อ + เลเวล + ธาตุ/ขนาด + ของดรอป
func _monster_block(mid: StringName) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.slot_style(false))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	var d: MonsterData = GameData.get_monster(mid)
	var killed: int = PlayerState.kill_count(mid)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	box.add_child(head)
	var nm: String = d.display_name if d != null else String(mid)
	if d != null and d.is_boss:
		nm = "★ " + nm
	var name_l := UITheme.make_label(nm, 14, UITheme.TEXT if killed > 0 else UITheme.TEXT_DIM)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_l)
	head.add_child(UITheme.make_label(
		"Lv.%d" % (d.level if d != null else 0), 13, UITheme.ACCENT))

	if killed <= 0:
		box.add_child(UITheme.make_label("ยังไม่เคยล้ม — ล้มแล้วจะเห็นของดรอป", 11, UITheme.TEXT_DIM))
		return panel

	box.add_child(UITheme.make_label("ล้มไปแล้ว %d ตัว" % killed, 11, UITheme.GOOD))
	if d == null or d.drops.is_empty():
		return panel
	var names: Array = []
	for e in d.drops:
		var entry: DropEntry = e
		if entry == null or entry.item_id == &"":
			continue
		var it: ItemData = GameData.get_item(entry.item_id)
		var label: String = it.display_name if it != null else String(entry.item_id)
		names.append("%s %.1f%%" % [label, entry.chance])
	if names.is_empty():
		return panel
	var drop_l := UITheme.make_label("ของดรอป: " + " · ".join(names), 11, Color("#ffe9a0"))
	drop_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(drop_l)
	return panel


func shell_hints() -> Array:
	return [["M", "เปิด/ปิดมินิแมพมุมจอ"], ["Esc", "ปิด"]]
