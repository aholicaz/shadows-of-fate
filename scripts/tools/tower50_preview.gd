extends Node
## Bounded rendering audit; no user save is loaded or written.
const Tower = preload("res://scripts/world/chapter8_tower_data.gd")
var checks := 0

func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	PlayerState.stats.job_id = &"ninth_edge"
	PlayerState.stats.level = 150
	PlayerState.stats.base_vit = 150
	PlayerState.refresh()
	# Leave story gate closed while reviewing scenery, so no timed waves begin.
	Tower.gm_test = false
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var quick := "--quick" in OS.get_cmdline_user_args()
	var guardians := "--guardians" in OS.get_cmdline_user_args()
	var hub_only := "--hub" in OS.get_cmdline_user_args()
	var first_floor := 0
	var last_floor := 50
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--range="):
			var bounds := arg.trim_prefix("--range=").split(":")
			first_floor = int(bounds[0])
			last_floor = int(bounds[1])
	for n in range(0, 51):
		if n < first_floor or n > last_floor: continue
		if hub_only and n > 0: continue
		if guardians and (n == 0 or n % 5 != 0): continue
		if quick and n > 0 and n % 5 != 0: continue
		PlayerState.revive(1.0)
		var id := &"yggdrasil_root" if n == 0 else Tower.floor_id(n)
		var map = load(Game.MAPS[id]).instantiate()
		add_child(map)
		await get_tree().process_frame
		Events.map_changed.emit(id)
		map.player.set_physics_process(false)
		map.player._play("Idle", true)
		map.camera.position_smoothing_enabled = false
		map.status.text = "อิกดราซิล • ชั้น %d / 50" % n
		if n > 0:
			assert(map.next_portal.target_map == (Tower.floor_id(n+1) if n < 50 else &"yggdrasil_root"))
			assert(map.next_portal.required_flag != &"")
			assert(map.get_node("Background/Depth").texture != null)
			checks += 3
		# Raycast actual collision at regular intervals through every floor.
		await get_tree().physics_frame
		for x in range(100, 4200, 200):
			var query := PhysicsRayQueryParameters2D.create(Vector2(x, 850), Vector2(x, 930), 1)
			var hit: Dictionary = map.get_world_2d().direct_space_state.intersect_ray(query)
			assert(not hit.is_empty() and absf(hit.position.y - 880.0) < 1.0)
			checks += 1
		# Sweep the actual player collision body across the entire active lane.
		map.player.position = Vector2(150, 879.0 - map.player._feet_y())
		assert(not map.player.test_move(map.player.global_transform, Vector2(3900, 0)))
		checks += 1
		if guardians:
			map.player.position = Vector2(2100, 880.0 - map.player._feet_y())
			map.camera.global_position = Vector2(2200, 580)
			map.camera.reset_smoothing()
			map._spawn(Tower.NEW_IDS[Tower.theme(n)], true, true, 2700)
			var boss = map.enemy_container.get_child(0)
			boss.set_physics_process(false)
			boss._tower_cast(Tower.theme(n))
			for phase in ["warning", "impact"]:
				await get_tree().create_timer(0.5 if phase == "warning" else 1.0).timeout
				assert(not PlayerState.is_dead() and is_instance_valid(boss.tower_pattern))
				var fired := false
				for zone in boss.tower_pattern.zones:
					if zone.fired: fired = true
				assert(fired == (phase == "impact"))
				checks += 2
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://output/tower50/boss_%02d_%s.png" % [n, phase])
			map.queue_free()
			await get_tree().process_frame
			await get_tree().process_frame
			GameData.release_monsters_except([])
			print("TOWER GUARDIAN VISUAL ", n)
			continue
		for aspect in [Vector2i(1280,720), Vector2i(1920,800)]:
			DisplayServer.window_set_size(aspect)
			await get_tree().process_frame
			var views: Array = [2100.0]
			if n % 5 == 0: views = [350.0, 1300.0, 2100.0, 3250.0, 3850.0]
			for x in views:
				map.player.position = Vector2(x, 880.0 - map.player._feet_y())
				map.camera.global_position = Vector2(x, 580)
				map.camera.reset_smoothing()
				await get_tree().process_frame
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://output/tower50/view_%02d_%d_%d.png" % [n, aspect.x, int(x)])
		print("TOWER VISUAL floor ", n)
		map.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		GameData.release_monsters_except([])
	print("TOWER50 PREVIEW PASS: ", checks, " collision, portal and scenery checks; no save writes")
	get_tree().quit()
