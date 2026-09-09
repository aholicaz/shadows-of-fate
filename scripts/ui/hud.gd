## HUD — แถบสถานะบนจอ (โฉม Petrol รอบ 98 ตามภาพตัวอย่างของผู้ใช้)
##
##   ซ้ายบน   : รูปหน้าวงกลมขอบทอง + ตราอาชีพ · "Lv.20  ชื่อ" · เหรียญซีนี · หลอด HP / SP
##              ใต้ลงมา: ◆ ชื่อเควสที่ติดตาม + เป้าหมาย (0/1)
##   ขวาบน    : แถบเมนู 6 ปุ่ม (IconMenuBar) · ใต้ลงมา: ─◆─ ชื่อแมพ ─◆─ + ชื่อภูมิภาค
##   ล่าง     : "EXP 16.9%" + แถบ EXP ทองบาง ๆ ยาวเต็มจอ (เพชรกลาง) · ขวาล่าง: สัญญาณ + นาฬิกา
##   ปุ่มโจมตี/สกิล/พุ่งหลบ/ยา Q R อยู่ที่ TouchControls (โชว์ทุกเครื่อง)
##
## สร้างทั้งหมดด้วยโค้ด ไม่ต้องจัด Scene เอง
class_name HUD
extends Control

## ★ ชื่อภูมิภาคใต้ชื่อแมพ ★ (แมพไหนไม่อยู่ในนี้ = ใช้ชื่อบท)
const REGION_NAMES := {
	&"prontera_town": "มิดการ์ด · บทที่ 1", &"prontera_field": "มิดการ์ด · บทที่ 1",
	&"asgard_forest_2": "มิดการ์ด · บทที่ 1", &"dark_forest": "มิดการ์ด · บทที่ 1",
	&"dark_forest_2": "มิดการ์ด · บทที่ 1", &"thunder_scar": "ที่ราบสูงสายฟ้า · บทที่ 1",
	&"iron_road": "นิดาเวลลีร์ · บทที่ 2", &"nidavellir_town": "นิดาเวลลีร์ · บทที่ 2",
	&"ember_mine": "นิดาเวลลีร์ · บทที่ 2", &"hall_of_silence": "นิดาเวลลีร์ · บทที่ 2",
	&"cold_forge": "นิดาเวลลีร์ · บทที่ 2", &"root_road": "วานาเฮม · บทที่ 3",
	&"vanir_town": "วานาเฮม · บทที่ 3", &"silver_marsh": "วานาเฮม · บทที่ 3",
	&"withered_grove": "วานาเฮม · บทที่ 3", &"forgotten_battlefield": "วานาเฮม · บทที่ 3",
	&"spring_of_life": "วานาเฮม · บทที่ 3", &"gm_room": "ห้องทดสอบ",
}
const PORTRAIT_D := 84.0
const MARGIN := 18.0

var hp_bar: ProgressBar
var sp_bar: ProgressBar
var exp_bar: ProgressBar
var hp_text: Label
var sp_text: Label
var exp_text: Label
var level_label: Label
var zeny_label: Label
var buff_box: HBoxContainer
var notice_label: Label
## กรอบซ้ายบน — ใช้เช็คว่าคลิกโดน UI หรือเปล่า (UI.is_point_over_ui)
var top_panel: Control
## (รอบ 98) ไม่มีแถบคำใบ้ล่างจอกับแผงปุ่มลัดแล้ว — เก็บชื่อไว้ให้โค้ดเก่าที่อ้างถึงไม่พัง
var bottom_panel: Control = null
var hotkey_panel: Control = null
## ชื่อแมพ + ภูมิภาค (ขวาบน ใต้แถบเมนู)
var map_block: Control
var map_name_label: Label
var region_label: Label
## เควสที่ติดตาม
var quest_block: Control
var quest_title: Label
var quest_lines: VBoxContainer
## ขวาล่าง
var clock_label: Label
var _portrait: Control
var _notice_timer := 0.0
var _clock_timer := 0.0


