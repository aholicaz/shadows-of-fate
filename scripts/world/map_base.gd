## MapBase — สคริปต์กลางของทุกแมพ
##
## หน้าที่: วางผู้เล่นที่จุดเกิด, ตั้งกล้องให้เดินได้ไกลกว่า 1 หน้าจอ,
##          ใส่ชั้นข้อความลอย
##
## โครงสร้าง Scene ของแมพ:
##   Map (Node2D)  <- ใส่สคริปต์นี้
##   ├── Background        (ParallaxBackground / Sprite2D — ตกแต่ง)
##   ├── Terrain           (TileMapLayer หรือ StaticBody2D พื้น)
##   ├── SpawnPoints (Node2D)
##   │   ├── default   (Marker2D)   <- ชื่อต้องตรงกับที่ Portal ส่งมา
##   │   └── from_town (Marker2D)
##   ├── Spawners (Node2D)  <- ใส่ MonsterSpawner ไว้ข้างใน
##   ├── Portals   (Node2D)
##   └── NPCs      (Node2D)
extends Node2D

@export var map_id: StringName = &"prontera_field"
@export var display_name: String = "ทุ่งหญ้าพรอนเทรา"
## ★ บทที่เท่าไหร่ของเนื้อเรื่อง (รอบ 31) ★ 1 = มิดการ์ด · 2 = สวาร์ทัลฟ์เฮม ...
@export var chapter: int = 1
## ชื่อภูมิภาค (โชว์ในมินิแมพ/สมุดเควสในอนาคต) เช่น "มิดการ์ด"
@export var region: String = "มิดการ์ด"

## ★ ขอบเขตของแมพ — กำหนดให้กว้างกว่าหน้าจอได้เลย ★
## เช่น Rect2(0, 0, 4000, 1200) = แมพกว้าง 4000 พิกเซล
@export var map_bounds: Rect2 = Rect2(0, 0, 4000, 1200)

## ★ เปิดอันนี้แล้วไม่ต้องมาแก้ Map Bounds เองทุกครั้ง ★
## ระบบจะวัดขนาดแมพจาก TileMap + กล่องชนของพื้นให้อัตโนมัติ
## ขยายพื้น/วาดกระเบื้องเพิ่ม = แมพกว้างขึ้นเองทันที
@export var auto_fit_bounds: bool = false
## เผื่อขอบซ้าย-ขวา / เผื่อที่ว่างเหนือหัว (พิกเซล)
@export var bounds_padding: Vector2 = Vector2(0, 300)

@export_group("กำแพงล่องหนขอบแมพ")
## ★★ รอบ 47 — กันผู้เล่นและมอนเดินหลุดออกนอกแมพ ★★
## สร้างกำแพงล่องหนที่ขอบซ้าย-ขวาของ Map Bounds ให้อัตโนมัติทุกแมพ ไม่ต้องวางเอง
## อยู่ "นอก" ขอบเขตแมพพอดี (ไม่กินพื้นที่เดิน) และสูงเลยขอบบนไปมาก กระโดด/พุ่งหลบก็ข้ามไม่ได้
@export var edge_walls: bool = true
## ความหนากำแพง — หนาไว้กันตัวที่เคลื่อนเร็ว (พุ่งหลบ 1100 px/s) ทะลุผ่านในเฟรมเดียว
@export var edge_wall_thickness: float = 120.0
## สูงเลยขอบบนของแมพขึ้นไปเท่าไหร่
@export var edge_wall_extra_top: float = 2000.0
## ลึกเลยขอบล่างลงไปเท่าไหร่ (กันช่องว่างระหว่างกำแพงกับพื้น)
@export var edge_wall_extra_bottom: float = 600.0

