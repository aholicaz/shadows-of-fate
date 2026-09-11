extends Node2D

func _ready() -> void:
	get_window().content_scale_size = Vector2i(1200, 900)
	RenderingServer.set_default_clear_color(Color("303744"))
	var frames: SpriteFrames = load("res://data/sprites/player_frames.tres")
	var item: ItemData = load("res://data/items/iron_blade.tres")
	var previous: ItemInstance = PlayerState.equipment.weapon()
	PlayerState.equipment.slots[Equipment.EquipSlot.WEAPON] = ItemInstance.create(&"iron_blade")
	var player = load("res://scripts/entities/player.gd").new()
	assert(player._fallback_chain("Idle")[0] == "Idle")
	assert(player._fallback_chain("Attack")[0] == "Attack_Blade")
	PlayerState.equipment.slots[Equipment.EquipSlot.WEAPON] = previous
	player.free()
	for i in range(9):
		var holder := Node2D.new()
		holder.position = Vector2(205 + (i % 3) * 380, 155 + (i / 3) * 280)
		add_child(holder)
		var body := AnimatedSprite2D.new()
		body.name = "AnimatedSprite2D"
		body.sprite_frames = frames
		body.animation = &"Idle"
		body.frame = i
		body.scale = Vector2.ONE * 0.31
		body.flip_h = i >= 6
		holder.add_child(body)
		var visual := CharacterVisual.new()
		visual.use_player_equipment = false
		holder.add_child(visual)
		visual.set_layer(Equipment.EquipSlot.WEAPON, item)
		visual._process(0.0)
		var layer: AnimatedSprite2D = visual._layers[Equipment.EquipSlot.WEAPON]
		assert(layer.visible)
		assert((layer.transform * (item.equip_grip + layer.offset)).distance_to(layer.position) < 0.01)
		body.animation = &"Run"
		visual._process(0.0)
		assert(not layer.visible)
		body.animation = &"Idle"
		body.frame = i
		visual.set_layer(Equipment.EquipSlot.WEAPON, null)
		assert(not layer.visible)
		visual.set_layer(Equipment.EquipSlot.WEAPON, item)
		visual._process(0.0)
		var caption := Label.new()
		caption.text = "Idle %d%s" % [i + 1, " (flipped)" if body.flip_h else ""]
		caption.position = Vector2(-90, 133)
		holder.add_child(caption)
	await get_tree().process_frame
	for child in UI.get_children():
		if child is CanvasLayer or child is CanvasItem:
			child.hide()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/idle_hand_review.png")
	var report := FileAccess.open("res://output/idle_hand_review.txt", FileAccess.WRITE)
	report.store_string("PASS: 9 Idle frames, mirrored grip, hidden on Run, unequip and re-equip.\n")
	get_tree().quit()
