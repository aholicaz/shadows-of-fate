extends Node
## ★ เทสต์รอบ 87 — บอสไล่ทั่วสนาม · กรอบโดนตีกว้างเท่าตัวจริง · หลอดเลือดบอสกลางจอ ★

func run() -> void:
	var score := [0, 0]
	var check := func(n: String, c: bool, e: String = "") -> void:
		if c: score[0] += 1
		else:
			score[1] += 1
			print("  x FAIL: ", n, " ", e)

	await Game.change_map(&"gm_room", &"default")
	await get_tree().create_timer(1.2).timeout
	get_tree().paused = false
	PlayerState.set_flag(&"seen_intro_stormscar")
	PlayerState.stats.level = 60
	PlayerState.gm_god_mode = true
	var p = get_tree().get_first_node_in_group("player")
	var map = get_tree().get_first_node_in_group("map")
	var d: MonsterData = GameData.get_monster(&"stormscar")
	check.call("โหลดอสูรสายฟ้าได้", d != null and p != null and map != null)
	if d == null or p == null:
		print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
		get_tree().quit()
		return

	# =========================================================
	# 1) ค่าตั้งต้นของช่องใหม่
	# =========================================================
	print("\n-- 1) ค่าตั้งต้น --")
	check.call("★ เปิดกรอบโดนตีตามภาพจริง ★", d.hit_box_from_sprite)
	check.call("สัดส่วนกรอบโดนตีอยู่ในช่วงที่ควร",
		d.hit_box_width_ratio >= 0.3 and d.hit_box_width_ratio <= 1.0, "%f" % d.hit_box_width_ratio)
	check.call("★ บอสล็อกเป้าทั่วสนาม ★", d.boss_arena_aggro)
	check.call("★ บอสใช้หลอดเลือดใบใหญ่ ★", d.use_boss_bar)
	check.call("SpriteFit วัดความกว้างได้",
		float(SpriteFit.measure(d.sprite_frames, &"Idle").get("widest", 0.0)) > 0.0)

	var mob = load("res://scenes/monsters/monster.tscn").instantiate()
	mob.data = d
	mob.global_position = Vector2(2400, 700)
	map.add_child(mob)
	mob.set_home(mob.global_position)
	await get_tree().create_timer(1.0).timeout

	# =========================================================
	# 2) กรอบโดนตีกว้างขึ้นจริง
	# =========================================================
	print("\n-- 2) กรอบโดนตี --")
	var narrow: float = mob.body_size().x
	var wide: float = mob.hit_width()
	print("   กล่องชนพื้น %.0f px → กรอบโดนตี %.0f px" % [narrow, wide])
	check.call("★ กรอบโดนตีกว้างกว่ากล่องชนพื้น ★", wide > narrow + 1.0, "%.0f vs %.0f" % [wide, narrow])
	check.call("กรอบโดนตีไม่กว้างเกินตัวที่วาด",
		wide <= float(SpriteFit.measure(d.sprite_frames, mob.sprite.animation).get("widest", 0.0))
			* absf(mob.sprite.scale.x) + 1.0)
	var br: Rect2 = mob.body_rect()
	check.call("body_rect ใช้ความกว้างใหม่", absf(br.size.x - wide) < 1.0, "%.0f vs %.0f" % [br.size.x, wide])
	check.call("body_rect สูงเท่า Display Height", absf(br.size.y - d.display_height) < 2.0)
	check.call("เท้าบอสอยู่ขอบล่างของกรอบ", absf(br.position.y + br.size.y - mob.foot_position().y) < 2.0)
	# ระยะที่มอน "ตีเรา" ต้องไม่เปลี่ยนตาม (ไม่งั้นบอสจะหยุดไกลขึ้น)
	check.call("★ ระยะที่บอสตีเรายังคิดจากกล่องชนพื้นเหมือนเดิม ★",
		absf(mob.attack_reach() - (d.attack_range + narrow * 0.5)) < 1.0,
		"%.0f" % mob.attack_reach())

	# ยืนห่างเท่าไหร่ถึงฟันโดน
	var reach_ok := 0.0
	for dist in [60.0, 120.0, 180.0, 240.0, 300.0]:
		p.global_position = Vector2(mob.global_position.x - dist, 700)
		p.facing = 1
		await get_tree().process_frame
		if p.attack_rect(p.attack_range_x, p.attack_range_y, false).intersects(mob.body_rect(), true):
			reach_ok = dist
	print("   ฟันโดนได้ไกลสุด %.0f px (เดิมได้แค่ ~180)" % reach_ok)
	check.call("★ ยืนห่าง 240 px ยังฟันโดน ★", reach_ok >= 240.0, "%.0f" % reach_ok)

	# =========================================================
	# 3) พื้นข้างหน้า — เรย์ต้องยิงจากปลายเท้า
	# =========================================================
	print("\n-- 3) เช็คพื้นข้างหน้า --")
	mob.global_position = Vector2(2400, 700)
	await get_tree().create_timer(0.5).timeout
	check.call("★ ยืนกลางพื้นเรียบ → ข้างหน้ามีพื้น (ทั้งซ้ายและขวา) ★",
		mob._has_ground_ahead(-1) and mob._has_ground_ahead(1))

	# =========================================================
	# 4) บอสไล่จากไกล ๆ (ไกลกว่า Detect Range)
	# =========================================================
	print("\n-- 4) บอสไล่ทั่วสนาม --")
	check.call("ผู้เล่นอยู่ไกลกว่า Detect Range จริง", 900.0 > d.detect_range, "%.0f" % d.detect_range)
	p.global_position = Vector2(mob.global_position.x - 900.0, 700)
	p.velocity = Vector2.ZERO
	await get_tree().create_timer(0.4).timeout
	var x0: float = mob.global_position.x
	await get_tree().create_timer(1.2).timeout
	var moved: float = x0 - mob.global_position.x
	print("   บอสขยับเข้าหาผู้เล่น %.0f px ใน 1.2 วิ" % moved)
	check.call("★ บอสวิ่งเข้าหาผู้เล่นจริง (ไม่เดินวนอยู่กับที่) ★", moved > 200.0, "%.0f px" % moved)
	check.call("บอสอยู่ในสถานะไล่/ตี", mob.state == 2 or mob.state == 3, "state %d" % mob.state)

	# ปิดสวิตช์ = กลับไปเป็นแบบเดิม (รอ Detect Range)
	var d2: MonsterData = d.duplicate()
	d2.boss_arena_aggro = false
	var mob2 = load("res://scenes/monsters/monster.tscn").instantiate()
	mob2.data = d2
	mob2.global_position = Vector2(3600, 700)
	map.add_child(mob2)
	mob2.set_home(mob2.global_position)
	await get_tree().create_timer(1.2).timeout
	var far_enough: bool = absf(mob2.global_position.x - p.global_position.x) > d2.detect_range
	check.call("★ ปิดสวิตช์แล้วบอสไม่ไล่ (ยืนยันว่าสวิตช์ทำงาน) ★",
		far_enough and mob2.state != 2, "state %d" % mob2.state)
	mob2.queue_free()

	# =========================================================
	# 5) ท่าวิ่งเล่นช้าลงตามความเร็วจริง
	# =========================================================
	print("\n-- 5) ความเร็วท่าวิ่ง --")
	mob.set_physics_process(false)
	mob._play("Run", true)
	mob.velocity.x = -d.move_speed
	mob._sync_run_anim_speed()
	var fast: float = mob.sprite.speed_scale
	mob.velocity.x = -d.wander_speed
	mob._sync_run_anim_speed()
	var slow: float = mob.sprite.speed_scale
	print("   วิ่งเต็มสปีด %.0f → %.2f×   ·   เดินเตร่ %.0f → %.2f×"
		% [d.move_speed, fast, d.wander_speed, slow])
	check.call("★ วิ่งเต็มสปีด = ความเร็วภาพเต็ม ★", is_equal_approx(fast, 1.0), "%f" % fast)
	check.call("★ เดินช้า = ภาพช้าลงด้วย (ไม่ใช่วิ่งอยู่กับที่) ★", slow < fast - 0.1, "%f" % slow)
	check.call("ไม่ช้าจนหยุดนิ่ง", slow >= 0.3, "%f" % slow)
	mob._play("Idle", true)
	mob._sync_run_anim_speed()
	check.call("ท่าอื่นความเร็วภาพปกติ", is_equal_approx(mob.sprite.speed_scale, 1.0))
	mob.set_physics_process(true)

	# =========================================================
	# 6) หลอดเลือดบอสกลางจอ
	# =========================================================
	print("\n-- 6) หลอดเลือดบอส --")
	check.call("★ มีหลอดเลือดบอสใน UI ★", UI.boss_bar != null and UI.boss_bar is BossBar)
	check.call("★ บอสที่ใช้หลอดใหญ่ ไม่มีหลอดเล็กเหนือหัว ★", mob._hp_bar == null)
	if UI.boss_bar != null:
		var bar: BossBar = UI.boss_bar
		p.global_position = mob.global_position + Vector2(-300, 0)
		await get_tree().create_timer(0.6).timeout
		check.call("★ อยู่ใกล้บอส → หลอดโผล่ ★", bar.visible and bar.modulate.a > 0.5,
			"visible %s a %.2f" % [bar.visible, bar.modulate.a])
		check.call("★ โชว์ชื่อบอส ★", bar._name_label.text == String(d.display_name),
			"«%s»" % bar._name_label.text)
		check.call("โชว์คำโปรยบอส", bar._title_label.text == String(d.boss_title))
		check.call("ตัวเลขเลือดตรงกับบอส", bar._hp_label.text.begins_with(BossBar._comma(mob.hp)),
			bar._hp_label.text)
		# หลอดอยู่กลางจอด้านบน
		var scr: Vector2 = bar.size
		var cx: float = bar._box.position.x + bar._box.size.x * 0.5
		print("   หลอดกว้าง %.0f · กลางที่ x %.0f (จอกว้าง %.0f) · y %.0f"
			% [bar._bar_root.size.x, cx, scr.x, bar._box.position.y])
		check.call("★ หลอดอยู่กึ่งกลางจอแนวนอน ★", absf(cx - scr.x * 0.5) < 4.0)
		check.call("★ หลอดอยู่ด้านบนของจอ ★", bar._box.position.y < scr.y * 0.2, "%.0f" % bar._box.position.y)
		check.call("★ หลอดใหญ่ (กว้างเกิน 40% ของจอ) ★", bar._bar_root.size.x > scr.x * 0.4,
			"%.0f / %.0f" % [bar._bar_root.size.x, scr.x])
		# ตีบอสแล้วหลอดสั้นลง
		var w0: float = bar._fill.size.x
		mob.take_damage(int(d.max_hp * 0.4), false, 0)
		await get_tree().create_timer(0.3).timeout
		print("   ตีไป 40%% → หลอดจาก %.0f เหลือ %.0f (แถบไล่ตาม %.0f)"
			% [w0, bar._fill.size.x, bar._chase.size.x])
		check.call("★ ตีบอสแล้วหลอดสั้นลง ★", bar._fill.size.x < w0 - 10.0)
		check.call("★ แถบเหลืองไล่ตามหลัง (ยังยาวกว่าหลอดจริง) ★", bar._chase.size.x > bar._fill.size.x)
		# เดินหนีไกล ๆ → หลอดหาย
		p.global_position = mob.global_position + Vector2(-(BossBar.SHOW_RANGE + 400.0), 0)
		await get_tree().create_timer(0.8).timeout
		check.call("★ เดินหนีไกล → หลอดหายไป ★", bar.modulate.a < 0.4, "a %.2f" % bar.modulate.a)
		# บอสตาย → หลอดหาย
		p.global_position = mob.global_position + Vector2(-300, 0)
		await get_tree().create_timer(0.5).timeout
		mob.take_damage(d.max_hp * 2, false, 0)
		await get_tree().create_timer(0.8).timeout
		check.call("★ บอสตาย → หลอดหายไป ★", bar.modulate.a < 0.6, "a %.2f" % bar.modulate.a)

	PlayerState.gm_god_mode = false
	print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
	get_tree().quit()
