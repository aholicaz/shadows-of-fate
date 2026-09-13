extends Node

var failures := 0
func check(ok: bool, message: String) -> void:
	if ok: print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _ready() -> void:
	PlayerState.new_game()
	PlayerState.gm_god_mode = true
	var map = load("res://scenes/maps/prontera_field.tscn").instantiate()
	add_child(map)
	await get_tree().create_timer(0.5).timeout
	var player = map.player
	player.facing = 1
	var start_x: float = player.position.x
	var seen := {}
	player.sprite.frame_changed.connect(func():
		if player.sprite.animation == &"Dash": seen[player.sprite.frame] = true)
	player._start_dodge()
	seen[0] = true
	var frames: int = player.sprite.sprite_frames.get_frame_count(&"Dash")
	check(is_equal_approx(player._anim_length("Dash") / player.sprite.speed_scale,player._dodge_duration),"animation length matches complete dash duration")
	check(is_equal_approx(player._iframe,player.dodge_invincible),"invulnerability duration remains unchanged")
	PlayerState.skills.learned[&"bash"] = 1
	var sp: int = PlayerState.stats.sp
	player.start_attack()
	player.use_skill(&"bash")
	check(not player.is_attacking and player.sprite.animation==&"Dash" and PlayerState.stats.sp==sp,"attack and skill buttons cannot cut off Dash")
	var peak := 0.0
	while player._dodge_time > 0:
		await get_tree().physics_frame
		peak = maxf(peak,absf(player.velocity.x))
	check(absf(player.position.x-start_x-player.dodge_distance)<2,"eased dash preserves travel distance")
	check(peak <= player.dodge_speed+1,"dash does not exceed configured speed")
	check(seen.size()==frames,"every Dash frame is reached: %d/%d"%[seen.size(),frames])
	await get_tree().create_timer(0.05).timeout
	check(player.sprite.animation != &"Dash" and player.sprite.speed_scale==1,"dash returns to locomotion at normal playback speed")
	player._dodge_cd = 0
	player._start_dodge()
	player._dodge_wall_stopped = true
	start_x = player.position.x
	await get_tree().create_timer(0.1).timeout
	check(player._dodge_time > 0 and player.sprite.animation==&"Dash" and absf(player.position.x-start_x)<1,"wall stop preserves remaining animation without travel")
	await get_tree().create_timer(0.5).timeout
	check(player._dodge_time==0 and player.sprite.speed_scale==1,"wall recovery finishes normally")
	print("DASH TIMING: failures=",failures)
	map.queue_free()
	await get_tree().process_frame
	get_tree().quit(1 if failures else 0)
