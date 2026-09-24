extends Node
func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	var before := GameData.monsters.size()
	var started := Time.get_ticks_usec()
	for id in GameData.monster_ids():
		var info := GameData.get_monster_info(id)
		assert(info != null and info.id == id)
		assert(info.sprite_frames == null)
		var packed := GameData.parse_monster_info(GameData.QUEST_CATALOG.SOURCE[String(id)])
		for field in ["id", "display_name", "level", "is_boss", "zeny_min", "zeny_max"]:
			assert(info.get(field) == packed.get(field))
		assert(info.drops.size() == packed.drops.size())
		for i in range(info.drops.size()):
			assert(info.drops[i].item_id == packed.drops[i].item_id)
			assert(info.drops[i].chance == packed.drops[i].chance)
	for quest in GameData.all_quests():
		quest.target_name()
		for objective in quest.steps(): objective.describe()
	var locations: Array = JSON.parse_string(FileAccess.get_file_as_string("res://output/quest_location_labels.json"))
	assert(locations.size() == 44)
	for row in locations:
		var quest := GameData.get_quest(StringName(row.quest))
		var found := false
		for objective in quest.steps():
			if objective.target == StringName(row.target) and objective.kind == int(row.kind):
				found = true
				assert(objective.describe().contains(row.name))
				assert(not objective.describe().contains(row.target))
		assert(found)
	var visit := ObjectiveData.new()
	visit.kind = ObjectiveData.Kind.VISIT
	visit.target = &"dimming_wood"
	assert(visit.describe().contains(Game.map_display_name(&"dimming_wood")))
	var board := BountyBoard.new()
	for town in [&"prontera_town", &"vanir_town", &"emberhaven"]:
		board.turned_in[town] = BountyBoard.BOSS_UNLOCK_TURNINS
		board.ensure_board(town)
		assert(not board.specs_of(town).is_empty())
		for spec in board.specs_of(town):
			if not spec.is_empty(): assert(not BountyBoard.short_label(spec).is_empty())
	assert(GameData.monsters.size() == before)
	var poring := GameData.get_monster_info(&"poring")
	assert(poring.display_name == "โพริง" and poring.drops.size() == 4)
	assert(poring.drops[0].chance == 6.0 and poring.drops[0].min_count == 1)
	print("QUEST_METADATA_PASS: all metadata/export parity, quest labels, bounty generation; full monster loads=0; elapsed_ms=", (Time.get_ticks_usec()-started)/1000.0)
	get_tree().quit()
