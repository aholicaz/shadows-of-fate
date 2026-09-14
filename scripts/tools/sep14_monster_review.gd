extends Node2D
## Real rendering + actual attack coroutines. Initializes memory only; never saves.
const OUT := "res://output/spriteflow/sep14/runtime/"
const IDS := ["frost_wolf","snow_hawk","snow_mammoth","ice_troll","stone_soldier","echo_wraith","wall_shieldbearer","stone_hrungnir","light_moth","crystal_stag","light_eater_bloom","garden_keeper","reflection","water_nymph","hollow_elf","hollow_moth","light_forsaken","radiant_alfr"]
const NEW := ["snow_hawk","echo_wraith","water_nymph","hollow_elf","light_forsaken","radiant_alfr"]
const SHOTS := {"echo_wraith":2,"light_forsaken":2,"radiant_alfr":1,"water_nymph":1,"gullveig_ember":3}
class Target extends Node2D:
	func foot_position() -> Vector2: return global_position
	func body_rect() -> Rect2: return Rect2(global_position-Vector2(35,288),Vector2(70,288))
	func take_damage(_d: int,_k: float,_f: int) -> void: pass
var actor
var player
var target: Target
var checks := 0
var failures: Array[String] = []
var title := "MONSTER SCALE / PLAYER 288 PX"
var released: Array = []
var cast_direction := 1
var interrupt_cast := false
var capture_mode := false
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func _draw() -> void:
	draw_rect(Rect2(0,940,1800,100),Color("354454"))
	draw_line(Vector2(0,940),Vector2(1800,940),Color("9db4c6"),2)
	draw_string(ThemeDB.fallback_font,Vector2(35,45),title,HORIZONTAL_ALIGNMENT_LEFT,-1,27)
func capture(file: String) -> void:
	queue_redraw()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+file+".png")
func load_actor(id: String) -> void:
	if is_instance_valid(actor):
		actor.queue_free()
		await get_tree().process_frame
	actor = preload("res://scenes/monsters/monster.tscn").instantiate()
	actor.data = load("res://data/monsters/"+id+".tres")
	add_child(actor)
	actor.set_physics_process(false)
	actor.position = Vector2(1130,940-actor.data.foot_offset())
	actor.sprite.position.y = -actor.hover_lift()
	actor._player = target
	if actor._hp_bar != null: actor._hp_bar.hide()
	actor._play("Idle",true)
	actor._apply_fit()
	actor.projectile_released.connect(on_release)
