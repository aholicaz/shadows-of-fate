## MonsterProjectile — กระสุนของมอนสเตอร์ (รอบ 36)
##
## 2 แบบ:
##   ★ ยิงตรง ★  fire_straight() — บอลพุ่งไปข้างหน้า ชนผู้เล่นแล้วทำดาเมจ (ลูนาติก)
##   ★ ขว้างโค้ง ★ fire_lob()    — บอลลอยเป็นโค้งไปตกที่ตำแหน่งผู้เล่น แล้วระเบิดทำดาเมจรอบ ๆ (คิงโพริง)
##
## ไม่ต้องสร้างเอง — ใส่รูปในช่อง Projectile Texture / Skill Projectile Texture ของ MonsterData แล้ว
## monster_base.gd จะเรียกให้เองตอนโจมตี/ร่ายสกิล
class_name MonsterProjectile
extends Node2D
signal impacted(kind: StringName, at: Vector2)

const DEFAULT_BURST := "res://Sprites/effects/slime_burst.png"
const BURST_FRAMES := 8
## ★ รอบ 82 ★ ขนาดช่องคิดจากภาพจริง (กว้างภาพ / จำนวนเฟรม) ไม่ใช่เลขตายตัวอีกแล้ว
## เปลี่ยนภาพชีทใหม่แล้วไม่ต้องมาแก้โค้ด ขอแค่เป็นแถวเดียว 8 ช่องเท่ากัน
## ตัวคูณตำแหน่ง: ยกภาพขึ้นจากจุดตกเท่าไหร่ (0.5 = กึ่งกลางภาพอยู่ที่จุดตกพอดี)
const BURST_LIFT := 0.46
const FIRE_SHADER = preload("res://Sprites/effects/gullveig_fireball.gdshader")
const FIRE_BURST = preload("res://scripts/entities/fireball_burst.gd")

enum Mode { STRAIGHT, LOB }

var data: MonsterData
var mode: Mode = Mode.STRAIGHT
var _dir := 1
var _velocity_direction := Vector2.RIGHT
var _speed := 0.0
var _range := 0.0
var _travelled := 0.0
var _hit_size := Vector2.ZERO
var _spin := 0.0
var _sprite: Sprite2D
var _done := false
## ★ รอบ 69 ★ ตัวคูณดาเมจของนัดนี้ (ใช้ตอนมอนยิงหลายนัดในท่าเดียว)
var damage_mult := 1.0

# ---- แบบโค้ง ----
var _start := Vector2.ZERO
var _end := Vector2.ZERO
var _arc := 0.0
var _flight := 1.0
var _t := 0.0
var _shadow_y := 0.0


# =========================================================
# สร้าง
# =========================================================
## ยิงตรงจากตัวมอน — facing: 1 = ขวา · -1 = ซ้าย
static func fire_straight(d: MonsterData, caster: Node2D, facing: int, origin: Vector2 = Vector2.INF, target: Vector2 = Vector2.INF) -> MonsterProjectile:
	if d == null or d.projectile_texture == null:
		return null
	var p := MonsterProjectile.new()
	p.data = d
	p.mode = Mode.STRAIGHT
	p._dir = 1 if facing > 0 else -1
	p._speed = d.projectile_speed
	p._range = d.projectile_range
	p._hit_size = d.projectile_hit_size
	p._spin = d.projectile_spin
	var foot: Vector2 = caster.foot_position() if caster.has_method("foot_position") else caster.global_position
	p.global_position = foot + Vector2(d.projectile_offset.x * p._dir, d.projectile_offset.y)
	if origin != Vector2.INF:
		p.global_position = origin
	p._velocity_direction = Vector2(p._dir,0)
	if target != Vector2.INF and p.global_position.distance_to(target) > .01:
		p._velocity_direction = (target-p.global_position).normalized()
		p.rotation = p._velocity_direction.angle() - (PI if p._dir < 0 else 0.0)
	p._build_sprite(d.projectile_texture, d.projectile_height, d.projectile_faces_left)
	_add_to_map(caster, p)
	if d.projectile_fire_effect:
		FIRE_BURST.spawn(p.get_parent(),p.global_position,p._dir)
	return p


## ขว้างโค้งไปตกที่ target (จุดเท้าผู้เล่น) แล้วระเบิด
static func fire_lob(d: MonsterData, caster: Node2D, target: Vector2) -> MonsterProjectile:
	if d == null or d.skill_projectile_texture == null:
		return null
	var p := MonsterProjectile.new()
	p.data = d
	p.mode = Mode.LOB
	var foot: Vector2 = caster.foot_position() if caster.has_method("foot_position") else caster.global_position
	p._dir = 1 if target.x >= foot.x else -1
	p._start = foot + Vector2(d.skill_projectile_offset.x * p._dir, d.skill_projectile_offset.y)
	p._end = target
	p._arc = d.skill_projectile_arc
	p._flight = maxf(0.15, d.skill_projectile_time)
	p._spin = d.skill_projectile_spin
	p._shadow_y = target.y
	p.global_position = p._start
	p._build_sprite(d.skill_projectile_texture, d.skill_projectile_height, false)
	_add_to_map(caster, p)
	return p


