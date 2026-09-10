extends Node

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	for map_id in ["ember_mine", "hall_of_silence"]:
		var map = load("res://scenes/maps/%s.tscn" % map_id).instantiate()
		map.get_node("Spawners").free()
		add_child(map)
		var player = map.player
		player.global_position = Vector2(3700, 650)
		for tick in range(60):
			await get_tree().physics_frame
		var shadow = player.get_node("FootShadow")
		check(shadow.visible and absf(shadow.global_position.y - (900.0 + shadow.floor_offset.y)) < 0.1, "Shadow must sit on floor")
		var grounded_alpha: float = shadow.modulate.a
		var grounded_width: float = shadow.global_scale.x
		Input.action_press("move_right")
		for tick in range(30):
			await get_tree().physics_frame
			check(absf(shadow.global_position.x - player.global_position.x) < 6.0, "Shadow follows walking")
		Input.action_release("move_right")
		await get_tree().physics_frame
		player.set_physics_process(false)
		player.global_position.y -= 160.0
		await get_tree().physics_frame
		await get_tree().physics_frame
		check(absf(shadow.global_position.y - (900.0 + shadow.floor_offset.y)) < 0.1, "Airborne shadow stays on ground")
		check(shadow.modulate.a < grounded_alpha and shadow.global_scale.x < grounded_width, "Airborne shadow softens and shrinks")
		player.global_position.x = 10000.0
		await get_tree().physics_frame
		await get_tree().physics_frame
		check(not shadow.visible, "No floating shadow over empty space")
		player.global_position = Vector2(3700, 650)
		player.set_physics_process(true)
		for tick in range(60):
			await get_tree().physics_frame
		map.camera.position_smoothing_enabled = false
		map.camera.zoom = Vector2(0.9, 0.9)
		UI.layer.hide()
		await get_tree().process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://output/map_art/%s_player_shadow.png" % map_id)
		map.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	print("PLAYER_SHADOW_TEST: 2 maps, walking, airborne, empty ground; %d failures" % failures)
	get_tree().quit(failures)
