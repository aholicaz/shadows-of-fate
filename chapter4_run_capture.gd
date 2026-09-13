extends Node

# Six short location shots, later cross-dissolved. Capture only; no save calls.
const MAPS := ["frost_pass", "utgard_town", "giant_steppe", "frozen_hall", "broken_wall", "hrungnir_crater"]
const CENTERS := [2600.0, 2100.0, 2800.0, 2700.0, 3250.0, 1700.0]
const SHOT_FRAMES := 108
var tick := 0
var map: Node2D
var actor: Node2D

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	_load_map(0)

func _load_map(index: int) -> void:
	var feet_y := 0.0
	if is_instance_valid(map):
		feet_y = actor.position.y
		actor.reparent(self)
		remove_child(map)
		map.queue_free()
	map = load("res://scenes/maps/%s.tscn" % MAPS[index]).instantiate()
	map.intro_video = ""
	map.camera_fit_height = false
	map.camera_zoom = Vector2.ONE * (720.0 / 1400.0)
	for child_name in ["Spawners", "Portals", "Lore", "NPCs"]:
		var child := map.get_node_or_null(child_name)
		if child != null:
			child.free()
	add_child(map)
	actor = map.player
	if actor.get_parent() != map:
		actor.reparent(map)
	actor.position.x = CENTERS[index] - PlayerState.stats.move_speed * 1.8
	if feet_y != 0.0:
		actor.position.y = feet_y
	map.camera.position_smoothing_enabled = false
	map.camera.limit_left = -100000
	map.camera.limit_right = 100000
	map.camera.limit_top = -100000
	map.camera.limit_bottom = 100000
	map.camera.offset = Vector2.ZERO
	map.camera.reset_smoothing()
	UI.layer.hide()
	print("CH4_SHOT ", index, " ", MAPS[index], " zoom=", map.camera.zoom)

func _process(_delta: float) -> void:
	if tick == 30:
		Input.action_press("move_right")
	var shot_tick := tick - 30
	if shot_tick > 0 and shot_tick % SHOT_FRAMES == 0:
		_load_map(shot_tick / SHOT_FRAMES)
	# Identical world-space framing: full 1400-unit height, runner on the center line.
	map.camera.global_position = Vector2(actor.global_position.x, 500.0)
	if shot_tick >= 0 and shot_tick % SHOT_FRAMES in [12, 54, 96]:
		_preview(shot_tick / SHOT_FRAMES, shot_tick % SHOT_FRAMES)
	tick += 1

func _preview(index: int, frame: int) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/chapter4_run/%s_%d.png" % [MAPS[index], frame])
	var screen_at: Vector2 = actor.get_global_transform_with_canvas().origin
	print("CH4_POSITION ", MAPS[index], " ", frame, " screen=", screen_at, " animation=", actor.sprite.animation)

func _exit_tree() -> void:
	Input.action_release("move_right")
