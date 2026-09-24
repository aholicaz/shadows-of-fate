extends "res://scripts/world/map_base.gd"
const Tower = preload("res://scripts/world/chapter8_tower_data.gd")
const Rewards = preload("res://scripts/world/chapter8_rewards.gd")
const MONSTER = preload("res://scenes/monsters/chapter8_monster.tscn")
const PORTAL = preload("res://scenes/world/portal.tscn")
@export_range(0, 100) var floor_number := 1   # ★ รอบ 179 ★ 50 → 100
var stage := 0
var living := 0
var cleared := false
var next_portal: Area2D
var status: Label
var advance_button: Button
var transition_timer: Timer
var enemy_container: Node2D

func _ready() -> void:
	super._ready()
	# Shared scene spawn markers predate the enlarged C3 collision capsule.
	# Align using the actual current body instead of a guessed sprite offset.
	if is_instance_valid(player): player.position.y = 880.0 - player._feet_y()
	if Game.music != null:
		var tracks := [&"root_road", &"frozen_hall", &"vanir_town", &"ash_procession"]
		Game.music.play_for_map(&"vanir_town" if floor_number == 0 else tracks[Tower.theme(floor_number) % tracks.size()])
	_build_status()
	if floor_number == 0:
		_build_hub()
		return
	_add_portal("กลับจุดพักราก", &"yggdrasil_root", 110, &"default")
	next_portal = _add_portal("ทางขึ้นยังถูกผนึก", Tower.floor_id(floor_number + 1) if floor_number < Tower.FLOOR_COUNT else &"yggdrasil_root", 4100, &"default")
	next_portal.required_flag = &"c8_never_open_directly"
	next_portal.locked_text = "กำจัดศัตรูและผู้คุมของชั้นนี้ให้ครบก่อน ทางรากจึงจะเปิด"
	enemy_container = Node2D.new()
	enemy_container.name = "TowerEnemies"
	add_child(enemy_container)
	if not Tower.can_enter(floor_number):
		status.text = "เส้นทางยังไม่เปิด — จบบท 7 และผ่านชั้นก่อนหน้าก่อน"
		return
	_next_stage()
	if Tower.gm_test: status.text = "GM ทดสอบ • " + status.text

func _build_status() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	status = Label.new()
	status.anchor_left = 0.5
	status.anchor_right = 0.5
	status.anchor_top = 1.0
	status.anchor_bottom = 1.0
	status.offset_left = -340
	status.offset_right = 340
	status.offset_top = -145
	status.offset_bottom = -95
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 20)
	status.add_theme_color_override("font_color", Color("c8f4dd"))
	status.add_theme_constant_override("outline_size", 5)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(status)
	advance_button = Button.new()
	advance_button.text = "เริ่มเวฟถัดไป"
	advance_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	advance_button.position = Vector2(-110, -95)
	advance_button.size = Vector2(220, 46)
	advance_button.add_theme_font_size_override("font_size", 20)
	advance_button.hide()
	advance_button.pressed.connect(_advance_encounter)
	layer.add_child(advance_button)

func _add_portal(title: String, target: StringName, x: float, spawn: StringName) -> Area2D:
	var portal := PORTAL.instantiate() as Area2D
	portal.position = Vector2(x, 880)
	portal.target_map = target
	portal.target_spawn_point = spawn
	portal.label_text = title
	portal.destination_name = title
	add_child(portal)
	return portal

func _build_hub() -> void:
	if not Tower.gm_test: Rewards.claim_earned()
	PlayerState.heal_hp(PlayerState.stats.max_hp)
	PlayerState.restore_sp(PlayerState.stats.max_sp)
	status.text = "อิกดราซิล • เส้นทาง %d ชั้น\nรับภารกิจจากสวาลา • เลือกจุดพักที่ศิลาราก" % Tower.FLOOR_COUNT
	_add_portal("← อัมเบอร์เฮเวน", &"emberhaven", 110, &"from_chapter8")
	var start := _add_portal("เริ่มชั้น 1 →", Tower.floor_id(1), 4100, &"default")
	start.required_flag = &"" if Tower.gm_test else &"chapter7_done"
	start.locked_text = "ส่งทะเบียนหนึ่งร้อยชื่อให้สวาลาในบท 7 ก่อน"
	# One selector instead of nine overlapping portals across the road.
	var marker := Area2D.new()
	marker.position = Vector2(2400, 880)
	marker.set_script(preload("res://scripts/world/chapter8_checkpoint.gd"))
	add_child(marker)

