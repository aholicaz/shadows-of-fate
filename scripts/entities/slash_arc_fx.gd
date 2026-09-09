## SlashArcFX — รอยฟันเป็นส่วนโค้ง วาดด้วยเชดเดอร์ (รอบ 100)
##
## ★★ หัวใจ: จังหวะตรงกับการฟัน ★★
## เชดเดอร์ซ่อนภาพไว้ตอน progress = 0 และ 1 แล้ว**เห็นชัดที่สุดตอน progress = 0.5 พอดี**
## (เกณฑ์ความจางในเชดเดอร์คือ `abs(cos(p*PI))` → p=0 ได้ 1 = ไม่เห็นเลย · p=0.5 ได้ 0 = เห็นเต็ม)
##
## เราจึงยืด-หดเวลาสองช่วงแยกกัน ให้ **p = 0.5 ตกตรงเฟรมที่ดาเมจออกเป๊ะ ๆ**
##
##     กดฟัน                     ดาเมจออก (เฟรมที่ดาบฟาดถึง)              จบ
##       |------------ peak_time ------------|-------- tail_time --------|
##     p=0.0                               p=0.5                       p=1.0
##     (ยังไม่เห็น)                      (สว่างสุด/กวาดกลางพอดี)         (จางหาย)
##
## `peak_time` = ค่า windup ตัวเดียวกับที่ `player.start_attack()` ใช้รอก่อนออกดาเมจ
## (มาจาก `_attack_hit_time()` ของรอบ 94/95 = เฟรมที่ปลายดาบยื่นถึง หารด้วยความเร็วท่าตาม ASPD)
## → ASPD เปลี่ยน · ท่าเปลี่ยน · ไม้ 1/2/3 คนละความยาว — รอยฟันก็ยังตรงจังหวะเองทุกครั้ง
class_name SlashArcFX
extends Sprite2D

const DIR := "res://Sprites/shaders/slash/"
const SHADER_PATH := DIR + "slash_arc.gdshader"
const QUAD_PATH := DIR + "quad_white.png"
const NOISE_PATH := DIR + "base_noise.png"
const HIGHLIGHT_PATH := DIR + "highlight.png"
const WIDTH_MASK_PATH := DIR + "width_mask.tres"
const LENGTH_MASK_PATH := DIR + "length_mask.tres"
const COLOR_CYAN_PATH := DIR + "color_cyan.tres"
const COLOR_EMBER_PATH := DIR + "color_ember.tres"

## ★ เห็นชัดที่สุดตอน progress เท่าไหร่ ★ (เชดเดอร์กำหนดมาแบบนี้ ห้ามแก้ถ้าไม่แก้เชดเดอร์ด้วย)
const PEAK_PROGRESS := 0.5

static var _cache: Dictionary = {}

var _t := 0.0
var _peak := 0.12          # วินาทีจากเริ่มฟัน → ดาเมจออก
var _tail := 0.16          # วินาทีจากดาเมจออก → จางหมด
var _follow: Node2D = null
var _follow_offset := Vector2.ZERO
var _mat: ShaderMaterial


static func _res(path: String) -> Resource:
	if _cache.has(path):
		return _cache[path]
	var r: Resource = load(path) if ResourceLoader.exists(path) else null
	_cache[path] = r
	return r


## มีไฟล์ครบพร้อมใช้ไหม (ไม่ครบ = ผู้เรียกถอยไปใช้เอฟเฟกต์แบบชีทภาพเหมือนเดิม)
static func available() -> bool:
	return _res(SHADER_PATH) != null and _res(QUAD_PATH) != null


## สร้างรอยฟัน 1 ครั้ง
## cfg ที่ใช้บ่อย: peak (วินาทีถึงดาเมจ) · tail · size · offset · rotate · zoom · scale
##                color (Texture2D ตารางสี) · emission · follow · z
static func spawn(cfg: Dictionary, caster: Node2D, facing: int) -> SlashArcFX:
	if caster == null or not available():
		return null
	var tree := caster.get_tree()
	if tree == null:
		return null
	var parent: Node = tree.get_first_node_in_group("map")
	if parent == null:
		parent = tree.current_scene
	if parent == null:
		return null

	var fx := SlashArcFX.new()
	fx.name = "SlashArcFX"
	fx._setup(cfg, caster, facing)

	# ★ ตั้งตำแหน่งก่อน add_child เสมอ ★ ไม่งั้นจะเห็นแวบที่จุด (0,0) หนึ่งเฟรม
	var base_offset: Vector2 = cfg.get("offset", Vector2.ZERO)
	var off := Vector2(base_offset.x * signf(facing), base_offset.y)
	fx.position = caster.global_position + off - parent.global_position
	parent.add_child(fx)
	return fx


