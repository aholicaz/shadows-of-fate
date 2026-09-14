extends RefCounted
## Paid attempts keep the main weapon intact. Pity belongs to that instance.
const RATES := [40.0, 60.0, 80.0, 100.0]
const STONES := [&"socket_stone_1", &"socket_stone_2", &"socket_stone_3"]
const SHARDS := [&"socket_shard_1", &"socket_shard_2", &"socket_shard_3"]

static func tier(inst: ItemInstance) -> int:
	var lv := inst.data().required_level
	return 0 if lv < 70 else (1 if lv < 90 else 2)

static func reason(inst: ItemInstance) -> String:
	if inst == null or inst.data() == null: return "เลือกอาวุธหลักก่อน"
	if inst.data().slot != ItemData.Slot.WEAPON or inst.data().required_level < 50:
		return "รูที่ 3 ใช้กับอาวุธเลเวล 50 ขึ้นไป"
	if inst.slots != 2: return "อาวุธหลักต้องมี 2 รู (สูงสุด 3 รู)"
	return ""

static func requirements(inst: ItemInstance) -> Dictionary:
	if not reason(inst).is_empty(): return {}
	var index := tier(inst)
	return {"stone": STONES[index], "shard": SHARDS[index],
		"zeny": clampi(30000 + int(round((inst.data().required_level - 50) * 1400.0)), 30000, 100000),
		"rate": RATES[clampi(inst.socket_failures, 0, 3)], "attempt": mini(inst.socket_failures + 1, 4)}

static func donor_ok(main: ItemInstance, donor: ItemInstance) -> bool:
	return donor != null and donor != main and donor.item_id == main.item_id \
		and donor.cards.is_empty() and not donor.socket_locked and donor.slots <= 2 \
		and donor.socket_failures == 0 and donor.count == 1

static func check(main: ItemInstance, donors: Array, inv: Inventory, wallet: Object) -> String:
	var why := reason(main)
	if not why.is_empty(): return why
	if not inv.slots.has(main) and not PlayerState.equipment.slots.values().has(main):
		return "อาวุธหลักไม่ได้อยู่กับตัวแล้ว กรุณาเลือกใหม่"
	if donors.size() != 2 or donors[0] == donors[1]: return "เลือกอาวุธชื่อเดียวกันอีก 2 เล่มเป็นวัตถุดิบ"
	for donor in donors:
		if not donor is ItemInstance or not inv.slots.has(donor) or not donor_ok(main, donor):
			return "วัตถุดิบเปลี่ยนไป หรือมีการ์ด/ล็อกไว้/มีความคืบหน้าการเจาะ"
		if PlayerState.equipment.slots.values().has(donor): return "ห้ามใช้อาวุธที่สวมอยู่เป็นวัตถุดิบ"
	var req := requirements(main)
	if wallet.zeny < req.zeny: return "ซีนีไม่พอ"
	if inv.count_of(req.stone) < 1: return "ยังไม่มี " + GameData.item_name(req.stone)
	return ""

static func attempt(main: ItemInstance, donors: Array, inv: Inventory, wallet: Object, rng: RandomNumberGenerator = null) -> Dictionary:
	var error := check(main, donors, inv, wallet)
	if not error.is_empty(): return {"ok": false, "success": false, "message": error}
	var req := requirements(main)
	# Capture references/indices before any inventory signals refresh the UI.
	var indices: Array[int] = [inv.slots.find(donors[0]), inv.slots.find(donors[1])]
	var success := (rng.randf() if rng != null else randf()) * 100.0 < float(req.rate)
	for index in indices: inv.take_from_slot(index, 1)
	inv.remove_id(req.stone, 1)
	wallet.add_zeny(-int(req.zeny))
	if success:
		main.slots = 3
		main.socket_failures = 0
	else:
		main.socket_failures = mini(main.socket_failures + 1, 3)
	Events.inventory_changed.emit()
	Events.equipment_changed.emit()
	Events.socket_result.emit(success, main.display_name(), main.slots)
	return {"ok": true, "success": success, "message": "สำเร็จ! อาวุธหลักมี 3 รูแล้ว" if success else "ยังไม่สำเร็จ — อาวุธหลักอยู่ครบ ครั้งต่อไป %d%%" % RATES[main.socket_failures]}

static func combine(index: int, inv: Inventory) -> String:
	if index < 0 or index >= STONES.size(): return "ชนิดหินไม่ถูกต้อง"
	if inv.count_of(SHARDS[index]) < 10: return "ต้องใช้เศษหินชนิดเดียวกัน 10 ชิ้น"
	var can_fit := inv.can_add(ItemInstance.create(STONES[index]))
	var remaining := 10
	for item in inv.slots:
		if item == null or item.item_id != SHARDS[index]: continue
		if item.count <= remaining: can_fit = true
		remaining -= mini(remaining, item.count)
		if remaining == 0: break
	if not can_fit: return "กระเป๋าเต็ม กรุณาเว้น 1 ช่อง"
	inv.remove_id(SHARDS[index], 10)
	inv.add(ItemInstance.create(STONES[index]))
	return "รวมสำเร็จ: " + GameData.item_name(STONES[index])
