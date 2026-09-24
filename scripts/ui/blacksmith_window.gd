## BlacksmithWindow — ★ รอบ 163 ★ หน้าต่าง «โรงตีเหล็ก» รวม ตีบวก · เจาะรู · รูที่ 3 · คราฟต์ ไว้ที่เดียว
##
## หน้าตาชุดเดียวกับร้านค้าแบบ A (รอบ 160):
##   บน   = แท็บ 4 ปุ่ม + ซีนี
##   ตีบวก/เจาะรู:
##     ซ้าย = กรองรายการ (ทั้งหมด/สวมอยู่/ในกระเป๋า) + «วัสดุที่ระบบใช้» (ไอคอน · มีกี่ชิ้น · ใช้ตอนไหน · หาได้ที่ไหน)
##     กลาง = กริดอุปกรณ์ (ป้าย +N · สวมอยู่ · โอกาสสำเร็จ / จำนวนรูที่จะได้)
##     ขวา  = รายละเอียด: ค่าพลังก่อน→หลัง · หลอดโอกาสสำเร็จ · «วัสดุที่ต้องใช้» (ไอคอน ใช้/มี แดง-เขียว) · คำเตือน · ปุ่มทอง
##   รูที่ 3 = แผงเดิม ThirdSocketPanel (ย้ายมาอยู่ในแท็บ)
##   คราฟต์ = หน้าต่าง CraftWindow เดิม (วงคราฟต์ที่ผู้ใช้เลือก รอบ 131) ฝังเข้ามาเป็นแท็บ
## ระบบข้างหลังเป็นของเดิม: RefineSystem · SocketSystem · ThirdSocket · CraftWindow
## หน้าต่างเก่า RefineWindow / SocketWindow ยังอยู่ (เทสต์เก่าใช้) แต่ NPC เปิดหน้านี้แทน
class_name BlacksmithWindow
extends GameWindow

const WIN_MAX := Vector2(1120, 640)
const LEFT_W := 200.0
const DETAIL_W := 340.0
const CELL := Vector2(92, 104)
const GRID_COLS := 5
const TABS := [["refine", "ตีบวก"], ["socket", "เจาะรู"], ["third", "รูที่ 3 · หลอมอาวุธ"], ["craft", "คราฟต์"]]
const FILTERS := [["all", "ทั้งหมด"], ["worn", "สวมอยู่"], ["bag", "ในกระเป๋า"]]
## วัสดุที่ระบบตีเหล็กใช้ — [id, ใช้กับอะไร, หาได้ที่ไหน]
const MATERIALS := [
	[&"phracon", "ตีบวก +0 → +5 (ครั้งละ 1) · เจาะรูของ Lv 1-30 (10 ก้อน)", "ร้านค้าทุกเมือง · ใบประกาศล่า · บอส"],
	[&"emveretarcon", "ตีบวก +5 → +10 (ครั้งละ 1) · เจาะรูของ Lv 31+ (10 ก้อน)", "ร้านค้า · ใบประกาศล่าบท 4+ · บอส"],
]
## ★ ลุ้นตีบวก (เหมือนหน้าตีบวกเดิม รอบ 59) ★
const ROLL_TIME := 1.3
const RESULT_SHOW := 1.3
const SFX_ROLL := "refine_roll"
const SFX_SUCCESS := "refine_success"
const SFX_FAIL := "refine_fail"

signal refine_finished(out: Dictionary)

var tab := "refine"
var last_result: Dictionary = {}
var _filter := "all"
var _selected := ""            # "inv:<i>" / "eq:<slot>"
var _rolling := false

var _tab_buttons: Dictionary = {}
var _zeny_label: Label
var _page_items: HBoxContainer     # หน้า ตีบวก/เจาะรู
var _page_third: Control
var _page_craft: Control
var _craft: CraftWindow
var _third: Control
var _filter_buttons: Dictionary = {}
var _mat_box: VBoxContainer
var _grid_title: Label
var _list: VBoxContainer
var _empty_hint: Label
# แผงขวา
var _d_body: VBoxContainer
var _d_empty: Label
var _d_art: TextureRect
var _d_badge: Label
var _d_name: Label
var _d_sub: Label
var _d_stats: VBoxContainer
var _d_rate_bar: ProgressBar
var _d_rate: Label
var _d_mats: VBoxContainer
var _d_warn: Label
var _d_roll: ProgressBar
var _d_action: Button
var _d_result: Label
var _big_result: Label
var _big_tween: Tween


