## ShopWindow — ร้านค้า (เปิดโดยคุยกับ NPC ประเภท SHOP)
##
## ★★ รอบ 160 — ดีไซน์ A «ตู้โชว์กริด + แผงรายละเอียด» (ผู้ใช้เลือกจาก _docs/mockup_รอบ159_ร้านค้า_A.png) ★★
##   ซ้าย   = ปุ่ม ซื้อ/ขาย · หมวดสินค้า (จำนวนในวงเล็บ) · กล่องขั้นกิลด์ + ส่วนลด (โหมดขาย: ปุ่มขายขยะทั้งหมด)
##   กลาง   = ค้นหา · เรียง · «เฉพาะที่ใส่ได้» · กริดไอคอนพร้อมราคา
##            (▲ เขียว = ดีกว่าที่ใส่อยู่ · ป้าย «ใส่อยู่» · สีหม่น + Lv แดง = เลเวลยังไม่ถึง)
##            เลือกหมวดแล้ว หมวดนั้นขึ้นก่อน ที่เหลืออยู่ใต้หัว «หมวดอื่น» · «ทั้งหมด» = แบ่งหัวข้อตามหมวด
##   ขวา    = รายละเอียด + เทียบค่าพลังกับของที่ใส่ + เลือกจำนวน (− + ×10 สูงสุด) + ราคา/ส่วนลดกิลด์/เหลือหลังซื้อ + ปุ่มทอง
##   ล่าง   = ซีนี · ช่องกระเป๋า · คำใบ้ปุ่ม
## ลัด: ดับเบิลคลิก = ซื้อ/ขาย 1 · Shift+คลิก = ซื้อ 10 / ขายทั้งกอง
## ตัวเลขขนาดหน้าต่าง/ช่อง ปรับที่ค่าคงที่ข้างล่าง
class_name ShopWindow
extends GameWindow

const WIN_MAX := Vector2(1120, 640)
const LEFT_W := 186.0
const DETAIL_W := 330.0
const CELL := Vector2(96, 104)
const GRID_COLS := 5
const QTY_MAX := 999
const PRICE_COLOR := Color("#ffe9a0")

## หมวด — id · ชื่อ · ตัวอักษรนำหน้า (หมวดที่ไม่มีของจะซ่อนเอง)
const CATS := [
	["all", "ทั้งหมด", "◆"],
	["consumables", "ยา & ของใช้", "✚"],
	["weapons", "อาวุธ", "⚔"],
	["armor", "ชุดเกราะ", "⛨"],
	["accessory", "เครื่องประดับ", "◇"],
	["materials", "แร่ & วัตถุดิบ", "✦"],
	["other", "อื่น ๆ", "•"],
]
const SORTS := ["ค่าเริ่มต้น", "ราคา ต่ำ→สูง", "ราคา สูง→ต่ำ", "เลเวล"]

## ★ ชื่อ NPC ร้านที่เปิดล่าสุด (npc.open_shop ตั้งก่อนยิงสัญญาณ) → หัวหน้าต่าง «ร้านของ…» ★
static var next_owner: String = ""

var _shop_items: Array = []
var _mode_buy := true
var _category := "all"
var _sort := 0
var _search := ""
var _usable_only := false
var _sel_id: StringName = &""      # โหมดซื้อ: id สินค้าที่เลือก
var _sel_slot := -1                # โหมดขาย: ช่องในกระเป๋าที่เลือก
var _qty := 1
var _bulk_selling := false

var _tab_buy: Button
var _tab_sell: Button
var _cat_buttons: Dictionary = {}
var _rank_icon: TextureRect
var _rank_label: Label
var _bulk_button: Button
var _search_edit: LineEdit
var _sort_button: OptionButton
var _usable_button: Button
var _list: VBoxContainer           # เนื้อหากริด (อยู่ใน ScrollContainer — เทสต์ chapter7 อ้าง _list.get_parent())
var _zeny_label: Label
var _slots_label: Label
var _hint_label: Label
# แผงขวา
var _d_art: TextureRect
var _d_name: Label
var _d_type: Label
var _d_chips: HBoxContainer
var _d_cmp: VBoxContainer
var _d_desc: Label
var _d_qty: Label
var _d_qty_row: HBoxContainer
var _d_sum: VBoxContainer
var _d_action: Button
var _d_empty: Label
var _d_body: VBoxContainer
var _d_info: VBoxContainer         # ★ รอบ 164 ★ เนื้อหาในกล่องเลื่อนของแผงรายละเอียด


func _ready() -> void:
	window_title = "ร้านค้า"
	super._ready()
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for child in _bar.get_child(0).get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(44, 44)
			child.add_theme_font_size_override("font_size", 20)
	get_viewport().size_changed.connect(_place_shop)
	Events.zeny_changed.connect(func(_z): refresh())
	Events.inventory_changed.connect(refresh)
	Events.equipment_changed.connect(refresh)


func open_shop(item_ids: Array) -> void:
	_shop_items = item_ids
	_mode_buy = true
	_category = "all"
	_search = ""
	if _search_edit != null:
		_search_edit.text = ""
	_sel_id = StringName(item_ids[0]) if not item_ids.is_empty() else &""
	_sel_slot = -1
	_qty = 1
	set_title("─◆  %s  ◆─" % (("ร้านของ" + next_owner) if next_owner != "" else "ร้านค้า"))
	next_owner = ""
	show_window()