static func _add_to_map(caster: Node2D, p: MonsterProjectile) -> void:
	var parent: Node = caster.get_tree().current_scene if caster.get_tree() != null else caster.get_parent()
	if parent == null:
		parent = caster.get_parent()
	p.z_index = 70
	parent.add_child(p)


func _build_sprite(tex: Texture2D, height: float, faces_left: bool) -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = tex
	var k: float = height / maxf(1.0, float(tex.get_height()))
	_sprite.scale = Vector2(k, k)
	# รูปต้นฉบับหันซ้าย → ยิงไปขวาต้องพลิก
	_sprite.flip_h = faces_left and _dir > 0
	if data != null and data.projectile_fire_effect and mode == Mode.STRAIGHT:
		var material := ShaderMaterial.new()
		material.shader = FIRE_SHADER
		_sprite.material = material
		# The glowing head, not the tail's canvas center, is the collision origin.
		_sprite.position.x = -_dir * float(tex.get_width()) * .24 * k
	add_child(_sprite)
	if _hit_size == Vector2.ZERO:
		_hit_size = tex.get_size() * k * 0.7
	if data != null and data.projectile_fire_effect and mode == Mode.STRAIGHT:
		return
	# โผล่มาแบบเด้งเล็กน้อย
	_sprite.scale = Vector2(k, k) * 0.4
	var tw := create_tween()
	tw.tween_property(_sprite, "scale", Vector2(k, k), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# =========================================================
# เคลื่อนที่
# =========================================================
func _process(delta: float) -> void:
	if _done:
		return
	if _spin != 0.0 and _sprite != null:
		_sprite.rotation += _spin * TAU * delta * _dir

	if mode == Mode.STRAIGHT:
		var step: float = _speed * delta
		var previous := global_position
		position += _velocity_direction * step
		_travelled += step
		# Fireballs sweep the travelled segment so low FPS cannot skip a wall/player.
		if data.projectile_fire_effect:
			var query := PhysicsRayQueryParameters2D.create(previous,global_position)
			query.collision_mask = 1
			var wall := get_world_2d().direct_space_state.intersect_ray(query)
			var end: Vector2 = wall.position if not wall.is_empty() else global_position
			if _swept_player(previous,end):
				_hit_player_direct()
				_pop(&"player")
				return
			if not wall.is_empty():
				global_position = end
				_pop(&"terrain")
				return
		if _hits_player():
			_hit_player_direct()
			_pop(&"player")
			return
		if _travelled >= _range or _hits_terrain():
			_pop()
			return
	else:
		_t += delta / _flight
		var u: float = minf(1.0, _t)
		# เส้นตรงจากจุดปล่อยไปเป้า + โค้งพาราโบลาขึ้นตรงกลาง
		global_position = _start.lerp(_end, u) + Vector2(0, -_arc * 4.0 * u * (1.0 - u))
		queue_redraw()
		if _t >= 1.0:
			_explode()


## เงาบนพื้นใต้บอล (เฉพาะแบบโค้ง) — เล็กลงตอนบอลอยู่สูง
func _draw() -> void:
	if mode != Mode.LOB or _done:
		return
	var h: float = maxf(0.0, _shadow_y - global_position.y)
	var k: float = clampf(1.0 - h / 500.0, 0.35, 1.0)
	var r := Vector2(38.0 * k, 12.0 * k)
	draw_set_transform(Vector2(0, h), 0.0, r)
	draw_circle(Vector2.ZERO, 1.0, Color(0, 0, 0, 0.35 * k))


# =========================================================
# ชน
# =========================================================
func _player_rect() -> Rect2:
	var p := get_tree().get_first_node_in_group("player")
	if p == null or PlayerState.is_dead():
		return Rect2()
	if p.has_method("body_rect"):
		return p.body_rect()
	var f: Vector2 = p.foot_position() if p.has_method("foot_position") else p.global_position
	var h: float = float(p.auto_fit_height) if "auto_fit_height" in p and p.auto_fit_height > 0.0 else 200.0
	return Rect2(f.x - h * 0.16, f.y - h, h * 0.32, h)


func _hits_player() -> bool:
	var pr := _player_rect()
	if pr.size == Vector2.ZERO:
		return false
	var mine := Rect2(global_position - _hit_size * 0.5, _hit_size)
	return mine.intersects(pr, true)


func _swept_player(start: Vector2, finish: Vector2) -> bool:
	var rect := _player_rect()
	if not rect.has_area(): return false
	# Minkowski expansion turns the ball's box into a point/rectangle sweep.
	rect = Rect2(rect.position-_hit_size*.5,rect.size+_hit_size)
	var delta := finish-start
	var enter := 0.0
	var leave := 1.0
	for axis in range(2):
		if absf(delta[axis]) < .0001:
			if start[axis] < rect.position[axis] or start[axis] > rect.end[axis]: return false
		else:
			var a := (rect.position[axis]-start[axis])/delta[axis]
			var b := (rect.end[axis]-start[axis])/delta[axis]
			enter = maxf(enter,minf(a,b))
			leave = minf(leave,maxf(a,b))
			if enter > leave: return false
	global_position = start.lerp(finish,enter)
	return true


func _hits_terrain() -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + _velocity_direction * _hit_size.x * 0.5)
	q.collision_mask = 1
	return not space.intersect_ray(q).is_empty()


