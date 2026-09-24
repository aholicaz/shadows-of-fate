extends Node2D
## ★ รอบ 158 ★ สกิลบอสแบบ «วงเตือนบนพื้น» — กรอบที่เห็น = พื้นที่โดนจริง (ไม่ไล่ตามผู้เล่นหลังขึ้นเตือน)
## เรียกผ่าน cast(actor, skill, turn) จาก MonsterBase._cast_rotation_skill · จบแล้วส่ง finished
## โดนได้ไม่เกิน MAX_HITS ครั้งต่อการร่าย 1 ครั้ง · พุ่งหลบ (อมตะ) ผ่านได้
signal finished

const MAX_HITS := 2
const STRIKE_TIME := 0.38
const PREVIEW := 1.2          ## วินาที — กรอบที่ยังไม่ถึงคิวจะจางจนเหลือเวลาไม่เกินนี้
const PILLAR_H := 540.0
const KNOCKBACK := 260.0

var caster: Node2D
var data: MonsterData
var zones: Array[Dictionary] = []
var color := Color.WHITE
var style := "light"
var elapsed := 0.0
var hits := 0
var _done := false
var _end := 0.0


static func cast(actor: Node2D, skill: Dictionary, turn: int) -> Node2D:
	var fx = load("res://scripts/entities/boss_zone_skill.gd").new()
	fx.caster = actor
	fx.data = actor.data
	fx.color = Color(String(skill.get("color", "ffffff")))
	fx.style = String(skill.get("style", "light"))
	fx.top_level = true
	fx.z_index = 60
	var foot: Vector2 = actor.foot_position()
	var target_x: float = foot.x + float(actor.facing) * 300.0
	var player := actor.get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("foot_position"):
		target_x = player.foot_position().x
	var rage: bool = int(actor.hp) <= int(actor.data.max_hp / 2)
	var mult := float(skill.get("mult", 1.0))
	fx.zones = layout(String(skill.get("pattern", "pillars3")), target_x, foot.x, int(actor.facing), turn, rage, foot.y, mult)
	# ★ รอบ 172 ★ บอสตัวสูงกว่ากรอบ → ยืดกรอบขึ้นไปให้สูงเกินตัวบอส 10%
	# (ความกว้าง/จังหวะ/ช่องปลอดภัยเท่าเดิม · โดนเฉพาะที่เท้า จึงไม่ยากขึ้น)
	var tall: float = actor.body_size().y * 1.1 if actor.has_method("body_size") else 0.0
	for z in fx.zones:
		var zr: Rect2 = z["rect"]
		if String(z["kind"]) == "pillar" and tall > zr.size.y:
			z["rect"] = Rect2(zr.position.x, zr.end.y - tall, zr.size.x, tall)
	for z in fx.zones:
		fx._end = maxf(fx._end, float(z["at"]) + STRIKE_TIME + 0.15)
	actor.get_parent().add_child(fx)
	fx.global_position = Vector2.ZERO
	return fx


