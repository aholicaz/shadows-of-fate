## Inventory — ช่องเก็บของ
class_name Inventory
extends RefCounted

var size: int = 40
var slots: Array = []   # ItemInstance หรือ null
## ★ รอบ 155 ★ ไอเทมเควส (type QUEST) แยกเก็บ ไม่กินช่องกระเป๋า — เปิดเฉพาะกระเป๋าผู้เล่น (คลังไม่ใช้)
var separate_quest := false
var quest_items: Array = []   # ItemInstance (กองรวมตาม id)


func _init(p_size: int = 40) -> void:
	size = p_size
	slots.resize(size)


## ★ รอบ 50 — เปลี่ยนจำนวนช่อง (STR ทุก 5 แต้มได้ +1 ช่อง) ★
## ★★ ห้ามทำของหาย ★★ ตอนย่อ: ย้ายของที่อยู่เกินช่องใหม่ลงมาช่องว่างข้างล่างก่อน
## ถ้าข้างล่างเต็ม จะย่อได้แค่ถึงช่องสุดท้ายที่ยังมีของ (ค้างไว้จนผู้เล่นใช้/ทิ้งของออก)
func set_size(new_size: int) -> void:
	new_size = maxi(1, new_size)
	if new_size == size:
		return
	if new_size > size:
		size = new_size
		slots.resize(size)
	else:
		for i in range(new_size, size):
			if slots[i] == null:
				continue
			var dest := -1
			for j in range(new_size):
				if slots[j] == null:
					dest = j
					break
			if dest < 0:
				break
			slots[dest] = slots[i]
			slots[i] = null
		var last := 0
		for i in range(size):
			if slots[i] != null:
				last = i + 1
		size = maxi(new_size, last)
		slots.resize(size)
	Events.inventory_changed.emit()


func used_slots() -> int:
	var n := 0
	for s in slots:
		if s != null:
			n += 1
	return n


func is_full() -> bool:
	return used_slots() >= size


func first_empty() -> int:
	for i in range(size):
		if slots[i] == null:
			return i
	return -1


## ★ รอบ 98 ★ ใส่ของชิ้นนี้ได้อย่างน้อย 1 ชิ้นไหม (ไม่แตะกระเป๋า) — ของดรอปใช้เช็คก่อนลอยเข้าตัว
func can_add(inst: ItemInstance) -> bool:
	if inst == null or inst.count <= 0:
		return false
	var data := inst.data()
	if data == null:
		return false
	if _is_quest_data(data):
		return true
	if data.is_stackable():
		for i in range(size):
			var s: ItemInstance = slots[i]
			if s != null and s.same_kind_as(inst) and s.count < data.max_stack:
				return true
	return first_empty() >= 0


## Pure capacity check, including slots freed by quest consumption. Emits no signals.
func can_add_all(inst: ItemInstance, removals: Dictionary = {}) -> bool:
	if inst == null or inst.count <= 0: return true
	var data := inst.data()
	if data == null: return false
	if _is_quest_data(data): return true   # ★ รอบ 155 ★
	var remaining := inst.count
	var consume := removals.duplicate()
	for slot: ItemInstance in slots:
		var count := 0 if slot == null else slot.count
		if slot != null:
			var take := mini(count, int(consume.get(slot.item_id, 0)))
			count -= take
			consume[slot.item_id] = int(consume.get(slot.item_id, 0)) - take
		if count == 0:
			remaining -= data.max_stack if data.is_stackable() else 1
		elif data.is_stackable() and slot.same_kind_as(inst):
			remaining -= maxi(0, data.max_stack - count)
		if remaining <= 0: return true
	return false


## ใส่ของเข้ากระเป๋า คืนค่าจำนวนที่ใส่ไม่ได้ (0 = ใส่ได้หมด)
func add(inst: ItemInstance) -> int:
	if inst == null or inst.count <= 0:
		return 0
	var data := inst.data()
	if data == null:
		push_warning("[Inventory] ไม่รู้จักไอเทม: " + String(inst.item_id))
		return inst.count

	# ★ รอบ 155 ★ ไอเทมเควสไปหน้าแยก ไม่กินช่อง
	if _is_quest_data(data):
		_add_quest(inst)
		Events.inventory_changed.emit()
		Events.item_gained.emit(inst.item_id, inst.count)
		return 0

	var remaining := inst.count

	# กองรวมกับของเดิมก่อน
	if data.is_stackable():
		for i in range(size):
			var s: ItemInstance = slots[i]
			if s != null and s.same_kind_as(inst):
				var can_add: int = mini(remaining, data.max_stack - s.count)
				if can_add > 0:
					s.count += can_add
					remaining -= can_add
				if remaining <= 0:
					Events.inventory_changed.emit()
					Events.item_gained.emit(inst.item_id, inst.count)
					return 0

	# ใส่ช่องว่าง
	while remaining > 0:
		var idx := first_empty()
		if idx == -1:
			break
		if data.is_stackable():
			var put: int = mini(remaining, data.max_stack)
			slots[idx] = ItemInstance.create(inst.item_id, put, inst.refine)
			remaining -= put
		else:
			# ★ ของสวมใส่ต้องเก็บ "ชิ้นเดิม" ★
			# ไม่งั้นช่องการ์ด / การ์ดที่ใส่ไว้ / ค่าตีบวก จะหายตอนเก็บเข้ากระเป๋า
			if remaining == inst.count:
				inst.count = 1
				slots[idx] = inst
			else:
				var copy := ItemInstance.create(inst.item_id, 1, inst.refine, inst.slots)
				copy.cards = inst.cards.duplicate()
				slots[idx] = copy
			remaining -= 1

	Events.inventory_changed.emit()
	if remaining < inst.count:
		Events.item_gained.emit(inst.item_id, inst.count - remaining)
	return remaining


