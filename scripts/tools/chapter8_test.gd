extends Node
const Tower = preload("res://scripts/world/chapter8_tower_data.gd")
const Pattern = preload("res://scripts/entities/chapter8_pattern.gd")
var checks := 0
var failures := 0
class Target extends Node2D:
	var total := 0
	func foot_position() -> Vector2: return position
	func take_damage(amount: int, _force: float, _direction: int) -> void: total += amount
class Caster extends Node2D:
	var dead := false
	var data: MonsterData
	func foot_position() -> Vector2: return position
	func is_dead() -> bool: return dead
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("C8: " + message)

func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	check(not Tower.can_enter(1), "chapter 7 gate")
	PlayerState.set_flag(&"chapter7_done")
	check(Tower.can_enter(1) and not Tower.can_enter(2), "ordered progression")
	check(not Tower.can_enter(21), "trial stops at 20")
	check(NpcDirectory.map_name_of("สวาลา ผู้เก็บชื่อ", 8) == "อิกดราซิล จุดพักราก", "quest directs to chapter 8 NPC")
	for n in range(1, 21):
		check(ResourceLoader.exists(Game.MAPS[Tower.floor_id(n)]), "map exists %d" % n)
		var packed := load(Game.MAPS[Tower.floor_id(n)]) as PackedScene
		check(packed != null, "map parses %d" % n)
		var source := GameData.get_monster(StringName(Tower.BOSSES[n - 1]))
		var old_hp := source.max_hp
		var old_id := source.id
		var copy := Tower.make_enemy(source, n, true)
		check(copy != source and source.max_hp == old_hp and source.id == old_id, "campaign immutable")
		check(copy.id != source.id and copy.drops.is_empty(), "isolated IDs and rewards")
		check(copy.level == 110 + n and copy.exp_reward == 0, "floor tuning")
		if n > 1:
			var previous := Tower.make_enemy(source, n - 1, true)
			check(copy.max_hp > previous.max_hp and copy.atk_max > previous.atk_max, "monotonic scaling")
		for id in Tower.PACKS[Tower.theme(n)]:
			check(GameData.get_monster(StringName(id)) != null, "pack exists " + id)
		GameData.release_monsters_except([])
	for mode in range(4):
		check(GameData.get_monster(StringName(Tower.NEW_IDS[mode])) != null, "new guardian slot")
		var zones := Pattern.layout(mode, 2000, 2600, 0, false)
		check(zones.size() >= 3, "multi-step boss skill")
		for zone in zones:
			check(zone.at >= 1.35 and zone.rect.size.x > 0, "readable warning")
			check(zone.rect.end.y == 880, "warning touches floor")
	# Run real spawn/death callbacks through both encounter stages and all 4 guardians.
	PlayerState.stats.job_id = &"ninth_edge"
	PlayerState.stats.level = 115
	PlayerState.stats.base_vit = 150
	PlayerState.refresh()
	for n in [1, 5, 10, 15, 20]:
		PlayerState.set_flag(Tower.clear_flag(n - 1))
		var map = load(Game.MAPS[Tower.floor_id(n)]).instantiate()
		add_child(map)
		await get_tree().process_frame
		check(absf(map.player.foot_position().y - 880.0) < 2.0, "C3 feet on collision floor")
		map.player.set_physics_process(false)
		map.player.position.x = 300
		check(map.stage == 1 and map.living >= 3, "regular wave starts")
		for pass_index in range(3 if n % 5 == 0 else 2):
			for actor in map.enemy_container.get_children():
				if actor.is_in_group("enemy") and not actor.is_dead():
					actor.set_physics_process(false)
					actor.take_damage(actor.hp + 1)
			await get_tree().create_timer(2.75).timeout
		check(map.cleared and map.next_portal.required_flag == &"", "clear unlocks exit %d" % n)
		check(PlayerState.has_flag(Tower.clear_flag(n)), "persistent floor completion")
		var zeny := PlayerState.zeny
		map._complete_floor()
		check(PlayerState.zeny == zeny, "idempotent floor rewards")
		map.cleared = false
		map._complete_floor()
		check(PlayerState.zeny == zeny, "saved entitlement prevents replay reward")
		map.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		GameData.release_monsters_except([])
		print("C8 runtime floor ", n, " passed")
	check(PlayerState.has_flag(&"c8_trial20_done") and not PlayerState.has_flag(&"chapter8_done"), "partial chapter only")
	var hub = load(Game.MAPS[&"yggdrasil_root"]).instantiate()
	add_child(hub)
	await get_tree().process_frame
	var destinations: Array[StringName] = []
	for child in hub.get_children():
		if "target_map" in child: destinations.append(child.target_map)
	check(destinations.has(&"yggdrasil_06") and destinations.has(&"yggdrasil_11") and destinations.has(&"yggdrasil_16"), "earned checkpoints restored")
	check(not destinations.has(&"yggdrasil_21"), "no unfinished destination")
	hub.queue_free()
	await get_tree().process_frame
	var target := Target.new()
	target.position = Vector2(2000, 880)
	target.add_to_group("player")
	add_child(target)
	var caster := Caster.new()
	caster.position = Vector2(2600, 880)
	caster.data = Tower.make_enemy(GameData.get_monster(&"c8_root_jailer"), 5, true, true)
	add_child(caster)
	for mode in range(4):
		for rage in [false, true]:
			var fx := Pattern.new()
			fx.caster = caster
			fx.kind = mode
			fx.enraged = rage
			add_child(fx)
			fx.set_physics_process(false)
			fx.zones.sort_custom(func(a,b): return a.at < b.at)
			var zone: Dictionary = fx.zones[0]
			target.position = Vector2(zone.rect.get_center().x, 880)
			var before := target.total
			fx._physics_process(1.0)
			check(target.total == before, "no damage before warning")
			fx._physics_process(0.36)
			check(target.total > before, "warned zone deals damage")
			before = target.total
			fx._physics_process(0.05)
			check(target.total == before, "one hit per impact")
			fx.queue_free()
			await get_tree().process_frame
			target.position = Vector2(2000, 880)
	var fx := Pattern.new()
	fx.caster = caster
	add_child(fx)
	fx.set_physics_process(false)
	var before := target.total
	target.position = Vector2(100, 880)
	fx._physics_process(1.36)
	check(target.total == before, "outside zone safe")
	caster.dead = true
	fx._physics_process(0.1)
	check(fx.done, "caster death cancels hazards")
	target.queue_free()
	caster.queue_free()
	check(not SaveManager._active, "tests never activate real saves")
	var rewards = preload("res://scripts/world/chapter8_rewards.gd")
	PlayerState.new_game()
	PlayerState.inventory = Inventory.new(1)
	PlayerState.inventory.add_id(&"novice_sword", 1)
	PlayerState.set_flag(Tower.clear_flag(5))
	check(rewards.claim_earned(false) == 0, "full bag defers reward")
	check(not PlayerState.has_flag(&"c8_reward_5_c8_root_heart"), "full bag retains entitlement")
	PlayerState.inventory = Inventory.new(40)
	check(rewards.claim_earned(false) == 2, "deferred reward recovered")
	check(rewards.claim_earned(false) == 0, "reward cannot duplicate")
	for n in [10, 15, 20]: PlayerState.set_flag(Tower.clear_flag(n))
	check(rewards.claim_earned(false) == 7, "all other milestone rewards recovered")
	for id in Tower.NEW_IDS:
		var monster := GameData.get_monster(StringName(id))
		var tex := monster.sprite_frames.get_frame_texture(&"Idle", 0)
		check(tex.resource_path.contains("chapter8/runtime"), "unique guardian artwork")
		check(not monster.flying and not monster.fit_fixed_anchor_enabled, "new feet alignment")
		var card := GameData.get_item(StringName("card_" + id)) as CardData
		check(card != null and card.illustration != null and card.icon.get_size() == Vector2(256,256), "card artwork linked")
	PlayerState.stats.level = 130
	PlayerState.set_flag(&"c8_trial20_done")
	PlayerState.add_zeny(60000)
	var recipe := load("res://data/recipes/c8_rootbound_pendant.tres") as RecipeData
	check(recipe.has_materials(PlayerState.inventory), "guardian materials satisfy recipe")
	check(PlayerState.craft(recipe).ok, "pendant craft succeeds")
	check(PlayerState.inventory.count_of(&"c8_rootbound_pendant") == 1, "pendant received")
	check(not PlayerState.craft(recipe).ok, "one-time materials prevent duplicate craft")
	check(not SaveManager._active, "reward test never activates saves")
	print("C8 RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
