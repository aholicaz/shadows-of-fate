## SlashSheetFX — ภาพชุดเดิมหรือเสี้ยวแสงสดตามเฟรมดาบผ่าน PlayerFXBook
## crescent_enabled เปิดเสี้ยวแสงสีขาว; ปิดเพื่อใช้แหล่งภาพตามลำดับเดิม
## หมายเหตุด้านล่างเป็นที่มาของโหมดภาพชุด Alternative 3
##
## ★★ ทำไมถึงเปลี่ยนจากเชดเดอร์รอบ 100 ★★
## เชดเดอร์รอบ 100 วาดรอยฟันเป็น "ส่วนโค้งรอบตัว" (polar coordinates) — ดูเป็นวงกลม
## และทิศทางไม่ตรงกับดาบที่ฟันจริง ผู้ใช้จึงหาภาพชุดใหม่มาให้ (โฟลเดอร์ Alternative 3)
## ภาพชุดนี้เป็น "ลำแสงยาวเป็นเส้นตรง" ไม่ใช่วงโค้ง → หมุนให้ตรงทิศดาบได้ตรง ๆ
##
## ★★ โครงสร้างไฟล์ภาพ ★★
##   res://Sprites/shaders/Alternative 3/<ชุด>/Alternative_3_<เลข 2 หลัก>.png
##   ชุด 1..5 · ชุดละ 6 เฟรม · เลขไฟล์ไล่ยาว: ชุด 1 = 01-06 · ชุด 2 = 07-12 · ... ชุด 5 = 25-30
##   → เลขไฟล์ของ (ชุด s, เฟรม f) = (s - 1) * 6 + f + 1
##
##   ชุด 1-3 = รอยโค้งเป็นวงกลม (แบบที่ผู้ใช้ไม่เอา) · ★ ชุด 4-5 = ลำแสงเส้นตรง ★
##   วัดจากภาพจริง: ชุด 4 กับ 5 วางตัวทำมุม -45 องศาบนจอ (ชี้ขึ้นไปทางขวา "/") ทุกเฟรม
##   → NATIVE_ANGLE_DEG = -45.0 · หมุนเพิ่มเท่าไหร่ค่อยคิดจากมุมนี้
##
## ★★ หัวใจ: จังหวะตรงกับการฟัน (สัญญาเดิมจากรอบ 100 ไม่เปลี่ยน) ★★
##
##     กดฟัน                     ดาเมจออก (เฟรมที่ดาบฟาดถึง)              จบ
##       |------------ peak_time ------------|-------- tail_time --------|
##     p=0.0                               p=0.5                       p=1.0
##     เฟรม 0                              ★เฟรม 3★                    เฟรม 5
##
## เฟรม 3 (นับจาก 0) คือเฟรมที่ลำแสงยาว/สว่างที่สุดของทั้งชุด 4 และชุด 5 (วัดจากภาพจริง)
## และ int(0.5 * 6) = 3 พอดี → ใช้ progress_at() สูตรเดียวกับรอบ 100 ได้เลย
## ★★ รอบ 103 — ใส่ภาพเอฟเฟกต์ของตัวเองได้ ★★
## นอกจากภาพชุด Alternative 3 ที่แถมมา ยังรับแหล่งภาพได้อีก 2 ทาง (เรียงตามลำดับความสำคัญ):
##   1. `frames` = SpriteFrames (+ `anim` ชื่อท่า) — ลากไฟล์ใส่ในสมุดเอฟเฟกต์ได้เลย
##   2. `dir` = พาธโฟลเดอร์ที่มีไฟล์ .png เรียงตามชื่อ — โหลดทุกไฟล์ในนั้นเป็นเฟรม
##   3. ไม่ใส่ทั้งคู่ → ใช้ `set` (ภาพชุด 1-5) เหมือนเดิม
## ★ กี่เฟรมก็ได้ ★ ไม่จำเป็นต้อง 6 เฟรม — จังหวะ "เฟรมกลาง = ตอนดาเมจออก" ยังตรงเหมือนเดิม
## และขนาดบนจอคิดจากความสูงจริงของภาพที่ใส่มา ไม่ได้ล็อกไว้ที่ 150 px
class_name SlashSheetFX
extends Sprite2D

const DIR := "res://Sprites/shaders/Alternative 3/"
const PREFIX := "Alternative_3_"
const FRAMES_PER_SET := 6
const SET_COUNT := 5

## ★ มุมที่ภาพต้นฉบับวางตัวอยู่แล้ว (องศาบนจอ · บวก = ตามเข็ม) ★
## วัดจากแกนหลักของพิกเซลสว่างในภาพจริงทั้ง 6 เฟรมของชุด 4 และ 5 = -45.5 ถึง -43.0
const NATIVE_ANGLE_DEG := -45.0

