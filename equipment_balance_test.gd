extends Node
var checks := 0
var failures := 0
func check(ok: bool, title: String) -> void:
	checks += 1
	if ok: print("PASS: ", title)
	else:
		failures += 1
		push_error(title)

func _ready() -> void:
	PlayerState.new_game()
	PlayerState.set_process(false)
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/equipment_balance_expected.json"))
	for row in expected.items:
		var d := GameData.get_item(StringName(row.id))
		var ok := d != null
		for key in expected.stat_keys:
			ok = ok and is_equal_approx(float(d.get(key)), float(row.stats.get(key, 0)))
		check(ok, "all combat stats match approved: " + row.id)
		check(d.buy_price == int(row.buy) and d.sell_price == int(row.sell) and d.required_level == int(row.level) and d.attack_element == int(row.element) and d.card_slots == int(row.slots), "price/level/element/slots: " + row.id)
	for iid in expected.add_drops:
		var pair: Array = expected.add_drops[iid]
		var monster: MonsterData = load("res://data/monsters/%s.tres" % pair[0])
		var matches := 0
		for entry in monster.drops:
			if String(entry.item_id) == iid:
				matches += 1
				check(is_equal_approx(entry.chance, float(pair[1])), "drop chance: " + iid)
		check(matches == 1, "single reachable drop entry: " + iid)
	for iid in expected.remove_drops:
		for mid in expected.remove_drops[iid]:
			var monster: MonsterData = load("res://data/monsters/%s.tres" % mid)
			var found := false
			for entry in monster.drops:
				if String(entry.item_id) == iid: found = true
			check(not found, "removed mismatched source: " + iid + "/" + mid)
	PlayerState.equipment = Equipment.new()
	var shoes := ItemInstance.create(&"leather_shoes", 1, 0, 1)
	shoes.bonus_percent = 30.0
	check(shoes.socket_card(&"card_crystal_stag"), "movement card fits existing shoe slot")
	PlayerState.equipment.equip(Equipment.EquipSlot.SHOES, shoes)
	PlayerState.refresh()
	check(is_equal_approx(PlayerState.stats.move_speed, PlayerStats.BASE_MOVE_SPEED * 1.06), "equipment one percent plus card five percent, no random-roll multiplier")
	check(ItemInfoPopup.describe(shoes.data(), shoes).contains("ความเร็วเดิน +1%"), "movement equipment tooltip")
	var light := ItemInstance.create(&"conduit_edge")
	PlayerState.equipment.equip(Equipment.EquipSlot.WEAPON, light)
	PlayerState.refresh()
	check(is_equal_approx(PlayerState.stats.sp_drain_percent, 0.25), "Conduit SP drain reaches runtime")
	var inv_ui: InventoryWindow = UI.windows[&"inventory"]
	var drain_visible := false
	for row in inv_ui._stat_lines(light, null):
		if row[1] == "ดูดมานา" and row[2] == "+0.25%": drain_visible = true
	check(drain_visible, "inventory detail exposes fractional SP drain")
	var rolled_fang := ItemInstance.create(&"garm_fang")
	rolled_fang.bonus_percent = 15.0
	var boosted_visible := false
	for row in inv_ui._stat_lines(rolled_fang, ItemInstance.create(&"garm_fang")):
		if row[1] == "อัตราคริ" and row[2] == "+17  (+3)": boosted_visible = true
	check(boosted_visible, "inventory comparison includes rolled flat stat bonus on both items")
	var monster_script = load("res://scripts/entities/monster_base.gd")
	var target = monster_script.new()
	PlayerState.stats.sp = 0
	target._drain_to_player(399)
	check(PlayerState.stats.sp == 0, "Conduit below threshold cannot mint SP")
	target._drain_to_player(400)
	check(PlayerState.stats.sp == 1, "Conduit restores one SP at 400 actual damage")
	target.free()
	var bone := ItemInstance.create(&"bone_greatsword", 1, 3)
	bone.bonus_percent = 15.0
	check(bone.total_atk() == 728, "560 base +15 percent drop roll +3 refine totals 728 ATK")
	check(RefineSystem.preview(bone).atk_gain == 28, "refine preview uses new base")
	var armor := ItemInstance.create(&"plate_armor", 1, 3, 2)
	armor.socket_card(&"card_fabre")
	PlayerState.stats.level = 30
	PlayerState.equipment.equip(Equipment.EquipSlot.ARMOR, armor)
	PlayerState.refresh()
	var saved := PlayerState.to_dict()
	PlayerState.from_dict(saved)
	var restored := PlayerState.equipment.get_item(Equipment.EquipSlot.ARMOR)
	check(restored != null and restored.item_id == &"plate_armor" and restored.slots == 2 and restored.cards.size() == 1 and restored.refine == 3, "old equipped armor survives new level gate, sockets and refine preserved")
	PlayerState.inventory = Inventory.new(2)
	PlayerState.inventory.add_id(&"plate_armor", 1)
	check(not PlayerState.equip_from_inventory(0), "new equip attempts respect level 48")
	if "--preview" in OS.get_cmdline_user_args():
		await preview()
	print("EQUIPMENT BALANCE: %d checks; failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func preview() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	PlayerState.stats.level = 96
	PlayerState.inventory = Inventory.new(30)
	for id in [&"conduit_edge", &"river_walker", &"garm_fang"]:
		PlayerState.inventory.add(ItemInstance.create_drop(id))
	PlayerState.refresh()
	UI.shell.open_tab("inventory")
	var inv: InventoryWindow = UI.windows[&"inventory"]
	for i in range(3):
		inv._selected = i
		inv.refresh()
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var error := get_viewport().get_texture().get_image().save_png("res://output/equipment_balance_review_2026-09-14/equipment_%d.png" % i)
		check(error == OK, "rendered equipment details " + str(i))
