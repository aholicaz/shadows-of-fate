## CardGetPopup — ฉากเปิดตัวการ์ดใบใหม่ครั้งแรก
##
## อ้างอิงหน้าจอ Obtain Card:
## - หยุดเกมและหรี่ฉากหลัง
## - การ์ดใบใหญ่เอียงอยู่ซ้าย
## - ชื่อ/ระดับ/เอฟเฟกต์อยู่ขวา
## - แตะพื้นที่ว่างหรือกดปุ่มใดก็ได้เพื่อไปต่อ
class_name CardGetPopup
extends Control

## 0 = รอผู้เล่นแตะปิดเอง (เหมือนหน้าจออ้างอิง)
@export var auto_close: float = 0.0

var _dim: ColorRect
var _warm_wash: ColorRect
var _content: VBoxContainer
var _title: Label
var _card_shell: PanelContainer
var _card_art: TextureRect
## ★ รอบ 148 ★ การ์ดถูกวาดใน SubViewport ที่ 2 เท่า แล้วเอาเป็นภาพมาหมุน → ขอบเอียงเรียบ (ไม่แตกเป็นขั้นบันได)
var _card_vp: SubViewport
var _card_tex: _CardTexture
const CARD_SIZE := Vector2(246, 360)
## เผื่อขอบรอบการ์ดใน viewport ให้เงา (shadow_size 18 + offset 13) ไม่โดนตัด
const CARD_PAD := 36.0
## วาดใน viewport กี่เท่าของขนาดจริง (2 = supersample 2x)
const CARD_SS := 2.0
var _name_label: Label
var _rarity_label: Label
var _description_label: Label
var _slot_label: Label
var _effect_label: Label
var _open := false
var _timer := 0.0
var _grace := 0.0
var _base_card_angle := -4.0
var _open_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	z_index = 190
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0.015, 0.012, 0.01, 0.76)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	# สีน้ำตาลอุ่นบาง ๆ ทำให้ฉากหลังมีอารมณ์เดียวกับภาพอ้างอิง
	_warm_wash = ColorRect.new()
	_warm_wash.name = "WarmWash"
	_warm_wash.color = Color(0.31, 0.20, 0.09, 0.18)
	_warm_wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_warm_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_warm_wash)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_content = VBoxContainer.new()
	_content.name = "ObtainCardContent"
	_content.custom_minimum_size = Vector2(780, 500)
	_content.add_theme_constant_override("separation", 14)
	_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_content)

	# ตราจางด้านหลังหัวเรื่อง
	var heading := CenterContainer.new()
	heading.custom_minimum_size.y = 72
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(heading)

	var emblem := Label.new()
	emblem.text = "◇"
	emblem.add_theme_font_size_override("font_size", 76)
	emblem.add_theme_color_override("font_color", Color(0.82, 0.67, 0.31, 0.18))
	emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(emblem)

	_title = UITheme.make_label("OBTAIN CARD", 28, Color("#f0d897"))
	_title.add_theme_constant_override("outline_size", 6)
	_title.add_theme_color_override("font_outline_color", Color(0.08, 0.045, 0.02, 0.9))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(_title)

	var line := HSeparator.new()
	line.custom_minimum_size.x = 560
	line.add_theme_stylebox_override("separator", _separator_style())
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(line)

	var body_center := CenterContainer.new()
	body_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(body_center)

	var body := HBoxContainer.new()
	body.name = "CardAndDetails"
	body.add_theme_constant_override("separation", 56)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_center.add_child(body)

	# ★ รอบ 148 ★ ตัวที่อยู่ในเลย์เอาต์และถูกหมุน = ภาพจาก SubViewport · ตัวการ์ดจริงวาดใน viewport
	_card_tex = _CardTexture.new()
	_card_tex.name = "CardView"
	_card_tex.custom_minimum_size = CARD_SIZE
	_card_tex.pad = CARD_PAD
	_card_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_tex.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	body.add_child(_card_tex)
	_card_vp = SubViewport.new()
	_card_vp.name = "CardViewport"
	_card_vp.transparent_bg = true
	_card_vp.size = Vector2i((CARD_SIZE + Vector2.ONE * CARD_PAD * 2.0) * CARD_SS)
	_card_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_card_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_card_tex.add_child(_card_vp)
	_card_tex.texture = _card_vp.get_texture()
	_card_shell = PanelContainer.new()
	_card_shell.name = "Card"
	_card_shell.custom_minimum_size = CARD_SIZE
	_card_shell.add_theme_stylebox_override("panel", _card_style())
	_card_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_shell.position = Vector2.ONE * CARD_PAD * CARD_SS
	_card_shell.scale = Vector2.ONE * CARD_SS
	_card_vp.add_child(_card_shell)

	_card_art = TextureRect.new()
	_card_art.name = "Art"
	_card_art.custom_minimum_size = Vector2(230, 344)
	_card_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_card_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_card_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_shell.add_child(_card_art)

	var details := VBoxContainer.new()
	details.name = "Details"
	details.custom_minimum_size = Vector2(365, 310)
	details.add_theme_constant_override("separation", 9)
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(details)

	_name_label = UITheme.make_label("", 25, UITheme.TEXT)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(_name_label)

	_rarity_label = UITheme.make_label("", 18, UITheme.ACCENT)
	_rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(_rarity_label)

	_description_label = UITheme.make_label("", 12, Color(UITheme.TEXT, 0.78))
	_description_label.custom_minimum_size.x = 340
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(_description_label)

	var detail_line := HSeparator.new()
	detail_line.add_theme_stylebox_override("separator", _separator_style())
	detail_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(detail_line)

	var effects_title := UITheme.make_label("CARD EFFECTS", 13, Color("#d8c18b"))
	effects_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(effects_title)

	_slot_label = UITheme.make_label("", 12, UITheme.TEXT_DIM)
	_slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(_slot_label)

	_effect_label = UITheme.make_label("", 15, UITheme.TEXT)
	_effect_label.custom_minimum_size = Vector2(340, 96)
	_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_effect_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(_effect_label)

	var hint := UITheme.make_label("แตะพื้นที่ว่างเพื่อดำเนินการต่อ", 13, Color(UITheme.TEXT, 0.78))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_constant_override("outline_size", 5)
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(hint)

	Events.card_obtained.connect(show_card)


