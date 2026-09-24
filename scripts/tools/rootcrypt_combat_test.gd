extends Node
func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	PlayerState.set_flag(&"seen_intro_baphomet")
	PlayerState.stats.level = 50
	PlayerState.stats.base_vit = 30
	PlayerState.refresh()
	var map = load("res://scenes/maps/blackhorn_rootcrypt.tscn").instantiate()
	add_child(map)
	await get_tree().process_frame
	var hp_before: int = map.boss.hp
	map.boss.take_damage(99999)
	assert(map.boss.hp == hp_before)
	map.player.position = Vector2(4300,770)
	map._physics_process(0.016)
	assert(not map.fighting and map.player.position.x == 4200)
	for i in range(3): PlayerState.set_flag(StringName("rb_seal_%d" % i))
	PlayerState.quests.accept(&"rb5_oath_eater")
	var player_hp := PlayerState.stats.hp
	map.player.position.x = 4300
	map._physics_process(0.016)
	assert(map.fighting and map.boss.is_physics_processing())
	assert(PlayerState.stats.hp == player_hp)
	assert(not map.boss.get_meta("encounter_locked"))
	map.boss.take_damage(1)
	assert(map.boss.hp == hp_before - 1)
	map.player.position.x = 5200
	assert(map.boss.data.atk_min == 520 and map.boss.data.has_skill())
	var jr = map._spawn(true,Vector2(5900,790),true)
	assert(jr.data.atk_min == 380 and jr.data.drops.is_empty() and jr.data.exp_reward == 0)
	for i in range(600):
		PlayerState.stats.max_hp = 100000
		PlayerState.stats.hp = 100000
		await get_tree().physics_frame
	print("DIAG ", map.boss.position, " player ", map.player.position, " dead ", PlayerState.is_dead(), " state ", map.boss.state, " cd ", map.boss._skill_cd)
	assert(map.boss._special_cast_count > 0)
	assert(map.boss.is_physics_processing())
	print("ROOTCRYPT_COMBAT_PASS: live boss AI casts signature skill, local damage, rewardless summons")
	get_tree().quit()
