extends Node2D
const DASH = preload("res://scripts/entities/rune_dash_fx.gd")
const RAIN = preload("res://scripts/entities/worldcleaver_rain_visual.gd")
var checks := 0
func check(ok: bool, note: String) -> void:
	assert(ok, note)
	checks += 1
	print("PASS: ", note)

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/rune_upgrade_" + name + ".png")

func _ready() -> void:
	get_window().size = Vector2i(1400, 1000)
	get_window().content_scale_size = Vector2i(1400, 1000)
	RenderingServer.set_default_clear_color(Color("#111b29"))
	PlayerState.new_game()
	PlayerState.stats.job_id = &"runeblade"
	PlayerState.equipment.slots[Equipment.EquipSlot.WEAPON] = ItemInstance.create(&"iron_blade")
	var player = load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	player.position = Vector2(200, 690)
	await get_tree().process_frame
	for child in UI.get_children():
		if child is CanvasLayer or child is CanvasItem: child.hide()
	var field = preload("res://scripts/entities/runic_blade_field.gd").new()
	field.configure(player.runeblade, &"worldcleaver", 14, Vector2(740, 820), 1)
	add_child(field)
	field.set_process(false)
	var rain = field.get_children().filter(func(n): return n.get_script() == RAIN)[0]
	rain.set_process(false)
	check(RAIN.START_HEIGHT == 390.0 * 1.5, "rain starts fifty percent higher")
	check(field.pulses == 5 and field.interval == 0.2 and field.height == 420, "five pulses and combat height preserved")
	check(rain.swords.size() == 45, "45 independently scheduled blades across five waves")
	check(rain.drops[0].start != rain.drops[1].start and rain.drops[0].fall != rain.drops[1].fall, "release times and fall speeds differ")
	check(rain.drops.all(func(d): return d.start + d.fall + 0.12 < 1.34), "all rain finishes within field lifetime")
	for t in [0.115, 0.275, 0.435]:
		field.elapsed = t
		rain.update_visual()
		field.queue_redraw()
		await shot("rain_" + str(int(t * 1000)))
	field.elapsed = 0
	field.pulse_count = 0
	field.next_pulse = 0.16
	for i in range(100): field._process(0.01)
	check(field.pulse_count == 5, "all five gameplay strikes remain scheduled")
	field.queue_free()
	await get_tree().process_frame
	get_window().size = Vector2i(1000, 650)
	get_window().content_scale_size = Vector2i(1000, 650)
	var camera := Camera2D.new()
	camera.position = Vector2(650, 635)
	camera.zoom = Vector2(1.25, 1.25)
	add_child(camera)
	for dodge in [true, false]:
		for dir in [-1, 1]:
			player.position = Vector2(650, 680)
			player.facing = dir
			player.is_attacking = true
			player._update_facing()
			player._play("Dash" if dodge else player.skill_animation(&"rune_lunge"), true)
			player.sprite.pause()
			player.sprite.frame = 2 if dodge else 6
			player._dodge_time = 0.5
			player._dodge_wall_stopped = false
			player._dash_time = 0.5
			var fx = DASH.new()
			fx.caster = player
			fx.facing = dir
			fx.dodge = dodge
			player.add_child(fx)
			fx.set_process(false)
			fx.speed.pause()
			fx.gold.pause()
			for i in range(10):
				player.position.x += dir * 10
				fx._process(0.016)
			await get_tree().process_frame
			fx.update_visual()
			check(fx.speed.sprite_frames.get_frame_count(&"default") == 4 and fx.gold.sprite_frames.get_frame_count(&"default") == 4, "both imagegen layers contain four animation frames")
			check(fx.speed.scale.x * dir < 0 and fx.gold.scale.x * dir < 0 if not dodge else fx.speed.scale.x * dir < 0, "speed and thrust face movement direction")
			check(fx.z_index < player.sprite.z_index and fx.show_behind_parent, "effects are behind the character")
			check(fx.gold.visible == not dodge, "golden thrust replaces the rune lunge star")
			if not dodge:
				var vis = player.get_node("EquipVisual")
				var layer = vis._layers[Equipment.EquipSlot.WEAPON]
				check(fx.gold.global_position.is_equal_approx(layer.to_global(Vector2(15,1222) + layer.offset)), "golden wedge begins at equipped blade tip")
			await shot(("dash_" if dodge else "lunge_") + str(dir))
			if not dodge and dir == -1:
				for frame in range(4):
					fx.age = frame / 18.0 + 0.00001
					fx.update_visual()
					check(fx.gold.frame == frame, "golden thrust advances to frame " + str(frame))
					await shot("gold_motion_" + str(frame))
				fx.age = 0.16
			check(fx.speed.modulate.a > 0 and fx.ending < 0, "animated speed trail active during movement")
			if dodge:
				check(not fx.speed.sprite_frames.get_animation_loop(&"default"), "dash burst never loops")
				fx._process(0.039)
				check(fx.speed.frame == 3 and fx.visible and not fx.is_queued_for_deletion(), "fourth dash frame displays before burst ends")
				fx._process(0.002)
				check(not fx.visible and fx.is_queued_for_deletion() and player._dodge_time > 0, "dash effect disappears at 0.2 seconds even while player is moving")
			player._dodge_time = 0
			player._dash_time = 0
			fx._process(0.01)
			fx._process(0.13)
			check(fx.is_queued_for_deletion(), "speed effect cleans up when movement ends")
			await get_tree().process_frame
	player._dodge_cd = 0
	player._dodge_time = 0
	player.is_attacking = false
	player._start_dodge()
	check(player.get_children().any(func(n): return n.get_script() == DASH), "real dodge creates animated speed effect")
	player.queue_free()
	print("RUNE UPGRADE: ", checks, " checks passed")
	get_tree().quit()

func _draw() -> void:
	draw_line(Vector2(60, 820), Vector2(1340, 820), Color("#455363"), 2)
