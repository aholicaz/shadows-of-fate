extends Node2D
## รอบ 181 — ภาพหน้าสกิล Ninth Edge (ต้นไม้ 8 ช่อง + รายละเอียด)
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output/r181/"))
	get_window().size = Vector2i(1280, 720)
	PlayerState.new_game()
	PlayerState.stats.job_id = &"ninth_edge"
	PlayerState.stats.level = 120
	PlayerState.stats.job_level = 30
	PlayerState.stats.skill_points = 12
	for id in [&"ninth_vessel", &"named_edge", &"erasing_step", &"ninefold_cyclone", &"ninth_inscription"]:
		PlayerState.skills.learned[id] = 3
	PlayerState.refresh()
	await get_tree().process_frame
	UI.open(&"skills")
	await get_tree().process_frame
	var w = UI.windows[&"skills"]
	w.refresh()
	for sel in [&"ninefold_cyclone", &"ninth_inscription"]:
		w._select(sel)
		for i in 4: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://output/r181/skill_window_%s.png" % sel))
	get_tree().quit()
