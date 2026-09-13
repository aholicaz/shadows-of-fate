## ch456_campaign — เหตุการณ์พิเศษของบท 4-6 (รอบ 105)   MapBase เพิ่มโหนดนี้ให้เองทุกแมพที่ chapter >= 4
##
## ทำอะไรบ้าง (แต่ละแมพ):
##   utgard_town     S6 หลุมศพที่ชื่อถูกสกัด (อ่านสุสานขณะมีเศษภาพวาด) · อาสมุนด์หายจากเมืองถ้าถูกสงสัย
##   broken_wall     ที่นั่งรอค่ำ/เช้า (สลับร่างกลางคืน) · S5 คนแปลกหน้าบนกำแพงตอนกลางคืน
##   ljosalf_city    ผลึกเงาใหญ่ — สลับร่างจาง/สว่าง · ดาเกอร์หายไปถ้าปล่อยผู้หลุดจากแสง · S8 หมอน็อตต์
##   mirror_lake     S7 คนแปลกหน้าดึงขึ้นจากน้ำ (ตายครั้งแรกระหว่าง C5-5) · นับเงาสะท้อนในร่างจาง (RB11)
##   eljudnir        S9 คนแปลกหน้าให้หน้าสุดท้ายของเล่ม 7
##   hall_of_names   ★ ผนังที่เก้า — พิธี awakening Ninth Edge (RB13) ★
##   garm_gate       โซ่สายฟ้า 4 เส้น ปลดครบ = การ์มหยุดสู้ เลือกปล่อย/ฆ่า
##   odin_seat       บัลลังก์ว่าง (C6-10) · การ์มที่ถูกปล่อยมานอน · S10 คนแปลกหน้า
##   ทุกแมพ          ธง has_frida_song · killed_mammoth_many
extends Node2D

const Point = preload("res://scripts/world/story_point.gd")
const STRANGER := "คนแปลกหน้า"

var map: Node2D
var _busy := false
var _rest_point: Node2D


func _ready() -> void:
	map = get_parent()
	Events.npc_talked.connect(_on_npc_talked)
	Events.quest_changed.connect(_on_quest_changed)
	Events.monster_killed.connect(_on_monster_killed)
	Events.boss_killed.connect(_on_boss_killed)
	# ธงที่ NPC ใช้เลือกบทพูด (dialog_by_flag ดูธงได้ แต่ดูกระเป๋าไม่ได้)
	if PlayerState.inventory != null and PlayerState.inventory.count_of(&"frida_song") > 0:
		PlayerState.set_flag(&"has_frida_song")
	match String(map.map_id):
		"utgard_town":
			_utgard()
		"broken_wall":
			_broken_wall()
		"ljosalf_city":
			_ljosalf()
		"mirror_lake":
			add_to_group("death_guard")
		"hall_of_names":
			_hall_of_names()
		"garm_gate":
			_garm_gate()
		"odin_seat":
			_odin_seat()


# =========================================================
# ตัวช่วย
# =========================================================
func point(at: Vector2, title: String, shape: String, action: Callable) -> Node2D:
	var node = Point.new()
	node.position = at
	node.title = title
	node.shape = shape
	node.action = action
	add_child(node)
	return node


func _talk(pages: Array) -> int:
	return await UI.talk(pages)


func _wait_talk_end() -> void:
	await get_tree().create_timer(0.15).timeout
	var guard := 0
	while (UI.is_asking() or UI.is_any_window_open()) and guard < 6000:
		await get_tree().process_frame
		guard += 1


func _free_npc(npc_name: String) -> void:
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.get("npc_name") == npc_name:
			npc.queue_free()


func _find_boss(id: StringName) -> Node:
	for e in get_tree().get_nodes_in_group("enemy"):
		var d = e.get("data")
		if d != null and d.id == id and not (e.has_method("is_dead") and e.is_dead()):
			return e
	return null


# =========================================================
# สัญญาณรวม
# =========================================================
func _on_monster_killed(monster_id: StringName, _lv: int) -> void:
	if monster_id == &"snow_mammoth" and int(PlayerState.kills.get(&"snow_mammoth", 0)) > 5:
		PlayerState.set_flag(&"killed_mammoth_many")
	if monster_id == &"reflection" and map.get("is_variant") == true and PlayerState.quests.is_active(&"rb11_shadow_of_the_blade"):
		var n := int(PlayerState.get_flag(&"rb11_kill_count", 0)) + 1
		PlayerState.set_flag(&"rb11_kill_count", n)
		Events.say("เงาสะท้อนในร่างจาง %d / 3" % n)
		if n >= 3:
			PlayerState.set_flag(&"rb11_shadow_kills")


