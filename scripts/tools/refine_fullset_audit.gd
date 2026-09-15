extends Node
func _ready() -> void:
	SaveManager.end_session()
	var results := []
	for level in [15, 50, 90]:
		var equipment := Equipment.new()
		for slot in range(8):
			var best: ItemData
			for d in GameData.items.values():
				if not d.is_equipment() or d.required_level > level: continue
				if Equipment.slot_for(d, slot == 7) != slot: continue
				if best == null or (d.atk if slot == 0 else d.def) > (best.atk if slot == 0 else best.def): best = d
			if best != null: equipment.slots[slot] = ItemInstance.create(best.id)
		for rank in [0,10]:
			var names := []
			for item in equipment.slots.values():
				if item != null:
					item.refine = rank if item.data().refinable else 0
					names.append(item.item_id)
			var stats := PlayerStats.new()
			stats.level = level
			stats.job_id = &"swordsman" if level == 15 else &"runeblade"
			stats.job_level = mini(level, 50)
			stats.base_vit = int(level / 3.0)
			stats.base_str = level
			stats.flat_bonus = equipment.collect_bonus()
			stats.percent_bonus = equipment.collect_percent_bonus()
			stats.weapon_atk = equipment.weapon_atk()
			stats.recalculate()
			results.append({"level":level,"rank":rank,"def":stats.def,"hp":stats.max_hp,"atk":stats.atk,"regen":stats.hp_regen,"items":names})
	var file := FileAccess.open("res://output/refine_fullset_audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"  "))
	file.close()
	print("FULLSET_AUDIT_PASS")
	get_tree().quit()
