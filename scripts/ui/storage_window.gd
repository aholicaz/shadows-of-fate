## StorageWindow — ★ รอบ 123 ★ คลังแบบ B: กริดช่องสี่เหลี่ยม ซ้าย = คลัง (8 คอลัมน์) · กลาง = รายละเอียด + ปุ่มฝาก/ถอน · ขวา = กระเป๋า (6 คอลัมน์)
## เปิดจากเสาวาปในเมือง หรือ NPC ที่ติ๊ก Has Storage (Events.storage_opened)
## การใช้: คลิกช่อง = เลือก (แผงกลางโชว์ค่าพลัง) → ปุ่ม ◀ ฝาก / ถอน ▶ / ย้าย 1 / ระบุจำนวน
##         ดับเบิลคลิก = ย้ายทั้งกองทันที · คลิกขวา = ย้าย 1 ชิ้น · ลากข้ามฝั่ง = ย้ายทั้งกอง · ลากในฝั่งเดียวกัน = สลับช่อง
## ของสวมใส่ย้ายทั้งชิ้นพร้อมตีบวก/การ์ด (PlayerState.storage_deposit/withdraw) · ของเควสฝากไม่ได้
class_name StorageWindow
extends GameWindow

const STORAGE_COLUMNS := 8
const BAG_COLUMNS := 6
const SLOT_SIZE := Vector2(58, 58)
const GRID_SEP := 6
const DOUBLE_CLICK_SEC := 0.35

const SIDE_STORAGE := 0
const SIDE_BAG := 1

var _storage_slots: Array = []   # DragSlot
var _bag_slots: Array = []
var _storage_caption: Label
var _bag_caption: Label
var _detail_icon: TextureRect
var _detail_name: Label
var _detail_text: RichTextLabel
var _btn_deposit: Button
var _btn_withdraw: Button
var _btn_one: Button
var _btn_amount: Button
var _amount_input: LineEdit
var _btn_cards: Button
var _btn_sort_storage: Button
var _btn_sort_bag: Button
var _zeny_bag: Label
var _zeny_storage: Label
var _zeny_input: LineEdit

var _sel_side := -1
var _sel_index := -1
var _last_click_side := -1
var _last_click_index := -1
var _last_click_time := 0.0
var _busy := false


func _ready() -> void:
	window_title = "คลัง — ฝากไว้กับธอร์ หยิบได้ทุกเมือง"
	super._ready()
	title_label.add_theme_font_size_override("font_size", 18)
	get_viewport().size_changed.connect(_place)
	Events.zeny_changed.connect(func(_z): refresh())
	Events.inventory_changed.connect(refresh)


