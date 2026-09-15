extends Node
var records := []
func textures(node: Node, out: Array) -> void:
	if node is Sprite2D and node.texture != null: out.append(node.texture.resource_path)
	if node is AnimatedSprite2D and node.sprite_frames != null:
		for animation in node.sprite_frames.get_animation_names():
			if node.sprite_frames.get_frame_count(animation) > 0:
				var texture = node.sprite_frames.get_frame_texture(animation, 0)
				if texture is AtlasTexture: texture = texture.atlas
				if texture != null and not out.has(texture.resource_path): out.append(texture.resource_path)
	for child in node.get_children(): textures(child, out)
func scan(node: Node, map_id: String) -> void:
	if node is NPC:
		var art := []
		textures(node, art)
		records.append({"map":map_id,"name":node.npc_name,"node":String(node.name),"art":art,"portrait":node.portrait.resource_path if node.portrait != null else node.portrait_file})
	for child in node.get_children(): scan(child, map_id)
func _ready() -> void:
	SaveManager.end_session()
	var items := []
	for d in GameData.items.values():
		items.append({"id":String(d.id),"name":d.display_name,"type":d.type,"icon":d.icon.resource_path if d.icon != null else ""})
	for id in Game.MAPS:
		var scene = load(Game.MAPS[id])
		if not scene is PackedScene: continue
		var map = scene.instantiate()
		scan(map, String(id))
		map.free()
		scene = null
		GameData.monsters.clear()
		print("ART_SCAN ", id)
	var f := FileAccess.open("res://output/art_asset_audit.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"items":items,"npcs":records},"  "))
	f.close()
	print("ART_AUDIT_COMPLETE")
	get_tree().quit()
