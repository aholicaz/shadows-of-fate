extends VBoxContainer
## Uses instance sockets, including saved equipment; never template capacity.
func set_item(inst: ItemInstance) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	visible = inst != null and inst.card_slots() > 0
	if not visible: return
	add_theme_constant_override("separation", 5)
	add_child(UITheme.make_label("การ์ดที่ใส่  %d / %d" % [inst.cards.size(), inst.card_slots()], 12, UITheme.ACCENT))
	for i in range(inst.card_slots()):
		var card: CardData = GameData.get_item(inst.cards[i]) as CardData if i < inst.cards.size() else null
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UITheme.slot_style())
		add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 7)
		panel.add_child(row)
		var art := TextureRect.new()
		art.custom_minimum_size = Vector2(38, 48)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		art.texture = CardView.card_texture(card) if card != null else null
		row.add_child(art)
		var text_box := VBoxContainer.new()
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_box)
		var title := UITheme.make_label(card.display_name if card != null else ("ไม่พบข้อมูลการ์ด" if i < inst.cards.size() else "ช่องว่าง"), 12, UITheme.TEXT if card != null else UITheme.TEXT_DIM)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_box.add_child(title)
		if card != null:
			var stats := UITheme.make_label(card.describe().replace("\n", " · "), 11, UITheme.TEXT_DIM)
			stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text_box.add_child(stats)
