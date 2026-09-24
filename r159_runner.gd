extends Node
## รอบ 159 — เควส «ใบประกาศใบแรก» (m3_guild_bounty)
var fails := 0
var passes := 0
var rank_opened := 0

func ok(cond: bool, msg: String) -> void:
	if cond:
		passes += 1
		print("  PASS ", msg)
	else:
		fails += 1
		print("  FAIL ", msg)

func _auto() -> void:
	while true:
		await get_tree().create_timer(0.05).timeout
		var d = UI.dialogue
		if d != null and d.is_open():
			if d._waiting_choice:
				d._pick(0)
			else:
				d._advance()

func _ready() -> void:
	await get_tree().process_frame
	_auto()
	Events.guild_rank_opened.connect(func(): rank_opened += 1)
	var q := GameData.get_quest(&"m3_guild_bounty")
	ok(q != null, "โหลดเควส m3_guild_bounty")
	ok(q.steps().size() == 1 and q.steps()[0].kind == ObjectiveData.Kind.FLAG and q.steps()[0].target == &"guild_first_bounty", "เงื่อนไข = FLAG guild_first_bounty")
	ok(q.required_quests == [&"hans_poring"] and q.required_level == 3, "ต้องจบ hans_poring + Lv3")
	ok(GameData.get_item(q.reward_item_id) != null, "ไอเทมรางวัลมีจริง")
	ok(q.cutscene_text.split("\n\n", false).size() >= 5, "คำอธิบายขั้นกิลด์ %d หน้า" % q.cutscene_text.split("\n\n", false).size())
	var m6 := GameData.get_quest(&"m6_ceremony")
	print("  m6 CR=", m6.cutscene_text.count("\r"), " pages=", m6.cutscene_text.split("\n\n", false).size(), " · m3 CR=", q.cutscene_text.count("\r"), " offer pages=", q.dialog_offer.split("\n\n", false).size())
	var scn := load("res://scenes/maps/prontera_town.tscn") as PackedScene
	var st := scn.get_state()
	var found := false
	for i in st.get_node_count():
		if st.get_node_name(i) == "GuildMaster":
			for j in st.get_node_property_count(i):
				if st.get_node_property_name(i, j) == "quest_ids":
					found = &"m3_guild_bounty" in st.get_node_property_value(i, j)
	ok(found, "บียอร์นในพรอนเทรามี m3 ใน quest_ids")

	PlayerState.new_game()
	PlayerState.current_map_id = &"prontera_town"
	var log := PlayerState.quests
	PlayerState.stats.level = 2
	log.completed.append(&"m1_adventurer_badge"); log.completed.append(&"m2_oath")
	ok(not log.can_accept(&"m3_guild_bounty", 3), "ยังไม่จบ hans_poring = รับไม่ได้")
	log.completed.append(&"hans_poring")
	ok(not log.can_accept(&"m3_guild_bounty", 2), "Lv2 = รับไม่ได้")
	PlayerState.stats.level = 3
	ok(log.can_accept(&"m3_guild_bounty", 3), "จบ hans_poring + Lv3 = รับได้")

	var npc = (load("res://scenes/npc/npc.tscn") as PackedScene).instantiate()
	npc.npc_name = "หัวหน้ากิลด์บียอร์น"
	npc.type = 0
	npc.has_bounty_board = true
	npc.quest_ids = [&"m11_king_poring", &"m3_guild_bounty"] as Array[StringName]
	add_child(npc)
	await get_tree().process_frame
	await npc.interact()
	ok(log.is_active(&"m3_guild_bounty"), "คุยบียอร์น → รับ m3 แล้ว")
	ok(not log.is_ready(&"m3_guild_bounty"), "ยังไม่ส่งใบ = ยังไม่ครบ")

	# m11 เปิดระหว่างที่ m3 ค้าง → ต้องเสนอ m11 (ไม่ใช่บอกความคืบหน้า m3 วนไป)
	var saved_completed := log.completed.duplicate()
	for x in [&"tony_fabre", &"m5_old_mine_iron", &"m6_ceremony", &"m7_silent_forest", &"m8_burnt_bark", &"m9_missing_hunter", &"m10_hunter_journal"]:
		log.completed.append(x)
	PlayerState.stats.level = 12
	ok(log.can_accept(&"m11_king_poring", 12), "m11 รับได้ (เตรียม)")
	await npc.interact()
	ok(log.is_active(&"m11_king_poring"), "m3 ค้างอยู่ แต่บียอร์นเสนอ m11 ได้")
	log.active.erase(&"m11_king_poring")
	log.completed = saved_completed
	PlayerState.stats.level = 3

	# ส่งใบประกาศ 1 ใบ
	var board: BountyBoard = PlayerState.bounties
	board.ensure_board(&"prontera_town")
	var spec: Dictionary = board.specs_of(&"prontera_town")[0]
	var bid := StringName(spec["id"])
	ok(log.accept(bid), "รับใบประกาศช่อง 1: %s" % GameData.get_quest(bid).title)
	for i in int(spec["count"]):
		log.on_monster_killed(StringName(spec["monster"]))
	ok(log.is_ready(bid), "ใบประกาศครบ")
	ok(PlayerState.turn_in_quest(bid), "ส่งใบประกาศ")
	ok(PlayerState.has_flag(&"guild_first_bounty"), "ตั้งธง guild_first_bounty")
	ok(log.is_ready(&"m3_guild_bounty"), "m3 พร้อมส่ง")

	var zeny0: int = PlayerState.zeny
	var pots0: int = PlayerState.inventory.count_of(&"red_potion")
	await npc.interact()
	ok(log.is_done(&"m3_guild_bounty"), "ส่ง m3 สำเร็จ")
	ok(PlayerState.zeny - zeny0 == 800, "ได้ 800 z (%d)" % (PlayerState.zeny - zeny0))
	ok(PlayerState.inventory.count_of(&"red_potion") - pots0 == 10, "ได้ยาแดง 10")
	await get_tree().create_timer(0.3).timeout
	ok(rank_opened == 1, "จบเควสแล้วเปิดหน้าขั้นกิลด์ (%d)" % rank_opened)

	# เซฟเก่า: เคยส่งใบประกาศแล้วแต่ไม่มีธง
	var d: Dictionary = PlayerState.to_dict()
	var fl: Dictionary = d["flags"]
	fl.erase("guild_first_bounty")
	d["quests"] = {"active": ["m3_guild_bounty"], "completed": ["hans_poring"], "progress": {}}
	PlayerState.from_dict(d)
	ok(PlayerState.has_flag(&"guild_first_bounty"), "เซฟเก่า (ส่งใบแล้ว) → ได้ธงตอนโหลด")
	var d2: Dictionary = PlayerState.to_dict()
	(d2["flags"] as Dictionary).erase("guild_first_bounty")
	(d2["bounties"] as Dictionary)["total"] = 0
	PlayerState.from_dict(d2)
	ok(not PlayerState.has_flag(&"guild_first_bounty"), "เซฟที่ยังไม่เคยส่งใบ → ไม่มีธง")

	print("R159 RESULT: %d pass · %d fail" % [passes, fails])
	get_tree().quit(1 if fails > 0 else 0)
