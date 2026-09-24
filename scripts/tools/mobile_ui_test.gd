extends Node2D

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	SaveManager.end_session()
	SaveManager.save_directory = "res://output/mobile_ui/isolated_saves"
	PlayerState.new_game()
	DirAccess.make_dir_recursive_absolute("res://output/mobile_ui")
	RenderingServer.set_default_clear_color(Color("233546"))
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://Sprites/map/chapter1/organic/dark_forest_2_depth.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.size = Vector2(1280,720)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var book := SkillBook.new()
	book.from_dict({"hotkeys":["bash", "slash", "", ""]})
	check(book.hotkeys.size() == 8 and book.hotkey_at(1) == &"slash" and book.hotkey_at(7) == &"", "Legacy save migration")
	book.set_hotkey(7, &"rune_lunge")
	book.switch_bank()
	check(book.active_hotkey_at(3) == &"rune_lunge", "Second bank mapping")
	var copy := SkillBook.new()
	copy.from_dict(book.to_dict())
	check(copy.active_bank == 1 and copy.active_hotkey_at(3) == &"rune_lunge", "Eight slots and bank round trip")
	copy.set_hotkey(0, &"rune_lunge")
	check(copy.hotkey_at(7) == &"", "No duplicate skill across banks")
	PlayerState.skills = book
	UI.set_in_game(true)
	UI.hud.quest_block.show()
	UI.hud.quest_title.text = "เดินทางสู่ป่าและตามหาร่องรอยที่หายไป"
	for text in ["กำจัดมอนสเตอร์ในพื้นที่ 0 / 10", "กลับไปพูดคุยกับหัวหน้าหมู่บ้าน"]:
		var label := UITheme.make_label(text, 20, Color.WHITE)
		label.custom_minimum_size.x = 380
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.hud.quest_lines.add_child(label)
	var point = preload("res://scripts/world/story_point.gd").new()
	point.title = "สำรวจแท่นพิธี"
	point.position = Vector2(570, 480)
	add_child(point)
	for i in range(2):
		var drop = load("res://scenes/items/dropped_item.tscn").instantiate()
		var id: StringName = &"red_potion" if i == 0 else &"card_orc_warrior"
		drop.setup(ItemInstance.create(id))
		add_child(drop)
		drop.position = Vector2(510 + i * 130, 545)
		drop._landed = true
		drop.auto_pickup = false
		var d := GameData.get_item(id)
		check(is_equal_approx(maxf(drop._sprite.texture.get_size().x, drop._sprite.texture.get_size().y) * drop._sprite.scale.x, d.drop_display_size * 2.0), "Drop doubles width for square icon")
		check(drop._is_card == (i == 1), "Card-only halo")
	for touch_mode in [false, true]:
		get_window().size = Vector2i(1280, 720)
		get_window().content_scale_size = Vector2i(1280, 720)
		UI.touch.mode = TouchControls.Mode.ON if touch_mode else TouchControls.Mode.OFF
		UI.touch._refresh_visible()
		UI.touch._layout()
		await get_tree().process_frame
		await get_tree().process_frame
		var zones: Array = UI.touch._zones
		for z in zones:
			if not z.node.visible: continue
			check(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(z.rect), "Button outside viewport: " + str(z.id))
			for other in zones:
				if other.id == z.id or not other.node.visible: continue
				var overlap: bool = (z.rect as Rect2).intersects(other.rect)
				if not z.has("square") and not other.has("square"):
					overlap = (z.rect as Rect2).get_center().distance_to((other.rect as Rect2).get_center()) < (z.rect.size.x + other.rect.size.x) * 0.5
				check(not overlap, "Overlapping buttons: %s / %s" % [z.id, other.id])
		check(UI.layer.find_child("Minimap", true, false) == null, "No floating minimap")
		check(UI.touch.get_node_or_null("Btn_down") == null, "No down button")
		var bank: Dictionary = {}
		for z in zones:
			if z.id == "bank": bank = z
		check((bank.rect as Rect2).end.y < 630.0, "Bank button must clear EXP area")
		for z in zones:
			if z.id != "skill_3": continue
			for other in zones:
				if other.id == "skill_4":
					check(not z.node.get_global_rect().intersects(other.node.get_global_rect()), "Actual skill 3/4 controls overlap")
					check(not z.pill.get_global_rect().intersects(other.node.get_global_rect()), "Skill 3 label overlaps skill 4")
		for z in zones:
			if z.id in ["attack", "bank"]:
				var bounds: Rect2 = z.glyph_node.get_global_rect()
				check(bounds.get_center().distance_to(z.node.get_global_rect().get_center()) < 1.0, "Glyph must be centered: " + z.id)
				check(bounds.size.length() * 0.5 < z.node.size.x * 0.5 - 2.0, "Glyph must fit inside circle: " + z.id)
		var old: int = book.active_bank
		UI.touch._press_at(41, (bank.rect as Rect2).get_center())
		UI.touch._release_finger(41)
		check(book.active_bank == 1 - old, "Touch bank toggles exactly once")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://output/mobile_ui/%s.png" % ("mobile" if touch_mode else "desktop"))
	var map_key := InputEventAction.new()
	map_key.action = &"toggle_minimap"
	map_key.pressed = true
	UI._unhandled_input(map_key)
	await get_tree().process_frame
	check(UI.windows[&"map"].visible, "Map opens full map page")
	UI.close_all()
	UI.toggle(&"skills")
	await get_tree().process_frame
	await get_tree().process_frame
	for tile in UI.windows[&"skills"]._tiles.values():
		var label := tile.get_node("SkillName") as Label
		check(label.clip_text and label.size.x <= 138.1, "Skill title fits card width")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/mobile_ui/skill_window.png")
	print("MOBILE_UI_TEST failures=", failures)
	get_tree().quit(0 if failures == 0 else 1)
