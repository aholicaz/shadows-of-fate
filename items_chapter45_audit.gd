extends Node

var failures := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var rows = JSON.parse_string(FileAccess.get_file_as_string("res://output/items_chapter45/manifest.json"))
	var viewport := get_tree().root
	viewport.content_scale_size = Vector2i(1260, 850)
	viewport.size = Vector2i(1260, 850)
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	var textures: Array[Texture2D] = []
	for row in rows:
		var id: String = row.id
		var path := "res://Sprites/items/placeholder/%s.png" % id
		var category := "cards" if id.begins_with("card_") else "items"
		var item = load("res://data/%s/%s.tres" % [category, id]) as ItemData
		var texture: Texture2D = null
		if item is CardData:
			texture = CardView.card_texture(item)
		elif item != null:
			texture = item.icon
		if texture == null or texture.resource_path != path or texture.get_size() != Vector2(256,256):
			push_error("ASSET_FAIL: " + id)
			failures += 1
		textures.append(texture)
	for page in range(ceili(rows.size() / 45.0)):
		for child in layer.get_children():
			child.queue_free()
		await get_tree().process_frame
		var bg := ColorRect.new()
		bg.color = Color("28313d")
		bg.size = Vector2(1260,850)
		layer.add_child(bg)
		for i in range(page * 45, mini((page+1) * 45, rows.size())):
			var slot := i % 45
			var rect := TextureRect.new()
			rect.texture = textures[i]
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			rect.position = Vector2((slot % 9)*140+8, (slot / 9)*170+4)
			rect.size = Vector2(120,120) if String(rows[i].id).begins_with("card_") else Vector2(64,64)
			layer.add_child(rect)
			var label := Label.new()
			label.text = String(rows[i].id).replace("_", "\n")
			label.add_theme_font_size_override("font_size", 12)
			label.position = Vector2((slot % 9)*140+5,(slot / 9)*170+120)
			layer.add_child(label)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://output/items_chapter45/godot_preview_%d.png" % (page+1))
	print("CHAPTER45_ART_AUDIT: ", rows.size(), " resources checked, failures=", failures)
	get_tree().quit(failures)
