extends Node
## รอบ 182 — ตราทอง (B) + หลบพอดี (C)
const Tower = preload("res://scripts/world/chapter8_tower_data.gd")
var checks := 0
var fails := 0
var world: Node2D
var player
var killed_events := 0
func check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		fails += 1
		print("FAIL: ", msg)

func snap(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)

func spawn(id: StringName, x: float, marks: Array, champion := true):
	var m = load("res://scenes/monsters/monster.tscn").instantiate()
	m.data = GameData.get_monster(id)
	if champion:
		m.set_meta(&"champion", true)
		m.set_meta(&"gold_marks", marks)
	m.position = Vector2(x, 860)
	world.add_child(m)
	m.set_physics_process(false)
	return m

func _ready() -> void:
	await get_tree().process_frame
	PlayerState.new_game()
	PlayerState.stats.level = 80
	PlayerState.stats.base_str = 90
	PlayerState.stats.base_dex = 90
	PlayerState.refresh()
	Events.monster_killed.connect(func(_id, _lv): killed_events += 1)
	var bg := ColorRect.new(); bg.color = Color(0.3, 0.38, 0.45); bg.size = Vector2(5000, 2000); bg.position = Vector2(-500, -600); add_child(bg)
	world = Node2D.new(); add_child(world)
	var body := StaticBody2D.new(); var cs := CollisionShape2D.new(); var rs := RectangleShape2D.new(); rs.size = Vector2(8000, 40); cs.shape = rs; body.add_child(cs); body.position = Vector2(1000, 900); world.add_child(body)
	player = load("res://scenes/player/player.tscn").instantiate()
	player.position = Vector2(700, 820)
	world.add_child(player)
	var cam := Camera2D.new(); cam.position = Vector2(1000, 640); add_child(cam); cam.make_current()
	for i in 10: await get_tree().physics_frame
	player.set_physics_process(false)

	# ── สุ่มตรา ──
	var many := {}
	for i in 200:
		var r: Array = preload("res://scripts/entities/monster_base.gd").roll_gold_marks(40)
		check(r.size() == 1, "low level 1 mark")
		var r2: Array = preload("res://scripts/entities/monster_base.gd").roll_gold_marks(90, [&"split"])
		check(r2.size() >= 1 and r2.size() <= 2 and not r2.has(&"split"), "high level 1-2 excl split")
		for m in r2: many[m] = true
	check(many.size() == 5, "all non-split marks appear")

	# ── โล่ทอง ──
	var wolf = spawn(&"wolf", 1000, [&"gold_shield"])
	check(wolf.is_champion and wolf.gold_shield_up and wolf.get_node_or_null("GoldMarkFX") != null, "shield champion + fx")
	check(wolf.get_node("ChampionTag").text.contains("โล่ทอง"), "tag shows mark")
	var base_dmg: int = wolf._gold_mark_damage(1000, &"basic", false)
	check(base_dmg == 400, "shield cuts basic 60%% (%d)" % base_dmg)
	var sk: int = wolf._gold_mark_damage(1000, &"bash", false)
	check(sk == 1000 and not wolf.gold_shield_up, "skill breaks shield")
	wolf._tick_gold_marks(8.1)
	check(wolf.gold_shield_up, "shield returns after 8s")
	# ── เร่งรีบ ──
	var fast = spawn(&"wolf", 1300, [&"haste"])
	var plain: MonsterData = GameData.get_monster(&"wolf")
	check(is_equal_approx(fast.data.move_speed, plain.move_speed * 1.35), "haste speed")
	check(fast.data.attack_cooldown < plain.attack_cooldown, "haste attack cd")
	# ── ผู้พิทักษ์ ──
	var warden = spawn(&"orc_warrior", 1500, [&"warden"])
	var buddy = spawn(&"wolf", 1650, [], false)
	check(buddy._gold_mark_damage(1000, &"basic", false) == 700, "warden protects neighbour 30%")
	check(warden._gold_mark_damage(1000, &"basic", false) == 1000, "warden not self protected")
	var far = spawn(&"wolf", 2400, [], false)
	check(far._gold_mark_damage(1000, &"basic", false) == 1000, "far monster unprotected")
	await snap("/tmp/r182_marks.png")
	# ── สะท้อน ──
	var mirror = spawn(&"wolf", 900, [&"reflect"])
	var hp0 := PlayerState.stats.hp
	mirror._gold_mark_damage(1000000, &"basic", true)
	var lost := hp0 - PlayerState.stats.hp
	check(lost > 0 and lost <= int(PlayerState.stats.max_hp * 0.05) + 1, "reflect capped 5%% (lost %d)" % lost)
	var hp1 := PlayerState.stats.hp
	mirror._gold_mark_damage(1000000, &"basic", true)
	check(PlayerState.stats.hp == hp1, "reflect 0.5s cooldown")
	PlayerState.heal_hp(99999)
	# ── ฟื้นฟู ──
	var regen = spawn(&"orc_warrior", 1200, [&"regen"])
	regen.hp = regen.data.max_hp / 2
	regen._tick_gold_marks(1.0)
	check(regen.hp == regen.data.max_hp / 2, "no regen before 3s")
	for i in 60: regen._tick_gold_marks(0.05)
	check(regen.hp > regen.data.max_hp / 2, "regen after idle (%d/%d)" % [regen.hp, regen.data.max_hp])
	regen._gold_mark_damage(10, &"basic", false)
	check(not regen.gold_regenerating(), "hit resets regen")
	# ── แตกร่าง ──
	var splitter = spawn(&"wolf", 1100, [&"split"])
	var before := world.get_child_count()
	killed_events = 0
	splitter.take_damage(splitter.hp + 5, false, 1)
	await get_tree().process_frame
	await get_tree().process_frame
	var kids := []
	for c in world.get_children():
		if c.has_meta(&"split_child"): kids.append(c)
	check(kids.size() == 2, "split into 2 (%d)" % kids.size())
	check(killed_events == 1, "parent counted once")
	if kids.size() == 2:
		check(kids[0].data.max_hp == int(splitter.data.max_hp * 0.2) and kids[0].data.exp_reward == 0 and kids[0].data.drops.is_empty(), "child weak no reward")
		check(splitter.data.drops.size() > 0 or GameData.get_monster(&"wolf").drops.size() == 0, "parent drops untouched")
		for k in kids: k.take_damage(k.hp + 5, false, 1)
		await get_tree().process_frame
		check(killed_events == 1, "children give no kill credit")
	check(GameData.get_monster(&"wolf").drops.size() > 0, "campaign wolf drops unchanged")
	# ── ดาเมจจริงผ่าน take_damage_from_player ──
	var real = spawn(&"wolf", 1000, [&"gold_shield"])
	PlayerState.gm_one_hit = false
	player._rb_attack_tag = &"basic"
	var h0: int = real.hp
	for i in 5: real.take_damage_from_player(1.0, false, 1)
	check(real.hp < h0 and real.gold_shield_up, "basic hits keep shield")
	player._rb_attack_tag = &"bash"
	real.take_damage_from_player(1.0, false, 1)
	check(not real.gold_shield_up, "skill tag breaks shield in real path")

	# ── หลบพอดี ──
	player.set_physics_process(true)
	PlayerState.heal_hp(99999)
	PlayerState.stats.job_id = &"swordsman"
	PlayerState.stats.sp = 0
	player._start_dodge()
	var hpd := PlayerState.stats.hp
	player.take_damage(500, 100.0, 1)
	check(player.perfect_dodge_count == 1 and PlayerState.stats.hp == hpd, "perfect dodge no damage")
	check(PlayerState.stats.sp > 0, "swordsman gets SP")
	check(Engine.time_scale < 1.0, "slow motion")
	await get_tree().process_frame
	await snap("/tmp/r182_dodge.png")
	player.take_damage(500, 100.0, 1)
	check(player.perfect_dodge_count == 1, "once per dodge")
	await get_tree().create_timer(1.2, true, false, true).timeout
	check(Engine.time_scale == 1.0, "time scale restored")
	# late dodge (> 0.2s) → ordinary หลบ
	player._dodge_cd = 0.0
	player._start_dodge()
	player._iframe = player.dodge_invincible - 0.23
	player.take_damage(500, 100.0, 1)
	check(player.perfect_dodge_count == 1 and PlayerState.stats.hp == hpd, "late dodge = normal invincible")
	# runeblade rune
	await get_tree().create_timer(1.5).timeout
	print("dbg can_dodge ", player.can_dodge(), " dcd ", player._dodge_cd, " dt ", player._dodge_time)
	PlayerState.stats.job_id = &"ninth_edge"
	player.runeblade.charges = 0
	player._dodge_cd = 0.0
	player._start_dodge()
	player.dodge_contact()
	check(player.perfect_dodge_count == 2 and player.runeblade.charges == 1, "rune +1 via dodge_contact")
	await get_tree().create_timer(1.0, true, false, true).timeout
	# no dodge → take damage normally
	await get_tree().create_timer(0.5).timeout
	player._iframe = 0.0
	var hpx := PlayerState.stats.hp
	print("dbg hp ", hpx, " inv ", player.is_invincible(), " shield ", player.runeblade.shield)
	player.take_damage(50, 0.0, 1)
	check(PlayerState.stats.hp < hpx and player.perfect_dodge_count == 2, "no dodge = hit")

	# ── หอชั้น 60: แชมเปี้ยนเวฟละ ≤1 ไม่มีแตกร่าง ──
	PlayerState.set_flag(&"chapter7_done")
	for n in range(1, 60): PlayerState.set_flag(Tower.clear_flag(n))
	Tower.gm_test = true
	var champs := 0
	for rep in 3:
		var map = load(Game.MAPS[Tower.floor_id(60)]).instantiate()
		add_child(map)
		await get_tree().process_frame
		map.player.set_physics_process(false)
		for wave in range(Tower.wave_sizes(60).size()):
			for child in map.get_children():
				if child is Timer and child != map.transition_timer:
					child.stop(); child.timeout.emit()
			await get_tree().process_frame
			var wc := 0
			for a in map.enemy_container.get_children():
				if a.is_dead(): continue
				if a.is_champion:
					wc += 1
					check(not a.gold_marks.has(&"split") and a.gold_marks.size() >= 1, "tower champion marks")
				a.set_physics_process(false)
				a.take_damage(a.hp + 1)
			check(wc <= 1, "≤1 champion per wave")
			champs += wc
			map._advance_encounter()
			await get_tree().process_frame
		map.queue_free()
		await get_tree().process_frame
	print("tower champions seen: ", champs)
	check(champs >= 1, "tower champions appear")
	Tower.gm_test = false
	print("R182 %d checks · fails %d" % [checks, fails])
	print("R182 DONE")
	get_tree().quit()
