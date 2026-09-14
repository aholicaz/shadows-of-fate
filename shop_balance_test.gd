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
	var review: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/shop_balance_expected.json"))
	for row in review.prices:
		var d := GameData.get_item(StringName(row.id))
		check(d != null and d.buy_price == int(row.new), "runtime price: " + row.id)
		check(d.buy_price > d.sell_price and d.buy_price >= int(row.old), "no resale profit or accidental price reduction: " + row.id)
	var pattern := RegEx.new()
	pattern.compile("(?m)^shop_items = (.+)$")
	var item_pattern := RegEx.new()
	item_pattern.compile("&\"([^\"]+)\"")
	var scenes := {}
	for shop in review.shops: scenes[shop.scene] = true
	var shops_seen := 0
	for scene in scenes:
		var text := FileAccess.get_file_as_string("res://" + String(scene).replace("\\", "/"))
		for found in pattern.search_all(text):
			shops_seen += 1
			for item_match in item_pattern.search_all(found.get_string(1)):
				var id := item_match.get_string(1)
				check(id not in review.removed and GameData.get_item(StringName(id)) != null, "live shop entry valid: " + id)
	check(shops_seen == 7, "all seven explicit shops inspected")
	var ghost := GameData.get_monster(&"mist_ghost")
	var found_saber := 0
	for entry in ghost.drops:
		if entry.item_id == &"mist_saber":
			found_saber += 1
			check(is_equal_approx(entry.chance, 3.0), "Mist Saber real drop chance is three percent")
	check(found_saber == 1, "Mist Saber remains obtainable exactly once in matching monster table")
	PlayerState.inventory = Inventory.new(2)
	PlayerState.zeny = 10000
	var price := GameData.get_item(&"wooden_sword").buy_price
	check(PlayerState.buy(&"wooden_sword"), "buy basic equipment")
	check(PlayerState.zeny == 10000 - price, "buy charges updated price")
	var bought := PlayerState.inventory.get_slot(0)
	check(bought != null and bought.slots == 0 and bought.bonus_percent == 0.0, "shop gear cannot replace dropped socket/roll bonuses")
	var sale := bought.sell_value()
	PlayerState.sell_slot(0, 1)
	check(PlayerState.zeny == 10000 - price + sale and PlayerState.zeny < 10000, "buy-sell cycle removes currency")
	PlayerState.inventory = Inventory.new(1)
	var potion := GameData.get_item(&"red_potion")
	PlayerState.inventory.add_id(&"red_potion", potion.max_stack - 1)
	PlayerState.zeny = 10000
	check(PlayerState.buy(&"red_potion", 10), "partial stack purchase succeeds")
	check(PlayerState.zeny == 10000 - potion.buy_price, "full bag charges only the one potion delivered")
	PlayerState.zeny = 0
	check(not PlayerState.buy(&"red_potion"), "insufficient money cannot buy")
	print("SHOP BALANCE: %d checks; failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)