# =========================================================
# สร้างหน้าต่าง
# =========================================================
func _build_content() -> void:
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	body.add_child(_build_left())
	body.add_child(_build_middle())
	body.add_child(_build_right())

	content.add_child(UITheme.separator())
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 20)
	content.add_child(foot)
	var zrow := HBoxContainer.new()
	zrow.add_theme_constant_override("separation", 6)
	var coin := PetrolWidgets.glyph("coin", 18.0, UITheme.GOLD_BRIGHT)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	zrow.add_child(coin)
	_zeny_label = UITheme.make_label("0 z", 18, UITheme.TEXT)
	zrow.add_child(_zeny_label)
	foot.add_child(zrow)
	_slots_label = UITheme.make_label("", 16, UITheme.TEXT_DIM)
	foot.add_child(_slots_label)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(sp)
	_hint_label = UITheme.make_label("", 14, UITheme.TEXT_DIM)
	foot.add_child(_hint_label)


func _build_left() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = LEFT_W
	col.add_theme_constant_override("separation", 4)

	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 6)
	col.add_child(modes)
	_tab_buy = UITheme.make_button("ซื้อ")
	_tab_sell = UITheme.make_button("ขาย")
	for b: Button in [_tab_buy, _tab_sell]:
		b.custom_minimum_size = Vector2(0, 46)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 19)
		modes.add_child(b)
	_tab_buy.pressed.connect(func(): _set_mode(true))
	_tab_sell.pressed.connect(func(): _set_mode(false))

	var gap := Control.new()
	gap.custom_minimum_size.y = 6
	col.add_child(gap)
	for c in CATS:
		var id := String(c[0])
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 40)
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(_on_category.bind(id))
		col.add_child(b)
		_cat_buttons[id] = b

	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(fill)

	_bulk_button = UITheme.make_button("ขายขยะทั้งหมด")
	_bulk_button.custom_minimum_size.y = 44
	_bulk_button.add_theme_font_size_override("font_size", 16)
	_bulk_button.pressed.connect(_sell_junk)
	col.add_child(_bulk_button)

	var rank := PanelContainer.new()
	rank.add_theme_stylebox_override("panel", UITheme.inner_style(Color("#091816cc"), 4, 8.0))
	var rrow := HBoxContainer.new()
	rrow.add_theme_constant_override("separation", 8)
	rank.add_child(rrow)
	_rank_icon = TextureRect.new()
	_rank_icon.custom_minimum_size = Vector2(34, 34)
	_rank_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rank_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_rank_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_rank_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rrow.add_child(_rank_icon)
	_rank_label = UITheme.make_label("", 14, UITheme.TEXT)
	rrow.add_child(_rank_label)
	col.add_child(rank)
	return col


func _on_category(id: String) -> void:
	_category = id
	refresh()


