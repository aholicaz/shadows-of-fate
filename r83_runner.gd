extends Node
## ★ เทสต์รอบ 83 — ทุกท่าของมอนตัวเท่ากัน (ผู้พิทักษ์เตาหลอม: Attack เคยหดลง 15%) ★

const ANIMS := [&"Idle", &"Run", &"Attack"]

func run() -> void:
	var score := [0, 0]
	var check := func(n: String, c: bool, e: String = "") -> void:
		if c: score[0] += 1
		else:
			score[1] += 1
			print("  x FAIL: ", n, " ", e)

	# =========================================================
	# 1) ข้อมูลมอน + ชีทครบ
	# =========================================================
	print("\n-- 1) ข้อมูล --")
	var d: MonsterData = GameData.get_monster(&"forge_guardian")
	check.call("โหลดผู้พิทักษ์เตาหลอมได้", d != null)
	if d == null:
		print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
		get_tree().quit()
		return
	check.call("★ ค่าเริ่มต้น: ใช้สเกลเดียวกันทุกท่า ★", d.fit_uniform_scale)
	check.call("ท่าอ้างอิงคือ Idle", d.fit_reference_anim == &"Idle", "%s" % d.fit_reference_anim)
	check.call("ตั้งความสูงบนจอไว้", d.display_height > 0.0, "%f" % d.display_height)
	var sf: SpriteFrames = d.sprite_frames
	check.call("มีไฟล์ท่าทาง", sf != null)
	if sf == null:
		print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
		get_tree().quit()
		return
	for a in ANIMS:
		check.call("มีท่า %s" % a, sf.has_animation(a) and sf.get_frame_count(a) > 0)

	# ★ ขนาดกรอบภาพดิบของแต่ละท่า ★ นี่คือต้นเหตุ: Attack ยกอาวุธสูงกว่า Idle มาก
	var raw := {}
	for a in ANIMS:
		var m: Dictionary = SpriteFit.measure(sf, a)
		raw[a] = float(m.get("tallest", 0.0))
		print("   %s กรอบสูงสุด %.0f px" % [a, raw[a]])
	check.call("Attack มีเฟรมที่กรอบสูงกว่า Idle จริง (ยกอาวุธ)",
		raw[&"Attack"] > raw[&"Idle"], "%.0f vs %.0f" % [raw[&"Attack"], raw[&"Idle"]])

	# =========================================================
	# 2) เกิดมอนจริงในห้อง GM แล้ววัดสเกลของแต่ละท่า
	# =========================================================
	print("\n-- 2) สเกลจริงตอนเล่นแต่ละท่า --")
	await Game.change_map(&"gm_room", &"default")
	await get_tree().create_timer(1.2).timeout
	get_tree().paused = false
	PlayerState.set_flag(&"seen_intro_forge_guardian")
	var map = get_tree().get_first_node_in_group("map")
	var mob = load("res://scenes/monsters/monster.tscn").instantiate()
	mob.data = d
	mob.global_position = Vector2(1200, 700)
	map.add_child(mob)
	mob.set_home(mob.global_position)
	await get_tree().create_timer(0.8).timeout
	mob.set_physics_process(false)

	var scales := {}
	var feet := {}
	var body_h := {}
	for a in ANIMS:
		mob._play(String(a), true)
		await get_tree().process_frame
		await get_tree().process_frame
		scales[a] = float(mob.sprite.scale.y)
		feet[a] = mob.foot_position().y
		body_h[a] = mob.body_size().y
		print("   %s → scale %.4f · ตัวสูงบนจอ %.0f px · เท้า y %.0f"
			% [a, scales[a], raw[a] * scales[a], feet[a]])

	var s_idle: float = scales[&"Idle"]
	var s_run: float = scales[&"Run"]
	var s_atk: float = scales[&"Attack"]
	check.call("★ Attack ใช้สเกลเท่ากับ Idle ★", is_equal_approx(s_atk, s_idle),
		"%.4f vs %.4f" % [s_atk, s_idle])
	check.call("★ Run ใช้สเกลเท่ากับ Idle ★", is_equal_approx(s_run, s_idle),
		"%.4f vs %.4f" % [s_run, s_idle])
	check.call("สเกลไม่เป็นศูนย์", s_idle > 0.0)
	check.call("★ ท่าอ้างอิง (Idle) สูงเท่า Display Height พอดี ★",
		absf(raw[&"Idle"] * s_idle - d.display_height) < 2.0,
		"%.1f vs %.1f" % [raw[&"Idle"] * s_idle, d.display_height])

	# ★ ตัวจริง (เฟรมยืน) ต้องสูงพอ ๆ กันทุกท่า ★
	var stand := {}
	for a in ANIMS:
		stand[a] = _stand_height(sf, a) * float(scales[a])
		print("   %s เฟรมยืนสูงบนจอ %.0f px" % [a, stand[a]])
	var lo: float = minf(minf(stand[&"Idle"], stand[&"Run"]), stand[&"Attack"])
	var hi: float = maxf(maxf(stand[&"Idle"], stand[&"Run"]), stand[&"Attack"])
	var spread: float = (hi - lo) / hi
	check.call("★ ตัวมอนสูงพอ ๆ กันทุกท่า (ต่างกัน %.1f%%) ★" % (spread * 100.0), spread <= 0.08)
	check.call("★ Attack ไม่หดเมื่อเทียบกับ Run (%.0f vs %.0f px) ★" % [stand[&"Attack"], stand[&"Run"]],
		stand[&"Attack"] >= stand[&"Run"] * 0.92)
	check.call("★ Attack ไม่หดเมื่อเทียบกับ Idle ★", absf(stand[&"Attack"] - stand[&"Idle"]) <= 8.0,
		"%.0f vs %.0f" % [stand[&"Attack"], stand[&"Idle"]])

	# =========================================================
	# 3) เท้ายังแตะพื้นเท่ากันทุกท่า · กรอบโดนฟันไม่โตตามอาวุธ
	# =========================================================
	print("\n-- 3) เท้า/กรอบตัว --")
	var f_lo: float = minf(minf(feet[&"Idle"], feet[&"Run"]), feet[&"Attack"])
	var f_hi: float = maxf(maxf(feet[&"Idle"], feet[&"Run"]), feet[&"Attack"])
	check.call("★ เท้าอยู่ระดับเดียวกันทุกท่า (ต่าง %.0f px) ★" % (f_hi - f_lo), f_hi - f_lo <= 2.0)
	check.call("★ กรอบตัวไม่โตตอนยกอาวุธ (Attack %.0f = Idle %.0f) ★" % [body_h[&"Attack"], body_h[&"Idle"]],
		is_equal_approx(body_h[&"Attack"], body_h[&"Idle"]))
	check.call("กรอบตัวไม่เล็กกว่า Display Height", body_h[&"Idle"] >= d.display_height - 1.0)

	# =========================================================
	# 4) ปิดสวิตช์แล้วกลับไปเป็นแบบเดิม (ของเก่ายังใช้ได้)
	# =========================================================
	print("\n-- 4) ปิดสวิตช์ = พฤติกรรมเดิม --")
	var d2: MonsterData = d.duplicate()
	d2.fit_uniform_scale = false
	var mob2 = load("res://scenes/monsters/monster.tscn").instantiate()
	mob2.data = d2
	mob2.global_position = Vector2(1600, 700)
	map.add_child(mob2)
	mob2.set_home(mob2.global_position)
	await get_tree().create_timer(0.6).timeout
	mob2.set_physics_process(false)
	var old_scales := {}
	for a in ANIMS:
		mob2._play(String(a), true)
		await get_tree().process_frame
		await get_tree().process_frame
		old_scales[a] = float(mob2.sprite.scale.y)
	print("   แบบเดิม: Idle %.4f · Run %.4f · Attack %.4f"
		% [old_scales[&"Idle"], old_scales[&"Run"], old_scales[&"Attack"]])
	check.call("★ ปิดสวิตช์แล้ว Attack กลับมาเล็กกว่า Idle (ยืนยันว่านี่คือบั๊กเดิมจริง) ★",
		old_scales[&"Attack"] < old_scales[&"Idle"] - 0.001,
		"%.4f vs %.4f" % [old_scales[&"Attack"], old_scales[&"Idle"]])
	var gain: float = (s_atk / old_scales[&"Attack"] - 1.0) * 100.0
	print("   ★ ท่า Attack ใหญ่ขึ้น %.1f%% จากของเดิม ★" % gain)
	check.call("แก้แล้วท่า Attack ใหญ่ขึ้นจริง", gain > 5.0, "%.1f%%" % gain)

	# =========================================================
	# 4.5) ★ รอบ 86 ★ ชีทที่วาดตัวคนละขนาด ต้องไม่ทำให้ตัวบวม
	# =========================================================
	print("\n-- 4.5) กันตัวบวม (ชีทวาดคนละขนาด) --")
	check.call("มีเพดานกันบวมตั้งไว้", d.fit_max_overshoot >= 1.0, "%f" % d.fit_max_overshoot)
	# หามอนที่มีท่าสูงกว่าท่าอ้างอิงเกินเพดาน (ในเกมจริงคือ Run ของออร์ค/มูนัค/อสูรสายฟ้า)
	var swollen := 0
	var checked_sw := 0
	for mid in GameData.monsters.keys():
		var md: MonsterData = GameData.monsters[mid]
		if md.sprite_frames == null or md.display_height <= 0.0 or not md.fit_uniform_scale:
			continue
		var names := md.sprite_frames.get_animation_names()
		var ref := 0.0
		for want in ["Idle", "Stand", "Run", "Walk"]:
			for nm in names:
				if String(nm).to_lower() == want.to_lower() and md.sprite_frames.get_frame_count(nm) > 0:
					ref = float(SpriteFit.measure(md.sprite_frames, StringName(nm)).get("tallest", 0.0))
					break
			if ref > 0.0:
				break
		if ref <= 0.0:
			continue
		checked_sw += 1
		for nm in names:
			if md.sprite_frames.get_frame_count(nm) <= 0:
				continue
			var t := float(SpriteFit.measure(md.sprite_frames, nm).get("tallest", 0.0))
			if t <= 0.0:
				continue
			# สเกลที่ระบบจะใช้จริงหลังใส่เพดานแล้ว
			var from: float = ref if t <= ref * md.fit_max_overshoot else t
			var on_screen: float = t * (md.display_height / from)
			if on_screen > md.display_height * md.fit_max_overshoot + 1.0:
				swollen += 1
				print("    (%s ท่า %s สูงบนจอ %.0f · Display Height %.0f)" % [mid, nm, on_screen, md.display_height])
	check.call("★ มอน %d ตัว — ไม่มีท่าไหนสูงเกินเพดาน %.2f เท่าของ Display Height ★"
		% [checked_sw, d.fit_max_overshoot], swollen == 0, "%d ท่า" % swollen)

	# มอนจำลอง: ท่า Run ถูกวาดใหญ่กว่า Idle 2.2 เท่า → ต้องถอยไปย่อแยกท่า ไม่ใช่บวม
	var fake := _fake_frames(200, 440)      # Idle สูง 200 · Run สูง 440 (2.2 เท่า)
	var d3: MonsterData = d.duplicate()
	d3.sprite_frames = fake
	d3.display_height = 200.0
	var mob3 = load("res://scenes/monsters/monster.tscn").instantiate()
	mob3.data = d3
	mob3.global_position = Vector2(2000, 700)
	map.add_child(mob3)
	mob3.set_home(mob3.global_position)
	await get_tree().create_timer(0.6).timeout
	mob3.set_physics_process(false)
	var on := {}
	for a in [&"Idle", &"Run"]:
		mob3._play(String(a), true)
		await get_tree().process_frame
		await get_tree().process_frame
		var t := float(SpriteFit.measure(fake, a).get("tallest", 0.0))
		on[a] = t * float(mob3.sprite.scale.y)
		print("   จำลอง %s: ภาพสูง %.0f → บนจอ %.0f" % [a, t, on[a]])
	check.call("★ ท่า Idle สูงเท่า Display Height ★", absf(on[&"Idle"] - 200.0) < 2.0, "%.1f" % on[&"Idle"])
	check.call("★ ท่า Run ที่วาดใหญ่ 2.2 เท่า ไม่บวม (ยังราว ๆ 200 ไม่ใช่ 440) ★",
		on[&"Run"] <= 200.0 * d3.fit_max_overshoot + 2.0, "%.1f" % on[&"Run"])
	check.call("กรอบตัวยังนิ่ง (เท่า Display Height)", absf(mob3.body_size().y - 200.0) < 2.0,
		"%.1f" % mob3.body_size().y)

	# =========================================================
	# 5) มอนตัวอื่นไม่พัง
	# =========================================================
	print("\n-- 5) มอนตัวอื่น --")
	var bad := 0
	var checked := 0
	for mid in GameData.monsters.keys():
		var md: MonsterData = GameData.monsters[mid]
		if md.sprite_frames == null or md.display_height <= 0.0:
			continue
		checked += 1
		var names := md.sprite_frames.get_animation_names()
		var ref := 0.0
		for want in ["Idle", "Stand", "Run", "Walk"]:
			for nm in names:
				if String(nm).to_lower() == want.to_lower() and md.sprite_frames.get_frame_count(nm) > 0:
					ref = float(SpriteFit.measure(md.sprite_frames, StringName(nm)).get("tallest", 0.0))
					break
			if ref > 0.0:
				break
		if ref <= 0.0:
			continue
		var k: float = md.display_height / ref
		# ท่าไหนก็ไม่ควรโตเกิน 2 เท่าของความสูงที่ตั้งไว้ (กันภาพล้นจอ)
		for nm in names:
			if md.sprite_frames.get_frame_count(nm) <= 0:
				continue
			var t := float(SpriteFit.measure(md.sprite_frames, nm).get("tallest", 0.0))
			if t * k > md.display_height * 2.0:
				bad += 1
				print("    (%s ท่า %s สูง %.0f — เกิน 2 เท่าของ %.0f)" % [mid, nm, t * k, md.display_height])
				break
	check.call("★ มอน %d ตัวที่ตั้ง Display Height ไว้ ไม่มีตัวไหนภาพล้นเกิน 2 เท่า ★" % checked, bad == 0)

	print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
	get_tree().quit()


