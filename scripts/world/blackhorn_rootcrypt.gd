extends "res://scripts/world/map_base.gd"

const Point = preload("res://scripts/world/runeblade_point.gd")
# ★ รอบ 126 ★ ยามเสาพันธนาการ 7-10 ตัวต่อเสา กระจายกว้าง ±SEAL_SPREAD (เดิม 2 ตัวยืนติดกัน)
const SEAL_GUARDS_MIN := 7
const SEAL_GUARDS_MAX := 10
const SEAL_SPREAD := 420.0
# ★ รอบ 126 ★ หลังปราบ Baphomet แล้ว ห้องบอสกลายเป็นที่ฟาร์ม: Baphomet เกิดใหม่ตลอด (คูลดาวน์บอสตามไฟล์มอน) + ลูกอสูร 5 ตัว
const FARM_ROOM := Rect2(4300, 300, 1900, 700)
const FARM_JR_COUNT := 5
## ★ รอบ 127 ★ ค่าพลังลูกอสูรในแมพนี้ (ทั้งยามเสาและห้องฟาร์ม) — เดิม ATK 130–175 เบาเกินสำหรับ Lv49
const JR_ATK_MIN := 380
const JR_ATK_MAX := 500
const JR_HIT := 95
var boss: Node2D
var fighting := false
var gate_notice_time := 0.0
var hazards: Array[Dictionary] = []
var guards: Dictionary = {}
var next_attack := 2.0
var next_adds := 10.0
var attack_number := 0
var clear_grace := 0.0
var had_adds := false
var seal_clock := 10.0
var slow_zones: Array[Dictionary] = []
var slowed := false
var seal_wait: Dictionary = {}

func _ready() -> void:
	# All dungeon state uses its own flags: old chapter-1 kills never complete this quest.
	_build_world()
	super._ready()
	if Game.music: Game.music.play_for_map(&"cold_forge")
	point(Vector2(160,900),"[F] กลับบึงหมอกเงิน",func(): await Game.change_map(&"silver_marsh",&"default"))
	for i in range(3):
		var index := i
		point(Vector2(1100+i*950,900),"[F] เสาพันธนาการ %d" % (i+1),func(): await _seal(index))
	point(Vector2(6070,900),"[F] วงจรหลังบัลลังก์",_core)
	Events.damage_dealt.connect(_interrupt_jr)
	if not PlayerState.has_flag(&"rb_baphomet_defeated"):
		boss = _spawn(false,Vector2(5450,760))
		boss.set_physics_process(false)
		boss.set_meta("encounter_locked", true)
		boss.died.connect(_boss_died)
	else:
		_setup_farm_room()   # ★ รอบ 126 ★
	queue_redraw()

func _build_world() -> void:
	var bg = load("res://scenes/world/chapter3/blackhorn_rootcrypt_background.tscn").instantiate()
	add_child(bg)
	var ground := StaticBody2D.new()
	ground.position = Vector2(3200,960)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(6400,120)
	collision.shape = shape
	ground.add_child(collision)
	add_child(ground)
	var spawns := Node2D.new()
	spawns.name = "SpawnPoints"
	for pair in [["default",Vector2(250,770)],["checkpoint",Vector2(3970,770)]]:
		var marker := Marker2D.new()
		marker.name = pair[0]
		marker.position = pair[1]
		spawns.add_child(marker)
	add_child(spawns)

func point(at: Vector2, title: String, action: Callable) -> void:
	var p = Point.new()
	p.position = at
	p.draw_marker = false
	p.title = title
	p.action = action
	add_child(p)

func _configure_boss(data: MonsterData) -> void:
	data.display_name = "บาฟโฟเมท ผู้กินคำสัตย์"
	data.set_meta("hide_skill_notice", true)
	data.atk_min = 520
	data.atk_max = 680
	data.hit = 95
	data.attack_cooldown = 1.15
	data.skill_chance = 1.0
	data.skill_cooldown = 6.0
	data.skill_damage_mult = 2.0