# =========================================================
# สร้างหน้าตา
# =========================================================
func _build_content() -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(columns)

	# ---------- ซ้าย: คลัง ----------
	var left := _pane()
	columns.add_child(left)
	_storage_caption = _pane_caption(left, "คลัง")
	_storage_slots = _make_grid(left, PlayerState.STORAGE_SIZE, STORAGE_COLUMNS, SIDE_STORAGE)

	# ---------- กลาง: รายละเอียด + ปุ่ม ----------
	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 6)
	mid.custom_minimum_size.x = 240
	columns.add_child(mid)

	var detail := PanelContainer.new()
	detail.add_theme_stylebox_override("panel", InventoryWindow._style(InventoryWindow.C_INNER, UITheme.BORDER_SOFT, 8, 8))
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_child(detail)
	var dbox := VBoxContainer.new()
	dbox.add_theme_constant_override("separation", 4)
	detail.add_child(dbox)
	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = SLOT_SIZE
	icon_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_frame.add_theme_stylebox_override("panel", UITheme.slot_style(true))
	dbox.add_child(icon_frame)
	_detail_icon = TextureRect.new()
	_detail_icon.custom_minimum_size = SLOT_SIZE - Vector2(16, 16)
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon_frame.add_child(_detail_icon)
	_detail_name = UITheme.make_label("เลือกช่องเพื่อดูรายละเอียด", 14, UITheme.GOLD_BRIGHT)
	_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dbox.add_child(_detail_name)
	_detail_text = RichTextLabel.new()
	_detail_text.bbcode_enabled = true
	_detail_text.fit_content = false          # ★ ห้ามยืดตามเนื้อหา — ไม่งั้นหน้าต่างล้นจอ (รอบ 124)
	_detail_text.scroll_active = true
	_detail_text.custom_minimum_size = Vector2(216, 90)
	_detail_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_text.add_theme_font_size_override("normal_font_size", 12)
	_detail_text.add_theme_color_override("default_color", UITheme.TEXT)
	dbox.add_child(_detail_text)

	_btn_deposit = _mid_button("◀  ฝากเข้าคลัง", true)
	_btn_deposit.pressed.connect(func(): _move_selected(-1))
	mid.add_child(_btn_deposit)
	_btn_withdraw = _mid_button("ถอนออกมา  ▶", true)
	_btn_withdraw.pressed.connect(func(): _move_selected(-1))
	mid.add_child(_btn_withdraw)
	# ★ รอบ 124 ★ รวม "ย้าย 1" + ช่องจำนวน + "ตามจำนวน" ไว้แถวเดียว (ลดความสูงคอลัมน์กลาง ไม่ให้ล้นจอ)
	var amount_row := HBoxContainer.new()
	amount_row.add_theme_constant_override("separation", 4)
	mid.add_child(amount_row)
	_btn_one = _mid_button("ย้าย 1")
	_btn_one.pressed.connect(func(): _move_selected(1))
	amount_row.add_child(_btn_one)
	_amount_input = LineEdit.new()
	_amount_input.placeholder_text = "จำนวน"
	_amount_input.custom_minimum_size = Vector2(58, 30)
	_amount_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_amount_input.add_theme_font_size_override("font_size", 14)
	amount_row.add_child(_amount_input)
	_btn_amount = _mid_button("ตามจำนวน")
	_btn_amount.pressed.connect(func(): _move_selected(int(_amount_input.text.strip_edges().to_int())))
	amount_row.add_child(_btn_amount)

	mid.add_child(UITheme.separator())
	_btn_cards = _mid_button("ฝากการ์ดทั้งหมด")
	_btn_cards.pressed.connect(_deposit_all_cards)
	mid.add_child(_btn_cards)
	var sort_row := HBoxContainer.new()
	sort_row.add_theme_constant_override("separation", 4)
	mid.add_child(sort_row)
	_btn_sort_storage = _mid_button("เรียงคลัง")
	_btn_sort_storage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_sort_storage.pressed.connect(func(): _sort(SIDE_STORAGE))
	sort_row.add_child(_btn_sort_storage)
	_btn_sort_bag = _mid_button("เรียงกระเป๋า")
	_btn_sort_bag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_sort_bag.pressed.connect(func(): _sort(SIDE_BAG))
	sort_row.add_child(_btn_sort_bag)

	# ---------- ขวา: กระเป๋า ----------
	var right := _pane()
	columns.add_child(right)
	_bag_caption = _pane_caption(right, "กระเป๋า")
	_bag_slots = _make_grid(right, PlayerState.INVENTORY_SIZE, BAG_COLUMNS, SIDE_BAG)

	# ---------- ล่าง: ซีนี ----------
	content.add_child(UITheme.separator())
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 8)
	content.add_child(foot)
	_zeny_bag = _zeny_chip(foot)
	_zeny_input = LineEdit.new()
	_zeny_input.placeholder_text = "จำนวนซีนี"
	_zeny_input.custom_minimum_size = Vector2(130, 34)
	_zeny_input.add_theme_font_size_override("font_size", 15)
	foot.add_child(_zeny_input)
	var dep := _mid_button("ฝากเงิน")
	dep.pressed.connect(func(): _move_zeny(true, false))
	foot.add_child(dep)
	var wd := _mid_button("ถอนเงิน")
	wd.pressed.connect(func(): _move_zeny(false, false))
	foot.add_child(wd)
	var dep_all := _mid_button("ฝากทั้งหมด")
	dep_all.pressed.connect(func(): _move_zeny(true, true))
	foot.add_child(dep_all)
	var wd_all := _mid_button("ถอนทั้งหมด")
	wd_all.pressed.connect(func(): _move_zeny(false, true))
	foot.add_child(wd_all)
	_zeny_storage = _zeny_chip(foot)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(spacer)
	var hint := UITheme.make_label("ดับเบิลคลิก = ย้ายทั้งกอง · คลิกขวา = 1 ชิ้น · ลากข้ามฝั่งได้", 11, UITheme.TEXT_DIM)
	foot.add_child(hint)