## สร้างกรอบทั้งหมดของท่า — rect เป็นพิกัดโลก (ฐานกรอบ = พื้นใต้เท้าบอส)
static func layout(pattern: String, tx: float, cx: float, facing: int, turn: int, rage: bool, ground: float, mult: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var sp := 0.88 if rage else 1.0
	var t0 := 1.25
	var add := func(x0: float, w: float, h: float, at: float, kind: String) -> void:
		out.append({"rect": Rect2(x0, ground - h, w, h), "at": at, "mult": mult, "kind": kind, "fired": false})
	match pattern:
		"pillars3":
			var order := [-1, 0, 1] if turn % 2 == 0 else [1, 0, -1]
			for i in range(3):
				add.call(tx + float(order[i]) * 300.0 - 110.0, 220.0, PILLAR_H, t0 + i * 0.4 * sp, "pillar")
		"inout":
			var outer_first := turn % 2 == 0
			var t_out := t0 if outer_first else t0 + 1.2 * sp
			var t_in := t0 + 1.2 * sp if outer_first else t0
			add.call(tx - 760.0, 580.0, 460.0, t_out, "pillar")
			add.call(tx + 180.0, 580.0, 460.0, t_out, "pillar")
			add.call(tx - 180.0, 360.0, 460.0, t_in, "pillar")
		"rain":
			for i in range(5):
				add.call(cx + float(facing) * (170.0 + i * 170.0) - 85.0, 170.0, PILLAR_H, 1.0 + i * 0.24 * sp, "pillar")
		"gap3":
			for r in range(2):
				var safe := (turn + r) % 3
				for col in range(3):
					if col == safe:
						continue
					add.call(tx - 580.0 + col * 400.0, 360.0, 460.0, t0 + r * 1.25 * sp, "pillar")
		"escape":
			add.call(tx - 140.0, 280.0, 480.0, t0, "pillar")
			for d in [-1, 1]:
				add.call(tx + float(d) * 380.0 - 130.0, 260.0, 480.0, t0 + 1.15 * sp, "pillar")
		"pendulum":
			var offs := [-360.0, 0.0, 360.0, 0.0, -360.0]
			for i in range(5):
				add.call(tx + offs[i] - 105.0, 210.0, 500.0, t0 + i * 0.7 * sp, "pillar")
		"eruption":
			for o in [-340.0, 0.0, 340.0]:
				add.call(tx + o - 110.0, 220.0, PILLAR_H, t0, "pillar")
			for o in [-170.0, 170.0]:
				add.call(tx + o - 110.0, 220.0, PILLAR_H, t0 + 1.0 * sp, "pillar")
		"stomp3":
			for i in range(3):
				add.call(cx + float(facing) * (260.0 + i * 270.0) - 150.0, 300.0, 300.0, 1.0 + i * 0.5 * sp, "stomp")
		"judgment":
			add.call(tx - 140.0, 280.0, 480.0, t0, "pillar")
			add.call(tx - 650.0, 460.0, 480.0, t0 + 1.15 * sp, "pillar")
			add.call(tx + 190.0, 460.0, 480.0, t0 + 1.15 * sp, "pillar")
			add.call(tx - 140.0, 280.0, 480.0, t0 + 2.3 * sp, "pillar")
		_:
			add.call(tx - 150.0, 300.0, 480.0, t0, "pillar")
	return out


func _finish() -> void:
	if not _done:
		_done = true
		finished.emit()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(caster) or caster.is_queued_for_deletion() or caster.is_dead():
		_finish()
		queue_free()
		return
	elapsed += delta
	for z in zones:
		if not z["fired"] and elapsed >= float(z["at"]):
			z["fired"] = true
			_strike(z)
	if elapsed >= _end:
		_finish()
		queue_free()
		return
	queue_redraw()


func _strike(z: Dictionary) -> void:
	if Game.sfx != null:
		if style == "fire":
			Game.sfx.play_first(["skill_magnum_break", "dark_wave"], 0.8)
		else:
			Game.sfx.play_first(["thunder_strike", "skill_magnum_break"], 0.8)
	if hits >= MAX_HITS or PlayerState.is_dead():
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var feet: Vector2 = player.foot_position() if player.has_method("foot_position") else player.global_position
	var r: Rect2 = z["rect"]
	if feet.x < r.position.x or feet.x > r.end.x or feet.y < r.position.y - 20.0 or feet.y > r.end.y + 40.0:
		return
	if player.has_method("is_invincible") and player.is_invincible():
		if player.has_method("dodge_contact"): player.dodge_contact()   # ★ รอบ 182 ★ หลบพอดี
		return
	var result := Combat.monster_skill_hits_player(data, PlayerState.stats, data.skill_damage_mult * float(z["mult"]))
	if result.miss:
		return
	hits += 1
	player.take_damage(result.damage, KNOCKBACK, 1 if feet.x >= r.get_center().x else -1)


func _draw() -> void:
	for z in zones:
		var r: Rect2 = z["rect"]
		var at: float = z["at"]
		if elapsed < at:
			_draw_warning(r, at)
		elif elapsed < at + STRIKE_TIME:
			_draw_strike(r, (elapsed - at) / STRIKE_TIME, String(z["kind"]))


func _draw_warning(r: Rect2, at: float) -> void:
	var left := at - elapsed
	var af := clampf(1.0 - (left - PREVIEW) / 1.0, 0.25, 1.0)
	var p := clampf(1.0 - left / maxf(0.01, minf(at, PREVIEW + 0.4)), 0.0, 1.0)
	# แสงไล่จากพื้นขึ้นไป (ไม่ใช่กล่องทึบ) — ยิ่งใกล้เวลายิ่งเข้ม/สูง
	draw_texture_rect(_rise_tex(), r, false, Color(color, (0.18 + 0.30 * p) * af))
	var fill_h := r.size.y * (0.25 + 0.75 * p)
	draw_texture_rect(_rise_tex(), Rect2(r.position.x, r.end.y - fill_h, r.size.x, fill_h), false, Color(color.lightened(0.2), 0.35 * p * af))
	# ขอบซ้าย-ขวาจาง ๆ + เส้นพื้นชัด
	var edge := Color(color, 0.55 * af)
	draw_texture_rect(_rise_tex(), Rect2(r.position.x - 1.5, r.position.y, 3.0, r.size.y), false, edge)
	draw_texture_rect(_rise_tex(), Rect2(r.end.x - 1.5, r.position.y, 3.0, r.size.y), false, edge)
	draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y), Color(color.lightened(0.35), 0.95 * af), 5.0)
	# รูนนับถอยหลังบนพื้น: วงรีหดเข้าหาเส้นพื้น
	var mid := r.get_center().x
	draw_set_transform(Vector2(mid, r.end.y), 0.0, Vector2(1.0, 0.22))
	draw_arc(Vector2.ZERO, r.size.x * 0.5 * (1.0 - 0.6 * p) + 6.0, 0.0, TAU, 40, Color(color.lightened(0.4), 0.8 * af), 2.5, true)
	draw_set_transform(Vector2.ZERO)
	var top := r.position.y + 14.0
	var tri := PackedVector2Array([Vector2(mid - 10, top), Vector2(mid + 10, top), Vector2(mid, top + 14)])
	draw_colored_polygon(tri, Color(color, 0.8 * af))


