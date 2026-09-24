extends Node2D
## Explicit world-space hit rectangles are also the visible warnings.
signal finished
var caster: Node2D
var kind := 0
var combo := 0
var enraged := false
var elapsed := 0.0
var last_hit := -10.0
var zones: Array[Dictionary] = []
var done := false
const COLORS := [Color("95ed9b"), Color("72cdff"), Color("e4a6ff"), Color("ffb876"), Color("78e5d4"), Color("b2dfff"), Color("ffd77e"), Color("c4b0ff"), Color("e28cff"), Color("fff1bb"),
	Color("9e84ff"), Color("d8edff"), Color("ff8cd8"), Color("e5604c"), Color("b2d8ff"), Color("72e5e5"), Color("ff8c3f"), Color("8cd84c"), Color("ff4c66"), Color("72a5ff")]
## ★ รอบ 179 ★ ผู้คุมชั้น 55-100 (โหมด 10-19) = ท่าผู้คุมเดิม 2 ชุดต่อกัน
## ชุดหลังโผล่วงเตือนหลังชุดแรกฟาดจบ (ไม่ซ้อนกันบนจอ) · เป้าหมายจำตำแหน่งเดิม ไม่ไล่ตาม
const COMBOS := [[1, 0], [5, 2], [2, 7], [0, 3], [6, 1], [4, 7], [7, 8], [3, 5], [8, 2], [9, 6]]

static func layout(mode: int, target_x: float, origin_x: float, turn: int, rage: bool) -> Array[Dictionary]:
	if mode >= 10:
		var pair: Array = COMBOS[clampi(mode - 10, 0, COMBOS.size() - 1)]
		var first_part := layout(pair[0], target_x, origin_x, turn, rage)
		var last := 0.0
		for zone in first_part:
			zone["kind"] = pair[0]
			last = maxf(last, zone.at)
		var offset := last + 0.35
		for zone in layout(pair[1], target_x, origin_x, turn + 1, rage):
			zone["kind"] = pair[1]
			zone["show"] = offset
			zone["at"] = float(zone["at"]) + offset
			first_part.append(zone)
		return first_part
	var out: Array[Dictionary] = []
	var speed := 0.88 if rage else 1.0
	var first := 1.35
	if mode == 0:
		# Root cage: three pillars, then a low sweep that can be jumped.
		for offset in [-340.0, 0.0, 340.0]:
			out.append({"rect": Rect2(clampf(target_x + offset, 180, 4020) - 90, 530, 180, 350), "at": first, "mult": 2.1})
		out.append({"rect": Rect2(clampf(origin_x - 600, 80, 2920), 805, 1200, 75), "at": first + 1.3 * speed, "mult": 2.4})
	elif mode == 1:
		# Three fixed lightning strikes. No retargeting after their markers appear.
		for index in range(3):
			var x := clampf(target_x + float(index - 1) * 360.0, 200, 4000)
			out.append({"rect": Rect2(x - 125, 440, 250, 440), "at": first + index * 0.85 * speed, "mult": 2.0 + index * 0.2})
	elif mode == 2:
		# Mark target, then both escape routes. Move once, then move back.
		out.append({"rect": Rect2(target_x - 140, 510, 280, 370), "at": first, "mult": 2.3})
		for direction in [-1, 1]:
			out.append({"rect": Rect2(clampf(target_x + direction * 380, 200, 4000) - 130, 510, 260, 370), "at": first + 1.15 * speed, "mult": 2.3})
	elif mode == 3:
		# In/out sequence: broad outer seals leave a 360 px safe center.
		var x := clampf(target_x, 800, 3400)
		var outer_time := first if turn % 2 == 0 else first + 1.25 * speed
		var inner_time := first + 1.25 * speed if turn % 2 == 0 else first
		out.append({"rect": Rect2(x - 760, 460, 580, 420), "at": outer_time, "mult": 2.5})
		out.append({"rect": Rect2(x + 180, 460, 580, 420), "at": outer_time, "mult": 2.5})
		out.append({"rect": Rect2(x - 180, 460, 360, 420), "at": inner_time, "mult": 2.7})
	elif mode == 4:
		# A pendulum crosses the saved position, then returns. Never follows the player.
		var x := clampf(target_x, 650, 3550)
		for i in range(5):
			var offset: float = [-360.0, 0.0, 360.0, 0.0, -360.0][i]
			out.append({"rect":Rect2(x+offset-105,480,210,400),"at":first+i*.72*speed,"mult":2.0})
	elif mode == 5:
		var x := clampf(target_x, 650, 3550)
		out.append({"rect":Rect2(x-650,810,1300,70),"at":first,"mult":2.1})
		for offset in [-370.0,370.0]:
			out.append({"rect":Rect2(x+offset-125,440,250,440),"at":first+1.1*speed,"mult":2.4})
		out.append({"rect":Rect2(x-650,810,1300,70),"at":first+2.35*speed,"mult":2.2})
	elif mode == 6:
		var x := clampf(target_x, 800, 3400)
		out.append({"rect":Rect2(x-140,450,280,430),"at":first,"mult":2.6})
		for offset in [-650.0,250.0]:
			out.append({"rect":Rect2(x+offset,460,400,420),"at":first+1.3*speed,"mult":2.5})
		out.append({"rect":Rect2(x-700,805,1400,75),"at":first+2.6*speed,"mult":2.3})
	elif mode == 7:
		var x := clampf(target_x, 800, 3400)
		for i in range(3):
			# Two marked columns orbit around a clearly open third column.
			for col in range(3):
				if col == (i+turn)%3: continue
				out.append({"rect":Rect2(x-600+col*400,450,290,430),"at":first+i*1.15*speed,"mult":2.25})
	elif mode == 8:
		var x := clampf(target_x, 900, 3300)
		out.append({"rect":Rect2(x-340,490,680,390),"at":first,"mult":2.5})
		for offset in [-820.0,220.0]:
			out.append({"rect":Rect2(x+offset,490,600,390),"at":first+1.4*speed,"mult":2.5})
		out.append({"rect":Rect2(x-700,805,1400,75),"at":first+2.8*speed,"mult":2.2})
	elif mode == 9:
		var x := clampf(target_x, 900, 3300)
		for offset in [-680.0,240.0]:
			out.append({"rect":Rect2(x+offset,420,440,460),"at":first,"mult":2.6})
		out.append({"rect":Rect2(x-170,420,340,460),"at":first+1.3*speed,"mult":2.8})
		out.append({"rect":Rect2(x-850,805,1700,75),"at":first+2.65*speed,"mult":2.4})
	return out

