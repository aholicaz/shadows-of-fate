extends Node

# Capture-only montage. Media is written outside the game project.
const OUT := "C:/Users/peeco/Downloads/คลิปsof/บท1-3_นักดาบ_Runeblade/"
const MAPS := ["prontera_town", "asgard_forest_2", "dark_forest_2", "nidavellir_town", "ember_mine", "cold_forge", "vanir_town", "silver_marsh", "spring_of_life"]
const CENTERS := [1400.0, 1900.0, 2600.0, 2700.0, 2700.0, 2100.0, 2700.0, 2600.0, 1700.0]
const SHOT_FRAMES := 135
var tick := 0
var shot := 0
var map: Node2D
var actor: Node2D
var floor_y := 880.0

func _ready() -> void:
	seed(340012)
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	PlayerState.gm_god_mode = true
	# Skip automatic boss cutscenes during the running montage.
	UI.video_playing = true
	_load_map(0)

func _load_map(index: int) -> void:
	shot = index
	var wanted_job: StringName = &"swordsman" if index < 3 else &"runeblade"
	if PlayerState.stats.job_id != wanted_job:
		PlayerState.stats.change_profession(wanted_job)
		PlayerState.refresh()
		Events.skills_changed.emit()
	var root_to_foot := 120.0
	if is_instance_valid(map):
		root_to_foot = actor.foot_position().y - actor.global_position.y
		actor.reparent(self)
		remove_child(map)
		map.queue_free()
	map = load("res://scenes/maps/%s.tscn" % MAPS[index]).instantiate()
	map.intro_video = ""
	map.camera_fit_height = false
	map.camera_zoom = Vector2.ONE * (720.0 / 1400.0)
	for child_name in ["Portals", "Lore"]:
		var child := map.get_node_or_null(child_name)
		if child != null:
			child.free()
	var spawners := map.get_node_or_null("Spawners")
	if spawners != null:
		for spawner in spawners.get_children():
			if spawner is MapSpawner:
				spawner.spawn_offscreen = false
				spawner.initial_delay = 0.0
	add_child(map)
	actor = map.player
	if actor.get_parent() != map:
		actor.reparent(map)
	var ground := map.get_node("Terrain/Ground/Shape") as CollisionShape2D
	floor_y = ground.global_position.y - ground.shape.size.y * 0.5
	var half_duration := 2.25
	actor.global_position = Vector2(CENTERS[index] - PlayerState.stats.move_speed * half_duration, floor_y - root_to_foot)
	actor.velocity = Vector2.ZERO
	actor.set_collision_mask_value(3, false)
	map.camera.position_smoothing_enabled = false
	map.camera.limit_left = -100000
	map.camera.limit_right = 100000
	map.camera.limit_top = -100000
	map.camera.limit_bottom = 100000
	map.camera.offset = Vector2.ZERO
	map.camera.reset_smoothing()
	UI.layer.hide()
	if actor.runeblade != null and actor.runeblade.hud != null:
		actor.runeblade.hud.get_parent().hide()
	# Hidden equipment previews can have empty SpriteFrames; they are not part of this recording.
	for node in get_tree().root.find_children("*", "Node", true, false):
		var script = node.get_script()
		if script != null and script.resource_path == "res://scripts/entities/character_visual.gd":
			if node.body != null and node.body.sprite_frames == null:
				print("CAPTURE_SKIP_EMPTY_PREVIEW ", node.get_path())
				node.set_process(false)
	var floating := map.get_node_or_null("FloatingTextLayer") as CanvasItem
	if floating != null:
		floating.hide()
	print("WORLD_SHOT ", index, " ", MAPS[index], " floor=", floor_y, " movie_frame=", Engine.get_frames_drawn())

func _process(_delta: float) -> void:
	if tick == 30:
		Input.action_press("move_right")
	var run_tick := tick - 30
	if run_tick > 0 and run_tick % SHOT_FRAMES == 0 and run_tick / SHOT_FRAMES < MAPS.size():
		_load_map(run_tick / SHOT_FRAMES)
	map.camera.global_position = Vector2(actor.global_position.x, floor_y - 380.0)
	var local_tick := run_tick - shot * SHOT_FRAMES
	if run_tick >= 0 and local_tick in [18, 63, 114]:
		_preview(shot, local_tick)
	tick += 1
	if tick >= 1245:
		get_tree().quit()

func _preview(index: int, frame: int) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + "%s_%d.png" % [MAPS[index], frame])
	print("WORLD_FRAME ", MAPS[index], " ", frame, " screen=", actor.get_global_transform_with_canvas().origin, " job=", PlayerState.stats.job_id, " anim=", actor.sprite.animation, " enemies=", get_tree().get_nodes_in_group("enemy").size(), " npcs=", get_tree().get_nodes_in_group("npc").size())

func _exit_tree() -> void:
	Input.action_release("move_right")