func _spawn(jr: bool, at: Vector2, summoned: bool = false) -> Node2D:
	var enemy = load("res://scenes/monsters/monster.tscn").instantiate()
	enemy.data = load("res://data/monsters/%s.tres" % ("baphomet_jr" if jr else "baphomet")).duplicate()
	enemy.position = at
	if jr:
		enemy.data.level = 49
		enemy.data.max_hp = 2600
		enemy.data.atk_min = JR_ATK_MIN
		enemy.data.atk_max = JR_ATK_MAX
		enemy.data.hit = JR_HIT
		enemy.data.attack_cooldown = 0.85
		enemy.data.knockback_force = 0
		enemy.data.exp_reward = 400 if not summoned else 0
		if summoned:
			enemy.data.job_exp_reward = 0
			enemy.data.zeny_min = 0
			enemy.data.zeny_max = 0
			enemy.data.drops = enemy.data.drops.duplicate()
			enemy.data.drops.clear()
		enemy.set_meta("rb_add",summoned)
		enemy.set_meta("rb_caster",get_tree().get_nodes_in_group("rb_jr").size()%2 == 1)
	else:
		_configure_boss(enemy.data)
		enemy.set_meta("hide_skill_notice", true)
	add_child(enemy)
	if not jr: enemy.position.y += 900.0-enemy.foot_position().y
	if jr: enemy.add_to_group("rb_jr")
	return enemy

## ★ รอบ 126 ★ ยามเสา 7-10 ตัว เรียงห่างกันเท่า ๆ กันทั่วช่วง ±SEAL_SPREAD รอบเสา (+เขย่าเล็กน้อย) — ไม่กองรวมให้สกิลหมู่กวาดทีเดียว
func _spawn_seal_guards(index: int) -> Array:
	var center := 1100.0 + index * 950.0
	var n := randi_range(SEAL_GUARDS_MIN, SEAL_GUARDS_MAX)
	var step := SEAL_SPREAD * 2.0 / float(n - 1)
	var out: Array = []
	for k in range(n):
		var x := center - SEAL_SPREAD + step * k + randf_range(-18.0, 18.0)
		out.append(_spawn(true, Vector2(x, 790)))
	return out


## ★ รอบ 126 ★ ห้องบอสหลังจบเควส: ใช้ MapSpawner มาตรฐาน 2 ตัว (บอส 1 · ลูกอสูร 5) จำกัดพื้นที่ในห้องบอส
## บอสตายแล้วเกิดใหม่ตามคูลดาวน์ในไฟล์มอน (is_boss → ล็อกข้ามแมพ ระหว่างรอเป็นศพ) · ลูกอสูรเกิดใหม่ตาม respawn_time
func _setup_farm_room() -> void:
	var boss_data: MonsterData = load("res://data/monsters/baphomet.tres").duplicate()
	_configure_boss(boss_data)
	var jr_data: MonsterData = load("res://data/monsters/baphomet_jr.tres").duplicate()
	jr_data.level = 49
	jr_data.max_hp = 2600
	jr_data.atk_min = JR_ATK_MIN
	jr_data.atk_max = JR_ATK_MAX
	jr_data.hit = JR_HIT
	jr_data.attack_cooldown = 0.85
	jr_data.knockback_force = 0
	jr_data.exp_reward = 400
	for cfg in [[boss_data, 1, 420.0], [jr_data, FARM_JR_COUNT, 170.0]]:
		var sp := MapSpawner.new()
		sp.name = "FarmSpawner_" + String(cfg[0].id)
		sp.monster_types.append(cfg[0])
		sp.count_per_type = int(cfg[1])
		sp.min_spacing = float(cfg[2])
		sp.spawn_offscreen = false
		sp.max_spawn_distance = 2200.0
		sp.despawn_distance = 99999.0
		sp.edge_margin = 60.0
		add_child(sp)
		sp._bounds = FARM_ROOM   # จำกัดให้เกิดเฉพาะในห้องบอส (หลัง _ready คำนวณจากทั้งแมพ)


func _seal(index: int) -> void:
	var flag := StringName("rb_seal_%d" % index)
	if PlayerState.has_flag(flag):
		Events.say("เสานี้ถูกปลดแล้ว")
		return
	if not guards.has(index):
		guards[index] = _spawn_seal_guards(index)
	for guard in guards[index]:
		if is_instance_valid(guard) and not guard.is_dead():
			Events.say("กำจัดลูกอสูรที่ผูกกับเสาก่อน แล้วกด F เพื่อทำลายพันธนาการ")
			return
	PlayerState.set_flag(flag)
	Events.say("เสาพันธนาการ %d ถูกทำลาย — ฝูงนี้จะไม่กลับมา" % (index+1))
	queue_redraw()