var kills := 0
var boss_skill_until := 0.0
var _champion_stage := -1   # ★ รอบ 182 ★ เวฟที่มีแชมเปี้ยนแล้ว

func claim_boss_skill() -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if now < boss_skill_until: return false
	boss_skill_until = now + 7.5
	return true

func _next_stage() -> void:
	if not is_inside_tree() or cleared or PlayerState.is_dead(): return
	stage += 1
	var sizes := Tower.wave_sizes(floor_number)
	if stage <= sizes.size():
		var roster := Tower.wave_roster(floor_number, stage - 1)
		GameData.release_monsters_except(roster)
		living = roster.size()
		_update_wave_status()
		for i in range(roster.size()):
			_queue_spawn(roster[i], false, false, _spawn_x(i), 1.0)
	elif stage == sizes.size() + 1:
		var bosses := Tower.boss_roster(floor_number)
		GameData.release_monsters_except(bosses)
		living = bosses.size() # Includes the delayed partner, so an early kill cannot clear the floor.
		status.text = "ชั้น %d / %d • บอส %d ตัว" % [floor_number, Tower.FLOOR_COUNT, living]
		for i in range(bosses.size()):
			_queue_spawn(bosses[i], true, bosses[i] in Tower.NEW_IDS, _spawn_x(i), 1.0 if i == 0 else 7.0)
	else:
		_complete_floor()

func _spawn_x(index: int) -> float:
	var center := player.position.x if is_instance_valid(player) else 2100.0
	var side := -1.0 if index % 2 == 0 else 1.0
	var x := clampf(center + side * (620.0 + (index / 2) * 160.0), 450.0, 3750.0)
	if absf(x - center) < 450.0:
		x = clampf(center - side * (620.0 + (index / 2) * 100.0), 450.0, 3750.0)
	return x

func _queue_spawn(id: String, boss: bool, guardian: bool, x: float, delay: float) -> void:
	var marker := Label.new()
	marker.text = "◆ บอส ◆" if boss else "◇"
	marker.position = Vector2(x - 50.0, 780.0)
	marker.add_theme_font_size_override("font_size", 32)
	marker.modulate = Color("ffba75") if boss else Color("91d9d1")
	add_child(marker)
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = delay
	add_child(timer)
	timer.timeout.connect(func():
		marker.queue_free()
		timer.queue_free()
		if not PlayerState.is_dead() and not cleared: _spawn(id, boss, guardian, x))
	timer.start()

func _update_wave_status() -> void:
	var sizes := Tower.wave_sizes(floor_number)
	var total := 0
	for count in sizes: total += count
	status.text = "ชั้น %d / %d • เวฟ %d/%d • กำจัด %d/%d" % [floor_number, Tower.FLOOR_COUNT, stage, sizes.size(), kills, total]

func _spawn(source_id: String, boss: bool, guardian: bool, x: float) -> void:
	var original := GameData.get_monster(StringName(source_id))
	if original == null:
		push_error("Tower monster missing: " + source_id)
		status.text = "โหลดศัตรูไม่สำเร็จ: " + source_id
		return
	var actor := MONSTER.instantiate()
	actor.data = Tower.make_enemy(original, floor_number, boss, guardian)
	# ★ รอบ 182 ★ ชั้น 51+ สุ่มแชมเปี้ยนตราทอง (เวฟละไม่เกิน 1 ตัว · หอไม่ใช้ตราแตกร่าง เพราะนับตัวตายเพื่อผ่านเวฟ)
	if not boss and floor_number >= Tower.CHAMPION_FROM_FLOOR and _champion_stage != stage and randf() < Tower.CHAMPION_CHANCE:
		_champion_stage = stage
		actor.set_meta(&"champion", true)
		actor.set_meta(&"gold_mark_exclude", [&"split"])
	actor.position = Vector2(x, 880 - actor.data.foot_offset())
	actor.died.connect(_enemy_died)
	enemy_container.add_child(actor)
	actor.set_home(actor.position)

