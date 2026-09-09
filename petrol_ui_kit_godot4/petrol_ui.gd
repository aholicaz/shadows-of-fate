extends Control
## Godot 4.x standalone UI demonstration. All stats/items are sample data.
signal menu_requested(menu_id: String)
const INK = Color("102725")
const IVORY = Color("ece7d8")
const SAGE = Color("81958a")
const BRASS = Color("b5a16c")
const MENUS = ["status", "equipment", "inventory", "skills", "cards", "quests", "map", "system"]
var menu_window: PanelContainer
var page_title: Label
var inventory_content: HBoxContainer
var placeholder: Label

func box(color: Color, border: Color, radius: int = 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func text(value: String, size: int = 16) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", size)
	return l

func button(value: String) -> Button:
	var b := Button.new()
	b.text = value
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size.y = 40
	return b

func _ready() -> void:
	var t := Theme.new()
	t.default_font_size = 16
	t.set_color("font_color", "Label", IVORY)
	t.set_color("font_color", "Button", IVORY)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_stylebox("normal", "Button", box(Color(0.06,0.15,0.14,0.75), Color(0.5,0.58,0.54,0.25)))
	t.set_stylebox("hover", "Button", box(Color("243c34"), BRASS))
	t.set_stylebox("pressed", "Button", box(Color("34483b"), IVORY))
	t.set_stylebox("focus", "Button", box(Color(0,0,0,0), BRASS))
	t.set_stylebox("panel", "PanelContainer", box(INK, BRASS))
	t.set_stylebox("background", "ProgressBar", box(Color("091816"), SAGE, 6))
	t.set_stylebox("fill", "ProgressBar", box(Color("b8443a"), Color.TRANSPARENT, 6))
	theme = t
	build_hud()
	build_window()

func build_hud() -> void:
	var stats := VBoxContainer.new()
	stats.position = Vector2(24,24)
	stats.size.x = 270
	stats.add_child(text("Lv.20  Adventurer",22))
	for pair in [["HP", 76, "b8443a"], ["MP", 60, "4599c2"], ["ST", 45, "4d9b76"]]:
		stats.add_child(text(pair[0]))
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(270,12)
		bar.value = pair[1]
		bar.show_percentage = false
		bar.add_theme_stylebox_override("fill", box(Color(pair[2]), Color.TRANSPARENT,6))
		stats.add_child(bar)
	stats.add_child(text("A Veil of Storms",18))
	stats.add_child(text("Defeat the Lightning Beast  (0/1)",14))
	add_child(stats)
	var nav := HBoxContainer.new()
	nav.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	nav.position = Vector2(-730,24)
	nav.add_theme_constant_override("separation",6)
	for id in MENUS:
		var b := button("")
		b.custom_minimum_size = Vector2(82,80)
		b.tooltip_text = id.capitalize()
		var column := VBoxContainer.new()
		column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.texture = load("res://icons/" + id + ".svg")
		icon.custom_minimum_size = Vector2(32,40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(icon)
		var label := text(id.capitalize(),12)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(label)
		b.add_child(column)
		b.pressed.connect(open_menu.bind(id))
		nav.add_child(b)
	add_child(nav)
	var hint := text("UI DEMO  |  Click a menu  |  Esc closes window  |  Sample data only",14)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position = Vector2(24,-38)
	add_child(hint)

func build_window() -> void:
	menu_window = PanelContainer.new()
	menu_window.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu_window.position = Vector2(-520,-245)
	menu_window.custom_minimum_size = Vector2(1040,490)
	var layout := VBoxContainer.new()
	var header := HBoxContainer.new()
	page_title = text("INVENTORY",22)
	page_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(page_title)
	var close := button("Close  [Esc]")
	close.pressed.connect(menu_window.hide)
	header.add_child(close)
	layout.add_child(header)
	layout.add_child(HSeparator.new())
	inventory_content = HBoxContainer.new()
	inventory_content.add_theme_constant_override("separation",24)
	var stats := VBoxContainer.new()
	stats.custom_minimum_size.x = 200
	for line in ["ADVENTURER", "Level 20", "", "HP                 541", "MP                 195", "Attack             124", "Defense             86", "", "Paper doll / avatar", "goes here"]:
		stats.add_child(text(line))
	inventory_content.add_child(stats)
	var grid := GridContainer.new()
	grid.columns = 5
	for i in range(20):
		var slot := button("")
		slot.custom_minimum_size = Vector2(70,70)
		if i < 8:
			slot.icon = load("res://icons/" + MENUS[i] + ".svg")
			slot.expand_icon = true
			slot.add_theme_constant_override("icon_max_width",32)
		grid.add_child(slot)
	inventory_content.add_child(grid)
	var detail := VBoxContainer.new()
	detail.custom_minimum_size.x = 260
	for line in ["Vanguard Blade", "Rare", "", "Attack             96", "Critical rate    +4.5%", "Move speed       +2.0%", "", "Example item details"]:
		detail.add_child(text(line))
	for title in ["EQUIP", "COMPARE"]:
		var action := button(title + " (demo)")
		action.disabled = true
		detail.add_child(action)
	inventory_content.add_child(detail)
	layout.add_child(inventory_content)
	placeholder = text("Page layout placeholder — connect your game system here.",18)
	layout.add_child(placeholder)
	menu_window.add_child(layout)
	add_child(menu_window)
	menu_window.hide()

func open_menu(id: String) -> void:
	page_title.text = id.to_upper()
	inventory_content.visible = id in ["inventory", "equipment"]
	placeholder.visible = not inventory_content.visible
	menu_window.show()
	menu_requested.emit(id)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		menu_window.hide()
