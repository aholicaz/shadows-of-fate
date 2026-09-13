extends "res://scripts/world/map_base.gd"

const Point = preload("res://scripts/world/runeblade_point.gd")
var boss: Node2D
var fighting := false
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
	point(Vector2(4050,900),"[F] จุดพัก / เข้าห้องบอส",_start_boss)
	point(Vector2(6070,900),"[F] วงจรหลังบัลลังก์",_core)
	Events.damage_dealt.connect(_interrupt_jr)
	if not PlayerState.has_flag(&"rb_baphomet_defeated"):
		boss = _spawn(false,Vector2(5450,760))
		boss.set_physics_process(false)
		boss.died.connect(_boss_died)
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

func _spawn(jr: bool, at: Vector2, summoned: bool = false) -> Node2D:
	var enemy = load("res://scenes/monsters/monster.tscn").instantiate()
	enemy.data = load("res://data/monsters/%s.tres" % ("baphomet_jr" if jr else "baphomet")).duplicate()
	enemy.position = at
	if jr:
		enemy.data.level = 49
		enemy.data.max_hp = 1800
		enemy.data.atk_min = 130
		enemy.data.atk_max = 175
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
		enemy.data.max_hp = 65000
		enemy.data.display_name = "Baphomet — ผู้กินคำสัตย์"
	add_child(enemy)
	if not jr: enemy.position.y += 900.0-enemy.foot_position().y
	if jr: enemy.add_to_group("rb_jr")
	return enemy

func _seal(index: int) -> void:
	var flag := StringName("rb_seal_%d" % index)
	if PlayerState.has_flag(flag):
		Events.say("เสานี้ถูกปลดแล้ว")
		return
	if not guards.has(index):
		guards[index] = [_spawn(true,Vector2(1020+index*950,790)),_spawn(true,Vector2(1230+index*950,790))]
	for guard in guards[index]:
		if is_instance_valid(guard) and not guard.is_dead():
			Events.say("กำจัดลูกอสูรที่ผูกกับเสาก่อน แล้วกด F เพื่อทำลายพันธนาการ")
			return
	PlayerState.set_flag(flag)
	Events.say("เสาพันธนาการ %d ถูกทำลาย — ฝูงนี้จะไม่กลับมา" % (index+1))
	queue_redraw()

func _start_boss() -> void:
	if fighting: return
	for i in range(3):
		if not PlayerState.has_flag(StringName("rb_seal_%d" % i)):
			Events.say("ต้องปลดเสาพันธนาการทั้งสามก่อน")
			return
	PlayerState.set_flag(&"rb_checkpoint")
	PlayerState.heal_hp(PlayerState.stats.max_hp)
	PlayerState.restore_sp(PlayerState.stats.max_sp)
	if PlayerState.has_flag(&"rb_baphomet_defeated"):
		Events.say("Baphomet ถูกปราบแล้ว ไปปลดวงจรหลังบัลลังก์")
		return
	if not PlayerState.quests.is_active(&"rb5_oath_eater"):
		Events.say("รับเควส R5 ผู้กินคำสัตย์ จากญอร์ดาก่อนเข้าห้อง")
		return
	await UI.talk([{"name":"Baphomet", "text":"เจ้ามนุษย์เปลี่ยนนายอีกแล้วหรือ?"},{"text":"ข้ามาเอาสิ่งที่ไม่ควรมีนายคืนไป"}])
	fighting = true
	player.position.x = 4400
	queue_redraw()

func _core() -> void:
	if not PlayerState.has_flag(&"rb_baphomet_defeated"):
		Events.say("วงจรยังถูก Baphomet ยึดครอง")
		return
	await UI.talk([{"text":"เจ้ากลับทิศทางของวงจร พลังไหลคืนสู่ราก... แก่นรูนที่คืนอิสระสว่างขึ้น\n\nใต้บัลลังก์มีอักขระเก้าดวง สามดวงตอบรับ อีกหกดวงชี้ไปทางเหนือ — เมื่อเจ้าเติบโตถึงเลเวล 90 จงฟังเสียงเรียกอีกครั้ง"}])
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
	Events.say("Baphomet พ่ายแพ้! กด F ที่วงจรหลังบัลลังก์เพื่อคืนอิสระให้รูน")
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
	if not fighting:
		# Seal guards appear as the player approaches, not only on interaction.
		for i in range(3):
			if absf(player.position.x-(1100+i*950)) < 440 and not guards.has(i) and not PlayerState.has_flag(StringName("rb_seal_%d"%i)):
				guards[i] = [_spawn(true,Vector2(1020+i*950,790)),_spawn(true,Vector2(1230+i*950,790))]
			if guards.has(i) and not PlayerState.has_flag(StringName("rb_seal_%d"%i)):
				var alive := false
				for guard in guards[i]:
					if is_instance_valid(guard) and not guard.is_dead(): alive = true
				if not alive:
					seal_wait[i] = float(seal_wait.get(i,18.0))-delta
					if seal_wait[i] <= 0:
						guards[i] = [_spawn(true,Vector2(1020+i*950,790)),_spawn(true,Vector2(1230+i*950,790))]
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
	boss._tick_wound(delta)
	var phase := 1 if boss.hp > boss.data.max_hp*0.7 else (2 if boss.hp > boss.data.max_hp*0.35 else 3)
	next_attack -= delta
	next_adds -= delta
	clear_grace = maxf(0,clear_grace-delta)
	if next_attack <= 0:
		attack_number += 1
		var dir := 1 if player.position.x > boss.position.x else -1
		boss._face_to(dir)
		boss._play("Attack",true)
		if attack_number%3 == 0 and phase >= 2:
			_hazard(Rect2(player.foot_position()-Vector2(110,115),Vector2(220,120)),1.0,1.15)
		else:
			var x: float = boss.position.x if dir>0 else boss.position.x-460
			var rect := Rect2(Vector2(x,620),Vector2(460,285))
			_hazard(rect,0.7)
			if phase == 3: _hazard(rect,1.35,0.85)
		next_attack = 3.8 if phase < 3 else 4.4
	if next_attack > 1.5 and next_attack < 2.6:
		boss.position.x = move_toward(boss.position.x,player.position.x,90*delta)
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
		Events.say("กระดิ่งดัง... ลูกอสูรออกจากประตูด้านข้าง!")
	if hazards.is_empty() and next_attack > 2.0:
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
