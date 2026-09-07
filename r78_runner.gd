extends Node
## ★ เทสต์รอบ 78 — สกิล "เคียวเงามรณะ" ของบาฟโฟเมท (คลื่นเคียวมืดวิ่งบนพื้น) ★

func _wave_node(map: Node) -> Node:
	for n in map.get_children():
		if n is DarkWave:
			return n
	return null

func run() -> void:
	var score := [0, 0]
	var check := func(n: String, c: bool, e: String = "") -> void:
		if c: score[0] += 1
		else:
			score[1] += 1
			print("  x FAIL: ", n, " ", e)

	# =========================================================
	# 1) ข้อมูล + ไฟล์เอฟเฟกต์
	# =========================================================
	print("\n-- 1) ข้อมูลบาฟโฟเมท --")
	var d: MonsterData = load("res://data/monsters/baphomet.tres")
	check.call("★ บาฟโฟเมทมีสกิล «เคียวเงามรณะ» ★", d.skill_name == "เคียวเงามรณะ", d.skill_name)
	check.call("★ ใช้ระบบคลื่น (Skill Wave Count 2) ★", d.skill_wave_count == 2, str(d.skill_wave_count))
	check.call("ปล่อยทั้งหน้าและหลัง", d.skill_wave_both_sides)
	check.call("has_skill() รู้จักคลื่นแล้ว", d.has_skill())
	check.call("มีไฟล์เอฟเฟกต์ fx_dark_wave.tres", ResourceLoader.exists("res://data/sprites/fx_dark_wave.tres"))
	var fx: SpriteFrames = load("res://data/sprites/fx_dark_wave.tres")
	check.call("เอฟเฟกต์มีท่า wave 8 เฟรม", fx != null and fx.has_animation("wave") and fx.get_frame_count("wave") == 8)
	check.call("มีไฟล์เสียง dark_wave.ogg", ResourceLoader.exists("res://Sprites/sfx/dark_wave.ogg"))
	check.call("มอนอื่นไม่ได้เปิดคลื่นโดยไม่ตั้งใจ", (load("res://data/monsters/poring.tres") as MonsterData).skill_wave_count == 0)
	# ความสูงคลื่นต้องต่ำกว่าจุดสูงสุดของการกระโดด (420²/(2·980) ≈ 90) — กระโดดข้ามได้จริง
	var apex: float = 420.0 * 420.0 / (2.0 * 980.0)
	check.call("★ คลื่นเตี้ยกว่ายอดกระโดดผู้เล่น (%.0f < %.0f) ★" % [d.skill_wave_hit_height, apex],
		d.skill_wave_hit_height < apex - 10.0)

	# =========================================================
	# 2) ร่ายจริงในแมพ — คลื่นเกิด วิ่งไปทั้งสองข้าง แล้วสลาย
	# =========================================================
	print("\n-- 2) ร่ายจริง --")
	PlayerState.set_flag(&"seen_map_prontera_field")
	PlayerState.set_flag(&"seen_intro_baphomet")
	await Game.change_map(&"prontera_field", &"default")
	await get_tree().create_timer(0.9).timeout
	get_tree().paused = false
	var p = get_tree().get_first_node_in_group("player")
	var map = get_tree().get_first_node_in_group("map")
	for m in get_tree().get_nodes_in_group("enemy"):
		m.queue_free()
	await get_tree().process_frame

	var dt: MonsterData = d.duplicate()
	dt.atk_min = 12
	dt.atk_max = 12      # ดาเมจ ×2 ≈ 20 ผู้เล่น Lv1 (HP 51) ยังไม่ตาย จะได้เทสต์หลายรอบ
	dt.move_speed = 0.0
	dt.attack_range = 1.0
	dt.skill_chance = 1.0
	var mscene: PackedScene = load("res://scenes/monsters/monster.tscn")
	var boss = mscene.instantiate()
	boss.data = dt
	boss.global_position = p.global_position + Vector2(700, -40)
	p.get_parent().add_child(boss)
	await get_tree().create_timer(0.8).timeout
	boss.set_home(boss.global_position)
	boss.set_physics_process(false)      # กัน AI ตี/ร่ายเอง — เทสต์สั่งเอง (กับดัก 100)
	boss._player = p
	boss._face_to(p.global_position.x - boss.global_position.x)
	var face: int = boss.facing
	print("  บอสหัน %d · เท้าบอส %s · เท้าผู้เล่น %s" % [face, str(boss.foot_position()), str(p.foot_position())])

	# ผู้เล่นยืนไกล ๆ ก่อน (นอกเส้นทาง)
	p.global_position = boss.global_position + Vector2(-1500, 0)
	p.velocity = Vector2.ZERO
	await get_tree().process_frame
	boss._cast_skill()
	await get_tree().create_timer(dt.skill_wave_delay + 0.15).timeout
	var wave: Node = _wave_node(map)
	if wave == null:
		var names: Array = []
		for c in map.get_children():
			names.append(c.name)
		print("  ลูกของแมพ: ", names)
	check.call("★ ร่ายแล้วเกิดโหนด DarkWave ในแมพ ★", wave != null)
	check.call("บอสเล่นท่า Skill", String(boss.get_node("AnimatedSprite2D").animation) == "Skill",
		String(boss.get_node("AnimatedSprite2D").animation))
	check.call("ตั้งคูลดาวน์สกิลแล้ว", boss._skill_cd > 5.0, str(boss._skill_cd))
	if wave == null:
		print("\n=== ผ่าน %d · ล้มเหลว %d ===" % score)
		get_tree().quit()
		return
	check.call("คลื่นเริ่มที่ระดับเท้าบอส", absf(wave.global_position.y - boss.foot_position().y) < 20.0,
		"%.0f vs %.0f" % [wave.global_position.y, boss.foot_position().y])
	check.call("★ ลูกแรกออกทั้งซ้ายและขวา (Both Sides) ★", wave._waves.size() == 2, str(wave._waves.size()))
	var dirs: Array = []
	for w in wave._waves:
		dirs.append(int(w.dir))
	check.call("ทิศตรงข้ามกัน", dirs.size() == 2 and dirs[0] == -dirs[1], str(dirs))
	# วิ่งจริง
	var x0: float = float(wave._waves[0].x) if wave._waves.size() > 0 else 0.0
	await get_tree().create_timer(0.25).timeout
	var moved := false
	if is_instance_valid(wave) and wave._waves.size() > 0:
		moved = absf(float(wave._waves[0].x) - x0) > 60.0
		print("  ลูกแรกวิ่งจาก %.0f → %.0f" % [x0, float(wave._waves[0].x)])
	check.call("★ คลื่นวิ่งไปตามพื้น ★", moved)
	await get_tree().create_timer(dt.skill_wave_interval).timeout
	var most := 0
	if is_instance_valid(wave):
		most = wave._waves.size()
	check.call("★ ระลอกที่ 2 ออกมา (มีคลื่นพร้อมกัน ≥ 3) ★", most >= 3, str(most))
	# รอจนหมดระยะ → โหนดลบตัวเอง
	var total: float = dt.skill_wave_range / dt.skill_wave_speed + dt.skill_wave_interval + DarkWave.FADE_TIME + 1.0
	await get_tree().create_timer(total).timeout
	check.call("★ สุดระยะแล้วโหนดคลื่นลบตัวเอง (ไม่ค้างในแมพ) ★", not is_instance_valid(wave))

	# =========================================================
	# 3) ดาเมจ — ยืนขวางโดน · กระโดดข้ามไม่โดน · โดนได้ลูกเดียว
	# =========================================================
	print("\n-- 3) ดาเมจ --")
	PlayerState.revive(1.0)
	PlayerState.stats.hp = PlayerState.stats.max_hp
	# ★ วางผู้เล่นด้วย "ระดับเท้า" ★ (จุดกำเนิด ≠ ปลายเท้า — กับดัก 1) ให้เท้าอยู่ระดับเดียวกับเท้าบอส
	var foot_off: float = p.foot_position().y - p.global_position.y
	var ground_y: float = boss.foot_position().y - foot_off
	p.global_position = Vector2(boss.global_position.x + face * 380, ground_y)
	p.velocity = Vector2.ZERO
	p.set_physics_process(false)
	await get_tree().create_timer(0.2).timeout
	var hp0: int = PlayerState.stats.hp
	boss._skill_cd = 0.0
	boss.state = 0
	boss._cast_skill()
	var reach: float = 380.0 / dt.skill_wave_speed
	await get_tree().create_timer(dt.skill_wave_delay + reach + 0.3).timeout
	var hit1: int = hp0 - PlayerState.stats.hp
	print("  ยืนขวางทาง: HP %d → %d (โดน %d)" % [hp0, PlayerState.stats.hp, hit1])
	check.call("★ ยืนขวางทางคลื่น = โดน ★", hit1 > 0)
	# รอระลอก 2 ผ่าน — โดนซ้ำได้ไม่เกิน Max Hits ที่ตั้งไว้ในข้อมูลมอน
	# (ผู้ใช้ปรับ skill_wave_max_hits ได้เอง เทสต์เลยอ่านจากข้อมูลจริง ไม่ล็อกเลข)
	await get_tree().create_timer(dt.skill_wave_interval + 0.6).timeout
	var hit_total: int = hp0 - PlayerState.stats.hp
	# (HP ฟื้นเองระหว่างรอ → รวมอาจน้อยกว่า hit1 ได้ · ถ้าโดนเกินโควตาจะมากกว่าชัด ๆ)
	var cap: int = hit1 * maxi(1, dt.skill_wave_max_hits) + 2
	check.call("★ โดนไม่เกิน Max Hits (%d) ต่อการร่าย ★" % dt.skill_wave_max_hits,
		hit_total <= cap, "%d vs %d" % [hit_total, cap])
	var expect: int = int(round(Combat.monster_hits_player(dt, PlayerState.stats).damage * dt.skill_damage_mult))
	check.call("ดาเมจ ≈ ตีปกติ × 2 (คลาด 40%%)", hit1 >= expect * 0.6 and hit1 <= expect * 1.4, "%d vs %d" % [hit1, expect])
	await get_tree().create_timer(2.5).timeout

	# กระโดดข้าม: ยกเท้าผู้เล่นสูงกว่าคลื่น
	PlayerState.revive(1.0)
	PlayerState.stats.hp = PlayerState.stats.max_hp
	var hp1: int = PlayerState.stats.hp
	p.global_position = Vector2(boss.global_position.x + face * 380, ground_y - (dt.skill_wave_hit_height + 30.0))
	p.velocity = Vector2.ZERO
	await get_tree().process_frame
	boss._skill_cd = 0.0
	boss.state = 0
	boss._cast_skill()
	await get_tree().create_timer(dt.skill_wave_delay + reach + 0.3).timeout
	print("  ลอยเหนือคลื่น: HP %d → %d" % [hp1, PlayerState.stats.hp])
	check.call("★ เท้าอยู่สูงกว่าคลื่น (กระโดดข้าม) = ไม่โดน ★", PlayerState.stats.hp == hp1 and not PlayerState.is_dead())
	await get_tree().create_timer(2.5).timeout

	# ยืน "ข้างหลัง" บอส — Both Sides ต้องโดนด้วย
	PlayerState.revive(1.0)
	PlayerState.stats.hp = PlayerState.stats.max_hp
	var hp2: int = PlayerState.stats.hp
	p.global_position = Vector2(boss.global_position.x - face * 380, ground_y)
	p.velocity = Vector2.ZERO
	await get_tree().process_frame
	boss._skill_cd = 0.0
	boss.state = 0
	boss._face_to(float(face))       # ยังหันทางเดิม (ผู้เล่นอยู่ข้างหลัง)
	boss._cast_skill()
	await get_tree().create_timer(dt.skill_wave_delay + reach + 0.3).timeout
	print("  ยืนข้างหลังบอส: HP %d → %d" % [hp2, PlayerState.stats.hp])
	check.call("★ ยืนข้างหลังบอสก็โดน (Both Sides) ★", PlayerState.stats.hp < hp2)
	await get_tree().create_timer(2.5).timeout

	# ยืนไกลเกินระยะ = ไม่โดน
	PlayerState.revive(1.0)
	PlayerState.stats.hp = PlayerState.stats.max_hp
	var hp3: int = PlayerState.stats.hp
	p.global_position = Vector2(boss.global_position.x + face * (dt.skill_wave_range + 200.0), ground_y)
	p.velocity = Vector2.ZERO
	await get_tree().process_frame
	boss._skill_cd = 0.0
	boss.state = 0
	boss._cast_skill()
	await get_tree().create_timer(dt.skill_wave_delay + dt.skill_wave_range / dt.skill_wave_speed + 0.8).timeout
	check.call("★ ยืนไกลเกินระยะคลื่น = ไม่โดน ★", PlayerState.stats.hp == hp3)
	p.set_physics_process(true)

	# =========================================================
	# 4) อสูรสายฟ้ายังใช้สายฟ้าเหมือนเดิม (ไม่ปนกัน)
	# =========================================================
	print("\n-- 4) ไม่กระทบสกิลเดิม --")
	var storm: MonsterData = load("res://data/monsters/stormscar.tres")
	check.call("อสูรสายฟ้าไม่มีคลื่น", storm.skill_wave_count == 0)
	check.call("อสูรสายฟ้ายังมีสายฟ้า", storm.skill_bolt_count > 0)

	print("\n=== ผ่าน %d · ล้มเหลว %d ===" % score)
	get_tree().quit()
