extends Node2D
var checks := 0
var failures := 0
var player
var targets: Array = []
var events: Dictionary = {}

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ",label)
	else:
		failures += 1
		push_error(label)

func _ready() -> void:
	get_tree().create_timer(45).timeout.connect(func(): push_error("BALANCE TEST TIMEOUT"); get_tree().quit(1))
	PlayerState.new_game()
	PlayerState.set_process(false)
	PlayerState.stats.job_id = &"runeblade"
	PlayerState.stats.level = 70
	PlayerState.stats.base_str = 70
	PlayerState.stats.base_agi = 60
	PlayerState.stats.base_dex = 50
	PlayerState.stats.base_vit = 40
	PlayerState.equipment.equip(Equipment.EquipSlot.WEAPON, ItemInstance.create(&"frost_edge"))
	PlayerState.refresh()
	PlayerState.gm_god_mode = true
	var equipment_count := 0
	for id in GameData.items:
		var d: ItemData = GameData.items[id]
		if not d.refinable: continue
		equipment_count += 1
		var inst := ItemInstance.create(id)
		var previous := 0
		for rank in range(10):
			inst.refine = rank
			var price := RefineSystem.zeny_cost(inst)
			if price < 1000 or price > 50000 or price < previous:
				check(false,"refine fee range and monotonicity: %s" % id)
			previous = price
		if d.type == ItemData.Type.ARMOR:
			check(d.refine_atk_gain() == 0,"armor refine cannot grant unintended weapon ATK: %s" % id)
	check(equipment_count > 60,"all refinable equipment inspected")
	var sword := ItemInstance.create(&"bone_greatsword")
	var base := sword.total_atk()
	sword.refine = 1
	check(sword.total_atk() - base == 26,"520 ATK sword gains 26 per rank")
	check(RefineSystem.preview(sword).atk_gain == 26,"forge preview matches equipped gain")
	check(RefineSystem.success_rate(sword)==100.0,"early refinement guaranteed")
	check(GameData.get_item(&"phracon").buy_price == 1500,"ore price fits fee budget")
	for a in range(10):
		for d in range(10):
			if Combat.element_modifier(a,d) != 1.0: check(false,"no hidden element resistance")
	check(Combat.element_modifier(0,8)==1.0,"neutral attacks do full damage against ghosts")
	var high := PlayerStats.new()
	high.level = 97
	var frost := GameData.get_monster(&"frost_wolf")
	var reward: Dictionary = frost.experience_for(97)
	check(float(reward.base)/high.exp_to_next()<0.001,"level 97 farming chapter 4 gives under 0.1% per ordinary monster")
	check(frost.experience_for(60).base > reward.base,"level-appropriate fights give better EXP")
	var summon := MonsterData.new()
	summon.exp_reward = 0
	summon.job_exp_reward = 0
	check(summon.experience_for(97)=={"base":0,"job":0},"zero-reward summons stay zero")
	var storm := GameData.get_monster(&"stormscar")
	var storm_drops := []
	for d in storm.drops: storm_drops.append(d.item_id)
	check(&"storm_runeblade" in storm_drops and &"storm_pendant" in storm_drops,"storm boss has both chase items")
	var saved := SkillBook.new()
	saved.from_dict({"learned":{"faultline":5,"worldcleaver":3,"rune_flurry":4,"rune_lunge":2},"hotkeys":["faultline","worldcleaver","rune_flurry","rune_lunge"]})
	check(saved.level_of(&"faultline")==5 and saved.hotkey_at(1)==&"worldcleaver" and saved.level_of(&"rune_lunge")==2,"old and new skill IDs survive serialization")
	PlayerState.equipment.equip(Equipment.EquipSlot.ACCESSORY_1,ItemInstance.create(&"forge_core_pendant"))
	PlayerState.refresh()
	check(PlayerState.stats.skill_damage_percent==10.0,"equipment skill bonus reaches runtime stats")
	player = load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.position = Vector2(400,400)
	player.set_physics_process(false)
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000,40)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(600,580)
	add_child(floor_body)
	for i in range(8):
		var target = load("res://scenes/monsters/monster.tscn").instantiate()
		var data := GameData.get_monster(&"poring").duplicate()
		data.max_hp = 10000000
		data.flee = -1000
		data.exp_reward = 0
		data.zeny_min = 0
		data.zeny_max = 0
		data.drops.clear()
		target.data = data
		add_child(target)
		target.set_physics_process(false)
		target.position = Vector2(510+i*25,player.foot_position().y-data.foot_offset())
		targets.append(target)
	Events.runic_hit.connect(func(_target,source,_critical): events[source]=int(events.get(source,0))+1)
	for id in [&"rune_flurry",&"rune_lunge",&"anvil_cleave",&"faultline",&"worldcleaver"]:
		PlayerState.skills.learned[id] = GameData.get_skill(id).max_level
	# Existing monster damage path: a true skill bonus excludes basics.
	var target = targets[0]
	PlayerState.stats.skill_damage_percent = 0
	var start: int = target.hp
	seed(3456)
	target.take_damage_from_player(1,false,0,0,0,&"anvil_cleave")
	var plain: int = start-target.hp
	PlayerState.stats.skill_damage_percent = 50
	start = target.hp
	seed(3456)
	target.take_damage_from_player(1,false,0,0,0,&"anvil_cleave")
	check(abs((start-target.hp)-plain*1.5)<2,"skill damage bonus applies once to actual monster hit")
	PlayerState.stats.skill_damage_percent = 0
	player.facing = 1
	player._update_facing()
	player.runeblade.set_process(false)
	player.runeblade.charges = 0
	player.runeblade.charge_lock = 0
	prepare()
	player.runeblade.cast(&"rune_flurry")
	# This focused harness drives only the approach physics, with all movement inputs disabled.
	for frame in range(60):
		await get_tree().physics_frame
		if player.runeblade.approach_left > 0: player.runeblade.approach_step(1.0/60)
	check(int(events.get(&"rune_flurry",0)) > 18 and int(events.get(&"rune_flurry",0))<=48,"flurry reaches a full farming pack, up to 8 targets six times")
	check(player.runeblade.charges==1,"multi-target flurry grants only one rune")
	check(not player.is_attacking and not player.runeblade.casting,"flurry restores controls")
	prepare()
	player.runeblade.charges = 0
	player.runeblade.charge_lock = 0
	player.runeblade.cast(&"faultline")
	await get_tree().create_timer(0.65).timeout
	check(not player.is_attacking,"planted blade frees movement before pulses finish")
	var early := int(events.get(&"faultline",0))
	# Another cast serial while the field is active must not grant another rune.
	Events.skill_used.emit(&"bash",1)
	player.runeblade.charge_lock = 0
	await get_tree().create_timer(2.4).timeout
	check(int(events.get(&"faultline",0))>early,"planted blade continues damaging after recovery")
	check(int(events.get(&"faultline",0))>36 and int(events.get(&"faultline",0))<=60,"planted blade reaches the pack and respects ten targets per pulse")
	check(player.runeblade.charges==1,"overlapping skill cannot make a field grant additional runes")
	prepare()
	player.runeblade.charges = 3
	player.runeblade.cast(&"worldcleaver")
	await get_tree().create_timer(2.25).timeout
	check(player.runeblade.charges==0,"rain ultimate consumes 3 runes without refund")
	check(int(events.get(&"worldcleaver",0))>=15,"rain ultimate hits multiple waves")
	check(int(events.get(&"worldcleaver",0))>30 and int(events.get(&"worldcleaver",0))<=60,"rain reaches the pack and respects twelve targets per wave")
	check(not player.is_attacking,"rain ultimate restores controls")
	prepare()
	player.position = Vector2(200,400)
	player.runeblade.cast(&"rune_lunge")
	for frame in range(45):
		await get_tree().physics_frame
		if player._dash_time>0: player._dash_step(1.0/60)
	check(player.position.x>targets[-1].position.x and int(events.get(&"rune_lunge",0))>0,"rune lunge passes through the entire pack without stopping on enemies")
	check(player.runeblade.lunge_followup>0,"landed lunge primes flurry follow-up")
	# A terrain wall blocks both the dash and its forward hit box.
	var wall := StaticBody2D.new()
	var wall_shape := CollisionShape2D.new()
	var wall_rect := RectangleShape2D.new()
	wall_rect.size=Vector2(30,500)
	wall_shape.shape=wall_rect
	wall.add_child(wall_shape)
	wall.position=Vector2(850,350)
	add_child(wall)
	player.position=Vector2(700,400)
	targets[0].position.x=920
	for i in range(1,targets.size()): targets[i].position.x=1100+i*30
	await get_tree().physics_frame
	var blocked_hp: int=targets[0].hp
	prepare()
	player.runeblade.cast(&"rune_lunge")
	for frame in range(45):
		await get_tree().physics_frame
		if player._dash_time>0: player._dash_step(1.0/60)
	check(player.position.x<835 and targets[0].hp==blocked_hp,"dash stops at terrain and cannot damage through it")
	wall.queue_free()
	await get_tree().physics_frame
	# Remaining HP bounds lifesteal; tiny hits cannot round a sub-point drain up to one.
	PlayerState.stats.sp_drain_percent=1.0
	PlayerState.stats.sp=0
	targets[0]._drain_to_player(5)
	check(PlayerState.stats.sp==0,"tiny multi-hits cannot generate free SP by rounding up")
	PlayerState.stats.sp_drain_percent=0.0
	# Effects cannot outlive a dead caster.
	var field := preload("res://scripts/entities/runic_blade_field.gd").new()
	field.configure(player.runeblade,&"faultline",10,targets[0].foot_position(),1)
	add_child(field)
	player._dead = true
	await get_tree().process_frame
	await get_tree().process_frame
	check(not is_instance_valid(field),"death cancels persistent blade field")
	player._dead = false
	# Burns are bounded and do not invoke runic hit signals.
	events.clear()
	start = target.hp
	target._apply_weapon_element(1,100,0)
	for i in range(4): target._tick_burn(1.0)
	check(start-target.hp==60 and events.is_empty(),"burn has exactly 3 ticks and no rune/echo recursion")
	# Lightning must honor a shared lock across a multi-target cast.
	player.set_meta("lightning_ready_ms",0)
	for attempt in range(100):
		target._apply_weapon_element(4,100,0)
		if int(player.get_meta("lightning_ready_ms",0))>0: break
	start = targets[1].hp
	target._apply_weapon_element(4,100,0)
	check(targets[1].hp==start and events.is_empty(),"lightning shared cooldown prevents multi-hit recursion")
	for node in targets: node.queue_free()
	player.queue_free()
	await get_tree().create_timer(0.8).timeout
	print("BALANCE PASS: %d checks; failures=%d"%[checks,failures])
	get_tree().quit(1 if failures else 0)

func prepare() -> void:
	PlayerState.stats.sp = 1000
	PlayerState.cooldowns.clear()
	events.clear()
