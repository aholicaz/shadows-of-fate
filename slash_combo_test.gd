extends Node2D

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1040, 960)
	get_window().content_scale_size = Vector2i(1560, 1440)
	var book := load("res://data/sprites/player_fx.tres") as PlayerFXBook
	var frames := load("res://data/sprites/player_frames.tres") as SpriteFrames
	var count := 0
	for step in range(3):
		var track := book.active(PlayerFXBook.combo_key(step))
		check(track != null and track.white_mask, "Combo must enable book and white mask")
		for facing in [-1, 1]:
			for speed in [0.7, 1.0, 8.0]:
				var caster := Node2D.new()
				add_child(caster)
				var sprite := AnimatedSprite2D.new()
				caster.add_child(sprite)
				sprite.sprite_frames = frames
				sprite.play(track.track_animation)
				sprite.speed_scale = speed
				sprite.flip_h = facing > 0
				sprite.scale = Vector2(0.7, 0.7)
				sprite.offset = Vector2(17, -23)
				var fx := SlashSheetFX.spawn({"track": track, "sprite": sprite, "set": track.sheet_set,
					"native": SlashSheetFX.native_angle_of(track.sheet_set), "size": track.size_px}, caster, facing)
				check(fx != null, "Spawn failed")
				for f in range(frames.get_frame_count(track.track_animation)):
					sprite.set_frame_and_progress(f, 0.0)
					fx._process(0.0)
					var point := track.blade_positions[f]
					if sprite.flip_h:
						point.x = -point.x
					check(fx.global_position.distance_to(sprite.to_global(point + sprite.offset)) < 0.01, "Blade alignment")
					check(is_equal_approx(fx.modulate.a, track.blade_opacity[f]), "Blade visibility")
					var blade_axis := Vector2.from_angle(deg_to_rad(track.blade_angles[f]))
					if sprite.flip_h:
						blade_axis.x = -blade_axis.x
					var native := 0.0 if track.crescent_enabled else SlashSheetFX.native_angle_of(track.sheet_set)
					var fx_axis := Vector2.from_angle(fx.global_rotation + deg_to_rad(native))
					check(blade_axis.dot(fx_axis) > 0.999, "Blade angle")
					count += 1
				if track.crescent_enabled:
					var last := frames.get_frame_count(track.track_animation) - 1
					sprite.set_frame_and_progress(last, 0.95)
					fx._process(0.0)
					check(fx.modulate.a < 0.02, "Last pose must fade before animation ends")
					check(is_equal_approx(float((fx.material as ShaderMaterial).get_shader_parameter("phase")), last + 0.95), "Shader must follow animation subframe")
				sprite.play(&"Idle")
				fx._process(0.0)
				check(fx.is_queued_for_deletion(), "FX must stop when animation changes")
				caster.queue_free()
	# Let Godot advance the actual animation clock, including ASPD changes.
	for step in range(3):
		var track := book.active(PlayerFXBook.combo_key(step))
		for speed in [0.7, 1.0, 8.0]:
			var caster := Node2D.new()
			add_child(caster)
			var sprite := AnimatedSprite2D.new()
			caster.add_child(sprite)
			sprite.sprite_frames = frames
			sprite.play(track.track_animation)
			sprite.speed_scale = speed
			var fx := SlashSheetFX.spawn({"track": track, "sprite": sprite, "set": track.sheet_set}, caster, 1)
			var elapsed := 0.0
			while sprite.is_playing() and elapsed < 3.0:
				await get_tree().process_frame
				elapsed += get_process_delta_time()
			check(not sprite.is_playing(), "Animation clock must finish at configured speed")
			await get_tree().process_frame
			check(not is_instance_valid(fx) or fx.is_queued_for_deletion(), "Completed animation must release FX")
			caster.queue_free()
	# Render every authored pose for visual review using the real player's auto-fit.
	var index := 0
	for step in range(3):
		var track := book.active(PlayerFXBook.combo_key(step))
		for f in range(frames.get_frame_count(track.track_animation)):
			var player = load("res://scenes/player/player.tscn").instantiate()
			add_child(player)
			player.set_physics_process(false)
			player.set_process(false)
			player.position = Vector2(130 + (index % 6) * 260, 280 + (index / 6) * 350)
			player.sprite.play(track.track_animation)
			player.sprite.speed_scale = 0.0
			player.sprite.frame = f
			player.sprite.flip_h = true
			player._apply_auto_fit()
			var fx: SlashSheetFX = player._spawn_slash_sheet(step, 1.0, 0.12, 1.0)
			fx._process(0.0)
			fx.set_process(false)
			var label := Label.new()
			label.text = "Attack %d / frame %d" % [step + 1, f]
			label.position = player.position + Vector2(-110, -260)
			add_child(label)
			index += 1
	await get_tree().process_frame
	await get_tree().process_frame
	UI.layer.hide()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://slash_combo_review.png")
	# Compact peak-pose preview, rendered directly by Godot (finisher scale included).
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	get_window().size = Vector2i(1170, 480)
	get_window().content_scale_size = Vector2i(1560, 640)
	var backdrop := ColorRect.new()
	backdrop.size = Vector2(1560, 640)
	backdrop.color = Color(0.035, 0.045, 0.065)
	backdrop.z_index = -100
	add_child(backdrop)
	for step in range(3):
		var track := book.active(PlayerFXBook.combo_key(step))
		var player = load("res://scenes/player/player.tscn").instantiate()
		add_child(player)
		player.set_physics_process(false)
		player.set_process(false)
		player.position = Vector2(250 + step * 520, 400)
		player.sprite.play(track.track_animation)
		player.sprite.speed_scale = 0.0
		player.sprite.set_frame_and_progress([4, 2, 5][step], 0.0)
		player.sprite.flip_h = true
		player._apply_auto_fit()
		var fx: SlashSheetFX = player._spawn_slash_sheet(step, 1.25 if step == 2 else 1.0, 0.12, 1.0)
		fx._process(0.0)
		fx.set_process(false)
		var label := Label.new()
		label.text = "ATTACK %d" % (step + 1)
		label.position = Vector2(205 + step * 520, 90)
		label.add_theme_font_size_override("font_size", 24)
		add_child(label)
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/map_art/slash_three_hits.png")
	print("SLASH_COMBO_TEST: %d frame cases, %d failures" % [count, failures])
	get_tree().quit(failures)
