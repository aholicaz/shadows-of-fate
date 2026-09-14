extends Node
const Forge = preload("res://scripts/core/third_socket.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error(label)

func outcome(rate: float, success: bool) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	for seed_value in range(10000):
		rng.seed = seed_value
		if (rng.randf() * 100.0 < rate) == success:
			rng.seed = seed_value
			return rng
	return rng

func _ready() -> void:
	PlayerState.new_game()
	PlayerState.set_process(false)
	PlayerState.inventory = Inventory.new(40)
	PlayerState.equipment = Equipment.new()
	PlayerState.zeny = 1000000
	var inv := PlayerState.inventory
	var main := ItemInstance.create(&"flame_sword", 1, 7, 2)
	main.bonus_percent = 27.5
	main.socket_card(&"card_orc_warrior")
	main.socket_card(&"card_war_wraith")
	main.socket_locked = true
	inv.add(main)
	inv.add(ItemInstance.create(&"socket_stone_1", 5))
	check(Forge.requirements(main).zeny == 30000, "level 50 fee")
	var high := ItemInstance.create(&"garm_fang", 1, 0, 2)
	check(Forge.requirements(high).stone == &"socket_stone_3" and Forge.requirements(high).zeny == 94400, "endgame requires highest stone and scaled fee")
	check(not Forge.reason(ItemInstance.create(&"flame_sword")).is_empty(), "zero sockets cannot skip base service")
	check(not Forge.reason(ItemInstance.create(&"storm_runeblade", 1, 0, 2)).is_empty(), "level 30 not eligible")
	check(not Forge.reason(ItemInstance.create(&"plate_armor", 1, 0, 2)).is_empty(), "armor cannot get third socket")
	var donor := ItemInstance.create(&"flame_sword", 1, 0, 2)
	inv.add(donor)
	var cash := PlayerState.zeny
	check(not Forge.attempt(main, [donor,donor], inv, PlayerState).ok and PlayerState.zeny == cash and donor.count == 1, "same donor twice rejected without charging")
	donor.socket_locked = true
	check(not Forge.donor_ok(main, donor), "locked donor rejected")
	donor.socket_locked = false
	donor.socket_card(&"card_orc_warrior")
	check(not Forge.donor_ok(main, donor), "carded donor rejected")
	donor.cards.clear()
	donor.socket_failures = 1
	check(not Forge.donor_ok(main, donor), "pity donor rejected")
	donor.socket_failures = 0
	inv.slots[inv.slots.find(donor)] = null
	for i in range(4):
		var a := ItemInstance.create(&"flame_sword", 1, 0, 2)
		var b := ItemInstance.create(&"flame_sword", 1, 2, 0)
		inv.add(a)
		inv.add(b)
		var req := Forge.requirements(main)
		check(req.rate == Forge.RATES[i], "pity rate " + str(i))
		var before := PlayerState.zeny
		var out := Forge.attempt(main, [a,b], inv, PlayerState, outcome(req.rate, i == 3))
		check(out.ok and out.success == (i == 3), "deterministic attempt outcome " + str(i))
		check(not inv.slots.has(a) and not inv.slots.has(b) and PlayerState.zeny == before - req.zeny, "exact donors and fee consumed " + str(i))
		check(main.refine == 7 and main.bonus_percent == 27.5 and main.cards.size() == 2 and main.socket_locked, "main upgrades/cards/lock preserved " + str(i))
		var restored := ItemInstance.from_dict(main.to_dict())
		check(restored.socket_failures == mini(i+1,3) if i < 3 else restored.slots == 3, "save roundtrip persists progression " + str(i))
		inv.slots[inv.slots.find(main)] = restored
		main = restored
	check(inv.count_of(&"socket_stone_1") == 1 and main.slots == 3, "fourth attempt guaranteed, one stone per attempt")
	check(not Forge.attempt(main, [], inv, PlayerState).ok, "fourth socket impossible")
	check(main.socket_card(&"card_reflection"), "third socket accepts real card")
	var old := ItemInstance.from_dict({"item_id":"garm_fang","slots":1,"refine":6})
	check(old.slots == 2 and old.refine == 6, "old one-slot weapon gains new base capacity")
	check(ItemInstance.from_dict({"item_id":"flame_sword","slots":3}).slots == 3, "existing third socket preserved")
	check(ItemInstance.from_dict({"item_id":"garm_fang","slots":0}).slots == 0, "old shop copy stays unsocketed")
	check(main.duplicate_instance().socket_locked and main.duplicate_instance().slots == 3, "instance copy preserves metadata")
	var unsold := inv.slots.find(inv.slots.filter(func(item): return item != null and item.item_id == &"socket_stone_1")[0])
	check(not PlayerState.sell_slot(unsold) and inv.count_of(&"socket_stone_1") == 1, "boss materials cannot be sold or silently discarded by shop")
	var a := ItemInstance.create(&"garm_fang")
	var b := ItemInstance.create(&"garm_fang")
	inv.add(high)
	inv.add(a)
	inv.add(b)
	var before_cash := PlayerState.zeny
	check(not Forge.attempt(high,[a,b],inv,PlayerState).ok and PlayerState.zeny == before_cash and inv.slots.has(a), "missing tier-three stone cannot consume materials")
	inv.add(ItemInstance.create(&"socket_stone_3"))
	PlayerState.zeny = 0
	check(not Forge.attempt(high,[a,b],inv,PlayerState).ok and inv.count_of(&"socket_stone_3") == 1 and inv.slots.has(b), "missing zeny cannot consume stone or donors")
	PlayerState.zeny = before_cash
	check(not Forge.attempt(high,[a,main],inv,PlayerState).ok, "different weapon donor rejected")
	inv.slots[inv.slots.find(a)] = null
	check(not Forge.attempt(high,[a,b],inv,PlayerState).ok, "stale donor reference rejected")
	var tiny := Inventory.new(1)
	tiny.add(ItemInstance.create(&"socket_shard_1", 11))
	check(Forge.combine(0,tiny).contains("เต็ม") and tiny.count_of(&"socket_shard_1") == 11, "full bag craft does not lose fragments")
	tiny.slots[0].count = 10
	check(Forge.combine(0,tiny).contains("สำเร็จ") and tiny.count_of(&"socket_stone_1") == 1, "craft reuses freed fragment slot")
	check(Forge.combine(0,tiny).contains("10"), "cannot craft with missing fragments")
	for id in [&"socket_stone_1", &"socket_shard_1", &"socket_stone_2", &"socket_shard_2", &"socket_stone_3", &"socket_shard_3"]:
		var d := GameData.get_item(id)
		check(d != null and d.icon != null and d.buy_price == 0 and d.sell_price == 0, "new material art/economy " + String(id))
	var bosses := [["baphomet","thorn_matriarch","gullveig_ember","wall_shieldbearer"],["stone_hrungnir","light_forsaken","radiant_alfr"],["false_judge","chained_garm"]]
	for index in range(3):
		for id in bosses[index]:
			var monster: MonsterData = load("res://data/monsters/%s.tres" % id)
			var shard := 0
			var stone := 0
			for drop in monster.drops:
				if drop.item_id == Forge.SHARDS[index] and drop.chance == 100.0: shard += 1
				if drop.item_id == Forge.STONES[index] and drop.chance == 10.0: stone += 1
			check(shard == 1 and stone == 1, "tiered boss drops " + id)
	check(SocketSystem.can_punch(ItemInstance.create(&"claymore")), "level 35 base service gap closed")
	check(SocketSystem.can_punch(ItemInstance.create(&"garm_fang")), "endgame base service reachable")
	check(not SocketSystem.requirements(ItemInstance.create(&"garm_fang")).destroy_on_fail, "base service also keeps main equipment")
	if "--preview" in OS.get_cmdline_user_args(): await preview()
	print("THIRD SOCKET: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func preview() -> void:
	PlayerState.inventory = Inventory.new(40)
	var main := ItemInstance.create(&"flame_sword", 1, 7, 2)
	main.bonus_percent = 25.0
	main.socket_failures = 2
	PlayerState.inventory.add(main)
	for i in range(3): PlayerState.inventory.add(ItemInstance.create(&"flame_sword", 1, i, 2))
	PlayerState.inventory.add(ItemInstance.create(&"socket_stone_1", 1))
	PlayerState.inventory.add(ItemInstance.create(&"socket_shard_1", 8))
	PlayerState.zeny = 150000
	get_window().size = Vector2i(1280,720)
	get_window().content_scale_size = Vector2i(1280,720)
	Events.socket_npc_opened.emit()
	var window: SocketWindow = UI.windows[&"socket"]
	window._normal.hide()
	window._third.show()
	window._third.main = main
	window._third.donors = [PlayerState.inventory.slots[1], PlayerState.inventory.slots[2]]
	window.refresh()
	check(window._third._button.disabled, "UI requires explicit material confirmation")
	window._third._accept.button_pressed = true
	check(not window._third._button.disabled, "UI enables only when selected recipe and confirmation match")
	await get_tree().process_frame
	await get_tree().process_frame
	window.reset_size()
	window.position = (get_viewport().get_visible_rect().size-window.size)*0.5
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png("res://output/third_socket/forge.png") == OK, "render new NPC forge UI")
	window._third._attempt()
	check(PlayerState.zeny == 120000 and PlayerState.inventory.slots[1] == null and PlayerState.inventory.slots[2] == null and PlayerState.inventory.slots[3] != null, "UI consumes chosen donors only")
	var after := PlayerState.zeny
	window._third._attempt()
	check(PlayerState.zeny == after, "repeat click cannot charge again")
