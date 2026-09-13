extends Node

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else: print("PASS: ", message)

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	get_window().content_scale_size = Vector2i(1280,720)
	PlayerState.new_game()
	PlayerState.gm_god_mode = true
	var map = load("res://scenes/maps/prontera_field.tscn").instantiate()
	add_child(map)
	await get_tree().create_timer(1.0).timeout
	var player = map.player
	player.set_physics_process(false)
	player._play("Idle")
	player.sprite.pause()
	var visual: CharacterVisual = player.get_node("EquipVisual")
	visual._process(0)
	var sword: AnimatedSprite2D = visual._layers[Equipment.EquipSlot.WEAPON]
	check(PlayerState.equipment.weapon().item_id == &"novice_sword", "new player starts with novice sword equipped")
	check(sword.visible and sword.z_index >= 0, "idle sword draws above the map background")
	check(visual.get_index() < player.sprite.get_index(), "body and hand draw over idle grip at shared depth")
	for mirrored in [false,true]:
		player.sprite.flip_h = mirrored
		visual._process(0)
		check(sword.visible and (sword.scale.x < 0) == mirrored, "idle sword follows facing")
	player.sprite.flip_h = false
	var equipped := PlayerState.equipment.unequip(Equipment.EquipSlot.WEAPON)
	visual._process(0)
	check(not sword.visible, "unequipping hides the sword")
	PlayerState.equipment.equip(Equipment.EquipSlot.WEAPON,equipped)
	visual._process(0)
	check(sword.visible, "re-equipping restores idle sword")
	player.sprite.animation = &"Attack_Blade"
	player.sprite.frame = 1
	visual._process(0)
	check(sword.visible and sword.z_index == 1 and visual._attack_body.visible, "attack retains foreground sword and replacement body")
	player._play("Idle")
	player.sprite.pause()
	visual._process(0)
	check(sword.visible and not visual._attack_body.visible and player.sprite.self_modulate.a == 1, "return from attack restores idle layers")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/new_player_idle.png")
	print("NEW PLAYER IDLE: failures=",failures)
	map.queue_free()
	await get_tree().process_frame
	get_tree().quit(1 if failures else 0)