func _start_boss() -> void:
	if fighting or PlayerState.is_dead() or PlayerState.has_flag(&"rb_baphomet_defeated"): return
	if not is_instance_valid(boss) or boss.is_dead(): return
	var reason := ""
	for i in range(3):
		if not PlayerState.has_flag(StringName("rb_seal_%d" % i)):
			reason = "ต้องปลดเสาพันธนาการทั้งสามก่อน"
	if reason == "" and not PlayerState.quests.is_active(&"rb5_oath_eater"):
		reason = "รับเควส «ผู้กินคำสัตย์» จากญอร์ดาก่อนเข้าห้อง"
	if reason != "":
		player.position.x = 4200
		if gate_notice_time <= 0:
			Events.say(reason)
			gate_notice_time = 3.0
		return
	fighting = true
	boss.set_meta("encounter_locked", false)
	boss.set_physics_process(true)
	boss.set_home(Vector2(5350, boss.position.y))
	boss._set_aggro()
	queue_redraw()

func _core() -> void:
	if not PlayerState.has_flag(&"rb_baphomet_defeated"):
		Events.say("วงจรยังถูกบาฟโฟเมทยึดไว้")
		return
	await UI.talk([{"text":"เจ้าหมุนวงจรกลับทิศ... พลังที่เคยถูกดูดขึ้นไปตามราก ไหลคืนลงสู่แผ่นดิน รูนของอัศวินที่ถูกล่ามไว้สว่างขึ้นทีละดวง แล้วดับลงอย่างสงบ\n\nใต้บัลลังก์มีวงรูนเก้าดวง สามดวงสว่างตอบรับดาบของเจ้า อีกหกดวงยังมืด — ชี้ไปทางเหนือ"}])
	PlayerState.set_flag(&"rb_core_freed")
	PlayerState.set_flag(&"rb_next_job_hint")
	await Game.change_map(&"vanir_town",&"default")

func _boss_died(_enemy: Node, _data: MonsterData) -> void:
	fighting = false
	PlayerState.set_flag(&"rb_baphomet_defeated")
	hazards.clear()
	slow_zones.clear()
	slowed = false
	PlayerState.active_buffs.erase(&"rb_slow")
	PlayerState.refresh()
	for jr in get_tree().get_nodes_in_group("rb_jr"):
		if jr.get_meta("rb_add",false): jr.queue_free()
	Events.say("บาฟโฟเมทพ่ายแพ้! กด F ที่วงจรหลังบัลลังก์ เพื่อคืนพลังให้รูน")
	queue_redraw()

func _interrupt_jr(target: Node, _amount: int, _crit: bool) -> void:
	if target.get_meta("rb_channel",false):
		target.set_meta("rb_channel",false)
		target.set_physics_process(true)
		for h in hazards:
			if h.get("caster") == target: h["cancelled"] = true

