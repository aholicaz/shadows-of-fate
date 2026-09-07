extends Node
## ★ เทสต์รอบ 82 — ชีทเอฟเฟกต์ใหม่ magnum_break · slime_burst จัดสัดส่วนถูกต้อง ★

const MAGNUM_FRAMES := 12
const SLIME_FRAMES := 8

func run() -> void:
	var score := [0, 0]
	var check := func(n: String, c: bool, e: String = "") -> void:
		if c: score[0] += 1
		else:
			score[1] += 1
			print("  x FAIL: ", n, " ", e)

	# =========================================================
	# 1) ชีทแมกนัม — 12 เฟรมเท่ากันเป๊ะ ครอบคลุมทั้งภาพ
	# =========================================================
	print("\n-- 1) ชีทแมกนัม --")
	var sf: SpriteFrames = load("res://data/sprites/fx_magnum.tres")
	check.call("โหลด fx_magnum.tres ได้", sf != null)
	if sf == null:
		print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
		get_tree().quit()
		return
	check.call("มีท่า burst", sf.has_animation(&"burst"))
	var n := sf.get_frame_count(&"burst")
	# ★ ผู้ใช้ปรับจำนวนเฟรม/ความเร็วเองได้ ★ เทสต์เช็คว่า "เป็นตารางเท่ากันครบทั้งภาพ" ไม่ล็อกเลข
	check.call("มีอย่างน้อย 8 เฟรม", n >= 8, "%d" % n)

	var tex0: AtlasTexture = sf.get_frame_texture(&"burst", 0)
	check.call("เฟรมเป็น AtlasTexture", tex0 != null)
	var sheet: Texture2D = tex0.atlas
	var sw := sheet.get_width()
	var sh := sheet.get_height()
	print("   ชีท %dx%d · ช่อง %dx%d" % [sw, sh, int(tex0.region.size.x), int(tex0.region.size.y)])
	check.call("★ ช่องกว้างหารกับความกว้างชีทลงตัว ★", sw % int(tex0.region.size.x) == 0,
		"%d %% %d" % [sw, int(tex0.region.size.x)])
	check.call("★ ช่องสูงเต็มภาพ (ไม่ตัดบน-ล่าง) ★", int(tex0.region.size.y) == sh,
		"%d vs %d" % [int(tex0.region.size.y), sh])

	var ok_grid := true
	var ok_size := true
	for i in range(n):
		var t: AtlasTexture = sf.get_frame_texture(&"burst", i)
		if t == null:
			ok_grid = false
			continue
		if int(t.region.position.x) != i * int(tex0.region.size.x) or int(t.region.position.y) != 0:
			ok_grid = false
			print("    (เฟรม %d อยู่ที่ %v)" % [i, t.region.position])
		if t.region.size != tex0.region.size:
			ok_size = false
	check.call("★ ทุกเฟรมเรียงต่อกันไม่เหลื่อม ไม่มีช่องว่าง ★", ok_grid)
	check.call("★ ทุกเฟรมขนาดเท่ากัน ★", ok_size)
	var last: AtlasTexture = sf.get_frame_texture(&"burst", n - 1)
	check.call("เฟรมสุดท้ายไม่ล้นขอบขวาของชีท",
		int(last.region.position.x + last.region.size.x) <= sw,
		"%d vs %d" % [int(last.region.position.x + last.region.size.x), sw])
	check.call("ท่า burst ไม่วนซ้ำ", not sf.get_animation_loop(&"burst"))

	# =========================================================
	# 2) ทุกเฟรมมีภาพจริง + วงไฟที่พื้นอยู่กึ่งกลางช่องทุกเฟรม
	# =========================================================
	print("\n-- 2) เนื้อภาพในแต่ละเฟรม --")
	var img: Image = sheet.get_image()
	var cw := int(tex0.region.size.x)
	var empty := 0
	var worst := 0.0
	var bottoms: Array[int] = []
	for i in range(n):
		var box := _content_box(img, i * cw, cw, sh)
		if box.size.x <= 0.0:
			empty += 1
			continue
		var cx: float = box.position.x + box.size.x * 0.5
		var off: float = absf(cx - cw * 0.5) / (cw * 0.5)
		worst = maxf(worst, off)
		bottoms.append(int(box.position.y + box.size.y))
	check.call("★ ทุกเฟรมมีภาพ (ไม่มีช่องว่าง) ★", empty == 0, "ว่าง %d ช่อง" % empty)
	check.call("★ ภาพอยู่กึ่งกลางช่องทุกเฟรม (เบี้ยวสุด %.0f%%) ★" % (worst * 100.0), worst < 0.30)
	if bottoms.size() >= 2:
		var lo: int = bottoms.min()
		var hi: int = bottoms.max()
		# เฟรมใหญ่มีเศษหินกระเด็นต่ำกว่าวงไฟนิดหน่อย ยอมให้ต่างได้ 8% ของความสูงช่อง
		check.call("★ ระดับพื้นตรงกันทุกเฟรม (ต่างกัน %d px จาก %d) ★" % [hi - lo, sh],
			hi - lo <= int(sh * 0.08))

	# =========================================================
	# 3) ขนาดบนจอของสกิลแมกนัม
	# =========================================================
	print("\n-- 3) ขนาดบนจอ --")
	var skill: SkillData = GameData.get_skill(&"magnum_break")
	check.call("โหลดสกิลแมกนัมได้", skill != null)
	if skill != null:
		var k: float = skill.effect_height / float(sh)
		var on_w: float = cw * k
		print("   บนจอ %.0f x %.0f px (ตัวละครสูง 240)" % [on_w, skill.effect_height])
		check.call("ตั้งความสูงเอฟเฟกต์ไว้", skill.effect_height > 0.0)
		check.call("★ กว้างบนจอครอบระยะโดนของสกิล (%.0f >= %.0f) ★" % [on_w, skill.range_x],
			on_w >= skill.range_x)
		check.call("ไม่ใหญ่เกินจอ (สูง <= 720)", skill.effect_height <= 720.0)
		# ขอบล่างของภาพต้องอยู่ที่ระดับเท้า (จุดกำเนิด + 120)
		var pad_on: float = 8.0 * k
		var ground: float = skill.effect_offset.y + skill.effect_height * 0.5 - pad_on
		print("   ขอบล่างภาพอยู่ต่ำกว่าจุดกำเนิด %.0f px (เท้า = 120)" % ground)
		check.call("★ วงไฟอยู่ระดับเท้าตัวละคร (คลาด %.0f px) ★" % absf(ground - 120.0),
			absf(ground - 120.0) <= 20.0)

	# =========================================================
	# 4) ชีทสไลม์ — โค้ดคิดขนาดช่องจากภาพเอง
	# =========================================================
	print("\n-- 4) ชีทสไลม์ (เอฟเฟกต์ระเบิด) --")
	var stex: Texture2D = load(MonsterProjectile.DEFAULT_BURST)
	check.call("โหลด slime_burst.png ได้", stex != null)
	if stex != null:
		print("   ชีท %dx%d" % [stex.get_width(), stex.get_height()])
		check.call("★ กว้างหารด้วย %d ลงตัว ★" % SLIME_FRAMES,
			stex.get_width() % SLIME_FRAMES == 0, "%d" % stex.get_width())
		var bf: SpriteFrames = MonsterProjectile._default_burst_frames()
		check.call("สร้าง SpriteFrames ระเบิดได้", bf != null and bf.has_animation(&"burst"))
		if bf != null:
			var bn := bf.get_frame_count(&"burst")
			check.call("★ ระเบิดมี %d เฟรม ★" % SLIME_FRAMES, bn == SLIME_FRAMES, "%d" % bn)
			var b0: AtlasTexture = bf.get_frame_texture(&"burst", 0)
			check.call("★ ช่องกว้างคิดจากภาพจริง ไม่ใช่ 256 ตายตัว ★",
				int(b0.region.size.x) == stex.get_width() / SLIME_FRAMES,
				"%d vs %d" % [int(b0.region.size.x), stex.get_width() / SLIME_FRAMES])
			check.call("★ ช่องสูงเต็มภาพ ★", int(b0.region.size.y) == stex.get_height(),
				"%d vs %d" % [int(b0.region.size.y), stex.get_height()])
			var blast: AtlasTexture = bf.get_frame_texture(&"burst", bn - 1)
			check.call("เฟรมสุดท้ายจบพอดีขอบขวา",
				int(blast.region.position.x + blast.region.size.x) == stex.get_width())
			# ทุกเฟรมมีภาพ
			var simg: Image = stex.get_image()
			var scw := int(b0.region.size.x)
			var sempty := 0
			for i in range(bn):
				if _content_box(simg, i * scw, scw, stex.get_height()).size.x <= 0.0:
					sempty += 1
			check.call("★ ทุกเฟรมสไลม์มีภาพ ★", sempty == 0, "ว่าง %d" % sempty)

	var kp: MonsterData = GameData.get_monster(&"king_poring")
	if kp != null and stex != null:
		var kk: float = kp.skill_explosion_height / float(stex.get_height())
		print("   คิงโพริง: บนจอ %.0f x %.0f" % [(stex.get_width() / SLIME_FRAMES) * kk, kp.skill_explosion_height])
		check.call("ขนาดระเบิดคิงโพริงไม่ใหญ่เกิน 2 เท่าตัวละคร",
			kp.skill_explosion_height <= 480.0, "%f" % kp.skill_explosion_height)

	# =========================================================
	# 5) เล่นจริงในเกม — ใช้สกิลแล้วเอฟเฟกต์โผล่ ขนาดถูก
	# =========================================================
	print("\n-- 5) ใช้สกิลจริง --")
	await Game.change_map(&"gm_room", &"default")
	await get_tree().create_timer(1.2).timeout
	get_tree().paused = false
	var p = get_tree().get_first_node_in_group("player")
	if p != null and skill != null:
		PlayerState.stats.level = 50
		PlayerState.skills.learned[&"bash"] = 5
		PlayerState.skills.learned[&"magnum_break"] = 3
		PlayerState.cooldowns.clear()
		PlayerState.stats.sp = PlayerState.stats.max_sp
		p.use_skill(&"magnum_break")
		await get_tree().create_timer(skill.effect_delay + 0.25).timeout
		var fx: Node = null
		for c in p.get_parent().get_children():
			if String(c.name).begins_with("SkillEffect"):
				fx = c
		check.call("★ ใช้สกิลแล้วเอฟเฟกต์โผล่จริง ★", fx != null)
		if fx != null:
			var spr: AnimatedSprite2D = fx.get_child(0)
			var on_h: float = float(sh) * spr.scale.y
			check.call("★ เอฟเฟกต์บนจอสูง %.0f px ตามที่ตั้งไว้ ★" % on_h,
				absf(on_h - skill.effect_height) < 2.0, "%f" % on_h)
			var ground_y: float = fx.global_position.y + on_h * 0.5 - 8.0 * spr.scale.y
			var feet: float = p.foot_position().y
			check.call("★ วงไฟตกที่เท้าผู้เล่น (คลาด %.0f px) ★" % absf(ground_y - feet),
				absf(ground_y - feet) <= 30.0, "%f vs %f" % [ground_y, feet])
			check.call("เอฟเฟกต์เล่นท่า burst อยู่", spr.animation == &"burst")

	print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
	get_tree().quit()


## กรอบเนื้อภาพในช่องที่ x0 กว้าง w สูง h (ข้ามพิกเซลโปร่งใส)
func _content_box(img: Image, x0: int, w: int, h: int) -> Rect2:
	var l := w
	var r := -1
	var t := h
	var b := -1
	var step := 2
	for y in range(0, h, step):
		for x in range(0, w, step):
			if img.get_pixel(x0 + x, y).a > 0.08:
				if x < l: l = x
				if x > r: r = x
				if y < t: t = y
				if y > b: b = y
	if r < 0:
		return Rect2(0, 0, 0, 0)
	return Rect2(l, t, r - l + 1, b - t + 1)