func _ready() -> void:
	# ★ ต้อง _and_offsets_ ★ ไม่งั้นกรอบ HUD ยังกว้าง 0 อยู่
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_top_left()
	_build_quest_tracker()
	_build_map_block()
	_build_bottom()
	_build_notice()

	Events.hp_changed.connect(_on_hp_changed)
	Events.sp_changed.connect(_on_sp_changed)
	Events.exp_changed.connect(_on_exp_changed)
	Events.job_exp_changed.connect(func(_c, _n): _refresh_level())
	Events.job_level_up.connect(func(_lv): _refresh_all())
	Events.level_up.connect(func(_lv): _refresh_all())
	Events.stats_changed.connect(_refresh_all)
	Events.zeny_changed.connect(_on_zeny_changed)
	Events.buff_changed.connect(_refresh_buffs)
	Events.notice.connect(show_notice)
	Events.map_changed.connect(func(_id): _refresh_map())
	Events.quest_changed.connect(_refresh_quest)
	Events.quest_accepted.connect(func(_q): _refresh_quest())
	Events.quest_progress.connect(func(_q, _c, _n): _refresh_quest())
	Events.quest_completed.connect(func(_q): _refresh_quest())
	get_viewport().size_changed.connect(_layout)

	_refresh_all()
	_refresh_map()
	_refresh_quest()
	_layout.call_deferred()


# =========================================================
# ซ้ายบน: รูปหน้า + เลเวล/ชื่อ + ซีนี + หลอด
# =========================================================
func _build_top_left() -> void:
	top_panel = Control.new()
	top_panel.name = "TopLeft"
	top_panel.position = Vector2(MARGIN, 14)
	top_panel.custom_minimum_size = Vector2(360, 96)
	top_panel.size = Vector2(360, 96)
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_panel)

	# ---------- รูปหน้าวงกลม ----------
	var ring := PetrolWidgets.portrait_ring(PORTRAIT_D)
	ring.position = Vector2.ZERO
	ring.size = Vector2(PORTRAIT_D, PORTRAIT_D)
	top_panel.add_child(ring)
	_portrait = PetrolWidgets.circle_portrait(PORTRAIT_D, _player_portrait())
	_portrait.position = Vector2.ZERO
	_portrait.size = Vector2(PORTRAIT_D, PORTRAIT_D)
	top_panel.add_child(_portrait)
	# ตราอาชีพเม็ดเล็กมุมล่างซ้ายของรูป
	var emblem_bg := PetrolWidgets.portrait_ring(28.0)
	emblem_bg.position = Vector2(-2, PORTRAIT_D - 30)
	emblem_bg.size = Vector2(28, 28)
	top_panel.add_child(emblem_bg)
	var emblem := PetrolWidgets.glyph("emblem", 18.0, UITheme.ACCENT)
	emblem.position = Vector2(3, PORTRAIT_D - 25)
	emblem.size = Vector2(18, 18)
	top_panel.add_child(emblem)

	# ---------- ข้อความ + หลอด ----------
	var box := VBoxContainer.new()
	box.position = Vector2(PORTRAIT_D + 12, 4)
	box.size = Vector2(250, 90)
	box.add_theme_constant_override("separation", 5)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_panel.add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	box.add_child(top)
	level_label = UITheme.make_label("Lv.1  นักดาบ", 17, UITheme.TEXT)
	level_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	level_label.add_theme_constant_override("outline_size", 3)
	top.add_child(level_label)
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 14
	top.add_child(spacer)
	top.add_child(PetrolWidgets.glyph("coin", 16.0))
	zeny_label = UITheme.make_label("0", 14, UITheme.GOLD_BRIGHT)
	zeny_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	zeny_label.add_theme_constant_override("outline_size", 3)
	top.add_child(zeny_label)

	var hp_pair := _bar_row(UITheme.HP, 170.0, 10.0)
	hp_bar = hp_pair[0]
	hp_text = hp_pair[1]
	box.add_child(hp_pair[2])

	var sp_pair := _bar_row(UITheme.SP, 150.0, 9.0)
	sp_bar = sp_pair[0]
	sp_text = sp_pair[1]
	box.add_child(sp_pair[2])

	buff_box = HBoxContainer.new()
	buff_box.add_theme_constant_override("separation", 6)
	buff_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(buff_box)


## หลอด + ตัวเลขทางขวา (แบบภาพ: หลอดสั้น ตัวเลขอยู่นอกหลอด)  คืน [ProgressBar, Label, Container]
func _bar_row(color: Color, width: float, height: float) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := UITheme.make_bar(color, height)
	bar.custom_minimum_size = Vector2(width, height)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bar)
	var text := UITheme.make_label("", 12, UITheme.TEXT)
	text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	text.add_theme_constant_override("outline_size", 3)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	return [bar, text, row]


