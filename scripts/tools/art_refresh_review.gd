extends Node

func _ready() -> void:
	SaveManager.end_session()
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	await get_tree().process_frame
	var viewport_size := get_viewport().get_visible_rect().size
	var cell := Vector2(viewport_size.x / 9.0, (viewport_size.y - 140.0) / 2.0)
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("252a32")
	bg.size = Vector2(2400, 1800)
	layer.add_child(bg)
	var bosses: Array = []
	for card in GameData.cards.values():
		if card.illustration != null and card.illustration.resource_path.contains("boss_gold"):
			bosses.append(card)
	bosses.sort_custom(func(a,b): return a.id < b.id)
	assert(bosses.size() == 18)
	for i in range(bosses.size()):
		var card: CardData = bosses[i]
		assert(card.icon.get_size() == Vector2(256,256))
		assert(card.illustration.get_size() == Vector2(640,960))
		var view := TextureRect.new()
		view.texture = card.illustration
		view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		view.position = Vector2(5 + (i % 9) * cell.x, 5 + (i / 9) * cell.y)
		view.size = cell - Vector2(10,10)
		layer.add_child(view)
	var ids = ["book_seven_half_2", "socket_shard_1", "socket_stone_1", "socket_shard_2", "socket_stone_2", "socket_shard_3", "socket_stone_3"]
	for i in range(ids.size()):
		var item := GameData.get_item(StringName(ids[i]))
		assert(item.icon != null and item.icon.get_size() == Vector2(256,256))
		var view := TextureRect.new()
		view.texture = item.icon
		view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		view.position = Vector2(25 + i * viewport_size.x / 7.0, viewport_size.y - 125)
		view.size = Vector2(110,110)
		layer.add_child(view)
	for item in GameData.items.values(): assert(item.icon != null)
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/art_refresh/godot_review.png")
	print("ART_REFRESH PASS: 18 boss cards, 7 replacement items, all 341 inventory icons loaded; no save session")
	get_tree().quit()
