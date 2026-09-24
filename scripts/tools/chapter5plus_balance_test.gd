extends Node
func stats_only(id: String) -> MonsterData:
	# Numeric combat fields only: no loading hundreds of MB of unrelated sprite textures.
	var m := MonsterData.new()
	m.id = StringName(id)
	for line in FileAccess.get_file_as_string("res://data/monsters/"+id+".tres").split("\n"):
		var pair := line.split(" = ", true, 1)
		if pair.size()!=2: continue
		if pair[0] in ["max_hp","atk_min","atk_max","def","level","attack_cooldown","skill_cooldown","skill_damage_mult","skill_chance","crit","move_speed","skill_windup"]:
			m.set(pair[0],float(pair[1]))
	return m
func _ready() -> void:
	SaveManager.end_session()
	var changes = JSON.parse_string(FileAccess.get_file_as_string("res://output/chapter5plus_balance/changes.json"))
	var count := 0
	for row in changes:
		var m := stats_only(row.id)
		assert(m != null)
		for key in row.after:
			assert(is_equal_approx(float(m.get(key)),float(row.after[key])), str(row.id, " ", key))
		assert(m.atk_max >= m.atk_min and m.max_hp > 0)
		assert(m.def == int(row.def))
		count += 1
	var tower = preload("res://scripts/world/chapter8_tower_data.gd")
	for boss in [false,true]:
		for guardian in [false,true]:
			if guardian and not boss: continue
			var previous := 0
			for floor_number in range(1,21):
				var source := stats_only("chained_garm" if boss else "cinder_hound")
				var hp := source.max_hp
				var m: MonsterData = tower.make_enemy(source,floor_number,boss,guardian)
				assert(m.max_hp > previous and m.atk_max >= m.atk_min)
				assert(m.exp_reward==0 and m.zeny_max==0 and m.drops.is_empty())
				assert(source.max_hp==hp)
				previous = m.max_hp
	print("CHAPTER5PLUS_BALANCE_PASS campaign=",count," tower=60 variants; source immutable, reward-free, monotonic HP")
	get_tree().quit()
