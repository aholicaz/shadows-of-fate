## DarkWave — สกิล "คลื่นเคียวมืดวิ่งไปตามพื้น" ของมอน/บอส (รอบ 78 · บาฟโฟเมท)
##
## ★ ใช้ยังไง ★ ไม่ต้องสร้างโหนดเอง — ตั้งใน MonsterData (.tres) กลุ่ม
## "สกิล — คลื่นเคียวมืดวิ่งบนพื้น" แล้วใส่ Skill Wave Count มากกว่า 0
## ตอนมอนร่ายสกิล ระบบเรียกให้อัตโนมัติ (เหมือน LightningStrike ของอสูรสายฟ้า)
##
## ★ ทำงานยังไง ★
##   คลื่นเงามืดพุ่งออกจากเท้ามอน วิ่งไปตามพื้น "ข้างหน้าตามที่มอนหัน"
##   (ติ๊ก Both Sides = ปล่อยข้างหลังด้วยพร้อมกัน) จนสุดระยะแล้วสลาย
##   ผู้เล่นโดนเมื่อ "คลื่นวิ่งผ่านเท้า" และเท้าอยู่ต่ำกว่าความสูงคลื่น
##   → หลบด้วยการ **กระโดดข้าม** หรือพุ่งหลบ (ช่วงอมตะ) ทะลุ — ต่างจากสายฟ้าที่ต้องวิ่งออกจากวง
##
## ทั้งชุดเป็นโหนดเดียวที่เกิด "ในแมพ" ไม่ใช่ลูกของตัวมอน (คลื่นวิ่งไกลกว่าตัวมอนได้)
class_name DarkWave
extends Node2D

## SpriteFrames เริ่มต้นถ้าไม่ได้ใส่ในช่อง Skill Wave Frames
const DEFAULT_FRAMES := "res://data/sprites/fx_dark_wave.tres"
## ชื่อท่าในไฟล์นั้น
const WAVE_ANIM := "wave"
## ปล่อยให้ภาพสลายกี่วินาทีตอนสุดระยะ
const FADE_TIME := 0.22
## แสงวาบสีม่วงที่เท้ามอนตอนปล่อยคลื่น
const FLASH_COLOR := Color("#b04cff")

var _data: MonsterData
var _caster: Node2D
var _hits := 0                       ## ผู้เล่นโดนไปแล้วกี่ลูก (จำกัดด้วย Skill Wave Max Hits)
var _waves: Array = []               ## แต่ละลูก {"node", "dir", "x", "y", "hit", "dist", "fading"}
var _base_ground := 0.0
var _has_base := false
var _flash := 0.0                    ## เวลาที่เหลือของแสงวาบ
var _done_launching := false         ## ปล่อยครบทุกลูกแล้ว (ก่อนหน้านั้นห้ามลบตัวเอง — กับดัก 109)


## ★ เรียกจาก monster_base ตอนร่ายสกิล ★ คืน null ถ้ามอนตัวนี้ไม่ได้ตั้งคลื่นไว้
static func cast(data: MonsterData, caster: Node2D, facing: int) -> DarkWave:
	if data == null or caster == null or data.skill_wave_count <= 0:
		return null
	var tree := caster.get_tree()
	if tree == null:
		return null
	var parent: Node = tree.get_first_node_in_group("map")
	if parent == null:
		parent = tree.current_scene
	if parent == null:
		return null

	var node := DarkWave.new()
	node.name = "DarkWave_%s" % String(data.id)
	node._data = data
	node._caster = caster
	node.z_index = data.skill_wave_z
	# จุดอ้างอิง = ตรงเท้ามอนตอนเริ่มร่าย (คลื่นไม่วิ่งตามมอน)
	var foot: Vector2 = caster.foot_position() if caster.has_method("foot_position") \
		else caster.global_position
	node.position = foot - parent.global_position
	parent.add_child(node)
	node._run(1 if facing >= 0 else -1)
	return node


func _run(dir: int) -> void:
	var d := _data
	await get_tree().create_timer(maxf(0.0, d.skill_wave_delay)).timeout
	if not is_instance_valid(self):
		return
	for i in range(d.skill_wave_count):
		if not is_instance_valid(self):
			return
		_launch(dir)
		if d.skill_wave_both_sides:
			_launch(-dir)
		if i < d.skill_wave_count - 1:
			await get_tree().create_timer(maxf(0.02, d.skill_wave_interval)).timeout
	_done_launching = true


## ปล่อยคลื่น 1 ลูกไปทาง dir (1 = ขวา · −1 = ซ้าย)
func _launch(dir: int) -> void:
	var d := _data
	var frames: SpriteFrames = d.skill_wave_frames
	if frames == null and ResourceLoader.exists(DEFAULT_FRAMES):
		frames = load(DEFAULT_FRAMES)

	var sp := AnimatedSprite2D.new()
	var k := 1.0
	if frames != null:
		sp.sprite_frames = frames
		var anim := WAVE_ANIM
		if not frames.has_animation(anim):
			var names := frames.get_animation_names()
			anim = String(names[0]) if names.size() > 0 else ""
		if anim != "":
			var tex := frames.get_frame_texture(anim, 0)
			if tex != null and d.skill_wave_height > 0.0:
				k = d.skill_wave_height / maxf(1.0, tex.get_size().y)
			sp.scale = Vector2(k, k)
			# ★ ขอบล่างของภาพ = พื้น ★ ภาพวาดให้ "หน้าคลื่น" หันไปทางขวา → ไปซ้ายก็กลับด้าน
			sp.offset = Vector2(0, -tex.get_size().y * 0.5) if tex != null else Vector2.ZERO
			sp.flip_h = dir < 0
			sp.animation = anim
			sp.play(anim)
	sp.position = Vector2(0, 0)
	add_child(sp)

	_waves.append({"node": sp, "dir": dir, "x": 0.0, "y": 0.0, "hit": false, "dist": 0.0, "fading": false})
	_flash = 0.18
	queue_redraw()

	if d.skill_wave_sfx != "" and Game.sfx != null:
		Game.sfx.play(d.skill_wave_sfx, 1.0, 0.1)


