extends Node2D
## ★ รอบ 181 ★ ชุดสกิล Ninth Edge ใหม่ — ทุกท่าขยับตัว (วาร์ป · ดึง · หมุนเดิน · วาร์ปฟันไล่เป้า)
## ไม่ต้องมีรูนก่อนใช้ · รูนที่สะสมไว้ถูกใช้เองเป็นโบนัสดาเมจของท่าใหญ่ (runeblade_combat.spend_runes)
## โหนดนี้เป็นลูกของ runeblade_combat — runeblade_combat.cast() ส่งสกิลใน IDS มาที่ cast()

const IDS := [&"erasing_step", &"oathchain", &"ninefold_cyclone", &"erasing_cut", &"twin_inscription", &"ninth_inscription"]
## ท่าที่ร่างเงาสะท้อนทำตาม (อัลติไม่ตาม)
const MIRRORED := [&"erasing_step", &"oathchain", &"ninefold_cyclone", &"erasing_cut"]
## ยืมท่าของ Runeblade ไปก่อน จนกว่าจะมีสไปรท์ Ninth Edge ของจริง
const POSES := {
	&"erasing_step": "Lunge_Runeblade", &"oathchain": "Wave_Runeblade", &"ninefold_cyclone": "Flurry_Runeblade",
	&"erasing_cut": "Erasing_Runeblade", &"twin_inscription": "Wave_Runeblade", &"ninth_inscription": "Lunge_Runeblade",
}
const SLICES := ["Flurry_Runeblade_1", "Flurry_Runeblade_2", "Flurry_Runeblade_3"]

const STEP_RECAST_WINDOW := 1.2   ## กดก้าวลบเงาซ้ำฟรีภายในกี่วิ
const STEP_RECAST_POWER := 0.6
const STEP_SCAR_DELAY := 0.5      ## รอยแผลระเบิดหลังวาร์ปกี่วิ
const STEP_IFRAME := 0.25
const CHAIN_RANGE := 800.0
const CHAIN_PULL_RADIUS := 320.0
const CHAIN_STUN := 0.8
const CYCLONE_TIME := 2.5
const CYCLONE_TICKS := 9
const CYCLONE_RADIUS := 280.0
const CYCLONE_SUCTION := 420.0
const CYCLONE_MOVE := 0.8         ## เดินได้ 80% ของความเร็วปกติระหว่างหมุน
const CUT_LUNGE := 260.0
const SHADE_TIME := 10.0
const SHADE_REACH := 480.0
const VERDICT_RANGE := 900.0
const VERDICT_HITS := 9
const VERDICT_RADIUS := 500.0
const VERDICT_GAP := 0.13

var rb: Node2D
var player: Node2D
var step_recast_ms := 0
var step_recast_ready := false
var cyclone_left := 0.0
var cyclone_seq := -1
var cyclone_cancelled := false
var shade: AnimatedSprite2D
var shade_foot := Vector2.ZERO
var shade_time := 0.0
var shade_lv := 0

func setup(owner_rb: Node2D) -> void:
	rb = owner_rb
	player = rb.player

func handles(id: StringName) -> bool:
	return id in IDS

## ตัวเลขของแต่ละท่า (ใช้ทั้งในเกมและหน้าสกิล)
static func step_scar(lv: int) -> float: return 3.8 + 0.8 * (lv - 1)
static func cyclone_tick(lv: int) -> float: return 1.1 + 0.2 * (lv - 1)
static func cyclone_finale(lv: int) -> float: return 4.0 + 1.0 * (lv - 1)
static func shade_power(lv: int) -> float: return 0.35 + 0.05 * lv
static func verdict_hit(lv: int) -> float: return 2.6 + 0.3 * (lv - 1)
static func verdict_finale(lv: int) -> float: return 18.0 + 2.5 * (lv - 1)

## ก้าวลบเงากดซ้ำได้ฟรีไหม (เช็กก่อน can_use_skill เพราะคูลดาวน์เริ่มไปแล้ว)
func can_recast(id: StringName) -> bool:
	return id == &"erasing_step" and step_recast_ready and Time.get_ticks_msec() <= step_recast_ms \
		and PlayerState.skills.level_of(id) > 0