# ---------------------------------------------------------
# ★★ รอบ 55 — ไม่ให้เดินเลย "ขอบภาพฉาก" ★★
# ปัญหาเดิม: กำแพงอยู่ที่ขอบ Map Bounds ซึ่ง "กว้างกว่าภาพพื้นหลัง" อยู่หลายร้อยพิกเซล
# (เช่นทุ่งวิหาร ภาพจบที่ x 5648 แต่ Map Bounds ถึง 5870) → เดินออกไปยืนบนที่ว่างดำ ๆ ได้
# ตอนนี้ระบบวัดขอบของ "ภาพฉาก" เอง แล้วหุบ Map Bounds เข้ามาให้ (กล้องก็หยุดตามด้วย)
# ★ หุบเข้าอย่างเดียว ไม่ขยายออก ★ แมพที่ภาพกว้างกว่าขอบเขตอยู่แล้ว ไม่มีอะไรเปลี่ยน
# ---------------------------------------------------------
## หุบขอบแมพให้ไม่เกินภาพฉาก (ปิดได้ถ้าแมพไหนตั้งใจให้เดินเลยภาพ)
@export var clamp_bounds_to_art: bool = true
## เว้นจากขอบภาพเข้ามาอีกกี่พิกเซล (กันตัวละครยื่นพ้นภาพครึ่งตัว)
@export var art_edge_margin: float = 40.0
## ★ รอบ 74 ★ ขยายขอบซ้าย-ขวาตามภาพด้วย (ไม่ใช่หุบเข้าอย่างเดียว)
## ขยายได้ไม่เกิน "ขอบพื้นที่ยืนได้จริง" — เปลี่ยนภาพเป็นใบกว้างขึ้น + ยืดพื้นชนตาม = เดินได้เต็มภาพทันที
## ปิดถ้าแมพไหนตั้งใจให้เดินได้แคบกว่าภาพ
@export var bounds_follow_art_x: bool = true

# =========================================================
# ★★ วิดีโอตอนเข้าแมพ (รอบ 59) ★★  เช่น เดินเข้ารอยสายฟ้าครั้งแรก / ประตูนิดาเวลลิร์
# เล่นครั้งเดียว (จำด้วยธง seen_map_<map_id> ในเซฟ) เว้นแต่ปิด Intro Video Once
# =========================================================
@export_group("วิดีโอตอนเข้าแมพ")
@export_file("*.ogv") var intro_video: String = ""
## true = เล่นแค่ครั้งแรกที่เข้าแมพนี้ · false = เล่นทุกครั้ง
@export var intro_video_once: bool = true
## ต้องมีธงนี้ก่อนถึงจะเล่น (ว่าง = ไม่ต้อง) เช่น chapter2_open
@export var intro_video_flag: StringName = &""

@export_group("")
@export var player_scene: PackedScene
@export var camera_zoom: Vector2 = Vector2.ONE

# =========================================================
# ★★ กล้องเห็นฉากสูงเต็มจอ (รอบ 71) ★★
#
# ภาพฉากหลังที่วาดสูง 1200-1300 px แต่จอเกมสูงแค่ 720 → เห็นแค่ครึ่งกลาง ๆ
# เปิดตัวนี้ = กล้องซูมออกให้ "ขอบบนสุดถึงล่างสุดของแมพ" พอดีจอ (ตามความสูงของ map_bounds)
# แนวนอนยังเลื่อนตามตัวละครเหมือนเดิม · ปรับขนาดหน้าต่างเกมเมื่อไหร่ก็คำนวณใหม่ให้เอง
#
# ★ แลกกับ ★ ตัวละคร/มอนเล็กลงตามสัดส่วน (แมพสูง 1300 บนจอ 720 = เหลือ 55%)
# ถ้าเล็กเกินไป ตั้ง Camera Min Zoom สูงขึ้น (แต่จะเห็นไม่ครบทั้งสูง) หรือปิดเฉพาะแมพนั้น
# =========================================================
@export_group("กล้องเห็นฉากสูงเต็มจอ")
## เปิด = ซูมออกให้เห็นแมพสูงเต็มจอ · ปิด = ใช้ Camera Zoom ตามที่ตั้ง (แบบเดิม)
@export var camera_fit_height: bool = true
## ซูมออกได้ต่ำสุดแค่ไหน (0.5 = ตัวละครเหลือครึ่งหนึ่ง) กันเล็กจนมองไม่เห็น
@export_range(0.3, 1.0, 0.01) var camera_min_zoom: float = 0.5
@export_group("")
## กล้องตามแบบนุ่มนวล (0 = ติดตัวเป๊ะ)
@export_range(0.0, 20.0) var camera_smoothing: float = 6.0
## กล้องเลื่อนขึ้นเล็กน้อยเพื่อเห็นข้างหน้ามากขึ้น
@export var camera_offset: Vector2 = Vector2(0, -60)