func _init() -> void:
	window_title = "โรงตีเหล็ก"


func _ready() -> void:
	super._ready()
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_title("─◆  โรงตีเหล็ก  ◆─")
	Events.inventory_changed.connect(refresh)
	Events.equipment_changed.connect(refresh)
	Events.zeny_changed.connect(func(_z): refresh())
	get_viewport().size_changed.connect(_place)


## เปิดที่แท็บไหน: refine · socket · third · craft
func open_tab(id: String) -> void:
	tab = id
	_selected = ""
	if _d_result != null:
		_d_result.text = ""
	show_window()
	_show_page()


# =========================================================
# สร้างหน้าต่าง
# =========================================================
func _build_content() -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	content.add_child(top)
	for t in TABS:
		var id := String(t[0])
		var b := UITheme.make_button(String(t[1]))
		b.name = "Tab_" + id
		b.custom_minimum_size = Vector2(150 if id != "third" else 200, 44)
		b.add_theme_font_size_override("font_size", 17)
		b.pressed.connect(_on_tab.bind(id))
		top.add_child(b)
		_tab_buttons[id] = b
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var coin := PetrolWidgets.glyph("coin", 18.0, UITheme.GOLD_BRIGHT)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(coin)
	_zeny_label = UITheme.make_label("", 18, UITheme.TEXT)
	top.add_child(_zeny_label)

	var pages := Control.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages.custom_minimum_size.y = 470
	content.add_child(pages)

	_page_items = HBoxContainer.new()
	_page_items.add_theme_constant_override("separation", 12)
	_page_items.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages.add_child(_page_items)
	_page_items.add_child(_build_left())
	_page_items.add_child(_build_middle())
	_page_items.add_child(_build_right())

	# รูที่ 3 = แผงเดิม (third_socket_panel.gd) ใส่กรอบชุดเดียวกับแท็บอื่น
	_page_third = PanelContainer.new()
	_page_third.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_page_third.add_theme_stylebox_override("panel", UITheme.inner_style(Color("#091816b3"), 4, 12.0))
	pages.add_child(_page_third)
	var third_scroll := ScrollContainer.new()
	third_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_page_third.add_child(third_scroll)
	_third = preload("res://scripts/ui/third_socket_panel.gd").new()
	_third.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	third_scroll.add_child(_third)

	_page_craft = Control.new()
	_page_craft.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages.add_child(_page_craft)

	# คำ SUCCESS / FAIL ทับกลางหน้าต่าง
	_big_result = Label.new()
	_big_result.name = "BigResult"
	_big_result.set_anchors_preset(Control.PRESET_FULL_RECT)
	_big_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_big_result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_big_result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_big_result.add_theme_font_size_override("font_size", 56)
	_big_result.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_big_result.add_theme_constant_override("outline_size", 10)
	var dim := StyleBoxFlat.new()
	dim.bg_color = Color(0, 0, 0, 0.45)
	dim.set_corner_radius_all(6)
	_big_result.add_theme_stylebox_override("normal", dim)
	_big_result.visible = false
	_big_result.z_index = 50
	add_child(_big_result)


## ฝังหน้าต่างคราฟต์เดิมเข้ามาเป็นแท็บ (ui_manager เรียกตอนสร้าง)
func host_craft(w: CraftWindow) -> void:
	_craft = w
	if w.get_parent() != null:
		w.get_parent().remove_child(w)
	_page_craft.add_child(w)
	w.set_embedded(true, "")
	w.offset_left = 0
	w.offset_top = 0
	w.offset_right = 0
	w.offset_bottom = 0
	w.show()


