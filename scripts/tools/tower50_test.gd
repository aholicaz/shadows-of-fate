extends Node
const Tower = preload("res://scripts/world/chapter8_tower_data.gd")
const Loot = preload("res://scripts/world/chapter8_loot.gd")
const Pattern = preload("res://scripts/entities/chapter8_pattern.gd")
const Checkpoint = preload("res://scripts/world/chapter8_checkpoint.gd")
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		push_error(message)
		get_tree().quit(1)
		assert(ok, message)

func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	Tower.gm_test = false
	check(Tower.FLOOR_COUNT == 50, "50 floors")
	check(not Tower.can_enter(1), "chapter seven gate")
	PlayerState.set_flag(&"chapter7_done")
	check(Tower.can_enter(1) and not Tower.can_enter(2), "sequential gate")
	var old_hp := 0
	var loot_sources := {}
	for n in range(1,51):
		check(Game.MAPS.has(Tower.floor_id(n)), "registered floor")
		check(ResourceLoader.exists(Game.MAPS[Tower.floor_id(n)]), "scene exists")
		var scene = load(Game.MAPS[Tower.floor_id(n)]).instantiate()
		check(scene.floor_number == n, "correct floor scene")
		scene.free()
		var species := {}
		for w in range(Tower.wave_sizes(n).size()):
			var roster := Tower.wave_roster(n,w)
			check(roster.size() <= 8 and roster.size() >= 6, "bounded waves")
			for id in roster:
				check(ResourceLoader.exists("res://data/monsters/%s.tres" % id), "monster exists: "+id)
				species[id] = true
				loot_sources[id] = false
		check(species.size() >= 4, "varied enemies")
		var bosses := Tower.boss_roster(n)
		check(bosses.size() <= 2, "boss concurrency")
		var old_present := false
		for id in bosses:
			loot_sources[id] = true
			check(ResourceLoader.exists("res://data/monsters/%s.tres" % id), "boss exists")
			if id not in Tower.NEW_IDS: old_present = true
		check(old_present, "campaign boss every floor")
		if n%5 == 0: check(Tower.NEW_IDS[Tower.theme(n)] in bosses, "milestone guardian")
		var source := MonsterData.new()
		source.id = &"poring"
		source.max_hp = 100
		var enemy := Tower.make_enemy(source,n,false)
		check(enemy.max_hp > old_hp, "monotonic regular HP")
		old_hp = enemy.max_hp
		check(source.max_hp == 100 and source.drops.is_empty(), "source immutable")
		check(enemy.exp_reward == 0 and enemy.zeny_min > 0, "money not repeat EXP")
		for entry in enemy.drops: check(Loot.allowed(entry.item_id), "allowed drop")
		PlayerState.set_flag(Tower.clear_flag(n))
		if n<50: check(Tower.can_enter(n+1), "next unlocked")
	check(not Tower.can_enter(51), "no unfinished floor51")
	check(Checkpoint.destinations().size() == 20, "start checkpoints and boss hunts")
	# Inspect every real species table, not just a synthetic poring and new guardians.
	for id in loot_sources:
		var source := GameData.get_monster(StringName(id))
		check(source != null, "load actual tower species")
		var original_drops := source.drops.duplicate()
		for number in [1, 25, 50]:
			var copy := Tower.make_enemy(source, number, loot_sources[id], id in Tower.NEW_IDS)
			for drop in copy.drops:
				check(Loot.allowed(drop.item_id), "allowlist for actual source " + id)
				check(drop.chance > 0.0 and drop.chance <= 100.0, "valid drop chance")
		check(source.drops == original_drops, "campaign loot unchanged")
		GameData.release_monsters_except([])
	for i in range(10):
		var boss := GameData.get_monster(StringName(Tower.NEW_IDS[i]))
		check(boss != null and boss.sprite_frames != null, "guardian art")
		var equipment := GameData.get_item(StringName(Loot.GEAR[i]))
		check(equipment.is_equipment() and equipment.refinable and equipment.card_slots == 2, "farmable refinable gear")
		check(equipment.icon != null and equipment.icon.get_size() == Vector2(256,256), "gear256")
		var card := GameData.get_item(StringName("card_"+Tower.NEW_IDS[i])) as CardData
		check(card != null and card.illustration != null and card.rarity == 5, "gold guardian card")
		var drops := Loot.table(boss,(i+1)*5,true)
		var found := false
		for entry in drops:
			check(Loot.allowed(entry.item_id), "no junk/potions/quest drops")
			if entry.item_id == equipment.id:
				found = true
				check(is_equal_approx(entry.chance,18.0), "equipment drop18")
		check(found, "boss specific equipment")
		for rage in [false,true]:
			for x in [200.0,2100.0,4000.0]:
				var zones := Pattern.layout(i,x,2600,1,rage)
				check(not zones.is_empty(), "signature pattern")
				for zone in zones:
					check(zone.at >= 1.35 and zone.at < 6.2, "readable warning / cast reservation")
		GameData.release_monsters_except([])
	Tower.gm_test = true
	var gm_enemy := Tower.make_enemy(MonsterData.new(),50,true,true)
	check(gm_enemy.drops.is_empty() and gm_enemy.zeny_max == 0, "GM has no loot")
	Tower.gm_test = false
	var rewards = preload("res://scripts/world/chapter8_rewards.gd")
	PlayerState.inventory.set_size(200)
	rewards.claim_earned(false)
	check(rewards.claim_earned(false) == 0, "first clear rewards cannot duplicate")
	check(not PlayerState.has_flag(&"chapter8_done"), "story completion requires final report")
	print("TOWER50 PASS: ",checks," checks; roster, assets, gates, loot, patterns, save compatibility")
	get_tree().quit()
