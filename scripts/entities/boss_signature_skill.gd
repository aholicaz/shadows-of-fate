extends Node2D
signal finished
const METEOR = preload("res://Sprites/effects/boss_skills/meteor_frames.tres")
const JET = preload("res://Sprites/effects/boss_skills/flame_jet_frames.tres")
const SCYTHE = preload("res://Sprites/effects/boss_skills/scythe_frames.tres")
const GROUND = preload("res://Sprites/effects/boss_skills/burning_ground_frames.tres")
const IMPACT_TIMES := [1.65, 1.85, 2.05]
const SCYTHE_TIMES := [0.90, 1.32, 1.84]
const JET_TIMES := [1.00, 1.50, 2.00]
const BURN_SECONDS := 5.0
var caster: Node2D
var data: MonsterData
var kind := ""
var direction := 1
var elapsed := 0.0
var points: Array[Vector2] = []
var fired := 0
var ticks := [0,0,0]
var cast_done := false
var impact_hit := false
var last_burn := -10.0
var jet_origin := Vector2.ZERO

static func cast(actor: Node2D, mode: String, facing: int) -> Node2D:
	var fx = load("res://scripts/entities/boss_signature_skill.gd").new()
	fx.caster = actor
	fx.data = actor.data
	fx.kind = mode
	fx.direction = facing
	actor.get_parent().add_child(fx)
	fx.global_position = actor.foot_position()
	fx.z_index = 65
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if mode == "flame_jet":
		actor._play("Attack",true)
		fx.jet_origin = actor.projectile_origin(9) - fx.global_position
	var target := actor.get_tree().get_first_node_in_group("player")
	var center: Vector2 = target.foot_position() if target != null and target.has_method("foot_position") else actor.foot_position() + Vector2(facing * 300,0)
	if mode == "meteor":
		for offset in [-240.0,0.0,240.0]:
			var at := center + Vector2(offset,0)
			var ray := PhysicsRayQueryParameters2D.create(at + Vector2(0,-80),at + Vector2(0,1600),1)
			var ground := actor.get_world_2d().direct_space_state.intersect_ray(ray)
			at.y = ground.position.y if not ground.is_empty() else actor.foot_position().y
			fx.points.append(at)
	var label := "Meteor • ฝนเพลิงกุลล์ไวก์" if mode == "meteor" else ("เพลิงพุ่งเผาผลาญ" if mode == "flame_jet" else "เคียวฟาดฟันสามคม")
	Events.floating_text(actor.global_position + Vector2(0,actor.data.hp_bar_offset_y - 25), label, Color("ffb066"), 22, 0)
	return fx

func _finish_cast() -> void:
	if not cast_done:
		cast_done = true
		finished.emit()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(caster) or caster.is_queued_for_deletion() or caster.get("hp") <= 0 or PlayerState.is_dead():
		_finish_cast()
		queue_free()
		return
	elapsed += delta
	if kind == "meteor":
		for i in range(3):
			if fired == i and elapsed >= IMPACT_TIMES[i]:
				fired += 1
				if not impact_hit: impact_hit = _hit(points[i],120,260,2.6,90)
			while ticks[i] < 5 and elapsed >= IMPACT_TIMES[i] + float(ticks[i] + 1):
				ticks[i] += 1
				if elapsed - last_burn >= 0.85 and _hit(points[i],120,55,0.35,0): last_burn = elapsed
		if elapsed >= 2.25: _finish_cast()
		if elapsed >= IMPACT_TIMES[2] + BURN_SECONDS + 0.05: queue_free()
	else:
		var times: Array = SCYTHE_TIMES if kind == "scythe" else JET_TIMES
		while fired < 3 and elapsed >= times[fired]:
			var index := fired
			fired += 1
			if kind == "scythe":
				caster._play("Attack",true)
				_hit(global_position + Vector2(direction * 200,0),230,260,[1.15,1.25,1.5][index],250 if index == 2 else 25)
			else:
				_hit(global_position + Vector2(direction * 320,0),330,260,1.2,20)
		if elapsed >= 2.5:
			_finish_cast()
			queue_free()
	queue_redraw()