func _build_middle() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.inner_style(Color("#091816b3"), 4, 10.0))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	box.add_child(head)
	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "ค้นหาในร้าน…"
	_search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_edit.custom_minimum_size.y = 36
	_search_edit.add_theme_font_size_override("font_size", 15)
	_search_edit.add_theme_stylebox_override("normal", UITheme.panel_style(Color("#091816"), UITheme.BORDER, 3, 1, 8.0))
	_search_edit.add_theme_stylebox_override("focus", UITheme.panel_style(Color("#091816"), UITheme.ACCENT, 3, 1, 8.0))
	_search_edit.add_theme_color_override("font_color", UITheme.TEXT)
	_search_edit.add_theme_color_override("font_placeholder_color", UITheme.TEXT_DIM)
	_search_edit.text_changed.connect(_on_search)
	head.add_child(_search_edit)
	_sort_button = OptionButton.new()
	_sort_button.focus_mode = Control.FOCUS_NONE
	_sort_button.custom_minimum_size = Vector2(150, 36)
	_sort_button.add_theme_font_size_override("font_size", 14)
	for s in SORTS:
		_sort_button.add_item("เรียง: " + String(s))
	_sort_button.item_selected.connect(_on_sort)
	head.add_child(_sort_button)
	_usable_button = UITheme.make_button("เฉพาะที่ใส่ได้")
	_usable_button.toggle_mode = true
	_usable_button.custom_minimum_size.y = 36
	_usable_button.tooltip_text = "ซ่อนของสวมใส่ที่เลเวลยังไม่ถึง"
	_usable_button.toggled.connect(_on_usable)
	head.add_child(_usable_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 200
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	return panel


func _on_search(t: String) -> void:
	_search = t.strip_edges()
	refresh()


func _on_sort(i: int) -> void:
	_sort = i
	refresh()


func _on_usable(on: bool) -> void:
	_usable_only = on
	refresh()


func _build_right() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = DETAIL_W
	panel.add_theme_stylebox_override("panel", UITheme.panel_style(Color("#091816d9"), UITheme.ACCENT, 4, 1, 12.0))
	var outer := VBoxContainer.new()
	panel.add_child(outer)
	_d_empty = UITheme.make_label("เลือกสินค้าเพื่อดูรายละเอียด", 15, UITheme.TEXT_DIM)
	_d_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_empty.custom_minimum_size.x = DETAIL_W - 30.0
	outer.add_child(_d_empty)

	_d_body = VBoxContainer.new()
	_d_body.add_theme_constant_override("separation", 6)
	_d_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(_d_body)

	# ★ รอบ 164 ★ ส่วนข้อมูล (รูป/ชื่อ/เทียบค่าพลัง/คำอธิบาย) อยู่ในกล่องเลื่อน
	# ปุ่มจำนวน + ราคา + ปุ่มซื้อ ปักไว้ล่างสุดเสมอ → หน้าต่างไม่ยืดเกินจอเมื่อค่าพลังหลายบรรทัด
	var info_scroll := ScrollContainer.new()
	info_scroll.name = "DetailScroll"
	info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	info_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_d_body.add_child(info_scroll)
	_d_info = VBoxContainer.new()
	_d_info.add_theme_constant_override("separation", 6)
	_d_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_scroll.add_child(_d_info)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	_d_info.add_child(top)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UITheme.panel_style(Color("#102725"), UITheme.BORDER, 4, 1, 6.0))
	top.add_child(frame)
	_d_art = TextureRect.new()
	_d_art.custom_minimum_size = Vector2(76, 76)
	_d_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_d_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_d_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	frame.add_child(_d_art)
	var tcol := VBoxContainer.new()
	tcol.add_theme_constant_override("separation", 2)
	tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tcol.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(tcol)
	_d_name = UITheme.make_label("", 21, UITheme.TEXT)
	_d_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_name.custom_minimum_size.x = DETAIL_W - 140.0
	tcol.add_child(_d_name)
	_d_type = UITheme.make_label("", 14, UITheme.TEXT_DIM)
	tcol.add_child(_d_type)
	_d_chips = HBoxContainer.new()
	_d_chips.add_theme_constant_override("separation", 4)
	tcol.add_child(_d_chips)

	_d_info.add_child(UITheme.separator())
	var cmp_panel := PanelContainer.new()
	cmp_panel.add_theme_stylebox_override("panel", UITheme.panel_style(Color("#17343099"), Color(0, 0, 0, 0), 3, 0, 8.0))
	_d_info.add_child(cmp_panel)
	_d_cmp = VBoxContainer.new()
	_d_cmp.add_theme_constant_override("separation", 0)
	cmp_panel.add_child(_d_cmp)
	_d_desc = UITheme.make_label("", 13, UITheme.TEXT_DIM)
	_d_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_desc.max_lines_visible = -1   # ★ รอบ 164 ★ อยู่ในกล่องเลื่อนแล้ว โชว์ครบได้
	_d_desc.custom_minimum_size.x = DETAIL_W - 44.0   # autowrap ต้องมีความกว้างตั้งต้น ไม่งั้นความสูงขั้นต่ำพุ่งตอนเปิดครั้งแรก
	_d_info.add_child(_d_desc)


	_d_qty_row = HBoxContainer.new()
	_d_qty_row.add_theme_constant_override("separation", 6)
	_d_body.add_child(_d_qty_row)
	var minus := _small_button("−", 40)
	minus.pressed.connect(func(): _set_qty(_qty - 1))
	_d_qty_row.add_child(minus)
	var qbox := PanelContainer.new()
	qbox.add_theme_stylebox_override("panel", UITheme.panel_style(Color("#091816"), UITheme.ACCENT, 3, 1, 4.0))
	qbox.custom_minimum_size = Vector2(62, 38)
	_d_qty = UITheme.make_label("1", 19, UITheme.TEXT)
	_d_qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_d_qty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	qbox.add_child(_d_qty)
	_d_qty_row.add_child(qbox)
	var plus := _small_button("+", 40)
	plus.pressed.connect(func(): _set_qty(_qty + 1))
	_d_qty_row.add_child(plus)
	var ten := _small_button("×10", 50)
	ten.pressed.connect(func(): _set_qty(_qty * 10 if _qty > 1 else 10))
	_d_qty_row.add_child(ten)
	var mx := _small_button("สูงสุด", 64)
	mx.pressed.connect(func(): _set_qty(_max_qty()))
	_d_qty_row.add_child(mx)

	_d_sum = VBoxContainer.new()
	_d_sum.add_theme_constant_override("separation", 0)
	_d_body.add_child(_d_sum)
	_d_action = UITheme.make_gold_button("ซื้อ")
	_d_action.custom_minimum_size.y = 44
	_d_action.add_theme_font_size_override("font_size", 19)
	_d_action.pressed.connect(_do_action)
	_d_body.add_child(_d_action)
	return panel


func _small_button(text: String, w: float) -> Button:
	var b := UITheme.make_button(text, w)
	b.custom_minimum_size.y = 38
	b.add_theme_font_size_override("font_size", 16)
	return b


# =========================================================
# โหมด / จำนวน
# =========================================================
func _set_mode(buy: bool) -> void:
	_mode_buy = buy
	_category = "all"
	_qty = 1
	if buy:
		_sel_slot = -1
		if GameData.get_item(_sel_id) == null and not _shop_items.is_empty():
			_sel_id = StringName(_shop_items[0])
	else:
		_sel_slot = _first_sellable()
	refresh()


func _set_qty(n: int) -> void:
	_qty = clampi(n, 1, maxi(1, _max_qty()))
	refresh()


## ซื้อได้มากสุดกี่ชิ้น (เงิน + ที่ว่างในกระเป๋า) / ขายได้มากสุด = ทั้งกอง
func _max_qty() -> int:
	if not _mode_buy:
		var sinst: ItemInstance = PlayerState.inventory.get_slot(_sel_slot)
		return sinst.count if sinst != null else 1
	var d := GameData.get_item(_sel_id)
	if d == null:
		return 1
	var unit := unit_price(d)
	var by_money: int = QTY_MAX if unit <= 0 else int(PlayerState.zeny / unit)
	return clampi(mini(by_money, _room_for(d)), 1, QTY_MAX)


