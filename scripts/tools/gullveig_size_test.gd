extends Node2D
const MONSTER = preload("res://scenes/monsters/monster.tscn")
func _ready() -> void:
	get_window().size = Vector2i(1500,850)
	get_window().content_scale_size = Vector2i(1500,850)
	UI.layer.hide()
	RenderingServer.set_default_clear_color(Color("192333"))
	var actors: Array = []
	for i in range(3):
		var actor = MONSTER.instantiate()
		actor.data = load("res://data/monsters/gullveig_ember.tres")
		add_child(actor)
		actor.set_physics_process(false)
		actor.position = Vector2(250+i*500,730-actor.data.foot_offset())
		actor.sprite.position.y = -actor.data.hover_height
		actor._play(["Idle","Hit","Die"][i],true)
		actor.sprite.pause()
		actors.append(actor)
	var base_height: float = 656.0*actors[0].sprite.scale.y
	var hit_height: float = 298.0*actors[1].sprite.scale.y
	assert(absf(hit_height/base_height-1.0)<.04,"Hit body scale must match Idle")
	assert(is_equal_approx(actors[1].sprite.scale.y,actors[2].sprite.scale.y),"Hit and Die share native body scale")
	DirAccess.make_dir_recursive_absolute("res://output/gullveig_size")
	for index in [0,2,4,9,17]:
		actors[1].sprite.frame = mini(index,4)
		actors[2].sprite.frame = index
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/gullveig_size/compare_%02d.png"%index)
	print("GULLVEIG_SIZE_PASS idle=",base_height," hit=",hit_height," ratio=",hit_height/base_height)
	get_tree().quit()
func _draw() -> void:
	for i in range(3):
		draw_string(ThemeDB.fallback_font,Vector2(150+i*500,65),["IDLE","HIT","DIE"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color.WHITE)
	draw_line(Vector2(0,730),Vector2(1500,730),Color("8495aa"),2)
