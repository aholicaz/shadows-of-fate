extends Node
const Campaign = preload("res://scripts/world/ch456_campaign.gd")
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	assert(ok,message)
func finish_dialogue() -> void:
	var guard := 0
	while UI.dialogue.is_open() and guard<20:
		UI.dialogue._advance()
		await get_tree().process_frame
		guard+=1
func _ready() -> void:
	check(UI!=null and UI.dialogue!=null,"UI autoload ready")
	SaveManager.end_session()
	PlayerState.new_game()
	PlayerState.stats.level=150
	PlayerState.stats.base_vit=150
	PlayerState.refresh()
	get_window().size=Vector2i(1280,720)
	get_window().content_scale_size=Vector2i(1280,720)
	PlayerState.set_flag(&"wall_night")
	PlayerState.set_flag(&"knows_exile")
	PlayerState.set_flag(&"chapter6_done")
	PlayerState.quests.completed.append(&"c4_8_shieldbearer")
	var id := &"broken_wall"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): id=StringName(arg.trim_prefix("--map="))
	if id==&"ljosalf_city": PlayerState.set_flag(&"shade_view")
	var map=load(Game.MAPS[id]).instantiate()
	# No combat during an art inspection.
	var spawners=map.get_node_or_null("Spawners")
	if spawners!=null: spawners.free()
	add_child(map)
	await get_tree().process_frame
	map.player.set_physics_process(false)
	map.camera.position_smoothing_enabled=false
	var x := 3100.0
	if id==&"ljosalf_city":x=3700
	elif id==&"dimming_wood":x=map.get_node("NPCs/Sol_exile").position.x
	elif id==&"odin_seat":x=1300
	map.player.position=Vector2(x-180,880-map.player._feet_y())
	map.camera.global_position=Vector2(x,570)
	map.camera.reset_smoothing()
	var campaign
	for child in map.get_children():
		if child.get_script()==Campaign:campaign=child
	check(campaign!=null,"Campaign attached")
	if id==&"broken_wall":
		var stranger
		for point in get_tree().get_nodes_in_group("story_point"):
			if point.shape=="figure":stranger=point
		check(stranger!=null and stranger.has_node("StrangerArt"),"World stranger exists")
		check(stranger.self_modulate.a==0 and stranger.get_node("StrangerArt").is_visible_in_tree(),"Placeholder hidden, art visible")
		var source=[{"name":"คนแปลกหน้า","text":"..."},{"name":"เสียงจากข้างหลัง","text":"อย่าหันมา"}]
		var pages=campaign.portrait_pages(source)
		check(pages[0].portrait!=null and pages[1].portrait==null,"Identity art and secret unseen voice")
		check(not source[0].has("portrait"),"Caller pages preserved")
		campaign._s5()
		await get_tree().process_frame
		check(UI.dialogue._portraits[0].visible,"Actual S5 portrait shown")
		UI.dialogue._advance()
	elif id==&"ljosalf_city":
		var crystal
		for point in get_tree().get_nodes_in_group("story_point"):
			if point.shape=="crystal":crystal=point
		check(crystal!=null and crystal.has_node("CrystalArt"),"Crystal painted sprite")
		var visitor=campaign.visiting_stranger(Vector2(x,880))
		check(visitor.get_node("StrangerArt").texture.resource_path.ends_with("stranger.png"),"Chapter5 same identity")
	elif id==&"dimming_wood":
		var sol=map.get_node("NPCs/Sol_exile")
		check(sol.visible and sol.get_node("Sprite2D").texture!=null,"Exiled Sol visible art")
		check(sol.portrait_texture()!=null,"Sol dialogue portrait")
	else:
		var pages=campaign.portrait_pages([{"name":"คนแปลกหน้า","text":"ข้ามีพี่ชายคนหนึ่ง... เขาถือค้อน"}])
		check(pages[0].portrait.resource_path.ends_with("b68aa31bc058.tres"),"Chapter6 seated portrait")
		UI.talk(pages)
		await get_tree().process_frame
		UI.dialogue._advance()
	UI.touch.hide()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/story_art_audit/%s.png"%id)
	await finish_dialogue()
	if id==&"broken_wall":
		check(PlayerState.has_flag(&"s5_done") and PlayerState.inventory.count_of(&"mural_fragment")==1,"S5 reward intact")
		campaign._s5()
		await get_tree().process_frame
		await finish_dialogue()
		check(PlayerState.inventory.count_of(&"mural_fragment")==1,"Repeat no duplicate reward")
	if id==&"ljosalf_city":
		var before: int = campaign.get_child_count()
		campaign._s8()
		await get_tree().create_timer(.25).timeout
		check(UI.dialogue.is_open() and UI.dialogue._portraits[0].visible,"S8 actual portrait")
		check(campaign.get_child_count()==before+1,"S8 temporary actor")
		var nott=map.get_node("NPCs/Nott")
		map.camera.global_position=Vector2(nott.position.x,570)
		map.camera.reset_smoothing()
		UI.dialogue._advance()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/story_art_audit/s8_dialogue.png")
		UI.dialogue._next()
		UI.dialogue._next()
		check(UI.dialogue._portraits[0].texture==nott.portrait_texture(),"Doctor portrait replaces Stranger")
		await finish_dialogue()
		await get_tree().process_frame
		check(campaign.get_child_count()==before and PlayerState.has_flag(&"s8_done"),"Visitor removed and story flag intact")
		check(PlayerState.inventory.count_of(&"book_seven_half_2")==1,"S8 reward intact")
		campaign._s7_talk()
		await get_tree().process_frame
		check(campaign.get_child_count()==before+1 and UI.dialogue._portraits[0].visible,"Rescue scene actor and portrait")
		await finish_dialogue()
		await get_tree().process_frame
		check(campaign.get_child_count()==before,"Rescue visitor removed")
	print("STORY_ART_PASS ",id," checks=",checks)
	get_tree().quit()
