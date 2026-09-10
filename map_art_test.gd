## Visual/physics regression for the two chapter 2 map backgrounds.
## Run: godot --path . --scene res://map_art_test.tscn
extends Node

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	for spec in [{"id": "ember_mine", "width": 5200}, {"id": "hall_of_silence", "width": 4800}]:
		var map = load("res://scenes/maps/%s.tscn" % spec.id).instantiate()
		# Only remove enemies from this test instance; preserve the actual map.
		map.get_node("Spawners").free()
		add_child(map)
		var ambient := map.get_node("AmbientFX") as MapAmbientFX
		check(ambient._lamps.size() == (7 if spec.id == "ember_mine" else 2), "Authored lantern count")
		var first_light := ambient._lamps[0].light as PointLight2D
		var initial_energy := first_light.energy
		for tick in range(20):
			await get_tree().process_frame
		check(absf(first_light.energy - initial_energy) > 0.001, "Lantern light must flicker over time")
		check(first_light.energy > 0.0 and first_light.energy < 0.3, "Lantern light stays subtle")
		var sky := map.get_node("Background/Sky") as Polygon2D
		check(sky.texture.get_size() == Vector2(spec.width, 1400), "Native texture size: " + spec.id)
		check(sky.uv[2] == sky.texture.get_size(), "UV must map whole image 1:1: " + spec.id)
		var ground := map.get_node("Terrain/Ground/Shape") as CollisionShape2D
		var floor_y := ground.global_position.y - (ground.shape as RectangleShape2D).size.y * 0.5
		check(is_equal_approx(floor_y, 900.0), "Original collision floor must remain Y=900")
		check(is_equal_approx(sky.global_position.y + 1100.0, floor_y), "Art lip and collider must align")
		var body = map.player
		var camera := map.camera as Camera2D
		camera.position_smoothing_enabled = false
		for marker in map.get_node("SpawnPoints").get_children():
			check(marker.position.y == 840.0, "Spawn height preserved")
		for portal in map.get_node("Portals").get_children():
			check(portal.position.y == 900.0, "Portal height preserved")
		for i in range(3):
			body.global_position = Vector2(250.0 + i * (spec.width - 600.0) / 2.0, 650.0)
			body.velocity = Vector2.ZERO
			for frame in range(60):
				await get_tree().physics_frame
			check(body.is_on_floor(), "Player must stand at sample %d in %s" % [i, spec.id])
			check(absf(body.foot_position().y - floor_y) < 3.0, "Player feet must match floor")
			camera.reset_smoothing()
			UI.layer.hide()
			await get_tree().process_frame
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://output/map_art/%s_lighting_%d.png" % [spec.id, i])
		body.global_position = Vector2(spec.width * 0.5 - 450.0, body.global_position.y)
		Input.action_press("move_right")
		for frame in range(240):
			await get_tree().physics_frame
			check(body.is_on_floor(), "Continuous walk must not fall through floor")
		Input.action_release("move_right")
		check(body.global_position.x > spec.width * 0.5, "Player must cross artwork seam")
		map.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	print("MAP_ART_TEST: 2 maps, 6 standing samples, 480 walking frames, %d failures" % failures)
	get_tree().quit(failures)