## รูปหน้าผู้เล่น: ใช้ไฟล์ glyphs/portrait.png ถ้ามี · ไม่มีก็ตัด "หัว" จากท่ายืนของตัวละครมาใช้
func _player_portrait() -> Texture2D:
	var tex := UITheme.glyph_texture("portrait")
	if tex != null:
		return tex
	var frames: SpriteFrames = null
	var player := get_tree().get_first_node_in_group("player")
	if player != null and "sprite" in player and player.sprite != null:
		frames = player.sprite.sprite_frames
	if frames == null and ResourceLoader.exists("res://data/sprites/player_frames.tres"):
		frames = load("res://data/sprites/player_frames.tres")
	if frames == null:
		return null
	var anim := &"Idle"
	if not frames.has_animation(anim):
		var names := frames.get_animation_names()
		if names.is_empty():
			return null
		anim = names[0]
	if frames.get_frame_count(anim) <= 0:
		return null
	var base := frames.get_frame_texture(anim, 0)
	if base == null:
		return null
	var m: Dictionary = SpriteFit.measure(frames, anim)
	var fd: Dictionary = m.frames[0] if not m.get("frames", []).is_empty() else {}
	var ts := base.get_size()
	var used_h: float = float(m.get("tallest", ts.y))
	var bottom: float = float(fd.get("bottom", ts.y * 0.5)) + ts.y * 0.5
	var top: float = maxf(0.0, bottom - used_h)
	var cx: float = ts.x * 0.5 + float(fd.get("dx", 0.0))
	var side: float = used_h * 0.42
	var at := AtlasTexture.new()
	at.atlas = base
	at.region = Rect2(cx - side * 0.5, top - side * 0.06, side, side)
	return at


# =========================================================
# เควสที่ติดตาม (ใต้หลอดเลือด)
# =========================================================
func _build_quest_tracker() -> void:
	quest_block = VBoxContainer.new()
	quest_block.name = "QuestTracker"
	quest_block.position = Vector2(MARGIN + 6, 118)
	quest_block.add_theme_constant_override("separation", 2)
	quest_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(quest_block)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	quest_block.add_child(head)
	var q := PetrolWidgets.glyph("quest", 22.0)
	q.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(q)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	head.add_child(col)
	quest_title = UITheme.make_label("", 16, UITheme.TEXT)
	quest_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	quest_title.add_theme_constant_override("outline_size", 3)
	col.add_child(quest_title)
	var rule := PetrolWidgets.ornament(200.0, UITheme.ACCENT, 3.0)
	(rule as PetrolWidgets._Ornament).diamond_at_start = true
	rule.custom_minimum_size = Vector2(200, 8)
	col.add_child(rule)
	quest_lines = VBoxContainer.new()
	quest_lines.add_theme_constant_override("separation", 0)
	col.add_child(quest_lines)


func _refresh_quest() -> void:
	if quest_block == null:
		return
	var log: QuestLog = PlayerState.quests if "quests" in PlayerState else null
	if log == null or log.active.is_empty():
		quest_block.visible = false
		return
	# ติดตามเควสที่รับล่าสุด (ใช้ตัวท้ายสุดของรายการ)
	var qid: StringName = log.active[log.active.size() - 1]
	var q := GameData.get_quest(qid)
	if q == null:
		quest_block.visible = false
		return
	quest_block.visible = true
	quest_title.text = q.title
	GameWindow.clear_container(quest_lines)
	var lines := log.progress_lines(qid)
	var shown := 0
	for line in lines:
		var l := UITheme.make_label(String(line).replace("[x]", "✓").replace("[ ]", "").strip_edges(), 12, UITheme.TEXT_DIM)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
		l.add_theme_constant_override("outline_size", 3)
		quest_lines.add_child(l)
		shown += 1
		if shown >= 3:
			break
	if log.is_ready(qid):
		var done := UITheme.make_label("ครบแล้ว — กลับไปส่งเควส", 12, UITheme.GOOD)
		done.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
		done.add_theme_constant_override("outline_size", 3)
		quest_lines.add_child(done)


# =========================================================
# ชื่อแมพ (ขวาบน ใต้แถบเมนู)
# =========================================================
func _build_map_block() -> void:
	map_block = VBoxContainer.new()
	map_block.name = "MapBlock"
	map_block.add_theme_constant_override("separation", 0)
	map_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_block)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_END
	map_block.add_child(row)
	var left := PetrolWidgets.ornament(44.0, UITheme.ACCENT, 3.0)
	left.custom_minimum_size = Vector2(44, 10)
	left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(left)
	map_name_label = UITheme.make_label("", 17, UITheme.TEXT)
	map_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	map_name_label.add_theme_constant_override("outline_size", 3)
	row.add_child(map_name_label)
	var right := PetrolWidgets.ornament(44.0, UITheme.ACCENT, 3.0)
	right.custom_minimum_size = Vector2(44, 10)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(right)

	region_label = UITheme.make_label("", 11, UITheme.TEXT_DIM)
	region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	region_label.add_theme_constant_override("outline_size", 3)
	map_block.add_child(region_label)


