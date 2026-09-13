extends Node2D

var player: Node2D
var charges := 0
var charge_lock := 0.0
var idle := 0.0
var decay := 0.0
var rhythm := 0
var rhythm_idle := 0.0
var rhythm_decay := 0.0
var shield := 0
var shield_time := 0.0
var edge_time := 0.0
var echo_count := 0
var last_basic := -1
var cast_serial := 0
var charged_cast := -1
var committed_heavy := false
var casting := false
var approach_left := 0.0
var approach_dir := 1
var lunge_followup := 0.0
var hud: Label
# ★ รอบ 105 ★ Ninth Edge
var twin_time := 0.0          ## อักขระคู่ — เงาดาบตามทุกโจมตี
var inscription_time := 0.0   ## อักขระที่เก้า — วงสลักชื่อ
var inscription_center := Vector2.ZERO
var inscription_lv := 0
var inscription_ring: Line2D
const INSCRIPTION_RADIUS := 500.0

## รูนสะสมสูงสุด 3 · Ninth Vessel ระดับ 5 = 4
func max_charges() -> int:
	return 3 + (1 if PlayerState.skills.level_of(&"ninth_vessel") >= 5 else 0)

## จุดนี้อยู่ในวงอักขระที่เก้าไหม (monster_base ใช้: คริ 100% + มองข้าม DEF)
func inscription_covers(at: Vector2) -> bool:
	return inscription_time > 0 and at.distance_to(inscription_center) <= INSCRIPTION_RADIUS + 60

func _ready() -> void:
	player = get_parent()
	Events.runic_hit.connect(_hit)
	Events.skill_used.connect(_used)
	var layer := CanvasLayer.new()
	layer.layer = 12
	add_child(layer)
	hud = UITheme.make_label("",18,Color("#ffd979"))
	hud.position = Vector2(18,180)
	layer.add_child(hud)

func _used(_id: StringName, _lv: int) -> void:
	cast_serial += 1

func _hit(target: Node, source: StringName, _critical: bool) -> void:
	if not PlayerState.is_rune_job() or source in [&"rune_echo", &"twin_echo", &"element_burn", &"element_chain"]: return
	idle = 0
	if source == &"rune_lunge": lunge_followup = 3.0
	# ★ รอบ 105 ★ อักขระคู่ — เงาดาบตามทุกการโจมตี 50→70% ไม่คริ
	if twin_time > 0 and is_instance_valid(target) and target.has_method("is_dead") and not target.is_dead():
		var tl := PlayerState.skills.level_of(&"twin_inscription")
		target.take_damage_from_player(0.45 + 0.05 * tl, false, player.facing, 0, 0, &"twin_echo")
	if source in [&"basic",&"basic_finisher"]:
		if last_basic == player._attack_seq: return
		last_basic = player._attack_seq
		rhythm_idle = 0
		if PlayerState.skills.level_of(&"blade_rhythm") > 0:
			rhythm = mini(5,rhythm+1)
			_rhythm_buff()
		if source == &"basic_finisher": _gain()
		if edge_time > 0:
			echo_count += 1
			if echo_count%3 == 0 and is_instance_valid(target) and not target.is_dead():
				target.take_damage_from_player(0.8,false,player.facing,0,0,&"rune_echo")
	elif source not in [&"worldcleaver",&"unbroken_edge", &"faultline"] and charged_cast != cast_serial:
		charged_cast = cast_serial
		_gain()

func _gain() -> void:
	if charge_lock > 0: return
	charges = mini(max_charges(),charges+1)
	charge_lock = 0.2

func _rhythm_buff() -> void:
	if rhythm > 0:
		PlayerState.active_buffs[&"rb_rhythm"] = {"time_left":30.0,"values":{"aspd_percent":rhythm*PlayerState.skills.level_of(&"blade_rhythm")*0.6},"level":1}
	else: PlayerState.active_buffs.erase(&"rb_rhythm")
	PlayerState.refresh()

func absorb(amount: int) -> int:
	if committed_heavy: amount = int(amount*0.8)
	var blocked := mini(shield,amount)
	shield -= blocked
	return amount-blocked