func _build_left() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = LEFT_W
	col.add_theme_constant_override("separation", 4)
	for f in FILTERS:
		var id := String(f[0])
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 38)
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(_on_filter.bind(id))
		col.add_child(b)
		_filter_buttons[id] = b
	var gap := Control.new()
	gap.custom_minimum_size.y = 8
	col.add_child(gap)
	var mp := PanelContainer.new()
	mp.add_theme_stylebox_override("panel", UITheme.inner_style(Color("#091816cc"), 4, 8.0))
	mp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(mp)
	_mat_box = VBoxContainer.new()
	_mat_box.add_theme_constant_override("separation", 6)
	mp.add_child(_mat_box)
	return col


func _build_middle() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.inner_style(Color("#091816b3"), 4, 10.0))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_grid_title = UITheme.make_label("", 14, UITheme.TEXT_DIM)
	box.add_child(_grid_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	return panel


func _build_right() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = DETAIL_W
	panel.add_theme_stylebox_override("panel", UITheme.panel_style(Color("#091816d9"), UITheme.ACCENT, 4, 1, 12.0))
	var outer := VBoxContainer.new()
	panel.add_child(outer)
	_d_empty = UITheme.make_label("", 15, UITheme.TEXT_DIM)
	_d_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_empty.custom_minimum_size.x = DETAIL_W - 30.0
	outer.add_child(_d_empty)
	_d_body = VBoxContainer.new()
	_d_body.add_theme_constant_override("separation", 6)
	_d_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(_d_body)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	_d_body.add_child(top)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UITheme.panel_style(Color("#102725"), UITheme.BORDER, 4, 1, 6.0))
	top.add_child(frame)
	_d_art = TextureRect.new()
	_d_art.custom_minimum_size = Vector2(72, 72)
	_d_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_d_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_d_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	frame.add_child(_d_art)
	var tcol := VBoxContainer.new()
	tcol.add_theme_constant_override("separation", 2)
	tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tcol.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(tcol)
	_d_name = UITheme.make_label("", 19, UITheme.TEXT)
	_d_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_name.custom_minimum_size.x = DETAIL_W - 130.0
	tcol.add_child(_d_name)
	_d_badge = UITheme.make_label("", 22, UITheme.GOLD_BRIGHT)
	tcol.add_child(_d_badge)
	_d_sub = UITheme.make_label("", 13, UITheme.TEXT_DIM)
	tcol.add_child(_d_sub)

	var sp := PanelContainer.new()
	sp.add_theme_stylebox_override("panel", UITheme.panel_style(Color("#17343099"), Color(0, 0, 0, 0), 3, 0, 8.0))
	_d_body.add_child(sp)
	_d_stats = VBoxContainer.new()
	_d_stats.add_theme_constant_override("separation", 0)
	sp.add_child(_d_stats)

	var rate_row := HBoxContainer.new()
	rate_row.add_theme_constant_override("separation", 8)
	_d_body.add_child(rate_row)
	rate_row.add_child(UITheme.make_label("โอกาสสำเร็จ", 14, UITheme.TEXT_DIM))
	_d_rate_bar = UITheme.make_bar(UITheme.GOOD, 14.0)
	_d_rate_bar.max_value = 100.0
	_d_rate_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_d_rate_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rate_row.add_child(_d_rate_bar)
	_d_rate = UITheme.make_label("", 16, UITheme.TEXT)
	_d_rate.custom_minimum_size.x = 48
	_d_rate.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rate_row.add_child(_d_rate)

	_d_body.add_child(UITheme.make_label("วัสดุที่ต้องใช้", 14, UITheme.ACCENT))
	_d_mats = VBoxContainer.new()
	_d_mats.add_theme_constant_override("separation", 4)
	_d_body.add_child(_d_mats)
	_d_warn = UITheme.make_label("", 13, Color("#ffb36b"))
	_d_warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_warn.custom_minimum_size.x = DETAIL_W - 30.0
	_d_body.add_child(_d_warn)

	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_d_body.add_child(fill)
	_d_roll = UITheme.make_bar(Color("#ffb347"), 16.0)
	_d_roll.max_value = 100.0
	_d_roll.visible = false
	_d_body.add_child(_d_roll)
	_d_action = UITheme.make_gold_button("ตีบวก")
	_d_action.name = "ActionButton"
	_d_action.custom_minimum_size.y = 46
	_d_action.add_theme_font_size_override("font_size", 19)
	_d_action.pressed.connect(_do_action)
	_d_body.add_child(_d_action)
	_d_result = UITheme.make_label("", 14, UITheme.ACCENT)
	_d_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_result.custom_minimum_size.x = DETAIL_W - 30.0
	_d_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_d_body.add_child(_d_result)
	return panel


