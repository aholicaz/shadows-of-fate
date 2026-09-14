extends VBoxContainer
const Forge = preload("res://scripts/core/third_socket.gd")
var main: ItemInstance
var donors: Array = []
var _list: VBoxContainer
var _details: VBoxContainer
var _accept: Button
var _button: Button
var _result: Label
var _wallet: Label
var _working := false

func _ready() -> void:
	_wallet = UITheme.make_label("", 14, UITheme.ACCENT)
	add_child(_wallet)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	add_child(body)
	_list = _column(body, 245)
	_details = _column(body, 365)
	_accept = UITheme.make_button("")
	_accept.toggle_mode = true
	_accept.custom_minimum_size.y = 34
	_accept.add_theme_font_size_override("font_size", 12)
	_accept.toggled.connect(func(_on): _update_button())
	add_child(_accept)
	_button = UITheme.make_button("เจาะรูที่ 3")
	_button.custom_minimum_size.y = 42
	_button.pressed.connect(_attempt)
	add_child(_button)
	add_child(_label("อาวุธหลักไม่แตก • ตีบวก ค่าสุ่ม และการ์ดอยู่ครบ", UITheme.GOOD))
	_result = _label("", UITheme.ACCENT)
	add_child(_result)
	var stones := HBoxContainer.new()
	add_child(stones)
	for i in range(3):
		var btn := UITheme.make_button("รวมเศษระดับ %d (10 → 1)" % (i + 1))
		btn.add_theme_font_size_override("font_size", 12)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func():
			_working = true
			_result.text = Forge.combine(i, PlayerState.inventory)
			_working = false
			refresh())
		stones.add_child(btn)

func _column(parent: Control, width: float) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(width, 310)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 7)
	scroll.add_child(box)
	return box

