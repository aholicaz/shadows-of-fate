extends Node
## ★ เทสต์รอบ 95 — แก้ผลข้างเคียงของรอบ 94 ★
##   1) ท่าอ้างอิงต้องเป็น "ท่าที่เล่นจริง" (ถือดาบ = Idle_blade) ไม่ใช่ชื่อดิบ Idle
##   2) ดาเมจต้องไม่ออกช้าเกินไป
##   3) ครบไม้สุดท้ายแล้วต้องไม่มีไม้เกินโผล่มาเอง


const CELL := 512


static func _frame(body_h: int, sword_up: int, sword_fwd: int, foot_y: int = 460) -> ImageTexture:
	var img := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var bw := 120
	var bx := (CELL - bw) / 2
	var by := foot_y - body_h
	img.fill_rect(Rect2i(bx, by, bw, body_h), Color(1, 1, 1, 1))
	if sword_up > 0:
		img.fill_rect(Rect2i(bx + bw / 2 - 3, maxi(0, by - sword_up), 6, sword_up), Color(1, 1, 1, 1))
	if sword_fwd > 0:
		img.fill_rect(Rect2i(bx + bw, by + body_h / 3, sword_fwd, 6), Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)


static func _anim(sf: SpriteFrames, name: String, specs: Array, fps: float = 10.0) -> void:
	sf.add_animation(name)
	sf.set_animation_speed(name, fps)
	sf.set_animation_loop(name, false)
	for sp in specs:
		sf.add_frame(name, _frame(sp[0], sp[1], sp[2]))