# =========================================================
# แท็บ / ตัวกรอง
# =========================================================
func _on_tab(id: String) -> void:
	if _rolling:
		return
	tab = id
	_selected = ""
	_d_result.text = ""
	_show_page()


func _show_page() -> void:
	if _page_items == null:
		return
	_page_items.visible = tab == "refine" or tab == "socket"
	_page_third.visible = tab == "third"
	_page_craft.visible = tab == "craft"
	for id in _tab_buttons.keys():
		_style_tab(_tab_buttons[id], id == tab)
	if tab == "third" and _third != null and _third.has_method("refresh"):
		_third.refresh()
	if tab == "craft" and _craft != null:
		_craft.show()
		_craft.refresh()
	refresh()


func _on_filter(id: String) -> void:
	_filter = id
	refresh()


func _style_tab(b: Button, on: bool) -> void:
	b.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT if on else UITheme.TEXT_DIM)
	b.add_theme_stylebox_override("normal", UITheme._btn_style(UITheme.PANEL_HOVER if on else Color(0.06, 0.15, 0.14, 0.75), UITheme.ACCENT if on else UITheme.BORDER_SOFT))


func _style_filter(b: Button, on: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(UITheme.ACCENT, 0.16) if on else Color(0, 0, 0, 0)
	s.border_color = UITheme.ACCENT
	s.border_width_left = 3 if on else 0
	s.content_margin_left = 12
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = Color(UITheme.ACCENT, 0.22) if on else Color(UITheme.PANEL_HOVER, 0.8)
	b.add_theme_stylebox_override("normal", s)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT if on else UITheme.TEXT_DIM)


# =========================================================
# ของที่เลือก
# =========================================================
func _inst_of(src: String) -> ItemInstance:
	if src.begins_with("inv:"):
		return PlayerState.inventory.get_slot(int(src.substr(4)))
	if src.begins_with("eq:"):
		return PlayerState.equipment.get_item(int(src.substr(3)))
	return null


func selected_instance() -> ItemInstance:
	return _inst_of(_selected)


func _eligible(inst: ItemInstance) -> bool:
	if inst == null:
		return false
	return RefineSystem.can_refine(inst) if tab == "refine" else SocketSystem.can_punch(inst)


## รายการ source ที่โชว์ในกริด (สวมอยู่ก่อน แล้วค่อยของในกระเป๋า)
func _sources() -> Array:
	var out: Array = []
	if _filter != "bag":
		for slot in PlayerState.equipment.slots.keys():
			if _eligible(PlayerState.equipment.get_item(slot)):
				out.append("eq:%d" % slot)
	if _filter != "worn":
		for i in range(PlayerState.inventory.size):
			if _eligible(PlayerState.inventory.get_slot(i)):
				out.append("inv:%d" % i)
	return out


func select_source(src: String) -> void:
	if _rolling:
		return
	_selected = src
	_d_result.text = ""
	refresh()


# =========================================================
# refresh
# =========================================================
func refresh() -> void:
	if _list == null or not visible:
		return
	_zeny_label.text = "%s z" % HUD._comma(PlayerState.zeny)
	if tab == "third" or tab == "craft":
		return
	for f in FILTERS:
		_style_filter(_filter_buttons[String(f[0])], String(f[0]) == _filter)
	_refresh_materials()
	var srcs := _sources()
	for f in FILTERS:
		var id := String(f[0])
		var n := 0
		for s in srcs:
			n += 1 if id == "all" or (id == "worn") == String(s).begins_with("eq:") else 0
		(_filter_buttons[id] as Button).text = "%s   (%d)" % [String(f[1]), n] if _filter == "all" or id == _filter else String(f[1])
	_grid_title.text = "อุปกรณ์ที่ตีบวกได้ — คลิกเพื่อเลือก" if tab == "refine" else "ของสวมใส่ที่ยังไม่มีรู — คลิกเพื่อเลือก"
	GameWindow.clear_container(_list)
	if srcs.is_empty():
		var e := UITheme.make_label("ไม่มีอุปกรณ์ที่ตีบวกได้" if tab == "refine" else "ไม่มีของที่เจาะรูได้\n(ต้องเป็นของสวมใส่ที่ยังไม่มีรู)", 15, UITheme.TEXT_DIM)
		_list.add_child(e)
	else:
		var grid := GridContainer.new()
		grid.columns = GRID_COLS
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		_list.add_child(grid)
		for s in srcs:
			grid.add_child(_make_cell(String(s)))
	if not (_selected in srcs):
		_selected = String(srcs[0]) if not srcs.is_empty() else ""
	_refresh_detail()


