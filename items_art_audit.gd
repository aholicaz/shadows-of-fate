extends Node

var failures := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var rows = JSON.parse_string(FileAccess.get_file_as_string("res://output/items_chapter23/manifest.json"))
	var root := get_tree().root
	root.content_scale_size = Vector2i(1320, 1000)
	var layer := CanvasLayer.new()
	layer.layer = 120
	root.add_child(layer)
	root.size = Vector2i(1320, 1000)
	var bg := ColorRect.new()
	bg.color = Color("28313d")
	bg.size = Vector2(1320, 1000)
	layer.add_child(bg)
	var index := 0
	for row in rows:
		var id: String = row.id
		var path := "res://Sprites/items/placeholder/%s.png" % id
		var texture = load(path) as Texture2D
		if texture == null:
			failures += 1
			continue
		if id.begins_with("card_"):
			var card = load("res://data/cards/%s.tres" % id) as CardData
			if card == null or CardView.card_texture(card).resource_path != path:
				failures += 1
		var rect := TextureRect.new()
		rect.texture = texture
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		rect.position = Vector2((index % 11) * 120 + 12, (index / 11) * 195 + 10)
		rect.size = Vector2(96, 144) if id.begins_with("card_") else Vector2(64,64)
		layer.add_child(rect)
		var label := Label.new()
		label.text = id.replace("card_", "").replace("_", "\n")
		label.add_theme_font_size_override("font_size", 12)
		label.position = Vector2((index % 11) * 120 + 5, (index / 11) * 195 + 153)
		layer.add_child(label)
		index += 1
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/items_chapter23/godot_preview.png")
	print("ITEM_ART_AUDIT: ", index, " loaded, 17 card paths checked, failures=", failures)
	get_tree().quit(failures)

