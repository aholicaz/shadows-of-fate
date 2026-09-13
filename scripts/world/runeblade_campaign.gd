extends Node2D

const Point = preload("res://scripts/world/runeblade_point.gd")
var map: Node2D
var dummy: Node2D
var trial := ""
var rhythm := 0
var last_skill: StringName
var third := false
var attack_clock := 0.0
var warning := false
var zone := Rect2()
var opening := 0.0

func _ready() -> void:
	map = get_parent()
	match String(map.map_id):
		"nidavellir_town":
			_add_quests("บรอกก์", [&"rb1_unsung_iron"])
		"vanir_town":
			_add_quests("ผู้อาวุโสญอร์ดา", [&"rb1_unsung_iron",&"rb2_unbound_rune",&"rb3_beneath_marsh",&"rb4_edge_and_force",&"rb5_oath_eater",&"rb6_runeblade",&"rb7_ninth_inscription"])
			point(Vector2(740,900),"[F] ศิลาคำสัตย์",_ceremony)
			point(Vector2(3100,900),"[F] ลานฝึกดาบ · บททดสอบ Runeblade",func():
				if PlayerState.quests.is_active(&"rb4_edge_and_force"):
					await Game.change_map(&"runeblade_training",&"default")
				else: Events.say("รับเควส R4 คมและแรงกับญอร์ดาก่อน"))
		"runeblade_training":
			point(Vector2(200,900),"[F] กลับวานาเฮม",func(): await Game.change_map(&"vanir_town",&"from_training"))
			point(Vector2(700,900),"[F] เริ่มบททดสอบ",_training)
		"silver_marsh":
			point(Vector2(1600,900),"[F] ศิลารูนแตก",func(): await _read(&"rb_clue_stone","รอยแตกบนศิลาตรงกับชิ้นรูน... มีรอยเขาสองข้าง\nเส้นอักขระขาดตรงทางคืนพลัง เหมือนวงจรที่บรอกก์พบใต้ภูเขา แต่รอยนี้ถูกสกัดออกด้วยมือผู้สร้าง"))
			point(Vector2(2600,900),"[F] เงาในน้ำ",func(): await _read(&"rb_clue_shadow","ในน้ำมีเงารูปเขา แต่บนฝั่งไม่มีใครยืนอยู่\nเงาดึงแสงจากรูนเข้าหาตัว น้ำกลับนิ่งสนิท... สิ่งใต้บึงกำลังกินพลังที่ควรไหลคืนสู่ราก"))
			point(Vector2(3760,900),"[F] กระดิ่งใต้ราก",func(): await _read(&"rb_clue_bell","เสียงกระดิ่งดังใต้บึง ทางลงอยู่ในซุ้มรากข้าง ๆ\nใต้ฐานกระดิ่งมีข้อความ: จงเลือกคำสัตย์ด้วยตนเอง ผู้มอบดาบแก่เสียงเรียก ย่อมเหลือเพียงเปลือก"))
			var entrance = point(Vector2(3450,900),"[F] วิหารเขาทมิฬใต้ราก",_entrance)
			entrance.reveal_flag = &"rb_clues"

func _add_quests(who: String, ids: Array) -> void:
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.npc_name == who:
			for id in ids:
				if id not in npc.quest_ids: npc.quest_ids.append(id)
	Events.quest_changed.emit()

func point(at: Vector2, title: String, action: Callable) -> Node2D:
	var node = Point.new()
	node.position = at
	node.draw_marker = false
	node.title = title
	node.action = action
	add_child(node)
	return node

func _read(id: StringName, text: String) -> void:
	await UI.talk([{"name":"อักขระใต้ราก", "text":text}])
	PlayerState.quests.on_read(id)
	PlayerState.set_flag(StringName("read_"+String(id)))

func _ceremony() -> void:
	if PlayerState.stats.job_id == &"runeblade":
		var pick: int = await UI.talk([{"name":"ศิลาคำสัตย์", "text":"วงจรรูนยังมีอักขระที่เก้า... เมื่อถึงเลเวล 90 เสียงจากแดนเหนือจะเรียกหาเจ้า เส้นทางขั้นถัดไปยังไม่เปิดในบทนี้\nคืนแต้มฟรีครั้งแรก หลังจากนั้น 10,000 z", "choices":["อ่านอักขระที่เก้า", "คืนแต้ม Runeblade", "ไว้ก่อน"]}])
		if pick == 0:
			PlayerState.quests.on_read(&"rb_ninth_inscription")
			PlayerState.set_flag(&"rb_next_job_hint")
			if PlayerState.stats.level >= 90: PlayerState.set_flag(&"rb_next_job_ready")
		elif pick == 1:
			PlayerState.skills.reset_runeblade()
		return
	if PlayerState.quests.is_active(&"rb6_runeblade"):
		await _read(&"rb_ceremony","ข้าจะเป็นผู้เลือกทิศทางของดาบด้วยตนเอง กลับไปหาญอร์ดาเพื่อรับอาชีพ Runeblade")
	else:
		await _read(&"rb_rune_tablet","คมที่ไร้จังหวะย่อมแตกหัก แรงที่ไร้การควบคุมย่อมย้อนคืน\nรูนเก้าดวง... มีเพียงสามดวงที่เรายังอ่านออก")