func _refresh_materials() -> void:
	GameWindow.clear_container(_mat_box)
	_mat_box.add_child(UITheme.make_label("วัสดุที่ระบบใช้", 15, UITheme.ACCENT))
	for m in MATERIALS:
		var id: StringName = m[0]
		var it := GameData.get_item(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_mat_box.add_child(row)
		row.add_child(_icon(it.icon if it != null else null, 34))
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		col.add_child(UITheme.make_label(GameData.item_name(id), 14, UITheme.TEXT))
		var have := PlayerState.inventory.count_of(id)
		col.add_child(UITheme.make_label("มี %s ก้อน" % HUD._comma(have), 13, UITheme.GOOD if have > 0 else UITheme.BAD))
		var use := UITheme.make_label(String(m[1]), 11, UITheme.TEXT_DIM)
		use.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		use.custom_minimum_size.x = LEFT_W - 20.0
		_mat_box.add_child(use)
		var src := UITheme.make_label("หาได้: " + String(m[2]), 11, Color(UITheme.TEXT_DIM, 0.8))
		src.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		src.custom_minimum_size.x = LEFT_W - 20.0
		_mat_box.add_child(src)


func _icon(tex: Texture2D, s: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.custom_minimum_size = Vector2(s, s)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t


func _make_cell(src: String) -> Button:
	var inst := _inst_of(src)
	var d := inst.data()
	var selected := src == _selected
	var b := Button.new()
	b.name = "Cell_" + src.replace(":", "_")
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = CELL
	b.tooltip_text = inst.display_name()
	var st := UITheme.slot_style(selected)
	if selected:
		st.shadow_color = Color(UITheme.GOLD_BRIGHT, 0.35)
		st.shadow_size = 6
		st.border_color = UITheme.GOLD_BRIGHT
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", UITheme.slot_style(true))
	b.add_theme_stylebox_override("pressed", st)
	b.pressed.connect(select_source.bind(src))
	var art := _icon(d.icon if d != null else null, 58)
	art.position = Vector2((CELL.x - 58.0) * 0.5, 8)
	art.size = Vector2(58, 58)
	b.add_child(art)
	var bottom := UITheme.make_label("", 13, Color("#ffe9a0"))
	bottom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.position = Vector2(0, 74)
	bottom.size = Vector2(CELL.x, 22)
	if tab == "refine":
		bottom.text = "%.0f%%" % RefineSystem.success_rate(inst)
		var rate := RefineSystem.success_rate(inst)
		bottom.add_theme_color_override("font_color", UITheme.GOOD if rate >= 70.0 else (UITheme.GOLD_BRIGHT if rate >= 40.0 else UITheme.BAD))
	else:
		bottom.text = "→ %d รู" % SocketSystem.slots_gain(d)
	b.add_child(bottom)
	if src.begins_with("eq:"):
		b.add_child(_corner_chip("สวมอยู่", UITheme.GOLD_BRIGHT, true))
	if inst.refine > 0 or tab == "refine":
		b.add_child(_corner_chip("+%d" % inst.refine, UITheme.GOLD_BRIGHT if inst.refine > 0 else UITheme.TEXT_DIM, false))
	return b


func _corner_chip(text: String, color: Color, left: bool) -> Control:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(color, 0.12)
	s.border_color = Color(color, 0.6)
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	s.content_margin_left = 5
	s.content_margin_right = 5
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UITheme.make_label(text, 10, color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	p.position = Vector2(4, 3) if left else Vector2(CELL.x - 30.0, 3)
	return p


# =========================================================
# แผงขวา
# =========================================================
func _refresh_detail() -> void:
	var inst := selected_instance()
	_d_body.visible = inst != null
	_d_empty.visible = inst == null
	if inst == null:
		_d_empty.text = "เลือกอุปกรณ์ทางซ้ายเพื่อดูรายละเอียด"
		return
	var d := inst.data()
	_d_art.texture = d.icon if d != null else null
	_d_name.text = inst.display_name()
	GameWindow.clear_container(_d_stats)
	GameWindow.clear_container(_d_mats)
	if tab == "refine":
		_detail_refine(inst, d)
	else:
		_detail_socket(inst, d)


func _detail_refine(inst: ItemInstance, d: ItemData) -> void:
	var p := RefineSystem.preview(inst)
	_d_badge.text = "+%d  →  +%d" % [int(p.current_refine), int(p.next_refine)]
	var sub: Array[String] = ["ตีบวกสูงสุด +%d" % d.max_refine]
	if inst.bonus_percent > 0.0:
		sub.append("ของดรอป +%s%%" % ItemInstance._pct_text(inst.bonus_percent))
	_d_sub.text = "  ·  ".join(sub)
	_d_stats.add_child(_row("ค่าพลังที่เพิ่ม", "", UITheme.TEXT_DIM))
	var before := d.refine_bonuses(inst.refine)
	var after := d.refine_bonuses(inst.refine + 1)
	var any := false
	for key in after:
		var now := float(before.get(key, 0.0))
		var nxt := float(after[key])
		if absf(nxt - now) < 0.0001:
			continue
		any = true
		_d_stats.add_child(_row(String(key).to_upper(), "%s → %s  ▲ +%s" % [_num(now), _num(nxt), _num(nxt - now)], UITheme.GOOD))
	if not any:
		_d_stats.add_child(_row("—", "ไม่มีค่าพลังเพิ่ม", UITheme.TEXT_DIM))
	_set_rate(float(p.rate))
	var ore: StringName = p.ore_id
	_d_mats.add_child(_mat_row(ore, int(p.ore_count), PlayerState.inventory.count_of(ore)))
	_d_mats.add_child(_zeny_row(int(p.zeny)))
	_d_warn.text = "⚠ ระดับนี้ถ้าตีพลาดจะลดลง 1 ขั้น" if bool(p.can_downgrade) else ("ตีพลาดที่ระดับนี้ของไม่ลดขั้น (ลดตั้งแต่ +%d)" % RefineSystem.DOWNGRADE_FROM)
	var ok := PlayerState.zeny >= int(p.zeny) and PlayerState.inventory.count_of(ore) >= int(p.ore_count)
	if _rolling:
		_d_action.text = "กำลังตี..."
		_d_action.disabled = true
	elif not ok:
		_d_action.text = "วัสดุ/ซีนีไม่พอ"
		_d_action.disabled = true
	else:
		_d_action.text = "ตีบวก  +%d → +%d" % [int(p.current_refine), int(p.next_refine)]
		_d_action.disabled = false


func _detail_socket(inst: ItemInstance, d: ItemData) -> void:
	var p := SocketSystem.preview(inst, PlayerState.inventory)
	if p.is_empty():
		_d_badge.text = ""
		_d_sub.text = SocketSystem.reason_cannot_punch(inst)
		_set_rate(0.0)
		_d_action.disabled = true
		_d_action.text = "เจาะรูไม่ได้"
		_d_warn.text = ""
		return
	_d_badge.text = "ไม่มีรู → %d รู" % int(p.slots)
	_d_sub.text = "%s · Lv %d" % [String(p.tier_name), d.required_level]
	_d_stats.add_child(_row("ได้ช่องการ์ด", "%d ช่อง (ใส่การ์ดมอนได้)" % int(p.slots), UITheme.GOOD))
	_set_rate(float(p.rate))
	_d_mats.add_child(_mat_row(p.ore_id, int(p.ore_count), int(p.have_ore)))
	if bool(p.need_duplicate):
		var dup_have := 1 if int(p.dup_index) >= 0 else 0
		_d_mats.add_child(_mat_row(inst.item_id, 1, dup_have, "%s อีก 1 ชิ้น (ไม่มีรู/การ์ด)" % GameData.item_name(inst.item_id)))
	_d_mats.add_child(_zeny_row(int(p.zeny)))
	_d_warn.text = "⚠ เจาะไม่ติด = ของชิ้นนี้หาย" if bool(p.destroy_on_fail) else "เจาะไม่ติด อุปกรณ์หลักยังอยู่ (เสียวัสดุและซีนี)"
	var chk := SocketSystem.check(inst, PlayerState.inventory, PlayerState)
	_d_action.disabled = not bool(chk.ok)
	_d_action.text = "เจาะรู  (%d รู)" % int(p.slots) if bool(chk.ok) else "วัสดุ/ซีนีไม่พอ"


func _set_rate(rate: float) -> void:
	_d_rate_bar.value = rate
	_d_rate.text = "%.0f%%" % rate
	var fill := UITheme.bar_fill_style(UITheme.GOOD if rate >= 70.0 else (UITheme.ACCENT if rate >= 40.0 else UITheme.BAD))
	_d_rate_bar.add_theme_stylebox_override("fill", fill)


static func _num(v: float) -> String:
	if absf(v - roundf(v)) < 0.001:
		return str(int(roundf(v)))
	return ("%.2f" % v).trim_suffix("0")


func _row(left: String, right: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := UITheme.make_label(left, 14, UITheme.TEXT_DIM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	if right != "":
		var r := UITheme.make_label(right, 14, color)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(r)
	return row


## แถววัสดุ: [ไอคอน] ชื่อ ..... ใช้ N · มี M (เขียว = พอ · แดง = ขาด)
func _mat_row(id: StringName, need: int, have: int, label: String = "") -> Control:
	var p := PanelContainer.new()
	var ok := have >= need
	p.add_theme_stylebox_override("panel", UITheme.panel_style(Color("#102725"), UITheme.GOOD if ok else UITheme.BAD, 4, 1, 6.0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	p.add_child(row)
	var it := GameData.get_item(id)
	row.add_child(_icon(it.icon if it != null else null, 32))
	var nm := UITheme.make_label(label if label != "" else GameData.item_name(id), 14, UITheme.TEXT)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.clip_text = true
	row.add_child(nm)
	var amt := UITheme.make_label("ใช้ %s · มี %s" % [HUD._comma(need), HUD._comma(have)], 14, UITheme.GOOD if ok else UITheme.BAD)
	amt.name = "MatAmount"
	row.add_child(amt)
	return p


func _zeny_row(cost: int) -> Control:
	var p := PanelContainer.new()
	var ok := PlayerState.zeny >= cost
	p.add_theme_stylebox_override("panel", UITheme.panel_style(Color("#102725"), UITheme.GOOD if ok else UITheme.BAD, 4, 1, 6.0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	p.add_child(row)
	var g := PetrolWidgets.glyph("coin", 26.0, UITheme.GOLD_BRIGHT)
	g.custom_minimum_size = Vector2(32, 32)
	row.add_child(g)
	var disc := PlayerState.bounties.discount_percent() if PlayerState.bounties != null else 0
	var nm := UITheme.make_label("ค่าบริการ" + (" (กิลด์ −%d%%)" % disc if disc > 0 and tab == "refine" else ""), 14, UITheme.TEXT)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(nm)
	row.add_child(UITheme.make_label("%s z" % HUD._comma(cost), 14, UITheme.GOOD if ok else UITheme.BAD))
	return p


# =========================================================
# ตีบวก / เจาะรู
# =========================================================
func _do_action() -> void:
	if tab == "refine":
		await do_refine()
	elif tab == "socket":
		do_punch()


## ★ ตีบวก: หลอดลุ้น → รู้ผล → คำ SUCCESS/FAIL (เหมือนหน้าเดิมรอบ 59) ★ เทสต์: await win.do_refine()
func do_refine(roll_time: float = ROLL_TIME) -> void:
	if _rolling:
		return
	var inst := selected_instance()
	if inst == null or not RefineSystem.can_refine(inst):
		return
	var src := _selected
	_rolling = true
	_d_result.text = ""
	_d_action.disabled = true
	_d_action.text = "กำลังตี..."
	_d_roll.value = 0.0
	_d_roll.visible = true
	_play_sfx(SFX_ROLL)
	if roll_time > 0.0:
		var tw := create_tween()
		tw.tween_property(_d_roll, "value", 100.0, roll_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw.finished
	if not is_instance_valid(self):
		return
	_rolling = false
	_d_roll.visible = false
	if _inst_of(src) != inst:
		refresh()
		return
	var out := RefineSystem.try_refine(inst, PlayerState.inventory, PlayerState)
	last_result = out
	_d_result.text = String(out.message)
	_d_result.add_theme_color_override("font_color", UITheme.GOOD if out.success else UITheme.BAD)
	if bool(out.get("broke", false)):
		_remove_source(src)
	if bool(out.ok):
		_show_big_result(bool(out.success), "SUCCESS!" if out.success else ("FAIL\nของแตก!" if out.get("broke", false) else "FAIL"))
		_play_sfx(SFX_SUCCESS if out.success else SFX_FAIL)
	PlayerState.refresh()
	refresh()
	refine_finished.emit(out)


func do_punch() -> void:
	var inst := selected_instance()
	if inst == null:
		return
	var src := _selected
	var out := SocketSystem.try_punch(inst, PlayerState.inventory, PlayerState)
	last_result = out
	_d_result.text = String(out.message)
	_d_result.add_theme_color_override("font_color", UITheme.GOOD if out.success else UITheme.BAD)
	if bool(out.get("destroyed", false)):
		_remove_source(src)
	if bool(out.ok):
		_show_big_result(bool(out.success), "SUCCESS!" if out.success else "FAIL")
	PlayerState.refresh()
	refresh()


func _remove_source(src: String) -> void:
	if src.begins_with("inv:"):
		PlayerState.inventory.set_slot(int(src.substr(4)), null)
	elif src.begins_with("eq:"):
		PlayerState.equipment.unequip(int(src.substr(3)))
	_selected = ""


func _show_big_result(success: bool, text: String) -> void:
	if _big_tween != null and _big_tween.is_valid():
		_big_tween.kill()
	_big_result.text = text
	_big_result.add_theme_color_override("font_color", Color("#7dff8a") if success else Color("#ff5a5a"))
	_big_result.visible = true
	_big_result.modulate = Color(1, 1, 1, 0)
	_big_result.pivot_offset = size * 0.5
	_big_result.scale = Vector2(1.8, 1.8) if success else Vector2(0.6, 0.6)
	_big_result.position = Vector2.ZERO
	_big_result.size = size
	_big_tween = create_tween()
	_big_tween.set_parallel(true)
	_big_tween.tween_property(_big_result, "modulate:a", 1.0, 0.15)
	_big_tween.tween_property(_big_result, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_big_tween.chain().tween_interval(RESULT_SHOW)
	_big_tween.chain().tween_property(_big_result, "modulate:a", 0.0, 0.35)
	_big_tween.chain().tween_callback(func(): _big_result.visible = false)


func is_rolling() -> bool:
	return _rolling


func _play_sfx(key: String) -> void:
	var g := get_node_or_null("/root/Game")
	if g != null and "sfx" in g and g.sfx != null:
		g.sfx.play(key, 1.0, 0.0)


# =========================================================
# วางหน้าต่าง
# =========================================================
func fit_to_content() -> void:
	_place()
	for i in 2:
		await get_tree().process_frame
		if not is_instance_valid(self) or not visible:
			return
		_place()


func _place() -> void:
	if not is_inside_tree():
		return
	var vp := get_viewport_rect().size
	reset_size()
	size = Vector2(minf(WIN_MAX.x, vp.x - 40.0), minf(WIN_MAX.y, vp.y - 50.0))
	position = ((vp - size) * 0.5).floor()


func shell_hints() -> Array:
	return [["Esc", "ปิด"]]
