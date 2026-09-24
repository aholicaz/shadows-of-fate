extends Node
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManager.end_session()
	PlayerState.new_game()
	get_window().size=Vector2i(1440,900)
	get_window().content_scale_size=Vector2i(1440,900)
	UI.set_in_game(true)
	var checks := 0
	for rank in BountyBoard.RANKS:
		var texture := GuildRankWindow.rank_icon(String(rank[0]))
		assert(texture!=null and texture.get_size()==Vector2(512,512))
		checks+=1
	for idx in [1,6]:
		PlayerState.bounties.points=int(BountyBoard.RANKS[idx][1])+5
		UI._on_guild_rank_opened()
		await get_tree().process_frame
		var window=UI.windows[&"guild_rank"]
		assert(window._big_icon.texture==GuildRankWindow.rank_icon(String(BountyBoard.RANKS[idx][0])))
		assert(window._cards_row.get_child_count()==7)
		checks+=2
		for i in range(7):
			var icon=window._cards_row.get_child(i).get_child(0).get_child(0)
			assert(icon.texture==GuildRankWindow.rank_icon(String(BountyBoard.RANKS[i][0])))
			assert(is_equal_approx(icon.modulate.a,1.0 if i<=idx else .75))
			checks+=2
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/guild_rank_art/rank_%d.png"%idx)
		UI.close_all()
	print("GUILD_RANK_ART_PASS checks=",checks)
	get_tree().quit()
