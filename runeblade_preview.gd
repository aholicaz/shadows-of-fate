extends Node
func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	get_window().content_scale_size = Vector2i(1280,720)
	PlayerState.new_game()
	PlayerState.stats.level = 50
	PlayerState.stats.base_str = 60
	PlayerState.stats.base_dex = 40
	PlayerState.stats.base_vit = 35
	PlayerState.refresh()
	PlayerState.revive(1)
	PlayerState.gm_god_mode = true
	PlayerState.set_flag(&"rb_trials")
	for i in range(3): PlayerState.set_flag(StringName("rb_seal_%d"%i))
	PlayerState.quests.accept(&"rb5_oath_eater")
	var map = load("res://scenes/maps/blackhorn_rootcrypt.tscn").instantiate()
	add_child(map)
	Events.map_changed.emit(&"blackhorn_rootcrypt")
	map.player.position = Vector2(4850,760)
	map.camera.position_smoothing_enabled = false
	map.camera.reset_smoothing()
	map.fighting = true
	map.next_adds = 0.1
	map.boss.hp = int(map.boss.data.max_hp*0.3)
	await get_tree().create_timer(3.1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/runeblade_dungeon.png")
	await get_tree().create_timer(3).timeout
	map.queue_free()
	await get_tree().process_frame
	get_tree().quit()
