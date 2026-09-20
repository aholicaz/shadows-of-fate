## DamageNumber — ตัวเลขดาเมจสไตล์ MapleStory (รอบ 34)
##
## ตัวเลขแต่ละหลักเป็นรูปจากชีท Sprites/ui/damage_digits.png (ไม่ใช่ฟอนต์)
## เด้งโผล่ทีละหลักจากซ้ายไปขวา (ใหญ่ก่อนแล้วหดลง) → ลอยขึ้นช้า ๆ → จางหาย
##
## สไตล์ (แถวในชีท): 0 ปกติ ม่วง · 1 คริ ส้มทอง · 2 โดนตี แดง · 3 ฮีล เขียว
## ★ อยากเปลี่ยนหน้าตาตัวเลข ★ แก้สีใน make_damage_digits.py แล้วรันใหม่ หรือวาดชีทเองช่องละ 56x72
class_name DamageNumber
extends Node2D

const SHEET_PATH := "res://Sprites/ui/damage_digits.png"
const CELL := Vector2(56, 72)
## หลักตัวเลขซ้อนทับกันนิดหน่อยให้ดูแน่น (เหมือน Maple)
const ADVANCE := 42.0
## เวลาที่แต่ละหลักโผล่ห่างกัน
const STAGGER := 0.035

enum Style { NORMAL, CRIT, HURT, HEAL }

static var _sheet: Texture2D

## ข้อความตัวเลข (ไว้ให้เทสต์/ดีบักอ่าน) และขนาดกล่องรวม
var text: String = ""
var box: Vector2 = Vector2.ZERO
var _digit_scale: float = 1.0

# =========================================================
# ★ รอบ 146 ★ คริแบบ "ผลึกแตก" — ค้างให้อ่าน → รอยร้าว → แตกเป็นเศษตกลงพื้น
# ปรับความรู้สึกได้ที่ค่าพวกนี้
# =========================================================
## ค้างนิ่งให้อ่านตัวเลขกี่วินาทีก่อนร้าว
const SHATTER_HOLD := 0.30
## รอยร้าวโชว์กี่วินาทีก่อนแตก
const SHATTER_CRACK := 0.08
## เศษปลิวอยู่กี่วินาที (จางช่วงท้าย)
const SHATTER_LIFE := 0.55
## แรงโน้มถ่วงของเศษ (px/s²) · ความเร็วกระเด็นออก · ความเร็วขึ้น
const SHATTER_GRAVITY := 1500.0
const SHATTER_SPEED := 220.0
const SHATTER_UP := 260.0
## เศษต่อหลัก (สามเหลี่ยมพัดจากจุดกลาง)
const SHATTER_PIECES := 6
## พื้นให้เศษเด้ง = ต่ำกว่าตำแหน่งตัวเลขกี่ px (ประมาณเท้ามอน)
const SHATTER_FLOOR := 90.0

var _pieces: Array = []      # [{node, vel, spin}]
var _shattered := false


## กรอบบนจอ (มุมซ้ายบน) — ตัวเลขวาดจากจุดกึ่งกลาง
func rect() -> Rect2:
	return Rect2(global_position - box * 0.5, box)


