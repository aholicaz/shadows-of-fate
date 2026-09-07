extends Node
## ★ เทสต์รอบ 88 — มอนเปลี่ยนท่าแล้วต้องไม่เด้ง/ไม่กระพริบ · ความเร็วภาพท่าวิ่งไม่ติดไปท่าอื่น ★
##
## วิธีวัด: โหนดตัววัดทำงาน "หลัง" มอนทุกเฟรม (process_priority สูงกว่า) อ่านกรอบภาพจริง
## ที่กำลังวาด (sprite.get_rect() แปลงเป็นพิกัดโลก) แล้วบันทึกทุกเฟรมระหว่างเปลี่ยนท่า
## ถ้ามีเฟรมไหนขอบล่าง/ความสูง/กึ่งกลางกระโดด = เด้ง

var _samples: Array = []
var _watch: Node = null


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
	PlayerState.gm_god_mode = true
	var map = get_tree().get_first_node_in_group("map")
	var p = get_tree().get_first_node_in_group("player")
	p.global_position = Vector2(200, 700)

	# ตัววัด — ทำงานหลังมอนทุกตัว
	var sampler := Node.new()
	sampler.name = "Sampler"
	sampler.process_priority = 200
	sampler.set_script(load("res://r88_sampler.gd"))
	add_child(sampler)
	sampler.owner_runner = self

	# =========================================================
	# 1) ผู้พิทักษ์เตาหลอม (ภาพจริง) — Idle → Run → Attack → Hit → Idle
	# =========================================================
	print("\n-- 1) ผู้พิทักษ์เตาหลอม (ภาพจริง) --")
	var d: MonsterData = GameData.get_monster(&"forge_guardian")
	PlayerState.set_flag(&"seen_intro_forge_guardian")
	var now: Dictionary = await _cycle_and_check(d, map, check, "ผู้พิทักษ์เตาหลอม", 0.06)

	# เทียบกับแบบเดิมก่อนรอบ 83 (ย่อแยกท่า) — พิสูจน์ว่ารอบ 83 ไม่ได้ทำให้เด้งมากขึ้น
	print("\n-- 1b) แบบเดิมก่อนรอบ 83 (ปิด Fit Uniform Scale) เพื่อเทียบ --")
	var d_old: MonsterData = d.duplicate()
	d_old.fit_uniform_scale = false
	var old: Dictionary = await _cycle_and_check(d_old, map, check, "ผู้พิทักษ์ (แบบเดิม)", 0.06, false)
	check.call("★ รอบ 83 ไม่ได้ทำให้เท้าเด้งมากขึ้น (ตอนนี้ %.1f vs เดิม %.1f px) ★" % [now.trans_foot, old.trans_foot],
		now.trans_foot <= old.trans_foot + 3.0)
	check.call("★ รอบ 83 ทำให้ตัวโต/หดวูบน้อยลง (ตอนนี้ %.1f%% vs เดิม %.1f%%) ★" % [now.height_jump * 100.0, old.height_jump * 100.0],
		now.height_jump < old.height_jump)

	# =========================================================
	# 2) มอนจำลองแบบ "ออร์ค" — ชีท Run วาดใหญ่ 2.2 เท่า ผ้าใบคนละขนาด
	#    นี่คือกรณีที่สเกลเปลี่ยนตอนเปลี่ยนท่า (รอบ 86) ต้องไม่กระพริบสักเฟรม
	# =========================================================
	print("\n-- 2) มอนจำลอง: Run วาดใหญ่ 2.2 เท่าบนผ้าใบใหญ่กว่า --")
	var d2: MonsterData = d.duplicate()
	d2.id = &"fake_orc"
	d2.display_name = "จำลองออร์ค"
	d2.sprite_frames = _fake_frames()
	d2.display_height = 255.0
	d2.intro_video = ""
	await _cycle_and_check(d2, map, check, "จำลองออร์ค", 0.06)

	# =========================================================
	# 3) ความเร็วภาพท่าวิ่งต้องไม่ติดไปท่าอื่น (บั๊กรอบ 87)
	# =========================================================
	print("\n-- 3) ความเร็วภาพไม่ติดข้ามท่า --")
	var mob = load("res://scenes/monsters/monster.tscn").instantiate()
	mob.data = d
	mob.global_position = Vector2(2400, 700)
	map.add_child(mob)
	mob.set_home(mob.global_position)
	await get_tree().create_timer(0.6).timeout
	mob.set_physics_process(false)
	# จำลอง "เดินเตร่" → ภาพวิ่งช้า
	mob._play("Run", true)
	mob.velocity.x = -d.wander_speed
	mob._sync_run_anim_speed()
	check.call("เดินเตร่ → ท่าวิ่งช้าลง (%.2f×)" % mob.sprite.speed_scale, mob.sprite.speed_scale < 0.6)
	# แล้วเริ่มตีทันที (สถานะ ATTACK ไม่ผ่าน _sync_run_anim_speed อีก)
	mob._play("Attack", true)
	check.call("★ เริ่มตีจากเดินเตร่ → ท่าตีเล่นความเร็วปกติ (ไม่ใช่ 0.35×) ★",
		is_equal_approx(mob.sprite.speed_scale, 1.0), "%f" % mob.sprite.speed_scale)
	mob._play("Run", true)
	mob.velocity.x = -d.wander_speed
	mob._sync_run_anim_speed()
	mob._play("Hit", true)
	check.call("★ โดนตีตอนเดินเตร่ → ท่าโดนตีความเร็วปกติ ★", is_equal_approx(mob.sprite.speed_scale, 1.0))
	mob._play("Run", true)
	mob.velocity.x = -d.move_speed
	mob._sync_run_anim_speed()
	check.call("วิ่งเต็มสปีดยังได้ 1.0×", is_equal_approx(mob.sprite.speed_scale, 1.0))
	mob.queue_free()

	PlayerState.gm_god_mode = false
	print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
	get_tree().quit()


