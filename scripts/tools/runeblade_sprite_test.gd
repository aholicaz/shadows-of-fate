extends Node2D
const OUT := "res://output/runeblade_full/"
const VISUAL = preload("res://scripts/entities/runeblade_visual.gd")
var failures: Array[String] = []
var checks := 0
var actor
var label := ""
var combos: Array = []
var gallery_mode := false
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func _draw() -> void:
	if gallery_mode: return
	draw_rect(Rect2(0,580,1100,120),Color("354454"))
	draw_line(Vector2(0,580),Vector2(1100,580),Color("9db4c6"),2)
	draw_string(ThemeDB.fallback_font,Vector2(30,45),label,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE)
func capture(file: String) -> void:
	queue_redraw()
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(OUT+file+".png")==OK,"Captured "+file)
func _ready() -> void:
	get_window().size = Vector2i(1100,700)
	get_window().content_scale_size = Vector2i(1100,700)
	RenderingServer.set_default_clear_color(Color("18242c"))
	UI.layer.hide()
	PlayerState.new_game()
	actor = load("res://scenes/player/player.tscn").instantiate()
	add_child(actor)
	actor.set_physics_process(false)
	actor.runeblade.set_process(false)
	actor.position = Vector2(550,436)
	var original: SpriteFrames = actor.sprite.sprite_frames
	var old_run: String = actor._resolve_anim("Run")
	var old_scale: float = actor._fit_info(&"Attack_Blade").scale
	PlayerState.stats.job_id = &"runeblade"
	check(actor._play("Idle",true)=="Idle_Runeblade","Idle route")
	var frames: SpriteFrames = actor.sprite.sprite_frames
	check(frames.get_frame_count(&"Idle_Runeblade")==96,"All breathing frames twice plus complete sigh")
	check(not original.has_animation(&"Idle_Runeblade"),"Original shared frames unchanged")
	var routes: Dictionary = frames.get_meta("rb_routes")
	for request in routes:
		check(actor._play(request,true)==routes[request],"Route "+request)
	var skills: Dictionary = frames.get_meta("rb_skill_routes")
	for id in skills:
		check(actor.skill_animation(StringName(id))==skills[id],"Skill "+id)
	var registration: Dictionary = frames.get_meta("rb_frame_registration")
	for pose in frames.get_meta("rb_registration"):
		if String(pose).begins_with("Source_"): continue
		actor._play(pose,true)
		actor.sprite.pause()
		var count := frames.get_frame_count(pose)
		for flipped in [false,true]:
			actor.sprite.flip_h = flipped
			for f in [0,count/2,count-1]:
				actor.sprite.frame = int(f)
				actor._apply_auto_fit()
				var reg: Dictionary = registration[pose][int(f)]
				var anchor := Vector2(reg.anchor[0],reg.anchor[1])
				var p := anchor-frames.get_frame_texture(pose,int(f)).get_size()*.5
				if flipped:p.x=-p.x
				check(actor.sprite.to_global(p+actor.sprite.offset).distance_to(actor.foot_position()+Vector2(-1,0))<.02,"Anchor "+pose)
			if pose in ["Idle_Runeblade","Run_Runeblade","Death_Runeblade","Attack_Runeblade_1","Attack_Runeblade_2","Attack_Runeblade_3","Worldcleaver_Runeblade"]:
				actor.sprite.frame = mini(count-1,int(frames.get_meta("rb_hit_frames",{}).get(pose,count/2)))
				label = "%s / %s / 288 px" % [pose,"right" if flipped else "left"]
				await capture(pose+("_right" if flipped else "_left"))
		if VISUAL.baked_weapon(frames,pose):
			var gear = actor.get_node("EquipVisual")
			gear._process(0)
			for layer in gear._layers.values():check(not layer.visible,"No overlaid equipment "+pose)
	actor.sprite.flip_h = false
	actor.combo_step_started.connect(func(step,pose,mult):combos.append([step,pose,mult]))
	actor.reset_combo()
	for i in range(3):
		actor.start_attack()
		await get_tree().create_timer(PlayerState.stats.attack_interval()+.07).timeout
		actor.attack_cooldown = 0
	check(combos.size()==3,"Three real attack starts")
	for i in range(mini(3,combos.size())):
		check(combos[i][0]==i and combos[i][1]=="Attack_Runeblade_%d"%(i+1),"Real combo order %d"%i)
	PlayerState.stats.job_id = &"swordsman"
	check(actor._resolve_anim("Run")==old_run,"Legacy run unchanged")
	check(is_equal_approx(actor._fit_info(&"Attack_Blade").scale,old_scale),"Legacy attack scale unchanged")
	PlayerState.stats.job_id = &"runeblade"
	actor._play("Idle",true)
	actor.sprite.speed_scale = 1
	label = "Idle / breathing to sigh / original frames blended in Godot"
	# Capture a complete live cycle for motion review. This also exercises shader transitions.
	for i in range(96):
		await get_tree().create_timer(.125).timeout
		await capture("idle_motion_%03d"%i)
	actor.hide()
	gallery_mode = true
	var gallery = load("res://runeblade_sprite_gallery.tscn").instantiate()
	add_child(gallery)
	await get_tree().process_frame
	check(gallery.selector.item_count==31,"Gallery exposes all animations")
	gallery.play_pose("Attack_Runeblade_3")
	gallery.action("Flip")
	gallery.action("Next frame")
	check(gallery.body.flip_h and not gallery.body.is_playing(),"Gallery flip and frame stepping")
	await capture("gallery")
	gallery.queue_free()
	var result := {"checks":checks,"failures":failures,"combos":combos,"renderer":RenderingServer.get_current_rendering_method()}
	var file := FileAccess.open(OUT+"audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	print("RUNEBLADE_SPRITE_AUDIT ",JSON.stringify(result))
	get_tree().quit(0 if failures.is_empty() else 1)
