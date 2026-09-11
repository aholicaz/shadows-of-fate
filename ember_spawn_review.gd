extends Node

func _ready() -> void:
	PlayerState.new_game()
	var map = load("res://scenes/maps/ember_mine.tscn").instantiate()
	add_child(map)
	var spawner = map.get_node("Spawners/MapSpawner")
	assert(spawner.count_per_type == 5)
	assert(spawner._total_wanted() == 10)
	for i in range(200):
		await get_tree().create_timer(0.1).timeout
		if spawner._alive.size() >= 10:
			break
	var counts := {}
	for mon in spawner._alive:
		assert(is_instance_valid(mon) and not mon.is_dead())
		counts[mon.data.id] = counts.get(mon.data.id, 0) + 1
	print("EMBER MINE SPAWNS: ", counts)
	assert(counts.get(&"ember_bat", 0) > 0, "ember bats spawn")
	assert(counts.get(&"magma_slug", 0) > 0, "magma slugs spawn")
	var previous_count: int = spawner._alive.size()
	spawner._alive[0].queue_free()
	await get_tree().process_frame
	for i in range(100):
		await get_tree().create_timer(0.1).timeout
		if spawner._alive.size() >= previous_count and spawner._alive.all(func(m): return is_instance_valid(m)):
			break
	assert(spawner._alive.size() >= previous_count and spawner._alive.all(func(m): return is_instance_valid(m)), "missing monster replenishes")
	print("EMBER MINE PASS: both types spawn, refill verified; target capacity 10")
	get_tree().quit()