func _enemy_died(_actor: Node, _data: MonsterData) -> void:
	living -= 1
	if stage <= Tower.wave_sizes(floor_number).size():
		kills += 1
		_update_wave_status()
	if living > 0: return
	status.text = "ทางรากกำลังตอบสนอง…"
	transition_timer = Timer.new()
	transition_timer.one_shot = true
	transition_timer.wait_time = 2.0
	add_child(transition_timer)
	transition_timer.timeout.connect(_advance_encounter)
	if is_instance_valid(advance_button): advance_button.show()
	transition_timer.start()

func _advance_encounter() -> void:
	if not is_instance_valid(transition_timer): return
	transition_timer.stop()
	transition_timer.queue_free()
	transition_timer = null
	if is_instance_valid(advance_button): advance_button.hide()
	if not PlayerState.is_dead(): _next_stage()

func _complete_floor() -> void:
	if cleared: return
	cleared = true
	if Tower.gm_test:
		status.text = "GM ทดสอบผ่านชั้น %d • ไม่บันทึกผลผ่านหรือแจกของรางวัล" % floor_number
		next_portal.required_flag = &""
		next_portal.label_text = "กลับจุดพัก →" if floor_number == Tower.FLOOR_COUNT else "ขึ้นชั้น %d →" % (floor_number+1)
		next_portal.destination_name = next_portal.label_text
		next_portal.get_node("Label").text = next_portal.label_text
		next_portal.get_node("EnterHint").text = "กด F เพื่อ" + next_portal.label_text
		return
	var flag := Tower.clear_flag(floor_number)
	var first := not PlayerState.has_flag(flag)
	# Set the entitlement flag before granting rewards (safe against repeated callbacks).
	PlayerState.set_flag(flag)
	if first:
		PlayerState.gain_exp(Tower.clear_exp(floor_number), Tower.clear_job_exp(floor_number))
		PlayerState.add_zeny(9000 + floor_number * 1000)
	else:
		# A complete new encounter earns training EXP; repeated completion callbacks cannot.
		PlayerState.gain_exp(Tower.repeat_exp(floor_number), int(Tower.clear_job_exp(floor_number) * .25))
	if floor_number == 20:
		PlayerState.set_flag(&"c8_trial20_done")
	if floor_number == 50:
		PlayerState.set_flag(&"c8_ascent50_done")
		status.text = "ผ่านชั้น 50 • เปิดเส้นทางช่วยผู้ติดค้างแล้ว\nกลับรายงานสวาลาที่จุดพักราก หรือขึ้นต่อชั้น 51"
	elif floor_number == Tower.FLOOR_COUNT:   # ★ รอบ 179 ★ ยอดหอ
		PlayerState.set_flag(&"c8_ascent100_done")
		status.text = "ผ่านชั้น %d • ประตูแอสการ์ดเปิดแล้ว\nกลับรายงานสวาลาที่จุดพักราก" % floor_number
		if first: Events.say("คนแปลกหน้า: «เจ้ามาถึงจนได้... พี่ชายข้ารออยู่หลังประตูบานนี้»")
	else:
		status.text = "ผ่านชั้น %d • ทางขึ้นเปิดแล้ว%s" % [floor_number, " • จุดพักฟื้น" if floor_number % 5 == 0 else ""]
	if floor_number % 5 == 0:
		Rewards.claim_earned()
		PlayerState.heal_hp(PlayerState.stats.max_hp)
		PlayerState.restore_sp(PlayerState.stats.max_sp)
	next_portal.required_flag = &""
	next_portal.label_text = "กลับรายงานสวาลา →" if floor_number == Tower.FLOOR_COUNT else "ขึ้นชั้น %d →" % (floor_number + 1)
	next_portal.destination_name = next_portal.label_text
	var label := next_portal.get_node_or_null("Label") as Label
	if label != null: label.text = next_portal.label_text
	next_portal.get_node("EnterHint").text = "กด F เพื่อ" + next_portal.label_text
	SaveManager.request_autosave()
