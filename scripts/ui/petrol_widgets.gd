## PetrolWidgets — ชิ้นส่วน UI แบบ "Petrol" ที่ใช้ซ้ำทั้ง HUD และหน้าต่าง (รอบ 98)
##
## · ornament()   เส้นประดับ  ─────◆─────  (ใต้ชื่อแมพ / ข้างช่องยา / กลางแถบ EXP)
## · glyph(id)    ไอคอนเล็ก ๆ (เหรียญ หัวใจ ดาบ โล่ ...) — ถ้ามีไฟล์ที่ res://Sprites/ui/petrol/glyphs/<id>.svg|png
##                จะใช้ไฟล์นั้น ไม่มีก็วาดด้วยโค้ดให้ก่อน (รายชื่อ id ทั้งหมดดูที่ GLYPHS ข้างล่าง)
## · ring_style() วงกลมขอบทองสำหรับปุ่มโจมตี/สกิล/พุ่งหลบ (ตาม components/action.svg)
## · stat_row()   แถว [ไอคอน] ชื่อ ............ ค่า
class_name PetrolWidgets
extends RefCounted

## ★ รายชื่อไอคอนเล็กที่ระบบใช้ ★ วางไฟล์ชื่อนี้ในโฟลเดอร์ glyphs/ เมื่อไหร่ ระบบหยิบไปใช้เอง
const GLYPHS := [
	"coin",        # เหรียญซีนี (HUD + กระเป๋า)
	"quest",       # เพชรหัวข้อเควสบน HUD
	"emblem",      # ตราอาชีพใต้รูปตัวละคร
	"hp",          # หัวใจ (สเตตัส)
	"sp",          # หยดน้ำ (มานา)
	"attack",      # ดาบ (ค่าโจมตี · ปุ่มโจมตี)
	"defense",     # โล่
	"speed",       # รองเท้า (ความเร็ว)
	"crit",        # ดาว (คริ)
	"search",      # แว่นขยาย
	"all",         # ตาราง 4 ช่อง (หมวด ทั้งหมด)
	"weapons",     # ดาบ (หมวดอาวุธ)
	"armor",       # เสื้อ (หมวดเกราะ)
	"consumables", # ขวดยา (หมวดของใช้)
	"materials",   # ขนนก (หมวดวัตถุดิบ)
	"bag_empty",   # ถุงจาง ๆ ในช่องว่าง
	"slot_weapon", "slot_head", "slot_armor", "slot_garment",
	"slot_offhand", "slot_shoes", "slot_accessory",   # ไอคอนช่องสวมใส่ที่ยังว่าง
	"dash",        # ลูกศรพุ่งหลบ
	"swords",      # ดาบไขว้ (ปุ่มโจมตี)
	"signal",      # ขีดสัญญาณมุมขวาล่าง
	"portrait",    # รูปหน้าตัวละครผู้เล่น (วงกลมมุมซ้ายบน)
]


# =========================================================
# เส้นประดับ ─────◆─────
# =========================================================
static func ornament(width: float = 120.0, color: Color = UITheme.ACCENT, diamond: float = 4.0) -> Control:
	var o := _Ornament.new()
	o.color = color
	o.diamond = diamond
	o.custom_minimum_size = Vector2(width, maxf(10.0, diamond * 2.5))
	o.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return o


class _Ornament extends Control:
	var color := Color("#b5a16c")
	var diamond := 4.0
	## true = เพชรอยู่ปลาย "ซ้าย" แล้วเส้นวิ่งไปขวา (ใช้ที่หัวข้อเควส)
	var diamond_at_start := false

	func _draw() -> void:
		var cy := size.y * 0.5
		var d := diamond
		var cx: float = d + 2.0 if diamond_at_start else size.x * 0.5
		var faint := Color(color, 0.55)
		if diamond_at_start:
			draw_line(Vector2(cx + d + 3.0, cy), Vector2(size.x, cy), faint, 1.0, true)
		else:
			draw_line(Vector2(0, cy), Vector2(cx - d - 3.0, cy), faint, 1.0, true)
			draw_line(Vector2(cx + d + 3.0, cy), Vector2(size.x, cy), faint, 1.0, true)
		var pts := PackedVector2Array([Vector2(cx, cy - d), Vector2(cx + d, cy), Vector2(cx, cy + d), Vector2(cx - d, cy)])
		draw_colored_polygon(pts, color)
		# เพชรเล็กปลายเส้น
		if not diamond_at_start:
			for x in [2.0, size.x - 2.0]:
				var s := d * 0.45
				draw_colored_polygon(PackedVector2Array([Vector2(x, cy - s), Vector2(x + s, cy), Vector2(x, cy + s), Vector2(x - s, cy)]), faint)


