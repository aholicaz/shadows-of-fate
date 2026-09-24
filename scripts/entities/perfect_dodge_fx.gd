## ★ รอบ 182 ★ หลบพอดี (Perfect Dodge) — วงแสงทอง-ฟ้าขยายรอบตัวผู้เล่น + เส้นความเร็ว
## player.gd สร้างเป็นลูกของผู้เล่น · อยู่ 0.45 วิ (นับเวลาจริง ไม่ช้าตามสโลว์โมชั่น)
extends Node2D

const LIFE := 0.45
var age := 0.0
var _rays: Array[Vector2] = []   ## มุม, ความยาว

func _ready() -> void:
	z_index = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(14):
		_rays.append(Vector2(randf() * TAU, randf_range(60.0, 130.0)))


func _process(_delta: float) -> void:
	# นับเวลาจริง — ตอนสโลว์โมชั่น วงยังขยายด้วยความเร็วปกติ
	age += get_process_delta_time() / maxf(0.05, Engine.time_scale)
	queue_redraw()
	if age >= LIFE:
		queue_free()


func _draw() -> void:
	var t := clampf(age / LIFE, 0.0, 1.0)
	var a := 1.0 - t
	var r := lerpf(30.0, 170.0, 1.0 - pow(1.0 - t, 3.0))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(1.0, 0.88, 0.45, 0.85 * a), 6.0 * a + 1.0, true)
	draw_arc(Vector2.ZERO, r * 0.78, 0.0, TAU, 48, Color(0.6, 0.85, 1.0, 0.6 * a), 3.0, true)
	for ray in _rays:
		var d := Vector2.from_angle(ray.x)
		draw_line(d * (r * 0.55), d * (r * 0.55 + ray.y * a), Color(1, 0.95, 0.75, 0.8 * a), 2.0)
