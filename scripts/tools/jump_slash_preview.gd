extends Node2D
func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	PlayerState.stats.job_id = &"runeblade"
	get_window().size = Vector2i(1800,1000)
	get_window().content_scale_size = Vector2i(1800,1000)
	RenderingServer.set_default_clear_color(Color("18242c"))
	UI.layer.hide()
	var actor = load("res://scenes/player/player.tscn").instantiate()
	add_child(actor)
	actor.set_physics_process(false)
	actor.runeblade.set_process(false)
	actor.position = Vector2(800,720)
	actor._play("JumpSlash_Runeblade",true)
	actor.sprite.pause()
	var wave := preload("res://scripts/entities/jump_slash_wave.gd").new()
	wave.caster = actor
	wave.skill = GameData.get_skill(&"jump_slash")
	add_child(wave)
	wave.set_physics_process(false)
	wave.global_position = actor.foot_position()
	for right in [false,true]:
		actor.sprite.flip_h = right
		wave.direction = 1 if right else -1
		wave.art.scale.x = wave.direction*2.7
		wave.art.position.x = wave.direction*540.0
		for frame in [5,11,17,23,31]:
			actor.sprite.frame = frame
			actor._apply_auto_fit()
			wave.visible = frame >= 17 and frame < 31
			wave.art.frame = 2 if frame==17 else 4
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://output/jump_slash_import/pose_%s_%02d.png"%["right" if right else "left",frame])
	print("JUMP_SLASH_RENDER_PASS")
	get_tree().quit()
