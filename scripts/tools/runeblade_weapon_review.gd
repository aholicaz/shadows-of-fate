extends Node2D
const OUT := "res://output/runeblade_weapon/"
const TRACK = preload("res://scripts/entities/runeblade_weapon_track.gd")
var actor
var visual
var failures: Array[String] = []
var checks := 0
var title := "RUNEBLADE / EQUIPPED WEAPONS"
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func _draw() -> void:
	draw_rect(Rect2(0,580,1100,120),Color("354454"))
	draw_line(Vector2(0,580),Vector2(1100,580),Color("9db4c6"),2)
	draw_string(ThemeDB.fallback_font,Vector2(30,45),title,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE)
func fit() -> void:
	actor._apply_auto_fit()
	visual._process(0)
func capture(file: String) -> void:
	fit()
	queue_redraw()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+file+".png")
func _ready() -> void:
	get_window().size = Vector2i(1100,700)
	get_window().content_scale_size = Vector2i(1100,700)
	RenderingServer.set_default_clear_color(Color("18242c"))
	UI.layer.hide()
	PlayerState.new_game()
	PlayerState.stats.job_id = &"runeblade"
	actor = load("res://scenes/player/player.tscn").instantiate()
	add_child(actor)
	actor.set_physics_process(false)
	actor.runeblade.set_process(false)
	actor.position = Vector2(550,436)
	actor._play("Idle",true)
	visual = actor.get_node("EquipVisual")
	await get_tree().process_frame
	var layer: AnimatedSprite2D = visual._layers[Equipment.EquipSlot.WEAPON]
	var items: Array[ItemData] = []
	for id in GameData.items:
		var item: ItemData = GameData.get_item(id)
		if item.equip_follow_idle_hand: items.append(item)
	for item in items:
		visual.set_layer(Equipment.EquipSlot.WEAPON,item)
		for pose in ["Idle_Runeblade","Attack_Runeblade_1","Attack_Runeblade_2","Attack_Runeblade_3","Run_Runeblade"]:
			actor._play(pose,true)
			actor.sprite.pause()
			for flip in [false,true]:
				actor.sprite.flip_h = flip
				for frame in range(actor.sprite.sprite_frames.get_frame_count(pose)):
					actor.sprite.frame = frame
					fit()
					check(layer.visible,"Equipped sword visible: %s/%s/%d"%[item.id,pose,frame])
					var expected := 288.0/705.0*item.equip_hand_scale
					check(absf(absf(layer.global_scale.x)-expected)<.0001,"Weapon keeps world size")
				if pose=="Run_Runeblade":
					check(layer.z_index==0 and visual.get_index()<actor.sprite.get_index(),"Back carry is behind body")
		for pose in ["Anvil_Runeblade","Faultline_Runeblade","Worldcleaver_Runeblade","Erasing_Runeblade","Lunge_Runeblade","Wave_Runeblade","Flurry_Runeblade","Source_rb_skill_2108","Source_rb_skill_2055","Source_rb_skill_2044","Source_rb_skill_2020"]:
			actor._play(pose,true)
			actor.sprite.pause()
			for flip in [false,true]:
				actor.sprite.flip_h = flip
				for frame in range(actor.sprite.sprite_frames.get_frame_count(pose)):
					actor.sprite.frame = frame
					fit()
					check(layer.visible and layer.z_index==1,"Skill equipped sword: %s/%s/%d"%[item.id,pose,frame])
					check(absf(absf(layer.global_scale.x)-288.0/705.0*item.equip_hand_scale)<.0001,"Skill weapon world size")
	visual.set_layer(Equipment.EquipSlot.WEAPON,GameData.get_item(&"katana"))
	for source in ["2108","2055","2044","2020"]:
		actor._play("Source_rb_skill_"+source,true)
		actor.sprite.pause()
		for flip in [false,true]:
			actor.sprite.flip_h = flip
			for f in [4,8,12,15,18,20,23,27]:
				actor.sprite.frame = f
				title = "Skill %s / frame %d"%[source,f+1]
				await capture("skill_%s_%02d_%s"%[source,f+1,"R" if flip else "L"])
	for flip in [false,true]:
		actor.sprite.flip_h = flip
		for pose in ["Idle_Runeblade","Attack_Runeblade_1","Attack_Runeblade_2","Attack_Runeblade_3","Run_Runeblade"]:
			actor._play(pose,true)
			actor.sprite.pause()
			var selected: Array = [0,3,6] if pose.begins_with("Attack") else ([0,5,12,20] if pose=="Run_Runeblade" else [0,6,32,63,64,80,95])
			for f in selected:
				actor.sprite.frame = mini(f,actor.sprite.sprite_frames.get_frame_count(pose)-1)
				title = "%s / frame %d / %s"%[pose,actor.sprite.frame+1,"right" if flip else "left"]
				await capture("%s_%02d_%s"%[pose,f,"R" if flip else "L"])
	# The socket and scale at a source splice must agree on both sides of the boundary.
	actor._play("Idle",true)
	for flip in [false,true]:
		actor.sprite.flip_h = flip
		for f in [31,63,95]:
			actor.sprite.set_frame_and_progress(f,.99999)
			fit()
			var a := layer.global_position
			var sa := layer.global_scale
			actor.sprite.set_frame_and_progress((f+1)%96,0)
			fit()
			check(a.distance_to(layer.global_position)<.01,"Idle splice position continuity")
			check(sa.distance_to(layer.global_scale)<.0001,"Idle splice sword scale continuity")
	actor.sprite.flip_h = false
	actor._play("Idle",true)
	actor.sprite.speed_scale = 1
	title = "Idle / current breathing and sigh hand tracks"
	for i in range(144):
		await get_tree().create_timer(.085).timeout
		await capture("idle_motion_%03d"%i)
	var file := FileAccess.open(OUT+"audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"weapons":items.size()},"\t"))
	file.close()
	print("RUNEBLADE_WEAPON_AUDIT ",checks," failures=",failures," weapons=",items.size())
	get_tree().quit(0 if failures.is_empty() else 1)
