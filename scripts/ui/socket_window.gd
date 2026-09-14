## SocketWindow — หน้าต่าง "เจาะรูการ์ด" (คุยกับช่างตีเหล็ก) · รอบ 56
## หน้าตาเดียวกับหน้าตีบวก: ไอคอน · ชื่อ · จำนวนรู · กดเลือกแล้วดูเงื่อนไข
class_name SocketWindow
extends GameWindow

const ICON_SIZE := Vector2(30, 30)

var _normal: VBoxContainer
var _third: VBoxContainer
var _list: VBoxContainer
var _info: Label
var _punch_button: Button
var _result: Label
var _zeny_label: Label
var _selected_source := ""   # "inv:<index>" หรือ "eq:<slot>"


func _ready() -> void:
	window_title = "เจาะรูการ์ด"
	super._ready()
	custom_minimum_size = Vector2(680, 0)
	Events.inventory_changed.connect(refresh)
	Events.equipment_changed.connect(refresh)
	Events.zeny_changed.connect(func(_z): refresh())


func _build_content() -> void:
	var tabs := HBoxContainer.new()
	content.add_child(tabs)
	_normal = VBoxContainer.new()
	content.add_child(_normal)
	_third = preload("res://scripts/ui/third_socket_panel.gd").new()
	content.add_child(_third)
	_third.hide()
	for special in [false, true]:
		var tab := UITheme.make_button("รูที่ 3 • หลอมอาวุธ" if special else "เจาะรูพื้นฐาน")
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(func():
			_normal.visible = not special
			_third.visible = special
			refresh()
			fit_to_content())
		tabs.add_child(tab)
	var head := HBoxContainer.new()
	_normal.add_child(head)

	var title := UITheme.make_label("เลือกของสวมใส่ที่ยังไม่มีรู", 13, UITheme.TEXT_DIM)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)

	_zeny_label = UITheme.make_label("0 z", 15, Color("#ffe9a0"))
	head.add_child(_zeny_label)

	_normal.add_child(UITheme.separator())

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 210
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_normal.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)

	_normal.add_child(UITheme.separator())

	_info = UITheme.make_label("—", 13, UITheme.TEXT)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size.y = 108
	_normal.add_child(_info)

	_punch_button = UITheme.make_button("เจาะรู!", 130)
	_punch_button.disabled = true
	_punch_button.pressed.connect(_do_punch)
	_normal.add_child(_punch_button)

	_result = UITheme.make_label("", 14, UITheme.ACCENT)
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_normal.add_child(_result)


func _selected_instance() -> ItemInstance:
	if _selected_source.begins_with("inv:"):
		return PlayerState.inventory.get_slot(int(_selected_source.substr(4)))
	elif _selected_source.begins_with("eq:"):
		return PlayerState.equipment.get_item(int(_selected_source.substr(3)))
	return null


func _do_punch() -> void:
	var inst := _selected_instance()
	if inst == null:
		return

	var out := SocketSystem.try_punch(inst, PlayerState.inventory, PlayerState)
	_result.text = out.message
	_result.add_theme_color_override("font_color", UITheme.GOOD if out.success else UITheme.BAD)

	# ★ เจาะไม่ติด = ของหาย ★ เอาออกจากช่องที่มันอยู่
	if bool(out.get("destroyed", false)):
		if _selected_source.begins_with("inv:"):
			PlayerState.inventory.set_slot(int(_selected_source.substr(4)), null)
		elif _selected_source.begins_with("eq:"):
			PlayerState.equipment.unequip(int(_selected_source.substr(3)))
		_selected_source = ""

	PlayerState.refresh()
	refresh()


func refresh() -> void:
	if _third != null and _third.visible:
		_third.refresh()
		return
	if _list == null or not visible:
		return

	_zeny_label.text = "%s z" % HUD._comma(PlayerState.zeny)
	GameWindow.clear_container(_list)

	for slot in PlayerState.equipment.slots.keys():
		var eq_inst: ItemInstance = PlayerState.equipment.get_item(slot)
		if eq_inst == null or not SocketSystem.can_punch(eq_inst):
			continue
		_add_row(eq_inst, "eq:%d" % slot, "สวมอยู่")

	for i in range(PlayerState.inventory.size):
		var inst := PlayerState.inventory.get_slot(i)
		if inst == null or not SocketSystem.can_punch(inst):
			continue
		_add_row(inst, "inv:%d" % i, "")

	if _list.get_child_count() == 0:
		_list.add_child(UITheme.make_label(
			"ไม่มีของที่เจาะรูได้\n(ต้องเป็นของสวมใส่ที่ยังไม่มีรู · ทุกช่วงเลเวล)",
			13, UITheme.TEXT_DIM))

	_update_info()