func _on_boss_killed(monster_id: StringName, _name: String) -> void:
	if monster_id == &"chained_garm":
		PlayerState.set_flag(&"killed_garm")
		PlayerState.set_flag(&"garm_resolved")
	if monster_id == &"false_judge" and PlayerState.has_flag(&"recorded_truth"):
		Events.say("ผู้พิพากษา: «...ข้าจำชื่อเจ้าได้ ชื่อที่เจ้าทิ้งไว้ที่สะพาน... เจ้าบันทึกความจริงไว้ที่วานาเฮม»")


func _on_quest_changed() -> void:
	if _busy:
		return
	match String(map.map_id):
		"utgard_town":
			# S6 — อ่านสุสานขณะมีเศษภาพวาด (S5) → คนแปลกหน้าพูดจากข้างหลัง
			if PlayerState.has_flag(&"read_giant_graves") and not PlayerState.has_flag(&"s6_done") \
					and PlayerState.inventory.count_of(&"mural_fragment") > 0:
				_s6()
		"ljosalf_city":
			if PlayerState.has_flag(&"spared_forsaken") and PlayerState.quests.is_done(&"c5_8_forsaken") and not PlayerState.has_flag(&"dagr_left"):
				PlayerState.set_flag(&"dagr_left")
				_free_npc("เจ้าเมืองดาเกอร์")
				Events.say("ดาเกอร์: «เจ้าไม่เข้าใจ... ข้าเข้าใจ» — เจ้าเมืองเดินออกจากเมืองไปทางวิหาร")


func _on_npc_talked(npc_name: String) -> void:
	if _busy:
		return
	match String(map.map_id):
		"ljosalf_city":
			# S8 — คุยหมอน็อตต์ตอนร่างจาง + มีเศษภาพวาด
			if npc_name == "หมอน็อตต์" and map.get("is_variant") == true and not PlayerState.has_flag(&"s8_done") \
					and PlayerState.inventory.count_of(&"mural_fragment") > 0:
				_s8()
		"eljudnir":
			if npc_name == STRANGER and PlayerState.has_flag(&"s8_done") and not PlayerState.has_flag(&"s9_done"):
				_s9()
		"odin_seat":
			if npc_name == STRANGER and PlayerState.has_flag(&"chapter6_done") and not PlayerState.has_flag(&"s10_done"):
				_s10()


# =========================================================
# บท 4 — อุทการ์ด
# =========================================================
func _utgard() -> void:
	# อาสมุนด์กลับวิหารหลัง C4-9 ถ้าผู้เล่นสงสัยเขา (ผลต่อบท 9)
	if PlayerState.has_flag(&"doubt_asmund") and PlayerState.quests.is_done(&"c4_9_breach_on_the_south") \
			and not PlayerState.has_flag(&"asmund_left"):
		PlayerState.set_flag(&"asmund_left")
		_free_npc("นักบวชอาสมุนด์")


func _s6() -> void:
	_busy = true
	await _wait_talk_end()
	await _talk([
		{"name": "เสียงจากข้างหลัง", "text": "...หลุมนั้น ข้ารู้จักเขา"},
		{"name": "เสียงจากข้างหลัง", "text": "เขาชื่อ... ไม่ ข้าพูดชื่อไม่ได้แล้ว ถูกลบไปพร้อมกับข้า"},
		{"name": "เสียงจากข้างหลัง", "text": "อย่าหันมา คนตัวเล็ก เจ้ายังไม่ควรเห็นหน้าข้าในเมืองนี้\n\nชื่อของข้าก็ถูกสกัดออก — จากศิลา จากหลุม จากปากคน\nแต่ยังไม่ถูกสกัดออกจากคนที่จำได้"},
	])
	PlayerState.set_flag(&"s6_done")
	Events.say("[เหตุการณ์ลับ S6] ชื่อบนหลุมศพ — เจ้าเริ่มรู้ว่าชื่อของคนแปลกหน้าก็ถูกลบ")
	_busy = false