# =========================================================
# ไอคอนเล็ก (glyph)
# =========================================================
## คืน Control ขนาด size×size ที่โชว์ไอคอน id — ไฟล์จริงถ้ามี ไม่มีก็วาดเอง
static func glyph(id: String, size: float = 16.0, color: Color = UITheme.TEXT) -> Control:
	var tex := UITheme.glyph_texture(id)
	if tex != null:
		var art := TextureRect.new()
		art.texture = tex
		art.custom_minimum_size = Vector2(size, size)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.modulate = color
		return art
	var g := _Glyph.new()
	g.kind = id
	g.color = color
	g.custom_minimum_size = Vector2(size, size)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g


## ไอคอนไหนยังไม่มีไฟล์บ้าง (เอาไว้แจ้งผู้ใช้)
static func missing_glyphs() -> Array[String]:
	var out: Array[String] = []
	for id in GLYPHS:
		if UITheme.glyph_texture(String(id)) == null:
			out.append(String(id))
	return out


## ไอคอนวาดด้วยโค้ดบนตาราง 24×24 หน่วย (ตัวสำรองระหว่างรอไฟล์จริง)
class _Glyph extends Control:
	var kind := "coin"
	var color := Color("#ece7d8")
	var _u := 1.0
	var _o := Vector2.ZERO

	func p(x: float, y: float) -> Vector2:
		return _o + Vector2(x, y) * _u

	func poly(points: Array, c: Color) -> void:
		var out := PackedVector2Array()
		for pt in points:
			out.append(p(pt[0], pt[1]))
		draw_colored_polygon(out, c)

	func line(a: Array, b: Array, c: Color, w: float = 1.6) -> void:
		draw_line(p(a[0], a[1]), p(b[0], b[1]), c, w * _u, true)

	func _draw() -> void:
		_u = minf(size.x, size.y) / 24.0
		_o = (size - Vector2(24, 24) * _u) * 0.5
		var gold := UITheme.ACCENT
		match kind:
			"coin":
				draw_circle(p(12, 12), 9.0 * _u, gold)
				draw_circle(p(12, 12), 6.5 * _u, Color("#8a7645"))
				draw_circle(p(12, 12), 4.5 * _u, gold)
			"quest":
				poly([[12, 3], [21, 12], [12, 21], [3, 12]], gold)
				poly([[12, 7], [17, 12], [12, 17], [7, 12]], Color("#3a3120"))
				poly([[12, 9.5], [14.5, 12], [12, 14.5], [9.5, 12]], gold)
			"emblem":
				poly([[12, 2], [20, 7], [20, 15], [12, 22], [4, 15], [4, 7]], Color("#243c34"))
				line([12, 6], [12, 18], gold, 2.0)
				line([7, 10], [17, 10], gold, 2.0)
			"hp":
				poly([[12, 21], [3, 11], [3, 7], [6, 4], [9.5, 4], [12, 7], [14.5, 4], [18, 4], [21, 7], [21, 11]], color)
			"sp":
				poly([[12, 2], [18, 11], [18, 15], [15, 20], [9, 20], [6, 15], [6, 11]], color)
			"attack", "weapons":
				line([4, 20], [18, 6], color, 2.4)
				line([17, 4], [21, 8], color, 2.4)
				line([6, 15], [9, 18], color, 2.0)
				line([3, 18], [6, 21], color, 2.0)
			"defense":
				poly([[12, 2], [21, 5], [21, 12], [12, 22], [3, 12], [3, 5]], color)
				poly([[12, 5], [18, 7], [18, 12], [12, 19], [6, 12], [6, 7]], Color("#102725"))
				line([12, 7], [12, 17], color, 1.6)
			"speed":
				poly([[5, 14], [11, 14], [11, 6], [14, 6], [14, 14], [20, 18], [20, 21], [5, 21]], color)
			"crit":
				poly([[12, 2], [14.5, 9.5], [22, 12], [14.5, 14.5], [12, 22], [9.5, 14.5], [2, 12], [9.5, 9.5]], color)
			"search":
				draw_arc(p(10.5, 10.5), 6.5 * _u, 0.0, TAU, 24, color, 2.0 * _u, true)
				line([15.5, 15.5], [21, 21], color, 2.4)
			"all":
				for r in range(2):
					for c in range(2):
						draw_rect(Rect2(p(4 + c * 9, 4 + r * 9), Vector2(7, 7) * _u), color, true)
			"armor":
				poly([[8, 4], [10.5, 6.5], [13.5, 6.5], [16, 4], [21, 7], [18, 11], [17, 11], [17, 21], [7, 21], [7, 11], [6, 11], [3, 7]], color)
			"consumables":
				poly([[9, 3], [15, 3], [15, 7], [18, 12], [18, 20], [6, 20], [6, 12], [9, 7]], color)
				draw_rect(Rect2(p(8, 13), Vector2(8, 5) * _u), Color("#102725"), true)
			"materials":
				poly([[20, 3], [19, 12], [12, 20], [5, 21], [8, 13], [14, 6]], color)
				line([5, 21], [17, 7], Color("#102725"), 1.2)
			"bag_empty":
				var c := Color(color, 0.35)
				poly([[7, 9], [17, 9], [20, 21], [4, 21]], c)
				draw_arc(p(12, 8), 3.5 * _u, PI, TAU, 12, c, 1.5 * _u, true)
				draw_rect(Rect2(p(6, 9), Vector2(12, 2.2) * _u), Color(color, 0.5), true)
			"slot_weapon":
				line([5, 19], [17, 7], Color(color, 0.5), 2.2)
				line([16, 5], [20, 9], Color(color, 0.5), 2.2)
				line([4, 16], [8, 20], Color(color, 0.5), 2.0)
			"slot_head":
				var c2 := Color(color, 0.5)
				draw_arc(p(12, 13), 8.0 * _u, PI, TAU, 16, c2, 2.0 * _u, true)
				line([4, 13], [20, 13], c2, 2.0)
				line([12, 5], [12, 13], c2, 1.5)
			"slot_armor":
				poly([[8, 5], [16, 5], [20, 8], [18, 12], [17, 12], [17, 20], [7, 20], [7, 12], [6, 12], [4, 8]], Color(color, 0.5))
			"slot_garment":
				poly([[7, 4], [17, 4], [20, 20], [4, 20]], Color(color, 0.5))
				line([12, 4], [12, 20], Color("#102725"), 1.2)
			"slot_offhand":
				poly([[12, 3], [20, 6], [20, 12], [12, 21], [4, 12], [4, 6]], Color(color, 0.5))
			"slot_shoes":
				poly([[6, 12], [11, 12], [11, 5], [14, 5], [14, 12], [20, 16], [20, 20], [6, 20]], Color(color, 0.5))
			"slot_accessory":
				draw_arc(p(12, 13), 6.5 * _u, 0.0, TAU, 24, Color(color, 0.5), 2.0 * _u, true)
				poly([[12, 3], [15, 6], [12, 9], [9, 6]], Color(color, 0.5))
			"dash":
				poly([[3, 12], [11, 5], [11, 9], [15, 9], [15, 5], [22, 12], [15, 19], [15, 15], [11, 15], [11, 19]], color)
			"swords":
				line([4, 20], [18, 6], color, 2.4)
				line([16, 4], [20, 8], color, 2.4)
				line([20, 20], [6, 6], color, 2.4)
				line([8, 4], [4, 8], color, 2.4)
				line([3, 17], [7, 21], color, 2.0)
				line([21, 17], [17, 21], color, 2.0)
			"signal":
				for i in range(4):
					var h := 5.0 + i * 4.0
					draw_rect(Rect2(p(4 + i * 4.5, 21 - h), Vector2(3, h) * _u), color if i < 3 else Color(color, 0.35), true)
			"portrait":
				draw_circle(p(12, 9), 5.0 * _u, Color(color, 0.8))
				poly([[4, 22], [6, 15], [18, 15], [20, 22]], Color(color, 0.8))
			_:
				draw_circle(p(12, 12), 6.0 * _u, color)


