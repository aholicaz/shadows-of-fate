extends Node2D
const ART = preload("res://scripts/entities/runeblade_echo_art.gd")
const DASH = preload("res://scripts/entities/rune_dash_fx.gd")
const FIELD = preload("res://scripts/entities/runic_blade_field.gd")
var player
var visual
var checks := 0
var title: Label

class RangeTarget extends Node2D:
	var data: MonsterData
	var hp := 1000
	var hits := 0
	func body_rect() -> Rect2: return Rect2(global_position-Vector2(10,100),Vector2(20,100))
	func is_dead() -> bool: return false
	func take_damage_from_player(_mult: float,_magic: bool,_dir: int,_knock: float,_wound: float,_source: StringName) -> void:
		hp-=1
		hits+=1

func check(ok: bool, note: String) -> void:
	if not ok:
		push_error(note)
		get_tree().quit(1)
		assert(ok,note)
	checks += 1
	print("PASS: ",note)

func shot(name: String) -> void:
	for child in UI.get_children():
		if child is CanvasLayer or child is CanvasItem: child.hide()
	player.runeblade.hud.hide()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/runeblade_impact_revision/"+name+".png")

func _ready() -> void:
	SaveManager.end_session()
	SaveManager.set_process(false)
	DirAccess.make_dir_recursive_absolute("res://output/runeblade_impact_revision")
	get_window().size = Vector2i(960,640)
	get_window().content_scale_size = Vector2i(960,640)
	RenderingServer.set_default_clear_color(Color("#1c2029"))
	PlayerState.new_game()
	PlayerState.stats.job_id = &"runeblade"
	PlayerState.equipment.slots[Equipment.EquipSlot.WEAPON] = ItemInstance.create(&"iron_blade")
	player = load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	player.position = Vector2(480,400)
	player.is_attacking = true
	await get_tree().process_frame
	visual = player.get_node("EquipVisual")
	visual.set_process(false)
	var camera := Camera2D.new()
	camera.position = player.foot_position()-Vector2(0,140)
	camera.zoom = Vector2(1.1,1.1)
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	title = Label.new()
	title.position = Vector2(24,18)
	title.add_theme_font_size_override("font_size",22)
	canvas.add_child(title)
	var animations := ["Attack_Runeblade_1","Attack_Runeblade_2","Attack_Runeblade_3","Lunge_Runeblade","Flurry_Runeblade_1","Anvil_Runeblade","Faultline_Runeblade","Worldcleaver_Runeblade","Wave_Runeblade"]
	for dir in [-1,1]:
		player.facing = dir
		player._update_facing()
		for anim in animations:
			camera.zoom=Vector2.ONE*(0.75 if "Anvil_" in anim else 1.1)
			camera.position=player.foot_position()+Vector2(dir*150,-250) if "Anvil_" in anim else player.foot_position()-Vector2(0,140)
			player._play(anim,true)
			player.sprite.speed_scale = 0.0
			var count: int = player.sprite.sprite_frames.get_frame_count(player.sprite.animation)
			var fx: Node2D
			for sample in range(18):
				var phase: float = sample/17.0*(count-1)
				player.sprite.set_frame_and_progress(int(phase),fposmod(phase,1.0))
				visual._process(1.0/30.0)
				if sample==7 and ("Attack_" in anim or "Anvil_" in anim or "Flurry_" in anim):
					var style := "slam" if "Anvil_" in anim else ("flurry" if "Flurry_" in anim else "")
					fx = ART.cut(player,player.foot_position()+Vector2(dir*(317 if style=="slam" else 100),0 if style=="slam" else -135),dir,594.0 if style=="slam" else 230.0,animations.find(anim)%3,0.0,false,style)
					fx.set_process(false)
				if is_instance_valid(fx):
					fx._process(1.0/30.0)
					if fx.is_queued_for_deletion(): fx=null
				title.text = anim.replace("_Runeblade","")+" / "+("LEFT" if dir<0 else "RIGHT")
				if sample==9:
					if dir==1: await shot(anim+"_right_peak")
					check(visual._layers[Equipment.EquipSlot.WEAPON].visible,anim+" keeps equipped blade "+str(dir))
					var equipped = visual._layers[Equipment.EquipSlot.WEAPON]
					check(equipped.sprite_frames.get_frame_texture(equipped.animation,equipped.frame)==visual._layer_data[Equipment.EquipSlot.WEAPON].equip_texture,"equipped item texture retained")
				if dir == -1:
					await shot(anim+"_%02d"%sample)
			if dir==1: await shot(anim+"_right")
			if is_instance_valid(fx): fx.queue_free()
			await get_tree().process_frame
	# True frame animation: eight distinct atlas regions, no rotating rigid sword.
	var swipe = ART.cut(player,player.foot_position()+Vector2(-100,-135),-1,230.0)
	swipe.set_process(false)
	var regions: Array[Rect2] = []
	for i in range(8):
		swipe.age=(i+0.5)*swipe.lifetime/8.0
		swipe.update_visual()
		check(swipe.stroke.frame==i,"slash advances painted frame "+str(i))
		regions.append(swipe.stroke.sprite_frames.get_frame_texture(&"default",i).region)
		title.text="Painted slash / frame "+str(i+1)
		await shot("slash_%02d"%i)
	check(regions[0]!=regions[7] and swipe.get_child_count()==1,"separate slash uses distinct drawings, no spectral weapon clone")
	swipe._process(0.1)
	check(swipe.is_queued_for_deletion(),"slash ends without looping")
	check(swipe.reach>330 and swipe.z_index>player.z_index+2,"normal slash larger and in front of body/equipment")
	await get_tree().process_frame
	var cancelled = ART.cut(player,player.foot_position(),-1,230.0,0,0.15)
	cancelled.set_process(false)
	player._attack_seq += 1
	cancelled._process(0.01)
	check(cancelled.is_queued_for_deletion(),"cancelled windup produces no slash")
	player._play("Idle",true)
	visual._process(0.016)
	check(visual._layers[Equipment.EquipSlot.WEAPON].visible,"idle keeps equipment too")
	for weapon_id in [&"katana", &"rapier"]:
		PlayerState.equipment.slots[Equipment.EquipSlot.WEAPON] = ItemInstance.create(weapon_id)
		visual.refresh_from_player()
		player._play("Attack_Runeblade_1",true)
		player.sprite.frame=3
		visual._process(0.016)
		var layer = visual._layers[Equipment.EquipSlot.WEAPON]
		check(layer.visible and layer.sprite_frames.get_frame_texture(layer.animation,layer.frame)==GameData.get_item(weapon_id).equip_texture,"attack follows equipped "+String(weapon_id))
	PlayerState.equipment.slots[Equipment.EquipSlot.WEAPON] = ItemInstance.create(&"iron_blade")
	visual.refresh_from_player()
	# Capture actual combat entry point and wall-clock playback, not scrubbed poses.
	AudioServer.set_bus_mute(0,true)
	visual.set_process(true)
	player.facing=-1
	player._update_facing()
	player.is_attacking=false
	player.combo_step=0
	var stamps: Array[int] = []
	var real_index := 0
	var saw_slash := false
	for swing in range(3):
		player.start_attack()
		var stop_at := Time.get_ticks_msec()+int((player._attack_span+0.08)*1000)
		while Time.get_ticks_msec()<stop_at:
			for node in get_children():
				if node.get_script()==preload("res://scripts/entities/runeblade_echo_burst.gd") and node.visible:
					saw_slash=true
			title.text="Actual combo / equipped iron blade"
			stamps.append(Time.get_ticks_msec())
			await shot("actual_%03d"%real_index)
			real_index+=1
			await get_tree().create_timer(0.016).timeout
	check(saw_slash,"actual attack entry point releases sprite slash")
	check(not player.is_attacking,"actual combo completes normally")
	var timing_file := FileAccess.open("res://output/runeblade_impact_revision/timestamps.json",FileAccess.WRITE)
	timing_file.store_string(JSON.stringify(stamps))
	timing_file.close()
	visual.set_process(false)
	# Dodge must remain one short burst despite a longer movement duration.
	player._dodge_time = 0.8
	player._dodge_wall_stopped = false
	var dash = DASH.new()
	dash.caster=player
	dash.dodge=true
	dash.facing=1
	player.add_child(dash)
	dash.set_process(false)
	dash._process(0.199)
	check(dash.visible and not dash.is_queued_for_deletion(),"dash visible for its four-frame burst")
	dash._process(0.002)
	check(not dash.visible and dash.is_queued_for_deletion(),"dash disappears at 0.2 seconds while movement continues")
	await get_tree().process_frame
	var lunge = DASH.new()
	lunge.caster=player
	lunge.facing=-1
	player._dash_time=0.4
	player.add_child(lunge)
	lunge.set_process(false)
	check(is_instance_valid(lunge.thrust) and not lunge.gold.visible,"lunge owns separate animated thrust sheet")
	player._play("Lunge_Runeblade",true)
	player.sprite.speed_scale=0
	player.sprite.frame=3
	visual._process(0.016)
	lunge._thrust_start=-1.0
	lunge.update_visual()
	check(not lunge.thrust.visible,"thrust stays hidden while sword is wound backwards")
	for f in range(player.sprite.sprite_frames.get_frame_count(player.sprite.animation)):
		player.sprite.frame=f
		visual._process(0.016)
		var hand_layer = visual._layers[Equipment.EquipSlot.WEAPON]
		if (lunge.blade_tip()-hand_layer.global_position).normalized().dot(Vector2(-1,0))>0.98: break
	player._dash_time=0
	lunge._thrust_start=-1.0
	lunge.update_visual()
	check(not lunge.thrust.visible,"forward sword alone does not trigger thrust before dash")
	player._dash_time=0.4
	lunge._thrust_start=0.0
	for i in range(8):
		lunge.age=(i+0.5)*DASH.THRUST_DURATION/8.0
		lunge.update_visual()
		check(lunge.thrust.frame==i,"lunge advances thrust frame "+str(i))
		title.text="Lunge / actual equipped sword + thrust sprite"
		await shot("thrust_%02d"%i)
	lunge.age=0.30
	lunge.update_visual()
	check(lunge.thrust.visible and lunge.thrust.scale.length()>1.2,"larger thrust remains visible after old 0.2s lifetime")
	lunge.age=0.43
	lunge.update_visual()
	check(not lunge.thrust.visible,"thrust ends after new 0.42s lifetime")
	lunge.queue_free()
	player._dash_time=0
	# Fields keep damage timing while using only spectral blades.
	player.facing=-1
	player._update_facing()
	for id in [&"faultline",&"worldcleaver"]:
		player._play(player.skill_animation(id),true)
		player.sprite.speed_scale=0
		player.sprite.frame=mini(4,player.sprite.sprite_frames.get_frame_count(player.sprite.animation)-1)
		visual._process(0.016)
		var field = FIELD.new()
		field.configure(player.runeblade,id,10.0,player.foot_position()+Vector2(-180,0),-1)
		add_child(field)
		field.set_process(false)
		check(field.echo_style,"field uses light blades: "+String(id))
		if id==&"worldcleaver":
			camera.zoom=Vector2(0.55,0.55)
			camera.position=field.global_position-Vector2(0,410)
			var rain = field.get_children().filter(func(n):return n.get_script()==preload("res://scripts/entities/worldcleaver_rain_visual.gd"))[0]
			rain.set_process(false)
			check(rain.swords.size()==20 and rain.swords[0].blade.texture==ART.BLADE,"20 larger swords preserve staggered rain")
			check(field.pulses==5 and field.interval==0.2,"rain damage pulses unchanged")
			for frame in range(24):
				field.elapsed=frame/24.0*1.25
				rain.update_visual()
				title.text="Worldcleaver / staggered light swords"
				await shot("rain_%02d"%frame)
		else:
			camera.zoom=Vector2.ONE*0.8
			camera.position=field.global_position-Vector2(0,180)
			check(field.field_strokes.size()==4 and field.field_strokes[0].scale.x*field.field_strokes[1].scale.x<0,"planted sword cuts both sides")
			check(field.radius==420.0,"planted AOE expanded to 420")
			check(field.weapon_visual.blade.texture==ART.BLADE and field.pulses==6,"planted sword changes artwork only")
			for frame in range(12):
				field._process(0.04)
				title.text="Faultline / runic light blade"
				await shot("field_%02d"%frame)
		field.queue_free()
		await get_tree().process_frame
	var bash := SkillEffect.spawn(GameData.get_skill(&"bash"),player,-1,2.0)
	check(bash!=null and bash._damage and bash._hit_count==2 and bash._hit_size==Vector2(360,320),"Bash keeps damage node, two hits and hitbox")
	check(not bash._sprite.visible,"Bash original visual replaced without deleting damage node")
	bash.queue_free()
	camera.zoom=Vector2(1.1,1.1)
	camera.position=player.foot_position()-Vector2(0,140)
	var wave = preload("res://scripts/entities/rending_wave.gd").spawn(GameData.get_skill(&"magnum_break"),player,-1,1)
	wave.set_physics_process(false)
	check(wave._custom_visual and is_instance_valid(wave._echo_wave),"Rending Wave is a light sword")
	title.text="Rending Wave / spectral projectile"
	for frame in range(12):
		wave.global_position=player.foot_position()+Vector2(-30-frame*20,-120)
		await shot("wave_%02d"%frame)
	wave.queue_free()
	player.visual_job_override=&"swordsman"
	check(not ART.active(player),"other jobs keep their original effect paths")
	player.visual_job_override=&"runeblade"
	for dir in [-1,1]:
		var inside := RangeTarget.new()
		var outside := RangeTarget.new()
		add_child(inside)
		add_child(outside)
		inside.add_to_group("enemy")
		outside.add_to_group("enemy")
		inside.position=player.foot_position()+Vector2(dir*570,0)
		outside.position=player.foot_position()+Vector2(dir*710,0)
		player.runeblade.strike(&"anvil_cleave",1.0,GameData.get_skill(&"anvil_cleave").range_x,8,dir)
		check(inside.hits==1 and outside.hits==0,"Anvil hits beyond old range and respects new boundary "+str(dir))
		inside.position=player.foot_position()+Vector2(dir*380,0)
		outside.position=player.foot_position()+Vector2(dir*460,0)
		inside.hits=0
		var field := FIELD.new()
		field.configure(player.runeblade,&"faultline",1.0,player.foot_position(),dir)
		add_child(field)
		field.set_process(false)
		field.strike()
		check(inside.hits==1 and outside.hits==0,"Faultline reaches expanded radius on both sides "+str(dir))
		field.queue_free()
		inside.queue_free()
		outside.queue_free()
		await get_tree().process_frame
	# Real monster damage entry point: sparkle only for positive critical damage.
	var monster = load("res://scenes/monsters/monster.tscn").instantiate()
	monster.data=load("res://data/monsters/frost_wolf.tres").duplicate()
	add_child(monster)
	monster.set_physics_process(false)
	monster.position=player.foot_position()+Vector2(-240,0)
	monster.position.y+=player.foot_position().y-monster.foot_position().y
	camera.zoom=Vector2.ONE*0.85
	camera.position=monster.body_rect().get_center()+Vector2(140,0)
	var before := get_tree().get_nodes_in_group("critical_gold_bursts").size()
	monster.take_damage(1,false)
	monster.take_damage(0,true)
	check(get_tree().get_nodes_in_group("critical_gold_bursts").size()==before,"normal and zero damage do not spawn critical sparkle")
	monster.take_damage(1,true)
	var bursts := get_tree().get_nodes_in_group("critical_gold_bursts")
	check(bursts.size()==before+1,"positive critical damage spawns one sparkle")
	var critical = bursts[-1]
	critical.set_process(false)
	check(critical.global_position.distance_to(monster.body_rect().get_center())<0.01,"critical sparkle is centered on struck monster")
	for i in range(8):
		critical.age=(i+0.5)*critical.DURATION/8.0
		critical._process(0)
		title.text="Critical / eight-frame sparkle on monster"
		await shot("critical_%02d"%i)
	monster.queue_free()
	await get_tree().process_frame
	check(is_instance_valid(critical),"critical flash survives target deletion")
	critical._process(0.05)
	check(critical.is_queued_for_deletion(),"critical sparkle cleans up after animation")
	# Compare six genuinely different source sheets under identical playback.
	player.hide()
	for child in get_children():
		if child.get_script()==preload("res://scripts/entities/runeblade_echo_burst.gd"): child.hide()
	camera.position=Vector2(480,320)
	camera.zoom=Vector2.ONE
	var gallery: Array[AnimatedSprite2D] = []
	var paths: Array[String] = []
	var kinds := ["combo1","combo2","combo3","thrust","slam","flurry"]
	var names := ["1 / Down cut","2 / Rising cut","3 / Wide finisher","Lunge / Thrust","Anvil / Ground cleave","Flurry / Cross cuts"]
	for i in range(6):
		var art := ART.slash_sprite(170.0,-1,kinds[i])
		add_child(art)
		art.position=Vector2(160+(i%3)*320,180+(i/3)*280)
		if kinds[i]=="slam": art.position.y+=80
		gallery.append(art)
		var path: String = art.sprite_frames.get_frame_texture(&"default",0).atlas.resource_path
		check(not paths.has(path),"distinct sprite sheet: "+kinds[i])
		paths.append(path)
		var label := Label.new()
		label.text=names[i]
		label.position=Vector2(35+(i%3)*320,65+(i/3)*280)
		canvas.add_child(label)
	for i in range(8):
		for art in gallery: ART.slash_phase(art,(i+0.5)*0.025)
		title.text="Six independent animations / frame "+str(i+1)
		await shot("gallery_%02d"%i)
	player.queue_free()
	print("ECHO REVIEW: ",checks," checks passed")
	get_tree().quit()

func _draw() -> void:
	draw_line(Vector2(-1000,540),Vector2(2000,540),Color("#505761"),2)