# =========================================================
# บท 4 — กำแพงที่แตก (กลางคืน)
# =========================================================
func _broken_wall() -> void:
	var y := 880.0
	var night: bool = map.get("is_variant") == true
	_rest_point = point(Vector2(300, y), "[F] รอจนเช้า" if night else "[F] นั่งพักรอค่ำ", "camp", _toggle_night)
	if night and PlayerState.quests.is_done(&"c4_8_shieldbearer"):
		point(Vector2(3100, y), "[F] " + STRANGER, "figure", _s5)


func _toggle_night() -> void:
	if not PlayerState.quests.is_done(&"c4_8_shieldbearer"):
		await _talk([{"name": "", "text": "ยังไม่ใช่เวลาพัก... ผู้ถือโล่ยังยืนเฝ้าอยู่ปลายกำแพง"}])
		return
	var night: bool = PlayerState.has_flag(&"wall_night")
	PlayerState.set_flag(&"wall_night", not night)
	Events.say("รอจนเช้า..." if night else "นั่งพักจนฟ้ามืด... กำแพงตอนกลางคืนเงียบกว่าที่คิด")
	await Game.change_map(&"broken_wall", &"default")


func _s5() -> void:
	if PlayerState.has_flag(&"s5_done"):
		await _talk([{"name": STRANGER, "text": "...ข้ายังยืนตรงนี้ทุกคืน ดูรอยแตก\n\nไปเถอะ คนตัวเล็ก หลุมรอเจ้าอยู่"}])
		return
	await _talk([
		{"name": STRANGER, "text": "...เจ้ามาตอนกลางคืน ดี ตอนกลางวันข้ายืนที่นี่ไม่ได้"},
		{"name": STRANGER, "text": "ข้าอยู่ที่นี่วันที่มันแตก ข้าพยายามบอกพวกเขาว่าใครกำลังมา\n\nพวกเขาไม่ฟัง เพราะข้ามาจากฝั่งเดียวกับคนที่มา"},
		{"name": STRANGER, "text": "ภาพวาดในโถงน้ำแข็ง มุมซ้ายถูกขูดออก... เจ้าเห็นแล้วใช่ไหม\n\nนี่คือมุมนั้น ข้าเก็บไว้สามร้อยปี — เอาไปเถอะ ข้าดูมันมากพอแล้ว"},
	])
	PlayerState.gain_item_id(&"mural_fragment", 1)
	PlayerState.set_flag(&"s5_done")
	Events.say("[เหตุการณ์ลับ S5] คนที่ยืนบนกำแพง — ได้เศษภาพวาดที่หายไป")


# =========================================================
# บท 5 — ลโยซาลฟ์ (ร่างจาง)
# =========================================================
func _ljosalf() -> void:
	var y := 880.0
	var dim: bool = map.get("is_variant") == true
	point(Vector2(3700, y), "[F] ผลึกเงาใหญ่ — " + ("กลับสู่ร่างสว่าง" if dim else "มองผ่านร่างจาง"), "crystal", _toggle_shade)


func _toggle_shade() -> void:
	if not PlayerState.has_flag(&"has_shade_crystal") and PlayerState.inventory.count_of(&"shade_crystal") == 0:
		await _talk([{"name": "ผลึกเงาใหญ่", "text": "ผลึกสีดำสูงเท่าคน... ไม่มีใครในเมืองมองเห็นมัน\n\nต้องมี «ผลึกเงา» จากเงาสะท้อนที่ทะเลสาบกระจก (C5-5) ถึงจะใช้ได้"}])
		return
	var dim: bool = PlayerState.has_flag(&"shade_view")
	PlayerState.set_flag(&"shade_view", not dim)
	Events.say("แสงกลับมา... ทุกคนยิ้มอีกครั้ง" if dim else "แสงจางลง... เจ้าเห็นเมืองอย่างที่มันเป็น")
	await Game.change_map(&"ljosalf_city", &"default")