func _add_row(inst: ItemInstance, source: String, tag: String) -> void:
	var selected := source == _selected_source

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.slot_style(selected))
	_list.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)

	var d := inst.data()

	var frame := PanelContainer.new()
	frame.custom_minimum_size = ICON_SIZE + Vector2(4, 4)
	frame.add_theme_stylebox_override("panel",
		UITheme.panel_style(Color("#0d1119"), UITheme.BORDER, 3))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(frame)

	var art := TextureRect.new()
	art.name = "SocketIcon"
	art.custom_minimum_size = ICON_SIZE
	art.texture = d.icon if d != null else null
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(art)

	var name_btn := Button.new()
	name_btn.name = "PickButton"
	name_btn.text = inst.display_name() + (("  (%s)" % tag) if tag != "" else "")
	name_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_btn.flat = true
	name_btn.clip_text = true
	name_btn.focus_mode = Control.FOCUS_NONE
	name_btn.tooltip_text = "กดเพื่อเลือกและดูรายละเอียด"
	name_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_btn.add_theme_font_size_override("font_size", 13)
	name_btn.add_theme_color_override("font_color",
		UITheme.ACCENT if selected else UITheme.TEXT)
	name_btn.add_theme_color_override("font_hover_color", UITheme.ACCENT)
	row.add_child(name_btn)

	# จำนวนรูที่จะได้ + เลเวลของไอเทม
	var n := SocketSystem.slots_gain(d)
	var lv := UITheme.make_label("Lv.%d · %d รู" % [d.required_level if d != null else 1, n], 13,
		Color("#ffe9a0") if n > 1 else UITheme.TEXT_DIM)
	lv.custom_minimum_size.x = 84
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lv.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lv)

	var src := source
	var this_inst := inst
	name_btn.pressed.connect(func():
		_selected_source = src
		_result.text = ""
		UI.show_item(this_inst, self, "เลือกไว้เจาะรูแล้ว")
		refresh()
	)


func _update_info() -> void:
	var inst := _selected_instance()
	if inst == null:
		_info.text = "ยังไม่ได้เลือกไอเทม\n\nเจาะได้เฉพาะของสวมใส่ที่ยัง \"ไม่มีรู\"\nของเลเวล 1-30 ใช้ %s x10 + 15,000z (โอกาส 70%%)\nของเลเวล 31 ขึ้นไป ใช้ %s x10 + 50,000z (โอกาส 60%%)\nของที่เจาะได้ 2 รู ใช้ของและเงินเท่าตัว · เจาะไม่ติดอุปกรณ์หลักยังอยู่" % [
			GameData.item_name(&"phracon"), GameData.item_name(&"emveretarcon")]
		_punch_button.disabled = true
		return

	var p := SocketSystem.preview(inst, PlayerState.inventory)
	if p.is_empty():
		_info.text = SocketSystem.reason_cannot_punch(inst)
		_punch_button.disabled = true
		return

	var lines: Array[String] = []
	lines.append("%s   ไม่มีรู → %d รู   (%s)" % [p.name, p.slots, p.tier_name])
	lines.append("โอกาสสำเร็จ: %.0f%%" % p.rate)
	lines.append("ค่าเจาะ: %s z (มี %s z)" % [HUD._comma(p.zeny), HUD._comma(PlayerState.zeny)])
	lines.append("วัตถุดิบ: %s x%d (มี %d)" % [p.ore_name, p.ore_count, p.have_ore])
	if bool(p.need_duplicate):
		var ok_dup: bool = int(p.dup_index) >= 0
		lines.append("ไอเทมชิ้นที่สอง: %s x1 (%s)" % [
			GameData.item_name(inst.item_id), "มีแล้ว" if ok_dup else "ยังไม่มี"])
	if not bool(p.destroy_on_fail):
		lines.append("อุปกรณ์หลักไม่แตก • เสียเฉพาะเงินและวัตถุดิบเมื่อไม่สำเร็จ")
	if bool(p.destroy_on_fail):
		lines.append("⚠ เจาะไม่ติด = ของชิ้นนี้หายไปเลย (วัตถุดิบและเงินก็เสียด้วย)")

	var chk := SocketSystem.check(inst, PlayerState.inventory, PlayerState)
	if not bool(chk.ok):
		lines.append("✗ %s" % String(chk.message))

	_info.text = "\n".join(lines)
	_punch_button.disabled = not bool(chk.ok)


func show_window() -> void:
	super.show_window()
	await get_tree().process_frame
	reset_size()
	position = (get_viewport_rect().size - size) * 0.5
