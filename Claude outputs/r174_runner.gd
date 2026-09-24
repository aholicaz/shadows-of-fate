extends Node2D
## รอบ 174 — Meteor กุลล์ไวก์ไล่ตามผู้เล่น 5 ลูก ไม่มีไฟที่พื้น
const FX = preload("res://scripts/entities/boss_signature_skill.gd")
const MONSTER = preload("res://scenes/monsters/monster.tscn")
const OUT := "res://output/r174/"
class Target extends Node2D:
	var hits: Array = []
	var vx := 0.0
	func foot_position() -> Vector2: return global_position
	func is_invincible() -> bool: return false
	func take_damage(damage: int, _force: float, _direction: int) -> void: hits.append(damage)
	func _physics_process(d: float) -> void: position.x += vx * d
	func _draw() -> void:
		draw_rect(Rect2(-24,-130,48,130),Color("467faf"))
		draw_circle(Vector2(0,-143),22,Color("d5e8f8"))
var fails := 0
var passes := 0
var target: Target
var actor
func ok(c: bool, m: String) -> void:
	if c: passes += 1; print("  PASS ", m)
	else: fails += 1; print("  FAIL ", m)
func _draw() -> void:
	draw_rect(Rect2(0,690,1600,210),Color("293947"))
func _ready() -> void:
	get_window().size = Vector2i(1600,900)
	get_window().content_scale_size = Vector2i(1600,900)
	RenderingServer.set_default_clear_color(Color("111a2a"))
	UI.layer.hide()
	PlayerState.new_game()
	PlayerState.stats.max_hp = 999999
	PlayerState.stats.hp = 999999
	target = Target.new()
	target.add_to_group("player")
	add_child(target)
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(6000,100)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(800,740)
	add_child(floor_body)
	await get_tree().physics_frame
	actor = MONSTER.instantiate()
	actor.data = load("res://data/monsters/gullveig_ember.tres")
	add_child(actor)
	actor.set_physics_process(false)
	actor._player = target
	actor.sprite.visible = false   # คลาวด์ไม่มีภาพจริง (กล่องแดงบังจอ)
	actor.position = Vector2(300,690-actor.data.foot_offset())
	ok(FX.METEOR_COUNT == 5, "5 ลูก")
	# ---- ยืนนิ่ง ----
	target.position = Vector2(900,690)
	target.hits.clear()
	var fx = FX.cast(actor, "meteor", 1)
	var shots := 0
	while is_instance_valid(fx) and not fx.is_queued_for_deletion():
		await get_tree().physics_frame
		if not is_instance_valid(fx): break
		if shots < 3 and fx.elapsed >= [0.85, 1.25, 1.95][shots]:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "still_%d.png" % shots))
			shots += 1
	ok(target.hits.size() == 5, "ยืนนิ่งโดนครบ 5 ลูก (%d)" % target.hits.size())
	# ---- วิ่งหนี 430 px/s ----
	target.position = Vector2(700,690)
	target.hits.clear()
	target.vx = 430.0
	fx = FX.cast(actor, "meteor", 1)
	var xs: Array = []
	var shot2 := false
	while is_instance_valid(fx) and not fx.is_queued_for_deletion():
		await get_tree().physics_frame
		if not is_instance_valid(fx): break
		if not shot2 and fx.elapsed >= 1.9:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "run.png"))
			shot2 = true
		if fx.fired > xs.size():
			xs.append(fx.points[xs.size()].x)
	ok(xs.size() == 5 and xs[4] > xs[0] + 1000, "วิ่งหนี: ลูกตกตามตัว x = %s" % str(xs))
	ok(target.hits.size() == 0, "วิ่งต่อเนื่องหลบได้ทุกลูก (โดน %d)" % target.hits.size())
	# ---- วิ่งแล้วหยุด (ลูกที่ล็อกตอนหยุดต้องโดน) ----
	target.position = Vector2(700,690)
	target.hits.clear()
	target.vx = 430.0
	fx = FX.cast(actor, "meteor", 1)
	while is_instance_valid(fx) and not fx.is_queued_for_deletion():
		await get_tree().physics_frame
		if not is_instance_valid(fx): break
		if fx.elapsed >= 2.2: target.vx = 0.0
	ok(target.hits.size() >= 2, "หยุดกลางทาง = ลูกหลัง ๆ โดน (%d)" % target.hits.size())
	ok(not ("GROUND" in FX.new()), "ไม่มีไฟที่พื้นแล้ว")
	print("R174 RESULT: %d pass · %d fail" % [passes, fails])
	get_tree().quit(1 if fails > 0 else 0)
