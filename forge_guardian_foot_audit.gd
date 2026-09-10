extends SceneTree

func _initialize() -> void:
	call_deferred("audit")

func audit() -> void:
	var frames: SpriteFrames = load("res://data/sprites/monsters/forge_guardian_frames.tres")
	var pool := {}
	for anim in frames.get_animation_names():
		var bottoms := []
		for i in range(frames.get_frame_count(anim)):
			var pic := SpriteFit._frame_image(frames.get_frame_texture(anim,i), pool)
			var bottom := 0
			for y in range(390,470):
				var count := 0
				for x in range(260,410):
					if pic.get_pixel(x,y).a > 0.4:
						count += 1
				if count >= 10:
					bottom = y+1
			bottoms.append(bottom)
		print(anim, " soles=", bottoms)
	quit()