# =========================================================
# วงกลมขอบทอง (ปุ่มโจมตี / สกิล / พุ่งหลบ) — ตาม components/action.svg
# =========================================================
static func ring_style(pressed: bool = false, alpha: float = 0.85) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color("#34483b", alpha) if pressed else Color(UITheme.INK, alpha)
	st.border_color = UITheme.TEXT if pressed else UITheme.ACCENT
	st.set_border_width_all(2)
	st.set_corner_radius_all(999)
	return st


## วงในบาง ๆ (จาง) ที่อยู่ในปุ่มวงกลม
static func inner_ring(diameter: float, color: Color = Color("#81958a80")) -> Control:
	var r := _Ring.new()
	r.color = color
	r.custom_minimum_size = Vector2(diameter, diameter)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


class _Ring extends Control:
	var color := Color("#81958a80")
	var inset := 5.0
	func _draw() -> void:
		var rad := minf(size.x, size.y) * 0.5 - inset
		if rad > 2.0:
			draw_arc(size * 0.5, rad, 0.0, TAU, 48, color, 1.0, true)


## วงกลมกรอบรูปตัวละคร (ขอบทอง 2 ชั้น)
static func portrait_ring(diameter: float) -> Control:
	var r := _PortraitRing.new()
	r.custom_minimum_size = Vector2(diameter, diameter)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