func _setup(cfg: Dictionary, caster: Node2D, facing: int) -> void:
	texture = _res(QUAD_PATH)
	centered = true
	z_index = int(cfg.get("z", 45))
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	_peak = maxf(0.02, float(cfg.get("peak", 0.12)))
	_tail = maxf(0.03, float(cfg.get("tail", 0.16)))

	# ขนาดบนจอ (px) — ผืนขาวเป็น 256x256
	var size := maxf(16.0, float(cfg.get("size", 260.0))) * maxf(0.05, float(cfg.get("scale", 1.0)))
	var tex_w: float = maxf(1.0, texture.get_width())
	var k := size / tex_w
	# หันตามตัวละคร: พลิกผืน = รอยฟันกลับข้างตามไปด้วย
	scale = Vector2(k * (1.0 if facing >= 0 else -1.0), k)

	if bool(cfg.get("follow", true)):
		_follow = caster
		var base_offset: Vector2 = cfg.get("offset", Vector2.ZERO)
		_follow_offset = Vector2(base_offset.x * signf(facing), base_offset.y)

	_mat = ShaderMaterial.new()
	_mat.shader = _res(SHADER_PATH)
	_mat.set_shader_parameter("derive_progress", 0.0)     # ★ ป้อน progress เอง (ไม่ใช้ TIME) ★
	_mat.set_shader_parameter("ease_progress", 0.0)
	_mat.set_shader_parameter("progress", 0.0)
	_mat.set_shader_parameter("base_noise", _res(NOISE_PATH))
	_mat.set_shader_parameter("highlight", _res(HIGHLIGHT_PATH))
	_mat.set_shader_parameter("width_gradient_mask", _res(WIDTH_MASK_PATH))
	_mat.set_shader_parameter("length_gradient_mask", _res(LENGTH_MASK_PATH))
	var ramp: Texture2D = cfg.get("color", null)
	if ramp == null:
		ramp = _res(COLOR_CYAN_PATH)
	_mat.set_shader_parameter("color_lookup", ramp)
	_mat.set_shader_parameter("zoom", float(cfg.get("zoom", 0.6)))
	_mat.set_shader_parameter("rotate_all", float(cfg.get("rotate", 0.0)))
	_mat.set_shader_parameter("anim_rot_amt", float(cfg.get("sweep", 1.0)))
	_mat.set_shader_parameter("emission_strength", float(cfg.get("emission", 1.0)))
	_mat.set_shader_parameter("mix_strength", float(cfg.get("mix", 1.0)))
	_mat.set_shader_parameter("edge_fade", float(cfg.get("edge_fade", 0.06)))
	material = _mat
	modulate = cfg.get("modulate", Color.WHITE)
	_apply_progress(0.0)


## progress ณ เวลา t วินาที (แยกฟังก์ชันไว้ให้เทสต์เรียกตรวจได้)
func progress_at(t: float) -> float:
	if t <= _peak:
		return PEAK_PROGRESS * clampf(t / _peak, 0.0, 1.0)
	return PEAK_PROGRESS + (1.0 - PEAK_PROGRESS) * clampf((t - _peak) / _tail, 0.0, 1.0)


func _apply_progress(p: float) -> void:
	if _mat != null:
		_mat.set_shader_parameter("progress", clampf(p, 0.0, 1.0))


func _process(delta: float) -> void:
	_t += delta
	if _follow != null and is_instance_valid(_follow):
		var parent := get_parent() as Node2D
		var base: Vector2 = _follow.global_position + _follow_offset
		position = base - (parent.global_position if parent != null else Vector2.ZERO)
	var p := progress_at(_t)
	_apply_progress(p)
	if p >= 1.0:
		queue_free()
