extends Node2D

var samples: Array[Dictionary] = []

func _ready() -> void:
	get_window().content_scale_size = Vector2i(1800, 1250)
	RenderingServer.set_default_clear_color(Color("303744"))
	var frames: SpriteFrames = load("res://data/sprites/player_frames.tres")
	var names := [&"Idle", &"Attack_Blade", &"Attack_Blade_2", &"Attack_Blade_3"]
	var previous: ItemInstance = PlayerState.equipment.weapon()
	var filenames := DirAccess.get_files_at("res://data/items")
	filenames.sort()
	var checks := 0
	for filename in filenames:
		if not filename.ends_with(".tres"):
			continue
		var item = load("res://data/items/" + filename)
		if not item is ItemData or item.weapon_type != &"sword":
			continue
		assert(item.equip_follow_idle_hand and item.equip_attack_body_frames != null, filename)
		assert(item.equip_texture != null and item.equip_sprite_frames == null, filename)
		var index := samples.size()
		var holder := Node2D.new()
		holder.position = Vector2(180 + (index % 5) * 350, 190 + (index / 5) * 300)
		add_child(holder)
		var body := AnimatedSprite2D.new()
		body.name = "AnimatedSprite2D"
		body.sprite_frames = frames
		body.animation = &"Idle"
		body.scale = Vector2.ONE * 0.27
		holder.add_child(body)
		var visual := CharacterVisual.new()
		visual.use_player_equipment = false
		holder.add_child(visual)
		visual.set_layer(Equipment.EquipSlot.WEAPON, item)
		PlayerState.equipment.slots[Equipment.EquipSlot.WEAPON] = ItemInstance.create(item.id)
		var player = load("res://scripts/entities/player.gd").new()
		player.sprite = body
		assert(player._fallback_chain("Idle")[0] == "Idle", filename)
		for step in range(3):
			assert(player.combo_attack_animation(step) == String(names[step + 1]), filename)
		player.free()
		for anim in names:
			body.animation = anim
			for f in range(frames.get_frame_count(anim)):
				body.frame = f
				for mirrored in [false, true]:
					body.flip_h = mirrored
					visual._process(0.0)
					var sword: AnimatedSprite2D = visual._layers[Equipment.EquipSlot.WEAPON]
					assert(sword.visible and sword.sprite_frames.get_frame_texture(&"default", 0) == item.equip_texture, filename)
					assert(visual._attack_body.visible == (anim != &"Idle"), filename)
					assert(body.self_modulate.a == (1.0 if anim == &"Idle" else 0.0), filename)
					assert(body.sprite_frames == frames, filename)
					checks += 1
		visual.set_layer(Equipment.EquipSlot.WEAPON, null)
		assert(body.self_modulate.a == 1.0 and not visual._attack_body.visible, filename)
		visual.set_layer(Equipment.EquipSlot.WEAPON, item)
		body.animation = &"Run"
		visual._process(0.0)
		assert(not visual._layers[Equipment.EquipSlot.WEAPON].visible, filename)
		var label := Label.new()
		label.text = String(item.id)
		label.position = Vector2(-135, 117)
		holder.add_child(label)
		samples.append({"body": body, "visual": visual})
	PlayerState.equipment.slots[Equipment.EquipSlot.WEAPON] = previous
	assert(samples.size() == 17)
	await get_tree().process_frame
	for child in UI.get_children():
		if child is CanvasLayer or child is CanvasItem:
			child.hide()
	for page in range(4):
		for sample in samples:
			var body: AnimatedSprite2D = sample.body
			body.animation = names[page]
			body.frame = [0, 1, 3, 5][page]
			body.flip_h = page == 2
			body.scale = Vector2.ONE * (0.27 if page == 0 else 0.65)
			sample.visual._process(0.0)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/all_swords_%d.png" % page)
	var report := FileAccess.open("res://output/all_swords_review.txt", FileAccess.WRITE)
	report.store_string("PASS: %d swords, %d frame/direction checks; Idle and all three combo routes; texture identity; original animation resource preserved; unequip and Run restoration.\n" % [samples.size(), checks])
	get_tree().quit()