## ที่ว่างในกระเป๋าสำหรับไอเทมนี้ (ชิ้น)
func _room_for(d: ItemData) -> int:
	var inv := PlayerState.inventory
	var free := inv.size - inv.used_slots()
	if not d.is_stackable():
		return free
	var room := free * d.max_stack
	for i in range(inv.size):
		var s := inv.get_slot(i)
		if s != null and s.item_id == d.id and s.refine == 0:
			room += maxi(0, d.max_stack - s.count)
	return room


## ราคาซื้อต่อชิ้นหลังส่วนลดกิลด์
static func unit_price(d: ItemData) -> int:
	return BountyBoard.guild_price(d.buy_price)


# =========================================================
# ซื้อ / ขาย
# =========================================================
func _do_action() -> void:
	if _mode_buy:
		_buy(_sel_id, _qty)
	else:
		_sell(_sel_slot, _qty)


func _buy(id: StringName, n: int) -> void:
	if id == &"":
		return
	PlayerState.buy(id, maxi(1, n))
	_qty = 1
	refresh()


func _sell(slot: int, n: int) -> void:
	var inst: ItemInstance = PlayerState.inventory.get_slot(slot)
	if inst == null:
		return
	PlayerState.sell_slot(slot, clampi(n, 1, inst.count))
	_qty = 1
	if PlayerState.inventory.get_slot(slot) == null:
		_sel_slot = _first_sellable()
	refresh()


func _on_cell_input(ev: InputEvent, key: Variant) -> void:
	if not (ev is InputEventMouseButton):
		return
	var mb := ev as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	if mb.double_click:
		if _mode_buy:
			_buy(StringName(key), 1)
		else:
			_sell(int(key), 1)
		return
	if mb.shift_pressed:
		_select(key)
		if _mode_buy:
			_buy(StringName(key), mini(10, _max_qty()))
		else:
			var inst: ItemInstance = PlayerState.inventory.get_slot(int(key))
			if inst != null:
				_sell(int(key), inst.count)
		return
	_select(key)


func _select(key: Variant) -> void:
	if _mode_buy:
		if _sel_id != StringName(key):
			_qty = 1
		_sel_id = StringName(key)
	else:
		if _sel_slot != int(key):
			_qty = 1
		_sel_slot = int(key)
	if _d_info != null and _d_info.get_parent() is ScrollContainer:   # ★ รอบ 164 ★ เลือกชิ้นใหม่ = เลื่อนกลับบนสุด
		(_d_info.get_parent() as ScrollContainer).scroll_vertical = 0
	refresh()


func _first_sellable() -> int:
	for i in range(PlayerState.inventory.size):
		if _sellable(PlayerState.inventory.get_slot(i)):
			return i
	return -1


static func _sellable(inst: ItemInstance) -> bool:
	if inst == null:
		return false
	var d := inst.data()
	return d != null and d.type != ItemData.Type.QUEST and d.sellable and inst.sell_value() > 0


# =========================================================
# หมวด / ค้นหา / เปรียบเทียบ
# =========================================================
static func category_of(d: ItemData) -> String:
	if d == null:
		return "other"
	match d.type:
		ItemData.Type.CONSUMABLE:
			return "consumables"
		ItemData.Type.WEAPON:
			return "weapons"
		ItemData.Type.ARMOR:
			return "accessory" if d.slot == ItemData.Slot.ACCESSORY else "armor"
		ItemData.Type.MATERIAL:
			return "materials"
	return "other"


## ของที่ใส่อยู่ในช่องเดียวกับไอเทมนี้ (null = ไม่มี/ไม่ใช่ของสวมใส่)
static func equipped_for(d: ItemData) -> ItemInstance:
	if d == null or not d.is_equipment() or PlayerState.equipment == null:
		return null
	var slot: int = Equipment.slot_for(d)
	if slot < 0:
		return null
	return PlayerState.equipment.get_item(slot)


## คะแนนเทียบคร่าว ๆ: อาวุธ = ATK · อื่น ๆ = DEF + MDEF + MaxHP/10 + สเตตัส
static func _score(inst: ItemInstance) -> float:
	var d := inst.data()
	if d == null:
		return 0.0
	if d.type == ItemData.Type.WEAPON:
		return float(inst.total_atk()) + d.matk * 0.5
	return float(inst.total_def()) + d.mdef + d.max_hp / 10.0 + d.max_sp / 10.0 \
		+ d.bonus_str + d.bonus_agi + d.bonus_vit + d.bonus_int + d.bonus_dex + d.bonus_luk + d.flee * 0.5 + d.hit * 0.5


## ▲ = ดีกว่าที่ใส่อยู่ (ช่องว่างก็นับว่าดีกว่า)
static func is_upgrade(d: ItemData) -> bool:
	if d == null or not d.is_equipment():
		return false
	var cur := equipped_for(d)
	var mine := _score(ItemInstance.create(d.id))
	if cur == null:
		return mine > 0.0
	if cur.item_id == d.id:
		return false
	return mine > _score(cur) + 0.001


static func level_ok(d: ItemData) -> bool:
	return d == null or PlayerState.stats.level >= d.required_level


func _matches(d: ItemData) -> bool:
	if d == null:
		return false
	if _search != "" and d.display_name.findn(_search) < 0:
		return false
	if _usable_only and d.is_equipment() and not level_ok(d):
		return false
	return true


