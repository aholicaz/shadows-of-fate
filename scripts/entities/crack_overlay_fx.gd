## ★ รอบ 146 ★ ลายร้าวขาวบนตัวมอนตอนโดนคริ + สโลว์โมชั่นสั้น ๆ
## Cosmetic only · ไม่แตะ RNG การต่อสู้ · ลบตัวเองใน LIFE วินาที
extends Node2D

const LIFE := 0.5
const LINES := 6

static var _slow_until_msec: int = 0

var _lines: Array = []
var _size: Vector2 = Vector2(60, 80)
var _t: float = 0.0


static func spawn(target: Node2D) -> Node2D:
	var fx = load("res://scripts/entities/crack_overlay_fx.gd").new()
	fx.name = "CritCrackOverlay"
	var bounds: Rect2 = target.body_rect()
	fx._size = bounds.size
	target.get_parent().add_child(fx)
	fx.global_position = bounds.get_center()
	fx.z_index = 58
	return fx


## ภาพช้าลงเหลือ scale เท่า นาน seconds (นับเวลาจริง) · ★ รอบ 150 ★ มีคูลดาวน์ ไม่ซ้อน/ต่อเวลา และคืน time_scale แน่นอน
static var _next_allowed_msec: int = 0
## เวลาจริงที่ต้องคืน 1.0 อย่างช้าที่สุด (watchdog ใน HUD เช็คทุกเฟรม)
static var _restore_deadline_msec: int = 0

static func slow_mo(scale: float, seconds: float, cooldown: float = 0.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var now := Time.get_ticks_msec()
	if now < _next_allowed_msec or Engine.time_scale < 1.0:
		return
	_next_allowed_msec = now + int((seconds + cooldown) * 1000.0)
	Engine.time_scale = scale
	_restore_deadline_msec = now + int(seconds * 1000.0) + 50
	var timer := tree.create_timer(seconds, true, false, true)
	timer.timeout.connect(func(): Engine.time_scale = 1.0)


## เผื่อมีอะไรค้าง (เช่นเปลี่ยนฉากกลางสโลว์) — เรียกจากที่ไหนก็ได้เพื่อคืนความเร็วปกติ
static func reset_time() -> void:
	Engine.time_scale = 1.0
	_next_allowed_msec = 0
	_restore_deadline_msec = 0


## ★ รอบ 151 ★ เรียกทุกเฟรม (HUD) — ถ้าเวลาช้าค้างเกินกำหนดด้วยเหตุใดก็ตาม ให้คืน 1.0 ทันที
static func watchdog() -> void:
	if Engine.time_scale < 1.0 and Time.get_ticks_msec() > _restore_deadline_msec:
		Engine.time_scale = 1.0


func _ready() -> void:
	for i in range(LINES):
		var pts := PackedVector2Array()
		var p := Vector2(randf_range(-_size.x * 0.25, _size.x * 0.25), randf_range(-_size.y * 0.35, _size.y * 0.1))
		pts.append(p)
		var ang := randf_range(0.0, TAU)
		for k in range(4):
			ang += randf_range(-0.9, 0.9)
			p += Vector2.from_angle(ang) * randf_range(_size.y * 0.12, _size.y * 0.22)
			# ไม่ให้เส้นทะลุออกนอกตัวมอน
			p = p.clamp(-_size * 0.48, _size * 0.48)
			pts.append(p)
		_lines.append(pts)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var grow := clampf(_t / 0.08, 0.0, 1.0)         # เส้นวิ่งออกใน 0.08 วิ
	var a := 1.0 - clampf((_t - 0.2) / (LIFE - 0.2), 0.0, 1.0)
	for pts: PackedVector2Array in _lines:
		var n := int(ceil(pts.size() * grow))
		if n < 2:
			continue
		var part: PackedVector2Array = pts.slice(0, n)
		draw_polyline(part, Color(0.05, 0.05, 0.1, 0.8 * a), 4.0)
		draw_polyline(part, Color(1, 1, 1, a), 2.0)
