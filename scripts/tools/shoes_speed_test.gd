extends Node
func _ready() -> void:
	SaveManager.end_session()
	var count := 0
	for data in GameData.items.values():
		if data.slot != ItemData.Slot.SHOES: continue
		assert(data.move_speed_percent >= 5 and data.move_speed_percent <= 25)
		var equipment := Equipment.new()
		equipment.slots[Equipment.EquipSlot.SHOES] = ItemInstance.create(data.id)
		var stats := PlayerStats.new()
		stats.percent_bonus = equipment.collect_percent_bonus()
		stats.recalculate()
		assert(is_equal_approx(stats.move_speed, PlayerStats.BASE_MOVE_SPEED * (1 + data.move_speed_percent / 100)))
		count += 1
	assert(count == 10)
	print("SHOES_SPEED_PASS: 10 shoes, actual equipment movement bonus 5-25 percent")
	get_tree().quit()
