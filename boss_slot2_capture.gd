extends Node

# Recording controller: original save stats, equipment, damage and enemy AI.
# Only movement/attack/skill/potion inputs are automated; persistence is isolated.
var OUT := "C:/Users/peeco/Downloads/คลิปsof/บอสหรุงนีร์_เซฟ2/"
var hard_take := false
var arena: Node2D
var actor: Node2D
var boss: Node2D
var clock := 0.0
var frame := 0
var finish_time := -1.0
var pulse_release: Array[String] = []
var skill_wait := 0.0
var dodge_count := 0
var previous_hp := 0
var previous_boss_state := -1
var state_age := 0.0
var pilot := false

func _ready() -> void:
	seed(710021)
	process_mode = Node.PROCESS_MODE_ALWAYS
	pilot = "--pilot" in OS.get_cmdline_user_args()
	hard_take = "--weaker-weapon" in OS.get_cmdline_user_args()
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280,720)
	get_window().content_scale_size = Vector2i(1280,720)
	SaveManager.save_directory = OUT + "save_copy"
	if not SaveManager.load_game(1):
		get_tree().quit(2)
		return
	SaveManager.end_session()
	if hard_take:
		OUT += "ดาบรูน_รอบยาก/"
		DirAccess.make_dir_recursive_absolute(OUT)
		for i in range(PlayerState.INVENTORY_SIZE):
			var item = PlayerState.inventory.get_slot(i)
			if item != null and item.item_id == &"runic_blade":
				print("WEAKER_WEAPON runic_blade refine=",item.refine)
				assert(PlayerState.equip_from_inventory(i))
				break
	PlayerState.gm_god_mode = false
	UI.video_playing = true
	arena = load("res://scenes/maps/hrungnir_crater.tscn").instantiate()
	add_child(arena)
	actor = arena.player
	Events.map_changed.emit(&"hrungnir_crater")
	if arena.has_node("Lore"): arena.get_node("Lore").hide()
	for node in get_tree().root.find_children("*", "Control", true, false):
		if node is HUD: node.quest_block.hide()
	previous_hp = PlayerState.stats.hp
	print("FIGHT_START level=", PlayerState.stats.level, " hp=", PlayerState.stats.hp, "/", PlayerState.stats.max_hp)
	for node in get_tree().root.find_children("*", "Node", true, false):
		var script = node.get_script()
		if script != null and script.resource_path == "res://scripts/entities/character_visual.gd" and node.body != null and node.body.sprite_frames == null:
			node.set_process(false)

func press(action: String) -> void:
	Input.action_press(action)
	pulse_release.append(action)

func move(direction: float) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	if direction < 0: Input.action_press("move_left")
	if direction > 0: Input.action_press("move_right")

func dodge(direction: float) -> void:
	if not actor.can_dodge(): return
	move(direction)
	actor._start_dodge()
	dodge_count += 1
	print("DODGE t=", snappedf(clock,0.01), " dir=", direction)

func cast(slot: int, id: StringName) -> bool:
	if skill_wait > 0 or not PlayerState.can_use_skill(id).get("ok",false): return false
	if id == &"worldcleaver" and actor.runeblade.charges < 3: return false
	actor.use_skill(id)
	skill_wait = 0.65
	return true

func _physics_process(delta: float) -> void:
	for action in pulse_release: Input.action_release(action)
	pulse_release.clear()
	if not is_instance_valid(actor): return
	clock += delta
	frame += 1
	skill_wait = maxf(0,skill_wait-delta)
	Input.action_release("attack")
	if finish_time >= 0:
		move(0)
		if clock-finish_time > 4:
			print("FIGHT_END t=",clock," dodges=",dodge_count)
			get_tree().quit()
		return
	if PlayerState.is_dead():
		print("DEFEAT t=",clock," boss_hp=",boss.hp if is_instance_valid(boss) else -1)
		finish_time = clock
		return
	if not is_instance_valid(boss):
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if enemy.data.id == &"stone_hrungnir": boss = enemy
	if is_instance_valid(boss) and boss.hp <= 0:
		print("VICTORY t=",clock," hp=",PlayerState.stats.hp)
		finish_time = clock
		return
	if frame%300==0:
		print("STATUS t=",snappedf(clock,.1)," hp=",PlayerState.stats.hp," sp=",PlayerState.stats.sp," boss=",boss.hp if is_instance_valid(boss) else -1," x=",actor.position.x)
		if not pilot: snapshot()
	if clock > 180:
		print("TIMEOUT")
		get_tree().quit(3)
		return
	if PlayerState.stats.hp != previous_hp:
		if PlayerState.stats.hp < previous_hp: print("HIT t=",snappedf(clock,.1)," damage=",previous_hp-PlayerState.stats.hp)
		previous_hp = PlayerState.stats.hp
	if not actor.is_attacking and actor._dodge_time <= 0:
		if PlayerState.stats.hp < PlayerState.stats.max_hp*.8 and PlayerState.potion_cooldown_left(&"hp") <= 0:
			PlayerState.use_item_hotkey(0)
			return
		if PlayerState.stats.sp < 50 and PlayerState.potion_cooldown_left(&"sp") <= 0:
			PlayerState.use_item_hotkey(1)
			return
	if not is_instance_valid(boss):
		move(1)
		return
	var dx: float = boss.global_position.x-actor.global_position.x
	var distance := absf(dx)
	var toward := signf(dx)
	if int(boss.state) != previous_boss_state:
		previous_boss_state = int(boss.state)
		state_age = 0
	else: state_age += delta
	# React to the visible windup, then dash across the outgoing shock wave.
	for slam in get_tree().get_nodes_in_group("hrungnir_earthbreak"):
		move(0)
		var late_reaction: bool = hard_take and boss._special_cast_count == 1
		if late_reaction and slam.elapsed > 1.15 and slam.elapsed < 1.2:
			print("MISSED_SLAM_DODGE t=",clock)
		if not late_reaction and slam.elapsed >= 1.05 and slam.elapsed < 1.55 and actor.can_dodge(): dodge(toward)
		if slam.elapsed < 1.8: return
	if boss.state == boss.State.ATTACK:
		move(0)
		if state_age > .1 and actor.can_dodge(): dodge(toward if distance < 340 else -toward)
		return
	if actor.is_attacking or actor._dodge_time > 0: return
	move(toward if distance > 155 else 0)
	# Face the boss through the same directional input used by a player.
	if actor.facing != int(toward):
		move(toward)
		return
	if distance < 540 and boss._skill_cd > 1.1:
		if cast(3,&"worldcleaver"): return
	if distance < 650 and cast(4,&"faultline"): return
	if distance > 190 and distance < 490 and cast(1,&"rune_lunge"): return
	if distance < 260 and boss._attack_timer > .6 and cast(2,&"anvil_cleave"): return
	if distance < 180 and boss._attack_timer > .65 and boss._skill_cd > .9:
		Input.action_press("attack")

func snapshot() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+"fight_%04d.png" % int(clock))

func _exit_tree() -> void:
	for action in ["move_left","move_right","attack","jump","skill_1","skill_2","skill_3","skill_4","quick_potion","quick_sp_potion"]:
		Input.action_release(action)