func _hit(center: Vector2, radius: float, height: float, mult: float, force: float) -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or PlayerState.is_dead(): return false
	var point: Vector2 = player.foot_position() if player.has_method("foot_position") else player.global_position
	if absf(point.x-center.x) > radius or absf(point.y-center.y) > height: return false
	if player.has_method("is_invincible") and player.is_invincible(): return false
	var result := Combat.monster_skill_hits_player(data,PlayerState.stats,mult)
	if result.miss: return false
	player.take_damage(result.damage,force,signi(int(point.x-global_position.x)))
	return true

func _warn(at: Vector2, radius: float, progress: float) -> void:
	draw_set_transform(at,0,Vector2(1,0.25))
	draw_circle(Vector2.ZERO,radius,Color(1,0.22,0.03,0.12 + progress*0.15))
	draw_arc(Vector2.ZERO,radius,0,TAU,64,Color(1,0.55,0.10,0.9),3,true)
	draw_arc(Vector2.ZERO,radius*progress,0,TAU,64,Color(1,0.8,0.3,0.7),2,true)
	draw_set_transform(Vector2.ZERO)

static func animation_frame(frames: SpriteFrames, age: float) -> int:
	var index := maxi(0,int(floor(age * frames.get_animation_speed(&"default"))))
	var count := frames.get_frame_count(&"default")
	return index % count if frames.get_animation_loop(&"default") else mini(index,count-1)

func _texture(frames: SpriteFrames, age: float) -> Texture2D:
	return frames.get_frame_texture(&"default",animation_frame(frames,age))

func _draw() -> void:
	if kind == "meteor":
		for i in range(points.size()):
			var at := points[i]-global_position
			var impact: float = IMPACT_TIMES[i]
			if elapsed < impact:
				_warn(at,120,clampf(elapsed/impact,0,1))
				var fall := clampf((elapsed-(impact-0.45))/0.45,0,1)
				if fall > 0:
					draw_texture_rect(_texture(METEOR,elapsed+i*0.1),Rect2(at+Vector2(-230,-440-(1-fall)*750),Vector2(460,460)),false)
			elif elapsed <= impact+BURN_SECONDS:
				var age := elapsed-impact
				var fade := minf(1.0,(BURN_SECONDS-age)*2.0)
				var pulse := 1.0 + sin(elapsed*15+i)*0.02
				var ground_age := age+i*0.1
				var baselines: PackedFloat32Array = GROUND.get_meta("baseline_y")
				var baseline := baselines[animation_frame(GROUND,ground_age)] / 444.0 * 290.0
				draw_texture_rect(_texture(GROUND,ground_age),Rect2(at+Vector2(-145*pulse,15-baseline),Vector2(290*pulse,290)),false,Color(1,1,1,fade))
				if age < 0.35:
					_warn(at,120+age*150,1-age/0.35)
	else:
		var warning := 0.9 if kind == "scythe" else 1.0
		if elapsed < warning:
			_warn(Vector2(direction*(200 if kind=="scythe" else 320),0),230 if kind=="scythe" else 330,elapsed/warning)
		if kind == "flame_jet" and elapsed >= warning:
			var opacity := clampf((2.5-elapsed)*3.0,0,1)
			var end := Vector2(direction*630,-80)
			var ray := end-jet_origin
			var length := ray.length()/0.9
			var angle := Vector2(absf(ray.x),ray.y).angle()
			draw_set_transform(jet_origin,angle*direction,Vector2(direction,1))
			draw_texture_rect(_texture(JET,elapsed-warning),Rect2(-length*.05,-205,length,360),false,Color(1,1,1,opacity))
		elif kind == "scythe":
			for i in range(3):
				var age: float = elapsed-SCYTHE_TIMES[i]+0.12
				if age >= 0 and age < 0.42:
					var angle := deg_to_rad([-18.0,14.0,-6.0][i]+age*30)
					# Sheet opens right; convex cutting edge must lead away from caster.
					draw_set_transform(Vector2(direction*200,-150),angle*direction,Vector2(-direction,1))
					draw_texture_rect(_texture(SCYTHE,age),Rect2(-250,-215,500,430),false)
		draw_set_transform(Vector2.ZERO)