func _sort_keys(keys: Array) -> void:
	if _sort == 0:
		return
	keys.sort_custom(_sort_less)


func _sort_less(a: Variant, b: Variant) -> bool:
	var da := _data_of(a)
	var db := _data_of(b)
	if da == null or db == null:
		return false
	match _sort:
		1: return _price_of(a) < _price_of(b)
		2: return _price_of(a) > _price_of(b)
		3: return da.required_level < db.required_level
	return false


func _data_of(key: Variant) -> ItemData:
	if _mode_buy:
		return GameData.get_item(StringName(key))
	var inst: ItemInstance = PlayerState.inventory.get_slot(int(key))
	return inst.data() if inst != null else null


func _price_of(key: Variant) -> int:
	var d := _data_of(key)
	if d == null:
		return 0
	if _mode_buy:
		return unit_price(d)
	var inst: ItemInstance = PlayerState.inventory.get_slot(int(key))
	return int(inst.sell_value() / maxi(1, inst.count)) if inst != null else 0


## key ทั้งหมดของโหมดนี้ (ซื้อ = id สินค้า · ขาย = เลขช่องกระเป๋า)
func _all_keys() -> Array:
	var out: Array = []
	if _mode_buy:
		for id in _shop_items:
			if GameData.get_item(StringName(id)) != null:
				out.append(StringName(id))
	else:
		for i in range(PlayerState.inventory.size):
			if _sellable(PlayerState.inventory.get_slot(i)):
				out.append(i)
	return out


func _in_category(keys: Array, cid: String, inside: bool) -> Array:
	var out: Array = []
	for k in keys:
		if (category_of(_data_of(k)) == cid) == inside:
			out.append(k)
	return out


# =========================================================
# refresh
# =========================================================
func refresh() -> void:
	if _list == null or not visible or _bulk_selling:
		return
	var inv := PlayerState.inventory
	_zeny_label.text = "%s z" % HUD._comma(PlayerState.zeny)
	_slots_label.text = "กระเป๋า %d / %d ช่อง" % [inv.used_slots(), inv.size]
	_hint_label.text = "ดับเบิลคลิก = ซื้อ 1 · Shift+คลิก = ซื้อ 10" if _mode_buy else "ดับเบิลคลิก = ขาย 1 · Shift+คลิก = ขายทั้งกอง"
	_style_mode(_tab_buy, _mode_buy)
	_style_mode(_tab_sell, not _mode_buy)
	_search_edit.placeholder_text = "ค้นหาในร้าน…" if _mode_buy else "ค้นหาในกระเป๋า…"
	_usable_button.visible = _mode_buy
	_bulk_button.visible = not _mode_buy
	_bulk_button.disabled = junk_candidates().is_empty()
	_refresh_rank()

	var keys := _all_keys()
	var shown: Array = []
	var counts: Dictionary = {"all": 0}
	for k in keys:
		var d := _data_of(k)
		if not _matches(d):
			continue
		shown.append(k)
		counts["all"] = int(counts["all"]) + 1
		var c := category_of(d)
		counts[c] = int(counts.get(c, 0)) + 1
	if _category != "all" and int(counts.get(_category, 0)) == 0:
		_category = "all"
	for c in CATS:
		var id := String(c[0])
		var b: Button = _cat_buttons[id]
		var n := int(counts.get(id, 0))
		b.visible = id == "all" or n > 0
		b.text = "%s  %s   (%d)" % [String(c[2]), String(c[1]), n]
		_style_cat(b, id == _category)

	# ---------- กริด ----------
	GameWindow.clear_container(_list)
	_sort_keys(shown)
	if shown.is_empty():
		_list.add_child(UITheme.make_label("ไม่พบสินค้า" if _mode_buy else "ไม่มีของให้ขาย", 16, UITheme.TEXT_DIM))
	elif _category == "all":
		for c in CATS:
			var cid := String(c[0])
			if cid == "all":
				continue
			var part := _in_category(shown, cid, true)
			if part.is_empty():
				continue
			_list.add_child(UITheme.make_label(String(c[1]), 13, UITheme.ACCENT))
			_list.add_child(_make_grid(part))
	else:
		_list.add_child(_make_grid(_in_category(shown, _category, true)))
		var rest := _in_category(shown, _category, false)
		if not rest.is_empty():
			_list.add_child(UITheme.separator())
			_list.add_child(UITheme.make_label("หมวดอื่น", 13, UITheme.TEXT_DIM))
			_list.add_child(_make_grid(rest))

	if _mode_buy and GameData.get_item(_sel_id) == null and not shown.is_empty():
		_sel_id = StringName(shown[0])
	if not _mode_buy and not _sellable(inv.get_slot(_sel_slot)):
		_sel_slot = _first_sellable()
	_refresh_detail()


func _style_mode(b: Button, on: bool) -> void:
	b.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT if on else UITheme.TEXT_DIM)
	b.add_theme_stylebox_override("normal", UITheme._btn_style(UITheme.PANEL_HOVER if on else Color(0.06, 0.15, 0.14, 0.75), UITheme.ACCENT if on else UITheme.BORDER_SOFT))


func _style_cat(b: Button, on: bool) -> void:
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
	b.add_theme_color_override("font_hover_color", UITheme.TEXT)


