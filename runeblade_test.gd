extends Node2D
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else: print("PASS: ",message)
func _ready() -> void:
	PlayerState.new_game()
	check(GameData.get_job(&"swordsman").job_change_level == 50,"swordsman promotion level 50")
	check(GameData.get_job(&"runeblade").job_change_level == 90 and GameData.get_job(&"runeblade").next_job_ids == [&"ninth_edge"],"level 90 leads to Ninth Edge (round 105)")   # รอบ 105: อาชีพขั้น 3 ทำแล้ว
	for i in range(1,8):
		var found := false
		for id in GameData.quests:
			if String(id).begins_with("rb%d_"%i): found = true
		check(found,"quest chapter R%d loads"%i)
	check(not PlayerState.quests.can_accept(&"rb1_unsung_iron",50),"chapter 2 completion required")
	PlayerState.quests.completed.append(&"c2_8_hammer_truth")
	PlayerState.set_flag(&"chapter2_done")
	check(PlayerState.quests.can_accept(&"rb1_unsung_iron",40),"foreshadowing starts before level 50")
	PlayerState.quests.accept(&"rb1_unsung_iron")
	PlayerState.quests.on_talked_to("ผู้อาวุโสญอร์ดา")
	check(PlayerState.turn_in_quest(&"rb1_unsung_iron"),"first quest can complete in chapter 3")
	PlayerState.quests.completed.append(&"rb4_edge_and_force")
	check(not PlayerState.quests.can_accept(&"rb5_oath_eater",49),"dungeon quest rejects level 49")
	check(PlayerState.quests.can_accept(&"rb5_oath_eater",50),"dungeon quest accepts level 50")
	PlayerState.quests.accept(&"rb5_oath_eater")
	PlayerState.set_flag(&"killed_baphomet")
	check(not PlayerState.quests.is_ready(&"rb5_oath_eater"),"old chapter 1 boss kills cannot skip new dungeon")
	PlayerState.set_flag(&"rb_baphomet_defeated")
	PlayerState.set_flag(&"rb_core_freed")
	check(PlayerState.quests.is_ready(&"rb5_oath_eater"),"dungeon win and liberated core complete objectives")
	PlayerState.turn_in_quest(&"rb5_oath_eater")
	PlayerState.quests.accept(&"rb6_runeblade")
	PlayerState.quests.on_read(&"rb_ceremony")
	PlayerState.stats.level = 50
	PlayerState.current_map_id = &"silver_marsh"
	check(not PlayerState.turn_in_quest(&"rb6_runeblade"),"promotion cannot finish outside chapter 3 town")
	PlayerState.current_map_id = &"vanir_town"
	PlayerState.stats.job_level=47
	check(PlayerState.turn_in_quest(&"rb6_runeblade") and PlayerState.stats.job_id == &"runeblade","ceremony awards Runeblade")
	check(PlayerState.stats.job_level==1 and PlayerState.stats.job_exp_current==0 and PlayerState.stats.skill_points==0,"ceremony starts fresh Runeblade Job 1 after applying quest rewards")
	check(PlayerState.stats.profession_state(&"swordsman")["level"]==47,"ceremony archives earned Swordsman job progression")
	# ★ รอบ 108 ★ ไม่มีแต้มรูนแยก — สกิลรูนใช้แต้มสกิลปกติ · เพดานจ๊อบ Runeblade 80
	PlayerState.stats.skill_points = 5
	check(PlayerState.skills.rune_points()==5,"rune points are the ordinary skill points (round 108)")
	var ordinary := PlayerState.stats.skill_points
	check(PlayerState.skills.learn(&"blade_rhythm",PlayerState.stats),"can learn rune branch")
	check(PlayerState.stats.skill_points==ordinary-1 and PlayerState.skills.rune_points()==4,"rune skill spends the ordinary point budget (round 108)")
	PlayerState.stats.level = 75
	check(PlayerState.stats.max_job_level()==80 and PlayerState.stats.job_exp_to_next()>0,"job cap extends to 80 for Runeblade (round 108)")
	PlayerState.stats.skill_points = 29
	PlayerState.skills.learned[&"blade_rhythm"] = 5
	PlayerState.skills.learned[&"keen_inscription"] = 5
	PlayerState.skills.learned[&"rune_flurry"] = 5
	check(PlayerState.skills.can_learn(&"unbroken_edge",PlayerState.stats),"15 branch points unlock ultimate")
	PlayerState.skills.learned[&"worldcleaver"] = 1
	check(PlayerState.skills.can_learn(&"unbroken_edge",PlayerState.stats),"both ultimate nodes can be learned within the profession point budget")
	PlayerState.skills.learned.erase(&"worldcleaver")
	PlayerState.skills.learned[&"bash"] = 5
	PlayerState.skills.hotkeys[0] = &"bash"
	var before_reset := PlayerState.stats.skill_points
	check(PlayerState.skills.reset_runeblade() and PlayerState.skills.level_of(&"bash")==5 and PlayerState.skills.hotkey_at(0)==&"bash","branch reset preserves old skills and hotkeys")
	check(PlayerState.stats.skill_points==before_reset+15,"branch reset refunds 15 ordinary points (round 108)")
	PlayerState.stats.skill_points = 30
	var saved := PlayerState.to_dict()
	PlayerState.from_dict(saved)
	check(PlayerState.stats.job_id==&"runeblade" and PlayerState.has_flag(&"rb_core_freed") and PlayerState.skills.rune_points()==30,"save round trip preserves promotion and dungeon flags")
	var monster := load("res://data/monsters/baphomet.tres") as MonsterData
	PlayerState.stats.crit = 100
	var heavy := Combat.player_hits_monster(PlayerState.stats,monster,14,false,0,false,0.25)
	check(not heavy.crit,"heavy damage cannot crit even with 100 percent crit")
	var map = load("res://scenes/maps/blackhorn_rootcrypt.tscn").instantiate()
	PlayerState.set_flag(&"rb_trials")
	add_child(map)
	await get_tree().physics_frame
	check(map.player != null and map.map_id==&"blackhorn_rootcrypt","dungeon scene spawns player")
	check(map.boss==null,"saved dungeon victory does not respawn boss")
	var summoned = map._spawn(true,Vector2(600,790),true)
	check(summoned.data.exp_reward==0 and summoned.data.drops.is_empty() and summoned.data.zeny_max==0,"summoned juniors have no farming rewards")
	check(summoned.data.job_exp()==0,"summoned juniors do not grant job EXP either")
	var player = map.player
	PlayerState.skills.learned[&"rune_guard"] = 5
	PlayerState.stats.sp = 100
	PlayerState.cooldowns.clear()
	player.runeblade.cast(&"rune_guard")
	check(player.runeblade.shield>0 and PlayerState.stats.sp==88,"guard spends SP and grants shield")
	var shield: int = player.runeblade.shield
	check(player.runeblade.absorb(shield+10)==10 and player.runeblade.shield==0,"guard absorbs only its remaining amount")
	PlayerState.skills.learned[&"worldcleaver"] = 1
	var sp: int = PlayerState.stats.sp
	player.runeblade.cast(&"worldcleaver")
	check(PlayerState.stats.sp==sp and PlayerState.skill_cooldown_left(&"worldcleaver")==0,"ultimate with no runes spends nothing")
	PlayerState.gm_god_mode = true
	var victim = map._spawn(true,player.position+Vector2(100,0),true)
	player.facing = 1
	player._update_facing()
	victim.set_physics_process(false)
	victim.position.y += 900.0-victim.foot_position().y
	victim.hp = 1000000
	victim.data.flee = -1000 # Isolate skill behavior from enemy evasion; the global miss cap still applies.
	var hits := {"count":0,"crit":false}
	Events.runic_hit.connect(func(target,source,critical):
		if target==victim and source in [&"rune_flurry",&"anvil_cleave",&"faultline",&"worldcleaver"]:
			hits.count += 1
			hits.crit = hits.crit or critical)
	PlayerState.skills.learned[&"rune_flurry"] = 5
	PlayerState.stats.sp = 100
	player.runeblade.charge_lock = 0
	player.runeblade.cast(&"rune_flurry")
	await get_tree().create_timer(0.7).timeout
	check(hits.count>0 and hits.count<=6 and player.runeblade.charges==1,"Flurry lands up to six hits (accuracy applies) but generates one rune: %d"%hits.count)
	for id in [&"anvil_cleave",&"faultline",&"worldcleaver"]:
		PlayerState.skills.learned[id] = 5
		hits.count = 0
		hits.crit = false
		for attempt in range(8):
			PlayerState.stats.sp = 100
			PlayerState.cooldowns.clear()
			player.runeblade.charges = 3
			player.runeblade.cast(id)
			await get_tree().create_timer(3.1 if id == &"faultline" else (2.0 if id == &"worldcleaver" else 1.1)).timeout
			if hits.count > 0: break
		var expected_max := 6 if id == &"faultline" else (5 if id == &"worldcleaver" else 1)
		check(hits.count>0 and hits.count<=expected_max and not hits.crit,"heavy skill obeys per-cast hit budget without crit: %s hits=%d crit=%s player=%s victim=%s"%[id,hits.count,hits.crit,player.position,victim.position])
	check(player.runeblade.charges==0,"Worldcleaver spends all three runes without generating them back")
	check(not player.is_attacking and not player.runeblade.casting,"heavy recovery restores controls")
	map.queue_free()
	await get_tree().process_frame
	PlayerState.clear_flag(&"rb_baphomet_defeated")
	map = load("res://scenes/maps/blackhorn_rootcrypt.tscn").instantiate()
	add_child(map)
	check(is_instance_valid(map.boss) and is_equal_approx(map.boss.foot_position().y,900),"fresh dungeon spawns Baphomet on the floor")
	map.player.position.x = 4900
	map.fighting = true
	map.boss.hp = 10000
	map.next_adds = 0
	await get_tree().create_timer(1.5).timeout
	var alive_adds := 0
	for jr in get_tree().get_nodes_in_group("rb_jr"):
		if jr.get_meta("rb_add",false) and not jr.is_dead(): alive_adds += 1
	check(alive_adds==3,"final phase summons at most three juniors after a warning")
	map.boss.take_damage(999999)
	check(PlayerState.has_flag(&"rb_baphomet_defeated") and not map.fighting,"actual boss death persists dungeon victory")
	map.queue_free()
	await get_tree().process_frame
	map = load("res://scenes/maps/vanir_town.tscn").instantiate()
	add_child(map)
	var njorda: NPC
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.npc_name=="ผู้อาวุโสญอร์ดา": njorda=npc
	check(njorda != null and &"rb6_runeblade" in njorda.quest_ids,"chapter 3 elder receives the promotion quests")
	map.queue_free()
	await get_tree().process_frame
	map = load("res://scenes/maps/runeblade_training.tscn").instantiate()
	add_child(map)
	await get_tree().physics_frame
	var trainer: Node
	for child in map.get_children():
		if child.get_script() == load("res://scripts/world/runeblade_campaign.gd"): trainer = child
	check(map.player != null and trainer != null,"training courtyard loads with player and instructor")
	trainer._begin_training(0)
	check(is_equal_approx(trainer.dummy.foot_position().y,900),"training dummy stands on the floor")
	for combo in range(3):
		trainer._combo(2,"Attack",1.0)
		trainer._trial_hit(trainer.dummy,100,false)
	check(PlayerState.has_flag(&"rb_trial_rhythm"),"three landed finishers complete rhythm trial")
	await get_tree().process_frame
	trainer._begin_training(1)
	trainer._skill(&"bash",1)
	trainer.opening = 0
	trainer.dummy._wound_time = 5
	trainer._trial_hit(trainer.dummy,100,false)
	check(not PlayerState.has_flag(&"rb_trial_force"),"force trial rejects a hit outside the recovery window")
	trainer.opening = 2
	trainer._trial_hit(trainer.dummy,100,false)
	check(PlayerState.has_flag(&"rb_trial_force"),"wounded target and Bash in recovery complete force trial")
	map.queue_free()
	await get_tree().process_frame
	print("RUNEBLADE: %d checks; failures=%d"%[checks,failures])
	get_tree().quit(1 if failures else 0)