var player: Node2D
var camera: Camera2D


func _ready() -> void:
	add_to_group("map")
	PlayerState.current_map_id = map_id
	PlayerState.set_last_town(map_id)      # ★ รอบ 60 — จำเมืองล่าสุดไว้ให้ปีกแห่งวาลคีรี ★
	if auto_fit_bounds:
		map_bounds = _measure_bounds()
		print("[Map] %s ขนาดแมพที่วัดได้: %s" % [map_id, str(map_bounds)])
	if clamp_bounds_to_art:
		_clamp_bounds_to_art()
	_ensure_floating_text_layer()
	_build_edge_walls()
	_spawn_player()
	_setup_camera()
	_warm_sprite_fit()
	# ★ รอบ 52 — เพลงประจำแมพ ★ หาไฟล์ Sprites/music/<map_id>.mp3 ให้เอง (ไม่มี = เงียบ)
	if Game.music != null:
		Game.music.play_for_map(map_id)
	Events.say(display_name)
	_play_intro_video()


## ★ รอบ 59 ★ วิดีโอตอนเข้าแมพ (ไม่มีไฟล์/ดูไปแล้ว = ไม่ทำอะไร)
func _play_intro_video() -> void:
	if intro_video == "" or not ResourceLoader.exists(intro_video):
		return
	if intro_video_flag != &"" and not PlayerState.has_flag(intro_video_flag):
		return
	var seen := StringName("seen_map_" + String(map_id))
	if intro_video_once and PlayerState.has_flag(seen):
		return
	PlayerState.set_flag(seen)
	UI.play_video.call_deferred(intro_video)      # รอให้แมพ/ผู้เล่นตั้งตัวก่อน 1 เฟรม


# =========================================================
# วัดขนาดแมพจากของที่วางไว้จริง
# =========================================================
func _measure_bounds() -> Rect2:
	var rect := Rect2()
	var found := false

	for node in _all_descendants(self):
		var r := _rect_of(node)
		if r.size == Vector2.ZERO:
			continue
		rect = r if not found else rect.merge(r)
		found = true

	if not found:
		return map_bounds

	# เผื่อขอบซ้ายขวา + เผื่อที่ว่างเหนือหัวไว้ให้กระโดด
	return rect.grow_individual(bounds_padding.x, bounds_padding.y, bounds_padding.x, 0.0)


func _rect_of(node: Node) -> Rect2:
	# กระเบื้องที่วาดไว้
	if node.has_method("get_used_rect") and node.has_method("map_to_local"):
		var used: Rect2i = node.get_used_rect()
		if used.size.x <= 0 or used.size.y <= 0:
			return Rect2()
		var top_left: Vector2 = node.to_global(node.map_to_local(used.position))
		var bottom_right: Vector2 = node.to_global(node.map_to_local(used.position + used.size))
		return Rect2(top_left, bottom_right - top_left).abs()

	# กล่องชนของพื้น / แท่น
	if node is CollisionShape2D:
		var shape: Shape2D = (node as CollisionShape2D).shape
		var scale_v: Vector2 = (node as CollisionShape2D).global_scale
		if shape is RectangleShape2D:
			var sz: Vector2 = (shape as RectangleShape2D).size * scale_v
			return Rect2((node as CollisionShape2D).global_position - sz * 0.5, sz)
		if shape is CircleShape2D:
			var rad: float = (shape as CircleShape2D).radius * maxf(scale_v.x, scale_v.y)
			return Rect2((node as CollisionShape2D).global_position - Vector2(rad, rad), Vector2(rad, rad) * 2.0)
		if shape is CapsuleShape2D:
			var cap := shape as CapsuleShape2D
			var sz2 := Vector2(cap.radius * 2.0, cap.height) * scale_v
			return Rect2((node as CollisionShape2D).global_position - sz2 * 0.5, sz2)

	return Rect2()


