extends Node
## ★ เทสต์รอบ 94 — ขนาดตัวละครเท่ากันทุกท่า · ดาเมจออกตอนดาบฟาดถึง ★
##
## ใช้ภาพที่สร้างเองในเทสต์ (ไม่พึ่งงานศิลป์จริง) จะได้ผลเหมือนเดิมทุกครั้ง
## รูปแบบ: "ลำตัว" = สี่เหลี่ยมทึบกว้าง 120 px · "ดาบ" = เส้นบาง 6 px ที่ยื่นออกไป


const CELL := 512


## สร้างเฟรม 1 ใบ: ลำตัวสูง body_h วางให้เท้าอยู่ที่ y = foot_y
## sword_up = ดาบชูขึ้นเหนือหัวกี่ px (เส้นบาง) · sword_fwd = ดาบยื่นไปทางขวากี่ px
static func _frame(body_h: int, sword_up: int, sword_fwd: int, foot_y: int = 460) -> ImageTexture:
	var img := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var bw := 120
	var bx := (CELL - bw) / 2
	var by := foot_y - body_h
	img.fill_rect(Rect2i(bx, by, bw, body_h), Color(1, 1, 1, 1))
	if sword_up > 0:
		# เส้นบาง ๆ ชูขึ้นจากหัว — ต้องไม่ถูกนับเป็นลำตัว
		img.fill_rect(Rect2i(bx + bw / 2 - 3, maxi(0, by - sword_up), 6, sword_up), Color(1, 1, 1, 1))
	if sword_fwd > 0:
		# เส้นบาง ๆ ยื่นไปข้างหน้า (ขวา) ระดับอก
		img.fill_rect(Rect2i(bx + bw, by + body_h / 3, sword_fwd, 6), Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)