func _s8() -> void:
	_busy = true
	await _wait_talk_end()
	await _talk([
		{"name": STRANGER, "text": "(เขายืนอยู่ข้างหลังหมอ ไม่มีใครในเมืองเห็นเขา — ยกเว้นเจ้าที่มองผ่านร่างจาง)\n\nน็อตต์ แปลว่ากลางคืน"},
		{"name": STRANGER, "text": "พวกเจ้าเคยมีมัน หมอ พวกเจ้าเคยหลับ เคยฝัน เคยตื่นมาแล้วเศร้า\n\nแล้วพวกเจ้าแลกมันไป"},
		{"name": "หมอน็อตต์", "text": "...กลางคืน... ข้า... ข้าจำได้แล้ว\n\n(หมอทรุดลงนั่ง รอยยิ้มหายไปเป็นครั้งแรก)"},
		{"name": STRANGER, "text": "นี่ อีกครึ่งของเล่มที่ 7 หน้าที่พูดถึงสัญญาแห่งแสง\n\nชื่อคนที่คัดค้านสัญญาถูกลบ... เจ้าคงเดาได้แล้วว่าใคร"},
	])
	PlayerState.gain_item_id(&"book_seven_half_2", 1)
	PlayerState.set_flag(&"s8_done")
	Events.say("[เหตุการณ์ลับ S8] ชื่อที่หมอไม่รู้ความหมาย — ได้พงศาวดารเล่ม 7 อีกครึ่ง")
	_busy = false


# =========================================================
# บท 5 — ทะเลสาบกระจก: S7 คนแปลกหน้าดึงขึ้นจากน้ำ (player.take_damage ถามกลุ่ม death_guard ก่อนตาย)
# =========================================================
func try_rescue(amount: int) -> bool:
	if PlayerState.has_flag(&"s7_saved") or PlayerState.is_dead():
		return false
	if not PlayerState.quests.is_active(&"c5_5_thing_in_the_water"):
		return false
	if amount < PlayerState.stats.hp:
		return false
	PlayerState.set_flag(&"s7_saved")
	PlayerState.stats.hp = maxi(1, int(PlayerState.stats.max_hp * 0.3))
	Events.hp_changed.emit(PlayerState.stats.hp, PlayerState.stats.max_hp)
	Events.floating_text(map.player.global_position + Vector2(0, -60), "มือที่ดึงออกจากน้ำ", Color("#9be7ff"), 24, 0)
	_s7_talk.call_deferred()
	return true


func _s7_talk() -> void:
	_busy = true
	if is_instance_valid(map.player):
		map.player.velocity = Vector2.ZERO
	await _talk([
		{"name": STRANGER, "text": "(มือหนึ่งดึงเจ้าขึ้นจากน้ำ ก่อนเงาในทะเลสาบจะปิดเหนือหัว)\n\nครั้งนี้ข้าอยู่ใกล้พอ"},
		{"name": STRANGER, "text": "...ครั้งก่อน ๆ ข้าไม่เคยใกล้พอ\n\nลุกขึ้น เงาสะท้อนไม่รอ — และอย่าถามว่าข้าเป็นใคร ข้าตอบไม่ได้"},
	])
	Events.say("[เหตุการณ์ลับ S7] มือที่ดึงออกจากน้ำ — คนแปลกหน้าช่วยเจ้าเป็นครั้งแรก")
	_busy = false


# =========================================================
# บท 6 — เอลยุดเนียร์: S9
# =========================================================
func _s9() -> void:
	_busy = true
	await _wait_talk_end()
	await _talk([
		{"name": STRANGER, "text": "(ผู้ตายทุกตนในเมืองหันมองทางเดียวกัน — มองเขา)\n\nพวกเขาจำข้าได้ ทั้งที่ข้าไม่มีชื่อแล้ว"},
		{"name": STRANGER, "text": "หน้าสุดท้ายของเล่มที่ 7 — ตอนนี้เจ้ามีครบเล่ม\n\nคนเขียนคือ «น้องของผู้ถือค้อน» ชื่อถูกลบ... แต่ตัวหนังสือยังอยู่"},
	])
	PlayerState.inventory.remove_id(&"book_seven_half", 1)
	PlayerState.inventory.remove_id(&"book_seven_half_2", 1)
	PlayerState.gain_item_id(&"book_seven_complete", 1)
	PlayerState.set_flag(&"s9_done")
	Events.say("[เหตุการณ์ลับ S9] คนที่ผู้ตายมอง — พงศาวดารเล่ม 7 ครบเล่มแล้ว")
	_busy = false


# =========================================================
# บท 6 — โถงแห่งนาม: ★ ผนังที่เก้า — พิธี awakening Ninth Edge ★
# =========================================================
func _hall_of_names() -> void:
	var p := point(Vector2(4500, 880.0), "[F] ผนังว่างท้ายโถง", "wall", _ninth_wall)
	if PlayerState.stats.job_id == &"ninth_edge":
		p.set_title("[F] ผนังที่เก้า — ชื่อของเจ้า")


