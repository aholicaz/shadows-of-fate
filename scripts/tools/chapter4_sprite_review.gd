extends Node2D
## Artist review at current game sizes. Does not load or save player progress.
@export var monster_ids: Array[String] = ["frost_wolf", "ice_troll", "wall_shieldbearer", "stone_hrungnir"]
const ANIMS := ["Idle", "Walk", "Attack", "Hit", "Die", "Skill"]
@export var output_folder := "res://output/spriteflow/chapter4/"
var actors: Array[Node2D] = []
var selected := "Idle"
var mirrored := false
var capture_mode := false

func _ready() -> void:
	get_window().size = Vector2i(1850, 820)
	get_window().content_scale_size = Vector2i(1850, 820)
	RenderingServer.set_default_clear_color(Color("18242c"))
	UI.layer.hide()
	capture_mode = OS.get_cmdline_user_args().has("--capture-chapter4")
	for i in monster_ids.size():
		var actor = preload("res://scenes/monsters/monster.tscn").instantiate()
		actor.data = load("res://data/monsters/%s.tres" % monster_ids[i])
		actor.position = Vector2((i + 0.5) * 1850.0 / monster_ids.size(), 700 - actor.data.foot_offset())
		add_child(actor)
		actor.set_physics_process(false)
		if actor._hp_bar != null: actor._hp_bar.hide()
		actors.append(actor)
	var bar := HBoxContainer.new()
	bar.position = Vector2(30, 82)
	add_child(bar)
	var choice := OptionButton.new()
	for anim in ANIMS: choice.add_item(anim)
	choice.item_selected.connect(func(i: int): selected = ANIMS[i]; play())
	bar.add_child(choice)
	var flip := Button.new()
	flip.text = "Flip left / right"
	flip.pressed.connect(func(): mirrored = not mirrored; play())
	bar.add_child(flip)
	var restart := Button.new()
	restart.text = "Replay"
	restart.pressed.connect(play)
	bar.add_child(restart)
	play()
	if capture_mode:
		DirAccess.make_dir_recursive_absolute(output_folder)
		for direction in [false, true]:
			mirrored = direction
			for anim in ANIMS:
				selected = anim
				play()
				var last := 0.0
				for moment in [0.0, 0.45, 2.6]:
					if moment > last: await get_tree().create_timer(moment - last).timeout
					await RenderingServer.frame_post_draw
					get_viewport().get_texture().get_image().save_png(output_folder + "%s_%s_%03d.png" % [anim, "R" if direction else "L", int(moment * 100)])
					last = moment
		print("CHAPTER4_CAPTURE_COMPLETE")
		get_tree().quit()

func play() -> void:
	for actor in actors:
		actor.facing = 1 if mirrored else -1
		actor.sprite.flip_h = mirrored
		actor._play(selected, true)
		actor._apply_fit()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 700, 1850, 120), Color("354454"))
	draw_line(Vector2(0, 700), Vector2(1850, 700), Color("9db4c6"), 2)
	draw_string(ThemeDB.fallback_font, Vector2(30, 43), "CHAPTER 4 / SPRITEFLOW / " + selected, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
	for i in actors.size():
		draw_string(ThemeDB.fallback_font, Vector2(30 + i * 1850.0 / monster_ids.size(), 166), "%s / %d px" % [monster_ids[i], actors[i].data.display_height], HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