func _physics_process(delta: float) -> void:
	if _waves.is_empty():
		# ★ กับดัก 109 ★ ตอนยังรอ Skill Wave Delay อยู่ ลิสต์ก็ว่างเหมือนกัน — ห้ามลบตัวเองก่อนปล่อย
		if _done_launching and _flash <= 0.0:
			queue_free()
		return
	var d := _data
	var alive: Array = []
	for w in _waves:
		var sp: AnimatedSprite2D = w.node
		if not is_instance_valid(sp):
			continue
		if w.fading:
			alive.append(w)
			continue
		var step: float = d.skill_wave_speed * delta
		w.x += w.dir * step
		w.dist += step
		w.y = _ground_offset_at(w.x)
		sp.position = Vector2(w.x, w.y)
		_check_hit(w)
		if w.dist >= d.skill_wave_range or _hit_wall(w.x, w.y):
			_dissolve(w)
		alive.append(w)
	_waves = alive


## ผู้เล่นโดนไหม — คลื่นผ่านเท้า + เท้าอยู่ต่ำกว่าความสูงคลื่น (กระโดดข้ามได้)
func _check_hit(w: Dictionary) -> void:
	if w.hit:
		return
	var d := _data
	if d.skill_wave_max_hits > 0 and _hits >= d.skill_wave_max_hits:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player) or PlayerState.is_dead():
		return
	var pf: Vector2 = player.foot_position() if player.has_method("foot_position") \
		else player.global_position
	var center := global_position + Vector2(float(w.x), float(w.y))
	if absf(pf.x - center.x) > d.skill_wave_hit_width:
		return
	# เท้าสูงกว่ายอดคลื่น = ข้ามได้ · ต่ำกว่าพื้นมาก = คนละชั้น
	var above: float = center.y - pf.y
	if above > d.skill_wave_hit_height or above < -40.0:
		return

	w.hit = true
	_hits += 1
	var mult: float = d.skill_wave_damage_mult if d.skill_wave_damage_mult > 0.0 else d.skill_damage_mult
	var result := Combat.monster_hits_player(d, PlayerState.stats)
	var damage: int = maxi(1, int(round(result.damage * mult)))
	if player.has_method("take_damage"):
		player.take_damage(damage, d.skill_knockback, int(w.dir))


## สุดระยะ/ชนกำแพง → จางหายแล้วเอาออก
func _dissolve(w: Dictionary) -> void:
	w.fading = true
	var sp: AnimatedSprite2D = w.node
	var tw := create_tween()
	tw.tween_property(sp, "modulate:a", 0.0, FADE_TIME)
	tw.tween_callback(func() -> void:
		_waves.erase(w)
		if is_instance_valid(sp):
			sp.queue_free())


## ชนกำแพงล่องหนขอบแมพ / ขอบเขตแมพ ไหม
func _hit_wall(x: float, y: float) -> bool:
	var map := get_tree().get_first_node_in_group("map")
	if map != null and "map_bounds" in map:
		var b: Rect2 = map.map_bounds
		var gx: float = global_position.x + x
		if gx < b.position.x + 10.0 or gx > b.end.x - 10.0:
			return true
	return false


## ยิงเส้นลงหาพื้นตรงระยะ x — คืน y ของพื้น (พิกัดโลก) หรือ INF ถ้าไม่เจอ
func _raycast_ground(x: float) -> float:
	var world := get_world_2d()
	if world == null or world.direct_space_state == null:
		return INF
	var from := Vector2(global_position.x + x, global_position.y - 300.0)
	var to := Vector2(global_position.x + x, global_position.y + 300.0)
	var q := PhysicsRayQueryParameters2D.create(from, to)
	q.collision_mask = 1
	var hit := world.direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return INF
	return float(hit.position.y)


## ระดับพื้นตรงระยะ x เทียบกับจุดเท้ามอน (local y) — พื้นลาดคลื่นก็ไล่ตาม (ดู LightningStrike)
func _ground_offset_at(x: float) -> float:
	if not _has_base:
		_base_ground = _raycast_ground(0.0)
		_has_base = true
	if is_inf(_base_ground):
		return 0.0
	var here := _raycast_ground(x)
	if is_inf(here):
		return 0.0
	var diff := here - _base_ground
	if absf(diff) > _data.skill_wave_hit_height * 1.5:
		return 0.0
	return diff


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		queue_redraw()


## แสงวาบรูปวงรีสีม่วงที่เท้าตอนปล่อยคลื่น
func _draw() -> void:
	if _flash <= 0.0:
		return
	var t: float = clampf(_flash / 0.18, 0.0, 1.0)
	var r: float = 70.0 + 60.0 * (1.0 - t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, r, Color(FLASH_COLOR, 0.45 * t))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(FLASH_COLOR, 0.9 * t), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
