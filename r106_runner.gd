extends Node
## ★ เทสต์รอบ 106 — ห้อง GM: เปลี่ยนอาชีพ (นักดาบ/Runeblade/Ninth Edge) + ปลดล็อกรูน + ธงบท 4-6 + ชุดของเควสบท 4-6 ★

func run() -> void:
	var score := [0, 0]
	var check := func(n: String, c: bool, e: String = "") -> void:
		if c: score[0] += 1
		else:
			score[1] += 1
			print("  x FAIL: ", n, " ", e)

	PlayerState.new_game()
	await Game.change_map(&"gm_room", &"default")
	await _wait_map(&"gm_room")
	var win = UI.windows.get(&"gm", null)
	check.call("หน้าต่าง gm เป็น GMWindow", win != null and win is GMWindow)
	var gm: GMWindow = win
	gm.show_window()
	await get_tree().process_frame
	gm.refresh()
	await get_tree().process_frame

	print("\n-- 1) เมนูอาชีพ --")
	check.call("★ มีเมนูเปลี่ยนอาชีพ ★", gm._job_option != null)
	check.call("รายชื่ออาชีพ ≥ 3 (นักดาบ/Runeblade/Ninth Edge)", gm._job_ids.size() >= 3, str(gm._job_ids))
	check.call("มี runeblade", gm._job_ids.has(&"runeblade"))
	check.call("มี ninth_edge", gm._job_ids.has(&"ninth_edge"))
	check.call("ลำดับ: swordsman ก่อน runeblade ก่อน ninth_edge",
		gm._job_ids.find(&"swordsman") < gm._job_ids.find(&"runeblade") and gm._job_ids.find(&"runeblade") < gm._job_ids.find(&"ninth_edge"))
	check.call("เมนูชี้อาชีพปัจจุบัน (นักดาบ)", gm._job_ids[gm._job_option.selected] == &"swordsman")
	check.call("ช่องตั้งธงเควสรูนเปิดเป็นค่าเริ่มต้น", gm._unlock_check != null and gm._unlock_check.button_pressed)

	print("\n-- 2) นักดาบ → Runeblade --")
	gm._set_level(85, 40)
	PlayerState.stats.skill_points += 10
	PlayerState.skills.learn(&"bash", PlayerState.stats)
	check.call("(เตรียม) เรียน bash ได้", PlayerState.skills.is_learned(&"bash"))
	var sp_before: int = PlayerState.stats.skill_points
	gm.change_job(&"runeblade", true)
	var st := PlayerState.stats
	check.call("★ job_id = runeblade ★", st.job_id == &"runeblade")
	check.call("is_rune_job()", PlayerState.is_rune_job())
	check.call("ธง runeblade_awakened", PlayerState.has_flag(&"runeblade_awakened"))
	check.call("ธง job_runeblade", PlayerState.has_flag(&"job_runeblade"))
	check.call("ธง runeblade_start_level = 85", int(PlayerState.get_flag(&"runeblade_start_level", 0)) == 85)
	check.call("รูน 4-7 ปลดล็อก", PlayerState.has_flag(&"rb_rune_4") and PlayerState.has_flag(&"rb_rune_5") and PlayerState.has_flag(&"rb_rune_6") and PlayerState.has_flag(&"rb_rune_7"))
	check.call("ยังไม่ปลด ninth_inscription_unlocked (ยังไม่ใช่ Ninth Edge)", not PlayerState.has_flag(&"ninth_inscription_unlocked"))
	check.call("สกิลนักดาบ (bash) ยังอยู่", PlayerState.skills.is_learned(&"bash"))
	check.call("แต้มสกิลไม่เปลี่ยน", st.skill_points == sp_before, "%d vs %d" % [st.skill_points, sp_before])
	# ★ รอบ 108 ★ แต้มรูน = แต้มสกิลปกติ · เพดานจ๊อบ Runeblade 80
	check.call("★ รอบ 108: แต้มรูน = แต้มสกิล ★", PlayerState.skills.rune_points() == st.skill_points, str(PlayerState.skills.rune_points()))
	check.call("★ รอบ 108: เพดานจ๊อบ Runeblade 80 ★", st.max_job_level() == 80)
	check.call("จ๊อบ 40 → job_exp_to_next > 0 (ยังไม่ตัน)", st.job_exp_to_next() > 0)
	check.call("เรียน runic_vessel ได้", PlayerState.skills.can_learn(&"runic_vessel", st))
	check.call("เรียน wallbreaker_stance ได้ (Lv70)", PlayerState.skills.can_learn(&"wallbreaker_stance", st), PlayerState.skills.learn_blocker(&"wallbreaker_stance", st))
	check.call("เรียน twin_inscription ได้ (Lv82)", PlayerState.skills.can_learn(&"twin_inscription", st), PlayerState.skills.learn_blocker(&"twin_inscription", st))
	var sp_r: int = st.skill_points
	PlayerState.skills.learn(&"rune_guard", st)
	check.call("★ รอบ 108: เรียนสกิลรูนหักแต้มสกิลปกติ ★", st.skill_points == sp_r - 1 and PlayerState.skills.is_learned(&"rune_guard"))
	check.call("ninth_inscription ยังเรียนไม่ได้ (คนละอาชีพ)", not PlayerState.skills.can_learn(&"ninth_inscription", st))
	check.call("เมนูชี้ runeblade", gm._job_ids[gm._job_option.selected] == &"runeblade")
	check.call("HUD ชื่ออาชีพ", st.job().display_name.begins_with("Runeblade"))

	print("\n-- 3) Runeblade → Ninth Edge --")
	PlayerState.skills.learn(&"runic_vessel", st)
	gm._set_level(96, 50)
	gm.change_job(&"ninth_edge", true)
	check.call("★ job_id = ninth_edge ★", st.job_id == &"ninth_edge")
	check.call("ธง ninth_edge_awakened + job_ninth_edge", PlayerState.has_flag(&"ninth_edge_awakened") and PlayerState.has_flag(&"job_ninth_edge"))
	check.call("ธง runeblade_awakened ยังอยู่ (ผ่าน Runeblade มา)", PlayerState.has_flag(&"runeblade_awakened"))
	check.call("job_runeblade ยังอยู่ (เหมือนเปลี่ยนอาชีพจริงที่ผ่าน Runeblade มา)", PlayerState.has_flag(&"job_runeblade"))
	check.call("runeblade_start_level ไม่ถูกเขียนทับ (ยัง 85)", int(PlayerState.get_flag(&"runeblade_start_level", 0)) == 85)
	check.call("★ ninth_inscription_unlocked ★", PlayerState.has_flag(&"ninth_inscription_unlocked"))
	check.call("★ รอบ 108: Ninth Edge เพดานจ๊อบ 100 ★", st.max_job_level() == 100)
	check.call("แต้มรูน = แต้มสกิล", PlayerState.skills.rune_points() == st.skill_points)
	check.call("runic_vessel ที่เรียนไว้ยังอยู่", PlayerState.skills.is_learned(&"runic_vessel"))
	check.call("เรียน ninth_inscription ได้", PlayerState.skills.can_learn(&"ninth_inscription", st), PlayerState.skills.learn_blocker(&"ninth_inscription", st))
	check.call("เรียน erasing_cut ได้", PlayerState.skills.can_learn(&"erasing_cut", st), PlayerState.skills.learn_blocker(&"erasing_cut", st))
	check.call("เรียน named_edge ได้", PlayerState.skills.can_learn(&"named_edge", st), PlayerState.skills.learn_blocker(&"named_edge", st))

	print("\n-- 4) นักดาบ → Ninth Edge ตรง ๆ (ข้าม Runeblade) --")
	PlayerState.new_game()
	gm._set_level(90, 50)
	gm.change_job(&"ninth_edge", true)
	st = PlayerState.stats
	check.call("job_id = ninth_edge", st.job_id == &"ninth_edge")
	check.call("★ ตั้งธง runeblade_* ให้ด้วย ★", PlayerState.has_flag(&"runeblade_awakened") and int(PlayerState.get_flag(&"runeblade_start_level", 0)) == 90)
	check.call("แต้มรูน = แต้มสกิล (GM ตั้งจ๊อบ 50 ได้ 49 แต้ม)", PlayerState.skills.rune_points() == st.skill_points and st.skill_points >= 49, str(st.skill_points))
	# ★ รอบ 108 ★ นักดาบตันจ๊อบ 50 → เปลี่ยนเป็น Runeblade → เก็บจ๊อบต่อได้ถึง 80 · แต้มสกิล +1 ต่อจ๊อบ
	PlayerState.new_game()
	gm._set_level(52, 50)
	check.call("นักดาบ: จ๊อบ 50 ตัน (exp_to_next = 0)", PlayerState.stats.job_exp_to_next() == 0 and PlayerState.stats.add_job_exp(999999) == 0)
	var sp0: int = PlayerState.stats.skill_points
	gm.change_job(&"runeblade", false)
	check.call("★ รอบ 108: เป็น Runeblade แล้วจ๊อบไม่ตัน (เพดาน 80) ★", PlayerState.stats.job_exp_to_next() > 0 and PlayerState.stats.max_job_level() == 80)
	var gained: int = PlayerState.stats.add_job_exp(PlayerState.stats.job_exp_to_next())
	check.call("★ เก็บจ๊อบต่อ → จ๊อบ 51 + แต้มสกิล +1 ★", gained == 1 and PlayerState.stats.job_level == 51 and PlayerState.stats.skill_points == sp0 + 1, "job %d sp %d/%d" % [PlayerState.stats.job_level, PlayerState.stats.skill_points, sp0])
	PlayerState.stats.job_level = 80
	check.call("Runeblade จ๊อบ 80 ตัน", PlayerState.stats.job_exp_to_next() == 0)
	gm.change_job(&"ninth_edge", false)
	check.call("★ Ninth Edge → เพดาน 100 เก็บต่อได้ ★", PlayerState.stats.job_exp_to_next() > 0)
	PlayerState.new_game()
	gm._set_level(90, 50)
	gm.change_job(&"ninth_edge", true)
	st = PlayerState.stats

	print("\n-- 5) กลับเป็นนักดาบ --")
	st.skill_points += 10
	PlayerState.skills.learn(&"runic_vessel", st)
	PlayerState.skills.learn(&"bash", st)
	check.call("(เตรียม) เรียน runic_vessel + bash", PlayerState.skills.is_learned(&"runic_vessel") and PlayerState.skills.is_learned(&"bash"), PlayerState.skills.learn_blocker(&"runic_vessel", st) + " / " + PlayerState.skills.learn_blocker(&"bash", st))
	PlayerState.skills.set_hotkey(0, &"runic_vessel")
	PlayerState.skills.set_hotkey(1, &"bash")
	var sp2: int = st.skill_points
	gm.change_job(&"swordsman", true)
	check.call("job_id = swordsman", st.job_id == &"swordsman")
	check.call("★ สกิลรูนถูกลบ ★", not PlayerState.skills.is_learned(&"runic_vessel"))
	check.call("bash ยังอยู่", PlayerState.skills.is_learned(&"bash"))
	check.call("ปุ่มลัดสกิลรูนถูกล้าง · bash ยังอยู่", PlayerState.skills.hotkeys[0] == &"" and PlayerState.skills.hotkeys[1] == &"bash")
	check.call("★ รอบ 108: แต้มสกิลคืนจากสกิลรูนด้วย (+1) ★", st.skill_points == sp2 + 1, "%d vs %d" % [st.skill_points, sp2])
	check.call("job_ninth_edge ถูกเอาออก", not PlayerState.has_flag(&"job_ninth_edge"))
	check.call("is_rune_job() = false", not PlayerState.is_rune_job())
	check.call("รูนแต้ม = 0 (ไม่ใช่อาชีพรูน)", PlayerState.skills.rune_points() == 0)

	print("\n-- 6) ไม่ปลดล็อก --")
	PlayerState.new_game()
	gm._set_level(60, 30)
	gm.change_job(&"runeblade", false)
	check.call("job_id = runeblade", PlayerState.stats.job_id == &"runeblade")
	check.call("★ ไม่ตั้งธงเควสรูน 5/7 ★", not PlayerState.has_flag(&"rb_rune_5") and not PlayerState.has_flag(&"rb_rune_7"))
	PlayerState.stats.skill_points = 5
	check.call("รอบ 108: wallbreaker_stance เรียนไม่ได้เพราะ Lv 60 < 70 (ไม่ใช่เพราะธง)", not PlayerState.skills.can_learn(&"wallbreaker_stance", PlayerState.stats) and "เลเวล 70" in PlayerState.skills.learn_blocker(&"wallbreaker_stance", PlayerState.stats), PlayerState.skills.learn_blocker(&"wallbreaker_stance", PlayerState.stats))
	check.call("รอบ 108: runic_vessel เรียนได้โดยไม่มีธงใด ๆ", PlayerState.skills.can_learn(&"runic_vessel", PlayerState.stats))
	check.call("อาชีพผิด → ไม่พัง", true)
	gm.change_job(&"no_such_job", true)
	check.call("อาชีพที่ไม่มี: ยังเป็น runeblade", PlayerState.stats.job_id == &"runeblade")

	print("\n-- 7) ปุ่มในเมนู --")
	PlayerState.new_game()
	gm.refresh()
	gm._job_option.select(gm._job_ids.find(&"ninth_edge"))
	gm._apply_job()
	check.call("★ กดปุ่มเปลี่ยน → ninth_edge ★", PlayerState.stats.job_id == &"ninth_edge")

	print("\n-- 8) ธงบท 4-6 + ชุดของ --")
	var flags := []
	for f in GMWindow.STORY_FLAGS: flags.append(f[1])
	for want in ["chapter4_done", "chapter5_done", "chapter6_done", "has_shade_crystal", "name_left", "garm_resolved", "rb_next_job_ready"]:
		check.call("ธง %s อยู่ในเมนู" % want, flags.has(want))
	check.call("★ มีชุดของเควสบท 4-6 ★", GMWindow.QUICK_KITS.has("ของเควสบท 4-6"))
	var missing := []
	for kit in GMWindow.QUICK_KITS.values():
		for e in kit:
			if GameData.get_item(StringName(e[0])) == null: missing.append(e[0])
	check.call("ไอเทมในทุกชุดมีจริง", missing.is_empty(), str(missing))
	PlayerState.new_game()
	gm._give_kit("ของเควสบท 4-6")
	check.call("ได้สิ่วเกอร์ด", PlayerState.inventory.count_of(&"gerd_chisel") >= 1)

	print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
	get_tree().quit()


func _wait_map(want: StringName) -> void:
	for _i in range(80):
		await get_tree().create_timer(0.1).timeout
		if not Game._is_changing and PlayerState.current_map_id == want:
			break
	await get_tree().create_timer(0.4).timeout
