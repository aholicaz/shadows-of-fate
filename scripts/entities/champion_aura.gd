extends Node2D
## ★ รอบ 158 ★ ออร่ามอนแชมเปี้ยน — วงทองจาง ๆ ใต้เท้า + ประกายลอยขึ้น (ไม่ย้อมสีตัวมอน ตามที่ตกลงรอบ 128)
## ติดเป็นลูกของมอน (MonsterBase._attach_champion_fx) · วาดหลังตัวมอน
const GOLD := Color(1.0, 0.82, 0.3)
const SPARKS := 12
var radius := 70.0
var t := 0.0
var _seeds: Array[Vector3] = []   # x (−1..1) · เฟส · ความเร็ว


func _ready() -> void:
	z_index = -1
	for i in range(SPARKS):
		_seeds.append(Vector3(randf_range(-1.0, 1.0), randf(), randf_range(0.7, 1.3)))


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.85 + 0.15 * sin(t * 3.2)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.24))
	draw_circle(Vector2.ZERO, radius * 1.25 * pulse, Color(GOLD, 0.10))
	draw_circle(Vector2.ZERO, radius * pulse, Color(GOLD, 0.16))
	draw_arc(Vector2.ZERO, radius * pulse, 0.0, TAU, 48, Color(GOLD, 0.75), 3.0, true)
	draw_arc(Vector2.ZERO, radius * 0.72 * pulse, t * 0.8, t * 0.8 + TAU * 0.6, 32, Color(1, 0.95, 0.7, 0.55), 2.0, true)
	draw_set_transform(Vector2.ZERO)
	for s in _seeds:
		var life := fposmod(t * 0.55 * s.z + s.y, 1.0)
		var p := Vector2(s.x * radius * 0.9, -life * 150.0)
		var a := sin(life * PI)
		var r := 3.5 + 2.5 * a
		var star := PackedVector2Array([p + Vector2(0, -r * 2), p + Vector2(r * 0.5, -r * 0.5), p + Vector2(r * 2, 0),
			p + Vector2(r * 0.5, r * 0.5), p + Vector2(0, r * 2), p + Vector2(-r * 0.5, r * 0.5), p + Vector2(-r * 2, 0), p + Vector2(-r * 0.5, -r * 0.5)])
		draw_colored_polygon(star, Color(1, 0.93, 0.6, 0.85 * a))
