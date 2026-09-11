extends Node

# Dedicated 30-second capture scene; never saves player progress.
const MAPS := ["asgard_forest_2", "ember_mine", "hall_of_silence", "silver_marsh", "spring_of_life"]
const SHOT_FRAMES := 180
const FADE_FRAMES := 24.0
var frame := 0
var current_map: Node2D
var curtain: ColorRect

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)
	curtain = ColorRect.new()
	curtain.color = Color.BLACK
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(curtain)
	PlayerState.stats.move_speed = 240.0
	_load_map(0)
	Input.action_press("move_right")

func _load_map(index: int) -> void:
	if is_instance_valid(current_map):
		remove_child(current_map)
		current_map.queue_free()
	current_map = load("res://scenes/maps/%s.tscn" % MAPS[index]).instantiate()
	current_map.intro_video = ""
	for node_name in ["Spawners", "Portals"]:
		var node := current_map.get_node_or_null(node_name)
		if node != null:
			node.free()
	add_child(current_map)
	current_map.player.position.x = 1000.0
	current_map.camera.position_smoothing_enabled = false
	current_map.camera.reset_smoothing()
	UI.layer.hide()
	print("SHOWCASE_MAP ", MAPS[index])

func _process(_delta: float) -> void:
	if frame >= SHOT_FRAMES * MAPS.size():
		Input.action_release("move_right")
		get_tree().quit()
		return
	var local_frame := frame % SHOT_FRAMES
	if frame > 0 and local_frame == 0:
		_load_map(frame / SHOT_FRAMES)
	var fade_in := 1.0 - clampf(float(local_frame) / FADE_FRAMES, 0.0, 1.0)
	var fade_out := clampf(float(local_frame - (SHOT_FRAMES - 1 - int(FADE_FRAMES))) / FADE_FRAMES, 0.0, 1.0)
	curtain.color.a = maxf(fade_in, fade_out)
	if local_frame == 90:
		_save_preview(frame / SHOT_FRAMES)
	frame += 1

func _save_preview(index: int) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/map_run_showcase/%s.png" % MAPS[index])
	print("SHOWCASE_POSITION ", MAPS[index], " ", current_map.player.position)
