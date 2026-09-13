extends Node2D
## F6: five animations, both directions, actual MonsterBase visual fitting.
## -- --audit: verify every imported frame, capture PNGs, then quit.
## No player initialization, damage, drops, quests, or save writes.

const ANIMS: Array[StringName] = [&"Idle", &"Walk", &"Attack", &"Hit", &"Die"]
const MONSTER = preload("res://scenes/monsters/monster.tscn")
const DATA = preload("res://data/monsters/war_wraith.tres")
var actors: Array[Node2D] = []
var elapsed := 0.0
var paused := false
var failures := 0
var checks := 0
var audit := false

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	audit = OS.get_cmdline_user_args().has("--audit")
	get_window().size = Vector2i(1600, 800)
	get_window().content_scale_size = Vector2i(1600, 800)
	RenderingServer.set_default_clear_color(Color("101827"))
	UI.layer.hide()
	for row in range(2):
		for col in range(ANIMS.size()):
			var actor = MONSTER.instantiate()
			actor.data = DATA
			actor.position = Vector2(160 + col * 320, 371 + row * 350)
			add_child(actor)
			actor.set_physics_process(false)
			actor._hp_bar.hide()
			actor.facing = -1 if row == 0 else 1
			actor.sprite.flip_h = row == 1
			actor._play(String(ANIMS[col]), true)
			actor._apply_fit()
			actors.append(actor)
	if audit:
		await run_audit()

