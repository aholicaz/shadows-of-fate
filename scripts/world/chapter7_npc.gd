extends "res://scripts/world/npc.gd"
func _ready() -> void:
	super._ready()
	Events.quest_changed.connect(_sync_story)
func _sync_story() -> void:
	if hide_if_flag!=&"" and PlayerState.has_flag(hide_if_flag):
		visible=false
		_player_inside=false
		set_deferred("monitoring",false)
		set_process_unhandled_input(false)
		remove_from_group("npc")
		if _prompt!=null:_prompt.hide()
