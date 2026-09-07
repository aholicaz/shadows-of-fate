extends Node
## ★ เทสต์รอบ 81 — ท่าฟันไวขึ้นตาม ASPD ★

func run() -> void:
	var score := [0, 0]
	var check := func(n: String, c: bool, e: String = "") -> void:
		if c: score[0] += 1
		else:
			score[1] += 1
			print("  x FAIL: ", n, " ", e)

	# เข้าห้อง GM (พื้นเรียบ ไม่มีมอนมากวน)
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
	var sp: AnimatedSprite2D = p.sprite

	# =========================================================
	# 1) ค่าตั้งต้น
	# =========================================================
	print("\n-- 1) ค่าตั้งต้น --")
	check.call("เปิดระบบเร่งท่าตาม ASPD อยู่", p.attack_anim_follow_aspd)
	check.call("ความเร็วภาพเริ่มต้น = 1.0", is_equal_approx(sp.speed_scale, 1.0), "%f" % sp.speed_scale)
	var atk_anim: String = p._real_anim(p.attack_animation())
	var natural: float = p._anim_length(atk_anim)
	check.call("หาความยาวท่าฟันได้ (%s = %.2f วิ)" % [atk_anim, natural], natural > 0.0)

	# =========================================================
	# 2) ASPD ต่ำ — ท่าฟันเล่นความเร็วปกติ ไม่ถูกเร่ง
	# =========================================================
	print("\n-- 2) ASPD ต่ำ --")
	# ★ ตั้ง aspd ตรง ๆ ★ (percent_bonus จะถูก refresh() คำนวณทับจากของสวมใส่)
	var st := PlayerState.stats
	st.aspd = 0.7
	var slow_aspd: float = st.aspd
	var slow_gap: float = st.attack_interval()
	check.call("ASPD ต่ำ → ช่วงตีห่างกว่าท่าฟัน (%.2f > %.2f)" % [slow_gap, natural], slow_gap > natural)
	p.attack_cooldown = 0.0
	p.is_attacking = false
	p.start_attack()
	await get_tree().create_timer(0.1).timeout
	var slow_scale: float = sp.speed_scale
	check.call("★ ASPD ต่ำ → ไม่เร่งภาพ (speed_scale = 1.0) ★",
		is_equal_approx(slow_scale, 1.0), "%f" % slow_scale)
	await get_tree().create_timer(slow_gap + 0.3).timeout

	# =========================================================
	# 3) ASPD สูง — ท่าฟันถูกเร่งให้จบทัน
	# =========================================================
	print("\n-- 3) ASPD สูง --")
	st.aspd = 4.0
	var fast_aspd: float = st.aspd
	var fast_gap: float = st.attack_interval()
	check.call("ASPD สูงขึ้นจริง (%.2f → %.2f ครั้ง/วิ)" % [slow_aspd, fast_aspd], fast_aspd > slow_aspd)
	check.call("ASPD สูง → ช่วงตีสั้นกว่าท่าฟัน (%.3f < %.3f)" % [fast_gap, natural], fast_gap < natural)
	p.attack_cooldown = 0.0
	p.is_attacking = false
	p.start_attack()
	await get_tree().create_timer(0.02).timeout
	var fast_scale: float = sp.speed_scale
	check.call("★ ASPD สูง → ภาพถูกเร่ง (speed_scale %.2f > 1) ★", fast_scale > 1.0, "%f" % fast_scale)
	# เร่งแล้วท่าต้องจบทันก่อนตีครั้งถัดไป
	var scaled_len: float = natural / fast_scale
	check.call("★ เร่งแล้วท่าฟันจบก่อนตีครั้งถัดไป (%.3f <= %.3f) ★" % [scaled_len, fast_gap],
		scaled_len <= fast_gap + 0.001)
	check.call("ไม่เร่งเกินเพดานที่ตั้งไว้ (%.1f เท่า)" % p.attack_anim_max_speed,
		fast_scale <= p.attack_anim_max_speed + 0.001)
	# ASPD สูงเกินเพดาน → หยุดที่เพดาน ไม่เร่งต่อ
	await get_tree().create_timer(fast_gap + 0.3).timeout
	st.aspd = 20.0
	p.attack_cooldown = 0.0
	p.is_attacking = false
	p.start_attack()
	await get_tree().create_timer(0.02).timeout
	check.call("★ ASPD สูงลิบ → ชนเพดาน %.1f เท่าพอดี ★" % p.attack_anim_max_speed,
		is_equal_approx(sp.speed_scale, p.attack_anim_max_speed), "%f" % sp.speed_scale)

	# =========================================================
	# 4) ยิ่ง ASPD สูง ยิ่งเร่งมาก (จนชนเพดาน)
	# =========================================================
	print("\n-- 4) เร่งตามสัดส่วน --")
	await get_tree().create_timer(fast_gap + 0.3).timeout
	var scales: Array[float] = []
	for a in [0.8, 1.6, 3.2]:
		st.aspd = a
		p.attack_cooldown = 0.0
		p.is_attacking = false
		p.start_attack()
		await get_tree().create_timer(0.02).timeout
		scales.append(sp.speed_scale)
		await get_tree().create_timer(st.attack_interval() + 0.3).timeout
	check.call("★ ASPD สูงขึ้น → ความเร็วภาพไม่ลดลงเลย (%.2f · %.2f · %.2f) ★" % [scales[0], scales[1], scales[2]],
		scales[1] >= scales[0] - 0.001 and scales[2] >= scales[1] - 0.001)
	check.call("ASPD 3.2 เร่งมากกว่า ASPD 0.8", scales[2] > scales[0])

	# =========================================================
	# 5) จังหวะดาบโดนเลื่อนตามด้วย (ตีเร็ว = โดนเร็ว)
	# =========================================================
	print("\n-- 5) จังหวะดาบโดน --")
	st.aspd = 6.0
	_spawn_dummy(p)
	await get_tree().create_timer(0.4).timeout
	var mob = get_tree().get_first_node_in_group("enemy")
	check.call("มีมอนไว้ให้ตี", mob != null)
	if mob != null:
		mob.hp = 999999
		mob.set_physics_process(false)
	if mob != null:
		var hp0: int = mob.hp
		p.attack_cooldown = 0.0
		p.is_attacking = false
		p.start_attack()
		# ท่าฟันถูกเร่ง → ดาบต้องโดนภายในครึ่งหนึ่งของ windup ปกติ
		await get_tree().create_timer(p.attack_windup * 0.6).timeout
		check.call("★ ASPD สูง → ดาบโดนก่อนจังหวะ windup ปกติ ★", mob.hp < hp0,
			"%d → %d" % [hp0, mob.hp])
		await get_tree().create_timer(0.4).timeout

	# =========================================================
	# 6) ออกจากท่าฟันแล้วคืนความเร็วภาพเป็นปกติ
	# =========================================================
	print("\n-- 6) คืนความเร็วภาพ --")
	await get_tree().create_timer(0.8).timeout
	check.call("★ ฟันจบแล้ว speed_scale กลับเป็น 1.0 ★", is_equal_approx(sp.speed_scale, 1.0),
		"%f" % sp.speed_scale)
	check.call("ไม่ค้างสถานะกำลังฟัน", not p.is_attacking)
	# ตายกลางท่าฟันไว ๆ ก็ต้องคืน
	p.attack_cooldown = 0.0
	p.is_attacking = false
	p.start_attack()
	await get_tree().create_timer(0.02).timeout
	check.call("กำลังฟันอยู่ ภาพถูกเร่ง", sp.speed_scale > 1.0)
	p._on_died()
	await get_tree().create_timer(0.1).timeout
	check.call("★ ตายกลางท่าฟัน → speed_scale คืนเป็น 1.0 ★", is_equal_approx(sp.speed_scale, 1.0),
		"%f" % sp.speed_scale)

	# คืนค่าเดิม
	PlayerState.refresh(false)

	print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
	get_tree().quit()


## เรียกหุ่นทดสอบมายืนติดตัวผู้เล่น (เลือดเยอะ ๆ จะได้ไม่ตายกลางเทสต์)
func _spawn_dummy(p) -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		e.queue_free()
	var d: MonsterData = GameData.get_monster(&"poring")
	if d == null:
		return
	var mob = load("res://scenes/monsters/monster.tscn").instantiate()
	mob.data = d
	mob.global_position = p.global_position + Vector2(p.facing * 60.0, 0)
	get_tree().get_first_node_in_group("map").add_child(mob)
	mob.set_home(mob.global_position)
