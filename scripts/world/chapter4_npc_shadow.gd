extends "res://scripts/entities/foot_shadow.gd"
## Town NPCs stand on the painted rear pavement, above the player's collision lane.
## Keep the shared shadow texture, but register contact to their authored sole plane.
func _physics_process(_delta: float) -> void:
	var foot := _npc_foot()
	global_position = foot + Vector2(0,-2)
	global_rotation = 0.0
	global_scale = Vector2(clampf(ground_size.x * .65,65,140),14)/128.0
	modulate = Color(1,1,1,.34)
	visible = true