func _refresh_rank() -> void:
	var board: BountyBoard = PlayerState.bounties
	if board == null:
		return
	var letter := board.rank_letter()
	var path := "res://Sprites/ui/guild_rank/rank_%s.png" % letter.to_lower()
	_rank_icon.texture = (load(path) as Texture2D) if ResourceLoader.exists(path) else null
	if _mode_buy:
		_rank_label.text = "ขั้นกิลด์ %s\nทุกชิ้นลด %d%%" % [letter, board.discount_percent()]
	else:
		_rank_label.text = "ขั้นกิลด์ %s\n(ราคาขายไม่ลด)" % letter


func _make_grid(keys: Array) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = GRID_COLS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for k in keys:
		grid.add_child(_make_cell(k))
	return grid


func _make_cell(key: Variant) -> Button:
	var d := _data_of(key)
	var inst: ItemInstance = null if _mode_buy else PlayerState.inventory.get_slot(int(key))
	var selected: bool = (_mode_buy and StringName(key) == _sel_id) or (not _mode_buy and int(key) == _sel_slot)
	var b := Button.new()
	b.name = "Cell_%s" % String(d.id)
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = CELL
	b.tooltip_text = d.display_name
	var st := UITheme.slot_style(selected)
	if selected:
		st.shadow_color = Color(UITheme.GOLD_BRIGHT, 0.35)
		st.shadow_size = 6
		st.border_color = UITheme.GOLD_BRIGHT
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", UITheme.slot_style(true))
	b.add_theme_stylebox_override("pressed", st)
	b.gui_input.connect(_on_cell_input.bind(key))

	var art := TextureRect.new()
	art.texture = d.icon
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.position = Vector2((CELL.x - 60.0) * 0.5, 7)
	art.size = Vector2(60, 60)
	b.add_child(art)
	var lv_ok := level_ok(d)
	if d.is_equipment() and not lv_ok:
		art.modulate = Color(0.45, 0.45, 0.45, 1)

	# ราคา (ซื้อ: ราคาเดิมขีดฆ่า + ราคาหลังลด · ขาย: ราคาต่อชิ้น)
	var price := RichTextLabel.new()
	price.bbcode_enabled = true
	price.scroll_active = false
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price.position = Vector2(2, 72)
	price.size = Vector2(CELL.x - 4.0, 26)
	price.add_theme_font_size_override("normal_font_size", 14)
	price.add_theme_color_override("default_color", PRICE_COLOR)
	if _mode_buy:
		var unit := unit_price(d)
		if unit != d.buy_price:
			price.text = "[center][font_size=10][color=#81958a][s]%s[/s][/color][/font_size] %s[/center]" % [HUD._comma(d.buy_price), HUD._comma(unit)]
		else:
			price.text = "[center]%s[/center]" % HUD._comma(unit)
	else:
		price.text = "[center]%s[/center]" % HUD._comma(int(inst.sell_value() / maxi(1, inst.count)))
	b.add_child(price)

	# ป้ายมุม
	var cur := equipped_for(d)
	if _mode_buy and cur != null and cur.item_id == d.id:
		b.add_child(_corner_chip("ใส่อยู่", UITheme.GOLD_BRIGHT, true))
	elif d.is_equipment() and not lv_ok:
		b.add_child(_corner_chip("Lv %d" % d.required_level, UITheme.BAD, true))
	if d.is_equipment() and lv_ok and is_upgrade(d):
		var up := UITheme.make_label("▲", 14, UITheme.GOOD)
		up.name = "Upgrade"
		up.mouse_filter = Control.MOUSE_FILTER_IGNORE
		up.position = Vector2(CELL.x - 20.0, 2)
		b.add_child(up)
	if inst != null and inst.count > 1:
		var cnt := UITheme.make_label("×%d" % inst.count, 12, UITheme.TEXT)
		cnt.add_theme_color_override("font_outline_color", Color.BLACK)
		cnt.add_theme_constant_override("outline_size", 4)
		cnt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cnt.position = Vector2(CELL.x - 36.0, 52)
		b.add_child(cnt)
	if inst != null and inst.refine > 0:
		b.add_child(_corner_chip("+%d" % inst.refine, UITheme.GOLD_BRIGHT, false))
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
	p.position = Vector2(4, 3) if left else Vector2(CELL.x - 34.0, 3)
	return p