func cast(id: StringName, s: SkillData, lv: int, rune_mult: float, recast: bool = false) -> void:
	match id:
		&"erasing_step": _erasing_step(s, lv, recast)
		&"oathchain": _oathchain(s, lv, rune_mult)
		&"ninefold_cyclone": _cyclone(s, lv, rune_mult)
		&"erasing_cut": _erasing_cut(s, lv, rune_mult)
		&"twin_inscription": _mirror_shade(lv)
		&"ninth_inscription": _verdict(lv, rune_mult)

# ---------------------------------------------------------
# ตัวช่วย
# ---------------------------------------------------------
func _world() -> Node:
	return player.get_parent()

func _begin(id: StringName) -> int:
	rb.casting = true
	player.is_attacking = true
	player._attack_seq += 1
	player._rb_attack_tag = id
	player.velocity.x = 0
	player.reset_combo()
	_pose(id)
	return player._attack_seq

func _pose(id: StringName) -> void:
	var name: String = POSES.get(id, "")
	if name == "" or not player._has_anim(name): name = player.skill_animation(id)
	player._play(name, true)
	player.sprite.speed_scale = 1.0

func _slice(i: int) -> void:
	var name: String = SLICES[i % SLICES.size()]
	if player._has_anim(name):
		player._play(name, true)
		player.sprite.speed_scale = maxf(0.1, player._anim_length(name) / 0.22)

func _alive(seq: int) -> bool:
	return is_instance_valid(player) and not player._dead and seq == player._attack_seq

func _wait(sec: float, seq: int) -> bool:
	await get_tree().create_timer(sec).timeout
	return _alive(seq)

func _enemies() -> Array:
	var out: Array = []
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e) or not e.has_method("take_damage_from_player"): continue
		if e.has_method("is_dead") and e.is_dead(): continue
		out.append(e)
	return out

func _foot(e: Node) -> Vector2:
	return e.foot_position() if e.has_method("foot_position") else e.global_position

func _is_boss(e: Node) -> bool:
	var d = e.get("data")
	return d != null and bool(d.get("is_boss"))

func _clear(from: Vector2, to: Vector2) -> bool:
	var ray := PhysicsRayQueryParameters2D.create(from - Vector2(0, 80), Vector2(to.x, from.y - 80), 1)
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

