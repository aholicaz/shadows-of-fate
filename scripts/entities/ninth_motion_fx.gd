extends Node2D
## ★ รอบ 181 ★ เอฟเฟกต์วาดสดของสกิล Ninth Edge ชุดใหม่ (ยังไม่มีภาพจริง — ใช้เส้นวาดแทนไปก่อน)
## mode: "scar" รอยแผลตามทางวาร์ป · "chain" โซ่พันธะ · "ring" วงหมุนรอบตัว · "blink" ประกายตอนวาร์ปถึงเป้า · "burst" วงระเบิด
var mode := "scar"
var a := Vector2.ZERO        ## จุดเริ่ม (พิกัดท้องถิ่น)
var b := Vector2.ZERO        ## จุดปลาย
var radius := 280.0
var lifetime := 0.5
var age := 0.0
var follow: Node2D = null    ## วงหมุนเกาะตัวละคร
var color := Color("#c8a6ff")

static func spawn(parent: Node, at: Vector2, kind: String, life: float, extra: Dictionary = {}) -> Node2D:
	var fx = load("res://scripts/entities/ninth_motion_fx.gd").new()
	fx.global_position = at
	fx.mode = kind
	fx.lifetime = life
	for key in extra.keys(): fx.set(key, extra[key])
	fx.set_meta("ignore_map_bounds", true)
	parent.add_child(fx)
	return fx

func _ready() -> void:
	z_index = 16

func _process(delta: float) -> void:
	age += delta
	if is_instance_valid(follow):
		global_position = follow.foot_position() if follow.has_method("foot_position") else follow.global_position
	if age >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := clampf(age / maxf(lifetime, 0.01), 0.0, 1.0)
	match mode:
		"scar":
			# รอยแผลบาง ๆ ค้างบนทางวาร์ป แล้วสว่างวาบตอนใกล้ระเบิด
			var glow := 0.35 + 0.65 * pow(t, 3.0)
			for i in range(3):
				var off := Vector2(0, -60 - i * 38)
				draw_line(a + off, b + off, Color(0.55, 0.3, 1.0, 0.25 * glow), 18.0 - i * 4, true)
				draw_line(a + off, b + off, Color(0.93, 0.85, 1.0, 0.9 * glow), 3.0, true)
		"chain":
			# โซ่พุ่งออกไปครึ่งแรก แล้วหดกลับครึ่งหลัง
			var k := t * 2.0 if t < 0.5 else 2.0 - t * 2.0
			var tip := a.lerp(b, clampf(k, 0.0, 1.0))
			var links := int(a.distance_to(tip) / 26.0)
			draw_line(a, tip, Color(0.6, 0.45, 1.0, 0.35), 9.0, true)
			for i in range(links):
				var p := a.lerp(tip, (i + 0.5) / maxf(1.0, links))
				draw_arc(p, 7.0, 0.0, TAU, 10, Color(0.92, 0.86, 1.0, 0.95), 2.5, true)
			draw_circle(tip, 11.0, Color(1, 0.95, 1, 0.9))
		"ring":
			var spin := age * 14.0
			for j in range(3):
				var pts := PackedVector2Array()
				for i in range(25):
					var ang := spin + j * TAU / 3.0 + i / 24.0 * PI * 0.9
					pts.append(Vector2(cos(ang) * radius, -95 + sin(ang) * radius * 0.28))
				draw_polyline(pts, Color(0.5, 0.3, 1.0, 0.3), 16.0, true)
				draw_polyline(pts, Color(0.95, 0.88, 1.0, 0.85), 3.0, true)
		"blink":
			var r := 40.0 + 120.0 * t
			draw_arc(Vector2(0, -100), r, 0.0, TAU, 28, Color(0.9, 0.8, 1.0, 1.0 - t), 4.0, true)
			draw_line(Vector2(-r, -100), Vector2(r, -100), Color(1, 1, 1, 1.0 - t), 2.0, true)
		"burst":
			var r2 := radius * (0.3 + 0.7 * t)
			var fade := 1.0 - t
			draw_arc(Vector2(0, -40), r2, PI, TAU, 40, Color(0.6, 0.35, 1.0, 0.45 * fade), 26.0, true)
			draw_arc(Vector2(0, -40), r2, PI, TAU, 40, Color(1.0, 0.94, 1.0, fade), 4.0, true)
			for i in range(9):
				var ang2 := PI + PI * (i + 0.5) / 9.0
				draw_line(Vector2(0, -40), Vector2(cos(ang2), sin(ang2)) * r2 + Vector2(0, -40), Color(0.85, 0.75, 1.0, 0.6 * fade), 3.0, true)
