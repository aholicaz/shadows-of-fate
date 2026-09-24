extends "res://scripts/tools/sep14_monster_review.gd"
## Local artwork review. New game is memory-only; SaveManager remains inactive.
const CHAPTER6 := ["hel_hound", "mist_ghost", "ferryman", "name_warden", "erased_voice", "false_judge", "chained_garm", "nidhogg_spawn", "drowned"]
const REVIEW_OUT := "res://output/chapter6_sprites/runtime/"

func snap(file: String) -> void:
	queue_redraw()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(REVIEW_OUT + file + ".png")

func capture(file: String) -> void:
	await snap(file)

func _ready() -> void:
	get_window().size = Vector2i(1800,1040)
	get_window().content_scale_size = Vector2i(1800,1040)
	RenderingServer.set_default_clear_color(Color("18242c"))
	UI.layer.hide()
	PlayerState.new_game()
	PlayerState.stats.job_id = &"runeblade"
	player = load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	player.runeblade.set_process(false)
	player.remove_from_group("player")
	player.position = Vector2(440,796)
	player._play("Idle",true)
	player._apply_auto_fit()
	target = Target.new()
	add_child(target)
	target.position = Vector2(-10000,-10000)
	if not OS.get_cmdline_user_args().has("--audit-chapter6"):
		var bar := HBoxContainer.new()
		bar.position = Vector2(30,65)
		add_child(bar)
		var select := OptionButton.new()
		for id in CHAPTER6: select.add_item(id)
		select.item_selected.connect(func(i: int): await load_actor(CHAPTER6[i]); title=CHAPTER6[i]; queue_redraw())
		bar.add_child(select)
		var flip := Button.new()
		flip.text = "Flip"
		flip.pressed.connect(func(): actor.sprite.flip_h=not actor.sprite.flip_h; actor._apply_fit())
		bar.add_child(flip)
		for anim in ["Idle","Walk","Attack","Hit","Die","Skill"]:
			var button := Button.new()
			button.text = anim
			button.pressed.connect(func(): actor._play(anim,true); actor._apply_fit())
			bar.add_child(button)
		await load_actor(CHAPTER6[0])
		title = CHAPTER6[0]
		return
	capture_mode = true
	DirAccess.make_dir_recursive_absolute(REVIEW_OUT)
	for id in CHAPTER6:
		await load_actor(id)
		for anim in ["Idle","Walk","Run","Attack","Hit","Die","Skill"]:
			actor._play(anim,true)
			actor.sprite.pause()
			var count: int = actor.data.sprite_frames.get_frame_count(anim)
			check(count>1,id+" populated "+anim)
			check(actor.data.sprite_frames.get_animation_loop(anim)==(anim in ["Idle","Walk","Run"]),id+" loop "+anim)
			for flip in [false,true]:
				actor.sprite.flip_h = flip
				var initial_scale := Vector2.ZERO
				for f in count:
					actor.sprite.frame = f
					actor._apply_fit()
					if f==0: initial_scale=actor.sprite.scale
					check(actor.sprite.scale.is_equal_approx(initial_scale),id+" constant scale "+anim)
					var tex: Texture2D = actor.sprite.sprite_frames.get_frame_texture(anim,f)
					check(tex is AtlasTexture and tex.get_size()==Vector2(1600,1400),id+" registered canvas "+anim)
					if (anim!="Run" and f in [0,count/2,count-1]):
						title = "%s / %s / frame %d / %s / player 288 px" % [id,anim,f,"R" if flip else "L"]
						await snap("%s_%s_%02d_%s" % [id,anim,f,"R" if flip else "L"])
	for id in ["mist_ghost", "erased_voice", "false_judge"]:
		await load_actor(id)
		for direction in [-1,1]:
			cast_direction=direction
			released.clear()
			actor.position.x=1250 if direction<0 else 550
			actor.facing=direction
			actor.sprite.flip_h=direction>0
			actor.state=actor.State.IDLE
			target.position=Vector2(actor.position.x+direction*600,940)
			actor._attack()
			await wait_cast()
			check(released.size()==1,id+" one authored release "+str(direction))
			check(actor.state==actor.State.IDLE,id+" finishes attack")
		await sweep_test()
		target.remove_from_group("player")
		for child in get_children():
			if child is StaticBody2D: child.queue_free()
		await get_tree().physics_frame
	await load_actor("chained_garm")
	var freed := load("res://data/sprites/monsters/garm_freed_frames.tres") as SpriteFrames
	check(freed.get_frame_count("Walk")==16,"Freed Garm walking cycle")
	var departure = preload("res://scripts/world/garm_freed_departure.gd")
	departure.play(actor)
	await get_tree().create_timer(0.6).timeout
	title="Freed Garm / release cutscene"
	await snap("garm_freed_departure")
	await get_tree().create_timer(1.6).timeout
	check(is_instance_valid(actor) and not actor.visible,"Departure leaves quest cleanup to caller")
	var report := {"checks":checks,"failures":failures}
	var file := FileAccess.open(REVIEW_OUT+"audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("CHAPTER6_AUDIT ",JSON.stringify(report))
	get_tree().quit(0 if failures.is_empty() else 1)
