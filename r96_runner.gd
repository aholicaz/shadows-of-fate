extends Node
## ★ เทสต์รอบ 96 — กดปุ่มโจมตีค้าง = ฟันต่อเนื่อง (คลิกทีละครั้งยังใช้ได้) ★


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
	st.aspd = 3.0
	var gap: float = st.attack_interval()

	var log: Array = []
	var conn := func(step: int, _a: String, _m: float) -> void: log.append(step)
	p.combo_step_started.connect(conn)

	var release := func() -> void:
		if Input.is_action_pressed("attack"):
			Input.action_release("attack")

	# =========================================================
	# 1) ค่าตั้งต้น
	# =========================================================
	print("\n-- 1) ค่าตั้งต้น --")
	check.call("★ เปิดโหมดกดค้างไว้ ★", p.attack_hold_repeat)
	check.call("ยังไม่ได้กดเมาส์ค้าง", not p._mouse_attack_held())

	# =========================================================
	# 2) กดค้าง → ฟันต่อเนื่องเอง
	# =========================================================
	print("\n-- 2) กดค้าง = ฟันรัว --")
	p.reset_combo()
	log.clear()
	Input.action_press("attack")
	await get_tree().create_timer(gap * 3.6).timeout
	release.call()
	await get_tree().create_timer(gap + 0.3).timeout
	print("  กดค้าง ~3.6 ช่วงตี → ฟันไป %d ครั้ง · ลำดับไม้ %s" % [log.size(), log])
	check.call("★ กดค้างแล้วฟันหลายครั้งเอง (ไม่ต้องกดซ้ำ) ★", log.size() >= 3, "%d ครั้ง" % log.size())
	check.call("★ คอมโบยังวน 1→2→3→1 ตอนกดค้าง ★",
		log.size() >= 4 and log[0] == 0 and log[1] == 1 and log[2] == 2 and log[3] == 0, "%s" % [log])

	# =========================================================
	# 3) ปล่อยปุ่ม → หยุด
	# =========================================================
	print("\n-- 3) ปล่อยแล้วหยุด --")
	p.reset_combo()
	log.clear()
	Input.action_press("attack")
	await get_tree().create_timer(gap * 1.5).timeout
	release.call()
	var during: int = log.size()
	await get_tree().create_timer(gap * 3.0 + 0.3).timeout
	print("  ตอนกดค้างฟันไป %d ครั้ง · หลังปล่อยอีก %d ครั้ง" % [during, log.size() - during])
	check.call("★ ปล่อยปุ่มแล้วหยุดฟัน (ไม่ฟันต่อเอง) ★", log.size() - during <= 1,
		"เพิ่มอีก %d" % (log.size() - during))

	# =========================================================
	# 4) กดทีละครั้งยังใช้ได้เหมือนเดิม
	# =========================================================
	print("\n-- 4) กดทีละครั้ง --")
	p.reset_combo()
	log.clear()
	Input.action_press("attack")
	await get_tree().process_frame
	await get_tree().process_frame
	release.call()
	await get_tree().create_timer(gap * 2.5).timeout
	print("  กดแป๊บเดียวแล้วปล่อย → ฟัน %d ครั้ง" % log.size())
	check.call("★ กดทีละครั้ง = ฟันครั้งเดียว ★", log.size() == 1, "%d ครั้ง" % log.size())
	check.call("และเป็นไม้ที่ 1", log.size() >= 1 and log[0] == 0, "%s" % [log])

	# กดทีละครั้งสามรอบ ยังไล่คอมโบถูก
	p.reset_combo()
	log.clear()
	for i in 3:
		Input.action_press("attack")
		await get_tree().process_frame
		await get_tree().process_frame
		release.call()
		await get_tree().create_timer(gap + 0.1).timeout
	check.call("★ กดทีละครั้ง 3 รอบ ได้ไม้ 1→2→3 เหมือนเดิม ★", log == [0, 1, 2], "%s" % [log])

	# =========================================================
	# 5) ปิดสวิตช์ = กลับไปแบบเดิม
	# =========================================================
	print("\n-- 5) ปิดสวิตช์ --")
	p.attack_hold_repeat = false
	p.reset_combo()
	log.clear()
	Input.action_press("attack")
	await get_tree().create_timer(gap * 3.0).timeout
	release.call()
	await get_tree().create_timer(gap + 0.2).timeout
	print("  ปิดสวิตช์แล้วกดค้างเท่าเดิม → ฟัน %d ครั้ง" % log.size())
	check.call("★ ปิดสวิตช์ → กดค้างก็ฟันครั้งเดียว (เหมือนก่อนรอบ 96) ★", log.size() == 1,
		"%d ครั้ง" % log.size())
	p.attack_hold_repeat = true
	await get_tree().create_timer(gap + 0.2).timeout

	# =========================================================
	# 6) เมาส์: ต้องเช็คสถานะปุ่มจริง ไม่ใช่เชื่อธงอย่างเดียว
	# =========================================================
	print("\n-- 6) เมาส์กดค้าง --")
	p._click_attack_held = true          # แกล้งว่าเคยกดซ้ายไว้
	check.call("★ ธงค้างอยู่แต่ปุ่มจริงไม่ได้กด → ไม่ฟันรัว (กันค้างเพราะ UI กินอีเวนต์ปล่อย) ★",
		not p._mouse_attack_held())
	check.call("และธงถูกล้างให้เองด้วย", not p._click_attack_held)

	var old_mouse: bool = p.mouse_attack
	p.mouse_attack = false
	p._click_attack_held = true
	check.call("ปิดโจมตีด้วยเมาส์ → ไม่ฟันรัวจากเมาส์", not p._mouse_attack_held())
	p.mouse_attack = old_mouse
	p._click_attack_held = false

	# =========================================================
	# 7) ตายระหว่างกดค้าง → ต้องไม่ฟันต่อ
	# =========================================================
	print("\n-- 7) ตายระหว่างกดค้าง --")
	p._click_attack_held = true
	p._on_died()
	check.call("★ ตายแล้วเลิกฟันรัว ★", not p._click_attack_held)
	p._dead = false
	p.is_attacking = false
	PlayerState.stats.hp = PlayerState.stats.max_hp

	release.call()
	p.combo_step_started.disconnect(conn)
	p.reset_combo()

	print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
	get_tree().quit()
