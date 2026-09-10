## Temporary-instance integration test. Does not load or save user progress.
extends Node

var failures := 0
var roster: Array[StringName] = []
var lore_ids: Array[StringName] = []
var npc_names: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func capture(label: String) -> void:
	UI.layer.hide()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/chapter3_maps/%s.png" % label)

func settle(player: CharacterBody2D, x: float, floor_y: float) -> void:
	player.global_position = Vector2(x, floor_y - 220)
	player.velocity = Vector2.ZERO
	for tick in range(65):
		await get_tree().physics_frame
	check(player.is_on_floor(), "Player grounded at x=%s" % x)
	check(absf(player.foot_position().y - floor_y) < 3.0, "Player feet agree with collision surface")

func finish_dialogue() -> void:
	for press in range(20):
		await get_tree().process_frame
		if not UI.dialogue.is_open():
			return
		UI.dialogue._advance()
	check(not UI.dialogue.is_open(), "Dialogue completes")

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	PlayerState.quests = QuestLog.new()
	PlayerState.respawn_locks.clear()
	var specs = JSON.parse_string(FileAccess.get_file_as_string("res://output/chapter3_maps/specs.json"))
	for spec in specs:
		var map = load("res://scenes/maps/%s.tscn" % spec.id).instantiate()
		var monster_data: Array[MonsterData] = []
		for spawner in map.get_node("Spawners").get_children():
			if "monster_types" in spawner:
				for data in spawner.monster_types:
					if data not in monster_data:
						monster_data.append(data)
						roster.append(data.id)
		map.get_node("Spawners").free()
		add_child(map)
		map.camera.position_smoothing_enabled = false
		var player = map.player
		var sky: Polygon2D = map.get_node("Background/Sky")
		var shape: CollisionShape2D = map.get_node("Terrain/Ground/Shape")
		var floor_y := shape.global_position.y - (shape.shape as RectangleShape2D).size.y * 0.5
		check(sky.texture.get_size() == Vector2(spec.w, spec.h), "%s native output size" % spec.id)
		check(sky.uv[2] == sky.texture.get_size(), "%s texture mapped without stretching" % spec.id)
		check(absf(floor_y - (sky.position.y + float(spec.floor))) < 1.0, "%s original floor retained" % spec.id)
		var ambient: MapAmbientFX = map.get_node("AmbientFX")
		check(ambient.get_child_count() > 0, "%s animated atmosphere exists" % spec.id)
		var initial_time := ambient._time
		for sample in range(3):
			await settle(player, 400.0 + sample * (float(spec.w) - 800.0) / 2.0, floor_y)
			await capture("%s_view_%d" % [spec.id, sample])
		check(ambient._time > initial_time, "Atmosphere time advances")
		# Every seam is crossed on the actual walkable collider.
		for seam in range(1, int(spec.n)):
			var seam_x := sky.position.x + float(spec.step) * seam + 120.0
			await settle(player, seam_x - 100.0, floor_y)
			Input.action_press("move_right")
			for tick in range(45):
				await get_tree().physics_frame
				check(player.is_on_floor(), "Walk across image join without falling")
			Input.action_release("move_right")
		check(not player.can_jump, "Player jumping is disabled")
		# The existing jump binding performs a horizontal dodge, never a jump.
		await settle(player, 420.0, floor_y)
		Input.action_press("jump")
		for tick in range(100):
			await get_tree().physics_frame
			check(absf(player.foot_position().y - floor_y) < 3.0, "Dodge stays on painted walking lane")
		Input.action_release("jump")
		# Use every authored monster's real scene, sprite fitting and collision size.
		var enemies: Array[CharacterBody2D] = []
		for i in range(monster_data.size()):
			var enemy = load("res://scenes/monsters/monster.tscn").instantiate()
			enemy.data = monster_data[i]
			map.add_child(enemy)
			enemy.set_physics_process(false)
			enemy.global_position = Vector2(650 + i * 380, floor_y - enemy.data.foot_offset() - 25.0)
			enemies.append(enemy)
		for tick in range(90):
			await get_tree().physics_frame
			for enemy in enemies:
				enemy.velocity = Vector2(0, enemy.velocity.y + 980.0 / 60.0)
				enemy.move_and_slide()
		for enemy in enemies:
			check(enemy.is_on_floor(), "%s grounded" % enemy.data.id)
			var foot_y: float = enemy.foot_position().y
			check(foot_y >= floor_y - 86.0 and foot_y <= floor_y + 24.0, "%s feet remain inside walking plane" % enemy.data.id)
			if not enemy.data.flying:
				var sprite: AnimatedSprite2D = enemy.get_node("AnimatedSprite2D")
				var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
				var frame_image: Image
				if texture is AtlasTexture:
					frame_image = texture.atlas.get_image()
					if frame_image.is_compressed():
						frame_image.decompress()
					frame_image = frame_image.get_region(texture.region)
				else:
					frame_image = texture.get_image()
					if frame_image.is_compressed():
						frame_image.decompress()
				var used := frame_image.get_used_rect()
				var local_bottom := float(used.end.y) - (texture.get_height() * 0.5 if sprite.centered else 0.0) + sprite.offset.y
				var drawn_bottom := sprite.to_global(Vector2(0, local_bottom)).y
				check(drawn_bottom <= floor_y + 24.0 and drawn_bottom >= floor_y - 86.0, "%s actual painted feet fit within visible ground depth (y=%s floor=%s)" % [enemy.data.id, drawn_bottom, floor_y])
		await settle(player, 300.0, floor_y)
		map.camera.global_position.x = 1100.0
		await capture("%s_actor_feet" % spec.id)
		if map.has_node("NPCs"):
			var last_x := -10000.0
			for npc in map.get_node("NPCs").get_children():
				npc_names.append(npc.npc_name)
				if spec.id == "nidavellir_town":
					check(npc.position.x - last_x >= 650.0, "Expanded town gives each NPC adequate space")
					last_x = npc.position.x
				await settle(player, npc.position.x, floor_y)
				check(npc._player_inside, "%s can be interacted with from ground" % npc.name)
		if map.has_node("Lore"):
			for lore in map.get_node("Lore").get_children():
				lore_ids.append(lore.lore_id)
				await settle(player, lore.position.x, floor_y)
				await get_tree().physics_frame
				await get_tree().physics_frame
				check(lore._player_inside, "%s reachable from ground" % lore.lore_id)
				if lore.required_flag != &"":
					PlayerState.story_flags.erase(lore.required_flag)
					PlayerState.story_flags.erase(lore._read_flag())
					lore.read()
					await finish_dialogue()
					check(not PlayerState.has_flag(lore._read_flag()), "Siphon rune remains locked before boss")
					for enemy in enemies:
						if enemy.data.id == &"gullveig_ember":
							enemy.take_damage(100000000)
					check(PlayerState.has_flag(lore.required_flag), "Real boss death unlocks siphon rune")
				var quest_id: StringName = {&"war_mural":&"c3_4_song_of_child", &"dry_spring_grove":&"c3_6_withering", &"burnt_stake":&"c3_8_stake_burned_thrice", &"buried_banner":&"c3_8_stake_burned_thrice", &"siphon_rune":&"c3_10_flame_that_never_dies"}.get(lore.lore_id, &"")
				if quest_id != &"":
					PlayerState.quests.accept(quest_id)
				lore.read()
				await finish_dialogue()
				check(PlayerState.has_flag(lore._read_flag()), "%s read event succeeds" % lore.lore_id)
				if quest_id != &"":
					var steps = GameData.get_quest(quest_id).steps()
					for i in range(steps.size()):
						if steps[i].target == lore.lore_id:
							check(PlayerState.quests.step_done(quest_id, i), "Real lore read advances quest")
				if lore.required_flag != &"":
					for tick in range(240):
						await get_tree().physics_frame
				await capture("%s_%s" % [spec.id, lore.lore_id])
		for portal in map.get_node("Portals").get_children():
			var destination = load("res://scenes/maps/%s.tscn" % portal.target_map).instantiate()
			check(destination.has_node("SpawnPoints/" + String(portal.target_spawn_point)), "Portal destination spawn exists")
			destination.free()
		print("MAP_VERIFIED: ", spec.id, " floor=", floor_y, " monsters=", monster_data.size())
		map.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	# All chapter-three quest targets are represented by actual authored maps.
	for file in DirAccess.get_files_at("res://data/quests"):
		if not file.begins_with("c3_") or not file.ends_with(".tres"):
			continue
		var quest = load("res://data/quests/" + file)
		check(quest.giver_name in npc_names, "Quest giver is present: " + quest.giver_name)
		for step in quest.steps():
			if step.kind == ObjectiveData.Kind.KILL:
				check(step.target in roster, "Quest monster roster includes " + String(step.target))
			elif step.kind == ObjectiveData.Kind.READ:
				check(step.target in lore_ids, "Quest landmark exists " + String(step.target))
	for file in DirAccess.get_files_at("res://scenes/maps"):
		if not file.ends_with(".tscn"):
			continue
		var scene = load("res://scenes/maps/" + file).instantiate()
		for node in scene.find_children("Plat*", "StaticBody2D", true, false):
			check(false, "%s still has platform %s" % [file, node.name])
		scene.free()
	print("CHAPTER3_MAP_TEST: 8 maps, seams, no player jump, player/monster feet, NPC reach, lore events, boss gate and all maps without platforms; %d failures" % failures)
	get_tree().quit(failures)