func _entrance() -> void:
	if PlayerState.stats.level < 50 or not PlayerState.has_flag(&"rb_trials"):
		await UI.talk([{"text":"ประตูต้องการรูนประสานจากเควสคมและแรง และผู้ถือเลเวล 50 ขึ้นไป"}])
		return
	PlayerState.set_flag(&"rb_dungeon_open")
	await Game.change_map(&"blackhorn_rootcrypt", &"default")

func _training() -> void:
	if not PlayerState.quests.is_active(&"rb4_edge_and_force"):
		await UI.talk([{"text":"รับเควส R4 คมและแรงกับญอร์ดาก่อน แล้วกลับมาทดสอบที่นี่"}])
		return
	var pick: int = await UI.talk([{"text":"ทดสอบฟรี ฟื้น HP/SP เมื่อจบ หลีกแนวโจมตีสีแดงแล้วสวนในช่วงสีทอง", "choices":["จังหวะของคม: คอมโบครบ 3 ชุด", "น้ำหนักของดาบ: เปิดแผล แล้ว Bash ช่วงหุ่นเก็บท่า", "ออก"]}])
	if pick < 0 or pick > 1: return
	_begin_training(pick)

func _begin_training(pick: int) -> void:
	if is_instance_valid(dummy): dummy.queue_free()
	trial = "rhythm" if pick == 0 else "force"
	rhythm = 0
	third = false
	attack_clock = 2.0
	warning = false
	dummy = load("res://scenes/monsters/monster.tscn").instantiate()
	dummy.data = load("res://data/monsters/vanir_sentinel.tres").duplicate()
	dummy.data.display_name = "หุ่นทดสอบ — หลบแล้วสวน"
	dummy.data.max_hp = 10000000
	dummy.data.exp_reward = 0
	dummy.position = Vector2(1250, 780)
	map.add_child(dummy)
	dummy.position.y += 900.0-dummy.foot_position().y
	dummy.set_physics_process(false)
	if not Events.damage_dealt.is_connected(_trial_hit): Events.damage_dealt.connect(_trial_hit)
	if not Events.skill_used.is_connected(_skill): Events.skill_used.connect(_skill)
	if not map.player.combo_step_started.is_connected(_combo): map.player.combo_step_started.connect(_combo)

func _skill(id: StringName, _lv: int) -> void:
	last_skill = id
	third = false
func _combo(step: int, _anim: String, _mult: float) -> void:
	third = step == 2
	last_skill = &""
func _trial_hit(target: Node, _amount: int, _crit: bool) -> void:
	if target != dummy or trial == "": return
	if trial == "rhythm" and third:
		third = false
		rhythm += 1
		Events.say("คอมโบครบ %d / 3" % rhythm)
		if rhythm >= 3: _finish_trial(&"rb_trial_rhythm")
	elif trial == "force" and last_skill == &"bash" and dummy._wound_time > 0 and opening > 0:
		_finish_trial(&"rb_trial_force")
func _finish_trial(flag: StringName) -> void:
	PlayerState.set_flag(flag)
	trial = ""
	dummy.queue_free()
	PlayerState.heal_hp(PlayerState.stats.max_hp)
	PlayerState.restore_sp(PlayerState.stats.max_sp)
	Events.say("ผ่านบททดสอบแล้ว กลับไปหาญอร์ดาเมื่อครบทั้งสองบท")
	queue_redraw()
func _process(delta: float) -> void:
	if trial == "" or not is_instance_valid(dummy): return
	dummy._tick_wound(delta)
	if PlayerState.is_dead():
		trial = ""
		dummy.queue_free()
		queue_redraw()
		return
	attack_clock -= delta
	opening = maxf(0, opening-delta)
	if attack_clock <= 0:
		if not warning:
			zone = Rect2(map.player.foot_position()-Vector2(95,100),Vector2(190,105))
			warning = true
			attack_clock = 0.9
		else:
			if zone.has_point(map.player.foot_position()) and not map.player.is_dodging():
				rhythm = 0
				Events.say("โดนแนวโจมตี! เริ่มนับคอมโบใหม่ หลบออกจากสีแดงก่อนสวน")
			warning = false
			opening = 2.2
			attack_clock = 3.2
	queue_redraw()
func _draw() -> void:
	if trial == "": return
	if warning: draw_rect(zone,Color(1,0.15,0.05,0.45))
	elif opening > 0 and is_instance_valid(dummy): draw_arc(dummy.position,110,0,TAU,32,Color.GOLD,4,true)
