extends Node2D
const FX = preload("res://scripts/entities/boss_signature_skill.gd")
const MONSTER = preload("res://scenes/monsters/monster.tscn")
const OUT := "res://output/boss_skills/"
class Target extends Node2D:
	var hits: Array = []
	var invincible := false
	func foot_position() -> Vector2: return global_position
	func is_invincible() -> bool: return invincible
	func take_damage(damage: int, _force: float, _direction: int) -> void: hits.append(damage)
	func _draw() -> void:
		draw_rect(Rect2(-24,-130,48,130),Color("467faf"))
		draw_circle(Vector2(0,-143),22,Color("d5e8f8"))
var target: Target
var actor
var checks := 0
var failures: Array[String] = []
var rows: Array = []
var mode := ""
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func _draw() -> void:
	draw_rect(Rect2(0,690,1600,210),Color("293947"))
	draw_line(Vector2(0,690),Vector2(1600,690),Color("b2a7a0"),2)
	draw_string(ThemeDB.fallback_font,Vector2(45,65),"BOSS SKILLS / "+mode,HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("ffce88"))
func _ready() -> void:
	get_window().size = Vector2i(1600,900)
	get_window().content_scale_size = Vector2i(1600,900)
	RenderingServer.set_default_clear_color(Color("111a2a"))
	UI.layer.hide()
	PlayerState.new_game()
	DirAccess.make_dir_recursive_absolute(OUT)
	target = Target.new()
	target.add_to_group("player")
	add_child(target)
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000,100)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(800,740)
	add_child(floor_body)
	await get_tree().physics_frame
	if not "--preview-only" in OS.get_cmdline_user_args(): math_checks()
	for id in ["gullveig_ember","baphomet"]:
		actor = MONSTER.instantiate()
		actor.data = load("res://data/monsters/"+id+".tres")
		add_child(actor)
		actor.set_physics_process(false)
		actor._player = target
		actor.position = Vector2(500,690-actor.data.foot_offset())
		actor.sprite.position.y = -actor.data.hover_height
		if not "--preview-only" in OS.get_cmdline_user_args(): await integration_checks(id)
		for kind in (["meteor","flame_jet"] if id=="gullveig_ember" else ["scythe"]):
			if "--meteor-only" in OS.get_cmdline_user_args() and kind!="meteor": continue
			if "--scythe-only" in OS.get_cmdline_user_args() and kind!="scythe": continue
			if not "--preview-only" in OS.get_cmdline_user_args():
				for facing in [1,-1]: await spatial_checks(kind,facing)
			if DisplayServer.get_name() != "headless":
				await preview(kind,1)
				if not "--right-only" in OS.get_cmdline_user_args(): await preview(kind,-1)
		actor.queue_free()
		await get_tree().process_frame
	var report := {"checks":checks,"failures":failures,"bosses":rows,"renderer":RenderingServer.get_current_rendering_method()}
	var f := FileAccess.open(OUT+("render_audit.json" if "--preview-only" in OS.get_cmdline_user_args() else "audit.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"))
	f.close()
	print("BOSS_SKILL_AUDIT ",JSON.stringify(report))
	get_tree().quit(0 if failures.is_empty() else 1)
func math_checks() -> void:
	var stats := PlayerStats.new()
	stats.flee = 10000
	stats.def = 200
	for filename in DirAccess.get_files_at("res://data/monsters"):
		if not filename.ends_with(".tres"): continue
		var d = load("res://data/monsters/"+filename)
		if not d is MonsterData or not d.is_boss: continue
		var lo := 999999
		var hi := 0
		for i in range(100):
			var result := Combat.monster_skill_hits_player(d,stats,d.skill_damage_mult)
			check(not result.miss and not result.crit and result.damage>1,String(d.id)+": telegraphed skill never becomes phantom 1 damage")
			lo = mini(lo,result.damage)
			hi = maxi(hi,result.damage)
		seed(9123)
		var armored: int = Combat.monster_skill_hits_player(d,stats,2).damage
		stats.def = 0
		seed(9123)
		var unarmored: int = Combat.monster_skill_hits_player(d,stats,2).damage
		check(unarmored > armored*2.8,String(d.id)+": armor still protects")
		stats.def = 200
		rows.append({"id":d.id,"mult":d.skill_damage_mult,"damage_def200":[lo,hi]})
	var normal := MonsterData.new()
	normal.atk_min = 100
	normal.atk_max = 100
	var misses := 0
	for i in range(100):
		var r := Combat.monster_skill_hits_player(normal,stats,2)
		if r.miss:
			misses += 1
			check(r.damage==0,"Nonboss miss remains zero")
	check(misses>70,"Nonboss FLEE mechanic remains active")
	for frames in [FX.METEOR,FX.JET,FX.SCYTHE,FX.GROUND]:
		check(frames.get_frame_count(&"default")==8,"Eight authored animation frames")
		check(FX.animation_frame(frames,.15)>0,"Time advances actual atlas frame")
	check(FX.animation_frame(FX.SCYTHE,9)==7,"Scythe does not loop")
	check(FX.animation_frame(FX.GROUND,1)==4,"Ground animation loops")