func _ninth_wall() -> void:
	var q := PlayerState.quests
	if PlayerState.stats.job_id == &"ninth_edge":
		await _talk([{"name": "ผนังที่เก้า", "text": "ชื่อของเจ้าสลักอยู่บนผนัง — ชื่อเดียวในโถงที่ยังอ่านออก\n\nตัวอักษรเรืองเบา ๆ ตามจังหวะหัวใจเจ้า"}])
		return
	if not q.is_active(&"rb13_the_ninth_wall"):
		await _talk([{"name": "ผนังว่าง", "text": "ผนังหินว่างเปล่าท้ายโถง ไม่มีชื่อไหนสลักอยู่\n\nอักษรบนผนังอื่นไหลผ่านมันไป เหมือนไม่มีอะไรยึดติดตรงนี้ได้"}])
		return
	if not (q.step_done(&"rb13_the_ninth_wall", 0) and q.step_done(&"rb13_the_ninth_wall", 1) and q.step_done(&"rb13_the_ninth_wall", 2)):
		await _talk([{"name": "ผนังว่าง", "text": "โถงยังไม่เงียบ... ผู้เฝ้ากับเสียงที่ถูกลบยังพูดทับกัน และเจ้าต้องอ่านชื่อกลางผนังก่อน\n\n(RB13: ผู้เฝ้านาม 15 · เสียงที่ถูกลบ 10 · อ่านชื่อโอดิน)"}])
		return
	if PlayerState.stats.level < 90:
		await _talk([{"name": "ผนังว่าง", "text": "เจ้ายกค้อนขึ้น... แต่ผนังไม่รับสิ่ว\n\nอักขระที่เก้ายังไม่ตอบรับ — ต้องเลเวล 90 (ตอนนี้ %d)" % PlayerState.stats.level}])
		return
	if PlayerState.inventory.count_of(&"gerd_chisel") == 0:
		await _talk([{"name": "ผนังว่าง", "text": "ต้องใช้ค้อนสลักของเกอร์ด (จาก C4-6 รูนดวงที่สี่) — ช่างยักษ์ตาบอดบอกไว้ว่าวันหนึ่งเจ้าจะต้องสลักสิ่งที่นางสลักไม่ได้"}])
		return
	if not PlayerState.has_flag(&"name_left"):
		await _talk([{"name": "ผนังว่าง", "text": "เจ้ายังมีชื่อ... คนมีชื่อสลักบนผนังนี้ไม่ได้ ต้องทิ้งชื่อที่สะพานก่อน (C6-3)"}])
		return
	# ---------- พิธี ----------
	_busy = true
	await _talk([
		{"name": "ผนังที่เก้า", "text": "เจ้าวางค้อนของเกอร์ดลงบนผนังว่าง\n\nอักษรทั้งโถงหยุดไหล"},
		{"name": "ผนังที่เก้า", "text": "รูนแปดดวงบนดาบสว่างขึ้นทีละดวง — กำเนิด · กำแพง · แสง · เงา · เถ้า...\n\nดวงที่เก้าว่างเปล่า มันรอมาตลอด"},
		{"name": "เสียงจากทุกชื่อในโถง", "text": "อักขระที่เก้าไม่เคยมีใครสลัก\n\nเพราะมันคือชื่อของคนที่ถือดาบ"},
		{"name": "ผนังที่เก้า", "text": "เจ้าสลักชื่อของตัวเอง — ชื่อที่ทิ้งไว้ที่สะพาน ชื่อที่ยังไม่มีใครลบ\n\nในโถงที่ชื่อทุกชื่อถูกลบ ชื่อของเจ้าคือชื่อเดียวที่สลักใหม่ได้\n\n★ ดาบที่ธอร์ยังลบไม่ได้ ★"},
	])
	PlayerState.quests.on_read(&"ninth_wall")
	PlayerState.set_flag(&"read_ninth_wall")
	if not PlayerState.turn_in_quest(&"rb13_the_ninth_wall"):
		await _talk([{"name": "ผนังที่เก้า", "text": "...ชื่อยังไม่ติดผนัง (กระเป๋าเต็ม หรือเงื่อนไขไม่ครบ) — ลองใหม่อีกครั้ง"}])
		_busy = false
		return
	if is_instance_valid(map.player):
		Events.floating_text(map.player.global_position + Vector2(0, -120), "★ Ninth Edge — คมอักขระที่เก้า ★", Color("#ffd86b"), 30, 0)
		if map.player.has_method("_play_level_up"):
			map.player._play_level_up(LevelUpEffect.Kind.JOB, PlayerState.stats.job_level)
	Events.say("[เปลี่ยนอาชีพ] Ninth Edge — คมอักขระที่เก้า · ชื่อของเจ้ากลับมาบน HUD เป็นสีทอง · แต้มรูนสูงสุด 45 · รูนสะสม 4 (กายาอักขระ ระดับ 5)")
	for npc in get_tree().get_nodes_in_group("story_point"):
		if npc.has_method("set_title") and npc.title.begins_with("[F] ผนังว่าง"):
			npc.set_title("[F] ผนังที่เก้า — ชื่อของเจ้า")
	_busy = false


