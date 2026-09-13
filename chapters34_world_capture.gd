extends Node

# Capture-only montage. Media is written outside the game project.
const OUT := "C:/Users/peeco/Downloads/คลิปsof/บท3_วิ่งชมโลก/"
const MAPS := ["root_road", "vanir_town", "silver_marsh", "withered_grove", "forgotten_battlefield", "spring_of_life"]
const CENTERS := [2600.0, 2700.0, 2600.0, 2500.0, 2600.0, 1700.0]
const SHOT_FRAMES := 165
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
	_load_map(0)

func _load_map(index: int) -> void:
	shot = index
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
	var half_duration := 2.75
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
	var floating := map.get_node_or_null("FloatingTextLayer") as CanvasItem
	if floating != null:
		floating.hide()
	print("WORLD_SHOT ", index, " ", MAPS[index], " floor=", floor_y)

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

func _preview(index: int, frame: int) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + "%s_%d.png" % [MAPS[index], frame])
	print("WORLD_FRAME ", MAPS[index], " ", frame, " screen=", actor.get_global_transform_with_canvas().origin, " anim=", actor.sprite.animation, " enemies=", get_tree().get_nodes_in_group("enemy").size(), " npcs=", get_tree().get_nodes_in_group("npc").size())

func _exit_tree() -> void:
	Input.action_release("move_right")