## สร้างหลักตัวเลข · คืนขนาดกล่องรวม (ไว้ให้ FloatingTextLayer จองพื้นที่กันทับ)
## instant = โผล่พร้อมกันทุกหลัก (ใช้กับคริแบบผลึก) ★ รอบ 146 ★
func setup(value: int, style: int, scale_mul: float = 1.0, instant: bool = false) -> Vector2:
	if _sheet == null:
		_sheet = load(SHEET_PATH)
	var digits := str(absi(value))
	text = digits
	var n := digits.length()
	var total_w: float = (ADVANCE * (n - 1) + CELL.x) * scale_mul
	box = Vector2(total_w, CELL.y * scale_mul)
	var x0: float = -total_w * 0.5 + CELL.x * 0.5 * scale_mul

	for i in range(n):
		var d := int(digits[i])
		var spr := Sprite2D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = _sheet
		atlas.region = Rect2(d * CELL.x, style * CELL.y, CELL.x, CELL.y)
		spr.texture = atlas
		spr.position = Vector2(x0 + i * ADVANCE * scale_mul, 0)
		# หลักท้าย ๆ อยู่หน้าหลักก่อน (ซ้อนทับสวยกว่า)
		spr.z_index = i
		spr.scale = Vector2(1.9, 1.9) * scale_mul
		spr.modulate.a = 0.0
		add_child(spr)

		# ★ เด้งโผล่ทีละหลัก ★ ใหญ่ → หด (TRANS_BACK ให้เด้งเกินนิดแล้วกลับ)
		var tw := create_tween()
		if instant:
			# ★ รอบ 146 ★ คริ: ทุกหลักโผล่พร้อมกัน 1.5 → 1 ใน 0.1 วิ
			spr.modulate.a = 1.0
			spr.scale = Vector2(1.5, 1.5) * scale_mul
			tw.tween_property(spr, "scale", Vector2(scale_mul, scale_mul), 0.10) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			tw.tween_interval(STAGGER * i)
			tw.tween_callback(func(): spr.modulate.a = 1.0)
			tw.tween_property(spr, "scale", Vector2(scale_mul, scale_mul), 0.22) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_digit_scale = scale_mul
	return Vector2(total_w, CELL.y * scale_mul)


## เล่นการลอยขึ้น + จางหาย แล้วลบตัวเองทิ้ง
func play(rise: Vector2, life: float, on_done: Callable) -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	# ลอยขึ้น: เร็วตอนแรก ช้าตอนท้าย
	tw.tween_property(self, "position", position + rise, life) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# จางเฉพาะช่วงท้าย
	tw.tween_property(self, "modulate:a", 0.0, life * 0.35).set_delay(life * 0.65)
	tw.chain().tween_callback(func():
		on_done.call()
		queue_free())


## ★ รอบ 146 ★ เวอร์ชันคริ: ค้าง → ร้าว → แตกกระจาย (ไม่ลอยขึ้น)
func play_shatter(on_done: Callable) -> void:
	var tw := create_tween()
	tw.tween_interval(SHATTER_HOLD)
	tw.tween_callback(_show_cracks)
	tw.tween_interval(SHATTER_CRACK)
	tw.tween_callback(_shatter)
	tw.tween_interval(SHATTER_LIFE)
	tw.tween_callback(func():
		on_done.call()
		queue_free())


func _show_cracks() -> void:
	var c := _CrackDraw.new()
	c.box = box
	c.z_index = 20
	add_child(c)


## แทนที่หลักตัวเลขแต่ละหลักด้วยสามเหลี่ยม SHATTER_PIECES ชิ้น (พัดจากจุดกลางสุ่ม → ต่อกันสนิทไม่มีช่องว่าง)
func _shatter() -> void:
	if _shattered:
		return
	_shattered = true
	var digits: Array = []
	for ch in get_children():
		if ch is Sprite2D:
			digits.append(ch)
	for spr: Sprite2D in digits:
		var atlas := spr.texture as AtlasTexture
		if atlas == null:
			continue
		var cell_origin: Vector2 = atlas.region.position
		var s: float = _digit_scale
		# จุดกลางสุ่มใกล้ ๆ กลางช่อง
		var c := Vector2(randf_range(0.3, 0.7) * CELL.x, randf_range(0.3, 0.7) * CELL.y)
		# จุดรอบขอบช่อง (เดินตามเส้นรอบรูป) — ใส่ jitter ให้ชิ้นไม่เท่ากัน
		var ring: Array = []
		var n := SHATTER_PIECES
		for i in range(n):
			var u: float = (float(i) + randf_range(0.15, 0.85)) / float(n)
			ring.append(_perimeter_point(u))
		for i in range(n):
			var a: Vector2 = ring[i]
			var b: Vector2 = ring[(i + 1) % n]
			var centroid := (c + a + b) / 3.0
			var poly := Polygon2D.new()
			poly.texture = _sheet
			poly.polygon = PackedVector2Array([c - centroid, a - centroid, b - centroid])
			poly.uv = PackedVector2Array([cell_origin + c, cell_origin + a, cell_origin + b])
			# วางให้ตรงกับหลักเดิม (Sprite2D centered → local = cell - CELL/2)
			poly.position = spr.position + (centroid - CELL * 0.5) * s
			poly.scale = Vector2(s, s)
			poly.z_index = spr.z_index
			add_child(poly)
			var dir := (centroid - c).normalized() if centroid != c else Vector2.UP
			var vel := dir * SHATTER_SPEED * randf_range(0.6, 1.3) + Vector2(randf_range(-40, 40), -SHATTER_UP * randf_range(0.5, 1.0))
			_pieces.append({"node": poly, "vel": vel, "spin": randf_range(-9.0, 9.0), "bounced": false})
		spr.queue_free()
	set_process(true)


