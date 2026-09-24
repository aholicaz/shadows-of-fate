extends Node
const Tower = preload("res://scripts/world/chapter8_tower_data.gd")
var checks := 0

func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	PlayerState.stats.job_id = &"ninth_edge"
	PlayerState.stats.level = 150
	PlayerState.stats.base_vit = 150
	PlayerState.refresh()
	Tower.gm_test = true
	for number in [1, 25, 40, 50]:
		var map = load(Game.MAPS[Tower.floor_id(number)]).instantiate()
		add_child(map)
		await get_tree().process_frame
		map.player.set_physics_process(false)
		assert(absf(map.player.foot_position().y - 880.0) < 2)
		var money := PlayerState.zeny
		var stages := Tower.wave_sizes(number).size() + 1
		for wave in range(stages):
			# Fire existing spawn timers without waiting seven seconds per pair.
			# Actor creation, deaths, pending counts and stage transitions are real.
			for child in map.get_children():
				if child is Timer and child != map.transition_timer:
					child.stop()
					child.timeout.emit()
			await get_tree().process_frame
			var alive := 0
			for actor in map.enemy_container.get_children():
				if actor.is_in_group("enemy") and not actor.is_dead():
					alive += 1
					actor.set_physics_process(false)
					actor.take_damage(actor.hp + 1)
			assert(alive == (Tower.wave_sizes(number)[wave] if wave < stages-1 else Tower.boss_roster(number).size()))
			assert(map.living == 0 and is_instance_valid(map.transition_timer))
			map._advance_encounter()
			checks += 2
			await get_tree().process_frame
		assert(map.cleared and map.next_portal.required_flag == &"")
		assert(not PlayerState.has_flag(Tower.clear_flag(number)))
		assert(PlayerState.zeny == money)
		checks += 4
		# Now exercise first/repeat completion with an isolated in-memory state.
		Tower.gm_test = false
		map.cleared = false
		map._complete_floor()
		assert(PlayerState.has_flag(Tower.clear_flag(number)))
		var awarded := PlayerState.zeny
		map._complete_floor()
		assert(PlayerState.zeny == awarded)
		map.cleared = false
		map._complete_floor()
		assert(PlayerState.zeny == awarded)
		assert(not PlayerState.has_flag(&"chapter8_done"))
		checks += 4
		Tower.gm_test = true
		map.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		GameData.release_monsters_except([])
		print("TOWER ENCOUNTER floor ", number, " passed")
	assert(PlayerState.has_flag(&"c8_ascent50_done"))
	Tower.gm_test = false
	print("TOWER ENCOUNTER PASS: ", checks, " checks; real waves/deaths, gates, GM and repeated reward isolation")
	get_tree().quit()
