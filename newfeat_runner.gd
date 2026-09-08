extends Node

func run() -> void:
	var score := [0, 0]
	var check := func(n: String, c: bool, e: String = "") -> void:
		if c: score[0] += 1
		else:
			score[1] += 1
			print("  x FAIL: ", n, " ", e)

	# =========================================================
	# 1) ปุ่ม WASD
	# =========================================================
	for a in ["move_left", "move_right", "move_up", "move_down", "jump", "toggle_menu"]:
		check.call("มีปุ่ม %s" % a, InputMap.has_action(a))

	var keys := {}
	for a in ["move_left", "move_right", "move_up", "move_down", "jump"]:
		var codes := []
		for ev in InputMap.action_get_events(a):
			if ev is InputEventKey:
				codes.append(ev.physical_keycode)
		keys[a] = codes
	print("  ปุ่มเดิน: ", keys)
	check.call("A = เดินซ้าย", KEY_A in keys["move_left"])
	check.call("D = เดินขวา", KEY_D in keys["move_right"])
	check.call("W = กระโดด", KEY_W in keys["jump"])
	check.call("S = ลง", KEY_S in keys["move_down"])

	# =========================================================
	# 2) ความเร็วเดิน
	# =========================================================
	print("  ความเร็วพื้นฐาน: %.0f (เดิม 300)" % PlayerStats.BASE_MOVE_SPEED)
	check.call("วิ่งไวขึ้นกว่าเดิม", PlayerStats.BASE_MOVE_SPEED > 300.0,
		"%.0f" % PlayerStats.BASE_MOVE_SPEED)

	await Game.change_map(&"prontera_field", &"default")
	await _await_map()
	var player = get_tree().get_first_node_in_group("player")
	var map = get_tree().current_scene

	# =========================================================
	# 3) ปุ่มลัดอยู่ข้างหลอดเลือด (บนสุด)
	# =========================================================
	var hud = UI.hud
	check.call("มีแถวปุ่มลัด", hud.hotkey_box != null)
	check.call("มีปุ่มยาแดง", hud.potion_button != null)
	check.call("มีปุ่มเมนู", hud.menu_button != null)
	await get_tree().process_frame
	await get_tree().process_frame
	var hp_y: float = hud.hp_bar.global_position.y
	var hk_y: float = hud.hotkey_box.global_position.y
	print("  หลอดเลือดอยู่ y=%.0f  ปุ่มลัดอยู่ y=%.0f x=%.0f"
		% [hp_y, hk_y, hud.hotkey_box.global_position.x])
	# ★ รอบ 21: แถบปุ่มลัดเป็นแผงแยก อยู่ "ข้างขวา" แผงหลอดเลือด (แถวเดียวกัน) ★
	check.call("ปุ่มลัดอยู่ข้างขวาหลอดเลือด",
		hud.hotkey_box.global_position.x > hud.hp_bar.global_position.x + hud.hp_bar.size.x,
		"%.0f vs %.0f" % [hud.hotkey_box.global_position.x,
			hud.hp_bar.global_position.x + hud.hp_bar.size.x])
	check.call("แถบปุ่มลัดเป็นแผงแยก ไม่ได้อยู่ในแผงหลอดเลือด",
		not hud.top_panel.is_ancestor_of(hud.hotkey_box))
	check.call("ปุ่มลัดอยู่ครึ่งบนของจอ", hk_y < 320.0, "%.0f" % hk_y)

	# =========================================================
	# 4) เมนูระบบ: เซฟ / โหลด / เริ่มใหม่
	# =========================================================
	var sysw = UI.windows.get(&"system", null)
	check.call("มีหน้าต่างเมนูระบบ", sysw != null)
	PlayerState.stats.level = 7
	PlayerState.zeny = 12345
	SaveManager.delete_save(2)
	sysw._do_save(2)
	check.call("เซฟลงช่อง 3 ได้", SaveManager.has_save(2))
	var info: Dictionary = SaveManager.slot_info(2)
	print("  ข้อมูลเซฟช่อง 3: ", info)
	check.call("เซฟเก็บเลเวลถูก", int(info.get("level", 0)) == 7, str(info.get("level")))

	PlayerState.new_game()
	check.call("เริ่มเกมใหม่แล้วเลเวลกลับเป็น 1", PlayerState.stats.level == 1,
		str(PlayerState.stats.level))
	check.call("เริ่มเกมใหม่แล้วเงินกลับเป็น 1000", PlayerState.zeny == 1000,
		str(PlayerState.zeny))
	check.call("เริ่มเกมใหม่แล้วได้ของเริ่มต้น",
		PlayerState.inventory.count_of(&"red_potion") == 10,
		str(PlayerState.inventory.count_of(&"red_potion")))
	check.call("ไฟล์เซฟยังอยู่หลังเริ่มใหม่", SaveManager.has_save(2))
	check.call("โหลดเซฟกลับมาได้", SaveManager.load_game(2))
	check.call("โหลดแล้วเลเวลกลับมา 7", PlayerState.stats.level == 7,
		str(PlayerState.stats.level))
	SaveManager.delete_save(2)

	# =========================================================
	# 5) ของดรอป ต้องกด F เก็บ
	# =========================================================
	var drop_scene: PackedScene = load("res://scenes/items/dropped_item.tscn")
	var d = drop_scene.instantiate()
	map.add_child(d)
	d.global_position = player.foot_position() + Vector2(30, -30)
	d.setup(ItemInstance.create(&"jellopy", 2, 0))
	check.call("ของดรอปไม่เก็บอัตโนมัติแล้ว", not d.auto_pickup)
	await get_tree().create_timer(1.5).timeout
	check.call("ยืนทับเฉย ๆ ไม่เก็บให้", is_instance_valid(d))
	var hint: Label = d.get_node_or_null("PickupHint")
	check.call("มีป้ายบอกให้กด F", hint != null and hint.visible,
		str(hint.visible) if hint else "ไม่มีป้าย")
	if hint: print("  ป้ายบนไอเทม: '%s'" % hint.text)
	check.call("กด F แล้วเก็บได้", player.pickup_nearby())
	await get_tree().process_frame
	check.call("ของหายไปเข้ากระเป๋า", not is_instance_valid(d))

	# =========================================================
	# 6) วาป: ไม่เด้ง popup แล้ว ต้องกด F
	# =========================================================
	var portals := get_tree().get_nodes_in_group("portal")
	check.call("มีประตูในแมพ", portals.size() > 0)
	var portal = portals[0]
	check.call("ปิดกล่องยืนยันแล้ว", not portal.require_confirm)
	check.call("ไม่เข้าเองตอนเดินชน", not portal.auto_enter)

	var before_map: StringName = (await _await_map()).map_id
	player.global_position = portal.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(0.5).timeout
	check.call("เดินผ่านวาปแล้วไม่มี popup เด้ง", not UI.is_asking())
	check.call("เดินผ่านวาปแล้วเกมไม่หยุด", not get_tree().paused)
	check.call("เดินผ่านวาปเฉย ๆ ยังไม่เปลี่ยนแมพ",
		get_tree().current_scene.map_id == before_map)
	var phint: Label = portal.get_node_or_null("EnterHint")
	check.call("มีป้าย กด F ที่ประตู", phint != null and phint.visible,
		str(phint.visible) if phint else "ไม่มีป้าย")
	if phint: print("  ป้ายที่ประตู: '%s'" % phint.text)

	# กด F จริง
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().create_timer(1.5).timeout
	var now = await _await_map()
	print("  หลังกด F อยู่แมพ: ", now.map_id if now != null and "map_id" in now else "null")
	check.call("กด F แล้วเข้าประตูได้", now != null and "map_id" in now and now.map_id != before_map,
		str(now.map_id) if now != null and "map_id" in now else "null")

	# =========================================================
	# 7) เมือง Asgard กว้างขึ้น
	# =========================================================
	# รอบ 44: รอให้การเปลี่ยนแมพจากประตูจบก่อน (ไม่งั้น change_map ถัดไปถูกเมิน)
	while Game._is_changing:
		await get_tree().process_frame
	await Game.change_map(&"prontera_town", &"default")
	await get_tree().create_timer(1.0).timeout
	var town = get_tree().current_scene
	var b: Rect2 = town.map_bounds
	print("  ขอบเขตเมือง: %s (กว้าง %.0f px)" % [str(b), b.size.x])
	# ★ รอบ 74 ★ ขอบเมือง = ขอบภาพฉาก (ลบระยะเผื่อขอบ) — ผู้ใช้เปลี่ยนภาพเป็นใบกว้างขึ้นได้ตลอด
	var ax: Vector2 = town.art_span()
	var want: float = (ax.y - town.art_edge_margin) - (ax.x + town.art_edge_margin)
	check.call("เมืองกว้างเท่าภาพฉาก (ภาพ %.0f px)" % (ax.y - ax.x), absf(b.size.x - want) < 2.0,
		"แมพ %.0f · ควรได้ %.0f" % [b.size.x, want])

	# เดินไปสุดขอบซ้าย-ขวาแล้วยังมีพื้นให้ยืน
	var p2 = get_tree().get_first_node_in_group("player")
	var space: PhysicsDirectSpaceState2D = p2.get_world_2d().direct_space_state
	var ok_left := false
	var ok_right := false
	for x in [b.position.x + 60.0, b.position.x + b.size.x - 60.0]:
		var q := PhysicsRayQueryParameters2D.create(Vector2(x, b.position.y), Vector2(x, b.position.y + b.size.y))
		q.collision_mask = 1
		var hit: Dictionary = space.intersect_ray(q)
		if x < 0: ok_left = not hit.is_empty()
		else: ok_right = not hit.is_empty()
	check.call("ขอบซ้ายสุดมีพื้นให้ยืน", ok_left)
	check.call("ขอบขวาสุดมีพื้นให้ยืน", ok_right)

	print("\n=== ผ่าน %d / ล้มเหลว %d ===" % [score[0], score[1]])
	get_tree().quit(0 if score[1] == 0 else 1)


## ★ รอบ 90 ★ รอจนฉากปัจจุบันเป็น "แมพจริง" (ไม่ใช่ฉากคั่นตอนโหลด)
## แคชแมพลดเหลือ 2 แล้ว บางแมพต้องโหลดใหม่จริง ๆ จึงรอด้วยเวลาคงที่ไม่ได้
func _await_map() -> Node:
	for _i in range(80):
		if not Game._is_changing:
			var sc := get_tree().current_scene
			if sc != null and "map_id" in sc:
				await get_tree().create_timer(0.2).timeout
				return get_tree().current_scene
		await get_tree().create_timer(0.1).timeout
	return get_tree().current_scene
