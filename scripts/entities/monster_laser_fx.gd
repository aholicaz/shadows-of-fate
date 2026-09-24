## ★ รอบ 178 ★ เลเซอร์ยิงออกจากมือมอน (ราชินีหนาม)
## ยิงตามจังหวะเฟรมที่ตั้งใน Attack Hit Frames · พุ่งออกแนวนอนตามภาพท่าตี เร็วมาก ยาวไกล
## แล้ว "ฟาด" ลงหาตัวผู้เล่น (Laser Sweep Time) · ชนพื้น/ผนังแล้วหยุดตรงนั้น
## ดาเมจ = โจมตีปกติของมอน (Combat.monster_hits_player) · โดนผู้เล่นได้ครั้งเดียวต่อการยิง 1 ครั้ง
## ช่วงพุ่ง/ฟาด/ค้าง ถ้าผู้เล่นอยู่ในลำแสงก็โดน · พุ่งหลบ (อมตะ) ผ่านได้
class_name MonsterLaserFX
extends Node2D

var data: MonsterData
var target: Node2D
var start_angle := PI          ## มุมตอนพุ่งออก (แนวนอนตามทิศที่หัน)
var aim_angle := PI            ## มุมที่ฟาดลงไปหา
var max_length := 1000.0
var width := 30.0
var hit_height := 56.0
var extend_time := 0.06
var sweep_time := 0.08
var hold_time := 0.12
var fade_time := 0.22
var color := Color(0.93, 0.25, 0.42)
var core := Color(1.0, 0.95, 0.98)
var damage_mult := 1.0
var knockback := 300.0
var age := 0.0
var hit_player := false        ## (ไว้ให้เทสต์เช็ก) รอบนี้โดนผู้เล่นแล้วหรือยัง
var impact := false            ## ปลายลำแสงชนพื้น/ผนังอยู่ไหม (คิดใหม่ทุกเฟรม)

var _limit := 1000.0           ## ความยาวที่ถูกพื้น/ผนังตัด ณ มุมปัจจุบัน
var _exclude: Array[RID] = []
var _sparks: Array[Dictionary] = []
var _wisps: Array[Vector3] = []   ## ตำแหน่ง(สัดส่วน), ฝั่ง(±1), ความยาว — หนามแดงเข้มเลียบขอบลำแสง
var _rng := RandomNumberGenerator.new()
var _impact_burst := false


## src = มอนที่ยิง (MonsterBase) · from = จุดมือ (พิกัดโลก) · aim = ทิศที่จะฟาดลงไปหา
static func fire(src, from: Vector2, aim: Vector2, target_node: Node2D, mult: float) -> MonsterLaserFX:
	var d: MonsterData = src.data
	var fx := MonsterLaserFX.new()
	fx.data = d
	fx.target = target_node
	var face := float(src.facing) if float(src.facing) != 0.0 else -1.0
	fx.start_angle = Vector2(face, 0.0).angle()
	fx.aim_angle = aim.angle() if aim.length() > 0.01 else fx.start_angle
	fx.width = d.laser_width
	fx.hit_height = d.laser_hit_height
	fx.extend_time = d.laser_extend_time
	fx.sweep_time = d.laser_sweep_time
	fx.hold_time = d.laser_hold_time
	fx.fade_time = d.laser_fade_time
	fx.color = d.laser_color
	fx.core = d.laser_core_color
	fx.damage_mult = mult
	fx.knockback = d.knockback_force
	fx.max_length = d.laser_length
	fx._limit = d.laser_length
	if src is CollisionObject2D:
		fx._exclude.append(src.get_rid())
	fx.position = from
	fx.rotation = fx.start_angle
	fx.set_meta("ignore_map_bounds", true)
	src.get_parent().add_child(fx)
	return fx


func _ready() -> void:
	z_index = 60
	add_to_group("monster_laser_fx")
	_rng.seed = int(position.x * 13.0 + position.y * 7.0) + Time.get_ticks_msec()
	var n := int(clampf(max_length / 70.0, 4.0, 18.0))
	for i in range(n):
		_wisps.append(Vector3(_rng.randf_range(0.05, 0.95), -1.0 if i % 2 == 0 else 1.0, _rng.randf_range(40.0, 110.0)))
	_update_limit()
	# ประกายตรงมือตอนปล่อย
	_burst(Vector2.ZERO, 10, 260.0, 520.0, PI * 0.9, 0.0)


