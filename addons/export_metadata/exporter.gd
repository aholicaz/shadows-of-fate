@tool
extends EditorExportPlugin
func _get_name() -> String:
	return "MonsterQuestMetadata"
func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	var rows := preload("res://addons/export_metadata/builder.gd").collect()
	add_file("res://data/monster_quest_export.json", JSON.stringify(rows).to_utf8_buffer(), false)
	print("EXPORT_QUEST_METADATA: ", rows.size(), " current monsters")
