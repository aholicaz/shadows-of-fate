extends Node2D
const OUT := "res://output/tower_weapons/"
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
	SaveManager.end_session()
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
		if id in [&"c8_solar_fang", &"c8_dawn_crown_blade"]: items.append(item)
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
		for flip in [false,true]:
			actor.sprite.flip_h = flip
			for pose in ["Idle_Runeblade","Attack_Runeblade_1","Attack_Runeblade_2","Attack_Runeblade_3"]:
				actor._play(pose,true)
				actor.sprite.pause()
				actor.sprite.frame = 3
				title = "%s / %s / %s"%[item.id,pose,flip]
				await capture("%s_%s_%s"%[item.id,pose,flip])
	var Loot = load("res://scripts/world/chapter8_loot.gd")
	var Tower = load("res://scripts/world/chapter8_tower_data.gd")
	check(items.size()==2,"Two registered weapons")
	for floor_number in range(1,51):
		for id in Tower.boss_roster(floor_number):
			var source = GameData.get_monster(StringName(id))
			Tower.gm_test = false
			var enemy = Tower.make_enemy(source,floor_number,true)
			var weapon_count := 0
			for drop in enemy.drops:
				check(Loot.allowed(drop.item_id),"Allowed tower loot")
				if drop.item_id in Loot.WEAPONS.values():
					weapon_count += 1
					check(Loot.WEAPONS.get(source.id)==drop.item_id,"Correct owner")
					check(drop.chance==10.0,"10 percent weapon chance")
			check(weapon_count==(1 if Loot.WEAPONS.has(source.id) else 0),"Weapon present only on owner")
			Tower.gm_test = true
			check(Tower.make_enemy(source,floor_number,true).drops.is_empty(),"GM drops suppressed")
	Tower.gm_test = false
	for item in items:
		check(item.type==ItemData.Type.WEAPON and item.refinable and item.card_slots==2,"Equipment contract")
		check(item.refine_progress(10).get(&"atk",0)>0,"Actual refine increases attack")
		check(item.icon.get_size()==Vector2(256,256),"Inventory icon size")
	var file := FileAccess.open(OUT+"audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"weapons":items.size()},"\t"))
	file.close()
	print("TOWER_WEAPON_AUDIT ",checks," failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