func _process(delta: float) -> void:
	age += delta
	rotation = current_angle()
	_update_limit()
	if not hit_player and age <= extend_time + sweep_time + hold_time:
		_check_hit()
	if impact and not _impact_burst and age >= extend_time + sweep_time:
		_impact_burst = true
		_burst(Vector2(current_length(), 0.0), 14, 220.0, 560.0, PI * 0.8, PI)
	for s in _sparks:
		s.life -= delta
		s.pos += s.vel * delta
		s.vel *= 0.90
	_sparks.assign(_sparks.filter(func(s): return s.life > 0.0))
	queue_redraw()
	if age >= extend_time + sweep_time + hold_time + fade_time:
		queue_free()


## มุมปัจจุบัน: พุ่งแนวนอนก่อน แล้วฟาดลงหาเป้า (ease-in-out)
func current_angle() -> float:
	var t := clampf((age - extend_time) / maxf(0.001, sweep_time), 0.0, 1.0)
	return lerp_angle(start_angle, aim_angle, t * t * (3.0 - 2.0 * t))


## ความยาวปัจจุบัน — พุ่งออกแบบ ease-out (เร็วมากช่วงแรก) · ไม่เกินจุดที่ชนพื้น/ผนัง
func current_length() -> float:
	var t := clampf(age / maxf(0.001, extend_time), 0.0, 1.0)
	return minf(max_length * (1.0 - pow(1.0 - t, 3.0)), _limit)


## ยิงเรย์หาพื้น/ผนัง (เลเยอร์ 1 เหมือนพื้นที่ใช้กับท่าทุบ) ตามมุมปัจจุบัน
func _update_limit() -> void:
	if not is_inside_tree():
		return
	var d := Vector2.from_angle(rotation)
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + d * max_length, 1)
	q.exclude = _exclude
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		_limit = max_length
		impact = false
	else:
		_limit = maxf(20.0, global_position.distance_to(hit.position))
		impact = true


## รอยกวาดชัดตอนกำลังฟาด แล้วจางภายใน 0.25 วิ
func _trail_alpha() -> float:
	if sweep_time <= 0.0 or absf(wrapf(aim_angle - start_angle, -PI, PI)) < 0.05:
		return 0.0
	var t0 := age - extend_time
	if t0 <= 0.0:
		return 0.0
	var t1 := t0 - sweep_time
	if t1 <= 0.0:
		return 1.0
	return clampf(1.0 - t1 / 0.25, 0.0, 1.0)


func _fade() -> float:
	var t := age - extend_time - sweep_time - hold_time
	if t <= 0.0:
		return 1.0
	return clampf(1.0 - t / maxf(0.001, fade_time), 0.0, 1.0)


## กล่องโดนของผู้เล่น = กล่องชนจริง (CollisionShape2D) · ไม่มีก็ประมาณจากเท้า
func _target_rect() -> Rect2:
	var col := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null and col.shape != null:
		return col.global_transform * col.shape.get_rect()
	var f: Vector2 = target.foot_position() if target.has_method("foot_position") else target.global_position
	return Rect2(f.x - 22.0, f.y - 110.0, 44.0, 110.0)


func _check_hit() -> void:
	if target == null or not is_instance_valid(target) or PlayerState.is_dead():
		return
	var rect := _target_rect().grow(hit_height * 0.5)
	var d := Vector2.from_angle(rotation)
	var reach := current_length()
	var s := 0.0
	var touched := false
	while s <= reach:
		if rect.has_point(global_position + d * s):
			touched = true
			break
		s += 12.0
	if not touched:
		return
	hit_player = true
	var result := Combat.monster_hits_player(data, PlayerState.stats)
	if result.miss:
		Events.floating_text(target.global_position + Vector2(0, -40), "MISS", Color("#cccccc"), 20, 3)
		return
	if target.has_method("take_damage"):
		var side := 1 if d.x >= 0.0 else -1
		target.take_damage(maxi(1, int(round(result.damage * damage_mult))), knockback, side)
	_burst(Vector2(s, 0.0), 8, 200.0, 420.0, PI * 0.7, PI)