func _process(delta: float) -> void:
	if audit or paused:
		return
	elapsed += delta
	if elapsed >= 2.0:
		elapsed = 0.0
		for i in range(actors.size()):
			actors[i]._play(String(ANIMS[i % ANIMS.size()]), true)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		paused = not paused
		for actor in actors:
			if paused:
				actor.sprite.pause()
			else:
				actor.sprite.play()
		queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(28, 38), "WAR WRAITH / 40 FRAMES / GODOT RUNTIME", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("dce8ff"))
	draw_string(font, Vector2(28, 66), "Top: facing left   /   Bottom: mirrored right   /   Space: pause or resume", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("9eafc5"))
	for row in range(2):
		for col in range(ANIMS.size()):
			var at := Vector2(col * 320 + 8, 88 + row * 350)
			var light := row == 1
			draw_style_box(panel(Color("e8edf3") if light else Color("19263b")), Rect2(at, Vector2(304, 330)))
			var ink := Color("27374b") if light else Color("dce8ff")
			draw_string(font, at + Vector2(16, 28), "%s / 8 frames" % ANIMS[col], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, ink)
			draw_line(Vector2(col*320+20, 399+row*350), Vector2(col*320+300, 399+row*350), Color("718299"), 1)
	draw_string(font, Vector2(28, 789), "512 x 512 per frame | PNG RGBA | Fixed anchor (240, 448) | %s" % ("PAUSED" if paused else "PLAYING"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("9eafc5"))

func panel(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(12)
	return style

func run_audit() -> void:
	var frames: SpriteFrames = DATA.sprite_frames
	check(frames != null, "SpriteFrames loads")
	for anim in ANIMS:
		check(frames.has_animation(anim) and frames.get_frame_count(anim) == 8, "%s has eight frames" % anim)
		check(frames.get_animation_loop(anim) == (anim in [&"Idle", &"Walk"]), "%s loop policy" % anim)
		for i in range(8):
			var tex := frames.get_frame_texture(anim, i)
			check(tex is AtlasTexture and tex.get_size() == Vector2(512, 512), "%s %d region size" % [anim, i])
			var pixels := tex.get_image()
			check(pixels != null and not pixels.is_empty(), "%s %d decoded image" % [anim, i])
			if pixels == null or pixels.is_empty():
				continue
			var bounds := pixels.get_used_rect()
			check(bounds.has_area() and bounds.position.x >= 16 and bounds.position.y >= 16 and bounds.end.x <= 496 and bounds.end.y <= 496, "%s %d safe transparent gutter" % [anim, i])
			check(pixels.get_pixel(0, 0).a == 0 and pixels.get_pixel(511, 511).a == 0, "%s %d true alpha" % [anim, i])
	for actor in actors:
		var fixed_scale: Vector2 = actor.sprite.scale
		for anim in ANIMS:
			actor._play(String(anim), true)
			actor.sprite.pause()
			for i in range(8):
				actor.sprite.frame = i
				actor._apply_fit()
				check(actor.sprite.scale.is_equal_approx(fixed_scale), "Constant visual scale through %s" % anim)
				var point := DATA.fit_fixed_anchor - Vector2(256, 256)
				if actor.sprite.flip_h:
					point.x = -point.x
				var world_anchor: Vector2 = actor.sprite.to_global(point + actor.sprite.offset)
				check(world_anchor.distance_to(actor.foot_position()) < .1, "Fixed anchor stays on ground")
	check(is_equal_approx(actors[0]._anim_time_to_frame("Attack", 4), DATA.attack_windup), "Attack contact frame matches existing 0.4 second windup")
	check(is_equal_approx(actors[0]._anim_length("Attack"), DATA.attack_windup + DATA.attack_duration), "Attack length preserves existing action timing")
	for alias in [&"Run", &"Skill"]:
		check(frames.has_animation(alias), "Existing consumer alias %s" % alias)
	for i in range(8):
		check(frames.get_frame_texture(&"Run", i) == frames.get_frame_texture(&"Walk", i), "Movement uses authored Walk frame %d" % i)
		check(frames.get_frame_texture(&"Run", i) != frames.get_frame_texture(&"Idle", i), "Run no longer substitutes Idle")
	check(actors[0]._play("Death", true) == "Die", "Monster death resolves to Die")
	await test_locomotion()
	# Capture selected poses through the real renderer, both directions and backgrounds.
	DirAccess.make_dir_recursive_absolute("res://output/war_wraith/runtime")
	for f in [0, 2, 4, 7]:
		for i in range(actors.size()):
			actors[i]._play(String(ANIMS[i % ANIMS.size()]), true)
			actors[i].sprite.pause()
			actors[i].sprite.frame = f
			actors[i]._apply_fit()
		await RenderingServer.frame_post_draw
		var result := get_viewport().get_texture().get_image().save_png("res://output/war_wraith/runtime/frame_%02d.png" % f)
		check(result == OK, "Rendered screenshot saved")
	for i in range(actors.size()):
		actors[i]._play(String(ANIMS[i % ANIMS.size()]), true)
	var captured_at: Array[int] = []
	var began := Time.get_ticks_msec()
	for tick in range(28):
		await RenderingServer.frame_post_draw
		captured_at.append(Time.get_ticks_msec() - began)
		var shot := get_viewport().get_texture().get_image()
		shot.resize(1200, 600, Image.INTERPOLATE_LANCZOS)
		shot.save_png("res://output/war_wraith/runtime/motion_%02d.png" % tick)
		await get_tree().create_timer(.05).timeout
	for i in range(actors.size()):
		if ANIMS[i % ANIMS.size()] in [&"Idle", &"Walk"]:
			check(actors[i].sprite.is_playing(), "Idle/Walk keeps looping during real playback")
		else:
			check(actors[i].sprite.frame == 7 and not actors[i].sprite.is_playing(), "One-shot animation finishes and holds final frame")
	var timing_file := FileAccess.open("res://output/war_wraith/runtime/motion_timing.json", FileAccess.WRITE)
	timing_file.store_string(JSON.stringify(captured_at))
	timing_file.close()
	var report := {"checks": checks, "failures": failures, "renderer": RenderingServer.get_current_rendering_method(), "engine": Engine.get_version_info().string}
	var file := FileAccess.open("res://output/war_wraith/runtime/audit.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("WAR_WRAITH_AUDIT ", JSON.stringify(report))
	get_tree().quit(1 if failures > 0 else 0)

func test_locomotion() -> void:
	# Exercise real MonsterBase physics below the review viewport, with no player.
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1600, 40)
	shape.shape = rectangle
	floor_body.add_child(shape)
	floor_body.position = Vector2(800, 1320)
	add_child(floor_body)
	var walker = MONSTER.instantiate()
	walker.data = DATA
	walker.position = Vector2(800, 1272)
	add_child(walker)
	walker.set_home(walker.position)
	walker._wander_timer = 10.0
	walker._wander_dir = -1
	await get_tree().create_timer(.6).timeout
	check(walker.is_on_floor(), "Walking test has ground contact")
	check(walker.position.x < 780 and walker.sprite.animation == &"Run", "Actual AI walks left using Run/Walk")
	check(not walker.sprite.flip_h, "Left walking faces left")
	check(walker.sprite.frame > 0, "Walk frames advance during movement")
	check(is_equal_approx(walker.sprite.speed_scale, .35), "Walking cadence follows existing wander speed")
	var left_x: float = walker.position.x
	walker._wander_dir = 1
	walker._wander_timer = 10.0
	await get_tree().create_timer(.6).timeout
	check(walker.position.x > left_x + 20 and walker.sprite.animation == &"Run", "Actual AI walks right using Run/Walk")
	check(walker.sprite.flip_h, "Right walking mirrors correctly")
	walker._wander_dir = 0
	walker._wander_timer = 10.0
	await get_tree().create_timer(.15).timeout
	check(walker.sprite.animation == &"Idle" and is_zero_approx(walker.velocity.x), "Stopping returns to Idle")
	check(is_equal_approx(walker.sprite.speed_scale, 1.0), "Idle speed resets after walking")
	walker.queue_free()
	floor_body.queue_free()
	await get_tree().process_frame
