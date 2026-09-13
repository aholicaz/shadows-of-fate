extends Node

var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: ",message)
	else:
		failures += 1
		push_error(message)

func _ready() -> void:
	var music := MusicPlayer.new()
	add_child(music)
	music.enabled = true
	for map_id in MusicPlayer.MAP_TRACKS:
		var path := music.find_track(map_id)
		check(not path.is_empty(),"track resolves for "+map_id)
		var stream = load(path) as AudioStreamOggVorbis
		check(stream != null and stream.get_length()>118 and stream.get_length()<121,"compact OGG decodes: "+map_id)
	music.play_for_map(&"frost_pass")
	await get_tree().create_timer(0.1).timeout
	var active := music._active
	var stream := music._players[active].stream
	check(stream.loop and music._players[active].playing,"field music plays and loops")
	for map_id in [&"giant_steppe",&"frozen_hall",&"broken_wall"]:
		music.play_for_map(map_id)
		check(music._active==active and music._players[active].stream==stream,"field transition preserves playback: "+String(map_id))
	music.play_for_map(&"utgard_town")
	check(music._current_key=="chapter4_town" and music._active!=active,"town switches to its shared track")
	music.play_for_map(&"hrungnir_crater")
	check(music._current_key=="chapter4_boss" and music._players[music._active].playing,"boss map plays battle track")
	music.play_for_map(&"vanir_town")
	check(music._current_key=="vanir_town","other chapters retain their original mapping")
	music.queue_free()
	await get_tree().process_frame
	print("CHAPTER 4 MUSIC: %d checks; failures=%d"%[checks,failures])
	get_tree().quit(1 if failures else 0)
