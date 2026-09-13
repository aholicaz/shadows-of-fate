extends Node2D
## Isolated real-renderer test; no saves, drops, or real-player damage.
const MONSTER = preload("res://scenes/monsters/monster.tscn")
const OUT = "res://output/spriteflow/fire_update/runtime/"
class Target extends Node2D:
	var hits := 0
	func foot_position() -> Vector2: return global_position
	func body_rect() -> Rect2: return Rect2(global_position-Vector2(35,220),Vector2(70,220))
	func take_damage(_damage: int, _force: float, _direction: int) -> void: hits += 1
	func _draw() -> void:
		draw_rect(Rect2(-35,-220,70,220),Color("547b9c"))
		draw_circle(Vector2(0,-190),24,Color("b4dcf2"))
var actor
var target: Target
var releases: Array = []
var impacts: Array = []
var errors: Array[String] = []
var checks := 0
var case_name := ""
var started := 0
var interrupted := false
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: errors.append(message)
func _draw() -> void:
	draw_rect(Rect2(0,750,1600,150),Color("263347"))
	draw_line(Vector2(0,750),Vector2(1600,750),Color("8693a8"),2)
	draw_string(ThemeDB.fallback_font,Vector2(50,65),"GULLVEIG / THREE FIREBALLS",HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("ffce8b"))
	draw_string(ThemeDB.fallback_font,Vector2(50,105),"Hand release  >  flame trail  >  impact",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("b0bfd4"))
func _ready() -> void:
	get_window().size = Vector2i(1600,900)
	get_window().content_scale_size = Vector2i(1600,900)
	RenderingServer.set_default_clear_color(Color("111a2a"))
	UI.layer.hide()
	PlayerState.new_game()
	DirAccess.make_dir_recursive_absolute(OUT)
	target = Target.new()
	target.add_to_group("player")
	add_child(target)
	actor = MONSTER.instantiate()
	actor.data = load("res://data/monsters/gullveig_ember.tres")
	add_child(actor)
	actor.set_physics_process(false)
	actor._player = target
	actor.sprite.position.y = -actor.data.hover_height
	actor.projectile_released.connect(_released)
	await run_cast(-1)
	await run_cast(1)
	case_name = "interrupted"
	releases.clear()
	interrupted = true
	actor.state = actor.State.IDLE
	actor._attack()
	await get_tree().create_timer(4.2).timeout
	check(releases.size()==1,"Interrupted cast stops after first projectile")
	interrupted = false
	await sweep_checks()
	var report := {"checks":checks,"failures":errors,"renderer":RenderingServer.get_current_rendering_method(),"engine":Engine.get_version_info().string}
	var file := FileAccess.open(OUT+"audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("FIREBALL_AUDIT ",JSON.stringify(report))
	get_tree().quit(0 if errors.is_empty() else 1)
func run_cast(direction: int) -> void:
	case_name = "left" if direction<0 else "right"
	releases.clear()
	impacts.clear()
	target.position = Vector2(350 if direction<0 else 1250,750)
	actor.position = Vector2(1200 if direction<0 else 400,750-actor.data.foot_offset())
	actor.facing = direction
	actor.sprite.flip_h = direction>0
	actor.state = actor.State.IDLE
	started = Time.get_ticks_msec()
	actor._attack()
	await get_tree().create_timer(5.0).timeout
	check(releases.size()==3,case_name+": exactly three projectiles")
	check(impacts.size()==3,case_name+": all three projectiles hit target")
	check(actor.state==actor.State.IDLE,case_name+": attack completes")
	var file := FileAccess.open(OUT+case_name+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"releases":releases,"impacts":impacts},"\t"))
	file.close()
func _released(shot: MonsterProjectile, frame: int) -> void:
	var expected: Vector2 = actor.projectile_origin(frame)
	check(shot.global_position.distance_to(expected)<.01,case_name+": muzzle anchored to hand")
	check(frame in [9,22,35],case_name+": authored release frame")
	check(actor.sprite.frame==frame,case_name+": release follows displayed frame")
	check(shot._velocity_direction.dot((target.body_rect().get_center()-expected).normalized())>.999,case_name+": aims at target body")
	releases.append({"frame":frame,"time":(Time.get_ticks_msec()-started)/1000.0,"origin":str(expected),"direction":str(shot._velocity_direction)})
	shot.impacted.connect(func(kind: StringName, at: Vector2):
		impacts.append({"kind":kind,"at":str(at)})
		check(kind==&"player",case_name+": collides with player")
	)
	if interrupted:
		actor.state = actor.State.DEAD
		actor.sprite.pause()
	else:
		capture(case_name+"_release_"+str(releases.size()))
		capture_flight(case_name+"_flight_"+str(releases.size()))
func capture(name_: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+name_+".png")
func capture_flight(name_: String) -> void:
	await get_tree().create_timer(.40).timeout
	await capture(name_)
func sweep_checks() -> void:
	actor.state = actor.State.IDLE
	target.position = Vector2(850,700)
	var shot := MonsterProjectile.fire_straight(actor.data,actor,1,Vector2(100,590),Vector2(850,590))
	shot.set_process(false)
	var results: Array = []
	shot.impacted.connect(func(kind: StringName,_at: Vector2): results.append(kind))
	shot._process(1.5)
	check(results==[&"player"],"Large frame step cannot tunnel through target")
	shot._process(1.5)
	check(results.size()==1,"One projectile impacts only once")
	await get_tree().create_timer(.3).timeout
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40,500)
	shape.shape = rect
	wall.add_child(shape)
	wall.position = Vector2(500,500)
	add_child(wall)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var blocked := MonsterProjectile.fire_straight(actor.data,actor,1,Vector2(100,590),Vector2(850,590))
	blocked.set_process(false)
	var blocked_results: Array = []
	blocked.impacted.connect(func(kind: StringName,_at: Vector2): blocked_results.append(kind))
	blocked._process(1.5)
	check(blocked_results==[&"terrain"],"Wall stops projectile before target at low FPS")
	wall.queue_free()
