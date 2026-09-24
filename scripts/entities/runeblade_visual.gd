extends RefCounted
## Authored job poses override only their matching animation routes.
const IDLE := &"Idle_Runeblade"
const FULL_PATH := "res://data/sprites/runeblade_frames.tres"
static func source_frames() -> SpriteFrames:
	return load(FULL_PATH if ResourceLoader.exists(FULL_PATH) else "res://data/sprites/runeblade_idle_frames.tres") as SpriteFrames
static func install(body: AnimatedSprite2D) -> void:
	if body.sprite_frames.has_animation(IDLE): return
	var source := source_frames()
	var merged := body.sprite_frames.duplicate() as SpriteFrames
	for anim in source.get_animation_names():
		if source.get_frame_count(anim)==0: continue
		if merged.has_animation(anim): merged.remove_animation(anim)
		merged.add_animation(anim)
		merged.set_animation_loop(anim,source.get_animation_loop(anim))
		merged.set_animation_speed(anim,source.get_animation_speed(anim))
		for i in range(source.get_frame_count(anim)):
			merged.add_frame(anim,source.get_frame_texture(anim,i),source.get_frame_duration(anim,i))
	for key in source.get_meta_list(): merged.set_meta(key,source.get_meta(key))
	var jump := load("res://data/sprites/jump_slash_frames.tres") as SpriteFrames
	merged.add_animation(&"JumpSlash_Runeblade")
	merged.set_animation_loop(&"JumpSlash_Runeblade", false)
	merged.set_animation_speed(&"JumpSlash_Runeblade", 40.0)
	for i in jump.get_frame_count(&"JumpSlash_Runeblade"):
		merged.add_frame(&"JumpSlash_Runeblade", jump.get_frame_texture(&"JumpSlash_Runeblade", i))
	var regs: Dictionary = merged.get_meta("rb_registration", {}).duplicate(true)
	regs["JumpSlash_Runeblade"] = {"anchor": Vector2(556, 718), "height": 573.0}
	merged.set_meta("rb_registration", regs)
	var pose_regs: Dictionary = merged.get_meta("rb_frame_registration", {}).duplicate(true)
	var jump_regs: Array = []
	for i in 32:
		# Preserve the authored jump arc; register only the landing/recovery to the floor.
		var ground := 762.0 if i >= 17 and i <= 21 else (741.0 if i == 22 else (738.0 if i == 23 else (729.0 if i == 24 else 718.0)))
		jump_regs.append({"anchor": [556.0, ground], "height": 573.0})
	pose_regs["JumpSlash_Runeblade"] = jump_regs
	merged.set_meta("rb_frame_registration", pose_regs)
	var baked: Array = merged.get_meta("rb_baked_weapon", []).duplicate()
	baked.append("JumpSlash_Runeblade")
	merged.set_meta("rb_baked_weapon", baked)
	body.sprite_frames = merged
static func route(body: AnimatedSprite2D, request: String) -> String:
	install(body)
	var routes: Dictionary = body.sprite_frames.get_meta("rb_routes",{})
	return String(routes.get(request, "Idle_Runeblade" if request=="Idle" else ""))
static func is_pose(frames: SpriteFrames, anim: StringName) -> bool:
	return anim==IDLE or frames.get_meta("rb_registration",{}).has(String(anim))
static func baked_weapon(frames: SpriteFrames, anim: StringName) -> bool:
	return String(anim) in frames.get_meta("rb_baked_weapon",[])
static func fit(frames: SpriteFrames,height: float,anim: StringName=IDLE) -> Dictionary:
	var texture := frames.get_frame_texture(anim,0)
	var registration: Dictionary = frames.get_meta("rb_registration",{}).get(String(anim),{})
	var anchor: Vector2 = registration.get("anchor",frames.get_meta("runeblade_idle_anchor",Vector2(560,767)))
	var raw_height: float = registration.get("height",frames.get_meta("runeblade_idle_height",694.0))
	var point := anchor-texture.get_size()*.5
	var poses: Array = []
	var authored: Array = frames.get_meta("rb_frame_registration",{}).get(String(anim),[])
	for i in range(frames.get_frame_count(anim)):
		if i < authored.size():
			var a: Array = authored[i].anchor
			var p := Vector2(a[0],a[1])-frames.get_frame_texture(anim,i).get_size()*.5
			poses.append({"dx_use":p.x,"bottom_use":p.y,"scale":height/float(authored[i].height)})
		else:
			poses.append({"dx_use":point.x,"bottom_use":point.y})
	return {"scale":height/raw_height,"frames":poses,"tallest":raw_height,"body_med":raw_height,"reach_max":0.0}

static func update_idle(body: AnimatedSprite2D) -> void:
	if body.animation != IDLE or not body.sprite_frames.has_meta("rb_frame_registration"):
		if body.has_meta("rb_idle_material"):
			body.material = body.get_meta("rb_prior_material",null)
			body.remove_meta("rb_idle_material")
		return
	if not body.has_meta("rb_idle_material"):
		body.set_meta("rb_prior_material",body.material)
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/runeblade_idle.gdshader")
		body.material = material
		body.set_meta("rb_idle_material",true)
	var mat := body.material as ShaderMaterial
	var f := body.frame
	var n := (f+1)%body.sprite_frames.get_frame_count(IDLE)
	var regs: Array = body.sprite_frames.get_meta("rb_frame_registration")[String(IDLE)]
	var ca: Array = regs[f].anchor
	var na: Array = regs[n].anchor
	mat.set_shader_parameter("next_frame",body.sprite_frames.get_frame_texture(IDLE,n))
	mat.set_shader_parameter("current_anchor",Vector2(ca[0],ca[1]))
	mat.set_shader_parameter("next_anchor",Vector2(na[0],na[1]))
	mat.set_shader_parameter("height_ratio",float(regs[n].height)/float(regs[f].height))
	mat.set_shader_parameter("blend",body.frame_progress if body.is_playing() else 0.0)
