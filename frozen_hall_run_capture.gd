extends Node

# Isolated capture scene: real movement and animation; no save writes.
var tick := 0
var map: Node2D

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	map = load("res://scenes/maps/frozen_hall.tscn").instantiate()
	map.intro_video = ""
	map.camera_fit_height = false
	map.camera_zoom = Vector2(0.8, 0.8)
	for child_name in ["Spawners", "Portals", "Lore"]:
		var child := map.get_node_or_null(child_name)
		if child != null:
			child.free()
	add_child(map)
	map.player.position.x = 650.0
	map.camera.position_smoothing_enabled = false
	map.camera.reset_smoothing()
	UI.layer.hide()
	print("FROZEN_CAPTURE_SPEED ", PlayerState.stats.move_speed)

func _process(_delta: float) -> void:
	if tick == 30:
		Input.action_press("move_right")
	if tick in [60, 150, 240]:
		_preview(tick)
	tick += 1

func _preview(number: int) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/frozen_hall_run/frame_%d.png" % number)
	print("FROZEN_CAPTURE ", number, " ", map.player.position, " ", map.player.sprite.animation)

func _exit_tree() -> void:
	Input.action_release("move_right")
