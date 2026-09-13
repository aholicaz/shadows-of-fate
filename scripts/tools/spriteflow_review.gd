extends Node2D
## Focused visual audit; never deals damage, awards drops, or writes saves.
const MONSTER = preload("res://scenes/monsters/monster.tscn")
const ANIMS: Array[StringName] = [&"Idle", &"Walk", &"Attack", &"Hit", &"Die"]
@export var monster_id: String = "thorn_hound"
var actors: Array[Node2D] = []
var data: MonsterData
var checks := 0
var failures: Array[String] = []
var audit := false
var elapsed := 0.0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--monster="):
			monster_id = arg.trim_prefix("--monster=")
	audit = OS.get_cmdline_user_args().has("--audit")
	data = load("res://data/monsters/%s.tres" % monster_id)
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1800, 1000)
	get_window().content_scale_size = Vector2i(1800, 1000)
	RenderingServer.set_default_clear_color(Color("101827"))
	UI.layer.hide()
	for row in range(2):
		for col in range(ANIMS.size()):
			var actor = MONSTER.instantiate()
			actor.data = data
			actor.position = Vector2(180 + col * 360, 460 + row * 460 - data.foot_offset())
			add_child(actor)
			actor.set_physics_process(false)
			if actor._hp_bar != null: actor._hp_bar.hide()
			actor.facing = -1 if row == 0 else 1
			actor.sprite.flip_h = row == 1
			actor._play(String(ANIMS[col]), true)
			actor._apply_fit()
			actors.append(actor)
	if audit:
		await run_audit()

func _process(delta: float) -> void:
	if audit: return
	elapsed += delta
	if elapsed >= 4.5:
		elapsed = 0.0
		for i in range(actors.size()):
			actors[i]._play(String(ANIMS[i % ANIMS.size()]), true)

func _draw() -> void:
	if data == null: return
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(24,35), "%s / SPRITEFLOW / GODOT RUNTIME" % monster_id.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	draw_string(font, Vector2(24,65), "Original PNG frames | Left and mirrored right | Ground line | Actual game height: %d px" % data.display_height, HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("9eafc5"))
	for row in range(2):
		for col in range(ANIMS.size()):
			var at := Vector2(col*360+8,85+row*460)
			var box := Rect2(at,Vector2(344,410))
			draw_rect(box,Color("19263b") if row == 0 else Color("d5dfe8"))
			var ink := Color("dce8ff") if row == 0 else Color("20304a")
			draw_string(font, at+Vector2(12,25), "%s / %d frames" % [ANIMS[col],data.sprite_frames.get_frame_count(ANIMS[col])],HORIZONTAL_ALIGNMENT_LEFT,-1,18,ink)
			draw_line(Vector2(col*360+16,460+row*460),Vector2(col*360+344,460+row*460),Color("718299"),1)

func run_audit() -> void:
	var frames := data.sprite_frames
	for anim in ANIMS:
		check(frames.has_animation(anim) and frames.get_frame_count(anim)>0,"Animation exists: %s" % anim)
		check(frames.get_animation_loop(anim) == (anim in [&"Idle", &"Walk"]),"Loop policy: %s" % anim)
	for actor in actors:
		for anim in ANIMS:
			actor._play(String(anim),true)
			actor.sprite.pause()
			var fixed_scale: Vector2 = actor.sprite.scale
			for f in range(frames.get_frame_count(anim)):
				actor.sprite.frame = f
				actor._apply_fit()
				check(actor.sprite.scale.is_equal_approx(fixed_scale),"No scale jitter: %s" % anim)
				var tex: Texture2D = frames.get_frame_texture(anim,f)
				check(tex != null and tex.get_size() == Vector2(1600,1400),"Registered canvas: %s %d" % [anim,f])
				var point := data.fit_fixed_anchor - tex.get_size()*0.5
				if actor.sprite.flip_h: point.x = -point.x
				check(actor.sprite.to_global(point+actor.sprite.offset).distance_to(actor.foot_position())<.1,"Ground anchor: %s %d" % [anim,f])
	check(is_equal_approx(actors[0]._anim_length("Attack"),data.attack_windup+data.attack_duration),"Attack duration retains gameplay timing")
	var contacts := {"thorn_hound":2,"vanir_sentinel":8,"thorn_matriarch":6,"war_wraith":9,"root_crawler":3,"bog_lurker":7,"mist_sprite":11,"withered_treant":12,"gullveig_ember":9}
	check(is_equal_approx(actors[0]._anim_time_to_frame("Attack",contacts[monster_id]),data.attack_windup),"Attack impact frame retains existing windup")
	check(frames.get_frame_count(&"Run")==frames.get_frame_count(&"Walk"),"Run aliases Walk")
	check(actors[0]._play("Death",true)=="Die","Death resolves to Die")
	for i in range(frames.get_frame_count(&"Run")):
		check(frames.get_frame_texture(&"Run",i)==frames.get_frame_texture(&"Walk",i),"Run uses real walking frames")
	var output := "res://output/spriteflow/runtime/%s" % monster_id
	DirAccess.make_dir_recursive_absolute(output)
	for i in range(actors.size()):
		actors[i]._play(String(ANIMS[i%ANIMS.size()]),true)
	var last := 0.0
	var actual_frames: Array = []
	for moment in [0.0,0.4,0.9,2.0,4.3]:
		if moment>last: await get_tree().create_timer(moment-last).timeout
		await RenderingServer.frame_post_draw
		var indexes: Array = []
		for actor in actors: indexes.append(actor.sprite.frame)
		actual_frames.append({"time":moment,"frames":indexes})
		check(get_viewport().get_texture().get_image().save_png(output+"/motion_%03d.png" % int(moment*100))==OK,"Rendered capture saved")
		last=moment
	for i in range(actors.size()):
		var anim := ANIMS[i%ANIMS.size()]
		if anim in [&"Idle",&"Walk"]:
			check(actors[i].sprite.is_playing(),"Locomotion loops: %s" % anim)
		else:
			check(not actors[i].sprite.is_playing() and actors[i].sprite.frame==frames.get_frame_count(anim)-1,"One-shot finishes and holds: %s" % anim)
	var report := {"monster":monster_id,"checks":checks,"failures":failures,"playback":actual_frames,"renderer":RenderingServer.get_current_rendering_method(),"engine":Engine.get_version_info().string}
	var file := FileAccess.open(output+"/audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("SPRITEFLOW_AUDIT ",JSON.stringify(report))
	get_tree().quit(0 if failures.is_empty() else 1)