static func _anim(sf: SpriteFrames, name: String, specs: Array, fps: float = 10.0) -> void:
	sf.add_animation(name)
	sf.set_animation_speed(name, fps)
	sf.set_animation_loop(name, false)
	for sp in specs:
		sf.add_frame(name, _frame(sp[0], sp[1], sp[2]))


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

	# ---------- ชุดภาพจำลอง ----------
	# ทุกท่าลำตัวสูง 300 px เท่ากันหมด ต่างกันแค่ "ดาบชูสูงแค่ไหน"
	var sf := SpriteFrames.new()
	_anim(sf, "Idle", [[300, 0, 40], [300, 0, 40]])                       # ยืน ดาบห้อย
	_anim(sf, "Attack", [[300, 0, 40], [300, 0, 200], [300, 0, 60]])      # ฟันตรง
	_anim(sf, "Attack_up", [[300, 250, 40], [300, 240, 60], [300, 0, 40]])  # ชูดาบสูงมาก
	# ท่าที่ "วาดมาเล็กกว่า" — ลำตัว 150 px (ครึ่งเดียว) แต่ควรโชว์บนจอเท่ากัน
	_anim(sf, "Attack_small", [[150, 0, 20], [150, 0, 100], [150, 0, 30]])

	# =========================================================
	# 1) วัดลำตัวแยกจากดาบได้จริง
	# =========================================================
	print("\n-- 1) แยกลำตัวออกจากดาบ --")
	var m_idle: Dictionary = SpriteFit.measure(sf, &"Idle", {}, true)
	var m_up: Dictionary = SpriteFit.measure(sf, &"Attack_up", {}, true)
	print("  Idle      ความสูงรวม %.0f · ลำตัว %.0f" % [m_idle.tallest, m_idle.body_med])
	print("  Attack_up ความสูงรวม %.0f · ลำตัว %.0f" % [m_up.tallest, m_up.body_med])
	check.call("ลำตัวท่ายืน ≈ 300 px", absf(m_idle.body_med - 300.0) <= 8.0, "%.0f" % m_idle.body_med)
	check.call("★ ท่าชูดาบ: ความสูงรวมมากขึ้นจริง (ดาบนับรวม) ★", m_up.tallest > m_idle.tallest + 100.0,
		"%.0f vs %.0f" % [m_up.tallest, m_idle.tallest])
	check.call("★ แต่ลำตัวยังวัดได้ ≈ 300 px เท่าเดิม (ดาบไม่ถูกนับเป็นลำตัว) ★",
		absf(m_up.body_med - 300.0) <= 8.0, "%.0f" % m_up.body_med)

	# =========================================================
	# 2) สเกล: ทุกท่าลำตัวเท่ากันบนจอ
	# =========================================================
	print("\n-- 2) ขนาดตัวละครเท่ากันทุกท่า --")
	var old_sf: SpriteFrames = p.sprite.sprite_frames
	p.sprite.sprite_frames = sf
	p.clear_fit_cache()
	p.fit_uniform_body = true
	p.fit_reference_anim = &"Idle"

	var names := [&"Idle", &"Attack", &"Attack_up", &"Attack_small"]
	var on_new: Array = []
	for a in names:
		var info: Dictionary = p._fit_info(a)
		on_new.append(info.body_med * info.scale)
		print("  %-14s สเกล %.3f → ลำตัวบนจอ %.1f px" % [a, info.scale, info.body_med * info.scale])
	var lo_new: float = on_new.min()
	var hi_new: float = on_new.max()
	check.call("★ ทุกท่าลำตัวสูงเท่ากันบนจอ (คลาดไม่เกิน 2%%) ★", (hi_new - lo_new) / lo_new < 0.02,
		"%.1f .. %.1f px" % [lo_new, hi_new])
	check.call("★ ท่าที่วาดมาเล็กครึ่งเดียว ถูกขยายให้เท่ากัน ★",
		absf(on_new[3] - on_new[0]) / on_new[0] < 0.02, "%.1f vs %.1f" % [on_new[3], on_new[0]])

	# ขนาดตัวละครโดยรวมต้องไม่เปลี่ยน — ท่าอ้างอิงยังใช้สเกลเดิม
	var ref_info: Dictionary = p._fit_info(&"Idle")
	var old_ref_scale: float = p.auto_fit_height / maxf(1.0, ref_info.tallest)
	check.call("★ ท่าอ้างอิงสเกลเท่าเดิมเป๊ะ (ตัวละครไม่โตขึ้น/เล็กลงทั้งเกม) ★",
		absf(ref_info.scale - old_ref_scale) < 0.001, "%.4f vs %.4f" % [ref_info.scale, old_ref_scale])

	# เทียบกับของเดิม (สูตรเก่า = auto_fit_height ÷ ความสูงรวม ซึ่งนับดาบด้วย)
	var on_old: Array = []
	for a in names:
		var mm: Dictionary = SpriteFit.measure(sf, a, {}, true)
		on_old.append(mm.body_med * (p.auto_fit_height / maxf(1.0, mm.tallest)))
	var lo_old: float = on_old.min()
	var hi_old: float = on_old.max()
	print("  ก่อนแก้: ลำตัวบนจอ %.0f .. %.0f px (ต่างกัน %.0f%%)" % [lo_old, hi_old, 100.0 * (hi_old - lo_old) / lo_old])
	check.call("★ ยืนยันว่าของเดิมเพี้ยนจริง: ลำตัวต่างกันเกิน 20%% ★", (hi_old - lo_old) / lo_old > 0.20,
		"%.0f%%" % (100.0 * (hi_old - lo_old) / lo_old))

	# =========================================================
	# 3) หาเฟรมที่ดาบฟาดถึง
	# =========================================================
	print("\n-- 3) เฟรมที่ดาบฟาดถึง --")
	# Attack: ดาบยื่น 40 → 200 → 60 · ควรได้เฟรม 1
	var hf: int = p.attack_hit_frame_of("Attack")
	print("  Attack (ยื่น 40/200/60) → เฟรม %d" % hf)
	check.call("★ เลือกเฟรมที่ดาบยื่นสุด (เฟรม 1) ★", hf == 1, "%d" % hf)
	# Attack_small: 20 → 100 → 30 · ควรได้เฟรม 1 เหมือนกัน
	check.call("ท่าที่วาดเล็กกว่าก็หาเฟรมถูก", p.attack_hit_frame_of("Attack_small") == 1,
		"%d" % p.attack_hit_frame_of("Attack_small"))

	# ท่าที่ค้างดาบยื่นไว้หลายเฟรม → ต้องได้ "เฟรมแรกที่ดาบมาถึง" ไม่ใช่เฟรมท้าย
	var sf2 := SpriteFrames.new()
	_anim(sf2, "Hold", [[300, 0, 20], [300, 0, 30], [300, 0, 200], [300, 0, 210], [300, 0, 220]])
	p.sprite.sprite_frames = sf2
	p.clear_fit_cache()
	var hf2: int = p.attack_hit_frame_of("Hold")
	print("  Hold (ยื่น 20/30/200/210/220) → เฟรม %d" % hf2)
	check.call("★ ดาบค้างยื่นหลายเฟรม → เอาเฟรมแรกที่มาถึง (2) ไม่ใช่เฟรมท้าย (4) ★", hf2 == 2, "%d" % hf2)
	p.sprite.sprite_frames = sf
	p.clear_fit_cache()

	# =========================================================
	# 4) แปลงเฟรมเป็นเวลา + ลำดับความสำคัญของค่าที่ตั้งเอง
	# =========================================================
	print("\n-- 4) เวลาที่ดาเมจออก --")
	var t1: float = p._anim_time_to_frame("Attack", 1)
	check.call("เฟรม 1 ที่ 10 fps = 0.1 วิ", absf(t1 - 0.1) < 0.005, "%.3f" % t1)
	check.call("เฟรม 0 = 0 วิ", absf(p._anim_time_to_frame("Attack", 0)) < 0.001)

	p.attack_hit_auto = true
	p.combo_hit_frames = PackedInt32Array()
	var auto_t: float = p._attack_hit_time("Attack", 0)
	check.call("★ โหมดอัตโนมัติ: ดาเมจออกตอนเฟรม 1 (0.1 วิ) ไม่ใช่ 0.15 วิแบบเดิม ★",
		absf(auto_t - 0.1) < 0.005, "%.3f" % auto_t)

	p.combo_hit_frames = PackedInt32Array([2, -1, -1])
	check.call("ตั้งเลขเฟรมเองได้ (จังหวะ 1 → เฟรม 2 = 0.2 วิ)", absf(p._attack_hit_time("Attack", 0) - 0.2) < 0.005,
		"%.3f" % p._attack_hit_time("Attack", 0))
	check.call("ใส่ −1 = กลับไปให้ระบบหาเอง", absf(p._attack_hit_time("Attack", 1) - 0.1) < 0.005,
		"%.3f" % p._attack_hit_time("Attack", 1))

	p.combo_hit_frames = PackedInt32Array()
	p.attack_hit_auto = false
	check.call("ปิดอัตโนมัติ + ไม่ตั้งเอง → กลับไปใช้ Attack Windup เดิม",
		absf(p._attack_hit_time("Attack", 0) - p.attack_windup) < 0.005)
	p.attack_hit_auto = true

	# =========================================================
	# 5) ไม่พังเมื่อภาพผิดปกติ
	# =========================================================
	print("\n-- 5) กรณีผิดปกติ --")
	var sf3 := SpriteFrames.new()
	sf3.add_animation("Empty")
	sf3.set_animation_speed("Empty", 10.0)
	var blank := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	blank.fill(Color(0, 0, 0, 0))
	sf3.add_frame("Empty", ImageTexture.create_from_image(blank))
	var m_empty: Dictionary = SpriteFit.measure(sf3, &"Empty", {}, true)
	check.call("ภาพว่างเปล่าไม่ทำให้พัง", not m_empty.is_empty())
	check.call("ภาพว่างเปล่า → ลำตัว 0 (ตกไปใช้สูตรเดิม)", is_equal_approx(float(m_empty.get("body_med", -1.0)), 0.0),
		"%f" % float(m_empty.get("body_med", -1.0)))
	p.sprite.sprite_frames = sf3
	p.clear_fit_cache()
	var info_e: Dictionary = p._fit_info(&"Empty")
	check.call("ท่าที่วัดลำตัวไม่ได้ ยังคืนสเกลใช้งานได้", info_e.scale > 0.0, "%f" % info_e.scale)
	check.call("หาเฟรมฟาดไม่ได้ → คืน −1 (ไปใช้ Windup)", p.attack_hit_frame_of("Empty") == -1)

	# =========================================================
	# 6) แคช
	# =========================================================
	print("\n-- 6) แคช --")
	p.sprite.sprite_frames = sf
	p.clear_fit_cache()
	# ★ ใช้ชุดภาพใหม่เอี่ยม ★ ชุดเดิมถูกวัดไปแล้วระหว่างเทสต์ข้างบน จะทดสอบแคชไม่ได้
	var sf4 := SpriteFrames.new()
	_anim(sf4, "Solo", [[280, 0, 30], [280, 0, 150]])
	SpriteFit.measure(sf4, &"Solo", {}, true)
	var c1 := SpriteFit.measured_count
	SpriteFit.measure(sf4, &"Solo", {}, true)
	check.call("วัดซ้ำท่าเดิมใช้แคช", SpriteFit.measured_count == c1)
	# ★ ของที่วัดลำตัวแล้วมีข้อมูลครบกว่า → คนที่ไม่ต้องการลำตัว (มอน) ใช้ซ้ำได้เลย ไม่วัดใหม่
	var got: Dictionary = SpriteFit.measure(sf4, &"Solo", {}, false)
	check.call("★ วัดแบบไม่เอาลำตัว ใช้ของเดิมที่ครบกว่าได้ ไม่วัดซ้ำ ★",
		SpriteFit.measured_count == c1, "%d vs %d" % [SpriteFit.measured_count, c1])
	check.call("แคชช่องเดียว is_cached() ตอบถูก", SpriteFit.is_cached(sf4, &"Solo") and got.body_med > 0.0)

	# ทางกลับกัน: วัดแบบไม่เอาลำตัวก่อน แล้วค่อยขอลำตัว → ต้องวัดใหม่ทับ
	var sf5 := SpriteFrames.new()
	_anim(sf5, "Solo2", [[260, 0, 30], [260, 0, 140]])
	SpriteFit.measure(sf5, &"Solo2", {}, false)
	var c2 := SpriteFit.measured_count
	var up: Dictionary = SpriteFit.measure(sf5, &"Solo2", {}, true)
	check.call("★ ขอลำตัวทีหลัง → วัดใหม่ทับให้ (ไม่คืนค่าลำตัว 0) ★",
		SpriteFit.measured_count == c2 + 1 and up.body_med > 0.0, "%.0f" % up.body_med)

	# คืนของเดิม
	p.sprite.sprite_frames = old_sf
	p.clear_fit_cache()
	p.combo_hit_frames = PackedInt32Array()

	print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
	get_tree().quit()