## ★★ ชุด 1-3 เป็น "วงโค้งที่หมุนไปเรื่อย ๆ ระหว่างเฟรม" จึงไม่มีมุมประจำตัว ★★
## (วัดแล้วได้ -67 → 42 → -27 → 82 ... คนละทิศทุกเฟรม)
## → สำหรับชุดพวกนี้ถือว่ามุมต้นฉบับ = 0 แปลว่า `aim` ที่ใส่เข้ามากลายเป็น
##   "หมุนเพิ่มจากภาพต้นฉบับกี่องศา" (0 = ใช้ตามที่วาดมา) ซึ่งเป็นสิ่งที่คุมได้จริง
static func native_angle_of(set_no: int) -> float:
	return NATIVE_ANGLE_DEG if set_no >= 4 else 0.0

## เห็นชัดที่สุด (ลำแสงยาวสุด) ที่ progress เท่าไหร่ · และตรงกับเฟรมไหน
const PEAK_PROGRESS := 0.5
const PEAK_FRAME := 3

static var _cache: Dictionary = {}
static var _set_cache: Dictionary = {}
static var _crescent_canvas: GradientTexture2D
const CRESCENT_SHADER = preload("res://Sprites/shaders/slash/slash_crescent.gdshader")

var _t := 0.0
var _peak := 0.12          # วินาทีจากเริ่มฟัน → ดาเมจออก
var _tail := 0.16          # วินาทีจากดาเมจออก → จางหมด
var _follow: Node2D = null
var _follow_offset := Vector2.ZERO
var _travel := 0.0         # พุ่งไปข้างหน้ากี่ px ระหว่างเล่น (ตามทิศลำแสง)
var _dir := Vector2.RIGHT  # ทิศที่ลำแสงพุ่งออก (คิดจากมุมหมุนจริง)
var _textures: Array[Texture2D] = []
var _frame_idx := -1
var _base_scale := Vector2.ONE
var _reversed := false     # เล่นเฟรมจากท้ายมาหน้า (5→0)
var _sprite: AnimatedSprite2D
var _track: PlayerSkillFX
var _native := 0.0
var _tint_alpha := 1.0


## จำนวนเฟรมของชุดที่กำลังเล่น (ภาพชุดที่แถมมา = 6 · ภาพที่ผู้ใช้ใส่เอง = เท่าที่มี)
## ยังไม่ได้โหลดภาพ (เช่นโหนดเปล่าที่เอาไว้คำนวณจังหวะ) = ถือเป็นชุดมาตรฐาน 6 เฟรม
func frame_count() -> int:
	return _textures.size() if not _textures.is_empty() else FRAMES_PER_SET


## เส้นทางไฟล์ของ (ชุด, เฟรม)
static func frame_path(set_no: int, frame_no: int) -> String:
	var s := clampi(set_no, 1, SET_COUNT)
	var f := clampi(frame_no, 0, FRAMES_PER_SET - 1)
	return DIR + str(s) + "/" + PREFIX + "%02d" % ((s - 1) * FRAMES_PER_SET + f + 1) + ".png"


static func _res(path: String) -> Resource:
	if _cache.has(path):
		return _cache[path]
	var r: Resource = load(path) if ResourceLoader.exists(path) else null
	_cache[path] = r
	return r


## ภาพครบทั้ง 6 เฟรมของชุดนี้ไหม (ไม่ครบ = คืน array ว่าง)
static func load_set(set_no: int) -> Array[Texture2D]:
	var key := clampi(set_no, 1, SET_COUNT)
	if _set_cache.has(key):
		return _set_cache[key]
	var out: Array[Texture2D] = []
	for f in range(FRAMES_PER_SET):
		var tex := _res(frame_path(key, f)) as Texture2D
		if tex == null:
			out.clear()
			break
		out.append(tex)
	_set_cache[key] = out
	return out


## มีภาพชุดนี้พร้อมใช้ไหม (ไม่มี = ผู้เรียกถอยไปใช้เอฟเฟกต์แบบเดิม)
static func available(set_no: int = 4) -> bool:
	return not load_set(set_no).is_empty()


