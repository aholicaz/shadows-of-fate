extends RefCounted
const Tower = preload("res://scripts/world/chapter8_tower_data.gd")
const MATERIALS = ["c8_root_heart", "c8_storm_bell", "c8_mirror_mask", "c8_name_seal"]

## Separate claim flags allow full bags and older trial saves to recover rewards.
static func claim_earned(notify: bool = true) -> int:
	var received := 0
	var pending := false
	for i in range(Tower.NEW_IDS.size()):
		var floor_number := (i + 1) * 5
		if not PlayerState.has_flag(Tower.clear_flag(floor_number)): continue
		var ids: Array = ["card_" + Tower.NEW_IDS[i]]
		# Preserve the original quest-crafting entitlement; these are not enemy drops.
		if i < MATERIALS.size(): ids.append(MATERIALS[i])
		if floor_number == 20: ids.append("c8_living_register")
		for id in ids:
			var flag := StringName("c8_reward_" + str(floor_number) + "_" + id)
			if PlayerState.has_flag(flag): continue
			if PlayerState.inventory.add_id(StringName(id), 1) == 0:
				PlayerState.set_flag(flag)
				received += 1
			else:
				pending = true
	if received > 0:
		if notify: Events.say("ได้รับของรางวัลผู้คุมอิกดราซิล %d ชิ้น" % received)
		SaveManager.request_autosave()
	if pending and notify: Events.say("กระเป๋าเต็ม — เคลียร์ช่องแล้วกลับจุดพักรากเพื่อรับของที่ค้าง")
	return received