## เกิดมอน แล้วไล่เปลี่ยนท่าโดยบันทึกกรอบภาพจริงทุกเฟรม
func _cycle_and_check(d: MonsterData, map: Node, check: Callable, label: String, tol_frac: float, strict: bool = true) -> Dictionary:
	var mob = load("res://scenes/monsters/monster.tscn").instantiate()
	mob.data = d
	mob.global_position = Vector2(2400, 700)
	map.add_child(mob)
	mob.set_home(mob.global_position)
	await get_tree().create_timer(0.8).timeout
	mob.set_physics_process(false)
	mob.velocity = Vector2.ZERO

	_samples.clear()
	_watch = mob
	var seq := ["Idle", "Run", "Attack", "Hit", "Idle", "Run", "Idle"]
	for a in seq:
		mob._play(a, true)
		# เก็บ ~10 เฟรมต่อท่า (รวมเฟรมแรกหลังสลับท่า)
		for i in range(10):
			await get_tree().process_frame
	_watch = null

	# ---------- วิเคราะห์ ----------
	var foot: float = mob.foot_position().y
	var bottoms: Array[float] = []
	var heights: Array[float] = []
	var centers: Array[float] = []
	for s in _samples:
		bottoms.append(s.bottom)
		heights.append(s.height)
		centers.append(s.cx)
	var b_lo: float = bottoms.min()
	var b_hi: float = bottoms.max()
	var h_lo: float = heights.min()
	var h_hi: float = heights.max()
	var c_lo: float = centers.min()
	var c_hi: float = centers.max()
	print("   %s: เก็บ %d เฟรม · ขอบล่าง %.0f..%.0f (เท้า %.0f) · สูง %.0f..%.0f · กึ่งกลาง x %.0f..%.0f"
		% [label, _samples.size(), b_lo, b_hi, foot, h_lo, h_hi, c_lo, c_hi])
	# หาเฟรมที่ "กระโดด" จากเฟรมก่อนหน้า
	var worst_h := 0.0
	var worst_b := 0.0
	var worst_c := 0.0
	var worst_at := ""
	var worst_b_at := ""
	var trans_b := 0.0        # กระโดดของเท้าเฉพาะ "ตอนสลับท่า"
	var trans_at := ""
	for i in range(1, _samples.size()):
		var a = _samples[i - 1]
		var b = _samples[i]
		var dh: float = absf(b.height - a.height) / maxf(1.0, a.height)
		var db: float = absf(b.bottom - a.bottom)
		var dc: float = absf(b.cx - a.cx)
		if dh > worst_h:
			worst_h = dh
			worst_at = "%s→%s" % [a.anim, b.anim]
		if db > worst_b:
			worst_b = db
			worst_b_at = "%s f%d→%s f%d" % [a.anim, a.frame, b.anim, b.frame]
		if a.anim != b.anim and db > trans_b:
			trans_b = db
			trans_at = "%s→%s" % [a.anim, b.anim]
		worst_c = maxf(worst_c, dc)
	print("   กระโดดสุดระหว่างเฟรม: สูง %.1f%% (%s) · ขอบล่าง %.1f px (%s) · กึ่งกลาง %.1f px"
		% [worst_h * 100.0, worst_at, worst_b, worst_b_at, worst_c])
	print("   เฉพาะตอนสลับท่า: เท้ากระโดดสุด %.1f px (%s)" % [trans_b, trans_at])
	var result := {"foot_span": b_hi - b_lo, "trans_foot": trans_b, "height_jump": worst_h, "cx_jump": worst_c}
	if strict:
		# เท้าขยับได้ตามท่า (ก้าวเดิน/ย่อตัว) แต่ต้องไม่หลุดจากพื้นเกิน ~4% ของตัว
		var foot_tol: float = maxf(12.0, d.display_height * 0.04)
		check.call("★ %s: เท้าไม่หลุดพื้นเกิน %.0f px ตลอดการเปลี่ยนท่า ★" % [label, foot_tol],
			b_hi - b_lo <= foot_tol, "%.1f" % (b_hi - b_lo))
		check.call("★ %s: ตอนสลับท่าเท้าไม่กระโดดเกิน %.0f px ★" % [label, foot_tol],
			trans_b <= foot_tol, "%.1f" % trans_b)
		check.call("★ %s: ไม่มีเฟรมที่ตัวโต/หดวูบ (>%.0f%%) ★" % [label, (tol_frac + 0.04) * 100.0],
			worst_h <= tol_frac + 0.04, "%.1f%%" % (worst_h * 100.0))
		check.call("%s: ความสูงตลอดทุกท่าอยู่ในช่วง −25%%…+40%% ของ Display Height" % label,
			h_lo >= d.display_height * 0.75 and h_hi <= d.display_height * 1.4,
			"%.0f..%.0f vs %.0f" % [h_lo, h_hi, d.display_height])
		check.call("%s: กึ่งกลางแนวนอนไม่เด้งเกิน 25 px" % label, worst_c <= 25.0, "%.1f" % worst_c)
	mob.queue_free()
	await get_tree().process_frame
	return result


