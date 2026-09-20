extends Control

signal chosen(destination: StringName)
var targets: Array = []
var selected: StringName = &""
var list: VBoxContainer
var details: Label
var travel: Button
var finished := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 240
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 100
	panel.offset_right = -100
	panel.offset_top = 45
	panel.offset_bottom = -45
	panel.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.BG, UITheme.ACCENT, 4, 1, 20))
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	column.add_child(UITheme.make_label("เสาวาป · เลือกปลายทาง", 28, UITheme.TEXT))
	column.add_child(UITheme.make_label("เงินที่มี %s z · เลือกสถานที่แล้วกดเดินทาง" % HUD._comma(PlayerState.zeny), 20, UITheme.TEXT))
	var search := LineEdit.new()
	search.placeholder_text = "ค้นหาชื่อแมพ..."
	search.custom_minimum_size.y = 44
	search.add_theme_font_size_override("font_size", 20)
	column.add_child(search)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	details = UITheme.make_label("เลือกปลายทางจากรายการ", 20, UITheme.TEXT)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(details)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	var close := UITheme.make_button("กลับ / ยกเลิก")
	close.custom_minimum_size = Vector2(180, 52)
	close.pressed.connect(func(): finish(&""))
	actions.add_child(close)
	travel = UITheme.make_button("เดินทาง")
	travel.custom_minimum_size.y = 52
	travel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	travel.disabled = true
	travel.pressed.connect(func(): finish(selected))
	actions.add_child(travel)
	search.text_changed.connect(refresh)
	refresh("")

func refresh(query: String) -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	for target: Dictionary in targets:
		var title := String(target["name"])
		if not query.strip_edges().is_empty() and not title.to_lower().contains(query.strip_edges().to_lower()): continue
		# ★ รอบ 119 ★ บอกบท + ชนิด (เมือง / หน้าลานบอส) บนปุ่ม
		var ch := int(target.get("chapter", 0))
		var tag := ""
		if ch > 0:
			tag = "บทที่ %d · %s" % [ch, "เมือง" if String(target.get("kind", "")) == MapAtlas.KIND_TOWN else "หน้าลานบอส"]
		var cost := int(target.get("cost", 0))
		var available := bool(target.get("ok", false)) and cost <= PlayerState.zeny
		var reason := "%s z" % HUD._comma(cost)
		if not bool(target.get("ok", false)): reason = String(target.get("why", "ยังไม่ปลดล็อก"))
		elif cost > PlayerState.zeny: reason += " · เงินไม่พอ"
		var button := UITheme.make_button((tag + "\n" if tag != "" else "") + title + "\n" + reason)
		button.custom_minimum_size.y = 84 if tag != "" else 70
		button.add_theme_font_size_override("font_size", 20)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = not available
		button.add_theme_color_override("font_disabled_color", Color("a6b1ac"))
		button.toggle_mode = true
		button.button_pressed = selected == StringName(target["id"])
		button.pressed.connect(func():
			selected = StringName(target["id"])
			details.text = "%s · ค่าวาป %s z" % [title, HUD._comma(cost)]
			travel.disabled = false
			refresh(query))
		list.add_child(button)
	if list.get_child_count() == 0:
		list.add_child(UITheme.make_label("ไม่พบปลายทาง", 20, UITheme.TEXT))

func finish(destination: StringName) -> void:
	if finished: return
	finished = true
	chosen.emit(destination)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("close_windows"):
		get_viewport().set_input_as_handled()
		finish(&"")