func _refresh_map() -> void:
	if map_block == null:
		return
	var id: StringName = PlayerState.current_map_id
	map_name_label.text = Game.map_display_name(id)
	region_label.text = String(REGION_NAMES.get(id, ""))
	_layout.call_deferred()


# =========================================================
# ล่าง: EXP + นาฬิกา
# =========================================================
func _build_bottom() -> void:
	var exp_row := HBoxContainer.new()
	exp_row.name = "ExpRow"
	exp_row.add_theme_constant_override("separation", 8)
	exp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(exp_row)
	var cap := UITheme.make_label("EXP", 13, UITheme.TEXT)
	cap.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	cap.add_theme_constant_override("outline_size", 3)
	exp_row.add_child(cap)
	exp_text = UITheme.make_label("0.0000%", 13, UITheme.TEXT)
	exp_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	exp_text.add_theme_constant_override("outline_size", 3)
	exp_row.add_child(exp_text)
	exp_row.set_meta("hud_role", "exp_row")

	exp_bar = UITheme.make_bar(UITheme.EXP, 4.0)
	exp_bar.name = "ExpBar"
	var bg := UITheme.bar_bg_style()
	bg.set_corner_radius_all(2)
	bg.border_color = Color(UITheme.ACCENT, 0.35)
	exp_bar.add_theme_stylebox_override("background", bg)
	var fill := UITheme.bar_fill_style(UITheme.EXP)
	fill.set_corner_radius_all(2)
	exp_bar.add_theme_stylebox_override("fill", fill)
	exp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(exp_bar)
	var mid := PetrolWidgets.ornament(24.0, UITheme.ACCENT, 5.0)
	mid.name = "ExpDiamond"
	mid.custom_minimum_size = Vector2(24, 14)
	add_child(mid)

	var right := HBoxContainer.new()
	right.name = "ClockRow"
	right.add_theme_constant_override("separation", 8)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right)
	right.add_child(PetrolWidgets.glyph("signal", 14.0))
	clock_label = UITheme.make_label("00:00", 13, UITheme.TEXT)
	clock_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	clock_label.add_theme_constant_override("outline_size", 3)
	right.add_child(clock_label)
	_tick_clock()


func _tick_clock() -> void:
	if clock_label == null:
		return
	var t := Time.get_time_dict_from_system()
	clock_label.text = "%02d:%02d" % [int(t.hour), int(t.minute)]


## จัดตำแหน่งของที่ยึดขอบจอ (เรียกตอนเริ่ม/จอเปลี่ยนขนาด/เปลี่ยนแมพ)
func _layout() -> void:
	var vp := get_viewport_rect().size
	# EXP ล่างสุด ยาวเต็มจอ
	var exp_row := get_node_or_null("ExpRow") as Control
	if exp_row != null:
		exp_row.position = Vector2(MARGIN, vp.y - 80)
	if exp_bar != null:
		exp_bar.position = Vector2(MARGIN, vp.y - 62)
		exp_bar.size = Vector2(vp.x - MARGIN * 2.0, 4)
		var mid := get_node_or_null("ExpDiamond") as Control
		if mid != null:
			mid.position = Vector2(vp.x * 0.5 - 12, vp.y - 67)
			mid.size = Vector2(24, 14)
	var clock_row := get_node_or_null("ClockRow") as Control
	if clock_row != null:
		clock_row.reset_size()
		var w: float = maxf(clock_row.size.x, clock_row.get_combined_minimum_size().x)
		clock_row.position = Vector2(vp.x - MARGIN - w, vp.y - 80)
	# ชื่อแมพ: ชิดขวา ใต้แถบเมนู (แถบเมนูสูง ~70)
	if map_block != null:
		map_block.reset_size()
		var mw: float = maxf(map_block.size.x, map_block.get_combined_minimum_size().x)
		var top := 12.0 + IconMenuBar.BTN_H + 6.0
		if UI.menu_bar != null and UI.menu_bar.visible:
			top = UI.menu_bar.position.y + maxf(UI.menu_bar.size.y, IconMenuBar.BTN_H) + 6.0
		map_block.position = Vector2(vp.x - 12.0 - mw, top)
		# มินิแมพมุมจอขยับลงมาอยู่ใต้ชื่อแมพ
		if UI.minimap != null and not UI.minimap.embedded:
			UI.minimap.top_offset = top + maxf(map_block.size.y, map_block.get_combined_minimum_size().y) + 10.0
			UI.minimap.place()