func _ready() -> void:
	get_window().size = Vector2i(1800,1040)
	get_window().content_scale_size = Vector2i(1800,1040)
	RenderingServer.set_default_clear_color(Color("18242c"))
	UI.layer.hide()
	PlayerState.new_game()
	PlayerState.stats.job_id = &"runeblade"
	DirAccess.make_dir_recursive_absolute(OUT)
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
	capture_mode = OS.get_cmdline_user_args().has("--audit-sep14")
	if not capture_mode:
		var bar := HBoxContainer.new();bar.position=Vector2(30,65);add_child(bar)
		var select := OptionButton.new()
		for id in IDS:select.add_item(id)
		select.item_selected.connect(func(i: int): await load_actor(IDS[i]);title=IDS[i];queue_redraw())
		bar.add_child(select)
		var flip := Button.new();flip.text="Flip"
		flip.pressed.connect(func():actor.facing=-actor.facing;actor.sprite.flip_h=not actor.sprite.flip_h;actor._apply_fit())
		bar.add_child(flip)
		for anim in ["Idle","Walk","Attack","Hit","Die","Skill"]:
			var button := Button.new();button.text=anim
			button.pressed.connect(func():actor._play(anim,true);actor._apply_fit())
			bar.add_child(button)
		var cast := Button.new();cast.text="Fire projectiles"
		cast.pressed.connect(func(): actor.state=actor.State.IDLE;actor._attack())
		bar.add_child(cast)
		await load_actor(IDS[0])
		return
	for id in IDS:
		await load_actor(id)
		title = "%s / %d px / player 288 px"%[id,actor.data.display_height]
		check(actor.data.display_height>288,"Scale above player: "+id)
		await capture("size_"+id)
		if id not in NEW: continue
		for anim in ["Idle","Walk","Attack","Hit","Die","Skill"]:
			actor._play(anim,true);actor.sprite.pause()
			var n: int=actor.data.sprite_frames.get_frame_count(anim)
			check(n>1,id+" has "+anim)
			if anim in ["Attack","Hit","Die"]:check(not actor.data.sprite_frames.get_animation_loop(anim),id+" non-loop "+anim)
			for flip in [false,true]:
				actor.sprite.flip_h=flip
				var scale_before := Vector2.ZERO
				for f in range(n):
					actor.sprite.frame=f;actor._apply_fit()
					var tex: Texture2D=actor.sprite.sprite_frames.get_frame_texture(anim,f)
					check(tex != null and tex is AtlasTexture,id+" original texture "+anim)
					if f==0:scale_before=actor.sprite.scale
					check(actor.sprite.scale.is_equal_approx(scale_before),id+" stable scale "+anim)
					if anim in ["Attack","Die"] and f in [0,n/2,n-1]:
						title="%s / %s / %d / %s"%[id,anim,f,"R" if flip else "L"]
						await capture("%s_%s_%02d_%s"%[id,anim,f,"R" if flip else "L"])
	for id in SHOTS:
		await load_actor(id)
		for direction in [-1,1]:
			cast_direction=direction;released.clear()
			actor.position.x=1250 if direction<0 else 550
			actor.facing=direction;actor.sprite.flip_h=direction>0
			actor.state=actor.State.IDLE
			target.position=Vector2(actor.position.x+direction*650,940)
			actor._attack()
			await wait_cast()
			check(released.size()==SHOTS[id],id+" exact count "+str(direction))
			check(actor.state==actor.State.IDLE,id+" cast completes")
		if actor.data.skill_hand_projectiles:
			released.clear();actor._cast_skill();await wait_cast()
			check(released.size()==SHOTS[id],id+" skill also uses authored balls")
		released.clear();interrupt_cast=true
		actor.state=actor.State.IDLE;actor._attack();await wait_cast()
		check(released.size()==1,id+" interruption cancels remaining balls")
		interrupt_cast=false
	await sweep_test()
	var file:=FileAccess.open(OUT+"audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"sizes":IDS.size(),"new_monsters":NEW.size(),"shots":SHOTS},"\t"));file.close()
	print("SEP14_AUDIT checks=",checks," failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
func wait_cast() -> void:
	var elapsed:=0.0
	while actor.state==actor.State.ATTACK and elapsed<6.0:
		await get_tree().create_timer(.05).timeout;elapsed+=.05
	await get_tree().create_timer(.2).timeout
func on_release(shot: MonsterProjectile,frame: int) -> void:
	if not capture_mode:return
	check(shot.global_position.distance_to(actor.projectile_origin(frame))<.01,"Release at hand")
	check(actor.sprite.frame==frame,"Release follows visible frame")
	check(signi(int(shot._velocity_direction.x*100))==cast_direction,"Volley keeps original facing")
	check(not actor.data.projectile_aim_at_player,"No target lock")
	check(shot._speed==1000,"Fast projectile")
	var direction:=shot._velocity_direction
	target.position=Vector2(actor.position.x-cast_direction*800,100)
	check(shot._velocity_direction==direction,"Moving target cannot redirect projectile")
	released.append(frame)
	if interrupt_cast:
		actor.state=actor.State.HURT;actor.sprite.pause()
	else:
		title="%s / projectile %d / %s"%[actor.data.id,released.size(),"R" if cast_direction>0 else "L"]
		flight_capture("%s_ball_%d_%s"%[actor.data.id,released.size(),"R" if cast_direction>0 else "L"])
func flight_capture(file: String) -> void:
	await get_tree().create_timer(.12).timeout
	await capture(file)
func sweep_test() -> void:
	target.add_to_group("player");target.position=Vector2(900,850)
	var shot:=MonsterProjectile.fire_straight(actor.data,actor,1,Vector2(100,700),Vector2(900,700))
	shot.set_process(false)
	var impacts: Array=[]
	shot.impacted.connect(func(kind: StringName,_at: Vector2):impacts.append(kind))
	shot._process(1.0);shot._process(1.0)
	check(impacts==[&"player"],"Fast ball sweeps player once at low FPS")
	var wall:=StaticBody2D.new();wall.collision_layer=1
	var shape:=CollisionShape2D.new();var rect:=RectangleShape2D.new();rect.size=Vector2(30,600);shape.shape=rect;wall.add_child(shape);wall.position=Vector2(500,700);add_child(wall)
	await get_tree().physics_frame;await get_tree().physics_frame
	var blocked:=MonsterProjectile.fire_straight(actor.data,actor,1,Vector2(100,700),Vector2(900,700));blocked.set_process(false)
	var hits: Array=[];blocked.impacted.connect(func(kind: StringName,_at: Vector2):hits.append(kind));blocked._process(1.0)
	check(hits==[&"terrain"],"Wall blocks fast ball before player")