## ยิงตรง: ดาเมจเท่าโจมตีปกติ
func _hit_player_direct() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p == null or data == null:
		return
	var result := Combat.monster_hits_player(data, PlayerState.stats)
	if result.miss:
		Events.floating_text(p.global_position + Vector2(0, -40), "MISS", Color("#cccccc"), 20, 3)
		return
	if p.has_method("take_damage"):
		p.take_damage(maxi(1, int(round(result.damage * damage_mult))), data.knockback_force, _dir)


## ขว้างโค้ง: ระเบิดที่จุดตก ทำดาเมจถ้าผู้เล่นอยู่ในรัศมีสกิล
func _explode() -> void:
	if _done:
		return
	_done = true
	queue_redraw()
	_spawn_burst(_end)

	var p := get_tree().get_first_node_in_group("player")
	if p != null and not PlayerState.is_dead() and data != null:
		var pf: Vector2 = p.foot_position() if p.has_method("foot_position") else p.global_position
		var diff: Vector2 = pf - _end
		if absf(diff.x) <= data.skill_radius_x and absf(diff.y) <= data.skill_radius_y:
			var result := Combat.monster_hits_player(data, PlayerState.stats)
			var dmg := maxi(1, int(round(result.damage * data.skill_damage_mult)))
			if p.has_method("take_damage"):
				p.take_damage(dmg, data.skill_knockback, signi(int(signf(diff.x))) if diff.x != 0.0 else _dir)
		else:
			Events.floating_text(p.global_position + Vector2(0, -40), "หลบได้!", Color("#cccccc"), 20, 3)

	# บอลหายวับพร้อมระเบิด
	if _sprite != null:
		_sprite.visible = false
	await get_tree().create_timer(0.05).timeout
	queue_free()


## เอฟเฟกต์ระเบิด — ใช้ SpriteFrames ที่ตั้งไว้ หรือชีท slime_burst.png ที่ทำให้
func _spawn_burst(at: Vector2) -> void:
	var frames: SpriteFrames = data.skill_explosion_frames if data != null else null
	var anim: StringName = data.skill_explosion_anim if data != null else &"burst"
	if frames == null:
		frames = _default_burst_frames()
		anim = &"burst"
	if frames == null or not frames.has_animation(anim):
		return
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = frames
	fx.z_index = 80
	var tex := frames.get_frame_texture(anim, 0)
	var k: float = 1.0
	if tex != null and tex.get_height() > 0:
		k = data.skill_explosion_height / float(tex.get_height())
	fx.scale = Vector2(k, k)
	# วางให้ขอบล่างของเอฟเฟกต์อยู่ที่พื้นพอดี
	fx.global_position = at + Vector2(0, -data.skill_explosion_height * BURST_LIFT)
	get_parent().add_child(fx)
	fx.play(anim)
	fx.animation_finished.connect(fx.queue_free)


static var _burst_cache: SpriteFrames

static func _default_burst_frames() -> SpriteFrames:
	if _burst_cache != null:
		return _burst_cache
	if not ResourceLoader.exists(DEFAULT_BURST):
		return null
	var tex: Texture2D = load(DEFAULT_BURST)
	var f := SpriteFrames.new()
	f.add_animation(&"burst")
	f.set_animation_loop(&"burst", false)
	f.set_animation_speed(&"burst", 18.0)
	# ★ รอบ 82 ★ ช่องกว้าง = กว้างภาพ / จำนวนเฟรม · สูง = สูงภาพเต็ม
	# ชีทเก่าเป็น 8 ช่องจัตุรัส 256 ชีทใหม่ 8 ช่อง 285x198 — สูตรนี้ใช้ได้ทั้งคู่
	var cell_w: float = float(tex.get_width()) / float(BURST_FRAMES)
	var cell_h: float = float(tex.get_height())
	for i in range(BURST_FRAMES):
		var a := AtlasTexture.new()
		a.atlas = tex
		a.region = Rect2(roundf(i * cell_w), 0.0, roundf((i + 1) * cell_w) - roundf(i * cell_w), cell_h)
		f.add_frame(&"burst", a)
	_burst_cache = f
	return f


## กระสุนตรงหายไปแบบแตกเป็นประกาย
func _pop(kind: StringName = &"expired") -> void:
	if _done:
		return
	_done = true
	impacted.emit(kind,global_position)
	set_process(false)
	if data != null and data.projectile_fire_effect:
		FIRE_BURST.spawn(get_parent(),global_position,_dir,true)
	if _sprite == null:
		queue_free()
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_sprite, "scale", _sprite.scale * 1.6, 0.12)
	tw.tween_property(_sprite, "modulate:a", 0.0, 0.12)
	tw.chain().tween_callback(queue_free)