func is_open() -> bool:
	return _open


## เปิด popup เฉพาะตอนสัญญาณใบใหม่ถูกยิงจาก PlayerState.gain_item()
func show_card(card_id: StringName) -> void:
	var card := GameData.get_card(card_id)
	if card == null:
		return

	_card_art.texture = CardView.card_texture(card)
	_name_label.text = card.display_name
	_name_label.add_theme_color_override("font_color", card.rarity_color())
	_rarity_label.text = "%s   %s" % [_rarity_marks(card.rarity), card.rarity_name()]
	_rarity_label.add_theme_color_override("font_color", card.rarity_color())
	_description_label.text = card.description
	_description_label.visible = not card.description.strip_edges().is_empty()
	_slot_label.text = "ใช้กับ: %s%s" % [card.slot_name(), "   •   Lv.%d" % card.monster_level if card.monster_level > 0 else ""]
	_effect_label.text = _bullet_effects(card.describe())

	_open = true
	visible = true
	move_to_front()
	_timer = auto_close
	_grace = 0.35
	get_tree().paused = true
	call_deferred("_animate_open")


func close() -> void:
	if not _open:
		return
	_open = false
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	visible = false
	if _card_vp != null:
		_card_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	get_tree().paused = false


func _animate_open() -> void:
	if not _open or _content == null:
		return
	_content.pivot_offset = _content.size * 0.5
	_content.modulate.a = 0.0
	_content.scale = Vector2(0.94, 0.94)
	_dim.modulate.a = 0.0
	_warm_wash.modulate.a = 0.0
	_card_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_card_tex.pivot_offset = _card_tex.size * 0.5
	_card_tex.rotation_degrees = -11.0

	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	_open_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_open_tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_open_tween.tween_property(_dim, "modulate:a", 1.0, 0.24)
	_open_tween.tween_property(_warm_wash, "modulate:a", 1.0, 0.34)
	_open_tween.tween_property(_content, "modulate:a", 1.0, 0.34)
	_open_tween.tween_property(_content, "scale", Vector2.ONE, 0.42)
	_open_tween.tween_property(_card_tex, "rotation_degrees", _base_card_angle, 0.48)


func _process(delta: float) -> void:
	if not _open:
		return
	if _grace > 0.0:
		_grace -= delta
	if _title != null:
		_title.modulate.a = 0.88 + 0.12 * absf(sin(Time.get_ticks_msec() * 0.0025))
	if _card_tex != null and (_open_tween == null or not _open_tween.is_running()):
		_card_tex.rotation_degrees = _base_card_angle + sin(Time.get_ticks_msec() * 0.0016) * 0.45
	if auto_close > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			close()


func _input(event: InputEvent) -> void:
	if not _open or _grace > 0.0:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		close()
		get_viewport().set_input_as_handled()


static func _rarity_marks(rarity: int) -> String:
	var marks := ""
	for i in range(5):
		marks += "◆" if i < clampi(rarity, 1, 5) else "◇"
	return marks


static func _bullet_effects(text: String) -> String:
	var lines := PackedStringArray()
	for raw in text.split("\n", false):
		var clean := raw.strip_edges()
		if not clean.is_empty():
			lines.append("◆  " + clean)
	return "\n".join(lines)


static func _separator_style() -> StyleBoxLine:
	var style := StyleBoxLine.new()
	style.color = Color(0.76, 0.62, 0.32, 0.52)
	style.thickness = 1
	style.grow_begin = -4
	style.grow_end = -4
	return style


static func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.055, 0.035, 0.94)
	style.border_color = Color("#d4bd78")
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.set_content_margin_all(7)
	style.shadow_color = Color(0, 0, 0, 0.72)
	style.shadow_size = 18
	style.shadow_offset = Vector2(10, 13)
	return style


## ★ รอบ 148 ★ Control ที่วาดภาพการ์ดจาก SubViewport ให้ล้นกรอบตัวเองด้าน pad (เพื่อให้เงาโผล่) — หมุนตัวนี้แทน PanelContainer
class _CardTexture extends Control:
	var texture: Texture2D
	var pad: float = 0.0

	func _draw() -> void:
		if texture == null:
			return
		draw_texture_rect(texture, Rect2(Vector2.ONE * -pad, size + Vector2.ONE * pad * 2.0), false)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()