func _process(delta: float) -> void:
	hud.visible = PlayerState.is_rune_job() and not player._dead
	hud.position = Vector2(18,get_viewport_rect().size.y-110)
	if not hud.visible:
		charges = 0
		return
	if PlayerState.stats.level>=90 and not PlayerState.has_flag(&"rb_next_job_ready"):
		PlayerState.set_flag(&"rb_next_job_ready")
		Events.say("อักขระที่เก้าตอบรับเจ้าแล้ว... กลับไปอ่านศิลาคำสัตย์ที่วานาเฮม เส้นทางขั้นถัดไปยังรอเรื่องราวจากแดนเหนือ")
	if PlayerState.skills.level_of(&"blade_rhythm")==0 and rhythm>0:
		rhythm = 0
		_rhythm_buff()
	if PlayerState.skills.level_of(&"rune_guard")==0: shield = 0
	if PlayerState.skills.level_of(&"unbroken_edge")==0 and edge_time>0:
		edge_time = 0
		PlayerState.active_buffs.erase(&"unbroken_edge")
		PlayerState.refresh()
	charge_lock = maxf(0,charge_lock-delta)
	lunge_followup = maxf(0.0, lunge_followup - delta)
	idle += delta
	rhythm_idle += delta
	shield_time -= delta
	edge_time -= delta
	if shield_time <= 0: shield = 0
	# ★ รอบ 105 ★ นับถอยหลังอักขระคู่ / อักขระที่เก้า
	if twin_time > 0:
		twin_time -= delta
		if twin_time <= 0:
			PlayerState.active_buffs.erase(&"twin_inscription")
			PlayerState.refresh()
	if inscription_time > 0:
		inscription_time -= delta
		if inscription_time <= 0:
			_inscription_burst()
	if idle > 10:
		decay += delta
		if decay >= 3:
			charges = maxi(0,charges-1)
			decay = 0
	else: decay = 0
	if rhythm_idle > 3 and rhythm > 0:
		rhythm_decay += delta
		if rhythm_decay >= 1:
			rhythm -= 1
			rhythm_decay = 0
			_rhythm_buff()
	else: rhythm_decay = 0
	hud.text = "รูน  %s%s   จังหวะ %d/5%s%s" % ["◆".repeat(charges),"◇".repeat(max_charges()-charges),rhythm,"   โล่ %d"%shield if shield>0 else "",
		("   อักขระคู่ %.1f" % twin_time if twin_time > 0 else "") + ("   ★ อักขระที่เก้า %.1f" % inscription_time if inscription_time > 0 else "")]
	if lunge_followup > 0.0: hud.text += "   หกคม +20%%  %.1f" % lunge_followup