func new_fx(kind: String, facing: int):
	actor.hp = actor.data.max_hp
	actor.facing = facing
	actor.sprite.flip_h = facing>0
	target.hits.clear()
	target.invincible = false
	var fx = FX.cast(actor,kind,facing)
	fx.set_physics_process(false)
	return fx
func step(fx, seconds: float) -> void:
	for i in range(int(round(seconds*60))):
		if fx.is_queued_for_deletion(): break
		fx._physics_process(1.0/60.0)
func spatial_checks(kind: String, facing: int) -> void:
	target.position = actor.foot_position()+Vector2(facing*250,0)
	var fx = new_fx(kind,facing)
	step(fx,.70)
	check(target.hits.is_empty(),kind+": warning does no damage")
	step(fx,6.5 if kind=="meteor" else 2.0)
	check(target.hits.size()==(6 if kind=="meteor" else 3),kind+": correct impact/tick count facing "+str(facing))
	check(fx.cast_done,kind+": caster released")
	if not fx.is_queued_for_deletion(): fx.queue_free()
	await get_tree().process_frame
	target.position = actor.foot_position()+Vector2(facing*250,0)
	fx = new_fx(kind,facing)
	if kind=="meteor": target.position.x += 1500
	else: target.position = actor.foot_position()+Vector2(-facing*200,0)
	step(fx,7.2)
	check(target.hits.is_empty(),kind+": leaving telegraph or standing behind avoids hits")
	if not fx.is_queued_for_deletion(): fx.queue_free()
	await get_tree().process_frame
	target.position = actor.foot_position()+Vector2(facing*250,0)
	fx = new_fx(kind,facing)
	target.invincible = true
	step(fx,7.2)
	check(target.hits.is_empty(),kind+": dash invulnerability honored")
	if not fx.is_queued_for_deletion(): fx.queue_free()
	await get_tree().process_frame
	fx = new_fx(kind,facing)
	actor.hp = 0
	step(fx,.1)
	check(fx.cast_done and fx.is_queued_for_deletion(),kind+": caster death cancels safely")
	await get_tree().process_frame
	actor.hp = actor.data.max_hp
func preview(kind: String, facing: int) -> void:
	mode = kind.to_upper()
	queue_redraw()
	actor.position = Vector2(440 if facing>0 else 1160,690-actor.data.foot_offset())
	target.position = actor.foot_position()+Vector2(facing*(350 if kind=="scythe" else 460),0)
	actor.state = actor.State.ATTACK
	actor._play("Skill",true)
	var fx = new_fx(kind,facing)
	for i in range(90 if kind=="meteor" else 36):
		step(fx,1.0/12.0)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OUT+kind+("_left" if facing<0 else "")+"_%03d.png"%i)
		if fx.is_queued_for_deletion(): break
	if is_instance_valid(fx) and not fx.is_queued_for_deletion(): fx.queue_free()
	await get_tree().process_frame

func integration_checks(id: String) -> void:
	target.position = actor.foot_position()+Vector2(250,0)
	actor._special_cast_count = 0
	for i in range(2):
		actor._cast_skill()
		var found = null
		for child in get_children():
			if child.get_script() == FX and not child.is_queued_for_deletion(): found = child
		if id=="baphomet" and i==1:
			check(found==null,"Baphomet retains alternate dark-wave skill")
			await get_tree().create_timer(4.0).timeout
		else:
			check(found!=null,id+": real monster AI dispatches signature")
			if found!=null:
				check(found.kind==("scythe" if id=="baphomet" else ("meteor" if i==0 else "flame_jet")),id+": cast alternation")
				found.set_physics_process(false)
				step(found,2.6)
				check(actor.state==actor.State.IDLE,id+": real caster unlocked after signature")
				if not found.is_queued_for_deletion(): found.queue_free()
		await get_tree().process_frame
