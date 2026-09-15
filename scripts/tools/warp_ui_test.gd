extends Node
var cancelled := false
func exercise_picker() -> void:
	var result: StringName = await UI.choose_warp([])
	assert(result == &"" and not get_tree().paused and not UI.is_asking())
	cancelled = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().size = Vector2i(1280,720)
	get_window().content_scale_size = Vector2i(1280,720)
	SaveManager.end_session()
	PlayerState.new_game()
	UI.set_in_game(true)
	var page = load("res://scripts/ui/warp_selector.gd").new()
	for i in range(30):
		page.targets.append({"id": "map_%d" % i, "name": "ปลายทางทดสอบ %d" % i, "cost": 200 if i < 5 else 5000, "ok": i % 2 == 0, "why": "ยังไม่เคยไปถึง"})
	UI.layer.add_child(page)
	await get_tree().process_frame
	assert(page.list.get_child_count() == 30)
	assert(page.list.get_child(1).disabled)
	assert(page.list.get_child(6).disabled)
	page.list.get_child(0).pressed.emit()
	assert(page.selected == &"map_0" and not page.travel.disabled)
	page.refresh("ไม่พบแน่นอน")
	assert(page.list.get_child_count() == 1)
	page.refresh("")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/mobile_ui/warp_selector.png")
	page.finish(&"")
	page.queue_free()
	exercise_picker()
	await get_tree().process_frame
	assert(UI.is_asking() and get_tree().paused)
	UI.layer.get_child(UI.layer.get_child_count()-1).finish(&"")
	assert(cancelled)
	print("WARP_UI_PASS: scroll list, locked/poor destinations, selection, search, cancellation")
	get_tree().quit()
