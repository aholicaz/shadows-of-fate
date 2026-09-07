extends Node
## ★ เทสต์รอบ 80 — ห้อง GM: แมพทดสอบ · หน้าต่างเครื่องมือ (F10) · เรียกมอน/ไอเทม · ตั้งเลเวล · อมตะ · ตีทีเดียวตาย ★

func run() -> void:
	var score := [0, 0]
	var check := func(n: String, c: bool, e: String = "") -> void:
		if c: score[0] += 1
		else:
			score[1] += 1
			print("  x FAIL: ", n, " ", e)

	# =========================================================
	# 1) ทะเบียนแมพ + ปุ่มลัด + หน้าต่างถูกลงทะเบียน
	# =========================================================
	print("\n-- 1) ทะเบียน --")
	check.call("★ ทะเบียนแมพมี gm_room ★", Game.MAPS.has(&"gm_room"))
	check.call("gm_room มีชื่อไทย", Game.map_display_name(&"gm_room") != "gm_room")
	check.call("gm_room ไม่ใช่เมือง (ตายแล้วไม่เกิดที่นี่)", not Game.is_town(&"gm_room"))
	check.call("★ มีปุ่มลัด toggle_gm (F10) ★", InputMap.has_action("toggle_gm"))
	check.call("★ หน้าต่าง gm ลงทะเบียนแล้ว ★", UI.windows.has(&"gm"))
	var win = UI.windows.get(&"gm", null)
	check.call("หน้าต่าง gm เป็น GMWindow", win != null and win is GMWindow)

	# =========================================================
	# 2) แมพห้อง GM — โหลดได้ · ไม่มีประตู/ที่เกิดมอน · ผู้เล่นยืนบนพื้น
	# =========================================================
	print("\n-- 2) แมพห้อง GM --")
	await Game.change_map(&"gm_room", &"default")
	await get_tree().create_timer(1.0).timeout
	get_tree().paused = false
	var map = get_tree().get_first_node_in_group("map")
	check.call("★ เข้าห้อง GM ได้ ★", map != null and map.map_id == &"gm_room")
	if map == null:
		print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
		get_tree().quit()
		return
	check.call("★ ไม่มีประตูสักบาน (ไม่เชื่อมกับแมพไหน) ★",
		get_tree().get_nodes_in_group("portal").is_empty(),
		"%d" % get_tree().get_nodes_in_group("portal").size())
	check.call("★ ไม่มีตัวเกิดมอนอัตโนมัติ ★", map.get_node("Spawners").get_child_count() == 0)
	check.call("มอนในแมพเริ่มต้น = 0", get_tree().get_nodes_in_group("enemy").is_empty())
	var p = get_tree().get_first_node_in_group("player")
	await get_tree().create_timer(0.8).timeout
	check.call("ผู้เล่นยืนบนพื้น", p != null and p.is_on_floor())
	check.call("มีจุดเกิด default + arena",
		map.get_node_or_null("SpawnPoints/default") != null and map.get_node_or_null("SpawnPoints/arena") != null)
	# พื้นกว้างพอให้เดินได้ทั้งแมพ (ขอบแมพไม่ถูกหุบเข้ามา)
	var b: Rect2 = map.map_bounds
	check.call("แมพกว้างเกิน 4000 px", b.size.x >= 4000.0, "%f" % b.size.x)
	# เดินไปสุดขวาได้
	if p != null:
		p.global_position = Vector2(b.position.x + b.size.x - 150.0, 600.0)
		await get_tree().create_timer(0.8).timeout
		check.call("★ เดินไปสุดขอบขวาแล้วยังยืนบนพื้น ★", p.is_on_floor(), "%v" % p.global_position)
		p.global_position = map.get_node("SpawnPoints/default").global_position
		await get_tree().create_timer(0.5).timeout

	# =========================================================
	# 3) แท็บมอน — เรียกมอนมาเกิด · ลบมอนทั้งแมพ
	# =========================================================
	print("\n-- 3) เรียกมอน --")
	var gm: GMWindow = win
	gm.show_window()
	await get_tree().process_frame
	check.call("เปิดหน้าต่างแล้วเห็น", gm.visible)
	gm.refresh()
	await get_tree().process_frame
	check.call("★ รายชื่อมอนไม่ว่าง ★", gm._mon_list.item_count > 0, "%d" % gm._mon_list.item_count)
	check.call("★ รายชื่อไอเทมไม่ว่าง ★", gm._item_list.item_count > 0, "%d" % gm._item_list.item_count)
	# ค้นหาแล้วรายการต้องแคบลง
	gm._mon_search.text = "poring"
	gm._fill_monsters()
	var narrowed: int = gm._mon_list.item_count
	check.call("ค้นหา «poring» แล้วเจอ", narrowed > 0)
	gm._mon_search.text = ""
	gm._fill_monsters()
	check.call("ล้างคำค้นแล้วรายการกลับมาเต็ม", gm._mon_list.item_count > narrowed)
	# เลือกมอนตัวแรกแล้วเรียก 3 ตัว
	gm._mon_list.select(0)
	gm._mon_count.value = 3
	gm._spawn_selected()
	await get_tree().create_timer(0.6).timeout
	var spawned := get_tree().get_nodes_in_group("enemy").size()
	check.call("★ กดเกิดมอน 3 ตัว → มีมอน 3 ตัว ★", spawned == 3, "%d" % spawned)
	# มอนที่เกิดต้องอยู่ในแมพ (ไม่หลุดขอบ) และมีข้อมูล
	var ok_inside := true
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.data == null:
			ok_inside = false
		if not b.has_point(e.global_position):
			ok_inside = false
	check.call("มอนที่เรียกมามีข้อมูล + อยู่ในขอบแมพ", ok_inside)
	gm._clear_monsters()
	await get_tree().process_frame
	await get_tree().process_frame
	check.call("★ กดลบมอนทั้งแมพ → เหลือ 0 ★", get_tree().get_nodes_in_group("enemy").is_empty())

	# =========================================================
	# 4) แท็บไอเทม — ใส่ของลงกระเป๋า · ชุดของสำเร็จรูป
	# =========================================================
	print("\n-- 4) ไอเทม --")
	gm._item_search.text = "red_potion"
	gm._fill_items()
	check.call("ค้นหา red_potion เจอ", gm._item_list.item_count > 0)
	var before := PlayerState.inventory.count_of(&"red_potion")
	gm._item_list.select(0)
	gm._item_count.value = 25
	gm._give_selected()
	var after := PlayerState.inventory.count_of(&"red_potion")
	check.call("★ ใส่ยาแดง 25 ขวดเข้ากระเป๋า ★", after - before == 25, "%d → %d" % [before, after])
	gm._give_kit("หินตีบวก x99")
	check.call("★ ชุดหินตีบวก → มีฟราคอน ★", PlayerState.inventory.count_of(&"phracon") >= 99,
		"%d" % PlayerState.inventory.count_of(&"phracon"))
	var kit_ok := true
	for kit_name in GMWindow.QUICK_KITS.keys():
		for entry in GMWindow.QUICK_KITS[kit_name]:
			if GameData.get_item(StringName(entry[0])) == null:
				kit_ok = false
				print("    (ไม่มีไอเทม %s ในชุด %s)" % [entry[0], kit_name])
	check.call("★ ของในชุดสำเร็จรูปมีจริงทุกชิ้น ★", kit_ok)

	# =========================================================
	# 5) แท็บตัวละคร — ตั้งเลเวล · แต้ม · ซีนี
	# =========================================================
	print("\n-- 5) ตัวละคร --")
	gm._set_level(50, 30)
	check.call("★ ตั้งเลเวล 50 / อาชีพ 30 ★", PlayerState.stats.level == 50 and PlayerState.stats.job_level == 30,
		"%d/%d" % [PlayerState.stats.level, PlayerState.stats.job_level])
	check.call("เลเวลขึ้นแล้วได้แต้มสเตตัส", PlayerState.stats.stat_points > 0, "%d" % PlayerState.stats.stat_points)
	var hp50 := PlayerState.stats.max_hp
	check.call("เลือดสูงสุดเพิ่มตามเลเวล", hp50 > 100, "%d" % hp50)
	check.call("ตั้งเลเวลแล้วเลือดเต็ม", PlayerState.stats.hp == hp50, "%d/%d" % [PlayerState.stats.hp, hp50])
	gm._set_level(PlayerStats.MAX_LEVEL, PlayerStats.MAX_JOB_LEVEL)
	check.call("★ ปุ่มเลเวลสูงสุด → Lv99/50 ★",
		PlayerState.stats.level == 99 and PlayerState.stats.job_level == 50)
	check.call("เลเวลสูงสุดแล้วเลือดมากกว่า Lv50", PlayerState.stats.max_hp > hp50)
	gm._set_level(1, 1)
	check.call("★ รีเซ็ตกลับ Lv1 ได้ ★", PlayerState.stats.level == 1 and PlayerState.stats.job_level == 1)
	var z := PlayerState.zeny
	PlayerState.add_zeny(100000)
	check.call("เพิ่มซีนีได้", PlayerState.zeny == z + 100000)
	gm._set_level(40, 20)

	# =========================================================
	# 6) อมตะ — ผู้เล่นไม่เสียเลือด
	# =========================================================
	print("\n-- 6) อมตะ --")
	PlayerState.gm_god_mode = false
	PlayerState.heal_hp(PlayerState.stats.max_hp, false)
	var hp_before: int = PlayerState.stats.hp
	p.take_damage(50, 0.0, 1)
	await get_tree().create_timer(0.1).timeout
	check.call("ปิดอมตะ → เสียเลือดปกติ", PlayerState.stats.hp < hp_before, "%d → %d" % [hp_before, PlayerState.stats.hp])
	PlayerState.heal_hp(PlayerState.stats.max_hp, false)
	PlayerState.gm_god_mode = true
	hp_before = PlayerState.stats.hp
	for i in range(5):
		p.take_damage(999, 0.0, 1)
		await get_tree().create_timer(0.05).timeout
	check.call("★ เปิดอมตะ → โดน 5 ครั้งเลือดไม่ลด ★", PlayerState.stats.hp == hp_before,
		"%d → %d" % [hp_before, PlayerState.stats.hp])
	check.call("อมตะแล้วไม่ตาย", not PlayerState.is_dead())
	PlayerState.gm_god_mode = false

	# =========================================================
	# 7) ตีทีเดียวตาย
	# =========================================================
	print("\n-- 7) ตีทีเดียวตาย --")
	PlayerState.gm_one_hit = false
	gm._mon_search.text = "gullveig"
	gm._fill_monsters()
	if gm._mon_list.item_count == 0:
		gm._mon_search.text = ""
		gm._fill_monsters()
	gm._mon_list.select(0)
	gm._mon_count.value = 1
	gm._spawn_selected()
	await get_tree().create_timer(0.5).timeout
	var mobs := get_tree().get_nodes_in_group("enemy")
	check.call("เรียกบอสมาทดสอบได้", mobs.size() == 1)
	if mobs.size() == 1:
		var boss = mobs[0]
		var full: int = boss.hp
		# ตีธรรมดาหลายที (มีโอกาสพลาดได้) — บอสต้องเสียเลือดแต่ยังไม่ตาย
		gm._set_level(PlayerStats.MAX_LEVEL, PlayerStats.MAX_JOB_LEVEL)
		for i in range(10):
			boss.take_damage_from_player(1.0)
			await get_tree().create_timer(0.05).timeout
		check.call("ปิดตีทีเดียวตาย → บอสเสียเลือดแต่ยังไม่ตาย", boss.hp > 0 and boss.hp < full,
			"%d/%d" % [boss.hp, full])
		PlayerState.gm_one_hit = true
		boss.take_damage_from_player(1.0)
		await get_tree().create_timer(0.15).timeout
		check.call("★ เปิดตีทีเดียวตาย → บอสเลือดหมดทันที ★", boss.hp <= 0, "%d" % boss.hp)
		PlayerState.gm_one_hit = false
	gm._clear_monsters()
	await get_tree().process_frame

	# =========================================================
	# 8) แท็บระบบ — ธงเนื้อเรื่อง · วาปข้ามแมพ
	# =========================================================
	print("\n-- 8) ระบบ --")
	check.call("รายการแมพในกล่องเลือกครบ", gm._map_option.item_count == Game.MAPS.size(),
		"%d/%d" % [gm._map_option.item_count, Game.MAPS.size()])
	var flags_ok := true
	for entry in GMWindow.STORY_FLAGS:
		var flag := StringName(entry[1])
		PlayerState.clear_flag(flag)
		(gm._flag_boxes[flag] as CheckBox).button_pressed = true
		if not PlayerState.has_flag(flag):
			flags_ok = false
			print("    (ติ๊กแล้วธง %s ไม่ขึ้น)" % flag)
		(gm._flag_boxes[flag] as CheckBox).button_pressed = false
		if PlayerState.has_flag(flag):
			flags_ok = false
			print("    (ปลดติ๊กแล้วธง %s ยังอยู่)" % flag)
	check.call("★ ติ๊ก/ปลดติ๊กธงเนื้อเรื่องทั้ง %d ธงได้ ★" % GMWindow.STORY_FLAGS.size(), flags_ok)
	# วาปไปแมพอื่นแล้วกลับห้อง GM
	gm._warp_to(&"prontera_town")
	await _wait_map(&"prontera_town")
	get_tree().paused = false
	check.call("★ วาปจากห้อง GM ไปพรอนเทราได้ ★", PlayerState.current_map_id == &"prontera_town",
		"%s" % PlayerState.current_map_id)
	check.call("วาปแล้วหน้าต่างปิดเอง", not gm.visible)
	gm._warp_to(&"gm_room")
	await _wait_map(&"gm_room")
	get_tree().paused = false
	check.call("★ กดปุ่ม «เข้าห้อง GM» กลับมาได้ ★", PlayerState.current_map_id == &"gm_room",
		"%s" % PlayerState.current_map_id)
	# ห้อง GM ไม่ทำให้ "เมืองล่าสุด" เพี้ยน
	check.call("ห้อง GM ไม่ถูกจำเป็นเมืองล่าสุด", PlayerState.last_town != &"gm_room",
		"%s" % PlayerState.last_town)

	# =========================================================
	# 9) ห้อง GM ไม่ไปยุ่งกับเกมจริง
	# =========================================================
	print("\n-- 9) ไม่กระทบเกมจริง --")
	var linked := 0
	for mid in Game.MAPS.keys():
		if mid == &"gm_room":
			continue
		var scene: PackedScene = load(Game.MAPS[mid])
		if scene == null:
			continue
		var inst = scene.instantiate()
		var portals = inst.get_node_or_null("Portals")
		if portals != null:
			for pt in portals.get_children():
				if "target_map" in pt and pt.target_map == &"gm_room":
					linked += 1
					print("    (แมพ %s มีประตูไปห้อง GM)" % mid)
		inst.free()
	check.call("★ ไม่มีแมพไหนมีประตูไปห้อง GM ★", linked == 0)
	check.call("ค่า gm ทั้งสองปิดอยู่ตอนจบเทสต์",
		not PlayerState.gm_god_mode and not PlayerState.gm_one_hit)

	print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
	get_tree().quit()


## รอจนเปลี่ยนแมพเสร็จจริง (แมพที่มีภาพใหญ่โหลดนานกว่าเวลาคงที่)
func _wait_map(want: StringName) -> void:
	for _i in range(80):
		await get_tree().create_timer(0.1).timeout
		if not Game._is_changing and PlayerState.current_map_id == want:
			break
	await get_tree().create_timer(0.4).timeout
