extends Node2D
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
	else: print("PASS: ", label)

func _ready() -> void:
	get_tree().create_timer(45).timeout.connect(func(): get_tree().quit(1))
	PlayerState.new_game()
	PlayerState.set_process(false)
	PlayerState.stats.level = 96
	PlayerState.inventory = Inventory.new(30)
	var sword := ItemInstance.create(&"flame_sword", 1, 0, 3)
	check(sword.socket_card(&"card_orc_warrior"), "socket first card")
	check(sword.socket_card(&"card_war_wraith"), "socket second card")
	PlayerState.inventory.add(sword)
	var player = load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	player.hide()
	get_window().size = Vector2i(1280,720)
	get_window().content_scale_size = Vector2i(1280,720)
	UI.shell.open_tab("inventory")
	var inv: InventoryWindow = UI.windows[&"inventory"]
	inv._selected = 0
	for job in [&"swordsman", &"runeblade"]:
		PlayerState.stats.job_id = job
		for id in [&"flame_sword", &"garm_fang"]:
			PlayerState.equipment.equip(Equipment.EquipSlot.WEAPON, ItemInstance.create(id))
			PlayerState.refresh()
			inv.refresh()
			await get_tree().process_frame
			await get_tree().process_frame
			var preview = inv._preview
			check(preview.body.visible, "doll body visible " + String(job))
			check(preview.visual._layer_data[Equipment.EquipSlot.WEAPON].id == id, "equipped weapon follows " + String(id))
			check(preview.visual._layers[Equipment.EquipSlot.WEAPON].visible, "weapon rendered " + String(job))
			for flipped in [false, true]:
				player.sprite_faces_left = flipped
				preview.refresh()
				await get_tree().create_timer(0.15).timeout
				if "--preview" in OS.get_cmdline_user_args():
					await RenderingServer.frame_post_draw
					get_viewport().get_texture().get_image().save_png("res://output/socket_inventory/%s_%s_%s.png" % [job,id,flipped])
	var popup: ItemInfoPopup = UI.item_popup
	popup.show_item(sword)
	check(popup._cards_panel.visible and popup._cards_panel.get_child_count() == 4, "two cards and one empty socket rendered")
	var first_art = popup._cards_panel.get_child(1).get_child(0).get_child(0)
	check(first_art.texture != null, "real card icon loaded")
	await get_tree().process_frame
	await get_tree().process_frame
	if "--preview" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/socket_inventory/popup.png")
	popup.show_data(GameData.get_item(&"red_potion"))
	check(not popup._cards_panel.visible and popup._cards_panel.get_child_count() == 0, "unrelated item clears cards")
	popup.show_item(ItemInstance.create(&"flame_sword"))
	check(not popup._cards_panel.visible, "shop copy does not show template sockets")
	PlayerState.equipment.slots.erase(Equipment.EquipSlot.WEAPON)
	Events.equipment_changed.emit()
	inv.refresh()
	await get_tree().process_frame
	check(not inv._preview.visual._layers[Equipment.EquipSlot.WEAPON].visible, "unequip removes preview weapon")
	for id in inv._preview.ICON_GRIPS:
		var original: ItemData = GameData.get_item(StringName(id))
		PlayerState.equipment.equip(Equipment.EquipSlot.WEAPON, ItemInstance.create(StringName(id)))
		inv.refresh()
		await get_tree().process_frame
		inv._preview.visual._process(0.0)
		check(inv._preview.visual._layers[Equipment.EquipSlot.WEAPON].visible and original.equip_texture == null, "icon fallback visible without changing item resource: " + id)
	popup.hide_popup()
	inv._detail_scroll.scroll_vertical = 10000
	await get_tree().process_frame
	if "--preview" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/socket_inventory/inventory_cards.png")
	var rows: Array = []
	for id in GameData.items:
		var d: ItemData = GameData.items[id]
		if d.is_equipment(): rows.append({"id":id,"name":d.display_name,"level":d.required_level,"slots":d.card_slots,"slot":Equipment.slot_for(d)})
	var out := FileAccess.open("res://output/socket_inventory/equipment_slots.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(rows,"\t"))
	out.close()
	print("SOCKET INVENTORY: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
