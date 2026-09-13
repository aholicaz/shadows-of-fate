extends Node2D
const OUT := "res://output/spriteflow/idle_size_shadow/"
const PLAYER = preload("res://scenes/player/player.tscn")
const MONSTER = preload("res://scenes/monsters/monster.tscn")
var errors: Array[String] = []
var checks := 0
var actors: Array = []
var player
var title := "RUNE BLADE / CHAPTER 3"
var labels: Array = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		errors.append(message)
		push_error(message)
func _draw() -> void:
	draw_rect(Rect2(0,850,2000,150),Color("809083"))
	draw_line(Vector2(0,850),Vector2(2000,850),Color("b5c1af"),2)
	draw_string(ThemeDB.fallback_font,Vector2(40,55),title,HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(40,90),"Original character height: 288 px | Grounded shadows | Native game renderer",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("a9b9c6"))
	for entry in labels:
		draw_string(ThemeDB.fallback_font,entry[0],entry[1],HORIZONTAL_ALIGNMENT_CENTER,440,19,Color.WHITE)
func capture(file: String) -> void:
	queue_redraw()
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(OUT+file+".png")==OK,"Save rendered "+file)
func _ready() -> void:
	get_window().size = Vector2i(2000,1000)
	get_window().content_scale_size = Vector2i(2000,1000)
	RenderingServer.set_default_clear_color(Color("18242c"))
	UI.layer.hide()
	PlayerState.new_game()
	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(5000,150)
	shape.shape = rect
	ground.position = Vector2(1000,925)
	ground.add_child(shape)
	add_child(ground)
	player = PLAYER.instantiate()
	add_child(player)
	player.set_physics_process(false)
	player.position = Vector2(170,850-player._feet_y())
	await test_job()
	await test_sizes()
	await test_npcs()
	var file := FileAccess.open(OUT+"audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":errors,"renderer":RenderingServer.get_current_rendering_method()},"\t"))
	file.close()
	print("IDLE_SIZE_SHADOW_AUDIT checks=",checks," failures=",JSON.stringify(errors))
	get_tree().quit(0 if errors.is_empty() else 1)
func test_job() -> void:
	var old_idle: String = player._play("Idle",true)
	var old_run: String = player._resolve_anim("Run")
	var old_attack_scale: float = player._fit_info(&"Attack_Blade").scale
	var original: SpriteFrames = player.sprite.sprite_frames
	var old_run_tex := original.get_frame_texture(old_run,0)
	PlayerState.stats.job_id = &"runeblade"
	check(player._play("Idle",true)=="Idle_Runeblade","Runeblade selects new idle")
	check(player.sprite.sprite_frames.get_frame_count(&"Idle_Runeblade")==32,"32 native idle frames")
	check(not original.has_animation(&"Idle_Runeblade"),"Shared original SpriteFrames remains unchanged")
	player.position.x = 1000
	player.sprite.pause()
	var visual: CharacterVisual = player.get_node("EquipVisual")
	for facing in [false,true]:
		player.sprite.flip_h = facing
		for f in [0,8,16,24,31]:
			player.sprite.frame = f
			player._apply_auto_fit()
			visual._process(0)
			var tex: Texture2D = player.sprite.sprite_frames.get_frame_texture(&"Idle_Runeblade",f)
			var anchor: Vector2 = player.sprite.sprite_frames.get_meta("runeblade_idle_anchor")
			var point := anchor-tex.get_size()*.5
			if facing: point.x = -point.x
			check(player.sprite.to_global(point+player.sprite.offset).distance_to(player.foot_position()+Vector2(player.sprite.position.x,0))<.01,"Idle feet stay fixed")
			check(visual._layers[Equipment.EquipSlot.WEAPON].visible,"Equipped sword follows new idle")
		await get_tree().physics_frame
		await get_tree().physics_frame
		await capture("runeblade_right" if facing else "runeblade_left")
	check(player._play("Run",true)==old_run,"Missing Run uses original animation")
	check(player.sprite.sprite_frames.get_frame_texture(old_run,0)==old_run_tex,"Run texture remains identical")
	check(is_equal_approx(player._fit_info(&"Attack_Blade").scale,old_attack_scale),"Other attack sizing unchanged")
	PlayerState.stats.job_id = &"swordsman"
	check(player._play("Idle",true)==old_idle,"Other class retains original idle")
	PlayerState.stats.job_id = &"runeblade"
	player._play("Idle",true)
	player.sprite.flip_h = false
	player.position.x = 170