func cast(id: StringName) -> void:
	if casting or not PlayerState.is_rune_job(): return
	var check := PlayerState.can_use_skill(id)
	if not check.ok:
		Events.say(check.reason)
		return
	# ★ รอบ 105 ★ ค่ารูนของแต่ละสกิล: อัลติเมต 3 · อักขระคู่ 2 · ฟันลบนาม 3 · อักขระที่เก้า 4
	var rune_cost: int = {&"unbroken_edge": 3, &"worldcleaver": 3, &"twin_inscription": 2, &"erasing_cut": 3, &"ninth_inscription": 4}.get(id, 0)
	var ultimate := rune_cost > 0
	if ultimate and charges < rune_cost:
		Events.say("ต้องมีตรารูนครบ %d ดวง" % rune_cost)
		return
	var s := GameData.get_skill(id)
	var lv := PlayerState.skills.level_of(id)
	var flurry_bonus := 1.2 if id == &"rune_flurry" and lunge_followup > 0.0 else 1.0
	if id != &"worldcleaver" and not PlayerState.commit_skill_use(id): return
	if id == &"rune_flurry": lunge_followup = 0.0
	if id == &"rune_guard":
		shield = int(PlayerState.stats.max_hp*(0.02+lv*0.02))
		shield_time = 3
		_flash(player.foot_position()-Vector2(0,110),130,Color("#83dce8"))
		return
	if id == &"unbroken_edge":
		charges = 0
		edge_time = 8
		echo_count = 0
		PlayerState.active_buffs[id] = {"time_left":8.0,"values":{"aspd_percent":5.0*lv},"level":lv}
		PlayerState.refresh()
		return
	# ★ รอบ 105 ★ อักขระคู่ — 6 วิ ทุกโจมตีมีเงาดาบตาม (ใช้ 2 รูน)
	if id == &"twin_inscription":
		charges -= 2
		twin_time = 6.0
		PlayerState.active_buffs[id] = {"time_left":6.0,"values":{},"level":lv}
		PlayerState.refresh()
		_flash(player.foot_position()-Vector2(0,110),150,Color("#b8a6ff"))
		return
	# ★ รอบ 105 ★ อักขระที่เก้า — สลักชื่อลงพื้นเป็นวง 3 วิ: ทุกโจมตีในวงคริ 100% + มองข้าม DEF · จบแล้วระเบิด 2000% (ใช้ 4 รูน)
	if id == &"ninth_inscription":
		charges -= 4
		inscription_time = 3.0
		inscription_lv = lv
		inscription_center = player.foot_position()
		PlayerState.active_buffs[id] = {"time_left":3.0,"values":{"crit":100.0},"level":lv}
		PlayerState.refresh()
		_draw_inscription()
		Events.floating_text(inscription_center + Vector2(0,-190), "★ อักขระที่เก้า — %s ★" % PlayerState.stats.job().display_name, Color("#ffd86b"), 26, 0)
		return
	casting = true
	player.is_attacking = true
	player._attack_seq += 1
	var seq: int = player._attack_seq
	var dir: int = player.facing
	player._rb_attack_tag = id
	player.velocity.x = 0
	player.reset_combo()
	var anim: String = player._play(player.skill_animation(id),true)
	var windup := 0.28 if id == &"anvil_cleave" else (0.25 if id == &"faultline" else (0.7 if id == &"worldcleaver" else (0.3 if id == &"erasing_cut" else 0.05)))
	var flurry_interval := clampf(0.09 / sqrt(maxf(1.0, PlayerState.stats.aspd)), 0.04, 0.09)
	var span := windup + (0.26 + flurry_interval * 6 if id == &"rune_flurry" else 0.25)
	player.sprite.speed_scale = maxf(0.1,player._anim_length(anim)/span)
	player.attack_cooldown = span
	if id == &"worldcleaver":
		var elapsed := 0.0
		while elapsed < 0.35:
			await get_tree().physics_frame
			elapsed += get_physics_process_delta_time()
			if player._dead: _finish(seq); return
			if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept") or (InputMap.has_action("move_up") and Input.is_action_just_pressed("move_up")):
				PlayerState.cooldowns[id] = 2.0
				_finish(seq)
				player._start_dodge()
				return
		if not PlayerState.commit_skill_use(id): _finish(seq); return
		charges = 0
		committed_heavy = true
		await get_tree().create_timer(0.35).timeout
	else:
		await get_tree().create_timer(windup).timeout
	if player._dead or seq != player._attack_seq: _finish(seq); return
	if id == &"rune_lunge":
		var fx := preload("res://scripts/entities/rune_dash_fx.gd").new()
		fx.caster = player
		fx.facing = dir
		add_child(fx)
		player._start_dash(s, lv)
		player._play_skill_sfx(id)
		while player._dash_time > 0.0:
			await get_tree().physics_frame
			if player._dead or seq != player._attack_seq: _finish(seq); return
		await get_tree().create_timer(0.08).timeout
		_finish(seq)
		return
	if id == &"rune_flurry":
		approach_left = 480.0
		approach_dir = dir
		preload("res://scripts/entities/slash_flurry_fx.gd").spawn(player, player.sprite, dir)
		while approach_left > 0.0:
			await get_tree().physics_frame
			if player._dead or seq != player._attack_seq: _finish(seq); return
	if id in [&"faultline", &"worldcleaver"]:
		var center := field_center(s.field_offset, dir)
		var field := preload("res://scripts/entities/runic_blade_field.gd").new()
		field.configure(self, id, s.damage_mult(lv), center, dir)
		add_child(field)
		player._play_skill_sfx(id)
		await get_tree().create_timer(0.2).timeout
		_finish(seq)
		return
	if id == &"erasing_cut": charges -= 3   # ★ รอบ 105 ★ ฟันลบนาม ใช้ 3 รูน ฟันหนักครั้งเดียว ลบโล่/บัฟของมอน
	var reach := s.range_x
	var cap := s.max_targets_at(lv)
	var hits := 6 if id == &"rune_flurry" else 1
	for i in range(hits):
		if player._dead or seq != player._attack_seq: break
		strike(id,s.damage_mult(lv)*flurry_bonus/hits,reach,cap,dir)
		_flash(player.foot_position()+Vector2(dir*reach*0.55,-100),reach*0.45,Color("#ffc766"))
		if hits > 1: await get_tree().create_timer(flurry_interval).timeout
	player._play_skill_sfx(id)
	await get_tree().create_timer(0.18 if hits == 1 else 0.05).timeout
	_finish(seq)

