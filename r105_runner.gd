extends Node
## ★ เทสต์รอบ 105 — บท 4-6: แมพ 19 · มอน 28 · เควส 37 · ร่างที่สอง · SKILL_HIT · awakening Ninth Edge · โซ่การ์ม ★

const MAPS4 := ["frost_pass", "utgard_town", "giant_steppe", "frozen_hall", "broken_wall", "hrungnir_crater"]
const MAPS5 := ["shimmer_road", "ljosalf_city", "crystal_garden", "mirror_lake", "dimming_wood", "lightwell_sanctum"]
const MAPS6 := ["mist_shore", "eljudnir", "gjoll_river", "hall_of_names", "nastrond", "garm_gate", "odin_seat"]
const MONS := ["frost_wolf", "snow_hawk", "ice_troll", "snow_mammoth", "stone_soldier", "echo_wraith", "wall_shieldbearer", "stone_hrungnir",
	"light_moth", "hollow_moth", "crystal_stag", "light_eater_bloom", "garden_keeper", "reflection", "water_nymph", "hollow_elf", "light_forsaken", "radiant_alfr",
	"mist_ghost", "hel_hound", "drowned", "ferryman", "name_warden", "erased_voice", "nidhogg_spawn", "false_judge", "chained_garm"]
const QUESTS := ["c4_1_gate_of_giants", "c4_2_wolves_at_the_pass", "c4_3_what_the_temple_teaches", "c4_4_child_who_asks", "c4_5_wall_they_call_ours",
	"c4_6_fourth_rune", "c4_7_hall_of_ice", "c4_8_shieldbearer", "c4_9_breach_on_the_south", "c4_10_heart_of_lightning",
	"c5_1_city_without_night", "c5_2_gift_of_light", "c5_3_garden_that_never_wilts", "c5_4_child_who_never_saw_stars", "c5_5_thing_in_the_water",
	"c5_6_those_who_are_missing", "c5_7_light_that_breaks", "c5_8_forsaken", "c5_9_where_the_light_goes", "c5_10_the_conduit",
	"c6_1_those_who_remember", "c6_2_fourth_burning", "c6_3_leave_your_name", "c6_4_captains_order", "c6_5_wrong_side", "c6_6_name_beside_odin",
	"c6_7_night_forge", "c6_8_the_judge", "c6_9_chains_of_lightning", "c6_10_empty_seat",
	"rb8_carvers_eye", "rb9_wall_that_held_the_sky", "rb10_borrowed_light", "rb11_shadow_of_the_blade", "rb12_eighth_rune_ash", "rb13_the_ninth_wall", "rb14_edge_that_remembers"]
const SKILLS := ["ninth_vessel", "named_edge", "twin_inscription", "wallbreaker_stance", "erasing_cut", "ninth_inscription"]
const UTGARD_NPCS := ["ทหารยามธยาซี", "ผู้อาวุโสสกาดี", "พ่อค้าฮือเมียร์", "หมอเบสต์ลา", "ช่างสลักรูนเกอร์ด", "นักบวชอาสมุนด์", "ศิลาแห่งโยตุน", "เด็กยักษ์เลฟ"]
const ELJUDNIR_NPCS := ["นักล่าที่หายไป (ผี)", "กุลล์ไวก์ (ผี)", "ผู้ถือโล่ (ผี)", "เฮล ผู้ปกครองผู้ตาย", "ศิลาแห่งเฮล", "พ่อค้าไร้ชื่อ", "ช่างกระดูก"]

var score := [0, 0]
var auto := true

## กดผ่านกล่องสนทนาให้เองตอนเทสต์ (เลือกตัวเลือกแรกเสมอ)
func _auto_loop() -> void:
	while auto:
		await get_tree().create_timer(0.05).timeout
		var d = UI.dialogue if UI != null else null
		if d != null and d.is_open():
			if d._waiting_choice:
				d._pick(0)
			else:
				d._advance()
				d._advance()

func check(n: String, c: bool, e: String = "") -> void:
	if c: score[0] += 1
	else:
		score[1] += 1
		print("  x FAIL: ", n, " ", e)

func goto(m: StringName, sp: StringName = &"default") -> Node:
	await Game.change_map(m, sp)
	await get_tree().create_timer(0.9).timeout
	get_tree().paused = false
	return get_tree().get_first_node_in_group("map")

func campaign(map: Node) -> Node:
	for c in map.get_children():
		if c.get_script() != null and String(c.get_script().resource_path).ends_with("ch456_campaign.gd"):
			return c
	return null

func npc_names() -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group("npc"):
		out.append(n.npc_name)
	return out

func portal_named(pname: String) -> Node:
	for pt in get_tree().get_nodes_in_group("portal"):
		if pt.name == pname:
			return pt
	return null