func _burst(at: Vector2, count: int, v_min: float, v_max: float, spread: float, base_angle: float) -> void:
	for i in range(count):
		var a := base_angle + _rng.randf_range(-spread, spread)
		_sparks.append({
			"pos": at,
			"vel": Vector2.from_angle(a) * _rng.randf_range(v_min, v_max),
			"life": _rng.randf_range(0.14, 0.32),
			"max": 0.32,
		})


func _draw() -> void:
	var L := current_length()
	var a := _fade()
	var flick := 1.0 + 0.10 * sin(age * 70.0)
	var w := width * flick * lerpf(0.25, 1.0, a)
	var outer := color.darkened(0.45)
	var end := Vector2(L, 0.0)
	# ── เรืองรอบนอก (ชมพูแดงอมเลือด) ──
	draw_line(Vector2.ZERO, end, Color(outer, 0.16 * a), w * 2.6)
	draw_line(Vector2.ZERO, end, Color(color, 0.28 * a), w * 1.8)
	# ── หนามแดงเข้มเลียบขอบ (เหมือนลำแสงในภาพท่าตี) ──
	for wv in _wisps:
		var x0: float = wv.x * L
		var side: float = wv.y
		var ln: float = wv.z
		draw_line(Vector2(x0, side * w * 0.45), Vector2(minf(L, x0 + ln), side * w * 0.95), Color(outer, 0.55 * a), 3.0)
	# ── รอยกวาด (ภาพติดตาตอนฟาดลง) — ต่อเนื่องกับลำแสงแนวนอนในภาพท่าตี ──
	var trail := _trail_alpha()
	if trail > 0.01:
		var rel := wrapf(start_angle - rotation, -PI, PI)
		for i in range(1, 11):
			var f := float(i) / 10.0
			var ang := rel * f
			var tl := minf(L, max_length) * lerpf(0.9, 0.55, f)
			var tip := Vector2.from_angle(ang) * tl
			draw_line(Vector2.ZERO, tip, Color(color, 0.16 * trail * (1.0 - f * 0.6)), w * lerpf(0.9, 0.5, f))
			draw_line(Vector2.ZERO, tip * 0.8, Color(core, 0.12 * trail * (1.0 - f * 0.7)), w * 0.22)
	# ── ตัวลำแสง ──
	draw_line(Vector2.ZERO, end, Color(color, 0.95 * a), w)
	draw_line(Vector2.ZERO, end, Color(core.lerp(color, 0.35), a), w * 0.55)
	draw_line(Vector2.ZERO, end, Color(core, a), w * 0.26)
	# ── คลื่นพลังวิ่งตามลำแสง ──
	if L > 60.0:
		for k in range(5):
			var x := fmod(age * 2600.0 + k * L / 5.0, L)
			draw_line(Vector2(maxf(0.0, x - 70.0), 0.0), Vector2(x, 0.0), Color(1, 1, 1, 0.55 * a), w * 0.30)
	# ── แสงวาบที่มือ ──
	var flash := clampf(1.0 - age / (extend_time + sweep_time + hold_time), 0.0, 1.0)
	draw_circle(Vector2.ZERO, w * (0.8 + 0.6 * flash), Color(color, 0.40 * a))
	draw_circle(Vector2.ZERO, w * 0.5, Color(core, a))
	# ── หัวลำแสง / จุดชนพื้น ──
	if age < extend_time or impact:
		var tip_r := w * (0.55 if age < extend_time else 0.75 * flick)
		draw_circle(end, tip_r * 1.7, Color(color, 0.30 * a))
		draw_circle(end, tip_r * 0.7, Color(core, a))
	# ── ประกาย ──
	for s in _sparks:
		var k: float = clampf(s.life / s.max, 0.0, 1.0)
		var tail: Vector2 = s.vel.normalized() * (8.0 + 22.0 * k)
		draw_line(s.pos - tail, s.pos, Color(core.lerp(color, 1.0 - k), k), 2.5)
