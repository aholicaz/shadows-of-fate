## Real renderer checks: actor contrast with lamps on/off and map-local cleanup.
extends Node

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func shot() -> Image:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()

func contrast(a: Image, b: Image, rect: Rect2i) -> float:
	var sum := 0.0
	var area := rect.intersection(Rect2i(Vector2i.ZERO, a.get_size()))
	for y in range(area.position.y, area.end.y, 2):
		for x in range(area.position.x, area.end.x, 2):
			var c := a.get_pixel(x, y)
			var d := b.get_pixel(x, y)
			sum += absf(c.r-d.r) + absf(c.g-d.g) + absf(c.b-d.b)
	return sum

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	var map = load("res://scenes/maps/cold_forge.tscn").instantiate()
	map.get_node("Spawners").free()
	add_child(map)
	var player = map.player
	player.set_physics_process(false)
	player.global_position = Vector2(900, 760)
	player.sprite.play(&"Idle")
	player.sprite.speed_scale = 0.0
	var actors: Array[Node2D] = [player]
	for spec in [{"id":"forge_golem", "x":1524}, {"id":"forge_guardian", "x":2110}]:
		var monster = load("res://scenes/monsters/monster.tscn").instantiate()
		monster.data = load("res://data/monsters/%s.tres" % spec.id)
		map.add_child(monster)
		monster.set_physics_process(false)
		monster.global_position += Vector2(spec.x-monster.global_position.x, 880-monster.foot_position().y)
		monster.sprite.speed_scale = 0.0
		actors.append(monster)
	map.camera.position_smoothing_enabled = false
	map.camera.zoom = Vector2(0.6, 0.6)
	map.camera.offset = Vector2.ZERO
	map.camera.global_position = Vector2(1500, 490)
	UI.layer.hide()
	var ambient := map.get_node("AmbientFX") as MapAmbientFX
	check(map.get_node("Darkness") is CanvasModulate, "Cold Forge has local darkness")
	check(ambient.light_background and ambient.shaft_positions.is_empty(), "Only lanterns illuminate background")
	# Freeze flicker so the paired image subtraction measures actor lighting alone.
	ambient.set_process(false)
	var measures: Array = []
	for enabled in [false, true]:
		for lamp in ambient._lamps:
			lamp.light.enabled = enabled
		var with_actors := await shot()
		if enabled:
			with_actors.save_png("res://output/map_art_next/cold_forge_dark_lanterns.png")
		else:
			with_actors.save_png("res://output/map_art_next/cold_forge_dark_unlit.png")
		for actor in actors:
			actor.hide()
		var without_actors := await shot()
		var values: Array[float] = []
		for actor in actors:
			var foot: Vector2 = actor.foot_position()
			var world_box := Rect2(foot + Vector2(-95, -230), Vector2(190, 215))
			var screen_box: Rect2 = get_viewport().get_canvas_transform() * world_box
			values.append(contrast(with_actors, without_actors, Rect2i(screen_box)))
			actor.show()
		measures.append(values)
	for i in range(3):
		print("ACTOR_LIGHT_RATIO %d: %.2f" % [i, measures[1][i] / maxf(0.01, measures[0][i])])
		check(measures[1][i] > measures[0][i] * 1.5, "Player, monster and boss brighten in lantern light")
	var spatial: Array[float] = []
	actors[1].hide()
	actors[2].hide()
	for x in [100.0, 900.0]:
		player.global_position.x = x
		map.camera.global_position = Vector2(700, 490)
		player.show()
		var lit_actor := await shot()
		player.hide()
		var empty := await shot()
		var box := Rect2(player.foot_position() + Vector2(-95, -230), Vector2(190, 215))
		spatial.append(contrast(lit_actor, empty, Rect2i(get_viewport().get_canvas_transform() * box)))
	print("ENTER_LANTERN_RATIO: %.2f" % (spatial[1] / maxf(0.01, spatial[0])))
	check(spatial[1] > spatial[0] * 1.5, "Entering lantern area brightens player with all lamps continuously on")
	ambient.set_process(true)
	# Compare same scene after removing its CanvasModulate, then verify another map has none.
	map.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	var hall = load("res://scenes/maps/hall_of_silence.tscn").instantiate()
	hall.get_node("Spawners").free()
	add_child(hall)
	check(hall.get_node_or_null("Darkness") == null, "Hall keeps normal ambient light")
	check(not (hall.get_node("AmbientFX") as MapAmbientFX).light_background, "Other map lighting unchanged")
	for tick in range(60):
		await get_tree().physics_frame
	var restored := await shot()
	restored.save_png("res://output/map_art_next/hall_after_dark_forge.png")
	print("COLD_FORGE_DARKNESS_TEST: 3 real actor renders and map exit; %d failures" % failures)
	get_tree().quit(failures)
