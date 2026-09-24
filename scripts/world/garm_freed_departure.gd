extends RefCounted
## Only the release cutscene uses the new standing/walking form.
## The sleeping story portrait at Odin's throne remains appropriate to its dialogue.
static func play(garm: Node2D) -> void:
	var visual := AnimatedSprite2D.new()
	visual.sprite_frames = load("res://data/sprites/monsters/garm_freed_frames.tres")
	visual.centered = false
	visual.offset = Vector2(-800, -1100)
	visual.flip_h = true
	# Neutral body is 336 px tall; ignore the nearly invisible export halo.
	visual.scale = Vector2.ONE * garm.data.display_height / 336.0
	garm.get_parent().add_child(visual)
	visual.global_position = garm.foot_position()
	visual.z_index = garm.z_index
	garm.hide()
	visual.play("Walk")
	var tween := visual.create_tween()
	tween.tween_property(visual, "position:x", visual.position.x + 460.0, 2.0)
	tween.parallel().tween_property(visual, "modulate:a", 0.0, 0.35).set_delay(1.65)
	await tween.finished
	visual.queue_free()
