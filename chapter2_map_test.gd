## Integration/visual checks in temporary map instances. Never saves player state.
extends Node

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _process(_delta: float) -> void:
	# Keep real spawned quest monsters for event tests, but freeze combat during screenshots.
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.set_physics_process(false)
		enemy.hide()

func finish_dialogue() -> void:
	for press in range(12):
		await get_tree().process_frame
		if not UI.dialogue.is_open():
			return
		UI.dialogue._advance()
	check(not UI.dialogue.is_open(), "Lore dialogue must finish")

func capture(name: String) -> void:
	UI.layer.hide()
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/map_art_next/%s.png" % name)

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	PlayerState.quests = QuestLog.new()
	PlayerState.story_flags.erase(&"killed_forge_guardian")
	PlayerState.story_flags.erase(&"read_hammer_blueprint")
	PlayerState.story_flags.erase(&"chapter2_done")
	PlayerState.respawn_locks.clear()
	for spec in [{"id":"hall_of_silence", "width":4800, "height":1400, "floor":900.0, "back":830.0, "lip":900.0},
			{"id":"cold_forge", "width":3200, "height":1300, "floor":880.0, "back":780.0, "lip":880.0}]:
		var map = load("res://scenes/maps/%s.tscn" % spec.id).instantiate()
		if spec.id == "hall_of_silence":
			map.get_node("Spawners").free()
		add_child(map)
		var player = map.player
		map.camera.position_smoothing_enabled = false
		var sky := map.get_node("Background/Sky") as Polygon2D
		var ground := map.get_node("Terrain/Ground/Shape") as CollisionShape2D
		spec.floor = ground.global_position.y - (ground.shape as RectangleShape2D).size.y * 0.5
		check(sky.texture.get_size() == Vector2(spec.width, spec.height), "Native texture dimensions")
		check(sky.uv[2] == sky.texture.get_size(), "Whole texture UV 1:1")
		var ambient := map.get_node("AmbientFX") as MapAmbientFX
		check(ambient._runes.size() > 0 and ambient.mist_regions.size() > 0, "Rune and mist effects exist")
		var light := ambient._lamps[0].light as PointLight2D
		var initial_energy := light.energy
		for sample in range(3):
			player.global_position = Vector2(250 + sample * (spec.width - 600) / 2.0, spec.floor - 250)
			player.velocity = Vector2.ZERO
			for tick in range(60):
				await get_tree().physics_frame
			check(player.is_on_floor(), "Standing on actual collider")
			check(absf(player.foot_position().y - spec.floor) < 3.0, "Existing floor coordinate preserved")
			check(player.foot_position().y <= spec.lip + 3.0 and player.foot_position().y >= spec.lip - 20.0, "Feet remain on original shallow walkway")
			check(player.get_node("FootShadow").visible, "Foot shadow remains grounded")
			await capture("%s_final_%d" % [spec.id, sample])
		check(not is_equal_approx(initial_energy, light.energy), "Real lamp energy animates")
		player.global_position.x = spec.width * 0.5 - 500
		Input.action_press("move_right")
		for tick in range(240):
			await get_tree().physics_frame
			check(player.is_on_floor(), "Walk across stitched floor")
		Input.action_release("move_right")
		if spec.id == "cold_forge":
			await check_forge_quests(map)
		else:
			check(map.get_node("Lore/FamilyTools").lore_id == &"dvalin_family_tools", "Hall tools match story")
		map.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	print("CHAPTER2_MAP_TEST: 2 maps, 6 standing samples, 480 walking frames, forge quest chain; %d failures" % failures)
	get_tree().quit(failures)

func check_forge_quests(map: Node) -> void:
	var lore := map.get_node("Lore/HammerBlueprint") as LoreObject
	var spawner := map.get_node("Spawners/MapSpawner") as MapSpawner
	# Relax offscreen constraints only on this test instance to verify its complete authored roster.
	spawner.spawn_offscreen = false
	spawner.max_spawn_distance = 0.0
	for tick in range(360):
		if spawner._alive.size() >= 5:
			break
		await get_tree().physics_frame
	check(spawner._alive.size() == 5, "Five quest golems spawn in Cold Forge")
	PlayerState.quests.accept(&"c2_6_to_cold_forge")
	PlayerState.quests.on_map_entered(&"cold_forge")
	for golem in spawner._alive.duplicate():
		check(golem.data.id == &"forge_golem", "Quest monster identity")
		golem.take_damage(100000000)
	check(PlayerState.quests.is_ready(&"c2_6_to_cold_forge"), "Five real deaths complete golem objective")
	PlayerState.quests.turn_in(&"c2_6_to_cold_forge")
	PlayerState.quests.accept(&"c2_7_forge_guardian")
	PlayerState.quests.accept(&"c2_8_hammer_truth")
	map.player.global_position = Vector2(lore.position.x, 760)
	for tick in range(10):
		await get_tree().physics_frame
	check(lore._player_inside, "Blueprint can be reached from walking lane")
	lore.read()
	await finish_dialogue()
	check(not PlayerState.has_flag(&"read_hammer_blueprint"), "Blueprint is locked before boss defeat")
	var boss_spawner = map.get_node("Spawners/Boss_forge_guardian")
	check(boss_spawner._alive.size() == 1, "Guardian exists")
	if boss_spawner._alive.size() > 0:
		boss_spawner._alive[0].take_damage(100000000)
	check(PlayerState.has_flag(&"killed_forge_guardian"), "Boss defeat unlocks wall")
	check(PlayerState.quests.is_ready(&"c2_7_forge_guardian"), "Guardian quest receives death event")
	check(lore.position.x > boss_spawner.position.x, "Blueprint is beyond guardian")
	lore.read()
	await finish_dialogue()
	check(PlayerState.quests.is_ready(&"c2_8_hammer_truth"), "Reading wall advances real quest")
	PlayerState.quests.turn_in(&"c2_8_hammer_truth")
	var portal = map.get_node("Portals/ToRootRoad")
	check(PlayerState.has_flag(portal.required_flag), "Chapter 3 portal unlocks after quest turn-in")
	for tick in range(90):
		await get_tree().physics_frame
	var ambient := map.get_node("AmbientFX") as MapAmbientFX
	check(is_equal_approx(ambient._runes[0].modulate.a, ambient.rune_color.a), "Blueprint follows authored glow setting after guardian")
	await capture("cold_forge_blueprint_unlocked")