## เลื่อนไปถึง dest_x ได้แค่ไหนก่อนชนกำแพง
func _wall_clamp(from: Vector2, dest_x: float) -> float:
	var ray := PhysicsRayQueryParameters2D.create(from - Vector2(0, 80), Vector2(dest_x, from.y - 80), 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(ray)
	if hit.is_empty(): return dest_x
	return hit.position.x - signf(dest_x - from.x) * 36.0

func _hit(e: Node, mult: float, source: StringName) -> void:
	if not is_instance_valid(e) or (e.has_method("is_dead") and e.is_dead()): return
	var dir := 1 if e.global_position.x >= player.global_position.x else -1
	e.take_damage_from_player(mult, false, dir, 0.0, 0.0, source)

## ฟันทุกตัวในกรอบรอบจุด (ซ้าย-ขวาเท่ากัน)
func _area(center: Vector2, radius: float, mult: float, source: StringName, cap: int) -> Array:
	var box := Rect2(center.x - radius, center.y - 320, radius * 2.0, 350)
	var list := _enemies()
	list.sort_custom(func(a, b): return absf(a.global_position.x - center.x) < absf(b.global_position.x - center.x))
	var hit: Array = []
	for e in list:
		if not box.intersects(player.enemy_rect(e), true): continue
		if not _clear(center, _foot(e)): continue
		_hit(e, mult, source)
		hit.append(e)
		if hit.size() >= cap: break
	return hit

func _pull(e: Node, dest_x: float, time: float) -> void:
	var x := _wall_clamp(_foot(e), dest_x)
	var tw := e.create_tween()
	tw.tween_property(e, "global_position:x", x, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# ---------------------------------------------------------
# 1) ก้าวลบเงา — วาร์ปทะลุ 450 · อมตะ 0.25 วิ · รอยแผลระเบิดตามหลัง · กดซ้ำได้ใน 1.2 วิ
# ---------------------------------------------------------
func _erasing_step(s: SkillData, lv: int, recast: bool) -> void:
	var seq := _begin(&"erasing_step")
	var power := STEP_RECAST_POWER if recast else 1.0
	var dir: int = player.facing
	var start: Vector2 = player.foot_position()
	player._iframe = maxf(player._iframe, STEP_IFRAME)
	player._start_dash(s, lv)
	player._dash_mult *= power
	player._play_skill_sfx(&"erasing_step")
	preload("res://scripts/entities/ninth_motion_fx.gd").spawn(_world(), start, "blink", 0.3)
	while player._dash_time > 0.0:
		await get_tree().physics_frame
		if not _alive(seq): break
	var finish: Vector2 = player.foot_position()
	preload("res://scripts/entities/ninth_motion_fx.gd").spawn(_world(), finish, "blink", 0.3)
	_scar(start, finish, step_scar(lv) * power)
	step_recast_ready = not recast
	step_recast_ms = Time.get_ticks_msec() + int(STEP_RECAST_WINDOW * 1000.0)
	if not recast: Events.floating_text(finish + Vector2(0, -170), "กดซ้ำได้!", Color("#cdb6ff"), 16, 0)
	_mirror(&"erasing_step", (s.damage_mult(lv) + step_scar(lv)) * power, dir)
	await get_tree().create_timer(0.06).timeout
	rb._finish(seq)

func _scar(start: Vector2, finish: Vector2, mult: float) -> void:
	preload("res://scripts/entities/ninth_motion_fx.gd").spawn(_world(), start, "scar", STEP_SCAR_DELAY + 0.12, {"b": finish - start})
	var left := minf(start.x, finish.x) - 60.0
	var box := Rect2(left, minf(start.y, finish.y) - 320, absf(finish.x - start.x) + 120.0, 350 + absf(finish.y - start.y))
	get_tree().create_timer(STEP_SCAR_DELAY).timeout.connect(func() -> void:
		if not is_instance_valid(self) or not is_instance_valid(player) or player._dead: return
		for e in _enemies():
			if box.intersects(player.enemy_rect(e), true): _hit(e, mult, &"erasing_step")
		preload("res://scripts/entities/ninth_edge_fx.gd").spawn(_world(), (start + finish) * 0.5, 1, maxf(160.0, absf(finish.x - start.x) * 0.5), true))

# ---------------------------------------------------------
# 2) โซ่พันธะ — ดึงฝูงรอบเป้ามากองตรงหน้า + สตัน · บอสดึงไม่ไหว ตัวเราถูกดึงเข้าไปแทน
# ---------------------------------------------------------
func _chain_target(origin: Vector2, dir: int) -> Node:
	var best: Node = null
	var best_d := INF
	for e in _enemies():
		var f := _foot(e)
		var dx := (f.x - origin.x) * dir
		if dx < -40.0 or dx > CHAIN_RANGE or absf(f.y - origin.y) > 260.0: continue
		if not _clear(origin, f): continue
		if dx < best_d:
			best_d = dx
			best = e
	return best

func _oathchain(s: SkillData, lv: int, rune_mult: float) -> void:
	var seq := _begin(&"oathchain")
	var dir: int = player.facing
	var origin: Vector2 = player.foot_position()
	var target := _chain_target(origin, dir)
	var hand := origin + Vector2(dir * 50, -110)
	var tip: Vector2 = (_foot(target) + Vector2(0, -90)) if target != null else origin + Vector2(dir * CHAIN_RANGE, -110)
	player._play_skill_sfx(&"oathchain")
	preload("res://scripts/entities/ninth_motion_fx.gd").spawn(_world(), hand, "chain", 0.36, {"b": tip - hand})
	if not await _wait(0.16, seq):
		rb._finish(seq)
		return
	var mult := s.damage_mult(lv) * rune_mult
	if target == null or not is_instance_valid(target):
		await _wait(0.12, seq)
		rb._finish(seq)
		return
	if _is_boss(target):
		_hit(target, mult, &"oathchain")
		var gap := absf(target.global_position.x - player.global_position.x) - 140.0
		if gap > 0.0:
			rb.approach_left = gap
			rb.approach_dir = dir
		while rb.approach_left > 0.0:
			await get_tree().physics_frame
			if not _alive(seq):
				rb._finish(seq)
				return
	else:
		var group: Array = []
		for e in _enemies():
			if not _is_boss(e) and e.global_position.distance_to(target.global_position) <= CHAIN_PULL_RADIUS: group.append(e)
		group.sort_custom(func(a, b): return absf(a.global_position.x - origin.x) < absf(b.global_position.x - origin.x))
		var until := Time.get_ticks_msec() + int((CHAIN_STUN + 0.18) * 1000.0)
		for i in group.size():
			_pull(group[i], origin.x + dir * (120.0 + 34.0 * i), 0.18)
			group[i].set_meta("rb_stun_until", until)
		if not await _wait(0.18, seq):
			rb._finish(seq)
			return
		for e in group: _hit(e, mult, &"oathchain")
		Events.floating_text(origin + Vector2(dir * 140, -200), "พันธนาการ!", Color("#cdb6ff"), 18, 0)
	_mirror(&"oathchain", mult, dir)
	await _wait(0.1, seq)
	rb._finish(seq)

# ---------------------------------------------------------
# 3) กงจักรนามเก้า — หมุน 2.5 วิ เดินได้ 80% · 9 ครั้ง + ปิดท้าย · ดูดมอนเข้ามา · กดหลบยกเลิกได้
# ---------------------------------------------------------
func _cyclone(_s: SkillData, lv: int, rune_mult: float) -> void:
	var seq := _begin(&"ninefold_cyclone")
	cyclone_seq = seq
	cyclone_left = CYCLONE_TIME
	cyclone_cancelled = false
	player._play_skill_sfx(&"ninefold_cyclone")
	var ring := preload("res://scripts/entities/ninth_motion_fx.gd").spawn(_world(), player.foot_position(), "ring", CYCLONE_TIME,
		{"radius": CYCLONE_RADIUS, "follow": player})
	var interval := CYCLONE_TIME / float(CYCLONE_TICKS + 1)
	var tick := cyclone_tick(lv) * rune_mult
	for i in CYCLONE_TICKS:
		await get_tree().create_timer(interval).timeout
		if cyclone_cancelled or not _alive(seq): break
		_slice(i)
		_area(player.foot_position(), CYCLONE_RADIUS, tick, &"ninefold_cyclone", 12)
		_suction()
	if not cyclone_cancelled and _alive(seq):
		await get_tree().create_timer(interval).timeout
		if not cyclone_cancelled and _alive(seq):
			var finale := cyclone_finale(lv) * rune_mult
			_area(player.foot_position(), CYCLONE_RADIUS * 1.15, finale, &"ninefold_cyclone", 12)
			preload("res://scripts/entities/ninth_motion_fx.gd").spawn(_world(), player.foot_position(), "burst", 0.45, {"radius": CYCLONE_RADIUS * 1.15})
			_mirror(&"ninefold_cyclone", finale, player.facing)
	cyclone_left = 0.0
	if is_instance_valid(ring): ring.queue_free()
	if not cyclone_cancelled: rb._finish(seq)

func _suction() -> void:
	var center: Vector2 = player.foot_position()
	for e in _enemies():
		if _is_boss(e): continue
		var dx: float = e.global_position.x - center.x
		if absf(dx) > CYCLONE_SUCTION or absf(dx) < 90.0: continue
		_pull(e, e.global_position.x - signf(dx) * minf(45.0, absf(dx) - 80.0), 0.15)

## เรียกจาก player._physics_process ระหว่างโจมตี — true = กงจักรคุมการเคลื่อนที่เฟรมนี้
func drive(delta: float) -> bool:
	if cyclone_left <= 0.0 or cyclone_seq != player._attack_seq: return false
	cyclone_left -= delta
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept") \
			or (InputMap.has_action("move_up") and Input.is_action_just_pressed("move_up")):
		cyclone_left = 0.0
		cyclone_cancelled = true
		rb._finish(cyclone_seq)
		player._start_dodge()
		return true
	var axis := Input.get_axis("move_left", "move_right")
	if axis == 0.0: axis = Input.get_axis("ui_left", "ui_right")
	player.velocity.x = axis * PlayerState.stats.move_speed * CYCLONE_MOVE
	if axis != 0.0:
		player.facing = 1 if axis > 0.0 else -1
		player._update_facing()
	player.move_and_slide()
	return true

# ---------------------------------------------------------
# 4) คมตัดพันธะ (ปรับ) — พุ่งเข้า 260 แล้วฟันเสี้ยวจันทร์ 560 · ฆ่าได้คืนรูน 1 ดวง
# ---------------------------------------------------------
func _erasing_cut(s: SkillData, lv: int, rune_mult: float) -> void:
	var seq := _begin(&"erasing_cut")
	var dir: int = player.facing
	rb.approach_left = CUT_LUNGE
	rb.approach_dir = dir
	while rb.approach_left > 0.0:
		await get_tree().physics_frame
		if not _alive(seq):
			rb._finish(seq)
			return
	if not await _wait(0.16, seq):
		rb._finish(seq)
		return
	player._play_skill_sfx(&"erasing_cut")
	var mult := s.damage_mult(lv) * rune_mult
	var hit: Array = rb.strike(&"erasing_cut", mult, s.range_x, s.max_targets_at(lv), dir)
	preload("res://scripts/entities/ninth_edge_fx.gd").spawn(_world(), player.foot_position(), dir, s.range_x)
	for e in hit:
		if is_instance_valid(e) and e.has_method("is_dead") and e.is_dead():
			rb.refund_rune()
			Events.floating_text(player.global_position + Vector2(0, -170), "คืนรูน +1", Color("#9fd4ff"), 16, 0)
			break
	_mirror(&"erasing_cut", mult, dir)
	await _wait(0.2, seq)
	rb._finish(seq)

# ---------------------------------------------------------
# 5) ร่างเงาสะท้อน (แทนเงานามร่วมคม) — วางร่างเงา 10 วิ ทำท่า Ninth ตามจากตำแหน่งของมันเอง 40–60%
# ---------------------------------------------------------
func _mirror_shade(lv: int) -> void:
	player._play_support_sfx(&"twin_inscription", "buff")
	_clear_shade()
	var body: AnimatedSprite2D = player.sprite
	shade = AnimatedSprite2D.new()
	shade.sprite_frames = body.sprite_frames
	shade.centered = body.centered
	shade.offset = body.offset
	shade.animation = body.animation
	shade.frame = body.frame
	shade.flip_h = body.flip_h
	shade.modulate = Color(0.72, 0.55, 1.0, 0.62)
	shade.z_index = body.z_index
	shade.set_meta("ignore_map_bounds", true)
	_world().add_child(shade)
	shade.global_transform = body.global_transform
	shade.pause()
	shade_foot = player.foot_position()
	shade_time = SHADE_TIME
	shade_lv = lv
	PlayerState.active_buffs[&"twin_inscription"] = {"time_left": SHADE_TIME, "values": {}, "level": lv}
	PlayerState.refresh()
	preload("res://scripts/entities/ninth_motion_fx.gd").spawn(_world(), shade_foot, "blink", 0.4)
	Events.floating_text(shade_foot + Vector2(0, -200), "ร่างเงาสะท้อน", Color("#cdb6ff"), 20, 0)

func _clear_shade() -> void:
	if is_instance_valid(shade): shade.queue_free()
	shade = null
	shade_time = 0.0
	if PlayerState.active_buffs.has(&"twin_inscription"):
		PlayerState.active_buffs.erase(&"twin_inscription")
		if PlayerState.stats != null: PlayerState.refresh()

## ร่างเงาฟันไปทางตัวผู้เล่น (ตีขนาบฝูงจากอีกฝั่ง)
func _mirror(id: StringName, mult: float, _dir: int) -> void:
	if id not in MIRRORED or not is_instance_valid(shade) or shade_time <= 0.0: return
	var dir := 1 if player.global_position.x >= shade_foot.x else -1
	var box := Rect2(shade_foot.x - 80.0 if dir > 0 else shade_foot.x - SHADE_REACH, shade_foot.y - 320, SHADE_REACH + 80.0, 350)
	var n := 0
	for e in _enemies():
		if not box.intersects(player.enemy_rect(e), true): continue
		e.take_damage_from_player(mult * shade_power(shade_lv), false, dir, 0.0, 0.0, &"mirror_echo")
		n += 1
		if n >= 8: break
	preload("res://scripts/entities/ninth_edge_fx.gd").spawn(_world(), shade_foot, dir, SHADE_REACH)
	var tw := shade.create_tween()
	tw.tween_property(shade, "modulate", Color(1.0, 0.92, 1.0, 0.95), 0.06)
	tw.tween_property(shade, "modulate", Color(0.72, 0.55, 1.0, 0.62), 0.25)

func _process(delta: float) -> void:
	if shade_time <= 0.0: return
	shade_time -= delta
	if not is_instance_valid(shade) or not is_instance_valid(player) or player._dead or shade_time <= 0.0:
		_clear_shade()
		return
	var toward := 1 if player.global_position.x >= shade_foot.x else -1
	shade.flip_h = (toward > 0) if player.sprite_faces_left else (toward < 0)
	if shade_time < 1.0: shade.modulate.a = 0.62 * shade_time

# ---------------------------------------------------------
# 6) พิพากษานามที่เก้า (อัลติ แทนประกาศนามที่เก้า) — วาร์ปฟันไล่ 9 เป้า + ระเบิดใหญ่ · อมตะตลอดท่า
# ---------------------------------------------------------
func _verdict(lv: int, rune_mult: float) -> void:
	var seq := _begin(&"ninth_inscription")
	player._iframe = maxf(player._iframe, VERDICT_HITS * VERDICT_GAP + 0.9)
	player._play_skill_sfx(&"ninth_inscription")
	var origin: Vector2 = player.foot_position()
	Events.floating_text(origin + Vector2(0, -210), "★ พิพากษานามที่เก้า ★", Color("#ffd86b"), 26, 0)
	var targets: Array = []
	for e in _enemies():
		var f := _foot(e)
		if absf(f.x - origin.x) <= VERDICT_RANGE and absf(f.y - origin.y) <= 320.0 and _clear(origin, f): targets.append(e)
	targets.sort_custom(func(a, b): return absf(a.global_position.x - origin.x) < absf(b.global_position.x - origin.x))
	if not await _wait(0.22, seq):
		rb._finish(seq)
		return
	var hit_mult := verdict_hit(lv) * rune_mult
	var n := 0
	var idx := 0
	while n < VERDICT_HITS and not targets.is_empty():
		var e = targets[idx % targets.size()]
		if not is_instance_valid(e) or (e.has_method("is_dead") and e.is_dead()):
			targets.remove_at(idx % targets.size())
			continue
		var side := -1.0 if n % 2 == 0 else 1.0
		var here: Vector2 = player.foot_position()
		preload("res://scripts/entities/ninth_motion_fx.gd").spawn(_world(), here, "blink", 0.25)
		var dest := _wall_clamp(here, e.global_position.x + side * 70.0)
		player.global_position.x += dest - here.x
		player.facing = 1 if e.global_position.x >= player.global_position.x else -1
		player._update_facing()
		_slice(n)
		_hit(e, hit_mult, &"ninth_inscription")
		preload("res://scripts/entities/ninth_edge_fx.gd").spawn(_world(), player.foot_position(), player.facing, 260.0)
		n += 1
		idx += 1
		if not await _wait(VERDICT_GAP, seq): break
	if _alive(seq):
		_pose(&"erasing_cut")
		if await _wait(0.2, seq):
			var at: Vector2 = player.foot_position()
			_area(at, VERDICT_RADIUS, verdict_finale(lv) * rune_mult, &"ninth_inscription", 20)
			preload("res://scripts/entities/ninth_edge_fx.gd").spawn(_world(), at, 1, VERDICT_RADIUS, true)
			preload("res://scripts/entities/ninth_motion_fx.gd").spawn(_world(), at, "burst", 0.55, {"radius": VERDICT_RADIUS})
	await get_tree().create_timer(0.2).timeout
	rb._finish(seq)

func _exit_tree() -> void:
	_clear_shade()