func test_sizes() -> void:
	var groups := [
		["root_crawler","thorn_hound","bog_lurker"],
		["mist_sprite","withered_treant","vanir_sentinel"],
		["war_wraith","thorn_matriarch","gullveig_ember"],
		["baphomet_jr","baphomet"]]
	for page in range(groups.size()):
		labels.clear()
		labels.append([Vector2(20,930),"Runeblade / 288"])
		for i in range(groups[page].size()):
			var mid: String = groups[page][i]
			var actor = MONSTER.instantiate()
			actor.data = load("res://data/monsters/"+mid+".tres")
			actor.position = Vector2(670+i*510,850-actor.data.foot_offset())
			add_child(actor)
			actor.set_physics_process(false)
			actor._play("Idle",true)
			actors.append(actor)
			labels.append([Vector2(450+i*510,930),mid+" / "+str(actor.data.display_height)])
			check(actor.has_node("FootShadow"),mid+" has shadow")
			if mid=="root_crawler":
				check(actor.data.sprite_frames.get_frame_count(&"Idle")==10,"Root new idle")
				check(actor.data.sprite_frames.get_frame_count(&"Walk")==22,"Root new walk")
		await get_tree().create_timer(.6).timeout
		for actor in actors:
			var shadow: FootShadow = actor.get_node("FootShadow")
			check(shadow.visible,"Monster shadow visible on terrain")
			check(absf(shadow.global_position.y-843)<1,"Monster shadow rests on ground")
		await capture("chapter3_sizes_"+str(page+1))
		for actor in actors:
			actor.sprite.flip_h = true
			actor._play("Walk",true)
		await get_tree().create_timer(.6).timeout
		await capture("chapter3_walk_"+str(page+1))
		for actor in actors: actor.queue_free()
		actors.clear()
		await get_tree().process_frame
func test_npcs() -> void:
	labels.clear()
	title = "NPC / GROUND SHADOWS"
	var town: Node = load("res://scenes/maps/vanir_town.tscn").instantiate()
	for i in range(3):
		var npc = town.get_node("NPCs").get_child(0)
		npc.get_parent().remove_child(npc)
		npc.owner = null
		npc.position = Vector2(650+i*500,850)
		npc.show_if_flag = &""
		npc.hide_if_flag = &""
		add_child(npc)
		var shadow: FootShadow = npc.get_node("FootShadow")
		npc.position.y += 850-shadow._npc_foot().y
		actors.append(npc)
		check(npc.has_node("FootShadow"),"NPC has shared shadow")
	town.free()
	var static_npc: Node2D = load("res://scenes/npc/npc.tscn").instantiate()
	static_npc.npc_name = "Static NPC"
	var art: Sprite2D = static_npc.get_node("Sprite2D")
	art.texture = load("res://Sprites/player/runeblade/idle/frame_01.png")
	art.scale = Vector2(.35,.35)
	static_npc.position = Vector2(1850,600)
	add_child(static_npc)
	var static_shadow: FootShadow = static_npc.get_node("FootShadow")
	static_npc.position.y += 850-static_shadow._npc_foot().y
	actors.append(static_npc)
	await get_tree().create_timer(.6).timeout
	for npc in actors:
		var shadow: FootShadow = npc.get_node("FootShadow")
		check(shadow.visible,"Animated NPC shadow visible")
		check(absf(shadow.global_position.y-843)<1,"NPC shadow follows ground plane")
	await capture("npc_shadows")