# =========================================================
# แผงขวา
# =========================================================
func _refresh_detail() -> void:
	var d: ItemData = null
	var inst: ItemInstance = null
	if _mode_buy:
		d = GameData.get_item(_sel_id) if _sel_id != &"" else null
		if d != null:
			inst = ItemInstance.create(d.id)
	elif _sel_slot >= 0:
		inst = PlayerState.inventory.get_slot(_sel_slot)
		d = inst.data() if inst != null else null
	_d_empty.visible = d == null
	_d_body.visible = d != null
	if d == null:
		return
	_qty = clampi(_qty, 1, maxi(1, _max_qty()))

	_d_art.texture = d.icon
	_d_name.text = d.display_name if _mode_buy else inst.display_name()
	_d_type.text = _type_text(d)
	GameWindow.clear_container(_d_chips)
	var rar := UITheme.rarity_of(d)
	_d_chips.add_child(_chip(String(rar[0]), rar[1]))
	if d.is_equipment():
		if level_ok(d):
			_d_chips.add_child(_chip("ใส่ได้ (Lv %d)" % d.required_level, UITheme.GOOD))
		else:
			_d_chips.add_child(_chip("ต้อง Lv %d" % d.required_level, UITheme.BAD))
	var have := PlayerState.inventory.count_of(d.id)
	if _mode_buy and not d.is_equipment() and have > 0:
		_d_chips.add_child(_chip("มีอยู่ %d" % have, UITheme.TEXT_DIM))

	# ---------- เทียบ / ค่าพลัง ----------
	GameWindow.clear_container(_d_cmp)
	var cur := equipped_for(d)
	if d.is_equipment():
		if cur != null:
			_d_cmp.add_child(_row("เทียบกับที่ใส่อยู่ (%s)" % cur.display_name(), "", UITheme.TEXT_DIM, 14))
		else:
			_d_cmp.add_child(_row("ช่องนี้ยังว่างอยู่", "", UITheme.TEXT_DIM, 14))
	for l in _stat_lines(inst, cur if d.is_equipment() else null):
		_d_cmp.add_child(_row(String(l[0]), String(l[1]), l[2], 15))
	if d.is_equipment():
		_d_cmp.add_child(_row("ช่องการ์ด", ("%d (ของร้าน)" % inst.slots) if _mode_buy else str(inst.slots), UITheme.TEXT, 15))
	_d_cmp.get_parent().visible = _d_cmp.get_child_count() > 0
	_d_desc.text = d.description

	# ---------- จำนวน + ราคา ----------
	_d_qty.text = str(_qty)
	_d_qty_row.visible = _mode_buy or (inst != null and inst.count > 1)
	GameWindow.clear_container(_d_sum)
	if _mode_buy:
		var unit := unit_price(d)
		var full := d.buy_price * _qty
		var total := unit * _qty
		var board: BountyBoard = PlayerState.bounties
		var price_label := "ราคา" if _qty <= 1 else "ราคา  (%s × %d)" % [HUD._comma(d.buy_price), _qty]
		_d_sum.add_child(_row(price_label, "%s z" % HUD._comma(full), UITheme.TEXT, 14))
		if total != full and board != null:
			_d_sum.add_child(_row("ส่วนลดกิลด์ %s (%d%%)" % [board.rank_letter(), board.discount_percent()], "−%s" % HUD._comma(full - total), UITheme.GOOD, 14))
		_d_sum.add_child(_row("รวม", "%s z" % HUD._comma(total), PRICE_COLOR, 18))
		var left := PlayerState.zeny - total
		_d_sum.add_child(_row("เหลือหลังซื้อ", "%s z" % HUD._comma(left), UITheme.TEXT if left >= 0 else UITheme.BAD, 14))
		if PlayerState.zeny < unit:
			_d_action.text = "ซีนีไม่พอ"
			_d_action.disabled = true
		elif _room_for(d) <= 0:
			_d_action.text = "กระเป๋าเต็ม"
			_d_action.disabled = true
		else:
			_d_action.text = "ซื้อ %d ชิ้น" % _qty
			_d_action.disabled = false
	else:
		var each := int(inst.sell_value() / maxi(1, inst.count))
		_d_sum.add_child(_row("ราคาขาย / ชิ้น", "%s z" % HUD._comma(each), UITheme.TEXT, 14))
		_d_sum.add_child(_row("ได้รับ", "%s z" % HUD._comma(each * _qty), PRICE_COLOR, 18))
		_d_sum.add_child(_row("มีหลังขาย", "%s z" % HUD._comma(PlayerState.zeny + each * _qty), UITheme.TEXT, 14))
		_d_action.text = "ขาย %d ชิ้น" % _qty
		_d_action.disabled = false


func _type_text(d: ItemData) -> String:
	match d.type:
		ItemData.Type.CONSUMABLE: return "ยา / ของใช้"
		ItemData.Type.WEAPON: return "อาวุธ"
		ItemData.Type.MATERIAL: return "วัตถุดิบ"
		ItemData.Type.CARD: return "การ์ด"
		ItemData.Type.ARMOR:
			var slot: int = Equipment.slot_for(d)
			if slot >= 0:
				return "ของสวมใส่ · %s" % String(Equipment.SLOT_NAMES.get(slot, ""))
			return "ของสวมใส่"
	return "ไอเทม"