## ★ รอบ 103 — เฟรมจาก SpriteFrames ที่ผู้ใช้ลากมาใส่เอง ★
## `anim` เว้นว่าง = ใช้ท่าแรกที่เจอในไฟล์นั้น (ส่วนใหญ่มีท่าเดียวอยู่แล้ว)
static func load_frames(frames: SpriteFrames, anim: StringName = &"") -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	if frames == null:
		return out
	var a := anim
	if a == &"" or not frames.has_animation(a):
		var names := frames.get_animation_names()
		if names.is_empty():
			return out
		a = StringName(names[0])
	for i in range(frames.get_frame_count(a)):
		var tex := frames.get_frame_texture(a, i)
		if tex != null:
			out.append(tex)
	return out


## ★ รอบ 103 — เฟรมจากโฟลเดอร์ภาพที่ผู้ใช้โยนเข้ามา ★
## อ่านไฟล์ .png ทุกไฟล์ในโฟลเดอร์นั้น **เรียงตามชื่อ** → ตั้งชื่อ 01,02,03... จะได้ลำดับถูก
static func load_dir(path: String) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	if path.strip_edges() == "":
		return out
	if _set_cache.has(path):
		return _set_cache[path]
	var d := DirAccess.open(path)
	if d == null:
		_set_cache[path] = out
		return out
	var names: Array[String] = []
	for f in d.get_files():
		# ★ ในเกมที่ export แล้วไฟล์ .png จะกลายเป็น .ctex ★ ต้องรับทั้งสองนามสกุล
		var low := f.to_lower()
		if low.ends_with(".png") or low.ends_with(".png.import"):
			names.append(f.trim_suffix(".import"))
		elif low.ends_with(".ctex"):
			names.append(f)
	names.sort()
	var seen := {}
	for f in names:
		if seen.has(f):
			continue
		seen[f] = true
		var tex := _res(path.path_join(f)) as Texture2D
		if tex != null:
			out.append(tex)
	_set_cache[path] = out
	return out


## ★ แหล่งภาพของ cfg นี้ ★ SpriteFrames ที่ใส่เอง > โฟลเดอร์ที่ชี้ > ภาพชุด 1-5 ที่แถมมา
static func textures_for(cfg: Dictionary) -> Array[Texture2D]:
	var track := cfg.get("track") as PlayerSkillFX
	if track != null and track.crescent_enabled:
		if _crescent_canvas == null:
			_crescent_canvas = GradientTexture2D.new()
			_crescent_canvas.width = 512
			_crescent_canvas.height = 512
			_crescent_canvas.gradient = Gradient.new()
		return [_crescent_canvas]
	var out: Array[Texture2D] = load_frames(cfg.get("frames", null) as SpriteFrames,
		StringName(cfg.get("anim", &"")))
	if not out.is_empty():
		return out
	out = load_dir(String(cfg.get("dir", "")))
	if not out.is_empty():
		return out
	return load_set(int(cfg.get("set", 4)))


## ★ ต้องหมุนภาพกี่องศา ถึงจะได้ลำแสงชี้ไปทางมุม target (องศาบนจอ · บวก = ก้มลง) ★
## ใช้ตอนตั้งค่า/ตอนเทสต์ จะได้ไม่ต้องเดามุมเอง
## ชุด 1-3 (วงโค้ง) มุมต้นฉบับ = 0 → ค่าที่ใส่กลายเป็น "หมุนเพิ่มกี่องศา" ตรง ๆ
static func rotation_for(target_deg: float, set_no: int = 4) -> float:
	return target_deg - native_angle_of(set_no)


## สร้างรอยฟัน 1 ครั้ง
## cfg: set (1-5) · peak · tail · size · offset · rotate (องศาที่หมุนเพิ่มจากภาพต้นฉบับ)
##      reversed (เล่นเฟรมจากท้ายมาหน้า) · scale · travel · modulate · additive · z · follow
static func spawn(cfg: Dictionary, caster: Node2D, facing: int) -> SlashSheetFX:
	if caster == null:
		return null
	# ★ รอบ 103 ★ เช็คจาก "แหล่งภาพจริงที่จะใช้" ไม่ใช่แค่ภาพชุดที่แถมมา
	# (ใส่ SpriteFrames/โฟลเดอร์เอง แล้วเลขชุดชี้ไปที่ชุดที่ไม่มีไฟล์ ก็ยังต้องเกิดได้)
	if textures_for(cfg).is_empty():
		return null
	var tree := caster.get_tree()
	if tree == null:
		return null
	var parent: Node = tree.get_first_node_in_group("map")
	if parent == null:
		parent = tree.current_scene
	if parent == null:
		return null

	var fx := SlashSheetFX.new()
	fx.name = "SlashSheetFX"
	fx._setup(cfg, caster, facing)

	# ★ ตั้งตำแหน่งก่อน add_child เสมอ ★ ไม่งั้นจะเห็นแวบที่จุด (0,0) หนึ่งเฟรม
	var base_offset: Vector2 = cfg.get("offset", Vector2.ZERO)
	var off := Vector2(base_offset.x * signf(facing), base_offset.y)
	fx.position = caster.global_position + off - parent.global_position
	parent.add_child(fx)
	return fx


