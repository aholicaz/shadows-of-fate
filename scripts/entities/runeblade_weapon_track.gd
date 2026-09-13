extends RefCounted
## Source-pixel sockets follow the current texture, including reordered idle frames.
static var _data: Dictionary = {}
static func sample(texture: Texture2D) -> Dictionary:
	if texture == null: return {}
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/sprites/runeblade_weapon_tracks.json"))
	var path := texture.resource_path
	var source := path.get_base_dir().get_file()
	if not _data.has(source): return {}
	var index := int(path.get_file().get_basename().trim_prefix("frame_"))-1
	var poses: Array = _data[source]
	if index < 0 or index >= poses.size(): return {}
	var p: Array = poses[index]
	return {"point":Vector2(p[0],p[1]),"angle":float(p[2]),"source":source}

static func pose(body: AnimatedSprite2D) -> Dictionary:
	var frames := body.sprite_frames
	var current := sample(frames.get_frame_texture(body.animation,body.frame))
	if current.is_empty(): return {}
	var regs: Array = frames.get_meta("rb_frame_registration",{}).get(String(body.animation),[])
	var height := 705.0
	if body.frame < regs.size():height = float(regs[body.frame].height)
	current["scale"] = height/705.0
	current["back"] = current.source=="rb_run_2018"
	current["attack"] = current.source=="rb_basic_2102" or String(current.source).begins_with("rb_skill_")
	if body.animation==&"Idle_Runeblade" and body.is_playing():
		var next_index := (body.frame+1)%frames.get_frame_count(body.animation)
		var next := sample(frames.get_frame_texture(body.animation,next_index))
		if not next.is_empty() and next_index < regs.size():
			var ca: Array = regs[body.frame].anchor
			var na: Array = regs[next_index].anchor
			# Same registration transform and easing as the body's idle shader.
			var next_point: Vector2 = (next.point-Vector2(na[0],na[1]))*height/float(regs[next_index].height)+Vector2(ca[0],ca[1])
			var t := smoothstep(0.0,1.0,body.frame_progress)
			current.point = (current.point as Vector2).lerp(next_point,t)
			current.angle = lerp_angle(deg_to_rad(current.angle),deg_to_rad(next.angle),t)*180.0/PI
	return current