func _hazard(rect: Rect2, delay: float, damage: float = 1.0, caster: Node = null) -> void:
	hazards.append({"rect":rect,"time":delay,"mult":damage,"caster":caster})

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): return
	gate_notice_time = maxf(0.0, gate_notice_time - delta)
	if not fighting and player.position.x >= 4250:
		_start_boss()
	if not fighting:
		# Seal guards appear as the player approaches, not only on interaction.
		for i in range(3):
			if absf(player.position.x-(1100+i*950)) < 440 and not guards.has(i) and not PlayerState.has_flag(StringName("rb_seal_%d"%i)):
				guards[i] = _spawn_seal_guards(i)
			if guards.has(i) and not PlayerState.has_flag(StringName("rb_seal_%d"%i)):
				var alive := false
				for guard in guards[i]:
					if is_instance_valid(guard) and not guard.is_dead(): alive = true
				if not alive:
					seal_wait[i] = float(seal_wait.get(i,18.0))-delta
					if seal_wait[i] <= 0:
						guards[i] = _spawn_seal_guards(i)
						seal_wait.erase(i)
		return
	if PlayerState.is_dead():
		fighting = false
		hazards.clear()
		queue_redraw()
		return
	for zone in slow_zones.duplicate():
		zone.time -= delta
		if zone.time <= 0: slow_zones.erase(zone)
	var inside := false
	for zone in slow_zones:
		if zone.rect.has_point(player.foot_position()): inside = true
	if inside != slowed:
		slowed = inside
		if slowed: PlayerState.active_buffs[&"rb_slow"] = {"time_left":4.0,"values":{"move_speed_percent":-25.0},"level":1}
		else: PlayerState.active_buffs.erase(&"rb_slow")
		PlayerState.refresh()
	player.position.x = clampf(player.position.x,4250,6250)
	if not is_instance_valid(boss) or boss.is_dead(): return
	var phase := 1 if boss.hp > boss.data.max_hp*0.7 else (2 if boss.hp > boss.data.max_hp*0.35 else 3)
	boss.data.attack_cooldown = 1.15 if phase == 1 else (1.0 if phase == 2 else 0.9)
	boss.data.skill_cooldown = 6.0 if phase == 1 else (5.2 if phase == 2 else 4.5)
	boss.position.x = clampf(boss.position.x, 4350, 6100)
	next_adds -= delta
	clear_grace = maxf(0,clear_grace-delta)
	for h in hazards.duplicate():
		h.time -= delta
		if h.time > 0: continue
		hazards.erase(h)
		var caster = h.get("caster")
		if h.get("cancelled",false): continue
		if h.has("spawn"):
			_spawn(true,h.spawn,true)
			continue
		if caster != null:
			if not is_instance_valid(caster) or caster.is_dead(): continue
			caster.set_meta("rb_channel",false)
			caster.set_physics_process(true)
			if h.rect.has_point(player.foot_position()):
				var strike := Combat.monster_skill_hits_player(caster.data, PlayerState.stats, 1.25)
				if not strike.miss: player.take_damage(int(strike.damage))
			slow_zones.append({"rect":h.rect,"time":3.0})
			continue
		if h.rect.has_point(player.foot_position()):
			var hit := Combat.monster_hits_player(boss.data,PlayerState.stats)
			if not hit.miss: player.take_damage(int(hit.damage*h.mult))
	var adds: Array = []
	for jr in get_tree().get_nodes_in_group("rb_jr"):
		if jr.get_meta("rb_add",false) and not jr.is_dead(): adds.append(jr)
	if adds.is_empty() and had_adds: clear_grace = 8.0
	had_adds = not adds.is_empty()
	if next_adds <= 0 and clear_grace <= 0:
		var cap := 2 if phase == 1 else 3
		for i in range(cap-adds.size()):
			var at := Vector2(4330 if i%2==0 else 6170,790)
			hazards.append({"rect":Rect2(at-Vector2(45,0),Vector2(90,115)),"time":1.0,"spawn":at})
		next_adds = 18

	if hazards.is_empty():
		for jr in adds:
			var cd: float = jr.get_meta("rb_cast_cd",0.0)-delta
			jr.set_meta("rb_cast_cd",cd)
			if cd<=0 and jr.get_meta("rb_caster",false):
				jr.set_meta("rb_cast_cd",8.0)
				jr.set_meta("rb_channel",true)
				jr.set_physics_process(false)
				_hazard(Rect2(player.foot_position()-Vector2(70,100),Vector2(140,105)),1.2,0.35,jr)
				break
	queue_redraw()

func _draw() -> void:
	if fighting:
		draw_line(Vector2(4250,400),Vector2(4250,900),Color(0.7,0.1,0.3,0.65),12)
	for h in hazards:
		if not h.get("cancelled",false):
			draw_rect(h.rect,Color(0.9,0.08,0.2,0.35))
			draw_rect(h.rect,Color(1,0.5,0.3),false,3.0)
	for zone in slow_zones: draw_rect(zone.rect,Color(0.45,0.15,0.7,0.4))

func _exit_tree() -> void:
	PlayerState.active_buffs.erase(&"rb_slow")
	if PlayerState.stats != null and PlayerState.skills != null: PlayerState.refresh()