# =========================================================
# บท 6 — ประตูของการ์ม: โซ่สายฟ้า 4 เส้น
# =========================================================
func _garm_gate() -> void:
	var xs := [900, 1500, 2000, 3100]
	for i in range(4):
		var idx := i
		point(Vector2(xs[i], 880.0), "[F] โซ่สายฟ้า %d" % (i + 1), "chain", func(): await _chain(idx))


func _chain(i: int) -> void:
	var flag := StringName("garm_chain_%d" % (i + 1))
	if PlayerState.has_flag(&"garm_resolved"):
		await _talk([{"name": "โซ่สายฟ้า", "text": "โซ่ขาดแล้ว... ประจุสายฟ้าค่อย ๆ จางไป"}])
		return
	if PlayerState.has_flag(flag):
		Events.say("โซ่เส้นนี้ปลดแล้ว")
		return
	var garm := _find_boss(&"chained_garm")
	if garm == null:
		await _talk([{"name": "โซ่สายฟ้า", "text": "โซ่ยังมีประจุ แต่ปลายโซ่ว่าง... การ์มยังไม่มา รอมันก่อน"}])
		return
	if garm.global_position.distance_to(map.player.global_position) < 260:
		Events.say("การ์มอยู่ใกล้เกินไป — ล่อมันออกไปก่อนแล้วค่อยปลด")
		return
	PlayerState.set_flag(flag)
	var n := 0
	for k in range(4):
		if PlayerState.has_flag(StringName("garm_chain_%d" % (k + 1))):
			n += 1
	PlayerState.gain_item_id(&"garm_chain_link", 1)
	Events.say("ปลดโซ่สายฟ้า %d / 4 — การ์มหอนดังขึ้น" % n)
	if n >= 4:
		await _garm_freed(garm)


func _garm_freed(garm: Node) -> void:
	_busy = true
	if is_instance_valid(garm):
		garm.set_physics_process(false)
		if garm.has_method("_play"):
			garm._play("Idle")
	var pick: int = await _talk([
		{"name": "การ์ม", "text": "(โซ่เส้นสุดท้ายขาด... การ์มหยุด มันไม่กัด ไม่หอน — มันมองเจ้า)\n\nตาสีแดงคู่นั้นไม่ได้มองศัตรู มันมองคนที่ปลดโซ่"},
		{"name": "การ์ม", "text": "มันเดินมาหนึ่งก้าว แล้วหมอบลง\n\nสามร้อยปีที่ถูกล่ามให้เฝ้าไม่ให้ความจริงออกไป... ตอนนี้มันรอว่าเจ้าจะทำอะไร", "choices": ["ปล่อยมันไป — ให้มันไปนอนที่บัลลังก์", "จบมัน — มันคือสุนัขของธอร์"]},
	])
	if pick == 0 or pick < 0:
		PlayerState.set_flag(&"freed_garm")
		PlayerState.set_flag(&"garm_resolved")
		PlayerState.gain_item_id(&"garm_chain_link", 2)
		PlayerState.gain_exp(160000, 100000)
		Events.say("การ์มเป็นอิสระ — มันเดินผ่านประตูไปทางบัลลังก์ว่าง ไม่หันกลับมา")
		if is_instance_valid(garm):
			garm.queue_free()
	else:
		Events.say("การ์มลุกขึ้น... มันรู้ว่าเจ้าเลือกอะไร — สู้!")
		if is_instance_valid(garm):
			garm.set_physics_process(true)
	_busy = false


