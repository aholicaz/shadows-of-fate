extends "res://scripts/tools/sep14_monster_review.gd"
## Verify the actual Gjoll scene's data bindings, not separately loaded previews.
const REVIEW := "res://output/gjoll_sprite_check/"
var map_data: Dictionary = {}

func _ready() -> void:
	PlayerState.new_game()
	UI.layer.hide()
	get_window().size = Vector2i(1800,1040)
	get_window().content_scale_size = Vector2i(1800,1040)
	RenderingServer.set_default_clear_color(Color("18242c"))
	DirAccess.make_dir_recursive_absolute(REVIEW)
	var map = load("res://scenes/maps/gjoll_river.tscn").instantiate()
	for data in map.get_node("Spawners/MapSpawner").monster_types:
		map_data[String(data.id)] = data
	map.free()
	target = Target.new()
	add_child(target)
	target.position = Vector2(-10000,-10000)
	var report := {}
	for id in ["hel_hound","ferryman","drowned"]:
		await load_actor(id)
		check(actor.data == map_data[id], id+" uses same resource as actual map")
		var poses := {}
		for anim in ["Idle","Run","Attack","Hit","Die"]:
			actor._play(anim,true)
			var sf: SpriteFrames = actor.sprite.sprite_frames
			var paths: Dictionary = {}
			for f in sf.get_frame_count(anim):
				var tex = sf.get_frame_texture(anim,f)
				if tex is AtlasTexture: tex=tex.atlas
				paths[tex.resource_path]=true
			check(paths.size()>1,id+" distinct authored frames "+anim)
			for path in paths:
				check(not String(path).contains("/chapter6/runtime/"),id+" no mockup "+anim)
			var initial_frame: int = actor.sprite.frame
			await get_tree().create_timer(0.28).timeout
			poses[anim]={"frames":sf.get_frame_count(anim),"unique_textures":paths.size(),"advances":actor.sprite.frame!=initial_frame,"paths":paths.keys()}
			title=id+" / actual Gjoll resource / "+anim
			queue_redraw()
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(REVIEW+id+"_"+anim+".png")
		report[id]=poses
	var file := FileAccess.open(REVIEW+"audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"actors":report,"checks":checks,"failures":failures},"  "))
	print("GJOLL_BINDINGS ",JSON.stringify({"checks":checks,"failures":failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
