extends Node
## รอบ 160 — ร้านค้าแบบ A (ตู้โชว์กริด + แผงรายละเอียด)
var fails := 0
var passes := 0
const OUT := "res://output/r160/"
const TONY := ["red_potion", "orange_potion", "blue_potion", "meat", "wooden_sword", "novice_sword", "short_sword", "falchion", "wooden_shield", "guard", "ribbon", "cap", "leather_cap", "cotton_shirt", "leather_jacket", "hood", "sandals", "leather_shoes", "necklace", "earring", "wing_of_valkyrie", "phracon", "emveretarcon"]

func ok(c: bool, m: String) -> void:
	if c: passes += 1; print("  PASS ", m)
	else: fails += 1; print("  FAIL ", m)

func shot(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")

func click(shop, key, dbl := false, shift := false) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.double_click = dbl
	ev.shift_pressed = shift
	shop._on_cell_input(ev, key)

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	var bg := TextureRect.new()
	var img := Image.load_from_file(ProjectSettings.globalize_path(OUT + "bg.jpg"))
	bg.texture = ImageTexture.create_from_image(img)
	bg.size = Vector2(1280, 720)
	bg.modulate = Color(0.55, 0.6, 0.6)
	add_child(bg)
	await get_tree().process_frame
	SaveManager.end_session()
	PlayerState.new_game()
	UI.set_in_game(true)
	PlayerState.stats.level = 10
	PlayerState.zeny = 12450
	PlayerState.equipment.equip(Equipment.EquipSlot.WEAPON, ItemInstance.create(&"novice_sword"))
	PlayerState.equipment.equip(Equipment.EquipSlot.HEAD, ItemInstance.create(&"cap"))
	PlayerState.equipment.equip(Equipment.EquipSlot.ARMOR, ItemInstance.create(&"cotton_shirt"))
	PlayerState.inventory.add_id(&"red_potion", 4)
	PlayerState.inventory.add_id(&"jellopy", 23)
	PlayerState.inventory.add_id(&"wooden_sword", 1)
	ShopWindow.next_owner = "พ่อค้าโทนี่"
	UI._on_shop_opened(TONY)
	await get_tree().process_frame
	var shop: ShopWindow = UI.windows[&"shop"]
	ok(shop.visible, "เปิดร้านได้")
	ok(shop.title_label.text.contains("ร้านของพ่อค้าโทนี่"), "หัวหน้าต่าง = ร้านของพ่อค้าโทนี่")
	ok(shop.size.x <= 1120 and shop.size.y <= 660 and shop.position.y >= 0, "หน้าต่างพอดีจอ %s @ %s" % [shop.size, shop.position])
	ok(shop._cat_buttons["weapons"].text.contains("(4)") and shop._cat_buttons["accessory"].text.contains("(2)"), "จำนวนต่อหมวด")
	ok(shop._cat_buttons["other"].visible == false, "หมวดว่างถูกซ่อน")
	ok(ShopWindow.is_upgrade(GameData.get_item(&"short_sword")), "ดาบสั้น ▲ ดีกว่าดาบมือใหม่")
	ok(not ShopWindow.is_upgrade(GameData.get_item(&"wooden_sword")), "ดาบไม้ไม่ ▲")
	ok(not ShopWindow.is_upgrade(GameData.get_item(&"novice_sword")), "ของที่ใส่อยู่ไม่ ▲")
	ok(not ShopWindow.level_ok(GameData.get_item(&"falchion")), "ฟัลชิออน Lv12 ยังใส่ไม่ได้")
	ok(ShopWindow.unit_price(GameData.get_item(&"red_potion")) == BountyBoard.guild_price(60), "ราคาหลังส่วนลด")
	await shot("1_buy_all")

	shop._on_category("weapons")
	click(shop, &"short_sword")
	await shot("2_weapons_short_sword")
	var body = shop.content.get_child(0)
	print("  MIN content=", shop.content.get_combined_minimum_size(), " left=", body.get_child(0).get_combined_minimum_size(), " mid=", body.get_child(1).get_combined_minimum_size(), " right=", body.get_child(2).get_combined_minimum_size(), " win=", shop.get_combined_minimum_size())
	var txt := ""
	for r in shop._d_cmp.get_children():
		for l in r.get_children(): txt += (l as Label).text + "|"
	ok(txt.contains("ATK") and txt.contains("▲"), "แผงเทียบ ATK ▲ : %s" % txt)
	ok(shop._d_action.text == "ซื้อ 1 ชิ้น", "ปุ่ม ซื้อ 1 ชิ้น")

	# ซื้อยาแดง 3
	click(shop, &"red_potion")
	shop._set_qty(3)
	var z0 := PlayerState.zeny
	var c0 := PlayerState.inventory.count_of(&"red_potion")
	shop._do_action()
	ok(PlayerState.inventory.count_of(&"red_potion") == c0 + 3, "ซื้อยาแดง 3")
	ok(z0 - PlayerState.zeny == ShopWindow.unit_price(GameData.get_item(&"red_potion")) * 3, "หักเงินถูก (%d)" % (z0 - PlayerState.zeny))
	# ดับเบิลคลิก = 1 · shift = 10
	c0 = PlayerState.inventory.count_of(&"red_potion")
	click(shop, &"red_potion", true)
	ok(PlayerState.inventory.count_of(&"red_potion") == c0 + 1, "ดับเบิลคลิกซื้อ 1")
	click(shop, &"red_potion", false, true)
	ok(PlayerState.inventory.count_of(&"red_potion") == c0 + 11, "Shift+คลิกซื้อ 10")
	# สูงสุด = ตามเงิน
	click(shop, &"phracon")
	shop._set_qty(999)
	ok(shop._qty == int(PlayerState.zeny / ShopWindow.unit_price(GameData.get_item(&"phracon"))), "สูงสุดตามเงิน = %d" % shop._qty)
	click(shop, &"red_potion")
	shop._set_qty(20)
	await shot("3_potion_qty20")
	# ค้นหา
	shop._on_search("ดาบ")
	ok(shop._cat_buttons["all"].text.contains("(3)"), "ค้นหา 'ดาบ' = 3 : %s" % shop._cat_buttons["all"].text)
	shop._on_search("")
	shop._on_usable(true)
	ok(shop._cat_buttons["accessory"].visible == false, "เฉพาะที่ใส่ได้ ซ่อนเครื่องประดับ Lv12")
	shop._on_usable(false)
	shop._on_sort(2)
	await get_tree().process_frame
	shop._on_sort(0)
	# เงินไม่พอ
	PlayerState.zeny = 10
	click(shop, &"phracon")
	ok(shop._d_action.disabled and shop._d_action.text == "ซีนีไม่พอ", "เงินไม่พอ ปิดปุ่ม")
	PlayerState.zeny = 12450

	# ขาย
	shop._set_mode(false)
	await shot("4_sell")
	ok(shop._bulk_button.visible, "โหมดขายมีปุ่มขายขยะ")
	var slot := -1
	for i in PlayerState.inventory.size:
		var it := PlayerState.inventory.get_slot(i)
		if it != null and it.item_id == &"jellopy": slot = i
	if slot >= 0:
		click(shop, slot)
		shop._set_qty(5)
		var zz := PlayerState.zeny
		shop._do_action()
		ok(PlayerState.inventory.count_of(&"jellopy") == 18 and PlayerState.zeny > zz, "ขาย jellopy 5")
		click(shop, slot, false, true)
		ok(PlayerState.inventory.count_of(&"jellopy") == 0, "Shift+คลิกขายทั้งกอง")
	else:
		ok(false, "ไม่มี jellopy ในกระเป๋า")
	shop._set_mode(true)
	# เทสต์เก่า chapter7 อ้าง _list.get_parent()
	ok(shop._list.get_parent() is ScrollContainer, "_list อยู่ใน ScrollContainer")
	print("R160 RESULT: %d pass · %d fail" % [passes, fails])
	get_tree().quit(1 if fails > 0 else 0)
