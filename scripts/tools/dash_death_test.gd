extends Node
var finished := false
func wait_dash(player) -> void:
	assert(not await player._wait_dash_completion())
	finished = true
func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	var player = load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	player._dash_time = 10.0
	wait_dash(player)
	player._dead = true
	await get_tree().physics_frame
	await get_tree().process_frame
	assert(finished)
	finished = false
	player._dead = false
	wait_dash(player)
	remove_child(player)
	await get_tree().physics_frame
	await get_tree().process_frame
	assert(finished)
	player.free()
	print("DASH_DEATH_PASS: death during dash and scene removal both cancel pending wait")
	get_tree().quit()