## บรรทัดค่าพลัง [ชื่อ, ค่า, สี] — เทียบกับของที่ใส่อยู่ (สูงกว่า = เขียว ▲ · ต่ำกว่า = แดง ▼)
func _stat_lines(inst: ItemInstance, equipped: ItemInstance) -> Array:
	var d := inst.data()
	var ed: ItemData = equipped.data() if equipped != null else null
	var out: Array = []
	if d.is_equipment():
		_add_stat(out, "ATK", float(inst.total_atk()), float(equipped.total_atk()) if equipped != null else 0.0, "%d", equipped != null)
		_add_stat(out, "DEF", float(inst.total_def()), float(equipped.total_def()) if equipped != null else 0.0, "%d", equipped != null)
		for row in [["matk", "MATK"], ["mdef", "MDEF"], ["hit", "HIT"], ["flee", "FLEE"], ["crit", "คริ"],
				["max_hp", "MaxHP"], ["max_sp", "MaxSP"], ["bonus_str", "STR"], ["bonus_agi", "AGI"],
				["bonus_vit", "VIT"], ["bonus_int", "INT"], ["bonus_dex", "DEX"], ["bonus_luk", "LUK"]]:
			var mine: float = float(inst.boosted(float(d.get(row[0]))))
			var theirs: float = float(equipped.boosted(float(ed.get(row[0])))) if ed != null else 0.0
			_add_stat(out, String(row[1]), mine, theirs, "%d", equipped != null)
		for row in [["aspd_percent", "ความเร็วโจมตี %"], ["move_speed_percent", "ความเร็วเดิน %"],
				["damage_percent", "ดาเมจ %"], ["skill_damage_percent", "ดาเมจสกิล %"], ["crit_damage_percent", "ดาเมจคริ %"]]:
			var mine2: float = float(d.get(row[0]))
			var theirs2: float = float(ed.get(row[0])) if ed != null else 0.0
			_add_stat(out, String(row[1]), mine2, theirs2, "%.1f", equipped != null)
		if equipped != null and d.type == ItemData.Type.WEAPON and d.aspd_percent == 0.0 and ed.aspd_percent == 0.0:
			out.append(["ความเร็วโจมตี", "เท่าเดิม", UITheme.TEXT])
	else:
		if d.heal_hp != 0 or d.heal_hp_percent != 0.0:
			out.append(["ฟื้น HP", ("%d" % d.heal_hp) + ((" +%.0f%%" % d.heal_hp_percent) if d.heal_hp_percent != 0.0 else ""), UITheme.GOOD])
		if d.heal_sp != 0 or d.heal_sp_percent != 0.0:
			out.append(["ฟื้น SP", ("%d" % d.heal_sp) + ((" +%.0f%%" % d.heal_sp_percent) if d.heal_sp_percent != 0.0 else ""), UITheme.GOOD])
		if d.potion_cooldown > 0.0:
			out.append(["คูลดาวน์", "%.1f วินาที" % d.potion_cooldown, UITheme.TEXT])
		if d.buff_duration > 0.0:
			out.append(["ระยะเวลา", "%d วินาที" % int(d.buff_duration), UITheme.TEXT])
	return out


func _add_stat(out: Array, label: String, mine: float, theirs: float, fmt: String, compare: bool) -> void:
	if mine == 0.0 and theirs == 0.0:
		return
	if not compare:
		out.append([label, fmt % mine, UITheme.TEXT])
		return
	var diff := mine - theirs
	var text := "%s → %s" % [fmt % theirs, fmt % mine]
	var color := UITheme.TEXT
	if diff > 0.001:
		text += "  ▲ +" + (fmt % diff)
		color = UITheme.GOOD
	elif diff < -0.001:
		text += "  ▼ " + (fmt % diff)
		color = UITheme.BAD
	out.append([label, text, color])


func _row(left: String, right: String, color: Color, size: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := UITheme.make_label(left, size, UITheme.TEXT_DIM if right != "" else color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	row.add_child(l)
	if right != "":
		var r := UITheme.make_label(right, size, color)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(r)
	return row


func _chip(text: String, color: Color) -> Control:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(color, 0.1)
	s.border_color = Color(color, 0.55)
	s.set_border_width_all(1)
	s.set_corner_radius_all(9)
	s.content_margin_left = 7
	s.content_margin_right = 7
	p.add_theme_stylebox_override("panel", s)
	p.add_child(UITheme.make_label(text, 12, color))
	return p


# =========================================================
# วางหน้าต่าง (กลางจอ · ไม่เกิน WIN_MAX)
# =========================================================
func fit_to_content() -> void:
	_place_shop()
	# ขนาดขั้นต่ำของ Label ตัดบรรทัดคำนวณใหม่หลังจัดวางเฟรมแรก → วางซ้ำอีกครั้ง
	await get_tree().process_frame
	if is_instance_valid(self) and visible:
		_place_shop()


func _place_shop() -> void:
	if not is_inside_tree():
		return
	var vp := get_viewport_rect().size
	size = Vector2(minf(WIN_MAX.x, vp.x - 40.0), minf(WIN_MAX.y, vp.y - 60.0))
	position = ((vp - size) * 0.5).floor()


# =========================================================
# ขายขยะทั้งหมด (ระบบเดิม — เทสต์ shop_ui_test อ้างถึง)
# =========================================================
func junk_candidates() -> Array:
	var result: Array = []
	for i in range(PlayerState.inventory.size):
		var inst := PlayerState.inventory.get_slot(i)
		if inst == null: continue
		var data := inst.data()
		if data == null or not data.bulk_sell_junk or not data.sellable or data.type != ItemData.Type.MATERIAL or inst.sell_value() <= 0: continue
		var protected := false
		# Keep quest materials even if an item was later opted into junk by mistake.
		for quest in GameData.quests.values():
			for objective in quest.steps():
				if objective.kind == ObjectiveData.Kind.COLLECT and objective.target == inst.item_id:
					protected = true
		if not protected:
			result.append({"index":i, "instance":inst, "count":inst.count, "value":inst.sell_value()})
	return result

func _sell_junk() -> void:
	var entries := junk_candidates()
	if entries.is_empty(): return
	var count := 0
	var value := 0
	for entry in entries:
		count += int(entry.count)
		value += int(entry.value)
	if not await UI.ask("ขายขยะทั้งหมด", "ขายขยะ %d กอง รวม %d ชิ้น
ได้รับ %s z
เก็บอุปกรณ์ การ์ด ยา ของเควส และวัสดุสำคัญไว้" % [entries.size(), count, HUD._comma(value)], "ยืนยันขาย", "ยกเลิก"): return
	var current := junk_candidates()
	_bulk_selling = true
	for entry in entries:
		for fresh in current:
			if fresh.instance == entry.instance and fresh.count == entry.count and fresh.value == entry.value:
				PlayerState.sell_slot(int(fresh.index), int(fresh.count))
	_bulk_selling = false
	refresh()