func add_id(item_id: StringName, count: int = 1, refine: int = 0) -> int:
	return add(ItemInstance.create(item_id, count, refine))


func count_of(item_id: StringName) -> int:
	var total := 0
	for q: ItemInstance in quest_items:   # ★ รอบ 155 ★
		if q.item_id == item_id:
			total += q.count
	for s: ItemInstance in slots:
		if s != null and s.item_id == item_id:
			total += s.count
	return total


func has(item_id: StringName, count: int = 1) -> bool:
	return count_of(item_id) >= count


## เอาของออกตาม id คืน true ถ้าเอาออกครบ
func remove_id(item_id: StringName, count: int = 1) -> bool:
	if not has(item_id, count):
		return false
	var remaining := count
	for q: ItemInstance in quest_items.duplicate():   # ★ รอบ 155 ★ หักจากไอเทมเควสก่อน
		if q.item_id != item_id or remaining <= 0:
			continue
		var qt: int = mini(remaining, q.count)
		q.count -= qt
		remaining -= qt
		if q.count <= 0:
			quest_items.erase(q)
	for i in range(size):
		if remaining <= 0:
			break
		var s: ItemInstance = slots[i]
		if s == null or s.item_id != item_id:
			continue
		var take: int = mini(remaining, s.count)
		s.count -= take
		remaining -= take
		if s.count <= 0:
			slots[i] = null
		if remaining <= 0:
			break
	Events.inventory_changed.emit()
	return true


## เอาของออกจากช่องที่ระบุ คืน ItemInstance ที่เอาออกมา
func take_from_slot(index: int, count: int = 1) -> ItemInstance:
	if index < 0 or index >= size:
		return null
	var s: ItemInstance = slots[index]
	if s == null:
		return null
	var take: int = mini(count, s.count)
	var out := ItemInstance.create(s.item_id, take, s.refine)
	s.count -= take
	if s.count <= 0:
		slots[index] = null
	Events.inventory_changed.emit()
	return out


func get_slot(index: int) -> ItemInstance:
	if index < 0 or index >= size:
		return null
	return slots[index]


func set_slot(index: int, inst: ItemInstance) -> void:
	if index < 0 or index >= size:
		return
	slots[index] = inst
	Events.inventory_changed.emit()


func swap(a: int, b: int) -> void:
	if a < 0 or b < 0 or a >= size or b >= size:
		return
	var tmp = slots[a]
	slots[a] = slots[b]
	slots[b] = tmp
	Events.inventory_changed.emit()


## เรียงของ: ประเภทเดียวกันอยู่ด้วยกัน ช่องว่างไปท้ายสุด
func sort_items() -> void:
	var list: Array = []
	for s in slots:
		if s != null:
			list.append(s)
	list.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool:
		var da := a.data()
		var db := b.data()
		if da == null or db == null:
			return false
		if da.type != db.type:
			return da.type < db.type
		if a.item_id != b.item_id:
			return String(a.item_id) < String(b.item_id)
		return a.refine > b.refine
	)
	slots.clear()
	slots.resize(size)
	for i in range(mini(list.size(), size)):
		slots[i] = list[i]
	Events.inventory_changed.emit()


func to_array() -> Array:
	var out: Array = []
	for s: ItemInstance in slots:
		out.append(s.to_dict() if s != null else null)
	return out


func from_array(arr: Array) -> void:
	slots.clear()
	# ★ รอบ 50 ★ เซฟเก่าอาจมีช่องมากกว่าตอนนี้ (STR สูง) — ขยายรับให้หมดก่อน ของจะได้ไม่หาย
	# (PlayerState.refresh() จะย่อกลับให้พอดีเองทีหลัง)
	size = maxi(size, arr.size())
	slots.resize(size)
	for i in range(mini(arr.size(), size)):
		var d = arr[i]
		if d is Dictionary:
			slots[i] = ItemInstance.from_dict(d)
	Events.inventory_changed.emit()


# =========================================================
# ★★ รอบ 155 ★★ ไอเทมเควส — ไม่นับช่อง · ไม่โชว์ในหน้า «ทั้งหมด» · มีแท็บของตัวเอง
# =========================================================
func _is_quest_data(data: ItemData) -> bool:
	return separate_quest and data != null and data.type == ItemData.Type.QUEST


func _add_quest(inst: ItemInstance) -> void:
	for q: ItemInstance in quest_items:
		if q.item_id == inst.item_id:
			q.count += inst.count
			return
	quest_items.append(ItemInstance.create(inst.item_id, inst.count, inst.refine))


## เปิดโหมดแยกไอเทมเควส + ย้ายของเควสที่ค้างในช่องเดิม (เซฟเก่า) ออกมา
func enable_quest_pocket() -> void:
	separate_quest = true
	var moved := false
	for i in range(size):
		var s: ItemInstance = slots[i]
		if s != null and _is_quest_data(s.data()):
			_add_quest(s)
			slots[i] = null
			moved = true
	if moved:
		Events.inventory_changed.emit()


func quest_to_array() -> Array:
	var out: Array = []
	for q: ItemInstance in quest_items:
		out.append(q.to_dict())
	return out


func quest_from_array(arr: Array) -> void:
	quest_items.clear()
	for d in arr:
		if d is Dictionary:
			var inst := ItemInstance.from_dict(d)
			if inst != null and inst.data() != null:
				_add_quest(inst)