func strike(id: StringName, mult: float, reach: float, cap: int, dir: int) -> void:
	var origin: Vector2 = player.foot_position()
	var skill := GameData.get_skill(id)
	var height := skill.range_y
	var box := Rect2(Vector2(origin.x-90 if dir>0 else origin.x-reach,origin.y-height),Vector2(reach+90,height+30))
	var enemies := get_tree().get_nodes_in_group("enemy")
	enemies.sort_custom(func(a,b): return absf(a.global_position.x-origin.x)<absf(b.global_position.x-origin.x))
	var hit := 0
	for enemy in enemies:
		if not enemy.has_method("take_damage_from_player") or (enemy.has_method("is_dead") and enemy.is_dead()): continue
		if not box.intersects(player.enemy_rect(enemy)): continue
		var ray := PhysicsRayQueryParameters2D.create(origin-Vector2(0,80),Vector2(enemy.global_position.x,origin.y-80),1)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		enemy.take_damage_from_player(mult,false,dir,0.15 if id == &"anvil_cleave" else 0.0,4.0 if id == &"anvil_cleave" else 0.0,id)
		hit += 1
		if hit >= cap: break

## Called by the player's physics loop so movement respects walls and collision.
func approach_step(delta: float) -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy.has_method("is_dead") or enemy.is_dead(): continue
		var area: Rect2 = player.enemy_rect(enemy)
		if player.attack_rect(160.0, 200.0, false).intersects(area):
			approach_left = 0.0
			player.velocity.x = 0.0
			return
	var distance := minf(approach_left, 1800.0 * delta)
	player.velocity = Vector2(approach_dir * distance / maxf(delta, 0.001), 0.0)
	player.move_and_slide()
	approach_left = maxf(0.0, approach_left - distance)
	if player.is_on_wall(): approach_left = 0.0
	if approach_left <= 0.0: player.velocity.x = 0.0

func field_center(distance: float, dir: int) -> Vector2:
	var origin: Vector2 = player.foot_position() - Vector2(0, 80)
	var end := origin + Vector2(dir * distance, 0)
	var ray := PhysicsRayQueryParameters2D.create(origin, end, 1)
	var collision := get_world_2d().direct_space_state.intersect_ray(ray)
	if not collision.is_empty(): end = collision.position - Vector2(dir * 24, 0)
	return end + Vector2(0, 80)

# =========================================================
# ★ รอบ 105 ★ อักขระที่เก้า — วงบนพื้น + ระเบิดตอนจบ
# =========================================================
func _draw_inscription() -> void:
	if is_instance_valid(inscription_ring): inscription_ring.queue_free()
	var line := Line2D.new()
	line.global_position = inscription_center
	line.width = 5
	line.default_color = Color("#ffd86b")
	line.z_index = 64
	for i in range(41):
		var a := TAU * i / 40.0
		line.add_point(Vector2(cos(a) * INSCRIPTION_RADIUS, sin(a) * 40))
	get_parent().get_parent().add_child(line)
	inscription_ring = line

func _inscription_burst() -> void:
	inscription_time = 0
	PlayerState.active_buffs.erase(&"ninth_inscription")
	PlayerState.refresh()
	if is_instance_valid(inscription_ring):
		var tween := inscription_ring.create_tween()
		tween.tween_property(inscription_ring, "modulate:a", 0.0, 0.4)
		tween.tween_callback(inscription_ring.queue_free)
	if not is_instance_valid(player) or player._dead: return
	var mult := 20.0 + 2.0 * (inscription_lv - 1)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy.has_method("take_damage_from_player") or (enemy.has_method("is_dead") and enemy.is_dead()): continue
		if enemy.global_position.distance_to(inscription_center) > INSCRIPTION_RADIUS + 60: continue
		var dir := 1 if enemy.global_position.x >= inscription_center.x else -1
		enemy.take_damage_from_player(mult, false, dir, 0, 0, &"ninth_inscription")
	_flash(inscription_center - Vector2(0, 100), INSCRIPTION_RADIUS, Color("#ffd86b"))

func _flash(at: Vector2, radius: float, color: Color) -> void:
	var line := Line2D.new()
	line.global_position = at
	line.width = 6
	line.default_color = color
	line.z_index = 65
	for i in range(25):
		var angle := lerpf(-PI*0.7,PI*0.7,i/24.0)
		line.add_point(Vector2(cos(angle)*radius*player.facing,sin(angle)*95))
	get_parent().get_parent().add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line,"modulate:a",0.0,0.3)
	tween.tween_callback(line.queue_free)

func _finish(seq: int) -> void:
	approach_left = 0.0
	casting = false
	committed_heavy = false
	if is_instance_valid(player) and seq == player._attack_seq:
		player.is_attacking = false
		player.sprite.speed_scale = 1
		player.attack_cooldown = 0.0

func _exit_tree() -> void:
	PlayerState.active_buffs.erase(&"rb_rhythm")
	PlayerState.active_buffs.erase(&"unbroken_edge")
	PlayerState.active_buffs.erase(&"twin_inscription")
	PlayerState.active_buffs.erase(&"ninth_inscription")
	if PlayerState.stats != null and PlayerState.skills != null: PlayerState.refresh()
