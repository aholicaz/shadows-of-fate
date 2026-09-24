extends Node
const Tower = preload("res://scripts/world/chapter8_tower_data.gd")
class TestFloor extends "res://scripts/world/chapter8_floor.gd":
	var spawned := 0
	func _ready() -> void: pass
	func _queue_spawn(_id: String, _boss: bool, _guardian: bool, _x: float, _delay: float) -> void:
		spawned += 1
class TimedFloor extends "res://scripts/world/chapter8_floor.gd":
	var spawned := 0
	func _ready() -> void: pass
	func _spawn(_id: String, _boss: bool, _guardian: bool, _x: float) -> void:
		spawned += 1
class FakeBoss extends Node2D:
	var data: MonsterData
	var hp := 10000
	func is_dead() -> bool: return hp <= 0
func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	Tower.gm_test = false
	assert(not Tower.can_enter(1))
	Tower.gm_test = true
	for i in range(1,51): assert(Tower.can_enter(i))
	assert(not Tower.can_enter(0) and not Tower.can_enter(51))
	var floor := TestFloor.new()
	floor.floor_number = 5
	floor.status = Label.new()
	floor.add_child(floor.status)
	floor.next_portal = Area2D.new()
	floor.next_portal.set_script(load("res://scripts/world/portal.gd"))
	for title in ["Label","EnterHint"]:
		var label := Label.new()
		label.name = title
		floor.next_portal.add_child(label)
	# Keep portal out of tree: only exercise completion labels and lock properties.
	add_child(floor)
	for number in range(1, 51):
		floor.floor_number = number
		floor.stage = 0
		floor.spawned = 0
		var count := 0
		var species := {}
		for wave in range(Tower.wave_sizes(number).size()):
			var roster := Tower.wave_roster(number, wave)
			assert(roster.size() <= 8)
			for id in roster:
				assert(ResourceLoader.exists("res://data/monsters/%s.tres" % id), id)
				species[id] = true
			floor._next_stage()
			assert(floor.living == roster.size())
			count += roster.size()
		assert(count == [20, 24, 26, 30, 30, 30, 32, 32, 36, 36][Tower.theme(number)])
		assert(species.size() >= 4)
		floor._next_stage()
		var bosses := Tower.boss_roster(number)
		for id in bosses: assert(ResourceLoader.exists("res://data/monsters/%s.tres" % id), id)
		assert(floor.living == bosses.size())
		assert(floor.spawned == count + bosses.size())
	assert(floor.claim_boss_skill())
	assert(not floor.claim_boss_skill())
	floor.floor_number = 5
	var money := PlayerState.zeny
	floor._complete_floor()
	assert(floor.cleared and floor.next_portal.required_flag==&"")
	assert(not PlayerState.has_flag(Tower.clear_flag(5)))
	assert(PlayerState.zeny==money)
	floor.next_portal.free()
	Tower.gm_test = false
	assert(not Tower.can_enter(1))
	var source := MonsterData.new()
	source.id = &"poring"
	source.max_hp = 100
	var swarm := Tower.make_enemy(source, 1, false)
	assert(swarm.max_hp == 16800 and swarm.atk_max == 1200)
	assert(source.max_hp == 100 and source.drops.is_empty() and swarm.exp_reward == 0)
	for drop in swarm.drops: assert(preload("res://scripts/world/chapter8_loot.gd").allowed(drop.item_id))
	var pair := Tower.make_enemy(source, 11, true)
	assert(pair.max_hp == int(380000 * 1.52 * 0.65))
	var timed := TimedFloor.new()
	add_child(timed)
	timed._queue_spawn("poring", false, false, 1000, 0.05)
	assert(timed.spawned == 0)
	await get_tree().create_timer(0.1).timeout
	assert(timed.spawned == 1)
	# Leaving the floor removes pending spawn timers.
	timed._queue_spawn("poring", false, false, 1000, 0.2)
	timed.queue_free()
	await get_tree().process_frame
	# Pending boss is counted even when the first boss dies before its arrival.
	floor.stage = Tower.wave_sizes(11).size() + 1
	floor.floor_number = 11
	floor.living = 2
	floor._enemy_died(null, null)
	assert(floor.living == 1 and floor.transition_timer == null)
	var bar := preload("res://scripts/ui/boss_bar.gd").new()
	add_child(bar)
	var fake_bosses: Array[Node] = []
	for i in range(2):
		var enemy := FakeBoss.new()
		enemy.data = Tower.make_enemy(source, 11, true)
		enemy.data.display_name = "บอสทดสอบ %d" % (i + 1)
		enemy.data.max_hp = 10000
		add_child(enemy)
		enemy.add_to_group("enemy")
		fake_bosses.append(enemy)
	await get_tree().process_frame
	assert(bar._boss == fake_bosses[0])
	var second: Control
	for child in bar.get_children():
		if child is BossBar: second = child
	assert(second != null and second._boss == fake_bosses[1])
	await get_tree().create_timer(0.1).timeout
	print("BAR_LAYOUT ", bar._box.position, " ", bar._box.size, " second ",second._box.position)
	assert(second._box.position.y > bar._box.position.y + bar._box.size.y)
	if "--preview" in OS.get_cmdline_user_args():
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/tower_boss_pair_ui.png")
	fake_bosses[0].hp = 0
	await get_tree().process_frame
	await get_tree().process_frame
	assert(bar._boss == fake_bosses[1] and second._boss == null)
	print("TOWER_GM_PASS: all 50 floors, wave counts, diversity, boss pairs, skill coordination, gates and reward isolation")
	get_tree().quit()
