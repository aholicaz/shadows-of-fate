extends Node2D

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	RenderingServer.set_default_clear_color(Color("#141b27"))
	PlayerState.new_game()
	UI.layer.hide()
	PlayerState.skills.learned[&"magnum_break"] = 1
	PlayerState.stats.sp = 100
	var player = load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.position = Vector2(330, 450)
	player.set_physics_process(false)
	player.facing = 1
	player._update_facing()
	PlayerState.cooldowns.clear()
	player.use_skill(&"magnum_break")
	await get_tree().create_timer(0.07).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/rending_wave_windup.png")
	await get_tree().create_timer(0.38).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/rending_wave_preview.png")
	await get_tree().create_timer(0.35).timeout
	player.position.x = 950
	player.facing = -1
	player._update_facing()
	PlayerState.cooldowns.clear()
	player.use_skill(&"magnum_break")
	await get_tree().create_timer(0.46).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/rending_wave_left.png")
	await get_tree().create_timer(0.35).timeout
	player.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _draw() -> void:
	draw_line(Vector2(80, 580), Vector2(1200, 580), Color("#43505e"), 2.0)
