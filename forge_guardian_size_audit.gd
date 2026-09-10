extends SceneTree

func _initialize() -> void:
	call_deferred("audit")

func audit() -> void:
	var frames: SpriteFrames = load("res://data/sprites/monsters/forge_guardian_frames.tres")
	var pool := {}
	for anim in ["Idle", "Run", "Attack"]:
		var heights := []
		for i in range(6 if anim == "Attack" else frames.get_frame_count(anim)):
			var pic := SpriteFit._frame_image(frames.get_frame_texture(anim,i), pool)
			var top := 512
			var bottom := 0
			for y in range(512):
				var count := 0
				for x in range(220,380):
					if pic.get_pixel(x,y).a > 0.1:
						count += 1
				if count >= 8:
					top = mini(top,y)
					bottom = maxi(bottom,y)
			heights.append(bottom-top+1)
		heights.sort()
		print(anim, " torso/feet height median=", heights[heights.size()/2], " range=", heights.front(), "..", heights.back())
	quit()
