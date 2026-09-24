@tool
extends RefCounted
const FIELDS := ["id", "display_name", "level", "is_boss", "zeny_min", "zeny_max", "item_id", "chance", "min_count", "max_count", "drops"]
static func collect() -> Dictionary:
	var rows := {}
	for filename in DirAccess.get_files_at("res://data/monsters"):
		if not filename.ends_with(".tres"): continue
		var lines: PackedStringArray = []
		for line in FileAccess.get_file_as_string("res://data/monsters/" + filename).split("\n"):
			line = line.strip_edges()
			if line == "[resource]" or line.begins_with('[sub_resource type="Resource"') or line.get_slice(" = ", 0) in FIELDS:
				lines.append(line)
		rows[filename.get_basename()] = "\n".join(lines)
	return rows