func _setup(cfg: Dictionary, caster: Node2D, facing: int) -> void:
	_textures = textures_for(cfg)
	centered = true
	z_index = int(cfg.get("z", 45))
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	_peak = maxf(0.02, float(cfg.get("peak", 0.12)))
	_tail = maxf(0.03, float(cfg.get("tail", 0.16)))
	_travel = float(cfg.get("travel", 0.0))
	_reversed = bool(cfg.get("reversed", false))

	# ขนาดบนจอ (px) — ภาพต้นฉบับสูง 150 px ทุกเฟรม จึงยึดความสูงเป็นตัวตั้ง
	var size := maxf(16.0, float(cfg.get("size", 260.0))) * maxf(0.05, float(cfg.get("scale", 1.0)))
	# ★ ยึดความสูงของภาพจริง ★ เดิมหาร 150 ตายตัว (ความสูงของภาพชุด Alternative 3)
	# ภาพที่ผู้ใช้ใส่เองสูงเท่าไหร่ก็ได้ → ตั้ง "ขนาดบนจอ 250 px" แล้วต้องได้ 250 px จริงทุกภาพ
	var src_h := 150.0
	if not _textures.is_empty() and _textures[0] != null:
		src_h = maxf(1.0, float(_textures[0].get_height()))
	var k := size / src_h

	# ★★ พลิกซ้าย-ขวาให้ถูก ★★
	# เมทริกซ์ของ Node2D = R(φ)·S  ส่วนภาพที่เรา "อยากได้" ตอนหันซ้ายคือ Flip_x·R(θ)·S
	# กระจายออกมาแล้วเท่ากับ R(−θ)·diag(−s, s) พอดี → หันซ้ายต้อง "กลับทั้งมุมและ scale.x"
	# (ถ้ากลับแค่ scale.x อย่างเดียว ลำแสงจะเอียงผิดข้างทันที)
	var rot_deg: float = float(cfg.get("rotate", 90.0))
	var right := facing >= 0
	rotation = deg_to_rad(rot_deg if right else -rot_deg)
	_base_scale = Vector2(k * (1.0 if right else -1.0), k)
	scale = _base_scale

	# ทิศที่ลำแสงพุ่งออก = มุมของภาพต้นฉบับ + มุมที่หมุนเพิ่ม (พลิกข้างด้วยถ้าหันซ้าย)
	# ★ รอบ 103 ★ ภาพที่ผู้ใช้ใส่เองไม่รู้ว่าวาดเอียงมากี่องศา → ผู้เรียกส่ง "native" = 0 มา
	# แปลว่า "องศาที่ชี้" ที่ตั้งในสมุดกลายเป็นองศาหมุนตรง ๆ (ตั้งเท่าไหร่หมุนเท่านั้น)
	var native := float(cfg.get("native", native_angle_of(int(cfg.get("set", 4)))))
	var aim := deg_to_rad(native + rot_deg)
	_dir = Vector2(cos(aim), sin(aim))
	if not right:
		_dir.x = -_dir.x

	if bool(cfg.get("additive", true)):
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

	if bool(cfg.get("follow", true)):
		_follow = caster
		var base_offset: Vector2 = cfg.get("offset", Vector2.ZERO)
		_follow_offset = Vector2(base_offset.x * signf(facing), base_offset.y)

	modulate = cfg.get("modulate", Color.WHITE)
	_tint_alpha = modulate.a
	var track := cfg.get("track") as PlayerSkillFX
	if track != null and track.crescent_enabled:
		var crescent := ShaderMaterial.new()
		crescent.shader = CRESCENT_SHADER
		crescent.set_shader_parameter("arc_span", track.crescent_span)
		crescent.set_shader_parameter("arc_width", track.crescent_width)
		material = crescent
		native = 0.0
	elif track != null and track.white_mask:
		var shader := Shader.new()
		shader.code = "shader_type canvas_item;\n" + ("render_mode blend_add;\n" if bool(cfg.get("additive", true)) else "") + "varying vec4 tint; void vertex() { tint = COLOR; } void fragment() { vec4 c = texture(TEXTURE, UV); COLOR = vec4(vec3(1.0), c.a) * tint; }"
		var white := ShaderMaterial.new()
		white.shader = shader
		material = white
	_sprite = cfg.get("sprite") as AnimatedSprite2D
	if track != null and is_instance_valid(_sprite) and track.track_animation == _sprite.animation \
			and track.blade_positions.size() == _sprite.sprite_frames.get_frame_count(_sprite.animation) \
			and track.blade_angles.size() == track.blade_positions.size() \
			and track.blade_opacity.size() == track.blade_positions.size():
		_track = track
		_native = native
		process_priority = 100 # หลัง player ปรับ auto-fit ของเฟรมนี้
	_apply(0.0)
	if _track != null:
		visible = false # รอตำแหน่ง global หลัง add_child