func _pane() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", InventoryWindow._style(InventoryWindow.C_INNER, UITheme.BORDER_SOFT, 8, 8))
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return p


func _pane_caption(pane: PanelContainer, title: String) -> Label:
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 6)
	pane.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var t := UITheme.make_label(title, 15, UITheme.GOLD_BRIGHT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var cap := UITheme.make_label("0 / 0", 12, UITheme.TEXT_DIM)
	head.add_child(cap)
	return cap


func _make_grid(pane: PanelContainer, count: int, columns: int, side: int) -> Array:
	var box: VBoxContainer = pane.get_node("Box")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# ★ รอบ 124 ★ สูงขั้นต่ำแค่ 5 แถว ที่เหลือยืดตามหน้าต่าง (เลื่อนได้) — เดิม 7 แถว + แผงกลางยืด ทำให้ล้นจอ
	scroll.custom_minimum_size = Vector2(columns * (SLOT_SIZE.x + GRID_SEP) + 14, 4 * (SLOT_SIZE.y + GRID_SEP))
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", GRID_SEP)
	grid.add_theme_constant_override("v_separation", GRID_SEP)
	scroll.add_child(grid)
	var slots: Array = []
	for i in range(count):
		var btn := DragSlot.new()
		btn.kind = "storage" if side == SIDE_STORAGE else "storage_bag"
		btn.slot_index = i
		btn.custom_minimum_size = SLOT_SIZE
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_stylebox_override("normal", UITheme.slot_style(false))
		btn.add_theme_stylebox_override("hover", UITheme.slot_style(true))
		btn.add_theme_stylebox_override("pressed", UITheme.slot_style(true))
		var index := i
		btn.drag_icon_func = func() -> Texture2D:
			return _icon_of(_inv_of(side).get_slot(index))
		btn.can_drop_func = func(data: Dictionary, _t: DragSlot) -> bool:
			var k := String(data.get("kind", ""))
			return k == "storage" or k == "storage_bag"
		btn.drop_func = func(data: Dictionary, _t: DragSlot) -> bool:
			return _on_drop(data, side, index)
		btn.pressed.connect(func(): _on_slot_pressed(side, index))
		btn.gui_input.connect(func(ev: InputEvent): _on_slot_gui_input(ev, side, index))
		UITheme.make_slot_icon(btn, 7.0)
		grid.add_child(btn)
		slots.append(btn)
	return slots


func _mid_button(text: String, gold: bool = false) -> Button:
	var b := UITheme.make_button(text)
	b.custom_minimum_size.y = 30
	b.add_theme_font_size_override("font_size", 14)
	# ★ รอบ 124 ★ ปุ่มมาตรฐานสูง 54 (ขอบใน 14) — 5 แถวรวมกันดันหน้าต่างล้นจอ → ลดขอบในเหลือ 5
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := b.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		sb.content_margin_top = 5
		sb.content_margin_bottom = 5
		b.add_theme_stylebox_override(state, sb)
	if gold:
		b.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
	return b


func _zeny_chip(parent: Control) -> Label:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", InventoryWindow._style(UITheme.PANEL, UITheme.ACCENT, 6, 6))
	parent.add_child(p)
	var l := UITheme.make_label("", 14, UITheme.GOLD_BRIGHT)
	p.add_child(l)
	return l


# =========================================================
# ข้อมูล
# =========================================================
func _inv_of(side: int) -> Inventory:
	return PlayerState.storage if side == SIDE_STORAGE else PlayerState.inventory


static func _icon_of(inst: ItemInstance) -> Texture2D:
	if inst == null:
		return null
	var d := inst.data()
	if d == null:
		return null
	if d.icon != null:
		return d.icon
	if d is CardData:
		return CardView.card_texture(d as CardData)
	return null


func refresh() -> void:
	if _storage_slots.is_empty() or not visible or _busy:
		return
	_refresh_grid(_storage_slots, PlayerState.storage, SIDE_STORAGE)
	_refresh_grid(_bag_slots, PlayerState.inventory, SIDE_BAG)
	_storage_caption.text = "%d / %d ช่อง" % [PlayerState.storage.used_slots(), PlayerState.storage.size]
	_bag_caption.text = "%d / %d ช่อง" % [PlayerState.inventory.used_slots(), PlayerState.inventory.size]
	_zeny_bag.text = "กระเป๋า %s z" % HUD._comma(PlayerState.zeny)
	_zeny_storage.text = "คลัง %s z" % HUD._comma(PlayerState.storage_zeny)
	# ช่องที่เลือกยังมีของอยู่ไหม
	if _sel_side >= 0 and _inv_of(_sel_side).get_slot(_sel_index) == null:
		_clear_selection()
	_refresh_detail()


func _refresh_grid(slots: Array, inv: Inventory, side: int) -> void:
	for i in range(slots.size()):
		var btn: DragSlot = slots[i]
		var inst := inv.get_slot(i)
		var art: TextureRect = btn.get_node("SlotIcon")
		var cnt: Label = btn.get_node("SlotCount")
		art.texture = _icon_of(inst)
		cnt.text = str(inst.count) if inst != null and inst.count > 1 else ""
		btn.tooltip_text = inst.display_name() if inst != null else ""
		var selected := side == _sel_side and i == _sel_index
		btn.add_theme_stylebox_override("normal", UITheme.slot_style(selected))


func _refresh_detail() -> void:
	var inst: ItemInstance = _inv_of(_sel_side).get_slot(_sel_index) if _sel_side >= 0 else null
	var has := inst != null
	_detail_icon.texture = _icon_of(inst)
	_detail_name.text = ("%s x%d" % [inst.display_name(), inst.count]) if has else "เลือกช่องเพื่อดูรายละเอียด"
	_detail_text.text = ItemInfoPopup.describe(inst.data(), inst) if has else ""
	_btn_deposit.visible = not has or _sel_side == SIDE_BAG
	_btn_withdraw.visible = has and _sel_side == SIDE_STORAGE
	_btn_deposit.disabled = not has
	_btn_withdraw.disabled = not has
	_btn_one.disabled = not has or inst.count <= 1
	_btn_amount.disabled = not has or inst.count <= 1
	_btn_cards.disabled = _card_slots_in_bag().is_empty()


# =========================================================
# การกระทำ
# =========================================================
func _on_slot_pressed(side: int, index: int) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var is_double := side == _last_click_side and index == _last_click_index and now - _last_click_time < DOUBLE_CLICK_SEC
	_last_click_side = side
	_last_click_index = index
	_last_click_time = now
	var inst := _inv_of(side).get_slot(index)
	if inst == null:
		_clear_selection()
		refresh()
		return
	_sel_side = side
	_sel_index = index
	if is_double:
		_move(side, index, inst.count)
		_last_click_time = 0.0
		return
	refresh()


func _on_slot_gui_input(ev: InputEvent, side: int, index: int) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
		var inst := _inv_of(side).get_slot(index)
		if inst != null:
			_sel_side = side
			_sel_index = index
			_move(side, index, 1)


## ย้ายช่องที่เลือก — count = -1 คือทั้งกอง
func _move_selected(count: int) -> void:
	if _sel_side < 0:
		return
	var inst := _inv_of(_sel_side).get_slot(_sel_index)
	if inst == null:
		return
	if count <= 0 and count != -1:
		Events.say("กรอกจำนวนก่อน")
		return
	_move(_sel_side, _sel_index, inst.count if count == -1 else mini(count, inst.count))


func _move(side: int, index: int, count: int) -> void:
	var ok := false
	if side == SIDE_BAG:
		ok = PlayerState.storage_deposit(index, count)
	else:
		ok = PlayerState.storage_withdraw(index, count)
	if ok and _inv_of(side).get_slot(index) == null:
		_clear_selection()
	refresh()


## ลากวาง: ข้ามฝั่ง = ย้ายทั้งกอง · ฝั่งเดียวกัน = สลับช่อง
func _on_drop(data: Dictionary, target_side: int, target_index: int) -> bool:
	var from_side := SIDE_STORAGE if String(data.get("kind", "")) == "storage" else SIDE_BAG
	var from_index := int(data.get("slot", -1))
	if from_index < 0:
		return false
	if from_side == target_side:
		if from_index != target_index:
			_inv_of(from_side).swap(from_index, target_index)
			refresh()
		return true
	var inst := _inv_of(from_side).get_slot(from_index)
	if inst == null:
		return false
	_move(from_side, from_index, inst.count)
	return true


func _move_zeny(deposit: bool, all: bool) -> void:
	var amount: int
	if all:
		amount = PlayerState.zeny if deposit else PlayerState.storage_zeny
	else:
		amount = int(_zeny_input.text.strip_edges().replace(",", "").to_int())
	if amount <= 0:
		Events.say("กรอกจำนวนซีนีก่อน")
		return
	var ok: bool = PlayerState.storage_deposit_zeny(amount) if deposit else PlayerState.storage_withdraw_zeny(amount)
	if not ok:
		Events.say("ซีนีไม่พอ")
	refresh()


func _card_slots_in_bag() -> Array:
	var out: Array = []
	for i in range(PlayerState.inventory.size):
		var inst := PlayerState.inventory.get_slot(i)
		if inst != null and inst.data() != null and inst.data().is_card():
			out.append(i)
	return out


func _deposit_all_cards() -> void:
	var slots := _card_slots_in_bag()
	if slots.is_empty():
		return
	_busy = true
	slots.reverse()
	for i in slots:
		var inst := PlayerState.inventory.get_slot(i)
		if inst == null:
			continue
		if not PlayerState.storage_deposit(i, inst.count):
			break   # คลังเต็ม
	_busy = false
	_clear_selection()
	refresh()


func _clear_selection() -> void:
	_sel_side = -1
	_sel_index = -1


func _sort(side: int) -> void:
	_inv_of(side).sort_items()
	_clear_selection()
	refresh()


# =========================================================
# ขนาด/ตำแหน่ง
# =========================================================
func show_window() -> void:
	_clear_selection()
	super.show_window()
	_place()
	# ★ รอบ 163 ★ เฟรมแรกขนาดขั้นต่ำของข้อความตัดบรรทัดยังไม่นิ่ง → หน้าต่างโตเกินจอ (สูง 978) → วางซ้ำ
	for i in 2:
		await get_tree().process_frame
		if not is_instance_valid(self) or not visible:
			return
		_place()


func fit_to_content() -> void:
	_place()


func _place() -> void:
	if not is_inside_tree():
		return
	var viewport_size := get_viewport_rect().size
	# ★ รอบ 124 ★ กว้าง ≤ 1320 · สูง ≤ 680 และไม่เกินจอ (ทุกส่วนข้างในเลื่อน/ยืดได้ จึงย่อลงมาได้)
	size = Vector2(minf(1320.0, viewport_size.x - 40.0), minf(680.0, viewport_size.y - 40.0))
	reset_size()   # ★ รอบ 163 ★ หดกลับก่อน แล้วค่อยตั้งขนาดใหม่ (Container ไม่หดเอง)
	size = Vector2(minf(1320.0, viewport_size.x - 40.0), minf(680.0, viewport_size.y - 40.0))
	position = ((viewport_size - size) * 0.5).floor()


func shell_hints() -> Array:
	return [["Esc", "ปิด"]]