class _PortraitRing extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var rad := minf(size.x, size.y) * 0.5
		draw_circle(c, rad, Color("#0b1c1b"))
		draw_arc(c, rad - 1.5, 0.0, TAU, 64, UITheme.ACCENT, 2.5, true)
		draw_arc(c, rad - 6.0, 0.0, TAU, 64, Color(UITheme.ACCENT, 0.45), 1.0, true)


## ทำภาพให้เป็นวงกลม (ใช้ CircleClip: วาดภาพแล้วบังด้วยวงกลม) — คืน Control ที่ใส่รูปได้ผ่าน .texture
static func circle_portrait(diameter: float, tex: Texture2D) -> Control:
	var c := _CirclePortrait.new()
	c.texture = tex
	c.custom_minimum_size = Vector2(diameter, diameter)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


class _CirclePortrait extends Control:
	var texture: Texture2D
	func _draw() -> void:
		var rad := minf(size.x, size.y) * 0.5 - 4.0
		var c := size * 0.5
		if texture == null:
			draw_circle(c, rad, Color("#173430"))
			return
		# วาดรูปเป็น "วงกลม" ด้วย polygon + uv
		var n := 48
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		var ts := texture.get_size()
		var k := (rad * 2.0) / minf(ts.x, ts.y)   # ย่อให้ด้านสั้นพอดีวง
		for i in range(n):
			var a := TAU * i / n
			var v := c + Vector2(cos(a), sin(a)) * rad
			pts.append(v)
			# uv: กึ่งกลางภาพ (ด้านบนสำหรับรูปเต็มตัว ให้ใช้ AtlasTexture ตัดมาก่อน)
			var local := (v - c) / k + ts * 0.5
			uvs.append(local / ts)
		draw_polygon(pts, PackedColorArray([Color.WHITE]), uvs, texture)


# =========================================================
# แถวค่าพลัง  [ไอคอน] ชื่อ ............ ค่า
# =========================================================
static func stat_row(glyph_id: String, label: String, value: String, value_color: Color = UITheme.TEXT,
		size: int = 13) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(glyph(glyph_id, size + 2, UITheme.TEXT_DIM))
	var l := UITheme.make_label(label, size, UITheme.TEXT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var v := UITheme.make_label(value, size, value_color)
	v.name = "Value"
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(v)
	return row


## แถบหัวข้อเล็ก ๆ (ตัวหนังสือ + เส้นทองจาง ๆ ใต้)
static func caption(text: String, size: int = 12, color: Color = UITheme.TEXT_DIM) -> Label:
	var l := UITheme.make_label(text, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## มุมประดับ 4 มุมของกรอบใหญ่ (เส้นสั้น ๆ รูปตัว L สีงาช้าง ตาม slot-selected.svg)
static func corner_marks(inset: float = 4.0, length: float = 10.0, color: Color = Color("#ece7d8")) -> Control:
	var c := _Corners.new()
	c.inset = inset
	c.length = length
	c.color = color
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


class _Corners extends Control:
	var inset := 4.0
	var length := 10.0
	var color := Color("#ece7d8")
	func _draw() -> void:
		var i := inset
		var l := length
		var w := size.x
		var h := size.y
		var cl := Color(color, 0.8)
		draw_polyline(PackedVector2Array([Vector2(i, i + l), Vector2(i, i), Vector2(i + l, i)]), cl, 1.0, true)
		draw_polyline(PackedVector2Array([Vector2(w - i - l, i), Vector2(w - i, i), Vector2(w - i, i + l)]), cl, 1.0, true)
		draw_polyline(PackedVector2Array([Vector2(i, h - i - l), Vector2(i, h - i), Vector2(i + l, h - i)]), cl, 1.0, true)
		draw_polyline(PackedVector2Array([Vector2(w - i - l, h - i), Vector2(w - i, h - i), Vector2(w - i, h - i - l)]), cl, 1.0, true)
