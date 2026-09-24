extends Node
const Tower = preload("res://scripts/world/chapter8_tower_data.gd")
func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	PlayerState.stats.job_id = &"ninth_edge"
	PlayerState.stats.level = 115
	PlayerState.stats.base_vit = 120
	PlayerState.refresh()
	PlayerState.set_flag(&"chapter7_done")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1600, 900))
	for n in [0, 5, 10, 15, 20]:
		if n > 0: PlayerState.set_flag(Tower.clear_flag(n - 1))
		var id := &"yggdrasil_root" if n == 0 else Tower.floor_id(n)
		var map = load(Game.MAPS[id]).instantiate()
		add_child(map)
		await get_tree().process_frame
		Events.map_changed.emit(id)
		map.player.set_physics_process(false)
		map.player.position = Vector2(2050 if n > 0 else 1250, 880 - map.player._feet_y())
		map.player._play("Idle", true)
		map.camera.position_smoothing_enabled = false
		map.camera.global_position = Vector2(map.player.position.x, 600)
		if n > 0:
			for enemy in map.enemy_container.get_children(): enemy.queue_free()
			await get_tree().process_frame
			map._spawn(Tower.NEW_IDS[Tower.theme(n)], true, true, 2700)
			var boss = map.enemy_container.get_child(0)
			boss.set_physics_process(false)
			map.status.text = "อิกดราซิล ชั้น %d • %s" % [n, Tower.SKILL_NAMES[Tower.theme(n)]]
			await get_tree().create_timer(0.5).timeout
			boss._tower_cast(Tower.theme(n))
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/chapter8/preview_%02d.png" % n)
		if n > 0:
			await get_tree().create_timer(1.0).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://output/chapter8/impact_%02d.png" % n)
		print("C8 preview ", n)
		map.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		GameData.release_monsters_except([])
	get_tree().quit()
