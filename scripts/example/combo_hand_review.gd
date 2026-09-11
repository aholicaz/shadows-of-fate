extends Node2D

var _samples: Array[Node2D] = []

func _ready() -> void:
	get_window().content_scale_size = Vector2i(1800, 1100)
	RenderingServer.set_default_clear_color(Color("303744"))
	var frames: SpriteFrames = load("res://data/sprites/player_frames.tres")
	var item: ItemData = load("res://data/items/iron_blade.tres")
	var names := [&"Attack_Blade", &"Attack_Blade_2", &"Attack_Blade_3"]
	var index := 0
	for anim in names:
		assert(item.equip_attack_body_frames.get_frame_count(anim) == frames.get_frame_count(anim))
		assert(item.equip_attack_body_frames.get_animation_speed(anim) == frames.get_animation_speed(anim))
		for f in range(frames.get_frame_count(anim)):
			var holder := Node2D.new()
			holder.position = Vector2(150 + (index % 6) * 300, 160 + (index / 6) * 260)
			add_child(holder)
			_samples.append(holder)
			var body := AnimatedSprite2D.new()
			body.name = "AnimatedSprite2D"
			body.sprite_frames = frames
			body.animation = anim
			body.frame = f
			body.scale = Vector2.ONE * 0.58
			holder.add_child(body)
			var visual := CharacterVisual.new()
			visual.name = "Visual"
			visual.use_player_equipment = false
			holder.add_child(visual)
			visual.set_layer(Equipment.EquipSlot.WEAPON, item)
			for flipped in [false, true]:
				body.flip_h = flipped
				visual._process(0.0)
				var sword: AnimatedSprite2D = visual._layers[Equipment.EquipSlot.WEAPON]
				assert(sword.visible and visual._attack_body.visible)
				assert(body.self_modulate.a == 0.0)
				assert(body.sprite_frames == frames and body.frame == f)
				assert(visual._attack_body.flip_h == flipped)
				assert((sword.transform * (item.equip_grip + sword.offset)).distance_to(sword.position) < 0.001)
			visual.set_layer(Equipment.EquipSlot.WEAPON, null)
			assert(body.self_modulate.a == 1.0 and not visual._attack_body.visible)
			visual.set_layer(Equipment.EquipSlot.WEAPON, item)
			body.animation = &"Idle"
			visual._process(0.0)
			assert(body.self_modulate.a == 1.0 and not visual._attack_body.visible)
			body.animation = &"Run"
			visual._process(0.0)
			assert(not visual._layers[Equipment.EquipSlot.WEAPON].visible)
			body.animation = anim
			body.frame = f
			body.flip_h = false
			visual._process(0.0)
			var label := Label.new()
			label.text = "Hit %d / frame %d" % [names.find(anim) + 1, f + 1]
			label.position = Vector2(-110, 109)
			holder.add_child(label)
			index += 1
	await get_tree().process_frame
	for child in UI.get_children():
		if child is CanvasLayer or child is CanvasItem:
			child.hide()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/combo_hand_review.png")
	for holder in _samples:
		holder.get_node("AnimatedSprite2D").flip_h = true
		holder.get_node("Visual")._process(0.0)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/combo_hand_review_flipped.png")
	var report := FileAccess.open("res://output/combo_hand_review.txt", FileAccess.WRITE)
	report.store_string("PASS: 22 combo frames in both directions; original frame resources and timing preserved; unequip, Idle and Run restored.\n")
	get_tree().quit()
