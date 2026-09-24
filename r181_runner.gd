extends Node2D
## รอบ 181 — Ninth Edge ชุดสกิลใหม่ + เอาเงื่อนไขรูนออก
const MONSTER = preload("res://scenes/monsters/monster.tscn")
const OUT := "res://output/r181/"
var fails := 0
var passes := 0
var map
var player
var rb
var hits: Array = []   # [target, source]

func ok(c: bool, m: String) -> void:
	if c: passes += 1; print("  PASS ", m)
	else: fails += 1; print("  FAIL ", m)

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))

func spawn(x: float, hp: int = 5000000) -> Node:
	var m = MONSTER.instantiate()
	var d: MonsterData = (load("res://data/monsters/poring.tres") as MonsterData).duplicate()
	d.max_hp = hp
	d.flee = -1000
	d.def = 0
	m.data = d
	map.add_child(m)
	m.hp = hp
	m.set_physics_process(false)
	m.position = Vector2(x, 900.0)
	m.position.y += 900.0 - m.foot_position().y
	return m

func clear_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemy"): e.queue_free()
	await get_tree().process_frame

func count(target: Node, source: StringName) -> int:
	var n := 0
	for h in hits:
		if h[0] == target and h[1] == source: n += 1
	return n

func ready_cast(id: StringName) -> void:
	PlayerState.stats.sp = 9999
	PlayerState.cooldowns.clear()
	while rb.casting or player.is_attacking:
		await get_tree().physics_frame

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	get_window().size = Vector2i(1280, 720)
	PlayerState.new_game()
	PlayerState.stats.job_id = &"ninth_edge"
	PlayerState.stats.level = 120
	PlayerState.gm_god_mode = true
	for id in [&"ninth_vessel", &"named_edge", &"erasing_step", &"oathchain", &"ninefold_cyclone", &"erasing_cut", &"twin_inscription", &"ninth_inscription", &"worldcleaver", &"unbroken_edge", &"blade_rhythm"]:
		PlayerState.skills.learned[id] = 5
	PlayerState.refresh()
	map = load("res://scenes/maps/runeblade_training.tscn").instantiate()
	add_child(map)
	await get_tree().physics_frame
	await get_tree().physics_frame
	player = map.player
	rb = player.runeblade
	for e in get_tree().get_nodes_in_group("enemy"): e.queue_free()
	for n in get_tree().get_nodes_in_group("npc"): n.visible = false
	Events.runic_hit.connect(func(t, s, _c): hits.append([t, s]))
	ok(rb.ninth != null, "มีโหนดชุดสกิล Ninth")
	var job := GameData.get_job(&"ninth_edge")
	ok(&"erasing_step" in job.skill_ids and &"oathchain" in job.skill_ids and &"ninefold_cyclone" in job.skill_ids and not &"wallbreaker_stance" in job.skill_ids, "รายการสกิลอาชีพ: +3 ใหม่ · อ่านรอยพันธะออก")
	ok(GameData.get_skill(&"twin_inscription").display_name == "ร่างเงาสะท้อน" and GameData.get_skill(&"ninth_inscription").display_name == "พิพากษานามที่เก้า", "ชื่อสกิลใหม่")
	ok(is_equal_approx(float(PlayerState.skills.passive_bonus().get(&"aspd_percent", 0.0)), 12.5), "จังหวะคมดาบ = พาสซีฟ ASPD 2.5%%/lv (%s)" % PlayerState.skills.passive_bonus().get(&"aspd_percent", 0.0))

	# ---- 1) ไม่ต้องมีรูน: ผ่าโลกากดได้เลย ----
	player.position.x = 600
	var v := spawn(900)
	rb.charges = 0
	await ready_cast(&"worldcleaver")
	rb.cast(&"worldcleaver")
	await get_tree().create_timer(0.6).timeout
	ok(PlayerState.skill_cooldown_left(&"worldcleaver") > 0.0, "ผ่าโลกาใช้ได้โดยไม่มีรูน")
	await get_tree().create_timer(1.6).timeout
	ok(count(v, &"worldcleaver") > 0, "ผ่าโลกาไม่มีรูนยังทำดาเมจ")
	rb.charges = 3
	ok(is_equal_approx(rb.spend_runes(&"erasing_cut"), 1.3) and rb.charges == 0, "รูน 3 ดวง = +30% แล้วหมด")
	rb.charges = 2
	ok(is_equal_approx(rb.spend_runes(&"oathchain"), 1.0) and rb.charges == 2, "ท่าเล็กไม่กินรูน")
	rb.charges = 0
	await clear_enemies()

	# ---- 2) ก้าวลบเงา ----
	player.position.x = 500
	player.facing = 1
	var a := spawn(700)
	var b := spawn(850)
	await ready_cast(&"erasing_step")
	var x0: float = player.position.x
	rb.cast(&"erasing_step")
	await get_tree().physics_frame
	ok(player._iframe > 0.0, "ก้าวลบเงา: อมตะตอนวาร์ป")
	await get_tree().create_timer(0.25).timeout
	await shot("1_step_scar")
	var moved: float = player.position.x - x0
	ok(moved > 380.0 and moved < 530.0, "วาร์ปไป ~450 (%.0f)" % moved)
	ok(count(a, &"erasing_step") >= 1 and count(b, &"erasing_step") >= 1, "ฟันผ่านโดนทั้งคู่")
	ok(rb.ninth.can_recast(&"erasing_step"), "กดซ้ำได้ภายใน 1.2 วิ")
	var before_scar := count(a, &"erasing_step")
	await get_tree().create_timer(0.4).timeout
	ok(count(a, &"erasing_step") > before_scar, "รอยแผลระเบิดตามหลัง")
	var sp_before: int = PlayerState.stats.sp
	player.facing = -1
	player._update_facing()
	rb.cast(&"erasing_step")
	await get_tree().create_timer(0.2).timeout
	ok(PlayerState.stats.sp == sp_before and player.position.x < x0 + moved - 300.0, "กดซ้ำฟรี วาร์ปกลับอีกทาง")
	ok(not rb.ninth.can_recast(&"erasing_step"), "กดซ้ำได้ครั้งเดียว")
	await get_tree().create_timer(0.6).timeout
	await clear_enemies()

	# ---- 3) โซ่พันธะ ----
	player.position.x = 400
	player.facing = 1
	player._update_facing()
	var c1 := spawn(950)
	var c2 := spawn(1150)
	var far := spawn(1700)
	await ready_cast(&"oathchain")
	rb.cast(&"oathchain")
	await get_tree().create_timer(0.2).timeout
	await shot("2_chain")
	await get_tree().create_timer(0.3).timeout
	ok(c1.position.x < 700.0 and c2.position.x < 750.0, "ดึงฝูงมากองหน้า (%.0f, %.0f)" % [c1.position.x, c2.position.x])
	ok(far.position.x > 1600.0, "ตัวไกลเกินรัศมีไม่โดนดึง")
	ok(count(c1, &"oathchain") + count(c2, &"oathchain") >= 1 and count(c1, &"oathchain") <= 1 and count(c2, &"oathchain") <= 1, "ดึงแล้วฟันกลุ่ม ตัวละครั้งเดียว (%d, %d · MISS ได้ตามกติกาความแม่น)" % [count(c1, &"oathchain"), count(c2, &"oathchain")])
	ok(Time.get_ticks_msec() < int(c1.get_meta("rb_stun_until", 0)), "ติดสตัน")
	await clear_enemies()
	# บอส → ตัวเราถูกดึง
	player.position.x = 400
	var boss := spawn(1100)
	boss.data.is_boss = true
	await ready_cast(&"oathchain")
	rb.cast(&"oathchain")
	await get_tree().create_timer(0.8).timeout
	ok(boss.position.x > 1050.0 and player.position.x > 700.0, "บอสดึงไม่ไหว — ผู้เล่นพุ่งเข้าไปแทน (ผู้เล่น %.0f)" % player.position.x)
	await clear_enemies()

	# ---- 4) กงจักรนามเก้า ----
	player.position.x = 700
	player.facing = 1
	var s1 := spawn(820)
	var s2 := spawn(1080)
	await ready_cast(&"ninefold_cyclone")
	var cx: float = player.position.x
	rb.cast(&"ninefold_cyclone")
	Input.action_press("move_right")
	await get_tree().create_timer(1.2).timeout
	await shot("3_cyclone")
	Input.action_release("move_right")
	ok(player.position.x > cx + 150.0, "เดินได้ระหว่างหมุน (%.0f px)" % (player.position.x - cx))
	await get_tree().create_timer(1.6).timeout
	ok(count(s1, &"ninefold_cyclone") >= 9, "ฟันครบ 9 + ปิดท้าย (%d)" % count(s1, &"ninefold_cyclone"))
	ok(s2.position.x < 1080.0, "ดูดมอนเข้ามา")
	ok(not player.is_attacking and not rb.casting, "จบท่าแล้วคุมตัวได้")
	# ยกเลิกด้วยหลบ
	await ready_cast(&"ninefold_cyclone")
	rb.cast(&"ninefold_cyclone")
	await get_tree().create_timer(0.5).timeout
	Input.action_press("jump")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("jump")
	ok(rb.ninth.cyclone_left <= 0.0 and not rb.casting, "กดหลบยกเลิกกงจักรได้")
	await get_tree().create_timer(0.6).timeout
	await clear_enemies()

	# ---- 5) คมตัดพันธะ: พุ่งเข้า + ฆ่าได้คืนรูน ----
	player.position.x = 400
	player.facing = 1
	player._update_facing()
	var weak := spawn(900, 1)
	await ready_cast(&"erasing_cut")
	rb.charges = 0
	var ex: float = player.position.x
	rb.cast(&"erasing_cut")
	await get_tree().create_timer(0.35).timeout
	await shot("4_cut")
	await get_tree().create_timer(0.3).timeout
	ok(player.position.x > ex + 150.0, "พุ่งเข้าก่อนฟัน (%.0f)" % (player.position.x - ex))
	ok(weak.is_dead() and rb.charges == 1, "ฆ่าได้คืนรูน 1 (รูน %d)" % rb.charges)
	await clear_enemies()

	# ---- 6) ร่างเงาสะท้อน ----
	player.position.x = 500
	player.facing = 1
	var mid := spawn(900)
	await ready_cast(&"twin_inscription")
	rb.cast(&"twin_inscription")
	await get_tree().physics_frame
	ok(is_instance_valid(rb.ninth.shade) and rb.ninth.shade_time > 9.0, "วางร่างเงา 10 วิ")
	player.position.x = 1200
	player.facing = -1
	player._update_facing()
	await get_tree().physics_frame
	await ready_cast(&"erasing_cut")
	rb.cast(&"erasing_cut")
	await get_tree().create_timer(0.3).timeout
	await shot("5_shade")
	await get_tree().create_timer(0.4).timeout
	ok(count(mid, &"mirror_echo") >= 1, "ร่างเงาฟันตามจากอีกฝั่ง")
	ok("ร่างเงา" in rb.hud.text and not "จังหวะ" in rb.hud.text, "HUD: %s" % rb.hud.text)
	rb.ninth._clear_shade()
	await clear_enemies()

	# ---- 7) พิพากษานามที่เก้า ----
	player.position.x = 900
	player.facing = 1
	var t1 := spawn(500)
	var t2 := spawn(1200)
	var t3 := spawn(1500)
	await ready_cast(&"ninth_inscription")
	rb.charges = 2
	rb.cast(&"ninth_inscription")
	await get_tree().physics_frame
	ok(player._iframe > 1.0 and rb.charges == 0, "อัลติ: อมตะตลอดท่า + ใช้รูนเป็นโบนัส")
	await get_tree().create_timer(0.8).timeout
	await shot("6_verdict")
	await get_tree().create_timer(1.2).timeout
	var total := count(t1, &"ninth_inscription") + count(t2, &"ninth_inscription") + count(t3, &"ninth_inscription")
	ok(total >= 11, "วาร์ปฟัน 9 + ระเบิด (%d)" % total)
	ok(count(t1, &"ninth_inscription") >= 2 and count(t3, &"ninth_inscription") >= 2, "ไล่ทั้งซ้ายและขวา")
	ok(not player.is_attacking and not rb.casting, "จบอัลติแล้วคุมตัวได้")
	await clear_enemies()

	# ---- 8) ย้ายแต้มอ่านรอยพันธะ ----
	PlayerState.skills.learned[&"wallbreaker_stance"] = 3
	var pts: int = PlayerState.stats.skill_points
	rb._migrate_r181()
	ok(PlayerState.skills.level_of(&"wallbreaker_stance") == 0 and PlayerState.stats.skill_points == pts + 3, "คืนแต้มอ่านรอยพันธะ 3 แต้ม")
	# ---- 9) รูนไม่หายเอง ----
	rb.charges = 3
	rb.idle = 30.0
	await get_tree().create_timer(3.5).timeout
	ok(rb.charges == 3, "รูนไม่ลดเองเมื่อหยุดตี")
	print("R181: %d passed, %d failed" % [passes, fails])
	get_tree().quit(1 if fails else 0)
