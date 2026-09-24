extends Node
## รอบ 163 — คลังไม่ล้นจอ · โรงตีเหล็ก · บอร์ดใบประกาศ · HUD เควสหลัก/รอง
var fails := 0
var passes := 0
const OUT := "res://output/r163/"

func ok(c: bool, m: String) -> void:
	if c: passes += 1; print("  PASS ", m)
	else: fails += 1; print("  FAIL ", m)

func shot(name: String) -> void:
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	var bg := TextureRect.new()
	bg.texture = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(OUT + "bg.jpg")))
	bg.size = Vector2(1280, 720)
	bg.modulate = Color(0.6, 0.65, 0.65)
	add_child(bg)
	await get_tree().process_frame
	SaveManager.end_session()
	PlayerState.new_game()
	UI.set_in_game(true)
	PlayerState.current_map_id = &"prontera_town"
	PlayerState.stats.level = 12
	PlayerState.zeny = 60000
	PlayerState.equipment.equip(Equipment.EquipSlot.WEAPON, ItemInstance.create(&"short_sword"))
	PlayerState.equipment.equip(Equipment.EquipSlot.HEAD, ItemInstance.create(&"cap"))
	PlayerState.inventory.add_id(&"phracon", 12)
	PlayerState.inventory.add_id(&"leather_jacket", 1)
	PlayerState.inventory.add_id(&"leather_jacket", 1)
	PlayerState.inventory.add_id(&"guard", 1)
	PlayerState.inventory.add_id(&"red_potion", 5)

	# ---------- 1 คลัง ----------
	Events.storage_opened.emit()
	for i in 5: await get_tree().process_frame
	var st = UI.windows[&"storage"]
	ok(st.size.y <= 680.0 and st.position.y >= 0.0, "คลังไม่ล้นจอ %s @ %s" % [st.size, st.position])
	await shot("1_storage")
	UI.close_all()

	# ---------- 2 โรงตีเหล็ก ----------
	Events.refine_npc_opened.emit()
	for i in 4: await get_tree().process_frame
	var bs: BlacksmithWindow = UI.windows[&"blacksmith"]
	ok(bs.visible and bs.tab == "refine", "เมนูตีบวก → โรงตีเหล็กแท็บตีบวก")
	ok(bs.size.x <= 1120.0 and bs.size.y <= 670.0 and bs.position.y >= 0.0, "โรงตีเหล็กพอดีจอ %s @ %s" % [bs.size, bs.position])
	ok(not UI.windows[&"refine"].visible, "หน้าตีบวกเดิมไม่เปิด")
	bs.select_source("eq:%d" % Equipment.EquipSlot.WEAPON)
	await shot("2_refine")
	var mats := ""
	for c in bs._d_mats.get_children():
		var a = c.find_child("MatAmount", true, false)
		if a: mats += a.text + "|"
	ok(mats.contains("ใช้ 1 · มี 12"), "แผงวัสดุ: %s" % mats)
	ok(bs._mat_box.get_child_count() > 3, "ซ้ายโชว์วัสดุที่ระบบใช้")
	var z0 := PlayerState.zeny
	var w := PlayerState.equipment.get_item(Equipment.EquipSlot.WEAPON)
	await bs.do_refine(0.0)
	ok(w.refine == 1, "ตีบวก +0→+1 สำเร็จ (100%%)")
	ok(PlayerState.inventory.count_of(&"phracon") == 11 and PlayerState.zeny < z0, "หักฟราคอน 1 + ซีนี")
	await get_tree().create_timer(2.2).timeout
	bs._on_tab("socket")
	await get_tree().process_frame
	var jacket_src := ""
	for i in PlayerState.inventory.size:
		var it := PlayerState.inventory.get_slot(i)
		if it != null and it.item_id == &"leather_jacket" and jacket_src == "": jacket_src = "inv:%d" % i
	bs.select_source(jacket_src)
	await shot("3_socket")
	ok(bs._d_action.text.begins_with("เจาะรู") or bs._d_action.text.contains("ไม่พอ"), "แท็บเจาะรูแสดงปุ่ม: %s" % bs._d_action.text)
	bs._on_tab("third")
	await shot("4_third")
	UI.close_all()
	Events.craft_npc_opened.emit()
	for i in 4: await get_tree().process_frame
	ok(bs.visible and bs.tab == "craft" and bs._page_craft.visible, "เมนูคราฟต์ → แท็บคราฟต์")
	var craft = UI.windows[&"craft"]
	ok(craft.is_visible_in_tree() and craft._list.get_child_count() > 0, "หน้าคราฟต์เดิมฝังอยู่และมีสูตร")
	await shot("5_craft")
	UI.close_all()
	ok(not UI.is_any_window_open(), "ปิดแล้วไม่มีหน้าต่างค้าง (คราฟต์ฝังไม่นับ)")
	Events.socket_npc_opened.emit()
	await get_tree().process_frame
	ok(bs.visible and bs.tab == "socket", "เมนูเจาะรู → แท็บเจาะรู")
	UI.close_all()

	# ---------- 3 บอร์ดใบประกาศ ----------
	UI.open_bounty_board(&"prontera_town")
	for i in 4: await get_tree().process_frame
	var bb: BountyBoardWindow = UI.windows[&"bounty"]
	ok(bb.visible and bb._cards.get_child_count() == 3, "บอร์ด 3 ใบ")
	var board: BountyBoard = PlayerState.bounties
	var spec: Dictionary = board.specs_of(&"prontera_town")[0]
	var qid := StringName(spec["id"])
	await shot("6_bounty_fresh")
	bb._accept(qid)
	ok(PlayerState.quests.is_active(qid), "กดรับใบ → active")
	for i in int(spec["count"]) - 3:
		PlayerState.quests.on_monster_killed(StringName(spec["monster"]))
	bb.refresh()
	await shot("7_bounty_progress")
	for i in 3:
		PlayerState.quests.on_monster_killed(StringName(spec["monster"]))
	bb.refresh()
	var turn = bb._cards.get_child(0).find_child("TurnIn", true, false)
	ok(turn != null, "ครบแล้วมีปุ่มส่งงาน")
	await shot("8_bounty_ready")
	var pts := board.points
	bb._turn_in(qid)
	ok(board.points == pts + 1 and not PlayerState.quests.is_active(qid), "ส่งงานได้แต้ม +1")
	await get_tree().process_frame
	ok(board.cooldown_left(&"prontera_town", 0) > 0.0, "ช่อง 1 พักบอร์ด")
	await shot("9_bounty_cooldown")
	UI.close_all()

	# ---------- 4 HUD เควสหลัก/รอง ----------
	var log := PlayerState.quests
	for x in [&"m1_adventurer_badge", &"m2_oath", &"hans_poring", &"tony_fabre"]:
		log.completed.append(x)
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud == null:
		for n in get_tree().root.get_children():
			var f = n.find_child("QuestTracker", true, false)
			if f: hud = f.get_parent()
	ok(hud != null, "เจอ HUD")
	if hud:
		ok(not HUD.is_side_quest(&"m5_old_mine_iron") and HUD.is_side_quest(&"m3_guild_bounty") and HUD.is_side_quest(StringName(spec["id"])), "แบ่งเควสหลัก/รองถูก")
		var nq = hud._next_quest(log)
		ok(nq != null and nq.id != &"m3_guild_bounty", "ภารกิจถัดไป (หลัก) ไม่ใช่เควสกิลด์: %s" % (nq.id if nq else "null"))
		hud._refresh_quest()
		ok(hud._side_row.visible and hud._side_title.text.contains("เควสรอง"), "มีป้ายเควสรอง (แนะนำใบประกาศใบแรก)")
		await shot("10_hud_next_plus_side")
		log.accept(&"m5_old_mine_iron")
		var spec2: Dictionary = board.specs_of(&"prontera_town")[1] if not board.specs_of(&"prontera_town")[1].is_empty() else {}
		if not spec2.is_empty():
			log.accept(StringName(spec2["id"]))
		hud._refresh_quest()
		ok(hud.quest_title.text == GameData.get_quest(&"m5_old_mine_iron").title, "บน = เควสหลักที่รับอยู่ (%s)" % hud.quest_title.text)
		ok(spec2.is_empty() or hud._side_title.text.begins_with("เควสรอง · ใบ"), "ล่าง = ใบประกาศที่รับอยู่ (%s)" % hud._side_title.text)
		await shot("11_hud_main_side")
	print("R163 RESULT: %d pass · %d fail" % [passes, fails])
	get_tree().quit(1 if fails > 0 else 0)