# =========================================================
# ★ รอบ 55 — หุบขอบแมพให้พอดีกับภาพฉาก ★
# =========================================================
## ขอบซ้าย-ขวาของ "ภาพฉาก" ในพิกัดโลก — คืน Vector2(ซ้าย, ขวา) · คืน Vector2.ZERO ถ้าหาไม่เจอ
##
## นับเฉพาะภาพที่ "กว้างพอจะเป็นฉาก" (>= 25% ของความกว้างแมพ) เพื่อไม่ให้ก้อนหิน/ป้าย/มอน
## ไปดึงขอบให้กว้างเกินจริง · ข้ามภาพที่ซ่อนอยู่ และตัวละคร/มอน/NPC/ของตก
func art_span() -> Vector2:
	var rects := _art_rects()
	if rects.is_empty():
		return Vector2.ZERO
	var left := INF
	var right := -INF
	for r in rects:
		left = minf(left, r.position.x)
		right = maxf(right, r.position.x + r.size.x)
	if right <= left:
		return Vector2.ZERO
	return Vector2(left, right)


## ★ รอบ 72 ★ ขอบบน-ล่างของภาพฉาก (พิกัดโลก) — ใช้เกณฑ์เดียวกับ art_span()
## คืน (top, bottom) หรือ Vector2.ZERO ถ้าไม่มีภาพฉาก
func art_span_y() -> Vector2:
	var rects := _art_rects()
	if rects.is_empty():
		return Vector2.ZERO
	var top := INF
	var bottom := -INF
	for r in rects:
		top = minf(top, r.position.y)
		bottom = maxf(bottom, r.position.y + r.size.y)
	if bottom <= top:
		return Vector2.ZERO
	return Vector2(top, bottom)


## ★ รอบ 73 ★ กรอบ (พิกัดโลก) ของทุกชิ้นที่นับเป็น "ภาพฉาก"
##
## กติกา: ชิ้นที่กว้าง >= 25% ของแมพ · มองเห็นอยู่ · ไม่ใช่ตัวละคร/มอน/NPC
## และ ★ ถ้าแมพมีภาพจริง (Sprite/TextureRect/Polygon ที่มี texture) แม้แต่ชิ้นเดียว
## จะนับเฉพาะภาพจริง — Polygon สีล้วน (Sky/FarLayer/Ground Visual สมัย placeholder) ไม่นับ ★
## เพราะแผ่นสีพวกนี้มักยื่นเลยขอบภาพ ทำให้เห็นแถบสีทึบ ๆ ใต้/เหนือภาพ (พรอนเทรา รอบ 73)
## แมพที่ยังไม่มีภาพเลย (placeholder ล้วน) ยังนับแผ่นสีเหมือนเดิม
func _art_rects() -> Array[Rect2]:
	var min_w: float = map_bounds.size.x * 0.25
	var textured: Array[Rect2] = []
	var flat: Array[Rect2] = []
	for node in _all_descendants(self):
		if not (node is Sprite2D or node is TextureRect or node is Polygon2D):
			continue
		var item := node as CanvasItem
		if not item.is_visible_in_tree():
			continue
		if _is_actor(node):
			continue
		var r: Rect2 = _canvas_item_rect(item)
		if r.size.x < min_w:
			continue
		if _has_texture(item):
			textured.append(r)
		else:
			flat.append(r)
	return textured if not textured.is_empty() else flat


func _has_texture(item: CanvasItem) -> bool:
	if item is Sprite2D:
		return (item as Sprite2D).texture != null
	if item is TextureRect:
		return (item as TextureRect).texture != null
	if item is Polygon2D:
		return (item as Polygon2D).texture != null
	return false


## เป็นตัวละคร/มอน/NPC/ของตก ไหม (ไล่ดูตัวเองและพ่อแม่ขึ้นไป)
func _is_actor(node: Node) -> bool:
	var n: Node = node
	while n != null and n != self:
		if n.is_in_group("player") or n.is_in_group("enemy") or n.is_in_group("npc") \
				or n.is_in_group("dropped_item") or n.is_in_group("portal"):
			return true
		n = n.get_parent()
	return false