class FakeEnemy extends Node2D:
	var hits: Array[float] = []
	var data: MonsterData = MonsterData.new()
	var hp: int = 9999
	var max_hp: int = 9999
	func take_damage_from_player(mult: float, _m: bool, _d: int) -> void:
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
	await get_tree().create_timer(0.5).timeout
	var old_sf: SpriteFrames = p.sprite.sprite_frames

	# =========================================================
	# 1) ★ ท่าอ้างอิงต้องเป็นท่าที่เล่นจริง (ตามอาวุธที่ถือ) ★
	# =========================================================
	print("\n-- 1) ท่าอ้างอิงตามอาวุธ --")
	# เลียนแบบงานจริง: Idle (ตัวเปล่า) วาดใหญ่และไม่มีดาบ
	# ส่วน Idle_Blade วาดเล็กกว่า + มีดาบเลยหัวขึ้นไป → สัดส่วน "ลำตัวต่อความสูงรวม" ต่างกัน
	# ตรงนี้แหละที่ทำให้เลือกท่าอ้างอิงผิดแล้วทุกท่าโตเกิน
	var sf := SpriteFrames.new()
	_anim(sf, "Idle", [[600, 0, 60], [600, 0, 60]])            # ลำตัว 600 · สูงรวม 600
	_anim(sf, "Idle_Blade", [[300, 60, 40], [300, 60, 40]])    # ลำตัว 300 · สูงรวม 360
	_anim(sf, "Dash", [[150, 30, 200], [150, 30, 200]])        # ลำตัว 150 · สูงรวม 180
	_anim(sf, "Attack_Blade", [[300, 0, 40], [300, 0, 60], [300, 0, 90], [300, 0, 140], [300, 0, 200]])
	p.sprite.sprite_frames = sf
	p.clear_fit_cache()
	p.fit_uniform_body = true
	p.fit_reference_anim = &"Idle"
	p.fit_uniform_body_skip = PackedStringArray()   # ปิดรายการยกเว้นไว้ก่อน จะได้เห็นผลตรง ๆ

	var suffix: String = p.weapon_suffix()
	print("  อาวุธที่ถือ → คำต่อท้ายท่า '%s'" % suffix)
	var resolved: String = p._resolve_anim("Idle")
	print("  ท่าอ้างอิงที่ระบบเลือก: %s" % resolved)
	if suffix.to_lower() == "blade":
		check.call("★ ถือดาบ → ท่าอ้างอิงคือ Idle_Blade ไม่ใช่ Idle ★", resolved == "Idle_Blade", resolved)
	else:
		check.call("ท่าอ้างอิงเลือกได้", resolved != "")

	var idle_info: Dictionary = p._fit_info(StringName(resolved))
	var old_scale: float = p.auto_fit_height / maxf(1.0, idle_info.tallest)
	check.call("★ ท่ายืนที่เล่นจริงสเกลเท่าเดิมเป๊ะ (ตัวละครไม่โตขึ้น) ★",
		absf(idle_info.scale - old_scale) < 0.001, "%.4f vs %.4f" % [idle_info.scale, old_scale])

	# ถ้าเผลอไปใช้ Idle (ตัวเปล่า) เป็นตัวตั้ง ทุกท่าจะโตเกิน — ยืนยันว่าบั๊กเดิมมีจริง
	var m_bare: Dictionary = SpriteFit.measure(sf, &"Idle", {}, true)
	var bad_target: float = m_bare.body_med * (p.auto_fit_height / m_bare.tallest)
	var good_target: float = p._body_on_screen_target()
	print("  เป้าลำตัว: ถูก %.1f px · ถ้าใช้ Idle ตัวเปล่า %.1f px" % [good_target, bad_target])
	if suffix.to_lower() == "blade":
		check.call("★ ยืนยันบั๊กรอบ 94: ใช้ Idle ตัวเปล่าจะทำให้ทุกท่าโตเกิน ★", bad_target > good_target * 1.10,
			"%.1f vs %.1f" % [bad_target, good_target])
		var dash_bad: float = bad_target / float(SpriteFit.measure(sf, &"Dash", {}, true).body_med)
		var dash_now: float = p._fit_info(&"Dash").scale
		var dash_old: float = p.auto_fit_height / maxf(1.0, float(SpriteFit.measure(sf, &"Dash", {}, true).tallest))
		print("  ท่าพุ่ง: เดิม %.3f · บั๊กรอบ 94 %.3f (+%.0f%%) · ตอนนี้ %.3f (+%.0f%%)"
			% [dash_old, dash_bad, 100.0 * (dash_bad / dash_old - 1.0), dash_now, 100.0 * (dash_now / dash_old - 1.0)])
		check.call("★ ท่าพุ่งไม่บวมเหมือนรอบ 94 อีกแล้ว ★", dash_now < dash_bad * 0.95,
			"%.3f vs %.3f" % [dash_now, dash_bad])

	# =========================================================
	# 2) รายการยกเว้น — ท่าที่ไม่อยากให้ระบบยุ่ง
	# =========================================================
	print("\n-- 2) รายการยกเว้น --")
	p.fit_uniform_body_skip = PackedStringArray(["Dash"])
	p.clear_fit_cache()
	var d_info: Dictionary = p._fit_info(&"Dash")
	var d_old: float = p.auto_fit_height / maxf(1.0, d_info.tallest)
	check.call("★ ท่าที่อยู่ในรายการยกเว้น ใช้สเกลเดิมเป๊ะ ★", absf(d_info.scale - d_old) < 0.001,
		"%.4f vs %.4f" % [d_info.scale, d_old])
	check.call("เทียบชื่อไม่สนตัวพิมพ์ใหญ่เล็ก", p._fit_skips("dash") and p._fit_skips("DASH"))
	check.call("ท่าอื่นยังถูกจัดขนาดตามปกติ", not p._fit_skips("Attack_Blade"))

	# =========================================================
	# 3) ดาเมจต้องไม่ออกช้าเกินไป
	# =========================================================
	print("\n-- 3) ดาเมจไม่ออกช้าเกิน --")
	# ท่านี้ดาบยื่นเพิ่มเรื่อย ๆ จนเฟรมสุดท้าย — ของเดิมจะเลือกเฟรมท้าย (ฟันไปแล้วดาเมจค่อยตามมา)
	p.attack_hit_auto = true
	p.combo_hit_frames = PackedInt32Array()
	p.attack_hit_max_fraction = 0.6
	var hf: int = p.attack_hit_frame_of("Attack_Blade")
	print("  Attack_Blade (ยื่น 40/60/90/140/200 · 5 เฟรม) → เฟรม %d" % hf)
	check.call("★ ไม่เลือกเฟรมสุดท้าย (4) อีกแล้ว ★", hf < 4, "%d" % hf)
	check.call("★ ออกดาเมจไม่เกิน 60%% ของท่า (เฟรม 3 จาก 5) ★", hf <= 3, "%d" % hf)

	p.attack_hit_max_fraction = 1.0
	check.call("ยืนยันว่าเพดานคือตัวที่ทำให้เร็วขึ้น (ปลดเพดาน → กลับไปเฟรมท้าย)",
		p.attack_hit_frame_of("Attack_Blade") == 4, "%d" % p.attack_hit_frame_of("Attack_Blade"))
	p.attack_hit_max_fraction = 0.4
	check.call("ตั้งเพดานต่ำลง → ดาเมจออกเร็วขึ้นอีก", p.attack_hit_frame_of("Attack_Blade") <= 2,
		"%d" % p.attack_hit_frame_of("Attack_Blade"))
	p.attack_hit_max_fraction = 0.6

	# =========================================================
	# 4) ★ ครบไม้สุดท้ายแล้วต้องไม่มีไม้เกินโผล่มาเอง ★
	# =========================================================
	print("\n-- 4) ไม่มีไม้เกิน --")
	p.sprite.sprite_frames = old_sf
	p.clear_fit_cache()
	var st := PlayerState.stats
	st.aspd = 2.5
	var gap: float = st.attack_interval()

	var log: Array = []
	var conn := func(step: int, _a: String, _m: float) -> void: log.append(step)
	p.combo_step_started.connect(conn)

	check.call("ค่าเริ่มต้น: ไม่วนกลับไม้ 1 เอง", not p.combo_wrap_from_buffer)
	check.call("ค่าเริ่มต้น: คลิกก่อน 35% ของท่าไม่นับ", is_equal_approx(p.combo_buffer_from, 0.35))

	# ฟันครบ 3 ไม้ แล้ว "กดรัว" ระหว่างไม้ 3 → ต้องไม่มีไม้ที่ 4
	p.reset_combo()
	log.clear()
	for i in 3:
		p.start_attack()
		if i == 2:
			await get_tree().create_timer(gap * 0.5).timeout
			p._combo_queued = true          # ผู้เล่นกดเบิ้ลตอนออกไม้ 3
			await get_tree().create_timer(gap * 0.5 + 0.15).timeout
		else:
			await get_tree().create_timer(gap + 0.08).timeout
	await get_tree().create_timer(gap + 0.3).timeout
	print("  ไม้ที่ออกจริง: %s" % [log])
	check.call("★ กดเบิ้ลตอนไม้ 3 → ได้แค่ 3 ไม้ ไม่มีไม้ที่ 4 โผล่มาเอง ★", log.size() == 3, "%s" % [log])
	check.call("ลำดับยังถูก 1→2→3", log == [0, 1, 2], "%s" % [log])

	# แต่ระหว่างไม้ 1-2 ยังต่อให้เหมือนเดิม
	p.reset_combo()
	log.clear()
	p.start_attack()
	await get_tree().create_timer(gap * 0.5).timeout
	p._combo_queued = true
	await get_tree().create_timer(gap * 0.6 + 0.2).timeout
	check.call("★ กดกลางไม้ 1 → ยังต่อไม้ 2 ให้เหมือนเดิม ★", log.size() == 2 and log[1] == 1, "%s" % [log])
	await get_tree().create_timer(gap + 0.2).timeout

	# เปิดสวิตช์วนกลับ = ได้ไม้ที่ 4 (ยืนยันว่าสวิตช์คุมได้จริง)
	p.combo_wrap_from_buffer = true
	p.reset_combo()
	log.clear()
	for i in 3:
		p.start_attack()
		if i == 2:
			await get_tree().create_timer(gap * 0.5).timeout
			p._combo_queued = true
			await get_tree().create_timer(gap * 0.5 + 0.15).timeout
		else:
			await get_tree().create_timer(gap + 0.08).timeout
	await get_tree().create_timer(gap + 0.3).timeout
	check.call("เปิดสวิตช์วนกลับ → มีไม้ที่ 4 (สวิตช์คุมได้จริง)", log.size() == 4 and log[3] == 0, "%s" % [log])
	p.combo_wrap_from_buffer = false
	await get_tree().create_timer(gap + 0.3).timeout

	# =========================================================
	# 5) คลิกเร็วเกินไปไม่ถูกจำ
	# =========================================================
	print("\n-- 5) คลิกเร็วเกินไม่นับ --")
	p.reset_combo()
	log.clear()
	p.start_attack()
	await get_tree().create_timer(gap * 0.1).timeout
	var early: float = p._attack_progress()
	check.call("อยู่ช่วงต้นท่าจริง (%.0f%%)" % (early * 100.0), early < p.combo_buffer_from, "%.2f" % early)
	await get_tree().create_timer(gap + 0.3).timeout
	check.call("ระหว่างไม้: _attack_progress คืน 1.0 เมื่อไม่ได้ฟันอยู่", is_equal_approx(p._attack_progress(), 1.0))

	p.combo_step_started.disconnect(conn)
	p.reset_combo()
	p.combo_hit_frames = PackedInt32Array()

	print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
	get_tree().quit()
