## BossBar — หลอดเลือดบอสใบใหญ่ กลางจอด้านบน (รอบ 87)
##
## โผล่เองเมื่อ "มีบอสที่ยังไม่ตายอยู่ในแมพ และอยู่ใกล้พอ" — ไม่ต้องไปเรียกจากที่ไหน
## บอสที่ติ๊ก Use Boss Bar ไว้จะไม่มีหลอดเล็กเหนือหัวแล้ว (ดูใน monster_base._create_hp_bar)
##
## หน้าตา: ชื่อบอส + คำโปรย · หลอดแดงใหญ่ · แถบเหลืองไล่ตามหลัง (ดาเมจที่เพิ่งกิน)
## · ตัวเลขเลือด + % · ขีดแบ่งทุก 25%
class_name BossBar
extends Control

## บอสไกลเกินนี้ = ซ่อนหลอด (บอสอยู่คนละมุมแมพ ไม่ต้องโชว์)
const SHOW_RANGE := 1500.0
## ความกว้างหลอด = กี่ % ของจอ (แต่ไม่เกิน MAX_WIDTH)
const WIDTH_RATIO := 0.62
const MAX_WIDTH := 780.0
const BAR_HEIGHT := 26.0
const TOP_MARGIN := 18.0
## แถบเหลืองไล่ตามเร็วแค่ไหน (สัดส่วนต่อวินาที)
const CHASE_SPEED := 0.55
## เวลาเฟด เข้า/ออก (วินาที)
const FADE := 0.25

var _box: VBoxContainer
var _name_label: Label
var _title_label: Label
var _bar_root: Control
var _bg: ColorRect
var _chase: ColorRect
var _fill: ColorRect
var _marks: Control
var _hp_label: Label

var _boss: Node = null
var _chase_ratio := 1.0
var _target_alpha := 0.0


func _ready() -> void:
	name = "BossBar"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	visible = false
	_build()


func _build() -> void:
	_box = VBoxContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_constant_override("separation", 2)
	add_child(_box)

	_name_label = UITheme.make_label("", 22, UITheme.ACCENT)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 2)
	_box.add_child(_name_label)

	_title_label = UITheme.make_label("", 13, UITheme.TEXT_DIM)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_title_label)

	# ---------- ตัวหลอด ----------
	_bar_root = Control.new()
	_bar_root.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	_bar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_bar_root)

	_bg = _rect(Color(0.05, 0.05, 0.07, 0.92))
	_chase = _rect(Color(0.95, 0.78, 0.25, 0.75))     # ดาเมจที่เพิ่งกิน — ไล่ตามหลัง
	_fill = _rect(Color(0.85, 0.16, 0.16, 1.0))

	_marks = Control.new()
	_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_root.add_child(_marks)

	var frame := Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0)
	st.border_color = Color(0.75, 0.68, 0.45, 0.9)
	st.set_border_width_all(2)
	st.set_corner_radius_all(3)
	frame.add_theme_stylebox_override("panel", st)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bar_root.add_child(frame)

	_hp_label = UITheme.make_label("", 13, UITheme.TEXT)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_hp_label.add_theme_constant_override("shadow_offset_y", 1)
	_hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bar_root.add_child(_hp_label)


func _rect(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_root.add_child(r)
	return r


# =========================================================
# หาบอสที่ควรโชว์
# =========================================================
func _pick_boss() -> Node:
	var player := get_tree().get_first_node_in_group("player")
	var best: Node = null
	var best_d := SHOW_RANGE
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e) or e.data == null:
			continue
		if not e.data.is_boss or not e.data.use_boss_bar:
			continue
		if e.has_method("is_dead") and e.is_dead():
			continue
		if e.hp <= 0:
			continue
		if player == null:
			return e
		var d: float = e.global_position.distance_to(player.global_position)
		if d <= best_d:
			best_d = d
			best = e
	return best


func _process(delta: float) -> void:
	var found := _pick_boss()
	if found != _boss:
		_boss = found
		_chase_ratio = 1.0
		if _boss != null:
			_name_label.text = String(_boss.data.display_name)
			var t := String(_boss.data.boss_title)
			_title_label.text = t
			_title_label.visible = t != ""
	_target_alpha = 1.0 if _boss != null else 0.0

	modulate.a = move_toward(modulate.a, _target_alpha, delta / FADE)
	visible = modulate.a > 0.01
	if not visible:
		return

	_layout()
	if _boss == null:
		return

	var maxhp: float = maxf(1.0, float(_boss.data.max_hp))
	var ratio: float = clampf(float(_boss.hp) / maxhp, 0.0, 1.0)
	_chase_ratio = maxf(ratio, _chase_ratio - CHASE_SPEED * delta)

	var w: float = _bar_root.size.x
	_fill.size = Vector2(w * ratio, BAR_HEIGHT)
	_chase.size = Vector2(w * _chase_ratio, BAR_HEIGHT)
	_fill.color = Color(0.95, 0.45, 0.12) if ratio < 0.3 else Color(0.85, 0.16, 0.16)
	_hp_label.text = "%s / %s   (%d%%)" % [_comma(_boss.hp), _comma(int(maxhp)), roundi(ratio * 100.0)]


## จัดตำแหน่ง/ขนาดตามขนาดจอปัจจุบัน (จอย่อ-ขยายได้)
func _layout() -> void:
	var screen := size
	if screen.x <= 0.0:
		screen = get_viewport_rect().size
	var w: float = minf(screen.x * WIDTH_RATIO, MAX_WIDTH)
	_box.size.x = w
	_box.position = Vector2((screen.x - w) * 0.5, TOP_MARGIN)
	_bar_root.custom_minimum_size = Vector2(w, BAR_HEIGHT)
	_bar_root.size = Vector2(w, BAR_HEIGHT)
	_bg.size = Vector2(w, BAR_HEIGHT)

	# ขีดแบ่งทุก 25% — ดูออกว่าเหลือเลือดเท่าไหร่โดยไม่ต้องอ่านตัวเลข
	if _marks.get_child_count() != 3:
		for c in _marks.get_children():
			c.queue_free()
		for i in range(3):
			var m := ColorRect.new()
			m.color = Color(0, 0, 0, 0.45)
			m.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_marks.add_child(m)
	for i in range(_marks.get_child_count()):
		var m: ColorRect = _marks.get_child(i)
		m.size = Vector2(2, BAR_HEIGHT)
		m.position = Vector2(w * 0.25 * float(i + 1) - 1.0, 0)


static func _comma(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out