## กรอบของภาพในพิกัดโลก (คิด scale/หมุนแล้ว)
func _canvas_item_rect(item: CanvasItem) -> Rect2:
	var local := Rect2()
	if item is Sprite2D:
		local = (item as Sprite2D).get_rect()
	elif item is TextureRect:
		local = Rect2(Vector2.ZERO, (item as TextureRect).size)
	elif item is Polygon2D:
		var poly: PackedVector2Array = (item as Polygon2D).polygon
		if poly.size() < 2:
			return Rect2()
		local = Rect2(poly[0], Vector2.ZERO)
		for i in range(1, poly.size()):
			local = local.expand(poly[i])
		local.position += (item as Polygon2D).offset
	else:
		return Rect2()
	if local.size == Vector2.ZERO:
		return Rect2()
	var xf := item.get_global_transform()
	var out := Rect2(xf * local.position, Vector2.ZERO)
	for corner in [local.position + Vector2(local.size.x, 0.0),
			local.position + local.size, local.position + Vector2(0.0, local.size.y)]:
		out = out.expand(xf * corner)
	return out


## ★ รอบ 74 ★ ขอบซ้าย-ขวาของ "พื้นที่ยืนได้จริง" (พิกัดโลก)
##
## นับเฉพาะกล่องชนของ StaticBody2D ที่ **กว้างพอจะเป็นพื้นหลักของแมพ** (>= 25% ของความกว้างแมพ)
## → พื้นลอยเล็ก ๆ (Plat0..N) และกำแพงขอบแมพไม่นับ
## ใช้เป็น "เพดาน" ตอนขยายขอบแมพตามภาพ — ขยายได้เท่าที่มีพื้นให้ยืนเท่านั้น
## คืน Vector2.ZERO ถ้าแมพไม่มีพื้นหลัก (เช่น ใช้ TileMap) → ตกกลับไปโหมดหุบเข้าอย่างเดียว
func floor_span_x() -> Vector2:
	var min_w: float = map_bounds.size.x * 0.25
	var left := INF
	var right := -INF
	for node in _all_descendants(self):
		if not (node is CollisionShape2D or node is CollisionPolygon2D):
			continue
		if not (node.get_parent() is StaticBody2D):
			continue
		if not (node as Node2D).is_visible_in_tree():
			continue
		var local := Rect2()
		if node is CollisionShape2D:
			var sh: Shape2D = (node as CollisionShape2D).shape
			if sh is RectangleShape2D:
				local = Rect2(-(sh as RectangleShape2D).size * 0.5, (sh as RectangleShape2D).size)
			elif sh is CapsuleShape2D:
				var c := sh as CapsuleShape2D
				local = Rect2(-Vector2(c.radius, c.height * 0.5), Vector2(c.radius * 2.0, c.height))
			else:
				continue
		else:
			var poly: PackedVector2Array = (node as CollisionPolygon2D).polygon
			if poly.size() < 2:
				continue
			local = Rect2(poly[0], Vector2.ZERO)
			for i in range(1, poly.size()):
				local = local.expand(poly[i])
		var xf := (node as Node2D).get_global_transform()
		var out := Rect2(xf * local.position, Vector2.ZERO)
		for corner in [local.position + Vector2(local.size.x, 0.0),
				local.position + local.size, local.position + Vector2(0.0, local.size.y)]:
			out = out.expand(xf * corner)
		if out.size.x < min_w:
			continue
		left = minf(left, out.position.x)
		right = maxf(right, out.position.x + out.size.x)
	if left == INF or right <= left:
		return Vector2.ZERO
	return Vector2(left, right)