## ความสูงของ "เฟรมยืน" ของท่านั้น = ค่ากลาง (median) ของความสูงทุกเฟรม
## ใช้ค่ากลางเพราะเฟรมยกอาวุธ/ย่อตัวเป็นส่วนน้อย ไม่ควรมาชี้ขนาดตัวจริง
func _stand_height(sf: SpriteFrames, anim: StringName) -> float:
	var hs: Array[float] = []
	for i in range(sf.get_frame_count(anim)):
		var tex := sf.get_frame_texture(anim, i)
		if tex == null:
			continue
		var img := tex.get_image()
		if img == null:
			continue
		var r := img.get_used_rect()
		if r.size.y > 0:
			hs.append(float(r.size.y))
	if hs.is_empty():
		return 0.0
	hs.sort()
	return hs[hs.size() / 2]


## สร้าง SpriteFrames จำลอง: Idle เนื้อภาพสูง h1 · Run สูง h2 (ผ้าใบเท่ากัน)
func _fake_frames(h1: int, h2: int) -> SpriteFrames:
	var sf := SpriteFrames.new()
	for pair in [[&"Idle", h1], [&"Run", h2]]:
		var nm: StringName = pair[0]
		if not sf.has_animation(nm):
			sf.add_animation(nm)
		sf.set_animation_loop(nm, true)
		var img := Image.create(512, 512, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var hh: int = int(pair[1])
		img.fill_rect(Rect2i(200, 500 - hh, 112, hh), Color(0.6, 0.4, 0.8, 1.0))
		sf.add_frame(nm, ImageTexture.create_from_image(img))
	return sf