func _label(value: String, color: Color = UITheme.TEXT) -> Label:
	var label := UITheme.make_label(value, 13, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _item_row(inst: ItemInstance, text: String, picked: bool, callback: Callable) -> Control:
	var row := HBoxContainer.new()
	var art := TextureRect.new()
	art.texture = inst.data().icon
	art.custom_minimum_size = Vector2(36, 42)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(art)
	var button := Button.new()
	button.text = ("✓ " if picked else "") + text
	button.tooltip_text = inst.display_name()
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 44
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(callback)
	row.add_child(button)
	return row

func refresh() -> void:
	if _list == null or _working: return
	var inv := PlayerState.inventory
	_wallet.text = "รูที่ 3 • อาวุธ Lv.50+     ซีนี: %s" % HUD._comma(PlayerState.zeny)
	if main != null and not inv.slots.has(main) and not PlayerState.equipment.slots.values().has(main):
		main = null
		donors.clear()
		_accept.set_pressed_no_signal(false)
	for donor in donors.duplicate():
		if main == null or not inv.slots.has(donor) or not Forge.donor_ok(main, donor):
			donors.erase(donor)
			_accept.set_pressed_no_signal(false)
	GameWindow.clear_container(_list)
	GameWindow.clear_container(_details)
	_list.add_child(_label("1. เลือกอาวุธหลัก • เก็บไว้", UITheme.ACCENT))
	var items: Array = PlayerState.equipment.slots.values().duplicate()
	items.append_array(inv.slots)
	for inst in items:
		if inst == null or inst.data() == null or inst.data().slot != ItemData.Slot.WEAPON or inst.data().required_level < 50: continue
		var item: ItemInstance = inst
		_list.add_child(_item_row(item, item.display_name(), item == main, func():
			main = item
			donors.clear()
			_accept.set_pressed_no_signal(false)
			_result.text = ""
			refresh()))
	if _list.get_child_count() == 1: _list.add_child(_label("ยังไม่มีอาวุธเลเวล 50 ขึ้นไป", UITheme.TEXT_DIM))
	if main == null:
		_details.add_child(_label("ใช้ดาบชื่อเดียวกันรวม 3 เล่ม\nเล่มหลัก 1 + วัตถุดิบ 2\n\nโอกาส 40% → 60% → 80% → 100%\nความคืบหน้าบันทึกกับดาบแต่ละเล่ม\n\nอาวุธหลักไม่แตก ตีบวก ค่าสุ่ม และการ์ดอยู่ครบ\n\nหินระดับ 1: อาวุธ Lv.50–69\nหินระดับ 2: Lv.70–89\nหินระดับ 3: Lv.90 ขึ้นไป\nบอสที่ดรอป: เศษ 1 ชิ้นแน่นอน + ลุ้นหินเต็ม 10%"))
		_update_button()
		return
	var info := UITheme.make_button(main.display_name() + " • ดูรายละเอียด")
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.pressed.connect(func(): UI.show_item(main, self))
	_details.add_child(info)
	var lock := UITheme.make_button("ปลดล็อกวัตถุดิบ" if main.socket_locked else "ล็อก: กันเล่มนี้จากการใช้เป็นวัตถุดิบ")
	lock.toggle_mode = true
	lock.add_theme_font_size_override("font_size", 12)
	lock.set_pressed_no_signal(main.socket_locked)
	lock.toggled.connect(func(on):
		main.socket_locked = on
		lock.text = "ปลดล็อกวัตถุดิบ" if on else "ล็อก: กันเล่มนี้จากการใช้เป็นวัตถุดิบ")
	_details.add_child(lock)
	var why := Forge.reason(main)
	if not why.is_empty():
		_details.add_child(_label(why, UITheme.ACCENT))
		_update_button()
		return
	var req := Forge.requirements(main)
	_details.add_child(_label("2 รู → 3 รู   •   ครั้งที่ %d / 4\nโอกาสสำเร็จ %d%%" % [req.attempt, req.rate], UITheme.GOOD))
	_details.add_child(_label("ใช้ %s ซีนี\n%s ×1 (มี %d)\nเศษระดับนี้: %d / 10" % [HUD._comma(req.zeny), GameData.item_name(req.stone), inv.count_of(req.stone), inv.count_of(req.shard)]))
	_details.add_child(_label("2. เลือกวัตถุดิบที่จะเสีย (%d / 2)" % donors.size(), UITheme.ACCENT))
	var count := 0
	for inst in inv.slots:
		if not Forge.donor_ok(main, inst): continue
		var item: ItemInstance = inst
		count += 1
		_details.add_child(_item_row(item, item.display_name(), donors.has(item), func():
			if donors.has(item): donors.erase(item)
			elif donors.size() < 2: donors.append(item)
			_accept.set_pressed_no_signal(false)
			refresh()))
	if count < 2: _details.add_child(_label("ต้องหาเล่มชื่อเดียวกันเพิ่ม • ชิ้นที่มีการ์ด ล็อกไว้ หรือเคยเจาะพลาดจะไม่แสดง", UITheme.TEXT_DIM))
	var error := Forge.check(main, donors, inv, PlayerState)
	if not error.is_empty(): _details.add_child(_label(error, UITheme.BAD))
	_update_button()

func _update_button() -> void:
	_accept.text = ("✓ ยืนยันแล้ว" if _accept.button_pressed else "กดยืนยัน") + " • เสียวัตถุดิบ 2 เล่ม หิน และซีนี แม้ไม่สำเร็จ"
	_button.disabled = _working or not _accept.button_pressed or not Forge.check(main, donors, PlayerState.inventory, PlayerState).is_empty()

func _attempt() -> void:
	if _button.disabled: return
	_working = true
	_button.disabled = true
	var result := Forge.attempt(main, donors.duplicate(), PlayerState.inventory, PlayerState)
	_result.text = result.message
	_result.add_theme_color_override("font_color", UITheme.GOOD if result.success else UITheme.ACCENT)
	donors.clear()
	_accept.set_pressed_no_signal(false)
	_working = false
	PlayerState.refresh()
	refresh()
