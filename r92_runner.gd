extends Node
## ★ เทสต์รอบ 92 — auto-fit ต้องวัดถูกแม้ภาพเป็น VRAM Compressed (BC7) ★

func run() -> void:
	var score := [0, 0]
	var check := func(n: String, c: bool, e: String = "") -> void:
		if c: score[0] += 1
		else:
			score[1] += 1
			print("  x FAIL: ", n, " ", e)

	print("\n-- 1) ภาพในโปรเจกต์ทดสอบเป็น BC7 จริง --")
	var d: MonsterData = GameData.get_monster(&"forge_guardian")
	check.call("โหลดผู้พิทักษ์เตาหลอมได้", d != null and d.sprite_frames != null)
	var t0: Texture2D = d.sprite_frames.get_frame_texture(&"Idle", 0)
	var atlas_img: Image = (t0 as AtlasTexture).atlas.get_image() if t0 is AtlasTexture else t0.get_image()
	check.call("★ ชีทมอนถูก import เป็นภาพบีบอัด (เงื่อนไขของบั๊ก) ★", atlas_img != null and atlas_img.is_compressed(),
		"compressed=%s" % (atlas_img.is_compressed() if atlas_img else "null"))
	var raw_img: Image = t0.get_image()
	print("  AtlasTexture.get_image() บนผืนบีบอัดคืน: %s" % ("null" if raw_img == null else "%dx%d" % [raw_img.get_width(), raw_img.get_height()]))

	print("\n-- 2) วัดได้ขอบตัวจริง ไม่ใช่ทั้งช่อง --")
	var before := SpriteFit.decompressed_count
	var t_start := Time.get_ticks_msec()
	var heights := {}
	for a in [&"Idle", &"Run", &"Attack"]:
		var m: Dictionary = SpriteFit.measure(d.sprite_frames, a)
		heights[a] = float(m.get("tallest", 0.0))
		print("  %-7s สูงสุด %.0f px · เฟรมแรก bottom=%.0f dx=%.0f w=%.0f" % [a, heights[a], m.frames[0].bottom, m.frames[0].dx, m.frames[0].w])
	var ms := Time.get_ticks_msec() - t_start
	print("  ใช้เวลาวัด 3 ท่า (รวมคลายบีบอัด) %d ms · คลายไป %d ผืน" % [ms, SpriteFit.decompressed_count - before])
	check.call("★ ต้องคลายบีบอัดจริง (ไม่ใช่ผ่านเพราะภาพไม่ได้บีบ) ★", SpriteFit.decompressed_count - before >= 1)
	var cell_h: float = float(t0.get_height())
	check.call("★ Idle ไม่ได้วัดเท่าช่องภาพ (%.0f) ★" % cell_h, heights[&"Idle"] < cell_h - 20.0, "%.0f" % heights[&"Idle"])
	check.call("★ Attack สูงกว่า Idle (ยกอาวุธ) — เห็นความต่างระหว่างท่าได้ ★", heights[&"Attack"] > heights[&"Idle"] + 10.0,
		"%.0f vs %.0f" % [heights[&"Attack"], heights[&"Idle"]])
	check.call("bottom ของเฟรมแรกไม่ใช่ขอบล่างช่อง (เท้าไม่จม)", absf(SpriteFit.measure(d.sprite_frames, &"Idle").frames[0].bottom) < cell_h * 0.5 - 5.0)
	check.call("วัด 3 ท่าเสร็จภายใน 3 วินาที", ms < 3000, "%d ms" % ms)

	print("\n-- 3) วัดซ้ำใช้แคช ไม่คลายซ้ำ --")
	var before2 := SpriteFit.decompressed_count
	SpriteFit.measure(d.sprite_frames, &"Idle")
	check.call("วัดท่าเดิมซ้ำไม่คลายบีบอัดอีก", SpriteFit.decompressed_count == before2)

	print("\n-- 4) ผู้เล่น (เฟรมเป็นภาพทั้งใบ ไม่ใช่ atlas) --")
	var pf: SpriteFrames = load("res://data/sprites/player_frames.tres")
	if pf == null:
		pf = load("res://data/sprites/player/player_frames.tres")
	check.call("โหลดท่าผู้เล่นได้", pf != null)
	if pf != null:
		# หา "ท่าที่ใช้ชีทจริงแบบบีบอัด" (โปรเจกต์ทดสอบมีท่าที่เป็นภาพชั่วคราวปนอยู่)
		var pa: StringName = &""
		for cand in pf.get_animation_names():
			var ct: Texture2D = pf.get_frame_texture(cand, 0)
			if ct is AtlasTexture and (ct as AtlasTexture).atlas != null:
				var ai: Image = (ct as AtlasTexture).atlas.get_image()
				if ai != null and ai.is_compressed():
					pa = cand
					break
		check.call("★ ผู้เล่นมีท่าที่อยู่บนชีทบีบอัด (เงื่อนไขของบั๊ก) ★", pa != &"")
		if pa == &"":
			pa = pf.get_animation_names()[0]
		var pt: Texture2D = pf.get_frame_texture(pa, 0)
		print("  ท่าผู้เล่นที่ทดสอบ: %s (ช่อง %dx%d)" % [pa, pt.get_width(), pt.get_height()])
		var pm: Dictionary = SpriteFit.measure(pf, pa)
		var ph: float = float(pm.get("tallest", 0.0))
		print("  ผู้เล่น %s สูง %.0f px จากช่อง %d" % [pa, ph, pt.get_height()])
		check.call("★ ผู้เล่นวัดได้ขอบตัวจริง ไม่ใช่ทั้งช่อง ★", ph > 0.0 and ph < float(pt.get_height()) - 20.0, "%.0f" % ph)

	print("\n-- 5) ลูนาติก: ตีเบาเพราะธาตุ ไม่ใช่ DEF --")
	var lu: MonsterData = GameData.get_monster(&"lunatic")
	check.call("โหลดลูนาติกได้", lu != null)
	if lu != null:
		check.call("★ ลูนาติกเป็นธาตุ NEUTRAL แล้ว (เดิม GHOST = โดนตีแค่ 25%%) ★", lu.element == MonsterData.Element.NEUTRAL,
			"element=%d" % lu.element)
		var mod_neutral: float = Combat.element_modifier(MonsterData.Element.NEUTRAL, lu.element)
		check.call("อาวุธธาตุปกติตีลูนาติกเต็ม 100%%", is_equal_approx(mod_neutral, 1.0), "%.2f" % mod_neutral)
		var mod_ghost: float = Combat.element_modifier(MonsterData.Element.NEUTRAL, MonsterData.Element.GHOST)
		check.call("(ยืนยันสาเหตุ) ตีมอนธาตุผีด้วยอาวุธปกติได้แค่ 25%%", is_equal_approx(mod_ghost, 0.25), "%.2f" % mod_ghost)
		check.call("DEF ลูนาติกยังเท่าเดิม (ไม่ได้แตะ)", lu.def <= 5, "%d" % lu.def)

	print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
	get_tree().quit()