## เรียกจาก Sampler ทุกเฟรม (หลังมอน _process แล้ว)
func sample() -> void:
	if _watch == null or not is_instance_valid(_watch):
		return
	var sp: AnimatedSprite2D = _watch.sprite
	if sp.sprite_frames == null:
		return
	var tex := sp.sprite_frames.get_frame_texture(sp.animation, sp.frame)
	if tex == null:
		return
	# กรอบภาพในพิกัดของ sprite (AnimatedSprite2D ไม่มี get_rect — คิดเองจาก offset/centered)
	var tsz := Vector2(tex.get_width(), tex.get_height())
	var r := Rect2(sp.offset - (tsz * 0.5 if sp.centered else Vector2.ZERO), tsz)
	var xf: Transform2D = sp.global_transform
	# ★ กรอบเนื้อภาพจริง ★ (ตัดขอบโปร่งใส) — ไม่งั้นผ้าใบคนละขนาดจะหลอกตา
	var used := Rect2(0, 0, tex.get_width(), tex.get_height())
	var img := tex.get_image()
	if img != null:
		var u := img.get_used_rect()
		if u.size.x > 0:
			used = Rect2(u.position, u.size)
	var k: float = absf(sp.scale.y)
	var local_top: float = r.position.y + used.position.y
	var local_bot: float = r.position.y + used.position.y + used.size.y
	var local_cx: float = r.position.x + used.position.x + used.size.x * 0.5
	if sp.flip_h:
		local_cx = r.position.x + (r.size.x - (used.position.x + used.size.x * 0.5))
	_samples.append({
		"anim": String(sp.animation), "frame": sp.frame,
		"bottom": (xf * Vector2(0, local_bot)).y,
		"height": (local_bot - local_top) * k,
		"cx": (xf * Vector2(local_cx, 0)).x,
	})


## ชีทจำลองแบบออร์ค: Idle/Attack บนผ้าใบ 512 ตัวสูง 384 · Run บนผ้าใบ 1024 ตัวสูง 834 (2.2 เท่า)
func _fake_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	var spec := {
		"Idle": [512, 384, 4, 0.0], "Attack": [512, 384, 4, 0.05], "Hit": [512, 380, 2, 0.0],
		"Run": [1024, 834, 6, 0.0],
	}
	for nm in spec.keys():
		var canvas: int = spec[nm][0]
		var h: int = spec[nm][1]
		var n: int = spec[nm][2]
		var bob: float = spec[nm][3]
		sf.add_animation(nm)
		sf.set_animation_loop(nm, nm == "Idle" or nm == "Run")
		sf.set_animation_speed(nm, 10.0)
		for i in range(n):
			var img := Image.create(canvas, canvas, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var hh: int = h - int(float(h) * bob * (i % 2))
			var w: int = int(canvas * 0.45)
			var bottom: int = canvas - int(canvas * 0.08)
			img.fill_rect(Rect2i((canvas - w) / 2, bottom - hh, w, hh), Color(0.5, 0.7, 0.4, 1.0))
			sf.add_frame(nm, ImageTexture.create_from_image(img))
	return sf