## Map Bounds ซ้าย-ขวาให้พอดีภาพฉาก — แต่ไม่หุบจนบังประตู/จุดเกิด
##
## ★ รอบ 74 ★ เดิม "หุบเข้าอย่างเดียว" — พอผู้ใช้เปลี่ยนภาพฉากเป็นใบกว้างขึ้น (+ ยืดพื้นชนตาม)
## ขอบแมพยังเท่าเดิม เดินไปสุดซ้าย/ขวาของภาพไม่ได้ (พรอนเทรา ภาพ 7239 px แต่เดินได้แค่ 3620)
## ตอนนี้ขยายออกได้ด้วย **แต่ไม่เกินขอบพื้นที่ยืนได้จริง** (`floor_span_x()`) — ไม่มีพื้น = ไม่ขยาย
func _clamp_bounds_to_art() -> void:
	var span := art_span()
	if span == Vector2.ZERO:
		return
	var left: float = maxf(map_bounds.position.x, span.x + art_edge_margin)
	var right: float = minf(map_bounds.position.x + map_bounds.size.x, span.y - art_edge_margin)
	if bounds_follow_art_x:
		var fx := floor_span_x()
		if fx != Vector2.ZERO:
			left = maxf(span.x + art_edge_margin, fx.x)
			right = minf(span.y - art_edge_margin, fx.y)

	# ★ กันหุบจนประตู/จุดเกิดอยู่นอกกำแพง ★ (เข้าแมพแล้วติดกำแพง/ออกประตูไม่ได้)
	var keep: float = KEEP_INSIDE_MARGIN
	for node in _all_descendants(self):
		var p: Vector2
		if node is Marker2D and node.get_parent() != null and node.get_parent().name == "SpawnPoints":
			p = (node as Marker2D).global_position
		elif node.is_in_group("portal") and node is Node2D:
			p = (node as Node2D).global_position
		else:
			continue
		left = minf(left, p.x - keep)
		right = maxf(right, p.x + keep)

	if right - left < 200.0:
		push_warning("[Map] %s หุบขอบตามภาพแล้วแคบเกินไป — ข้าม" % map_id)
		return

	# ★★ รอบ 72 — หุบ "บน-ล่าง" ตามภาพด้วย ★★
	# กล้องโหมดเห็นสูงเต็มจอ (รอบ 71) ซูมตามความสูงของ map_bounds
	# ถ้าภาพฉากถูกลาก/ย่อใน Godot จนเตี้ยกว่า map_bounds → กล้องจะเห็น "ที่ว่างเทา ๆ" ใต้ภาพ
	# แก้ที่ต้นทาง: ให้ map_bounds บน-ล่าง = ขอบภาพเป๊ะ (ต่างจากแกน x ที่หุบเข้าอย่างเดียว —
	# แกน y ขยายออกได้ด้วย เพราะแค่เปลี่ยนช่วงที่กล้องมอง ไม่ได้เปิดที่ให้เดินเพิ่ม)
	# ลากภาพขึ้น/ลง/ย่อใน Godot ยังไง กล้องก็เห็นครบทั้งภาพ ไม่มีที่ว่าง
	# ยกเว้นห้ามแคบจนประตู/จุดเกิดหลุดออกนอกขอบ
	var top: float = map_bounds.position.y
	var bottom: float = map_bounds.position.y + map_bounds.size.y
	var sy := art_span_y()
	if sy != Vector2.ZERO:
		top = sy.x
		bottom = sy.y
		for node in _all_descendants(self):
			var p: Vector2
			if node is Marker2D and node.get_parent() != null and node.get_parent().name == "SpawnPoints":
				p = (node as Marker2D).global_position
			elif node.is_in_group("portal") and node is Node2D:
				p = (node as Node2D).global_position
			else:
				continue
			top = minf(top, p.y - keep)
			bottom = maxf(bottom, p.y + keep)
		if bottom - top < 300.0:
			top = map_bounds.position.y
			bottom = map_bounds.position.y + map_bounds.size.y

	var before := map_bounds
	map_bounds = Rect2(left, top, right - left, bottom - top)
	if before.is_equal_approx(map_bounds):
		return
	print("[Map] %s ปรับขอบตามภาพฉาก: x %.0f..%.0f → %.0f..%.0f · y %.0f..%.0f → %.0f..%.0f" % [
		map_id, before.position.x, before.position.x + before.size.x, left, right,
		before.position.y, before.position.y + before.size.y, top, bottom])
	# หุบเยอะผิดปกติ = ภาพฉากสั้นกว่าแมพจริง ๆ (ควรขยายภาพ ไม่ใช่ปล่อยให้เดินไปที่ว่าง)
	var cut: float = maxf(left - before.position.x, (before.position.x + before.size.x) - right)
	if cut > BIG_CLAMP_WARN:
		push_warning("[Map] %s ภาพฉากสั้นกว่าขอบเขตแมพ %.0f px — หุบให้แล้ว (อยากเดินได้กว้างเท่าเดิม ต้องขยายภาพฉาก)" % [map_id, cut])


