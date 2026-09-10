extends SceneTree

func _initialize() -> void:
	call_deferred("audit")

func audit() -> void:
	var frames = load("res://data/sprites/monsters/forge_guardian_frames.tres")
	var report := {}
	var original: Image = load("res://Sprites/monster/forge_guardian/spritesheet.png").get_image().duplicate()
	if original.is_compressed():
		original.decompress()
	original.resize(1024, int(original.get_height() * 1024.0 / original.get_width()))
	original.save_png("res://output/forge_guardian_stability/original.png")
	for anim in frames.get_animation_names():
		var measured = SpriteFit.measure(frames, anim)
		var rows := []
		var montage := Image.create(1024, ceili(frames.get_frame_count(anim) / 8.0) * 128, false, Image.FORMAT_RGBA8)
		montage.fill(Color(0.1,0.12,0.15))
		for i in range(frames.get_frame_count(anim)):
			var tex = frames.get_frame_texture(anim,i)
			var pic: Image = tex.get_image()
			var entry: Dictionary = measured.frames[i].duplicate()
			entry["index"] = i
			entry["region"] = str(tex.region) if tex is AtlasTexture else "full"
			entry["sheet"] = tex.atlas.resource_path if tex is AtlasTexture else tex.resource_path
			entry["size"] = str(tex.get_size())
			rows.append(entry)
			pic.resize(128,128)
			montage.blend_rect(pic,Rect2i(0,0,128,128),Vector2i(i%8*128,i/8*128))
		montage.save_png("res://output/forge_guardian_stability/"+anim+".png")
		report[anim] = {"tallest":measured.tallest,"frames":rows}
	var out = FileAccess.open("res://output/forge_guardian_stability/after.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(report,"\t"))
	quit()
