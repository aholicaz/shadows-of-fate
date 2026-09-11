extends Node

# Capture only. Uses the current player animation and movement speed.
var tick := 0
var map: Node2D
var headline: Label

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	map = load("res://scenes/maps/asgard_forest_2.tscn").instantiate()
	map.intro_video = ""
	map.camera_fit_height = false
	map.camera_zoom = Vector2.ONE
	for child_name in ["Spawners", "Portals", "Lore38"]:
		var child := map.get_node_or_null(child_name)
		if child != null:
			child.free()
	add_child(map)
	map.player.position.x = 900.0
	map.camera.position_smoothing_enabled = false
	map.camera.reset_smoothing()
	UI.layer.hide()
	var layer := CanvasLayer.new()
	layer.layer = 80
	add_child(layer)
	var plate := ColorRect.new()
	plate.position = Vector2(32, 28)
	plate.size = Vector2(730, 126)
	plate.color = Color(0.025, 0.06, 0.045, 0.85)
	layer.add_child(plate)
	var accent := ColorRect.new()
	accent.position = Vector2(32, 28)
	accent.size = Vector2(4, 126)
	accent.color = Color("e4c478")
	layer.add_child(accent)
	headline = _label(layer, "ก้าวใหม่ของ Shadows of Fate", Vector2(58, 36), 36, Color("f4e9cf"))
	_label(layer, "อัปเดตท่าวิ่ง • ภาพจากเกมระหว่างพัฒนา", Vector2(60, 98), 23, Color("d6dfd8"))
	print("CREATOR_RUN_SPEED ", PlayerState.stats.move_speed)

func _label(parent: Node, words: String, at: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = words
	label.position = at
	label.add_theme_font_override("font", load("res://fonts/NotoSansThai-Regular.ttf"))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _process(_delta: float) -> void:
	if tick == 30:
		Input.action_press("move_right")
	if tick == 150:
		map.player.position.x = 900.0
		map.camera.zoom = Vector2(0.82, 0.82)
		map.camera.reset_smoothing()
	if tick in [60, 90, 180, 210]:
		_preview(tick)
	if tick == 269:
		Input.action_release("move_right")
	tick += 1

func _preview(number: int) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/creator_run_update/frame_%d.png" % number)
	print("CREATOR_PREVIEW ", number, " ", map.player.position, " ", map.player.sprite.animation)