func _apply_blade_frame() -> void:
	var f := _sprite.frame
	var flip := Vector2(-1.0 if _sprite.flip_h else 1.0, -1.0 if _sprite.flip_v else 1.0)
	# Sprite2D offset อยู่ในพิกัดวาด; flip กลับภาพรอบ offset
	global_position = _sprite.to_global(_track.blade_positions[f] * flip + _sprite.offset)
	var angle := deg_to_rad(_track.blade_angles[f])
	var axis := Vector2(cos(angle), sin(angle)) * flip
	global_rotation = _sprite.global_rotation + axis.angle() - deg_to_rad(_native)
	scale = Vector2(absf(_base_scale.x), absf(_base_scale.y))
	texture = _textures[mini(PEAK_FRAME, _textures.size() - 1)]
	modulate.a = _track.blade_opacity[f] * _tint_alpha
	if _track.crescent_enabled:
		var crescent := material as ShaderMaterial
		crescent.set_shader_parameter("phase", float(f) + _sprite.frame_progress)
		crescent.set_shader_parameter("sweep_direction", _track.crescent_direction * flip.x * flip.y)
		if f == _track.blade_positions.size() - 1:
			modulate.a *= 1.0 - smoothstep(0.15, 1.0, _sprite.frame_progress)
	visible = modulate.a > 0.0


## progress ณ เวลา t วินาที (สูตรเดียวกับรอบ 100 — p = 0.5 ตกตรงเฟรมที่ดาเมจออกเป๊ะ)
func progress_at(t: float) -> float:
	if t <= _peak:
		return PEAK_PROGRESS * clampf(t / _peak, 0.0, 1.0)
	return PEAK_PROGRESS + (1.0 - PEAK_PROGRESS) * clampf((t - _peak) / _tail, 0.0, 1.0)


## เฟรมที่ต้องโชว์ ณ progress p · p = 0.5 → เฟรม 3 (เฟรมที่ลำแสงยาวสุด) พอดี
## ★ ถ้า reversed ★ เล่นจากท้ายมาหน้า: p = 0.5 → เฟรม 5−3 = 2 (ยังเป็นเฟรมกลาง ๆ ที่ใหญ่สุดอยู่)
func frame_at(p: float) -> int:
	var n := frame_count()
	var f := clampi(int(clampf(p, 0.0, 1.0) * float(n)), 0, n - 1)
	return (n - 1 - f) if _reversed else f


func _apply(p: float) -> void:
	if _textures.is_empty():
		return
	var f := frame_at(p)
	if f != _frame_idx:
		_frame_idx = f
		texture = _textures[f]
	# จางหายช่วงท้าย (เฟรมสุดท้ายของภาพจางอยู่แล้ว อันนี้ช่วยให้ไม่ตัดหายกึก)
	var a := 1.0
	if p > 0.82:
		a = clampf((1.0 - p) / 0.18, 0.0, 1.0)
	var c := modulate
	c.a = a
	modulate = c


func _process(delta: float) -> void:
	if _track != null:
		if not is_instance_valid(_sprite) or _sprite.animation != _track.track_animation or not _sprite.is_playing():
			queue_free()
			return
		_apply_blade_frame()
		return
	_t += delta
	var p := progress_at(_t)
	var base := Vector2.ZERO
	if _follow != null and is_instance_valid(_follow):
		base = _follow.global_position + _follow_offset
	else:
		base = global_position - _dir * _travel * clampf((p - PEAK_PROGRESS) / 0.5, 0.0, 1.0)
	# ★ พุ่งออกไปข้างหน้า ★ ขยับตามทิศลำแสงหลังจากดาเมจออกแล้ว (ก่อนหน้านั้นอยู่กับที่)
	var push := _dir * _travel * clampf((p - PEAK_PROGRESS) / 0.5, 0.0, 1.0)
	if _follow != null and is_instance_valid(_follow):
		var parent := get_parent() as Node2D
		position = base + push - (parent.global_position if parent != null else Vector2.ZERO)
	_apply(p)
	if p >= 1.0:
		queue_free()
