extends Node

func _ready() -> void:
	var runner := Node.new()
	runner.set_script(load("res://r82_runner.gd"))
	get_tree().root.add_child.call_deferred(runner)
	await get_tree().process_frame
	await get_tree().process_frame
	runner.run()
