extends RefCounted
## Partial job art: only authored poses override the existing weapon animations.
const IDLE := &"Idle_Runeblade"
static func install(body: AnimatedSprite2D) -> void:
	if body.sprite_frames.has_animation(IDLE): return
	var source := load("res://data/sprites/runeblade_idle_frames.tres") as SpriteFrames
	var merged := body.sprite_frames.duplicate() as SpriteFrames
	merged.add_animation(IDLE)
	merged.set_animation_loop(IDLE,true)
	merged.set_animation_speed(IDLE,source.get_animation_speed(IDLE))
	for i in range(source.get_frame_count(IDLE)):
		merged.add_frame(IDLE,source.get_frame_texture(IDLE,i),source.get_frame_duration(IDLE,i))
	for key in source.get_meta_list(): merged.set_meta(key,source.get_meta(key))
	body.sprite_frames = merged
static func fit(frames: SpriteFrames,height: float) -> Dictionary:
	var texture := frames.get_frame_texture(IDLE,0)
	var anchor: Vector2 = frames.get_meta("runeblade_idle_anchor")
	var raw_height: float = frames.get_meta("runeblade_idle_height")
	var point := anchor-texture.get_size()*.5
	var poses: Array = []
	for i in range(frames.get_frame_count(IDLE)):
		poses.append({"dx_use":point.x,"bottom_use":point.y})
	return {"scale":height/raw_height,"frames":poses,"tallest":raw_height,"body_med":raw_height,"reach_max":0.0}
