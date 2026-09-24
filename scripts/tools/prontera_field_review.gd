extends Node

func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1600, 900))
	var map = load("res://scenes/maps/prontera_field.tscn").instantiate()
	add_child(map)
	await get_tree().create_timer(2.0).timeout
	for x in [450.0, 1700.0, 3000.0, 4500.0, 5600.0]:
		map.player.position = Vector2(x, 400)
		await get_tree().create_timer(1.0).timeout
		map.camera.reset_smoothing()
		await get_tree().create_timer(.25).timeout
		var ray := PhysicsRayQueryParameters2D.create(Vector2(x,490), Vector2(x,530), 1)
		var hit: Dictionary = map.get_world_2d().direct_space_state.intersect_ray(ray)
		assert(not hit.is_empty() and absf(hit.position.y - 504.0) < .1)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/prontera_rebuild/runtime_%d.png" % x)
	map.player.position = Vector2(2500, 400)
	await get_tree().create_timer(.8).timeout
	var start_x: float = map.player.position.x
	Input.action_press("move_right")
	await get_tree().create_timer(1.0).timeout
	Input.action_release("move_right")
	assert(map.player.position.x > start_x + 50)
	assert(map.player.is_on_floor())
	DisplayServer.window_set_size(Vector2i(1920, 820))
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/prontera_rebuild/runtime_wide.png")
	print("Review window: ", DisplayServer.window_get_size(), " viewport: ", get_viewport().get_visible_rect().size)
	print("PRONTERA_REVIEW PASS: five floor samples, real walking, 16:9 and ultrawide; saves inactive")
	get_tree().quit()
