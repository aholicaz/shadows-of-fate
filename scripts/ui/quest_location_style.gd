extends RefCounted

static func apply(label: Label) -> void:
	var parent_scale: Vector2 = label.get_parent().get_global_transform().get_scale().abs()
	label.scale = Vector2(1.0 / maxf(parent_scale.x, 0.01), 1.0 / maxf(parent_scale.y, 0.01))
	label.position.x = -label.custom_minimum_size.x * label.scale.x * 0.5
	label.z_index = 30
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_outline_color", Color("10191e"))
	label.add_theme_constant_override("outline_size", 4)
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(0.035, 0.075, 0.09, 0.72)
	plate.border_color = Color("b5a16c")
	plate.border_width_bottom = 1
	plate.set_corner_radius_all(2)
	plate.content_margin_left = 16
	plate.content_margin_right = 16
	plate.content_margin_top = 9
	plate.content_margin_bottom = 9
	label.add_theme_stylebox_override("normal", plate)
	var marker := Label.new()
	marker.text = "◆ จุดสำรวจ"
	marker.add_theme_font_size_override("font_size", 18)
	marker.add_theme_color_override("font_color", Color("ece7d8"))
	marker.add_theme_color_override("font_outline_color", Color("10191e"))
	marker.add_theme_constant_override("outline_size", 6)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.position = Vector2(0, -30)
	marker.custom_minimum_size.x = label.custom_minimum_size.x
	label.add_child(marker)
