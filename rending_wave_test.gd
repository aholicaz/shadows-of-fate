extends Node2D

const Wave = preload("res://scripts/entities/rending_wave.gd")
var failures := 0
var checks := 0

class Caster extends Node2D:
	var _dead := false
	func foot_position() -> Vector2:
		return global_position

class Target extends Node2D:
	var data: MonsterData = null
	var hits := 0
	var bonus := 0.0
	func body_rect() -> Rect2:
		return Rect2(global_position - Vector2(15, 90), Vector2(30, 180))
	func take_damage_from_player(_mult: float, _magic: bool, _dir: int,
			wound: float = 0, _duration: float = 0) -> void:
		hits += 1
		bonus = wound
	func is_dead() -> bool:
		return false

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)

func target(at: Vector2) -> Target:
	var enemy := Target.new()
	add_child(enemy)
	enemy.global_position = at
	enemy.add_to_group("enemy")
	return enemy

func _ready() -> void:
	PlayerState.new_game()
	var skill := GameData.get_skill(&"magnum_break")
	check(skill.type == SkillData.SkillType.ACTIVE_WAVE, "legacy key loads replacement")
	check(is_equal_approx(skill.damage_mult(10), 3.6) and skill.sp_cost(10) == 19, "level 10 damage and cost")
	check(is_equal_approx(skill.wound_bonus(1), 0.2) and is_equal_approx(skill.wound_bonus(10), 0.35), "wound scaling 20 to 35 percent")
	var saved := SkillBook.new()
	saved.from_dict({"learned": {"magnum_break": 7}, "hotkeys": ["magnum_break", "bash"]})
	check(saved.level_of(&"magnum_break") == 7 and saved.hotkey_at(0) == &"magnum_break", "old learned level and hotkey survive")
	for direction in [-1, 1]:
		var caster := Caster.new()
		add_child(caster)
		var targets: Array[Target] = []
		# Reverse creation order to test nearest-target ordering.
		for i in range(7, 0, -1):
			targets.append(target(Vector2(direction * i * 80, -100)))
		var behind := target(Vector2(-direction * 70, -100))
		var above := target(Vector2(direction * 100, -400))
		var far := target(Vector2(direction * 800, -100))
		var wave = Wave.spawn(skill, caster, direction, 10)
		wave.set_physics_process(false)
		check(wave._custom_visual and wave._art != null, "painted wave replaces procedural fire")
		check(wave._art.flip_h == (direction > 0), "left-facing artwork mirrors only for right cast")
		check(skill.effect_frames.get_frame_count(&"wave") == 8, "all eight artwork frames loaded")
		var art_bottom: float = wave.global_position.y + wave._art.position.y + (0.94 - 0.5) * 443.0 * wave._art.scale.y
		check(absf(art_bottom - caster.foot_position().y) < 0.1, "wave artwork stays anchored to caster foot height")
		wave._physics_process(1.0)
		var hits := 0
		for enemy in targets:
			hits += enemy.hits
		check(hits == 5 and targets[0].hits == 0 and targets[6].hits == 1, "nearest 5 hit even on a large physics step, facing " + str(direction))
		check(behind.hits == 0 and above.hits == 0 and far.hits == 0, "no hits behind, above or beyond range")
		check(is_equal_approx(targets[6].bonus, 0.35), "wave forwards wound strength")
		for enemy in targets + [behind, above, far]:
			enemy.queue_free()
		caster.queue_free()
		await get_tree().process_frame
	var caster := Caster.new()
	add_child(caster)
	var single := target(Vector2(180,-100))
	var wave = Wave.spawn(skill, caster, 1, 1)
	wave.set_physics_process(false)
	for i in range(20):
		wave._physics_process(0.02)
	check(single.hits == 1, "one hit per enemy across overlapping frames")
	wave.queue_free()
	single.queue_free()
	await get_tree().process_frame
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 260)
	shape.shape = rect
	wall.add_child(shape)
	add_child(wall)
	wall.position = Vector2(200, -100)
	var near_target := target(Vector2(90,-100))
	var blocked_target := target(Vector2(240,-100))
	await get_tree().physics_frame
	await get_tree().physics_frame
	wave = Wave.spawn(skill,caster,1,1)
	wave.set_physics_process(false)
	wave._physics_process(1.0)
	check(near_target.hits == 1 and blocked_target.hits == 0, "terrain blocks wave and protects enemies beyond it")
	wall.queue_free()
	near_target.queue_free()
	blocked_target.queue_free()
	await get_tree().process_frame
	var custom := skill.duplicate() as SkillData
	custom.effect_frames = SpriteFrames.new()
	custom.effect_frames.add_animation(&"wave")
	custom.effect_frames.add_frame(&"wave", skill.icon)
	single = target(Vector2(150,-100))
	wave = Wave.spawn(custom,caster,1,1)
	wave.set_physics_process(false)
	wave._physics_process(0.3)
	check(wave._custom_visual and single.hits == 1, "replacement sprite does not change gameplay collision")
	wave.queue_free()
	single.queue_free()
	await get_tree().process_frame
	caster._dead = true
	single = target(Vector2(150,-100))
	wave = Wave.spawn(skill,caster,1,1)
	wave.set_physics_process(false)
	wave._physics_process(0.3)
	check(single.hits == 0 and wave.is_queued_for_deletion(), "dead caster cancels wave")
	single.queue_free()
	caster.queue_free()
	await get_tree().process_frame
	# Real monster combat: no mutation of the shared MonsterData resource.
	var monster = load("res://scenes/monsters/monster.tscn").instantiate()
	monster.data = load("res://data/monsters/poring.tres")
	add_child(monster)
	monster.set_physics_process(false)
	monster.hp = 100000
	var original_def: int = monster.data.def
	var hit_seed := 1
	for i in range(1,100):
		seed(i)
		if not Combat.player_hits_monster(PlayerState.stats,monster.data).miss:
			hit_seed = i
			break
	seed(hit_seed)
	var before: int = monster.hp
	monster.take_damage_from_player(10.0)
	var baseline: int = before - monster.hp
	monster.apply_wound(0.35,5.0)
	seed(hit_seed)
	before = monster.hp
	monster.take_damage_from_player(10.0)
	check(monster.hp < before - baseline and baseline > 0, "physical follow-up damage increases")
	monster.apply_wound(0.2,5.0)
	check(is_equal_approx(monster._wound_bonus,0.35), "wound refreshes without stacking or weakening")
	check(monster.data.def == original_def, "shared monster stats unchanged")
	monster._tick_wound(5.1)
	check(monster._wound_bonus == 0 and not monster._wound_label.visible, "wound expires with its indicator")
	seed(hit_seed)
	before = monster.hp
	monster.take_damage_from_player(10.0,true)
	var magic_baseline: int = before - monster.hp
	monster.apply_wound(0.35,5.0)
	seed(hit_seed)
	before = monster.hp
	monster.take_damage_from_player(10.0,true)
	check(before - monster.hp == magic_baseline, "wound does not amplify magical damage")
	monster._tick_wound(5.1)
	seed(hit_seed)
	before = monster.hp
	monster.take_damage_from_player(10.0,false,0,0.2,5.0)
	check(before-monster.hp == baseline and monster._wound_time > 0, "initial wave applies wound after its own damage")
	monster._tick_wound(5.1)
	var miss_seed := -1
	for i in range(1,1000):
		seed(i)
		if Combat.player_hits_monster(PlayerState.stats,monster.data).miss:
			miss_seed = i
			break
	seed(miss_seed)
	monster.take_damage_from_player(10.0,false,0,0.35,5.0)
	check(miss_seed >= 0 and monster._wound_time == 0, "miss does not apply wound")
	monster.data = load("res://data/monsters/forge_guardian.tres")
	monster.apply_wound(0.35,5.0)
	check(monster.data.is_boss and monster._wound_time > 0, "bosses accept the wound debuff")
	monster.queue_free()
	await get_tree().process_frame
	var player = load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	PlayerState.skills.learned[&"magnum_break"] = 1
	PlayerState.stats.sp = 100
	PlayerState.cooldowns.clear()
	check(player.skill_animation(&"magnum_break") == "Rending_Wave", "uses the artist's Rending_Wave animation")
	check(not player.sprite.sprite_frames.get_animation_loop("Rending_Wave"), "dedicated slash animation plays once")
	var timing: Vector3 = player._wave_animation_timing(skill, "Rending_Wave")
	check(is_equal_approx(timing.x, 0.3375) and is_equal_approx(timing.y, 0.72), "wave release matches downward slash frame 16")
	player.sprite.speed_scale = 4.0
	player.use_skill(&"magnum_break")
	check(is_equal_approx(player.sprite.speed_scale, timing.z), "cast overrides inherited attack animation speed")
	check(PlayerState.stats.sp == 90 and PlayerState.skill_cooldown_left(&"magnum_break") > 0, "cast spends SP and starts cooldown")
	await get_tree().create_timer(0.25).timeout
	check(get_node_or_null("RendingWave") == null and player.is_attacking, "windup keeps the pose active without an early projectile")
	await get_tree().create_timer(0.12).timeout
	check(get_node_or_null("RendingWave") != null, "real player casts the wave at windup")
	await get_tree().create_timer(0.3).timeout
	check(player.is_attacking, "recovery is not cut off before the pose ends")
	var sp: int = PlayerState.stats.sp
	player.use_skill(&"magnum_break")
	check(PlayerState.stats.sp == sp, "cooldown rejects repeat casts")
	await get_tree().create_timer(0.6).timeout
	check(not player.is_attacking and is_equal_approx(player.sprite.speed_scale, 1.0), "full pose finishes and restores normal playback")
	PlayerState.cooldowns.clear()
	PlayerState.stats.sp = 0
	player.use_skill(&"magnum_break")
	check(PlayerState.stats.sp == 0 and PlayerState.skill_cooldown_left(&"magnum_break") == 0,
		"insufficient SP does not cast or start cooldown")
	player.queue_free()
	await get_tree().process_frame
	print("RENDING WAVE: ", checks, " checks; failures=", failures)
	get_tree().quit(1 if failures else 0)
