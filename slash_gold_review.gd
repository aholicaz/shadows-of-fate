extends Node2D

const Flurry = preload("res://scripts/entities/slash_flurry_fx.gd")
var checks := 0

func verify(ok: bool, message: String) -> void:
	assert(ok, message)
	checks += 1
	print("PASS: ", message)

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	RenderingServer.set_default_clear_color(Color("#141b27"))
	PlayerState.new_game()
	var player = load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	await get_tree().process_frame
	for child in UI.get_children():
		if child is CanvasLayer or child is CanvasItem:
			child.hide()
	for direction in [-1, 1]:
		player.position = Vector2(640, 420)
		player.facing = direction
		player._update_facing()
		player.is_attacking = true
		player.sprite.play(&"Attack_Blade_slash")
		player.sprite.pause()
		player.sprite.frame = 0
		var fx = Flurry.spawn(player, player.sprite, direction)
		fx.set_process(false)
		fx._process(0)
		verify(fx.emitted == 0, "no light before the first cutting frame")
		for i in range(5):
			player.sprite.frame = Flurry.CUT_FRAMES[i]
			fx._process(0)
			verify(fx.emitted == i + 1, "one burst for cutting frame " + str(player.sprite.frame))
			if i < 4:
				fx._process(0)
				verify(fx.emitted == i + 1, "held frame does not duplicate the flash")
			var cut = get_tree().get_nodes_in_group("slash_gold_flashes").back()
			verify(cut.scale.x == -direction, "whole flash mirrors with facing")
			if i == 2:
				# Freeze the preview flashes while the first render uploads textures.
				for flash in get_tree().get_nodes_in_group("slash_gold_flashes"):
					flash.process_mode = Node.PROCESS_MODE_DISABLED
					flash.get_child(0).modulate.a = 0.75
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://output/slash_gold_%s.png" % ("left" if direction < 0 else "right"))
				for flash in get_tree().get_nodes_in_group("slash_gold_flashes"):
					flash.process_mode = Node.PROCESS_MODE_INHERIT
			await get_tree().create_timer(0.035).timeout
		await get_tree().create_timer(0.25).timeout
		verify(get_tree().get_nodes_in_group("slash_gold_flashes").is_empty(), "all trails clean up")
	# Real cast exercises the production hook and playback restoration.
	PlayerState.skills.learned[&"slash"] = 1
	PlayerState.stats.sp = 100
	PlayerState.cooldowns.clear()
	player.is_attacking = false
	player.sprite.speed_scale = 4.0
	player.use_skill(&"slash")
	verify(player.get_children().any(func(n): return n.get_script() == Flurry), "Slash cast creates frame controller")
	await get_tree().create_timer(0.20).timeout
	verify(player._dash_time > 0.0, "dash still starts after windup")
	player._dash_time = 0.0
	await get_tree().create_timer(0.25).timeout
	verify(not player.is_attacking and is_equal_approx(player.sprite.speed_scale, 1.0), "early dash end restores normal animation playback")
	verify(not player.get_children().any(func(n): return n.get_script() == Flurry), "early end cancels remaining flashes")
	player.queue_free()
	print("SLASH GOLD: ", checks, " checks passed")
	get_tree().quit()

func _draw() -> void:
	draw_line(Vector2(80, 550), Vector2(1200, 550), Color("#43505e"), 2)
