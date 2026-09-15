## ShopWindow — ร้านค้า (เปิดโดยคุยกับ NPC ประเภท SHOP)
class_name ShopWindow
extends GameWindow

var _tab_buy: Button
var _tab_sell: Button
var _list: VBoxContainer
var _zeny_label: Label
var _bulk_button: Button
var _bulk_selling := false
var _mode_buy := true
var _shop_items: Array = []


func _ready() -> void:
	window_title = "ร้านค้า"
	super._ready()
	custom_minimum_size = Vector2(760, 480)
	title_label.add_theme_font_size_override("font_size", 24)
	for child in _bar.get_child(0).get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(52, 52)
			child.add_theme_font_size_override("font_size", 24)
	get_viewport().size_changed.connect(_place_shop)
	Events.zeny_changed.connect(func(_z): refresh())
	Events.inventory_changed.connect(refresh)


func open_shop(item_ids: Array) -> void:
	_shop_items = item_ids
	_mode_buy = true
	show_window()


func _build_content() -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	content.add_child(top)

	_tab_buy = UITheme.make_button("ซื้อสินค้า", 170)
	_tab_buy.pressed.connect(func(): _set_mode(true))
	top.add_child(_tab_buy)

	_tab_sell = UITheme.make_button("ขายของในกระเป๋า", 210)
	_tab_sell.pressed.connect(func(): _set_mode(false))
	top.add_child(_tab_sell)
	for button in [_tab_buy, _tab_sell]:
		button.custom_minimum_size.y = 56
		button.add_theme_font_size_override("font_size", 24)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)

	_zeny_label = UITheme.make_label("0 z", 22, Color("#ffe9a0"))
	top.add_child(_zeny_label)

	content.add_child(UITheme.separator())

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 160
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)
	_bulk_button = UITheme.make_button("ขายขยะทั้งหมด")
	_bulk_button.custom_minimum_size.y = 56
	_bulk_button.add_theme_font_size_override("font_size", 22)
	_bulk_button.pressed.connect(_sell_junk)
	content.add_child(_bulk_button)


func _set_mode(buy: bool) -> void:
	_mode_buy = buy
	refresh()


func refresh() -> void:
	if _list == null or not visible or _bulk_selling:
		return

	_zeny_label.text = "%s z • %d/%d ช่อง" % [HUD._comma(PlayerState.zeny), PlayerState.inventory.used_slots(), PlayerState.inventory.size]
	_tab_buy.add_theme_color_override("font_color", UITheme.ACCENT if _mode_buy else UITheme.TEXT_DIM)
	_tab_sell.add_theme_color_override("font_color", UITheme.TEXT_DIM if _mode_buy else UITheme.ACCENT)

	_bulk_button.visible = not _mode_buy
	_bulk_button.disabled = junk_candidates().is_empty()
	GameWindow.clear_container(_list)

	if _mode_buy:
		_build_buy_list()
	else:
		_build_sell_list()


func _build_buy_list() -> void:
	for id in _shop_items:
		var d := GameData.get_item(StringName(id))
		if d == null:
			continue
		var row := _make_row(d.display_name, d.icon, "%d z" % d.buy_price, d.description)
		# กดที่ชื่อของ = ดูรายละเอียด
		var dd := d
		_bind_info(row, func(): UI.show_item_data(dd, self, "ราคาซื้อ : %d z" % dd.buy_price))

		var buy1 := _action_button("ซื้อ 1")
		buy1.disabled = PlayerState.zeny < d.buy_price
		var iid := d.id
		buy1.pressed.connect(func(): PlayerState.buy(iid, 1))
		row.add_child(buy1)

		if d.is_stackable():
			var buy10 := _action_button("ซื้อ 10")
			buy10.disabled = PlayerState.zeny < d.buy_price * 10
			buy10.pressed.connect(func(): PlayerState.buy(iid, 10))
			row.add_child(buy10)

		_list.add_child(row)


func _build_sell_list() -> void:
	var inv := PlayerState.inventory
	var any := false

	for i in range(inv.size):
		var inst := inv.get_slot(i)
		if inst == null:
			continue
		var d := inst.data()
		if d == null or d.type == ItemData.Type.QUEST or not d.sellable or inst.sell_value() <= 0:
			continue

		any = true
		var row := _make_row(
			"%s x%d" % [inst.display_name(), inst.count],
			d.icon,
			"%s z/ชิ้น" % HUD._comma(int(d.sell_price * (1.0 + inst.refine * 0.25))),
			d.description
		)
		# กดที่ชื่อของ = ดูรายละเอียด
		var this_inst := inst
		_bind_info(row, func(): UI.show_item(this_inst, self,
			"ราคาขาย : %d z" % this_inst.sell_value()))

		var index := i
		var sell1 := _action_button("ขาย 1")
		sell1.pressed.connect(func(): PlayerState.sell_slot(index, 1))
		row.add_child(sell1)

		if inst.count > 1:
			var sell_all := _action_button("ขายทั้งกอง")
			var amount := inst.count
			sell_all.pressed.connect(func(): PlayerState.sell_slot(index, amount))
			row.add_child(sell_all)

		_list.add_child(row)

	if not any:
		_list.add_child(UITheme.make_label("ไม่มีของให้ขาย", 20, UITheme.TEXT_DIM))


## ทำให้กดที่แถว (รูป/ชื่อ/ราคา) แล้วเปิดกล่องรายละเอียด
func _bind_info(row: HBoxContainer, action: Callable) -> void:
	var btn := row.get_node_or_null("InfoButton") as Button
	if btn != null:
		btn.pressed.connect(action)


func _make_row(title: String, icon: Texture2D, price: String, tooltip: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size.y = 66
	row.tooltip_text = tooltip

	if icon != null:
		var tex := TextureRect.new()
		tex.texture = icon
		tex.custom_minimum_size = Vector2(52, 52)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(tex)

	var name_btn := Button.new()
	name_btn.name = "InfoButton"
	name_btn.text = title
	name_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_btn.flat = true
	name_btn.clip_text = true
	name_btn.focus_mode = Control.FOCUS_NONE
	name_btn.tooltip_text = "กดเพื่อดูรายละเอียด"
	name_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_btn.add_theme_font_size_override("font_size", 20)
	name_btn.add_theme_color_override("font_color", UITheme.TEXT)
	name_btn.add_theme_color_override("font_hover_color", UITheme.ACCENT)
	row.add_child(name_btn)

	var price_label := UITheme.make_label(price, 20, Color("#ffe9a0"))
	price_label.custom_minimum_size.x = 140
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(price_label)

	return row


func fit_to_content() -> void:
	_place_shop()

func _place_shop() -> void:
	if not is_inside_tree(): return
	var viewport_size := get_viewport_rect().size
	size = Vector2(minf(1100.0, viewport_size.x - 64.0), viewport_size.y - 80.0)
	position = (viewport_size - size) * 0.5

func _action_button(text: String) -> Button:
	var button := UITheme.make_button(text, 126)
	button.custom_minimum_size.y = 54
	button.add_theme_font_size_override("font_size", 20)
	return button

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