func _all_descendants(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in root.get_children():
		out.append(child)
		out.append_array(_all_descendants(child))
	return out


# =========================================================
# ★ รอบ 47 — กำแพงล่องหนขอบซ้าย-ขวาของแมพ ★
#
# ทำไมใช้กำแพงจริง ไม่ clamp ตำแหน่ง: กำแพงเป็น StaticBody2D ชั้นเดียวกับพื้น
# ผู้เล่น (mask 1) และมอน (mask 1) จึงชนด้วย move_and_slide เหมือนชนกำแพงปกติ —
# ท่าเดิน/พุ่งหลบ/AI ไล่ตาม ไม่ต้องแก้อะไรเลย และ is_on_wall() ก็ทำงานถูก
# (พุ่งหลบมี dodge_stop_on_wall จึงหยุดที่ขอบพอดี ไม่ทะลุ)
#
# กำแพงอยู่นอก Map Bounds พอดี — ประตูกับจุดเกิดทุกแมพห่างจากขอบ ≥ 40 px จึงไม่โดนบัง
# =========================================================
## ประตู/จุดเกิด ต้องอยู่ในขอบแมพอย่างน้อยเท่านี้ (พิกเซล)
const KEEP_INSIDE_MARGIN := 90.0
## หุบเกินกี่พิกเซลถึงจะเตือนใน Output (แปลว่าภาพฉากสั้นกว่าแมพมาก)
const BIG_CLAMP_WARN := 300.0


func _build_edge_walls() -> void:
	if not edge_walls or get_node_or_null("EdgeWalls") != null:
		return

	var body := StaticBody2D.new()
	body.name = "EdgeWalls"
	body.collision_layer = 1    # ชั้นเดียวกับพื้น = ทั้งผู้เล่นและมอนชน
	body.collision_mask = 0     # กำแพงไม่ต้องตรวจว่าชนอะไร
	add_child(body)

	var t: float = maxf(8.0, edge_wall_thickness)
	var top: float = map_bounds.position.y - edge_wall_extra_top
	var bottom: float = map_bounds.position.y + map_bounds.size.y + edge_wall_extra_bottom
	var h: float = bottom - top
	var cy: float = (top + bottom) * 0.5
	var left_x: float = map_bounds.position.x - t * 0.5
	var right_x: float = map_bounds.position.x + map_bounds.size.x + t * 0.5

	for entry in [["Left", left_x], ["Right", right_x]]:
		var shape := RectangleShape2D.new()
		shape.size = Vector2(t, h)
		var col := CollisionShape2D.new()
		col.name = String(entry[0])
		col.shape = shape
		col.position = Vector2(float(entry[1]), cy)
		body.add_child(col)


func _ensure_floating_text_layer() -> void:
	if get_node_or_null("FloatingTextLayer") != null:
		return
	var layer := Node2D.new()
	layer.name = "FloatingTextLayer"
	layer.set_script(load("res://scripts/world/floating_text_layer.gd"))
	add_child(layer)


# =========================================================
# วางผู้เล่น
# =========================================================
func _spawn_player() -> void:
	player = get_tree().get_first_node_in_group("player")

	if player == null:
		if player_scene == null:
			push_error("[Map] ยังไม่ได้ใส่ Player Scene ให้แมพ %s" % map_id)
			return
		player = player_scene.instantiate()
		add_child(player)

	player.global_position = _find_spawn_position()


func _find_spawn_position() -> Vector2:
	var wanted := Game.requested_spawn_point()
	var points := get_node_or_null("SpawnPoints")

	if points != null:
		var target := points.get_node_or_null(String(wanted))
		if target == null:
			target = points.get_node_or_null("default")
		if target == null and points.get_child_count() > 0:
			target = points.get_child(0)
		if target is Node2D:
			return (target as Node2D).global_position

	return map_bounds.position + map_bounds.size * 0.5


# =========================================================
# กล้อง — จุดสำคัญที่ทำให้แมพเดินได้ไกลกว่า 1 หน้าจอ
# =========================================================
func _setup_camera() -> void:
	if player == null:
		return

	camera = player.get_node_or_null("Camera2D")
	if camera == null:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		player.add_child(camera)

	camera.zoom = camera_zoom
	camera.offset = camera_offset
	# ★ รอบ 71 ★ ซูมออกให้เห็นแมพสูงเต็มจอ + คำนวณใหม่เมื่อหน้าต่างเปลี่ยนขนาด
	if camera_fit_height:
		_apply_fit_zoom()
		var vp := get_viewport()
		if vp != null and not vp.size_changed.is_connected(_apply_fit_zoom):
			vp.size_changed.connect(_apply_fit_zoom)

	camera.limit_left = int(map_bounds.position.x)
	camera.limit_top = int(map_bounds.position.y)
	camera.limit_right = int(map_bounds.position.x + map_bounds.size.x)
	camera.limit_bottom = int(map_bounds.position.y + map_bounds.size.y)
	camera.limit_smoothed = true

	camera.position_smoothing_enabled = camera_smoothing > 0.0
	camera.position_smoothing_speed = camera_smoothing

	camera.make_current()


## ★ รอบ 71 ★ ซูมกล้องให้ความสูงของแมพ (map_bounds) พอดีกับความสูงจอ
## Godot: zoom < 1 = ซูมออก · เห็นความสูงโลก = สูงจอ ÷ zoom → zoom = สูงจอ ÷ สูงแมพ
func _apply_fit_zoom() -> void:
	if camera == null or not camera_fit_height:
		return
	var vp := get_viewport()
	if vp == null:
		return
	var view_h: float = vp.get_visible_rect().size.y
	var map_h: float = map_bounds.size.y
	if view_h <= 0.0 or map_h <= 0.0:
		return
	# ไม่ซูม "เข้า" เกิน 1 (แมพเตี้ยกว่าจอก็ปล่อยไว้ปกติ) · ไม่ซูมออกต่ำกว่า Camera Min Zoom
	var z: float = clampf(view_h / map_h, camera_min_zoom, 1.0)
	camera.zoom = Vector2(z, z)
	# ★ กับดัก 102 ★ Camera Offset ไม่โดน limit_* กัน — ถ้าเห็นทั้งสูงอยู่แล้วแต่ยังมี offset
	# แนวตั้ง กล้องจะเลยขอบแมพไปเป็นแถบเปล่า ๆ ด้านบน → ตอนเห็นครบทั้งสูง ให้ offset.y = 0
	if view_h / z >= map_h - 1.0:
		camera.offset = Vector2(camera_offset.x, 0.0)
	else:
		camera.offset = camera_offset


## ความสูงโลกที่กล้องเห็นอยู่ตอนนี้ (ไว้ให้เทสต์/ดีบัก)
func camera_visible_height() -> float:
	if camera == null:
		return 0.0
	var vp := get_viewport()
	if vp == null or camera.zoom.y <= 0.0:
		return 0.0
	return vp.get_visible_rect().size.y / camera.zoom.y


# =========================================================
# ★ รอบ 44 — อุ่นเครื่อง auto-fit ตอนโหลดแมพ ★
# วัดขอบภาพของผู้เล่น + มอนทุกชนิดในแมพนี้ให้เสร็จระหว่างจอยังมืด
# (SpriteFit จำไว้ทั้งเกม — มอนเกิดกลางเกมจะไม่ต้องดึงภาพจากการ์ดจออีก = ไม่กระตุก)
# =========================================================
func _warm_sprite_fit() -> void:
	var n := 0
	if player != null:
		var ps := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if ps != null:
			n += SpriteFit.warm(ps.sprite_frames)
	for node in _all_descendants(self):
		if "monster_types" in node:
			for md in node.monster_types:
				if md != null and "sprite_frames" in md:
					n += SpriteFit.warm(md.sprite_frames)
		if "data" in node and node.data != null and "sprite_frames" in node.data:
			n += SpriteFit.warm(node.data.sprite_frames)
	if n > 0:
		print("[Map] %s อุ่นเครื่อง auto-fit %d ท่า" % [map_id, n])