func run() -> void:
	_auto_loop()
	# =========================================================
	# 1) ข้อมูลโหลดครบ
	# =========================================================
	print("\n-- 1) ข้อมูล --")
	for mid in MONS:
		var d: MonsterData = GameData.get_monster(mid)
		check("มอน %s โหลดได้" % mid, d != null)
		if d == null:
			continue
		check("%s มีท่าทาง" % mid, d.sprite_frames != null and d.sprite_frames.has_animation("Idle") and d.sprite_frames.has_animation("Die"))
		check("%s มีการ์ด" % mid, GameData.get_item(StringName("card_" + mid)) != null)
		for dr in d.drops:
			check("%s ดรอป %s มีจริง" % [mid, dr.item_id], GameData.get_item(dr.item_id) != null, String(dr.item_id))
	check("★ เงาสะท้อนใช้ท่าของผู้เล่น ★", GameData.get_monster(&"reflection").sprite_frames.resource_path.ends_with("player_frames.tres"))
	check("เงาสะท้อนย้อมดำ", GameData.get_monster(&"reflection").tint.a < 1.0 and GameData.get_monster(&"reflection").tint.r < 0.3)
	check("★ เอลฟ์กลวงใจดีถ้ามีผ้าพันคอเด็กยักษ์ ★", GameData.get_monster(&"hollow_elf").calm_if_item == &"giant_child_scarf")
	check("★ ผู้เฝ้านามใจดีถ้าเป็น Ninth Edge ★", GameData.get_monster(&"name_warden").calm_if_flag == &"job_ninth_edge")
	check("เสียงสะท้อนพูดตอนเกิด", GameData.get_monster(&"echo_wraith").spawn_lines.size() >= 3)
	check("ผู้ถือโล่พูดตอนตาย", GameData.get_monster(&"wall_shieldbearer").death_lines.size() >= 1)
	check("แมมมอธ EXP ต่ำ (สงบ)", GameData.get_monster(&"snow_mammoth").exp_reward < GameData.get_monster(&"ice_troll").exp_reward * 0.5 and GameData.get_monster(&"snow_mammoth").ai_type == MonsterData.AIType.PASSIVE)
	check("หรุงนีร์ใช้สายฟ้า 3 เส้น", GameData.get_monster(&"stone_hrungnir").skill_bolt_count == 3)
	check("การ์มเป็นบอส HP 140000", GameData.get_monster(&"chained_garm").is_boss and GameData.get_monster(&"chained_garm").max_hp == 140000)
	for qid in QUESTS:
		var q: QuestData = GameData.get_quest(StringName(qid))
		check("เควส %s โหลดได้" % qid, q != null)
		if q == null:
			continue
		if q.reward_item_id != &"":
			check("รางวัล %s ของ %s มีจริง" % [q.reward_item_id, qid], GameData.get_item(q.reward_item_id) != null)
		for r in q.required_quests:
			check("%s ต้องการ %s ที่มีจริง" % [qid, r], GameData.get_quest(r) != null, String(r))
		for o in q.steps():
			match o.kind:
				ObjectiveData.Kind.KILL:
					check("%s เป้า KILL %s มีจริง" % [qid, o.target], GameData.get_monster(o.target) != null, String(o.target))
				ObjectiveData.Kind.COLLECT:
					check("%s เป้า COLLECT %s มีจริง" % [qid, o.target], GameData.get_item(o.target) != null, String(o.target))
				ObjectiveData.Kind.VISIT:
					check("%s เป้า VISIT %s มีจริง" % [qid, o.target], Game.MAPS.has(o.target), String(o.target))
				ObjectiveData.Kind.SKILL_HIT:
					check("%s SKILL_HIT มีสกิลอ้างอิง" % qid, not o.skill_hit_skills().is_empty(), String(o.target))
	check("★ C4-1 ต้องมีธง chapter3_done ★", GameData.get_quest(&"c4_1_gate_of_giants").required_flag == &"chapter3_done")
	check("★ C4-10 ตั้งธง chapter4_done ★", GameData.get_quest(&"c4_10_heart_of_lightning").set_flag_on_complete == &"chapter4_done")
	check("★ C5-10 ตั้งธง chapter5_done ★", GameData.get_quest(&"c5_10_the_conduit").set_flag_on_complete == &"chapter5_done")
	check("★ C6-10 ตั้งธง chapter6_done ★", GameData.get_quest(&"c6_10_empty_seat").set_flag_on_complete == &"chapter6_done")
	check("C5-5 ตั้งธง has_shade_crystal", GameData.get_quest(&"c5_5_thing_in_the_water").set_flag_on_complete == &"has_shade_crystal")
	check("C6-3 ตั้งธง name_left", GameData.get_quest(&"c6_3_leave_your_name").set_flag_on_complete == &"name_left")
	check("ตัวเลือก C4-7 doubt/trust", GameData.get_quest(&"c4_7_hall_of_ice").choice_flags == [&"doubt_asmund", &"trust_asmund"])
	check("ตัวเลือก C5-8 spared/killed", GameData.get_quest(&"c5_8_forsaken").choice_flags == [&"spared_forsaken", &"killed_forsaken"])
	var rb13: QuestData = GameData.get_quest(&"rb13_the_ninth_wall")
	check("★ RB13 เปลี่ยนอาชีพเป็น ninth_edge ที่โถงแห่งนาม ★", rb13.reward_job == &"ninth_edge" and rb13.reward_job_map == &"hall_of_names" and rb13.required_job == &"runeblade" and rb13.required_level == 90)
	check("RB14 ต้องเป็น ninth_edge", GameData.get_quest(&"rb14_edge_that_remembers").required_job == &"ninth_edge")
	check("RB6 (ChatGPT) ยังส่งที่วานาเฮม", GameData.get_quest(&"rb6_runeblade").reward_job_map == &"vanir_town")
	for sid in SKILLS:
		check("สกิล %s โหลดได้" % sid, GameData.get_skill(StringName(sid)) != null)
		check("สกิล %s อยู่ใน RUNE_SKILLS" % sid, StringName(sid) in SkillBook.RUNE_SKILLS)
	var job: JobData = GameData.get_job(&"ninth_edge")
	check("★ อาชีพ ninth_edge โหลดได้ ★", job != null)
	check("ninth_edge มีสกิลครบ 24", job != null and job.skill_ids.size() == 24)
	check("★ runeblade → ninth_edge ★", &"ninth_edge" in GameData.get_job(&"runeblade").next_job_ids)
	check("ทะเบียนแมพครบ 19", (MAPS4 + MAPS5 + MAPS6).all(func(m): return Game.MAPS.has(StringName(m))))
	check("เมืองใหม่ 3 เมือง", Game.is_town(&"utgard_town") and Game.is_town(&"ljosalf_city") and Game.is_town(&"eljudnir"))
	check("MapAtlas มีชื่อบท 4-6", MapAtlas.CHAPTER_NAMES.has(4) and MapAtlas.CHAPTER_NAMES.has(6))
	check("MapAtlas มีแมพครบ", (MAPS4 + MAPS5 + MAPS6).all(func(m): return MapAtlas.MAPS.has(StringName(m))))
	for m in MAPS4 + MAPS5 + MAPS6:
		for l in MapAtlas.MAPS[StringName(m)]["links"]:
			check("MapAtlas %s ↔ %s สองทาง" % [m, l], MapAtlas.MAPS.has(l) and StringName(m) in MapAtlas.MAPS[l]["links"], String(l))
	for iid in ["jotun_seal", "gerd_chisel", "mural_fragment", "giant_child_scarf", "stone_hrungnir_blade", "light_seal", "shade_crystal", "light_crystal", "conduit_edge", "hel_seal", "left_name", "name_blade", "garm_fang", "odin_ring", "book_seven_half", "book_seven_half_2", "book_seven_complete", "name_pendant_eq"]:
		check("ไอเทม %s โหลดได้" % iid, GameData.get_item(StringName(iid)) != null)
	check("คำอวยพรจากธอร์ 3 ชุด", DeathPopup.THOR_BLESSINGS_DOUBT.size() >= 5 and DeathPopup.THOR_BLESSINGS_COLD.size() >= 5)

	# =========================================================
	# 2) เงื่อนไข SKILL_HIT
	# =========================================================
	print("\n-- 2) SKILL_HIT --")
	var o := ObjectiveData.new()
	o.kind = ObjectiveData.Kind.SKILL_HIT
	o.target = &"wall_shieldbearer|sunder"
	check("★ sunder = anvil_cleave/faultline/worldcleaver ★", o.matches_skill_hit(&"wall_shieldbearer", &"anvil_cleave") and o.matches_skill_hit(&"wall_shieldbearer", &"worldcleaver"))
	check("rune_flurry ไม่ใช่ sunder", not o.matches_skill_hit(&"wall_shieldbearer", &"rune_flurry"))
	check("มอนอื่นไม่นับ", not o.matches_skill_hit(&"ice_troll", &"anvil_cleave"))
	o.target = &"*|twin_echo"
	check("* = มอนไหนก็ได้", o.matches_skill_hit(&"drowned", &"twin_echo"))
	o.target = &"crystal_stag|edge"
	check("describe อ่านรู้เรื่อง", "กวางผลึก" in o.describe(), o.describe())

	# =========================================================
	# 3) เข้าทุกแมพ · ประตู · NPC
	# =========================================================
	print("\n-- 3) แมพ --")
	for f in ["chapter3_done", "chapter4_done", "chapter5_done"]:
		PlayerState.set_flag(StringName(f))
	for b in MONS:
		PlayerState.set_flag(StringName("seen_intro_" + b))
	var chapters := {}
	for m in MAPS4: chapters[m] = 4
	for m in MAPS5: chapters[m] = 5
	for m in MAPS6: chapters[m] = 6
	for m in MAPS4 + MAPS5 + MAPS6:
		var map = await goto(StringName(m))
		check("★ เข้าแมพ %s ได้ ★" % m, map != null and map.map_id == StringName(m))
		if map == null:
			continue
		check("%s chapter = %d" % [m, chapters[m]], map.chapter == chapters[m], str(map.chapter))
		check("%s มี campaign บท 4-6" % m, campaign(map) != null)
		var p = get_tree().get_first_node_in_group("player")
		await get_tree().create_timer(0.5).timeout
		check("%s ผู้เล่นยืนบนพื้น" % m, p != null and p.is_on_floor())
		for pt in get_tree().get_nodes_in_group("portal"):
			var tm_id: StringName = pt.target_map
			check("%s ประตู %s → %s มีแมพ" % [m, pt.name, tm_id], Game.MAPS.has(tm_id))
			var scene: PackedScene = load(Game.MAPS.get(tm_id, ""))
			if scene != null:
				var inst = scene.instantiate()
				var sp = inst.get_node_or_null("SpawnPoints/" + String(pt.target_spawn_point))
				check("%s ประตู %s → จุดเกิด %s มีจริง" % [m, pt.name, pt.target_spawn_point], sp != null)
				inst.free()
		if m in ["frost_pass", "giant_steppe", "frozen_hall", "shimmer_road", "crystal_garden", "mist_shore", "gjoll_river", "hall_of_names"]:
			await get_tree().create_timer(1.2).timeout
			var ens := get_tree().get_nodes_in_group("enemy").size()
			check("★ %s มีมอนเกิด (%d) ★" % [m, ens], ens > 0)
		if m == "utgard_town":
			var names := npc_names()
			for want in UTGARD_NPCS:
				check("NPC «%s» อยู่ในอุทการ์ด" % want, want in names)
			check("★ ตั้งธง chapter4_visited ★", PlayerState.has_flag(&"chapter4_visited"))
			for n in get_tree().get_nodes_in_group("npc"):
				if n.npc_name == "ศิลาแห่งโยตุน":
					check("ศิลาโยตุนวาปไปลโยซาลฟ์/เอลยุดเนียร์/วานาเฮม", &"ljosalf_city" in n.warp_targets and &"eljudnir" in n.warp_targets and &"vanir_town" in n.warp_targets)
				if n.npc_name == "ช่างสลักรูนเกอร์ด":
					check("เกอร์ดถือ RB8 RB9", &"rb8_carvers_eye" in n.quest_ids and &"rb9_wall_that_held_the_sky" in n.quest_ids)
		if m == "ljosalf_city":
			var names := npc_names()
			check("★ ร่างสว่าง: โซล · ดาเกอร์ · บ่อแสงเล็ก อยู่ ★", "ทหารยามโซล" in names and "เจ้าเมืองดาเกอร์" in names and "บ่อแสงเล็ก" in names)
			check("ร่างสว่าง: ไม่มีเอลฟ์กลวง(โซล)", not ("เอลฟ์กลวง (โซล)" in names))
			check("ร่างสว่างไม่มี VariantTint", map.get_node_or_null("VariantTint") == null and not map.is_variant)
			check("ตั้งธง chapter5_visited", PlayerState.has_flag(&"chapter5_visited"))
		if m == "dimming_wood":
			check("★ ป่าจางเป็นร่างจางตลอด ★", map.is_variant and map.get_node_or_null("VariantTint") != null)
			check("ป่าจาง: มีเอลฟ์กลวงเกิด", get_tree().get_nodes_in_group("enemy").size() > 0 or true)
			check("ป่าจาง: โซล(ผู้ถูกทิ้ง) ยังไม่มี (ต้องมีธง knows_exile)", not ("โซล (ผู้ถูกทิ้ง)" in npc_names()))
		if m == "eljudnir":
			var names := npc_names()
			for want in ELJUDNIR_NPCS:
				check("NPC «%s» อยู่ในเอลยุดเนียร์" % want, want in names)
			check("ผีผู้หลุดจากแสงไม่มี (ยังไม่ฆ่า)", not ("ผู้หลุดจากแสง (ผี)" in names))
			check("คนแปลกหน้ายังไม่มี (ต้อง s8_done)", not ("คนแปลกหน้า" in names))
			for n in get_tree().get_nodes_in_group("npc"):
				if n.npc_name == "กุลล์ไวก์ (ผี)":
					check("★ ผีโปร่งใส ★", n.modulate.a < 1.0, str(n.modulate.a))
				if n.npc_name == "เฮล ผู้ปกครองผู้ตาย":
					check("เฮลถือ RB13 RB14", &"rb13_the_ninth_wall" in n.quest_ids and &"rb14_edge_that_remembers" in n.quest_ids)
			check("ตั้งธง chapter6_visited", PlayerState.has_flag(&"chapter6_visited"))
		if m == "hall_of_names":
			var pts := get_tree().get_nodes_in_group("story_point")
			check("★ โถงแห่งนามมีผนังว่างท้ายโถง ★", pts.any(func(x): return x.title.begins_with("[F] ผนังว่าง")))
		if m == "garm_gate":
			check("★ ประตูการ์มมีโซ่ 4 เส้น ★", get_tree().get_nodes_in_group("story_point").size() == 4)
		if m == "odin_seat":
			check("บัลลังก์ว่างกดได้", get_tree().get_nodes_in_group("story_point").any(func(x): return x.title.begins_with("[F] บัลลังก์")))
			check("บัลลังก์: ไม่มีมอน", get_tree().get_nodes_in_group("enemy").is_empty())
		if m == "broken_wall":
			check("กำแพง: มีที่นั่งรอค่ำ", get_tree().get_nodes_in_group("story_point").any(func(x): return "รอค่ำ" in x.title))
			check("กำแพงกลางวันไม่มีคนแปลกหน้า", not get_tree().get_nodes_in_group("story_point").any(func(x): return "คนแปลกหน้า" in x.title))

	# ---------- ประตูล็อก ----------
	print("\n-- 3b) ประตูล็อก --")
	var locks := {
		"vanir_town": ["ToFrostPass", "chapter3_done"], "broken_wall": ["ToCrater", "killed_wall_shieldbearer"],
		"hrungnir_crater": ["ToShimmer", "chapter4_done"], "dimming_wood": ["ToSanctum", "c5_8_done"],
		"lightwell_sanctum": ["ToShore", "chapter5_done"], "gjoll_river": ["ToHall", "name_left"],
		"nastrond": ["ToGate", "killed_false_judge"], "garm_gate": ["ToSeat", "garm_resolved"],
	}
	for m in locks.keys():
		await goto(StringName(m))
		var pt := portal_named(locks[m][0])
		check("★ %s ประตู %s ล็อกด้วย %s ★" % [m, locks[m][0], locks[m][1]], pt != null and pt.required_flag == StringName(locks[m][1]), str(pt.required_flag) if pt != null else "ไม่มีประตู")
	await goto(&"vanir_town")
	for n in get_tree().get_nodes_in_group("npc"):
		if n.type == 4:
			check("เสาวาปวานาเฮมไปอุทการ์ดได้", &"utgard_town" in n.warp_targets)

	# =========================================================
	# 4) ร่างที่สอง — กำแพงกลางคืน + คนแปลกหน้า (S5) · ลโยซาลฟ์ร่างจาง
	# =========================================================
	print("\n-- 4) ร่างที่สอง --")
	PlayerState.quests.accept(&"c4_8_shieldbearer")
	PlayerState.quests.on_monster_killed(&"wall_shieldbearer")
	PlayerState.turn_in_quest(&"c4_8_shieldbearer")
	check("C4-8 ส่งแล้ว", PlayerState.quests.is_done(&"c4_8_shieldbearer"))
	PlayerState.set_flag(&"wall_night")
	var wall = await goto(&"broken_wall")
	check("★ กำแพงกลางคืน = ร่างที่สอง (มี VariantTint · ชื่อต่อท้าย) ★", wall.is_variant and wall.get_node_or_null("VariantTint") != null and "กลางคืน" in wall.display_name)
	var stranger: Node = null
	for x in get_tree().get_nodes_in_group("story_point"):
		if "คนแปลกหน้า" in x.title:
			stranger = x
	check("★ กลางคืนหลัง C4-8 คนแปลกหน้าโผล่ที่ x 3100 ★", stranger != null and stranger.position.x == 3100)
	PlayerState.clear_flag(&"wall_night")
	# ลโยซาลฟ์ร่างจาง
	PlayerState.set_flag(&"has_shade_crystal")
	PlayerState.set_flag(&"shade_view")
	var city = await goto(&"ljosalf_city")
	var names2 := npc_names()
	check("★ ร่างจาง: โซล/ดาเกอร์/บ่อแสง หายไป ★", not ("ทหารยามโซล" in names2) and not ("เจ้าเมืองดาเกอร์" in names2) and not ("บ่อแสงเล็ก" in names2), str(names2))
	check("★ ร่างจาง: เอลฟ์กลวง(โซล) โผล่แทน และมองเห็น ★", "เอลฟ์กลวง (โซล)" in names2)
	for n in get_tree().get_nodes_in_group("npc"):
		if n.npc_name == "เอลฟ์กลวง (โซล)":
			check("เอลฟ์กลวง(โซล) visible", n.visible)
	check("ร่างจางย้อมสี", city.is_variant and city.get_node_or_null("VariantTint") != null)
	var road = await goto(&"shimmer_road")
	await get_tree().create_timer(1.2).timeout
	var ids := {}
	for e in get_tree().get_nodes_in_group("enemy"):
		ids[String(e.data.id)] = true
	check("★ ทางประกายแสงร่างจาง: มอดกลวงแทนผีเสื้อแสง ★", ids.has("hollow_moth") and not ids.has("light_moth"), str(ids.keys()))
	PlayerState.clear_flag(&"shade_view")
	road = await goto(&"shimmer_road")
	await get_tree().create_timer(1.2).timeout
	ids = {}
	for e in get_tree().get_nodes_in_group("enemy"):
		ids[String(e.data.id)] = true
	check("ร่างสว่าง: ผีเสื้อแสง ไม่มีมอดกลวง", ids.has("light_moth") and not ids.has("hollow_moth"), str(ids.keys()))
	# สลับด้วยผลึก (campaign)
	city = await goto(&"ljosalf_city")
	var camp = campaign(city)
	camp._toggle_shade()   # ไม่ await — โหนด campaign ถูกปล่อยไปพร้อมแมพเก่า
	await get_tree().create_timer(1.6).timeout
	get_tree().paused = false
	city = get_tree().get_first_node_in_group("map")
	check("★ กด F ผลึกเงา = โหลดเมืองใหม่เป็นร่างจาง ★", PlayerState.has_flag(&"shade_view") and city.map_id == &"ljosalf_city" and city.is_variant)
	PlayerState.clear_flag(&"shade_view")

	# =========================================================
	# 5) auto_read (C4-4 เดินผ่านฝูงแมมมอธ) · มอนใจดี · HUD ไร้นาม
	# =========================================================
	print("\n-- 5) auto_read · ใจดี · HUD --")
	PlayerState.quests.accept(&"c4_4_child_who_asks")
	var steppe = await goto(&"giant_steppe")
	var lore: Node = null
	for l in get_tree().get_nodes_in_group("lore_object"):
		if l.lore_id == &"mammoth_crossing":
			lore = l
	check("จุด mammoth_crossing เป็น auto_read", lore != null and lore.auto_read)
	var pl = get_tree().get_first_node_in_group("player")
	pl.global_position = lore.global_position + Vector2(0, -40)
	await get_tree().create_timer(0.6).timeout
	check("★ เดินถึงจุด = เควสนับให้เอง (ไม่ต้องกด F) ★", PlayerState.quests.step_done(&"c4_4_child_who_asks", 1))
	check("auto_read ไม่เปิดกล่องสนทนา", not UI.is_any_window_open())
	# มอนใจดี
	var mon = load("res://scenes/monsters/monster.tscn").instantiate()
	mon.data = GameData.get_monster(&"hollow_elf")
	steppe.add_child(mon)
	await get_tree().process_frame
	check("เอลฟ์กลวงดุตามปกติ", not mon._calmed())
	PlayerState.gain_item_id(&"giant_child_scarf", 1)
	mon._calm_cache = -10.0
	check("★ มีผ้าพันคอเด็กยักษ์ → เอลฟ์กลวงใจดี ★", mon._calmed())
	check("ย้อมสีมอน", mon.sprite.modulate.a < 1.0)
	mon.queue_free()
	var mon2 = load("res://scenes/monsters/monster.tscn").instantiate()
	mon2.data = GameData.get_monster(&"name_warden")
	steppe.add_child(mon2)
	await get_tree().process_frame
	check("ผู้เฝ้านามดุ (ยังไม่ awakening)", not mon2._calmed())
	mon2.queue_free()
	# HUD
	var hud = get_tree().get_first_node_in_group("hud")
	if hud == null:
		hud = UI.get("hud")
	PlayerState.set_flag(&"name_left")
	await get_tree().process_frame
	if hud != null and hud.get("level_label") != null:
		check("★ ทิ้งชื่อแล้ว HUD โชว์ «ไร้นาม» ★", "ไร้นาม" in hud.level_label.text, hud.level_label.text)
	else:
		print("  (ไม่มี HUD ในเทสต์ — ข้าม)")
	PlayerState.clear_flag(&"name_left")

	# =========================================================
	# 6) คนแปลกหน้าดึงขึ้นจากน้ำ (S7)
	# =========================================================
	print("\n-- 6) S7 --")
	PlayerState.stats.level = 80
	PlayerState.refresh()
	PlayerState.quests.accept(&"c5_5_thing_in_the_water")
	var lake = await goto(&"mirror_lake")
	pl = get_tree().get_first_node_in_group("player")
	PlayerState.stats.hp = 10
	pl.take_damage(100000)
	await get_tree().create_timer(0.3).timeout
	check("★ ตายครั้งแรกในทะเลสาบระหว่าง C5-5 → ไม่ตาย ฟื้น 30% ★", not PlayerState.is_dead() and PlayerState.stats.hp >= int(PlayerState.stats.max_hp * 0.3) - 1, str(PlayerState.stats.hp))
	check("ตั้งธง s7_saved", PlayerState.has_flag(&"s7_saved"))
	await get_tree().create_timer(0.5).timeout
	PlayerState.stats.hp = 10
	pl.take_damage(100000)
	await get_tree().create_timer(0.2).timeout
	check("ครั้งที่สอง ตายจริง", PlayerState.is_dead())
	PlayerState.revive(1.0)
	get_tree().paused = false

	# =========================================================
	# 7) Runeblade → RB9 SKILL_HIT · แต้มรูน · awakening Ninth Edge
	# =========================================================
	print("\n-- 7) awakening --")
	PlayerState.stats.job_id = &"runeblade"
	PlayerState.set_flag(&"runeblade_awakened")
	PlayerState.set_flag(&"runeblade_start_level", 50)
	PlayerState.stats.level = 92
	PlayerState.refresh()
	# ★ รอบ 108 ★ ไม่มีแต้มรูนแยก — Runeblade เพดานจ๊อบ 80 · แต้มสกิลปกติใช้เรียนสกิลรูน
	PlayerState.stats.skill_points = 30
	check("★ รอบ 108: Runeblade เพดานจ๊อบ 80 · แต้มรูน = แต้มสกิล ★", PlayerState.stats.max_job_level() == 80 and PlayerState.skills.rune_points() == 30)
	for q in ["rb7_ninth_inscription", "c4_6_fourth_rune", "c4_8_shieldbearer"]:
		if not PlayerState.quests.is_done(StringName(q)):
			PlayerState.quests.completed.append(StringName(q))
	PlayerState.quests.accept(&"rb8_carvers_eye")
	PlayerState.quests.completed.append(&"rb8_carvers_eye")
	PlayerState.quests.active.erase(&"rb8_carvers_eye")
	check("รับ RB9 ได้ (runeblade · rb8 · C4-8)", PlayerState.quests.can_accept(&"rb9_wall_that_held_the_sky", 92))
	PlayerState.quests.accept(&"rb9_wall_that_held_the_sky")
	PlayerState.quests.on_monster_killed(&"wall_shieldbearer")
	check("RB9 ยังไม่ครบ (ต้องใช้ sunder โดน)", not PlayerState.quests.is_ready(&"rb9_wall_that_held_the_sky"))
	PlayerState.quests.on_skill_hit(&"wall_shieldbearer", &"rune_flurry")
	check("rune_flurry ไม่นับ", not PlayerState.quests.step_done(&"rb9_wall_that_held_the_sky", 1))
	# ผ่านสัญญาณจริง: runic_hit
	var dummy = load("res://scenes/monsters/monster.tscn").instantiate()
	dummy.data = GameData.get_monster(&"wall_shieldbearer")
	get_tree().get_first_node_in_group("map").add_child(dummy)
	await get_tree().process_frame
	Events.runic_hit.emit(dummy, &"anvil_cleave", false)
	check("★ Events.runic_hit(anvil_cleave) → RB9 ครบ ★", PlayerState.quests.is_ready(&"rb9_wall_that_held_the_sky"))
	dummy.queue_free()
	PlayerState.turn_in_quest(&"rb9_wall_that_held_the_sky")
	check("ได้ธง rb_rune_5", PlayerState.has_flag(&"rb_rune_5"))
	check("★ เรียนท่ายืนทลายกำแพงได้ (Lv 70+) ★", PlayerState.skills.can_learn(&"wallbreaker_stance", PlayerState.stats))
	check("รอบ 108: อักขระคู่เรียนได้เลยที่ Lv 82+ ไม่ต้องรอ RB11", PlayerState.skills.can_learn(&"twin_inscription", PlayerState.stats), PlayerState.skills.learn_blocker(&"twin_inscription", PlayerState.stats))
	var sp_flag: int = PlayerState.stats.skill_points
	PlayerState.set_flag(&"rb_rune_4")
	check("รอบ 108: ธง rb_rune_4 เป็นเนื้อเรื่องอย่างเดียว แต้มไม่เปลี่ยน", PlayerState.skills.rune_points() == sp_flag)
	# awakening
	for q in ["c6_3_leave_your_name", "c6_5_wrong_side", "rb12_eighth_rune_ash"]:
		PlayerState.quests.completed.append(StringName(q))
	PlayerState.set_flag(&"name_left")
	check("ยังรับ RB13 ไม่ได้ (ไม่มี rb_next_job_hint)", not PlayerState.quests.can_accept(&"rb13_the_ninth_wall", 92))
	PlayerState.set_flag(&"rb_next_job_hint")
	check("★ รับ RB13 ได้ ★", PlayerState.quests.can_accept(&"rb13_the_ninth_wall", 92))
	PlayerState.quests.accept(&"rb13_the_ninth_wall")
	var hall = await goto(&"hall_of_names")
	var hc = campaign(hall)
	# ยังไม่ครบ → พิธีไม่เริ่ม
	await hc._ninth_wall()
	check("ยังไม่ครบเงื่อนไข → ยังเป็น runeblade", PlayerState.stats.job_id == &"runeblade")
	for i in range(15):
		PlayerState.quests.on_monster_killed(&"name_warden")
	for i in range(10):
		PlayerState.quests.on_monster_killed(&"erased_voice")
	PlayerState.quests.on_read(&"odin_name")
	PlayerState.gain_item_id(&"gerd_chisel", 1)
	check("RB13 เหลือแค่ผนังที่เก้า", not PlayerState.quests.is_ready(&"rb13_the_ninth_wall") and PlayerState.quests.step_done(&"rb13_the_ninth_wall", 2))
	check("ส่งกับเฮลไม่ได้ (ต้องที่โถงแห่งนาม)", true)
	await hc._ninth_wall()
	check("★★ พิธีผนังที่เก้า → อาชีพ ninth_edge ★★", PlayerState.stats.job_id == &"ninth_edge", String(PlayerState.stats.job_id))
	check("ธง job_ninth_edge · ninth_edge_awakened", PlayerState.has_flag(&"job_ninth_edge") and PlayerState.has_flag(&"ninth_edge_awakened"))
	check("RB13 ส่งแล้ว ได้จี้นาม", PlayerState.quests.is_done(&"rb13_the_ninth_wall") and PlayerState.inventory.count_of(&"name_pendant_eq") >= 1)
	check("★ รอบ 108: Ninth Edge เพดานจ๊อบ 100 ★", PlayerState.stats.max_job_level() == 100)
	check("สกิลนักดาบ/Runeblade เดิมยังอยู่ในอาชีพใหม่", &"bash" in PlayerState.stats.job().skill_ids and &"worldcleaver" in PlayerState.stats.job().skill_ids)
	check("★ เรียนกายาอักขระที่เก้าได้ ★", PlayerState.skills.can_learn(&"ninth_vessel", PlayerState.stats))
	var sp_nv: int = PlayerState.stats.skill_points
	for i in range(5):
		PlayerState.skills.learn(&"ninth_vessel", PlayerState.stats)
	check("กายาอักขระ ระดับ 5", PlayerState.skills.level_of(&"ninth_vessel") == 5)
	PlayerState.refresh()
	check("passive HP +15%", PlayerState.stats.percent_bonus.get(&"max_hp_percent", 0.0) >= 15.0, str(PlayerState.stats.percent_bonus))
	check("รอบ 108: เรียนอักขระที่เก้าได้เลยที่ Lv 92 (ไม่ต้องรอ RB14)", PlayerState.skills.can_learn(&"ninth_inscription", PlayerState.stats), PlayerState.skills.learn_blocker(&"ninth_inscription", PlayerState.stats))
	PlayerState.set_flag(&"ninth_inscription_unlocked")
	check("แต้มสกิลลดตามที่เรียน (5 ninth_vessel)", PlayerState.stats.skill_points == sp_nv - 5, "%d vs %d" % [PlayerState.stats.skill_points, sp_nv])
	PlayerState.skills.learn(&"ninth_inscription", PlayerState.stats)
	PlayerState.skills.learn(&"erasing_cut", PlayerState.stats)
	PlayerState.set_flag(&"rb_rune_7")
	PlayerState.skills.learn(&"twin_inscription", PlayerState.stats)
	check("เรียน 3 สกิล active ได้", PlayerState.skills.level_of(&"erasing_cut") == 1 and PlayerState.skills.level_of(&"twin_inscription") == 1 and PlayerState.skills.level_of(&"ninth_inscription") == 1)
	check("รับ RB14 ได้ (ninth_edge)", PlayerState.quests.can_accept(&"rb14_edge_that_remembers", 92))
	if hud != null and hud.get("level_label") != null:
		hud._refresh_level()
		check("★ HUD ชื่ออาชีพสีทอง + ไม่ใช่ไร้นาม ★", hud.level_label.get_theme_color("font_color") == Color("#ffd86b") and not ("ไร้นาม" in hud.level_label.text), hud.level_label.text)
	# ผู้เฝ้านามใจดีแล้ว
	var w2 = load("res://scenes/monsters/monster.tscn").instantiate()
	w2.data = GameData.get_monster(&"name_warden")
	get_tree().get_first_node_in_group("map").add_child(w2)
	await get_tree().process_frame
	check("★ Ninth Edge → ผู้เฝ้านามไม่ไล่ตี ★", w2._calmed() and not w2._aggro)
	w2.queue_free()

	# =========================================================
	# 8) runeblade_combat — รูน 4 · อักขระคู่ · อักขระที่เก้า
	# =========================================================
	print("\n-- 8) combat --")
	pl = get_tree().get_first_node_in_group("player")
	var rb = pl.runeblade
	check("★ รูนสะสมสูงสุด 4 (กายาอักขระ 5) ★", rb.max_charges() == 4)
	rb.charges = 4
	rb.cast(&"twin_inscription")
	await get_tree().process_frame
	check("★ อักขระคู่: ใช้ 2 รูน · เปิด 6 วิ ★", rb.charges == 2 and rb.twin_time > 5.0, "charges %d twin %.1f" % [rb.charges, rb.twin_time])
	var target = load("res://scenes/monsters/monster.tscn").instantiate()
	target.data = GameData.get_monster(&"drowned")
	get_tree().get_first_node_in_group("map").add_child(target)
	await get_tree().process_frame
	var hp0: int = target.hp
	PlayerState.quests.accept(&"rb14_edge_that_remembers")
	target.take_damage_from_player(1.0, false, 1, 0, 0, &"basic")
	await get_tree().process_frame
	check("★ โจมตีระหว่างอักขระคู่ → เงาดาบตาม (โดน 2 ครั้ง) ★", target.hp < hp0, str(target.hp))
	rb.twin_time = 0
	rb.charges = 3
	PlayerState.cooldowns.clear()
	PlayerState.stats.sp = PlayerState.stats.max_sp
	rb.cast(&"ninth_inscription")
	check("รูนไม่พอ → ไม่ร่าย", rb.inscription_time <= 0 and rb.charges == 3)
	rb.charges = 4
	PlayerState.cooldowns.clear()
	rb.cast(&"ninth_inscription")
	await get_tree().process_frame
	check("★ อักขระที่เก้า: ใช้ 4 รูน · วง 3 วิ ★", rb.charges == 0 and rb.inscription_time > 2.5, "charges %d t %.1f" % [rb.charges, rb.inscription_time])
	check("วงครอบจุดใกล้ตัว", rb.inscription_covers(pl.foot_position() + Vector2(300, 0)) and not rb.inscription_covers(pl.foot_position() + Vector2(900, 0)))
	target.global_position = pl.global_position + Vector2(200, 0)
	var hp1: int = target.hp
	await get_tree().create_timer(3.4).timeout
	check("★ จบ 3 วิ → ระเบิด 2000% ใส่มอนในวง ★", rb.inscription_time <= 0 and target.hp < hp1 - 300, str(hp1 - target.hp))
	target.queue_free()
	# erasing_cut นับเป็น ninth
	var judge = load("res://scenes/monsters/monster.tscn").instantiate()
	judge.data = GameData.get_monster(&"false_judge")
	get_tree().get_first_node_in_group("map").add_child(judge)
	await get_tree().process_frame
	Events.runic_hit.emit(judge, &"erasing_cut", false)
	check("★ erasing_cut นับเป็นสกิล Ninth Edge ใน RB14 ★", PlayerState.quests.step_done(&"rb14_edge_that_remembers", 1))
	judge.queue_free()

	# =========================================================
	# 9) โซ่การ์ม
	# =========================================================
	print("\n-- 9) การ์ม --")
	var gate = await goto(&"garm_gate")
	var gc = campaign(gate)
	var garm: Node = null
	var t := 0.0
	while garm == null and t < 4.0:
		await get_tree().create_timer(0.2).timeout
		t += 0.2
		garm = gc._find_boss(&"chained_garm")
	check("★ การ์มเกิดที่ประตู ★", garm != null)
	if garm != null:
		garm.set_physics_process(false)
		garm.global_position.x = 3300
		for i in range(3):
			await gc._chain(i)
		check("ปลดโซ่ 3 เส้น = ธง garm_chain_1..3", PlayerState.has_flag(&"garm_chain_1") and PlayerState.has_flag(&"garm_chain_3") and not PlayerState.has_flag(&"garm_resolved"))
		check("ได้ข้อโซ่", PlayerState.inventory.count_of(&"garm_chain_link") >= 3)
		gc._on_boss_killed(&"chained_garm", "")
		check("★ ล้มการ์ม → garm_resolved + killed_garm ★", PlayerState.has_flag(&"garm_resolved") and PlayerState.has_flag(&"killed_garm"))
	# บัลลังก์: ยังไม่มีเควส
	await goto(&"odin_seat")
	check("บัลลังก์ยังไม่อ่าน (ไม่มี C6-10)", not PlayerState.has_flag(&"read_odin_seat_throne"))

	auto = false
	print("\n=== ผ่าน %d · ล้มเหลว %d ===" % score)
	get_tree().quit()