func _perimeter_point(u: float) -> Vector2:
	var per := 2.0 * (CELL.x + CELL.y)
	var d := u * per
	if d < CELL.x:
		return Vector2(d, 0)
	d -= CELL.x
	if d < CELL.y:
		return Vector2(CELL.x, d)
	d -= CELL.y
	if d < CELL.x:
		return Vector2(CELL.x - d, CELL.y)
	d -= CELL.x
	return Vector2(0, CELL.y - d)


func _process(delta: float) -> void:
	if _pieces.is_empty():
		return
	var floor_y: float = box.y * 0.5 + SHATTER_FLOOR
	var t_alive: float = 0.0
	for p in _pieces:
		var node: Polygon2D = p["node"]
		if not is_instance_valid(node):
			continue
		var vel: Vector2 = p["vel"]
		vel.y += SHATTER_GRAVITY * delta
		node.position += vel * delta
		node.rotation += float(p["spin"]) * delta
		if node.position.y > floor_y and not bool(p["bounced"]):
			node.position.y = floor_y
			vel.y = -vel.y * 0.35
			vel.x *= 0.6
			p["bounced"] = true
		elif node.position.y > floor_y:
			node.position.y = floor_y
			vel = Vector2(vel.x * 0.9, 0.0)
		p["vel"] = vel
		p["life"] = float(p.get("life", 0.0)) + delta
		t_alive = float(p["life"])
		node.modulate.a = 1.0 - clampf((t_alive - SHATTER_LIFE * 0.45) / (SHATTER_LIFE * 0.55), 0.0, 1.0)


## รอยร้าววิ่งผ่านตัวเลข (เส้นหักซิกแซก ขาว + เงาเข้ม)
class _CrackDraw extends Node2D:
	var box: Vector2 = Vector2.ZERO
	var _lines: Array = []

	func _ready() -> void:
		var n: int = 3 + int(box.x / 60.0)
		for i in range(n):
			var pts := PackedVector2Array()
			var x := randf_range(-box.x * 0.45, box.x * 0.45)
			var y := randf_range(-box.y * 0.5, -box.y * 0.2)
			pts.append(Vector2(x, y))
			for k in range(4):
				x = clampf(x + randf_range(-box.x * 0.18, box.x * 0.18), -box.x * 0.5, box.x * 0.5)
				y = minf(y + box.y * randf_range(0.12, 0.3), box.y * 0.5)
				pts.append(Vector2(x, y))
			_lines.append(pts)
		queue_redraw()

	func _draw() -> void:
		for pts: PackedVector2Array in _lines:
			draw_polyline(pts, Color(0.1, 0.05, 0.0, 0.9), 3.0)
			draw_polyline(pts, Color(1, 1, 1, 0.95), 1.5)

