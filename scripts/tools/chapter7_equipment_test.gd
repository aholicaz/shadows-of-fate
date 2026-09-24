extends Node
const OUT := "res://output/chapter7_equipment/"
var checks := 0
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManager.end_session()
	PlayerState.new_game()
	get_window().size = Vector2i(1280,720)
	get_window().content_scale_size = Vector2i(1280,720)
	var design = JSON.parse_string(FileAccess.get_file_as_string(OUT+"design.json"))
	for monster_id in design.loot:
		var monster = GameData.get_monster(StringName(monster_id))
		for expected in design.loot[monster_id]:
			var found := false
			for drop in monster.drops:
				if String(drop.item_id)!=expected[0]: continue
				found = true
				check(drop.chance==expected[1],"Chance: "+monster_id)
				var certain: DropEntry = drop.duplicate()
				certain.chance = 100.0
				var inst := certain.roll()
				check(inst!=null and inst.data().is_equipment(),"Actual drop creates equipment")
				check(inst.slots==inst.data().card_slots and inst.bonus_percent>=5 and inst.bonus_percent<=30,"Drop sockets and bonus")
				var slot := Equipment.slot_for(inst.data())
				check(slot>=0,"Wearable slot")
				PlayerState.equipment.equip(slot,inst)
				check(PlayerState.equipment.get_item(slot)==inst,"Equip instance")
				PlayerState.equipment.unequip(slot)
			check(found,"Drop exists: "+expected[0])
	var town = load("res://scenes/maps/emberhaven.tscn").instantiate()
	var shop_ids = town.get_node("NPCs/orm").shop_items.duplicate()
	town.free()
	var equipment_count := 0
	for id in shop_ids:
		var item := GameData.get_item(id)
		check(item!=null,"Shop resource")
		if not item.is_equipment(): continue
		equipment_count += 1
		check(item.buy_price>item.sell_price and item.buy_price<=260000,"Chapter shop prices")
		PlayerState.zeny = item.buy_price
		check(PlayerState.buy(id) and PlayerState.zeny==0,"Real purchase deducts price")
		var bought: ItemInstance
		for inst in PlayerState.inventory.slots:
			if inst!=null and inst.item_id==id: bought=inst
		check(bought!=null and bought.slots==0 and bought.bonus_percent==0,"Shop has no drop bonuses")
		check(not PlayerState.buy(id),"Insufficient funds rejected")
	check(equipment_count==4,"Four shop equipment choices")
	check(not shop_ids.has(&"c7_oathbreak_signet") and not shop_ids.has(&"c7_chainbreak_shield"),"Hunt exclusives")
	for row in design.items:
		var item := GameData.get_item(StringName(row[0]))
		check(item.icon.get_size()==Vector2(256,256),"Icon dimensions")
		check(item.refinable and not item.refine_progress(1).is_empty(),"Refinable equipment")
		check(not DropDirectory.sources_of(item.id).is_empty(),"Discovery source")
	UI.set_in_game(true)
	PlayerState.zeny = 2000000
	UI._on_shop_opened(shop_ids)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+"shop.png")
	var shop = UI.windows[&"shop"]
	var scroll = shop._list.get_parent() as ScrollContainer
	scroll.scroll_vertical = 10000
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+"shop_equipment.png")
	UI.close_all()
	UI.open(&"inventory")
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+"inventory.png")
	var report := FileAccess.open(OUT+"audit.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CHAPTER7_EQUIPMENT ",checks," failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
