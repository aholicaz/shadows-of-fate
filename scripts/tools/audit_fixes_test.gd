extends Node
func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	var q := GameData.get_quest(&"hans_poring")
	PlayerState.quests.accept(q.id)
	for i in q.kill_count: PlayerState.quests.on_monster_killed(q.kill_monster_id)
	PlayerState.inventory = Inventory.new(1)
	var limit := GameData.get_item(q.reward_item_id).max_stack
	PlayerState.inventory.slots[0] = ItemInstance.create(q.reward_item_id, limit - 1)
	for attempt in range(2):
		assert(not PlayerState.turn_in_quest(q.id))
		assert(PlayerState.inventory.count_of(q.reward_item_id) == limit - 1)
		assert(PlayerState.quests.is_ready(q.id))
	PlayerState.inventory.remove_id(q.reward_item_id, 3)
	assert(PlayerState.turn_in_quest(q.id))
	assert(PlayerState.inventory.count_of(q.reward_item_id) == limit - 1)
	assert(not PlayerState.turn_in_quest(q.id))
	# Consumed quest items may free the only slot for the reward.
	var collect := QuestData.new()
	collect.id = &"audit_collect"
	collect.reward_item_id = &"blue_potion"
	collect.reward_item_count = 2
	var objective := ObjectiveData.new()
	objective.kind = ObjectiveData.Kind.COLLECT
	objective.target = &"red_potion"
	objective.count = 3
	collect.objectives.append(objective)
	GameData.quests[collect.id] = collect
	PlayerState.inventory = Inventory.new(1)
	PlayerState.inventory.slots[0] = ItemInstance.create(&"red_potion", 3)
	PlayerState.quests.accept(collect.id)
	assert(PlayerState.turn_in_quest(collect.id))
	assert(PlayerState.inventory.count_of(&"red_potion") == 0)
	assert(PlayerState.inventory.count_of(&"blue_potion") == 2)
	# Pure probes never mutate inventory or emit fake item rewards.
	var snapshot := PlayerState.inventory.to_array()
	assert(not PlayerState.inventory.can_add_all(ItemInstance.create(&"wooden_sword")))
	assert(PlayerState.inventory.to_array() == snapshot)
	var before := GameData.monsters.size()
	var map_page := preload("res://scripts/ui/world_map_page.gd").new()
	for mid in GameData.monster_ids():
		var block := map_page._monster_block(mid)
		block.free()
	map_page.free()
	assert(GameData.monsters.size() == before)
	UI.windows[&"gm"]._fill_monsters()
	assert(GameData.monsters.size() == before)
	var generated := preload("res://addons/export_metadata/builder.gd").collect()
	assert(generated.size() == GameData.monster_ids().size())
	for mid in generated:
		var info := GameData.parse_monster_info(generated[mid])
		assert(info.id == StringName(mid))
		assert(info.display_name == GameData.get_monster_info(StringName(mid)).display_name)
	var stats := PlayerStats.new()
	stats.change_profession(&"ninth_edge")
	stats.add_job_exp(GameData.get_quest(&"c7_4_ninth_edge").reward_job_exp)
	assert(stats.job_level == 4)
	var tower := preload("res://scripts/world/chapter8_tower_data.gd")
	for floor_number in range(1, 21):
		assert(tower.clear_exp(floor_number) <= PlayerStats.exp_needed_at(110 + floor_number) * 0.20)
	print("AUDIT_FIXES_PASS: atomic quest rewards, consumed slots, pure capacity checks, map and GM metadata only, export catalog, Job4 awakening, tower reward caps")
	get_tree().quit()