func _ready() -> void:
	z_index = 45
	var target := get_tree().get_first_node_in_group("player")
	var x: float = target.foot_position().x if is_instance_valid(target) else caster.foot_position().x - 300
	zones = layout(kind, x, caster.foot_position().x, combo, enraged)
	for zone in zones: zone["fired"] = false

func _physics_process(delta: float) -> void:
	if not is_instance_valid(caster) or caster.is_dead() or PlayerState.is_dead():
		_finish()
		return
	elapsed += delta
	var end := 0.0
	for zone in zones:
		end = maxf(end, zone.at)
		if not zone.fired and elapsed >= zone.at:
			zone.fired = true
			_hit(zone)
	queue_redraw()
	if elapsed > end + 1.15: _finish()

func _hit(zone: Dictionary) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player) or elapsed - last_hit < 0.65: return
	var feet: Vector2 = player.foot_position()
	# Feet and body center: low sweeps can be jumped, tall pillars cannot.
	var area: Rect2 = zone.rect
	if not area.has_point(feet - Vector2(0, 2)) and not area.has_point(feet - Vector2(0, 95)): return
	last_hit = elapsed
	var result := Combat.monster_skill_hits_player(caster.data, PlayerState.stats, zone.mult)
	player.take_damage(result.damage, 130.0, 1 if feet.x > caster.global_position.x else -1)

func _draw() -> void:
	var color: Color = COLORS[clampi(kind, 0, COLORS.size()-1)]
	for zone in zones:
		var zk: int = zone.get("kind", kind)   # ★ รอบ 179 ★ ลายตามท่าย่อย · สีตามผู้คุม
		var shown: float = zone.get("show", 0.0)
		if elapsed < shown: continue
		var rect: Rect2 = zone.rect
		var left: float = zone.at - elapsed
		if left < -0.45: continue
		if left > 0:
			# A dark keyline keeps the same hit area readable on pale ice/marble
			# as well as the shadowed upper floors. Timing and damage are unchanged.
			draw_rect(rect, Color(0.04, 0.03, 0.06, 0.13))
			draw_rect(rect, Color(color, 0.06))
			draw_rect(rect, Color(0.03, 0.02, 0.05, 0.9), false, 6.0)
			draw_rect(rect, Color(color, 0.95), false, 2.5)
			var progress := clampf(1.0 - left / maxf(0.01, zone.at - shown), 0, 1)
			draw_rect(Rect2(rect.position.x, rect.end.y - 16, rect.size.x, 16), Color(0.03, 0.02, 0.05, 0.85))
			draw_rect(Rect2(rect.position.x, rect.end.y - 12, rect.size.x * progress, 12), Color(color, 0.85))
			draw_rect(Rect2(rect.position + Vector2(4, 2), Vector2(62, 30)), Color(0.03, 0.02, 0.05, 0.9))
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, 25), "%.1f" % left, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, color)
		else:
			var alpha := 1.0 + left / 0.45
			draw_rect(rect, Color(color, alpha * 0.42))
			for i in range(5):
				var x := rect.position.x + rect.size.x * (i + 0.5) / 5.0
				if zk <= 1:
					var points := PackedVector2Array()
					for step in range(9):
						var wave := sin(step * (1.1 if kind == 0 else 4.3) + i) * minf(26.0, rect.size.x * 0.09)
						points.append(Vector2(x + wave, rect.end.y - rect.size.y * step / 8.0))
					draw_polyline(points, Color(color, alpha * 0.25), 16.0, true)
					draw_polyline(points, Color(color, alpha), 4.0, true)
				elif zk == 2:
					var center := Vector2(x, rect.get_center().y)
					var shard := PackedVector2Array([center + Vector2(-32,100), center + Vector2(-12,-30), center + Vector2(35,-110), center + Vector2(12,30)])
					draw_colored_polygon(shard, Color(color, alpha * 0.8))
				else:
					var center := Vector2(x, rect.get_center().y)
					var diamond := PackedVector2Array([center + Vector2(0,-100), center + Vector2(35,0), center + Vector2(0,100), center + Vector2(-35,0), center + Vector2(0,-100)])
					draw_polyline(diamond, Color(color, alpha), 4.0, true)
					draw_line(center + Vector2(-30,0), center + Vector2(30,0), Color.WHITE * alpha, 3.0)

func _finish() -> void:
	if done: return
	done = true
	finished.emit()
	queue_free()
