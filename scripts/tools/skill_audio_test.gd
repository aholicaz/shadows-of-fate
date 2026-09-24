extends Node
func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	var player = load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	var sfx := SfxPlayer.new()
	add_child(sfx)
	sfx.enabled = true
	sfx.volume = 0.5
	var expected := {&"slash":"skill_slash_eleven", &"magnum_break":"skill_wave_eleven", &"erasing_cut":"skill_wave_eleven", &"rune_flurry":"skill_flurry_eleven", &"worldcleaver":"skill_rain_eleven"}
	for id in expected:
		var keys: Array = player.skill_sfx_keys(id)
		assert(keys[0] == expected[id])
		assert(sfx.has_sound(keys[0]))
		var stream: AudioStream = load(sfx.find_sound(keys[0]))
		assert(stream != null and stream.get_length() > 1.9 and stream.get_length() < 2.1)
		sfx._last_played.clear()
		var voice := sfx._next
		assert(sfx.play_first(keys))
		assert(sfx._players[voice].stream == stream)
	assert(load("res://scripts/entities/runeblade_combat.gd") != null)
	print("SKILL_AUDIO_PASS: 5 skill mappings load valid audio and take priority over fallback sounds")
	get_tree().quit()
