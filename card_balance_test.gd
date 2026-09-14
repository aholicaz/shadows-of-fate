extends Node
var checks := 0
var failures := 0
func check(ok: bool, title: String) -> void:
	checks += 1
	if ok: print("PASS: ", title)
	else:
		failures += 1
		push_error(title)

func _ready() -> void:
	PlayerState.new_game()
	PlayerState.set_process(false)
	var st := PlayerState.stats
	st.max_hp = 1000
	st.hp = 500
	st.hp_drain_percent = 0.05
	for i in range(3): PlayerState.apply_hp_drain(500)
	check(st.hp == 500, "small hits do not round up to free healing")
	PlayerState.apply_hp_drain(500)
	check(st.hp == 501 and is_zero_approx(st.hp_drain_remainder), "four fractional hits yield one HP")
	st.hp_drain_percent = 0.01
	for i in range(100): PlayerState.apply_hp_drain(100)
	check(st.hp == 502, "0.01 percent survives floating point accumulation")
	st.hp_drain_percent = 0.05
	PlayerState.apply_hp_drain(500)
	PlayerState.heal_hp(1000, false)
	check(is_zero_approx(st.hp_drain_remainder), "full healing discards stored fraction")
	PlayerState.apply_hp_drain(100000)
	st.hp -= 10
	PlayerState.apply_hp_drain(500)
	check(st.hp == 990, "full HP attacks cannot bank future healing")
	PlayerState.apply_hp_drain(-100)
	check(is_equal_approx(st.hp_drain_remainder, 0.25), "negative damage cannot consume fraction")
	PlayerState.take_damage(10000)
	check(is_zero_approx(st.hp_drain_remainder), "death clears fraction")
	PlayerState.apply_hp_drain(100000)
	check(st.hp == 0, "drain cannot resurrect dead player")
	PlayerState.new_game()
	st = PlayerState.stats
	st.hp_drain_remainder = 0.75
	var save := PlayerState.to_dict()
	PlayerState.from_dict(save)
	check(is_zero_approx(PlayerState.stats.hp_drain_remainder), "in-memory save restore resets fraction without writing saves")
	PlayerState.stats.hp_drain_remainder = 0.5
	PlayerState.stats.from_dict(save.stats)
	check(is_zero_approx(PlayerState.stats.hp_drain_remainder), "reusing a stats object for load also clears fraction")
	check(CardData.percent_text(0.05, true) == "+0.05%", "hundredth-percent tooltip")
	check(CardData.percent_text(0.1) == "0.1%", "tenths tooltip")
	check(CardData.percent_text(10.0) == "10%", "whole percent retains trailing integer zero")
	check(GameData.get_card(&"card_munak").describe().contains("0.05%"), "card description retains small lifesteal")
	check(GameData.get_card(&"card_lunatic").describe().contains("0.3%"), "inherited SP drain appears in card description")
	var sword := ItemInstance.create(&"flame_sword", 1, 0, 3)
	for i in range(3): check(sword.socket_card(&"card_nidhogg_spawn"), "duplicate cards still fit saved slots")
	PlayerState.equipment.equip(Equipment.EquipSlot.WEAPON, sword)
	PlayerState.refresh()
	check(is_equal_approx(PlayerState.stats.hp_drain_percent, 1.2), "three cards add to 1.2 percent exactly once")
	var eqsave := PlayerState.to_dict()
	PlayerState.from_dict(eqsave)
	check(PlayerState.equipment.weapon().cards.size() == 3, "socketed cards survive in-memory save restore")
	check(is_equal_approx(PlayerState.stats.hp_drain_percent, 1.2), "saved cards resolve new resource stats")
	check(sword.sell_value() == GameData.get_item(&"flame_sword").sell_price + 3 * 360, "socketed sale uses lower card prices")
	var boss := MonsterData.new()
	boss.id = &"gullveig_ember"
	var ash := DropEntry.new()
	ash.item_id = &"gullveig_ash"
	ash.chance = 0.0
	boss.drops.append(ash)
	PlayerState.quests.active.append(&"c6_2_fourth_burning")
	check(boss.roll_drops().size() == 1, "quest guarantees missing ash despite failed normal roll")
	ash.chance = 100.0
	check(boss.roll_drops().size() == 1, "quest guarantee does not duplicate successful ash roll")
	PlayerState.inventory.add_id(&"gullveig_ash", 1)
	ash.chance = 0.0
	check(boss.roll_drops().is_empty(), "already owned ash does not get guaranteed again")
	boss.drops.clear()
	check(boss.roll_drops().is_empty(), "reward-disabled summon never creates quest loot")
	PlayerState.new_game()
	boss.drops.append(ash)
	check(boss.roll_drops().is_empty(), "ordinary farming without quest has no guaranteed ash")
	var fast := 0
	var move := 0
	for card in GameData.cards.values():
		if card.percent_effects.get("aspd_percent", 0.0) > 0: fast += 1
		if card.percent_effects.get("move_speed_percent", 0.0) > 0: move += 1
		check(card.sell_price >= 80 and card.sell_price <= 800, "card price bounded: " + String(card.id))
	check(fast == 8 and move == 5, "ASPD and movement farming choices distributed")
	print("CARD BALANCE: %d checks; failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)
