## ★ รอบ 182 ★ ภาพตราทองของแชมเปี้ยน (ระบบ B บท 9)
## โล่ทอง = ฟองทองรอบตัว (หายตอนแตก) · ผู้พิทักษ์ = วงระยะคุ้มกันจาง ๆ ที่พื้น · ฟื้นฟู = ประกายเขียวลอยขึ้นตอนกำลังฟื้น
extends Node2D

var monster: Node2D
var t := 0.0


func _ready() -> void:
	z_index = 2


func _process(delta: float) -> void:
	t += delta
	if not is_instance_valid(monster) or monster.is_dead():
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var marks: Array = monster.gold_marks
	var body: Rect2 = monster.body_rect()
	var local_center := body.get_center() - global_position
	if &"gold_shield" in marks and monster.gold_shield_up:
		var rx := body.size.x * 0.75 + 20.0
		var ry := body.size.y * 0.62 + 16.0
		var pulse := 1.0 + 0.04 * sin(t * 5.0)
		draw_set_transform(local_center, 0.0, Vector2(rx, ry) * pulse / 100.0)
		draw_circle(Vector2.ZERO, 100.0, Color(1.0, 0.84, 0.3, 0.10))
		draw_arc(Vector2.ZERO, 100.0, 0.0, TAU, 48, Color(1.0, 0.86, 0.35, 0.85), 3.0, true)
		for i in range(6):
			var a0 := t * 0.9 + i * TAU / 6.0
			draw_arc(Vector2.ZERO, 92.0, a0, a0 + 0.35, 8, Color(1, 0.97, 0.75, 0.9), 2.0, true)
		draw_set_transform(Vector2.ZERO)
	if &"warden" in marks:
		var foot: Vector2 = monster.foot_position() - global_position
		draw_set_transform(foot, 0.0, Vector2(1.0, 0.16))
		draw_arc(Vector2.ZERO, monster.GOLD_WARDEN_RANGE, 0.0, TAU, 96, Color(1.0, 0.8, 0.3, 0.35 + 0.1 * sin(t * 2.0)), 4.0, true)
		draw_set_transform(Vector2.ZERO)
	if &"regen" in marks and monster.gold_regenerating():
		for i in range(5):
			var life := fposmod(t * 0.8 + i * 0.2, 1.0)
			var p := local_center + Vector2((i - 2) * body.size.x * 0.18, body.size.y * 0.3 - life * body.size.y * 0.8)
			draw_circle(p, 4.0 * sin(life * PI) + 1.0, Color(0.5, 1.0, 0.55, 0.8 * sin(life * PI)))
