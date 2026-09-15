extends Node
func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	var checked := 0
	for d in GameData.items.values():
		if not d.refinable or not d.is_equipment(): continue
		assert(not d.refine_bonuses(10).is_empty())
		var inst := ItemInstance.create(d.id)
		var a := inst.total_atk()
		var b := inst.total_def()
		var preview := RefineSystem.preview(inst)
		inst.refine = 1
		assert(inst.total_atk() - a == preview.atk_gain)
		assert(inst.total_def() - b == preview.def_gain)
		checked += 1
	for d in GameData.items.values():
		if not d.refinable or not d.is_equipment(): continue
		for rank in range(10):
			var inst := ItemInstance.create(d.id, 1, rank)
			var preview := RefineSystem.preview(inst)
			var atk := inst.total_atk()
			var defense := inst.total_def()
			inst.refine += 1
			assert(inst.total_atk() - atk == preview.atk_gain)
			assert(inst.total_def() - defense == preview.def_gain)
			for key in d.refine_bonuses(rank):
				assert(d.refine_bonuses(rank + 1).get(key, 0) >= d.refine_bonuses(rank)[key])
	var boots := ItemInstance.create(&"boots", 1, 1)
	assert(is_equal_approx(float(boots.data().refine_bonuses(1)[&"flee"]), 0.5))
	var stats := PlayerStats.new()
	stats.recalculate()
	var initial := stats.flee
	stats.flat_bonus[&"flee"] = 0.5
	stats.recalculate()
	assert(is_equal_approx(stats.flee - initial, 0.5 * stats.job().flee_mod))
	assert(is_equal_approx(Combat.hit_rate(150, 150.5), Combat.hit_rate(150, 150.0) - 0.5))
	var monster := MonsterData.new()
	var drop := DropEntry.new()
	drop.item_id = &"phracon"
	drop.chance = 100
	drop.min_count = 5
	drop.max_count = 10
	monster.drops.append(drop)
	monster.drops.append(drop)
	for i in range(50):
		var loot := monster.roll_drops()
		assert(loot.size() == 1 and loot[0].count == 1)
	print("REFINE_BALANCE_PASS: %d equipment previews and gains, accessory level floors, duplicate ore cap" % checked)
	get_tree().quit()
