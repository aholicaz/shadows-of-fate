## Real Player.start_attack integration, both facings, rendered against the lit map.
extends Node

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	var map = load("res://scenes/maps/hall_of_silence.tscn").instantiate()
	map.get_node("Spawners").free()
	add_child(map)
	var player = map.player
	player.global_position = Vector2(3800, 650)
	map.camera.position_smoothing_enabled = false
	for tick in range(60):
		await get_tree().physics_frame
	UI.layer.hide()
	for facing in [1, -1]:
		player.facing = facing
		player._update_facing()
		player.reset_combo()
		for step in range(3):
			player.start_attack()
			var track: PlayerSkillFX = player.fx_book.active(PlayerFXBook.combo_key(step))
			check(player.sprite.animation == track.track_animation, "Real combo animation %d" % step)
			check(player.sprite.flip_h == (facing > 0), "Real sprite must face requested direction")
			var captured := false
			var elapsed := 0.0
			while player.is_attacking and elapsed < 3.0:
				await get_tree().process_frame
				elapsed += get_process_delta_time()
				if not captured and player.sprite.frame == [4, 2, 5][step]:
					var found := false
					for node in map.get_children():
						if node is SlashSheetFX and node.visible and not node.is_queued_for_deletion():
							found = true
					check(found, "Live attack must spawn visible SlashSheetFX")
					if DisplayServer.get_name() != "headless":
						await RenderingServer.frame_post_draw
						get_viewport().get_texture().get_image().save_png("res://output/map_art/attack_%d_facing_%d.png" % [step + 1, facing])
					captured = true
			check(captured and not player.is_attacking, "Real combo must reach impact and finish")
			check(player.is_on_floor(), "Attack preserves grounded player")
	print("FX_PLAYTEST: 6 live attacks, both facings, %d failures" % failures)
	get_tree().quit(failures)