# =========================================================
# ข้อความแจ้งเตือน
# =========================================================
func _build_notice() -> void:
	notice_label = UITheme.make_label("", 18, UITheme.GOLD_BRIGHT)
	# ★ ต้องใช้ set_anchors_AND_OFFSETS_preset ★ ไม่งั้นกรอบกว้าง 0 ข้อความไปกองมุมซ้าย
	notice_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	notice_label.offset_top = 150
	notice_label.offset_bottom = 192
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice_label.add_theme_color_override("font_outline_color", Color.BLACK)
	notice_label.add_theme_constant_override("outline_size", 5)
	notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_label.modulate.a = 0.0
	add_child(notice_label)


func show_notice(message: String) -> void:
	if notice_label == null:
		return
	notice_label.text = message
	notice_label.modulate.a = 1.0
	_notice_timer = 2.5


func _process(delta: float) -> void:
	# ★ เปิดหน้าต่างรวมอยู่ = ซ่อนแถบ EXP/นาฬิกาล่างจอ (ภาพตัวอย่างหน้ากระเป๋าไม่มี และคำใบ้ปุ่มใช้ที่ตรงนั้น) ★
	var shell_open: bool = UI.shell != null and UI.shell.visible
	for n in ["ExpRow", "ExpBar", "ExpDiamond", "ClockRow"]:
		var c := get_node_or_null(n) as Control
		if c != null:
			c.visible = not shell_open
	if _notice_timer > 0.0:
		_notice_timer -= delta
		if _notice_timer <= 0.5:
			notice_label.modulate.a = maxf(0.0, _notice_timer / 0.5)
	_clock_timer -= delta
	if _clock_timer <= 0.0:
		_clock_timer = 5.0
		_tick_clock()
	_refresh_buffs()


# =========================================================
# อัพเดตข้อมูล
# =========================================================
func _refresh_all() -> void:
	var s := PlayerState.stats
	if s == null:
		return
	_refresh_level()
	_on_hp_changed(s.hp, s.max_hp)
	_on_sp_changed(s.sp, s.max_sp)
	_on_exp_changed(s.exp_current, s.exp_to_next())
	_on_zeny_changed(PlayerState.zeny)


func _refresh_level() -> void:
	var s := PlayerState.stats
	if s == null or level_label == null:
		return
	# ★ ภาพตัวอย่าง: "Lv.20  Arlen" — เกมเรามีเลเวลอาชีพด้วย เลยใส่ต่อท้ายเล็ก ๆ ★
	level_label.text = "Lv.%d  %s  (Job %d)" % [s.level, s.job().display_name, s.job_level]


func _on_hp_changed(current: int, maximum: int) -> void:
	hp_bar.max_value = maxi(1, maximum)
	hp_bar.value = current
	hp_text.text = "%d / %d" % [current, maximum]


func _on_sp_changed(current: int, maximum: int) -> void:
	sp_bar.max_value = maxi(1, maximum)
	sp_bar.value = current
	sp_text.text = "%d / %d" % [current, maximum]


func _on_exp_changed(current: int, needed: int) -> void:
	exp_bar.max_value = maxi(1, needed)
	exp_bar.value = current
	if needed <= 0:
		exp_text.text = "MAX"
	else:
		exp_text.text = "%.4f%%" % (float(current) / needed * 100.0)


func _on_zeny_changed(amount: int) -> void:
	zeny_label.text = _comma(amount)


func _refresh_buffs() -> void:
	if buff_box == null:
		return
	var wanted := PlayerState.active_buffs.size()
	if buff_box.get_child_count() != wanted:
		GameWindow.clear_container(buff_box)
		for sid in PlayerState.active_buffs.keys():
			var s := GameData.get_skill(StringName(sid))
			var name_text: String = s.display_name if s != null else String(PlayerState.active_buffs[sid].get("name", sid))
			var lbl := UITheme.make_label(name_text, 11, UITheme.GOLD_BRIGHT)
			lbl.name = String(sid)
			lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
			lbl.add_theme_constant_override("outline_size", 3)
			buff_box.add_child(lbl)

	for child in buff_box.get_children():
		var info: Dictionary = PlayerState.active_buffs.get(StringName(child.name), {})
		if info.has("time_left") and child is Label:
			var s := GameData.get_skill(StringName(child.name))
			var n: String = s.display_name if s != null else String(info.get("name", child.name))
			(child as Label).text = "%s %ds" % [n, int(info.time_left)]


static func _comma(value: int) -> String:
	var text := str(absi(value))
	var out := ""
	var count := 0
	for i in range(text.length() - 1, -1, -1):
		out = text[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if value < 0 else "") + out
