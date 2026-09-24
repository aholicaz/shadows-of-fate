extends Node2D
class Dummy extends Node2D:
	var data = null
	var hits := 0
	var damage := 0.0
	func is_dead() -> bool: return false
	func take_damage_from_player(mult, _matk, _dir, _a, _b, _id) -> void:
		hits += 1
		damage += mult
var actor
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func floor_at(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	body.position = pos
	add_child(body)
func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	PlayerState.stats.job_id = &"runeblade"
	PlayerState.stats.level = 50
	PlayerState.skills.learned[&"jump_slash"] = 10
	PlayerState.refresh()
	PlayerState.stats.sp = PlayerState.stats.max_sp
	floor_at(Vector2(1000,600),Vector2(4000,80))
	actor = load("res://scenes/player/player.tscn").instantiate()
	add_child(actor)
	actor.position = Vector2(200,350)
	for i in 60: await get_tree().physics_frame
	var start: float = actor.position.x
	actor.facing = 1
	var target := Dummy.new()
	add_child(target)
	target.add_to_group("enemy")
	target.position = Vector2(start+850,550)
	actor.use_skill(&"jump_slash")
	check(is_instance_valid(actor.jump_slash_motion), "Cast started")
	actor._iframe = 0.1
	for i in 60: await get_tree().physics_frame
	check(actor._iframe <= 0.0, "Leap does not extend dodge immunity")
	check(target.hits == 1 and absf(target.damage-12.72)<0.01, "One hit with level 10 damage")
	check(actor.position.x-start > 500 and actor.position.x-start < 640, "Travel near 600")
	check(not actor.is_attacking and not actor.runeblade.casting, "Cast released controls")
	check(actor.sprite.sprite_frames.get_frame_count(&"JumpSlash_Runeblade") == 32, "32 imported frames")
	for lv in range(1,11):
		check(absf(GameData.get_skill(&"jump_slash").damage_mult(lv)-GameData.get_skill(&"rune_lunge").damage_mult(lv)*1.2)<0.001, "Damage 120 percent of lunge")
	actor._play("JumpSlash_Runeblade",true)
	actor.sprite.pause()
	actor.sprite.frame = 11
	actor._apply_auto_fit()
	var airborne_offset: float = actor.sprite.offset.y
	actor.sprite.frame = 6
	actor._apply_auto_fit()
	check((actor.sprite.offset.y-airborne_offset)*actor.sprite.scale.y > actor.auto_fit_height, "Apex clears standing height")
	actor._play("Idle",true)
	check(preload("res://scripts/entities/runeblade_visual.gd").baked_weapon(actor.sprite.sprite_frames,&"JumpSlash_Runeblade"), "Hide equipped blade")
	floor_at(Vector2(actor.position.x+220,400),Vector2(50,320))
	PlayerState.cooldowns.clear()
	PlayerState.stats.sp = PlayerState.stats.max_sp
	start = actor.position.x
	target.position.x = start+350
	target.hits = 0
	actor.use_skill(&"jump_slash")
	for i in 60: await get_tree().physics_frame
	check(target.hits == 0, "No wave damage through wall")
	check(actor.position.x-start < 220, "Wall stops leap")
	PlayerState.cooldowns.clear()
	PlayerState.stats.sp = PlayerState.stats.max_sp
	actor.facing = -1
	actor.use_skill(&"jump_slash")
	for i in 12: await get_tree().physics_frame
	actor._dead = true
	actor.jump_slash_motion.cancel()
	for i in 3: await get_tree().physics_frame
	check(not is_instance_valid(actor.jump_slash_motion) and not actor.runeblade.casting, "Death cancels")
	print("JUMP_SLASH_TEST failures=", failures)
	get_tree().quit(failures)