func _draw_strike(r: Rect2, s: float, kind: String) -> void:
	var fade := 1.0 - s * s
	var base := color
	var hot := color.lightened(0.5)
	if style == "fire":
		base = Color(1.0, 0.42, 0.10)
		hot = Color(1.0, 0.86, 0.40)
	var cx := r.get_center().x
	var bottom := r.end.y
	var top := r.position.y - (220.0 if kind == "pillar" else 40.0)
	var h := bottom - top
	var grow := 0.55 + 0.45 * minf(1.0, s * 5.0)
	var w := r.size.x * grow
	# ลำแสง: เรืองนอก (สี) → แกนใน (ขาว) ขอบนุ่มด้วยเท็กซ์เจอร์ไล่สี
	draw_texture_rect(_beam_tex(), Rect2(cx - w * 0.8, top, w * 1.6, h), false, Color(base, 0.45 * fade))
	draw_texture_rect(_beam_tex(), Rect2(cx - w * 0.5, top, w, h), false, Color(hot, 0.85 * fade))
	draw_texture_rect(_beam_tex(), Rect2(cx - w * 0.16, top, w * 0.32, h), false, Color(1, 1, 1, fade))
	if style == "fire":
		for i in range(7):
			var fx := r.position.x + r.size.x * (float(i) + 0.5) / 7.0
			var fh := 70.0 + 60.0 * absf(sin(elapsed * 23.0 + i * 1.7))
			draw_colored_polygon(PackedVector2Array([Vector2(fx - 16, bottom), Vector2(fx + 16, bottom), Vector2(fx + sin(elapsed * 9.0 + i) * 8.0, bottom - fh * (0.4 + fade))]), Color(1.0, 0.72, 0.22, 0.75 * fade))
	else:
		for i in range(5):
			var sx := cx + sin(i * 2.1 + elapsed * 5.0) * w * 0.35
			var sy := bottom - fmod(elapsed * 700.0 + i * 97.0, h)
			draw_circle(Vector2(sx, sy), 3.0 + (i % 2) * 2.0, Color(1, 1, 1, 0.8 * fade))
	# วงกระแทกบนพื้น
	draw_set_transform(Vector2(cx, bottom), 0.0, Vector2(1.0, 0.22))
	var rad := r.size.x * (0.5 + s * 0.9)
	draw_circle(Vector2.ZERO, rad, Color(hot, 0.28 * fade))
	draw_arc(Vector2.ZERO, rad, 0.0, TAU, 48, Color(1, 1, 1, 0.75 * fade), 4.0, true)
	draw_set_transform(Vector2.ZERO)


# ---------- เท็กซ์เจอร์ไล่สี (สร้างครั้งเดียว ใช้ร่วมกันทุกท่า) ----------
static var _beam: GradientTexture2D
static var _rise: GradientTexture2D

static func _beam_tex() -> GradientTexture2D:
	if _beam == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.3, 0.5, 0.7, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.55), Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
		_beam = GradientTexture2D.new()
		_beam.gradient = g
		_beam.width = 64
		_beam.height = 4
	return _beam


static func _rise_tex() -> GradientTexture2D:
	if _rise == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
		_rise = GradientTexture2D.new()
		_rise.gradient = g
		_rise.fill_from = Vector2(0, 1)
		_rise.fill_to = Vector2(0, 0)
		_rise.width = 4
		_rise.height = 64
	return _rise
