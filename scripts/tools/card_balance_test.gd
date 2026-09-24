extends Node
func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	var eq := Equipment.new()
	var a := ItemInstance.create(&"ring",1)
	var b := ItemInstance.create(&"ring",1)
	a.cards.append(&"card_oath_warden")
	b.cards.append(&"card_oath_warden")
	eq.slots[Equipment.EquipSlot.ACCESSORY_1] = a
	eq.slots[Equipment.EquipSlot.ACCESSORY_2] = b
	var single_flat := eq.collect_bonus()
	var single_pct := eq.collect_percent_bonus()
	b.cards.clear()
	assert(eq.collect_bonus()==single_flat, "Boss flat bonus not duplicated")
	assert(eq.collect_percent_bonus()==single_pct, "Boss percent bonus not duplicated")
	a.cards.clear()
	a.cards.append(&"card_silent_wraith")
	for i in 20: b.cards.append(&"card_light_eater_bloom")
	assert(is_equal_approx(float(eq.collect_percent_bonus()[&"sp_drain_percent"]),0.15))
	for i in 20: a.cards.append(&"card_silent_wraith")
	assert(is_equal_approx(float(eq.collect_percent_bonus()[&"hp_drain_percent"]),0.3))
	PlayerState.stats.max_hp = 10000
	PlayerState.stats.hp = 1000
	PlayerState.stats.max_sp = 1000
	PlayerState.stats.sp = 0
	PlayerState.stats.hp_drain_percent = 1.0
	PlayerState.stats.sp_drain_percent = 1.0
	PlayerState._reset_drains()
	for i in 20:
		PlayerState.apply_hp_drain(100000)
		PlayerState.apply_sp_drain(100000)
	assert(PlayerState.stats.hp == 1200, "AOE HP cap includes all targets")
	assert(PlayerState.stats.sp == 5, "AOE SP cap includes all targets")
	PlayerState._drain_clock += 1.01
	PlayerState.apply_sp_drain(100000)
	assert(PlayerState.stats.sp == 10, "Budget recovers after a second")
	PlayerState._reset_drains()
	PlayerState.stats.sp_drain_percent = 0.05
	for i in 10: PlayerState.apply_sp_drain(200)
	assert(PlayerState.stats.sp == 11, "Fractional SP accumulates")
	PlayerState.inventory = Inventory.new(1)
	PlayerState.inventory.slots[0] = ItemInstance.create(&"red_potion",99)
	var weapon := ItemInstance.create(&"wooden_sword",1)
	# Find a real weapon template without relying on a fixture ID.
	for id in GameData.items:
		var item: ItemData = GameData.items[id]
		if item.slot == ItemData.Slot.WEAPON:
			weapon = ItemInstance.create(item.id,1)
			break
	weapon.cards.append(&"card_reflection")
	PlayerState.equipment.slots[Equipment.EquipSlot.WEAPON] = weapon
	assert(PlayerState._return_moved_cards()==1)
	assert(weapon.cards.is_empty() and PlayerState.inventory.used_slots()==2)
	assert(PlayerState._return_moved_cards()==0, "Migration is idempotent")
	var restored := Inventory.new(1)
	restored.from_array(PlayerState.inventory.to_array())
	assert(restored.used_slots()==2, "Overflow survives save roundtrip")
	var old_slots := weapon.slots
	var saved := PlayerState.to_dict()
	PlayerState.from_dict(saved)
	assert(PlayerState.equipment.get_item(Equipment.EquipSlot.WEAPON).slots==old_slots, "No free sockets on load")
	assert(PlayerState._return_moved_cards()==0, "No duplicate returns on reload")
	for id in GameData.cards:
		var card: CardData = GameData.cards[id]
		assert(card.hp_drain_percent+float(card.percent_effects.get("hp_drain_percent",0))<=0.30001)
		assert(card.sp_drain_percent+float(card.percent_effects.get("sp_drain_percent",0))<=0.15001)
	print("CARD_BALANCE_PASS: boss uniqueness, drain stacking/caps/fractions, full bag migration, all card limits")
	get_tree().quit()
