extends Node
## ★ เทสต์รอบ 44 ★ กระตุก (SpriteFit กลาง · แมพทุ่งวิหารไม่มี TileMap) · ดรอป/ราคา · AI ไล่ไม่หยุด · แมพใหม่ · เอฟเฟกต์ฟัน

func run() -> void:
	var score := [0, 0]
	var check := func(n: String, c: bool, e: String = "") -> void:
		if c: score[0] += 1
		else:
			score[1] += 1
			print("  x FAIL: ", n, " ", e)

	# =========================================================
	# 1) แมพทุ่งวิหาร: ไม่มี TileMap แล้ว + Sprite2D ภาพเดียว + กล่องชนยังอยู่
	# =========================================================
	var field_scene: PackedScene = load("res://scenes/maps/prontera_field.tscn")
	check.call("★ prontera_field โหลดได้ ★", field_scene != null)
	var st := field_scene.get_state()
	var has_tilemap := false
	var has_bg := false
	var bg_pos := Vector2.ZERO
	var bg_centered := true
	var body_parent := ""
	for i in range(st.get_node_count()):
		var t := st.get_node_type(i)
		var nm := String(st.get_node_name(i))
		if t == "TileMap" or t == "TileMapLayer": has_tilemap = true
		if nm == "Background" and t == "Sprite2D":
			has_bg = true
			for j in range(st.get_node_property_count(i)):
				var pn := String(st.get_node_property_name(i, j))
				if pn == "position": bg_pos = st.get_node_property_value(i, j)
				if pn == "centered": bg_centered = st.get_node_property_value(i, j)
		if nm == "StaticBody2D": body_parent = String(st.get_node_path(i, true))
	check.call("★★ ไม่มี TileMap 22,000 กระเบื้องแล้ว ★★", not has_tilemap)
	check.call("★ มี Sprite2D ฉากหลังภาพเดียว ★", has_bg)
	check.call("ตำแหน่งภาพตรงกับกระเบื้องเดิม (-480,-208) ไม่จัดกึ่งกลาง", bg_pos == Vector2(-480, -208) and not bg_centered, str(bg_pos))
	check.call("กล่องชนพื้น/กำแพงย้ายไปใต้ Terrain", body_parent.contains("Terrain"), body_parent)
	var fsize := FileAccess.open("res://scenes/maps/prontera_field.tscn", FileAccess.READ).get_length()
	check.call("★ ไฟล์ฉากเล็กลงมาก (< 40 KB เดิม 769 KB) ★", fsize < 40000, str(fsize))

	# =========================================================
	# 2) SpriteFit กลาง — วัดครั้งเดียว ใช้ซ้ำข้ามตัว/ข้ามแมพ
	# =========================================================
	check.call("มีคลาส SpriteFit", ClassDB.class_exists("RefCounted") and ResourceLoader.exists("res://scripts/core/sprite_fit.gd"))
	SpriteFit.clear()
	await Game.change_map(&"prontera_field", &"default")
	await get_tree().create_timer(0.8).timeout
	UI.touch.set_mode(TouchControls.Mode.OFF)
	var player = get_tree().get_first_node_in_group("player")
	check.call("★ เข้าทุ่งวิหารได้ (ไม่มี TileMap) ★", player != null and get_tree().get_first_node_in_group("map").map_id == &"prontera_field")
	var pframes: SpriteFrames = player.get_node("AnimatedSprite2D").sprite_frames
	check.call("★★ อุ่นเครื่องตอนโหลดแมพ: ทุกท่าผู้เล่นถูกวัดไว้แล้ว ★★",
		SpriteFit.is_cached(pframes, &"Idle") and SpriteFit.is_cached(pframes, pframes.get_animation_names()[-1]))
	var poring := GameData.get_monster(&"poring")
	check.call("★ มอนในแมพ (โพริง) ถูกวัดไว้ล่วงหน้าทุกท่า ★", SpriteFit.is_cached(poring.sprite_frames, &"Idle"))
	var n0 := SpriteFit.measured_count
	var again := SpriteFit.measure(pframes, &"Idle")
	check.call("วัดซ้ำไม่นับเพิ่ม (ใช้แคช)", SpriteFit.measured_count == n0 and not again.is_empty())
	check.call("ผลวัดมี bottom_use/dx_use (ค่ากลางกันตัวเด้ง)", again.frames.size() > 0 and again.frames[0].has("bottom_use") and again.frames[0].has("dx_use"))
	# ผู้เล่นยืนบนพื้น: offset.y คงที่ระหว่างเฟรม Idle
	player.global_position = Vector2(600, 400)
	await get_tree().create_timer(0.8).timeout
	var ps: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
	var ys: Array = []
	for i in 10:
		await get_tree().process_frame
		ys.append(ps.offset.y)
	check.call("Idle ไม่เด้ง (offset.y ค่าเดียว)", ys.min() == ys.max(), str(ys))
	# มอนเกิดใหม่หลังจากนี้ต้องไม่วัดเพิ่ม
	var n1 := SpriteFit.measured_count
	await get_tree().create_timer(2.5).timeout
	var enemies := get_tree().get_nodes_in_group("enemy")
	check.call("★ มอนเกิดในแมพแล้วไม่ต้องวัดภาพเพิ่ม (ไม่กระตุก) ★", enemies.size() > 0 and SpriteFit.measured_count == n1,
		"มอน %d วัดเพิ่ม %d" % [enemies.size(), SpriteFit.measured_count - n1])
	# มอนที่ตายแล้วดรอปของ: ฉากของตกถูก preload
	check.call("ฉากของตก preload ไว้", enemies.size() > 0 and enemies[0].DROPPED_ITEM_SCENE != null)

	# =========================================================
	# 3) ดรอป/ราคา
	# =========================================================
	var bad: Array = []
	for mid in GameData.monsters.keys():
		var md: MonsterData = GameData.get_monster(mid)
		for dr in md.drops:
			var it := GameData.get_item(dr.item_id)
			if it == null: continue
			if it.type == ItemData.Type.CARD:
				var lo := 2.0 if md.is_boss else 0.5
				var hi := 2.5 if md.is_boss else 0.9
				if dr.chance < lo - 0.001 or dr.chance > hi + 0.001: bad.append("%s %s %.2f" % [mid, dr.item_id, dr.chance])
			elif it.type == ItemData.Type.WEAPON or it.type == ItemData.Type.ARMOR:
				# ★ รอบ 58 — ผู้ใช้ตั้งใจให้บอสดรอปของสวมใส่ง่ายกว่ามอนธรรมดา (บอสมีคูลดาวน์เกิด) → บอส ≤ 8% ★
				var cap := 8.0 if md.is_boss else 3.0
				if dr.chance > cap + 0.001: bad.append("%s %s %.2f" % [mid, dr.item_id, dr.chance])
			elif dr.item_id == &"phracon" or dr.item_id == &"emveretarcon":
				if dr.chance > 5.001: bad.append("%s %s %.2f" % [mid, dr.item_id, dr.chance])
	check.call("★★ การ์ด 0.5-0.9% / บอส 2-2.5% / ของสวมใส่ ≤3% (บอส ≤8%) / หิน ≤5% ทุกตัว ★★", bad.is_empty(), str(bad))
	var cp := GameData.get_monster(&"poring")
	var cw := GameData.get_monster(&"wolf")
	var cb := GameData.get_monster(&"baphomet")
	var chance := func(md: MonsterData, iid: StringName) -> float:
		for dr in md.drops:
			if dr.item_id == iid: return dr.chance
		return -1.0
	check.call("★ ไล่ระดับ: การ์ดโพริง Lv1 (0.9) > หมาป่า Lv13 (0.8) ★", chance.call(cp, &"card_poring") > chance.call(cw, &"card_wolf"))
	check.call("การ์ดบาฟโฟเมท (บอส Lv50) = 2.0%", is_equal_approx(chance.call(cb, &"card_baphomet"), 2.0))
	check.call("หินหมาป่า Lv13 ≈ 4.02%", is_equal_approx(chance.call(cw, &"phracon"), 4.02), str(chance.call(cw, &"phracon")))
	check.call("★ ราคาขายการ์ด 500 / การ์ดบอส 1000 ★",
		GameData.get_item(&"card_poring").sell_price == 500 and GameData.get_item(&"card_baphomet").sell_price == 1000 and GameData.get_item(&"card_king_poring").sell_price == 1000)
	# ★ รอบ 47 ทับรอบ 44 — ราคาขายของสวมใส่ถูกหาร 2 อีกที (ดูเทสต์ r47) ★
	check.call("★ ของสวมใส่ยังขายได้ (ราคารอบ 47 = ฐานรอบ 44 ÷ 2) ★",
		GameData.get_item(&"wolf_cloak").sell_price == 2240 and GameData.get_item(&"katana").sell_price == 4800,
		"%d / %d" % [GameData.get_item(&"wolf_cloak").sell_price, GameData.get_item(&"katana").sell_price])
	var bad_sell: Array = []
	for iid in GameData.items.keys():
		var it: ItemData = GameData.get_item(iid)
		if (it.type == ItemData.Type.WEAPON or it.type == ItemData.Type.ARMOR) and it.buy_price > 0 and it.sell_price >= it.buy_price:
			bad_sell.append(String(iid))
	check.call("★ ไม่มีของสวมใส่ที่ขายคืนได้ ≥ ราคาซื้อ (กันซื้อ-ขายวน) ★", bad_sell.is_empty(), str(bad_sell))
	check.call("ของร้าน falchion ขาย 880 (รอบ 47 หาร 2 จาก 1760)",
		GameData.get_item(&"falchion").sell_price == 880, str(GameData.get_item(&"falchion").sell_price))

	# =========================================================
	# 4) AI — โดนตีแล้วไล่ไม่หยุด ไม่ติด leash
	# =========================================================
	PlayerState.stats.level = 1
	PlayerState.refresh(true)
	PlayerState.revive(1.0)
	var m: Node = null
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.data != null and e.data.id == &"poring" and not e.is_dead(): m = e; break
	check.call("มีโพริงให้เทสต์", m != null)
	if m != null:
		m.data = m.data.duplicate()
		m.data.leash_range = 300.0
		m.data.detect_range = 200.0
		m.data.move_speed = 260.0
		m.data.jump_force = 0.0
		m.data.wander_pause_chance = 0.0
		m.hp = 999999
		m.spawn_position = m.global_position
		check.call("ยังไม่ล็อกเป้า", not m.is_aggro_locked())
		m.take_damage(1, false, 0)
		check.call("★ โดนตี = ล็อกเป้าทันที ★", m.is_aggro_locked())
		# ผู้เล่นยืนไกลกว่า leash (300) มาก ๆ — มอนต้องยังไล่มา
		player.global_position = m.global_position + Vector2(900, 0)
		player.velocity = Vector2.ZERO
		var start_x: float = m.global_position.x
		var d0: float = absf(m.global_position.x - player.global_position.x)
		await get_tree().create_timer(2.5).timeout
		var d1: float = absf(m.global_position.x - player.global_position.x)
		check.call("★★ ไล่ตามเกินระยะ leash/detect (ระยะลดจาก %.0f → %.0f) ★★" % [d0, d1], d1 < d0 - 200.0)
		check.call("ยังไล่อยู่ (CHASE/ATTACK) แม้ไกลบ้าน > leash", m.state == m.State.CHASE or m.state == m.State.ATTACK, str(m.state))
		check.call("ออกจากบ้านไกลกว่า leash 300 แล้วยังไม่หันกลับ", absf(m.global_position.x - m.spawn_position.x) > 300.0 or d1 < 250.0)
		# ★ เกิน 8 วิแล้วยังไม่เลิกโกรธ ★ (เดิม AGGRO_MEMORY 8 วิ)
		m._aggro_timer = -1.0
		await get_tree().physics_frame
		await get_tree().physics_frame
		check.call("★ ความโกรธไม่จางตามเวลาอีกแล้ว ★", m._aggro and m.is_aggro_locked())
		# ผู้เล่นตาย = เลิกไล่
		PlayerState.take_damage(999999)
		await get_tree().create_timer(0.3).timeout
		check.call("ผู้เล่นตาย → ปลดล็อกเป้า", not m.is_aggro_locked())
		PlayerState.revive(1.0)
		player._dead = false
	# มอนดุ (AGGRESSIVE) เห็นแล้วล็อก
	var wolf_d := GameData.get_monster(&"wolf")
	check.call("หมาป่าเป็นมอนดุ", wolf_d.ai_type == MonsterData.AIType.AGGRESSIVE)

	# =========================================================
	# 5) แมพ — สลับมอน · dark_forest_2 · ประตู
	# =========================================================
	check.call("★ Game.MAPS มี dark_forest_2 ★", Game.MAPS.has(&"dark_forest_2") and ResourceLoader.exists(Game.MAPS[&"dark_forest_2"]))
	var types := func(path: String, node_name: String) -> Array:
		var sc: PackedScene = load(path)
		var s2 := sc.get_state()
		for i in range(s2.get_node_count()):
			if String(s2.get_node_name(i)) == node_name:
				for j in range(s2.get_node_property_count(i)):
					if String(s2.get_node_property_name(i, j)) == "monster_types":
						var out: Array = []
						for md in s2.get_node_property_value(i, j): out.append(String(md.id))
						return out
		return []
	var f2: Array = types.call("res://scenes/maps/asgard_forest_2.tscn", "MapSpawner")
	check.call("★ ป่าสนธยา = drops, chonchon, wolf ★", f2 == ["drops", "chonchon", "wolf"], str(f2))
	var df: Array = types.call("res://scenes/maps/dark_forest.tscn", "MapSpawner")
	check.call("★ ป่าเงาลึก = hornet, wolf, lunatic ★", df == ["hornet", "wolf", "lunatic"], str(df))
	check.call("★ ป่าเงาลึกไม่มีบาฟโฟเมทแล้ว ★", types.call("res://scenes/maps/dark_forest.tscn", "BaphometBoss").is_empty())
	var df2: Array = types.call("res://scenes/maps/dark_forest_2.tscn", "MapSpawner")
	check.call("★ ป่าเงาลึกชั้นใน = munak, orc_warrior, baphomet_jr ★", df2 == ["munak", "orc_warrior", "baphomet_jr"], str(df2))
	check.call("★ บาฟโฟเมทย้ายมาป่าเงาลึกชั้นใน ★", types.call("res://scenes/maps/dark_forest_2.tscn", "Boss_baphomet") == ["baphomet"])
	# เดินจริง: dark_forest → dark_forest_2 (ไม่ล็อก) → ประตูไป iron_road ล็อก + บอสเฝ้า
	PlayerState.set_flag(&"seen_intro_baphomet")
	await Game.change_map(&"dark_forest", &"default")
	await get_tree().create_timer(0.6).timeout
	var to2 = null
	var to_iron = null
	for p in get_tree().get_nodes_in_group("portal"):
		if p.target_map == &"dark_forest_2": to2 = p
		if p.target_map == &"iron_road": to_iron = p
	check.call("★ ป่าเงาลึกมีประตูไปป่าเงาลึกชั้นใน ★", to2 != null)
	check.call("ป่าเงาลึกไม่มีประตูไปทางเหล็กตรง ๆ แล้ว", to_iron == null)
	check.call("ประตูนี้ไม่ล็อก", to2 != null and not to2.is_locked())
	if to2 != null:
		to2._enter()
		await get_tree().create_timer(1.2).timeout
		# ★ รอบ 90 ★ รอจนโหลดแมพเสร็จจริง (แคชแมพลดเหลือ 2 แล้ว บางแมพต้องโหลดใหม่จริง ๆ)
		for _w in range(60):
			if not Game._is_changing:
				break
			await get_tree().create_timer(0.1).timeout
		await get_tree().create_timer(0.4).timeout
		var mp = get_tree().get_first_node_in_group("map")
		check.call("★★ ผ่านประตูถึงป่าเงาลึกชั้นใน (บท 1) ★★", mp.map_id == &"dark_forest_2" and mp.chapter == 1, String(mp.map_id))
		player = get_tree().get_first_node_in_group("player")
		var gate = null
		var back = null
		for p in get_tree().get_nodes_in_group("portal"):
			if p.target_map == &"iron_road": gate = p
			if p.target_map == &"dark_forest": back = p
		check.call("มีประตูไปทางเหล็ก + กลับป่าเงาลึก", gate != null and back != null)
		PlayerState.story_flags.erase(&"chapter2_open")
		check.call("★ ประตูไปบท 2 ล็อกธง chapter2_open ★", gate != null and gate.is_locked())
		# บอสเฝ้าใกล้ประตู
		var baph = null
		var tw := 0.0
		while tw < 6.0 and baph == null:
			await get_tree().create_timer(0.3).timeout
			tw += 0.3
			for e in get_tree().get_nodes_in_group("enemy"):
				if e.data != null and e.data.id == &"baphomet": baph = e
		check.call("★ บาฟโฟเมทเกิดในแมพ ★", baph != null)
		if baph != null and gate != null:
			check.call("★ ยืนเฝ้าใกล้ประตูทางเหล็ก (< 400 px) ★", absf(baph.global_position.x - gate.global_position.x) < 400.0,
				"%.0f vs %.0f" % [baph.global_position.x, gate.global_position.x])
		check.call("จุดเกิด from_iron_road / from_dark_forest มีครบ",
			mp.get_node_or_null("SpawnPoints/from_iron_road") != null and mp.get_node_or_null("SpawnPoints/from_dark_forest") != null)
		# กลับป่าเงาลึกด้วยประตูซ้าย → ต้องไปโผล่ที่ from_dark_forest_2
		if back != null:
			back._enter()
			await get_tree().create_timer(1.2).timeout
			# ★ รอจนโหลดแมพเสร็จจริง ★ (แมพที่มีภาพใหญ่โหลดนานกว่า 1.2 วิ ได้)
			for _i in range(60):
				if not Game._is_changing:
					break
				await get_tree().create_timer(0.1).timeout
			await get_tree().create_timer(0.4).timeout
			var mp2 = get_tree().get_first_node_in_group("map")
			check.call("★ เดินกลับป่าเงาลึกได้ ★", mp2.map_id == &"dark_forest")
			var sp = mp2.get_node_or_null("SpawnPoints/from_dark_forest_2")
			var pl = get_tree().get_first_node_in_group("player")
			check.call("โผล่ที่จุด from_dark_forest_2 (ข้างประตูขวา)", sp != null and pl != null and absf(pl.global_position.x - sp.global_position.x) < 50.0)
	# iron_road ประตูซ้าย → dark_forest_2
	var ir: PackedScene = load("res://scenes/maps/iron_road.tscn")
	var irs := ir.get_state()
	var ir_ok := false
	for i in range(irs.get_node_count()):
		if String(irs.get_node_name(i)) == "ToForest":
			for j in range(irs.get_node_property_count(i)):
				if String(irs.get_node_property_name(i, j)) == "target_map" and irs.get_node_property_value(i, j) == &"dark_forest_2": ir_ok = true
	check.call("★ ทางเหล็ก ประตูซ้าย → ป่าเงาลึกชั้นใน ★", ir_ok)

	# =========================================================
	# 6) เอฟเฟกต์ฟันธรรมดา
	# =========================================================
	await Game.change_map(&"prontera_field", &"default")
	await get_tree().create_timer(0.6).timeout
	player = get_tree().get_first_node_in_group("player")
	check.call("มีไฟล์เอฟเฟกต์ฟัน", ResourceLoader.exists("res://data/sprites/fx_attack.tres") and ResourceLoader.exists("res://Sprites/effects/attack_slash.png"))
	var fx_frames: SpriteFrames = load("res://data/sprites/fx_attack.tres")
	# ★ ผู้ใช้วาดเอฟเฟกต์ฟันเองแล้ว (SlashFX 5A Attack) — จำนวนเฟรมเปลี่ยนได้ ไม่ล็อกตัวเลข ★
	check.call("มีท่า slash + slash2 และมีเฟรมพอเป็นแอนิเมชัน",
		fx_frames.has_animation(&"slash") and fx_frames.has_animation(&"slash2")
		and fx_frames.get_frame_count(&"slash") >= 4, str(fx_frames.get_frame_count(&"slash")))
	var before := 0
	for c in get_tree().get_first_node_in_group("map").get_children():
		if c is SkillEffect: before += 1
	player.start_attack()
	await get_tree().create_timer(0.12).timeout
	var fx: Array = []
	for c in get_tree().get_first_node_in_group("map").get_children():
		if c is SkillEffect and c.name.contains("attack"): fx.append(c)
	check.call("★★ ตีปกติแล้วมีเอฟเฟกต์รอยฟันเกิดในแมพ ★★", fx.size() >= 1, str(fx.size()))
	if fx.size() >= 1:
		check.call("เอฟเฟกต์ตามตัวละคร + ไม่ทำดาเมจเอง", fx[0]._follow == player and not fx[0]._damage)
		check.call("อยู่ข้างหน้าตัวละคร (ตามทิศหัน)", signf(fx[0].global_position.x - player.global_position.x) == signf(player.facing))
		check.call("ครั้งแรกไม่พลิก (ฟันลง)", not fx[0]._sprite.flip_v)
	await get_tree().create_timer(1.2).timeout
	player.start_attack()
	await get_tree().create_timer(0.12).timeout
	var fx2: Array = []
	for c in get_tree().get_first_node_in_group("map").get_children():
		if c is SkillEffect and c.name.contains("attack") and not c._ending: fx2.append(c)
	check.call("★ ตีครั้งที่ 2 = ฟันสวนขึ้น (flip_v) ★", fx2.size() >= 1 and fx2[-1]._sprite.flip_v)
	await get_tree().create_timer(0.8).timeout
	var left := 0
	for c in get_tree().get_first_node_in_group("map").get_children():
		if c is SkillEffect and c.name.contains("attack") and is_instance_valid(c) and not c._ending: left += 1
	check.call("เอฟเฟกต์หายเองหลังจบ", left == 0, str(left))
	player.attack_effect_enabled = false
	await get_tree().create_timer(0.5).timeout
	player.start_attack()
	await get_tree().create_timer(0.12).timeout
	var fx3 := 0
	for c in get_tree().get_first_node_in_group("map").get_children():
		if c is SkillEffect and c.name.contains("attack") and not c._ending: fx3 += 1
	check.call("ปิด Attack Effect Enabled แล้วไม่เกิด", fx3 == 0)

	print("\n=== ผ่าน %d / ล้มเหลว %d ===" % [score[0], score[1]])
	get_tree().quit(0 if score[1] == 0 else 1)
