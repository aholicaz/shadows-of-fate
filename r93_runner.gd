extends Node
## ★ เทสต์รอบ 93 — ฟัน 3 จังหวะ (คอมโบโจมตีปกติ) ★


## ศัตรูจำลอง — จำ "ตัวคูณดาเมจ" ที่ผู้เล่นส่งมาให้ทุกครั้งที่โดนตี (ไม่มีสุ่ม ไม่มี DEF มากวน)
class FakeEnemy extends Node2D:
	var hits: Array[float] = []
	var data: MonsterData = MonsterData.new()   # หลอดบอส/มินิแมพไล่อ่าน .data ของทุกตัวในกลุ่ม enemy
	var hp: int = 9999
	var max_hp: int = 9999
	func take_damage_from_player(mult: float, _use_matk: bool, _dir: int) -> void:
		hits.append(mult)
	func is_dead() -> bool:
		return false
	func foot_position() -> Vector2:
		return global_position
	func body_rect() -> Rect2:
		return Rect2(global_position.x - 40.0, global_position.y - 120.0, 80.0, 120.0)


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
	var p = get_tree().get_first_node_in_group("player")
	if p == null:
		print("  x FAIL: ไม่มีผู้เล่น")
		print("\n== รวม: ผ่าน 0 · ล้มเหลว 1 ==")
		get_tree().quit()
		return
	await get_tree().create_timer(0.6).timeout
	var st := PlayerState.stats
	st.aspd = 2.5   # ตีเร็วพอให้เทสต์ไม่ช้า แต่ท่ายังเล่นเห็น
	var gap: float = st.attack_interval()

	# จำสัญญาณทุกจังหวะที่เริ่มฟัน
	var log: Array = []
	p.combo_step_started.connect(func(step: int, anim: String, mult: float) -> void:
		log.append({"step": step, "anim": anim, "mult": mult}))

	# =========================================================
	# 1) ค่าตั้งต้น
	# =========================================================
	print("\n-- 1) ค่าตั้งต้น --")
	check.call("เปิดคอมโบอยู่", p.combo_enabled)
	check.call("มี 3 จังหวะ", p._combo_steps() == 3, "%d" % p._combo_steps())
	check.call("★ จังหวะ 3 แรงขึ้น 25% ★", is_equal_approx(p.combo_damage_mults[2], 1.25), "%f" % p.combo_damage_mults[2])
	check.call("จังหวะ 1-2 ดาเมจปกติ", is_equal_approx(p.combo_damage_mults[0], 1.0) and is_equal_approx(p.combo_damage_mults[1], 1.0))
	check.call("หน้าต่างต่อคอมโบ 0.7 วิ", is_equal_approx(p.combo_window, 0.7))
	check.call("จำคลิกระหว่างฟันเปิดอยู่", p.combo_buffer_input)

	# =========================================================
	# 2) เลือกท่าต่อจังหวะ — ยืมท่าสกิลจนกว่าจะวาดใหม่
	# =========================================================
	print("\n-- 2) ท่าต่อจังหวะ --")
	var base: String = p.attack_animation()
	print("  อาวุธที่ถือ → ท่าพื้นฐาน %s" % base)
	var a0: String = p.combo_attack_animation(0)
	var a1: String = p.combo_attack_animation(1)
	var a2: String = p.combo_attack_animation(2)
	print("  จังหวะ 1=%s · 2=%s · 3=%s" % [a0, a1, a2])
	check.call("จังหวะ 1 = ท่าพื้นฐานของอาวุธ", a0 == base)
	var has_slash: bool = p._has_anim(base + "_slash")
	var has_bash: bool = p._has_anim(base + "_bash")
	print("  ท่าที่มีให้ยืม: _slash=%s _bash=%s" % [has_slash, has_bash])
	if has_slash:
		check.call("★ จังหวะ 2 ยืมท่า _slash ★", a1 == base + "_slash", a1)
	elif has_bash:
		check.call("จังหวะ 2 ไม่มี _slash → ยืม _bash", a1 == base + "_bash", a1)
	else:
		check.call("จังหวะ 2 ไม่มีท่าให้ยืม → ใช้ท่าพื้นฐาน", a1 == base, a1)
	if has_bash:
		check.call("★ จังหวะ 3 ยืมท่า _bash ★", a2 == base + "_bash", a2)
	check.call("ท่าจังหวะ 3 ต่างจากจังหวะ 1 (เห็นการเปลี่ยนท่าจริง)", a2 != a0, "%s == %s" % [a2, a0])

	# ★ วาดท่าใหม่ชื่อ <ท่าอาวุธ>_2 แล้วระบบต้องหยิบไปใช้ก่อนท่ายืมโดยอัตโนมัติ
	var sf: SpriteFrames = p.sprite.sprite_frames
	var real_base: String = p._real_anim(base)
	var custom := real_base + "_2"
	sf.add_animation(custom)
	sf.add_frame(custom, sf.get_frame_texture(real_base, 0))
	p._anim_lookup.clear()
	check.call("★ วาดท่า %s แล้ว จังหวะ 2 สลับไปใช้เอง ★" % custom, p.combo_attack_animation(1) == custom,
		p.combo_attack_animation(1))
	sf.remove_animation(custom)
	p._anim_lookup.clear()
	check.call("ลบท่านั้นออก กลับไปยืมท่าเดิม", p.combo_attack_animation(1) == a1)

	# =========================================================
	# 3) คลิก 3 ครั้งติด → ท่าเปลี่ยน 1→2→3 แล้ววนกลับ 1
	# =========================================================
	print("\n-- 3) ลำดับจังหวะ --")
	p.reset_combo()
	log.clear()
	for i in 4:
		p.start_attack()
		await get_tree().create_timer(gap + 0.08).timeout
	await get_tree().create_timer(0.1).timeout
	var steps: Array = []
	var anims: Array = []
	for e in log:
		steps.append(e.step)
		anims.append(e.anim)
	print("  ลำดับที่ได้: %s" % [steps])
	print("  ท่าที่เล่น: %s" % [anims])
	check.call("★ ฟัน 4 ครั้ง ได้จังหวะ 1→2→3→1 ★", steps == [0, 1, 2, 0], "%s" % [steps])
	check.call("ท่าที่เล่นจริงเปลี่ยนตามจังหวะ (จังหวะ 3 ≠ จังหวะ 1)", anims.size() >= 3 and anims[2] != anims[0])
	check.call("ตัวคูณที่ส่งไป [1, 1, 1.25, 1]", log.size() == 4 and is_equal_approx(log[2].mult, 1.25) and is_equal_approx(log[3].mult, 1.0))

	# =========================================================
	# 4) เว้นนานเกินหน้าต่าง → กลับไปจังหวะ 1
	# =========================================================
	print("\n-- 4) หมดอายุคอมโบ --")
	p.reset_combo()
	log.clear()
	p.start_attack()
	await get_tree().create_timer(gap + 0.08).timeout
	p.start_attack()
	await get_tree().create_timer(gap + 0.08).timeout
	check.call("ฟัน 2 ครั้ง อยู่จังหวะ 2 แล้ว (ถัดไปจะเป็น 3)", p.combo_step == 2, "%d" % p.combo_step)
	await get_tree().create_timer(p.combo_window + 0.3).timeout
	p.start_attack()
	await get_tree().create_timer(gap + 0.08).timeout
	check.call("★ เว้นเกิน %.1f วิ → ครั้งถัดไปกลับเป็นจังหวะ 1 ★" % p.combo_window, log.size() == 3 and log[2].step == 0,
		"%s" % [log.map(func(e): return e.step)])

	# =========================================================
	# 5) ดาเมจจริงที่ศัตรูได้รับ — จังหวะ 3 ต้อง x1.25
	# =========================================================
	print("\n-- 5) ดาเมจต่อจังหวะ --")
	var fe := FakeEnemy.new()
	fe.add_to_group("enemy")
	get_tree().current_scene.add_child(fe)
	fe.global_position = p.foot_position() + Vector2(p.facing * 60.0, 0.0)
	p.reset_combo()
	for i in 3:
		p.start_attack()
		await get_tree().create_timer(gap + 0.08).timeout
	await get_tree().create_timer(0.1).timeout
	print("  ตัวคูณที่ศัตรูได้รับ: %s" % [fe.hits])
	check.call("โดนครบ 3 ครั้ง", fe.hits.size() == 3, "%d" % fe.hits.size())
	check.call("★ จังหวะ 1-2 ดาเมจปกติ · จังหวะ 3 = 1.25 เท่า ★",
		fe.hits.size() == 3 and is_equal_approx(fe.hits[0], 1.0) and is_equal_approx(fe.hits[1], 1.0) and is_equal_approx(fe.hits[2], 1.25))
	fe.queue_free()

	# =========================================================
	# 6) คลิกซ้ำระหว่างฟัน → ต่อจังหวะถัดไปเองทันทีที่ท่าจบ
	# =========================================================
	print("\n-- 6) จำคลิกระหว่างฟัน --")
	p.reset_combo()
	log.clear()
	p.start_attack()
	await get_tree().create_timer(gap * 0.4).timeout
	p._combo_queued = true          # = ผู้เล่นคลิกซ้ำกลางท่า
	await get_tree().create_timer(gap * 0.7 + 0.15).timeout
	check.call("★ คลิกกลางท่า → จังหวะ 2 เริ่มเองหลังท่า 1 จบ (ไม่ต้องคลิกซ้ำ) ★", log.size() == 2 and log[1].step == 1,
		"%s" % [log.map(func(e): return e.step)])
	await get_tree().create_timer(gap + 0.2).timeout

	# =========================================================
	# 7) ใช้สกิล / ปิดสวิตช์ → คอมโบรีเซ็ต
	# =========================================================
	print("\n-- 7) รีเซ็ต --")
	p.reset_combo()
	p.start_attack()
	await get_tree().create_timer(gap + 0.08).timeout
	check.call("อยู่จังหวะ 2", p.combo_step == 1)
	p.reset_combo()
	check.call("reset_combo() กลับไปจังหวะ 1", p.combo_step == 0)

	p.combo_enabled = false
	log.clear()
	for i in 3:
		p.start_attack()
		await get_tree().create_timer(gap + 0.08).timeout
	var off_steps: Array = log.map(func(e): return e.step)
	var off_mults: Array = log.map(func(e): return e.mult)
	check.call("ปิดสวิตช์ → ทุกครั้งเป็นจังหวะ 1 ท่าเดิม ดาเมจปกติ (เหมือนก่อนรอบ 93)",
		off_steps == [0, 0, 0] and off_mults.all(func(m): return is_equal_approx(m, 1.0)), "%s %s" % [off_steps, off_mults])
	p.combo_enabled = true

	print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
	get_tree().quit()
