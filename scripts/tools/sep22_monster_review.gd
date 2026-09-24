extends "res://scripts/tools/sep14_monster_review.gd"
## Local artwork review. New game is memory-only; SaveManager remains inactive.
const SEPT22 := ["hel_hound","ferryman","drowned","cinder_hound","slag_mantis","chainbound_ogre","kiln_sentinel","ash_knight"]
const REVIEW_OUT := "res://output/sep22_sprites/runtime/"

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
	if not OS.get_cmdline_user_args().has("--audit-sep22"):
		var bar := HBoxContainer.new()
		bar.position = Vector2(30,65)
		add_child(bar)
		var select := OptionButton.new()
		for id in SEPT22: select.add_item(id)
		select.item_selected.connect(func(i: int): await load_actor(SEPT22[i]); title=SEPT22[i]; queue_redraw())
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
		await load_actor(SEPT22[0])
		title = SEPT22[0]
		return
	capture_mode = true
	DirAccess.make_dir_recursive_absolute(REVIEW_OUT)
	for id in SEPT22:
		await load_actor(id)
		for anim in ["Idle","Walk","Run","Attack","Hit","Die","Skill"]:
			actor._play(anim,true)
			actor.sprite.pause()
			var count: int = actor.data.sprite_frames.get_frame_count(anim)
			check(count>1 or (id=="ash_knight" and anim in ["Idle","Walk","Run"]),id+" populated "+anim)
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
		for direction in [-1,1]:
			actor.facing=direction
			actor.sprite.flip_h=direction>0
			actor.state=actor.State.IDLE
			actor.hit_trace.clear()
			actor._attack()
			await wait_cast()
			var expected: Array[int] = actor.data.attack_hit_frame_list()
			check(actor.hit_trace.size()==expected.size(),id+" actual hit count "+str(direction))
			for i in mini(expected.size(),actor.hit_trace.size()):
				check(absi(actor.hit_trace[i]-expected[i])<=1,id+" hit matches visible contact "+str(i))
			check(actor.state==actor.State.IDLE,id+" attack recovers")
			if expected.size()>1:
				check(is_equal_approx(actor.data.attack_hit_damage_mult*expected.size(),1.0),id+" preserves total attack budget")
		if id=="kiln_sentinel":
			var impacts: Array = []
			actor.ground_slam_impact.connect(func(at: Vector2,_r: float,skill: bool,_i: int): impacts.append({"frame":actor.sprite.frame,"skill":skill,"at":at}))
			actor.state=actor.State.IDLE
			actor._cast_skill()
			await wait_cast()
			check(impacts.size()==1,"Kiln skill one ground slam")
			if impacts.size()==1:
				check(impacts[0].frame==7 and impacts[0].skill,"Kiln slam follows hammer impact")
			title="kiln_sentinel / ground slam"
			await snap("kiln_skill_recovery")
	var file := FileAccess.open(REVIEW_OUT+"audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("SEP22_AUDIT ",JSON.stringify({"checks":checks,"failures":failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func load_actor(id: String) -> void:
	if is_instance_valid(actor):
		actor.queue_free()
		await get_tree().process_frame
	actor=load("res://scenes/monsters/monster.tscn").instantiate()
	actor.set_script(load("res://scripts/tools/sep22_monster_probe.gd"))
	actor.data=load("res://data/monsters/"+id+".tres")
	add_child(actor)
	actor.set_physics_process(false)
	actor.position=Vector2(1130,940-actor.data.foot_offset())
	actor.sprite.position.y=-actor.hover_lift()
	actor._player=target
	if actor._hp_bar!=null:actor._hp_bar.hide()
	actor._play("Idle",true)
	actor._apply_fit()
