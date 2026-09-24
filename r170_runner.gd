extends Node
var fails := 0
var passes := 0
const OUT := "res://output/r170/"
func ok(c: bool, m: String) -> void:
	if c: passes += 1; print("  PASS ", m)
	else: fails += 1; print("  FAIL ", m)

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	var bg := TextureRect.new()
	bg.texture = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(OUT + "bg.jpg")))
	bg.size = Vector2(1280, 720)
	bg.modulate = Color(0.6, 0.65, 0.65)
	add_child(bg)
	await get_tree().process_frame
	SaveManager.end_session()
	PlayerState.new_game()
	UI.set_in_game(true)
	var sheet := Image.create(160 * 7, 180, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#102725"))
	var i := 0
	for id in [&"poring", &"lunatic", &"wolf", &"orc_warrior", &"munak", &"water_nymph", &"crystal_stag"]:
		var t0 := Time.get_ticks_msec()
		var tex := BountyBoardWindow.monster_portrait(id)
		var ms := Time.get_ticks_msec() - t0
		ok(tex != null, "รูปหน้า %s (%d ms)" % [id, ms])
		if tex != null:
			var im := tex.get_image()
			im.clear_mipmaps()
			im.resize(152, 152)
			sheet.blit_rect(im, Rect2i(0, 0, 152, 152), Vector2i(i * 160 + 4, 4))
		i += 1
	sheet.save_png(ProjectSettings.globalize_path(OUT + "portraits.png"))
	var t1 := Time.get_ticks_msec()
	BountyBoardWindow.monster_portrait(&"poring")
	ok(Time.get_ticks_msec() - t1 < 5, "เรียกซ้ำใช้แคช")
	PlayerState.current_map_id = &"prontera_town"
	PlayerState.stats.level = 5
	UI.open_bounty_board(&"prontera_town")
	for k in 6: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "board.png"))
	var bb = UI.windows[&"bounty"]
	ok(bb._cards.get_child(0).find_child("MonsterPortrait", true, false) != null, "การ์ดใบล่าใช้รูปหน้ามอน")
	print("R170 RESULT: %d pass · %d fail" % [passes, fails])
	get_tree().quit(1 if fails > 0 else 0)
