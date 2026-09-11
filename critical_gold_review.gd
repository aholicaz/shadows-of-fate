extends Node2D

var checks := 0
func verify(ok: bool, message: String) -> void:
	assert(ok, message)
	checks += 1
	print("PASS: ", message)

func bursts() -> Array[Node]:
	return get_tree().get_nodes_in_group("critical_gold_bursts")

func monster(at: Vector2) -> Node2D:
	var mon = load("res://scenes/monsters/monster.tscn").instantiate()
	mon.data = load("res://data/monsters/poring.tres")
	add_child(mon)
	mon.position = at
	mon.set_physics_process(false)
	mon.hp = 10000
	return mon

func _ready() -> void:
	get_window().size = Vector2i(1000, 650)
	get_window().content_scale_size = Vector2i(1000, 650)
	RenderingServer.set_default_clear_color(Color("#141b27"))
	PlayerState.new_game()
	Game.sfx.enabled = true
	Game.sfx.volume = 0.8
	Game.sfx._last_played.erase("critical_impact")
	var target = monster(Vector2(400, 430))
	var bystander = monster(Vector2(750, 430))
	await get_tree().process_frame
	for child in UI.get_children():
		if child is CanvasLayer or child is CanvasItem:
			child.hide()
	target.take_damage(10, false)
	verify(bursts().is_empty(), "ordinary hit produces no critical rays")
	verify(not Game.sfx._last_played.has("critical_impact"), "ordinary hit does not play critical audio")
	target.take_damage(0, true)
	verify(bursts().is_empty(), "zero damage produces no critical rays")
	var before: int = target.hp
	var expected: Vector2 = target.body_rect().get_center()
	target.take_damage(221, true)
	verify(target.hp == before - 221, "effect does not add damage")
	verify(bursts().size() == 1, "critical hit creates one burst")
	verify(not Game.sfx._last_played.has("critical_impact"), "critical impact audio is disabled")
	var burst = bursts()[0]
	verify(burst.global_position.is_equal_approx(expected), "rays originate at struck monster body center")
	verify(burst.get_child_count() == 8, "eight rays cover the full circle")
	for ray in burst.get_children():
		verify(is_equal_approx(ray.get_child(0).rotation_degrees, 45.0), "ray sharp tip faces inward")
	verify(bystander.hp == 10000, "nearby monster is unaffected")
	verify(burst.get_parent() == self, "burst is independent of the monster lifetime")
	# Freeze the real burst at an intermediate state for a stable preview.
	burst.process_mode = Node.PROCESS_MODE_DISABLED
	for ray in burst.get_children():
		ray.get_child(0).modulate.a = 1.0
		ray.get_child(0).position.x = 100.0
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/critical_gold_preview.png")
	burst.process_mode = Node.PROCESS_MODE_INHERIT
	await get_tree().create_timer(0.32).timeout
	verify(bursts().is_empty(), "burst cleans up after a quarter second")
	target.hp = 1
	target.take_damage(221, true)
	verify(bursts().size() == 1 and target.is_dead(), "lethal critical still shows the effect")
	target.take_damage(221, true)
	verify(bursts().size() == 1, "dead target cannot generate extra bursts")
	target.queue_free()
	await get_tree().process_frame
	verify(bursts().size() == 1, "effect survives target removal")
	await get_tree().create_timer(0.32).timeout
	verify(bursts().is_empty(), "lethal burst also cleans up")
	bystander.queue_free()
	print("CRITICAL GOLD: ", checks, " checks passed")
	get_tree().quit()