# =========================================================
# บท 6 — บัลลังก์ว่างของโอดิน
# =========================================================
func _odin_seat() -> void:
	point(Vector2(1700, 880.0), "[F] บัลลังก์ว่าง", "throne", _throne)
	if PlayerState.has_flag(&"freed_garm"):
		point(Vector2(900, 880.0), "[F] การ์ม (นอนอยู่)", "hound", func():
			await _talk([{"name": "การ์ม", "text": "การ์มนอนขดอยู่ข้างบัลลังก์ หายใจช้า ๆ\n\nโซ่ไม่มีแล้ว แต่มันยังไม่ไปไหน — มันเฝ้าบัลลังก์ว่าง ครั้งนี้ด้วยความสมัครใจ"}]))


func _throne() -> void:
	if PlayerState.has_flag(&"read_odin_seat_throne"):
		await _talk([{"name": "บัลลังก์ว่าง", "text": "บัลลังก์ไม้สีทอง — สิ่งเดียวในนิฟล์เฮมที่มีสี\n\nเงียบ ไม่มีเสียงอีกแล้ว แต่ที่นั่งยังอุ่น"}])
		return
	if not PlayerState.quests.is_active(&"c6_10_empty_seat"):
		await _talk([{"name": "บัลลังก์ว่าง", "text": "บัลลังก์ไม้สีทอง ว่างเปล่า... มีเสียงเบามากอยู่ข้างใน แต่ยังฟังไม่ออก\n\n(รับเควส C6-10 จากเฮลก่อน)"}])
		return
	_busy = true
	await _talk([
		{"name": "บัลลังก์ว่าง", "text": "เจ้าวางมือบนที่นั่ง... อุ่น เหมือนมีคนเพิ่งลุกไป"},
		{"name": "เศษวิญญาณ", "text": "(แสงสีทองจาง ๆ รวมตัวขึ้นเหนือบัลลังก์ เป็นรูปคนแก่ตาเดียว... แค่เสี้ยวเดียวของสิ่งที่เคยเป็น)"},
		{"name": "เศษวิญญาณ", "text": "ข้าไม่ได้หายไป...\n\n...ลูกข้า—"},
		{"name": "บัลลังก์ว่าง", "text": "(แสงสลายไป ก่อนจะพูดจบ)\n\nเหลือแค่เศษไม้สีทองชิ้นหนึ่งบนที่นั่ง"},
	])
	PlayerState.set_flag(&"read_odin_seat_throne")
	PlayerState.quests.on_read(&"odin_seat_throne")
	Events.say("[C6-10] เจ้าได้ยินคำว่า «ลูกข้า—» กลับไปบอกเฮล")
	_busy = false


func _s10() -> void:
	_busy = true
	await _wait_talk_end()
	var pick: int = await _talk([
		{"name": STRANGER, "text": "(เขานั่งอยู่ที่ขั้นบันไดของบัลลังก์ว่าง ไม่หันมา)\n\n...เจ้าได้ยินคำนั้นแล้ว"},
		{"name": STRANGER, "text": "เป็นครั้งแรกที่ข้าจะให้เจ้าถาม — คำถามเดียว", "choices": ["«ท่านคือลูกของโอดิน?»", "«ชื่อของท่าน... คืออะไร»", "ไม่ถามอะไร"]},
	])
	match pick:
		0:
			await _talk([
				{"name": STRANGER, "text": "......"},
				{"name": STRANGER, "text": "(เขาเงียบนานมาก)\n\nข้ามีพี่ชายคนหนึ่ง\n\nเขาถือค้อน"},
			])
		1:
			await _talk([{"name": STRANGER, "text": "ข้าพูดไม่ได้ เจ้ารู้แล้ว\n\nแต่ข้าบอกได้ว่าข้ามีพี่ชายคนหนึ่ง... เขาถือค้อน"}])
		_:
			await _talk([{"name": STRANGER, "text": "...ก็ดี บางคำถามถามตอนนี้ยังเร็วไป\n\nข้ามีพี่ชายคนหนึ่ง เจ้าคงเดาได้ว่าเขาถืออะไร"}])
	PlayerState.set_flag(&"s10_done")
	Events.say("[เหตุการณ์ลับ S10] ผู้ที่ยืนข้างบัลลังก์ — เจ้ารู้แล้วว่าเขาคือน้องของผู้ถือค้อน แต่ชื่อยังไม่มี")
	_busy = false
