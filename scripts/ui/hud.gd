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
## ★ รอบ 102 ★ ป้ายเควสบนจอหลัก — ระยะจากขอบบน (เดิม 118 ไปชนหลอดเลือด/แถบ EXP)
const QUEST_TRACKER_Y := 168.0
## สีบรรทัดเป้าหมายของเควส — เทาเดิมจมฉาก จึงใช้เทาอมเขียวสว่างขึ้น
const QUEST_LINE := Color("#cfe0d4")
## ★ รอบ 116 ★ สีป้าย «ภารกิจถัดไป» (ตอนไม่มีเควสค้าง) — อ่อนกว่าเควสจริงให้รู้ว่าเป็นคำใบ้ ไม่ใช่เควสที่รับแล้ว
const NEXT_TITLE := Color("#b9cfc1")
const NEXT_LINE := Color("#cfe0d4", 0.82)

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
var _rank_badge: TextureRect   # ★ รอบ 164 ★ ตราขั้นกิลด์ข้างรูปหน้า
var _rank_badge_letter := ""
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
	Events.level_up.connect(func(_lv): _refresh_quest())   # ★ รอบ 116 ★ ป้ายภารกิจถัดไปขึ้นกับเลเวล
	Events.stats_changed.connect(_refresh_all)
	Events.zeny_changed.connect(_on_zeny_changed)
	Events.buff_changed.connect(_refresh_buffs)
	Events.notice.connect(show_notice)
	Events.map_changed.connect(func(_id): _refresh_map())
	Events.quest_changed.connect(_refresh_quest)
	Events.quest_changed.connect(_refresh_rank_badge)   # ★ รอบ 164 ★ ส่งใบประกาศ = อาจเลื่อนขั้น
	Events.stats_changed.connect(_refresh_rank_badge)
	Events.quest_changed.connect(_refresh_level)   # ★ รอบ 105 ★ ธง name_left เปลี่ยน → อัปเดตชื่อ
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
	# ★ รอบ 164 ★ ตราขั้นกิลด์ (F-S) มุมล่างซ้ายของรูป แทนตราวงกลมเดิม · คลิก = เปิดหน้าขั้นกิลด์
	_rank_badge = TextureRect.new()
	_rank_badge.name = "GuildRankBadge"
	_rank_badge.position = Vector2(-8, PORTRAIT_D - 38)
	_rank_badge.size = Vector2(40, 40)
	_rank_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rank_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_rank_badge.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_rank_badge.mouse_filter = Control.MOUSE_FILTER_STOP
	_rank_badge.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_rank_badge.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
			Events.guild_rank_opened.emit())
	top_panel.add_child(_rank_badge)
	_refresh_rank_badge()

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
	# ★ รอบ 170 ★ เอาซีนีออกจากมุมซ้ายบน (ดูได้ในกระเป๋า/ร้าน/หน้าระบบ) — เหลือที่ให้แถบลัด
	# ยังสร้าง zeny_label ไว้ (ซ่อน) ให้โค้ดเดิมที่อัปเดตตัวเลขไม่พัง
	zeny_label = UITheme.make_label("0", 14, UITheme.GOLD_BRIGHT)
	zeny_label.visible = false
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
	# ★★ รอบ 102 ★★ เดิมคืน AtlasTexture ชี้เข้าชีทตัวละครก้อนใหญ่ (1112×834)
	# แล้วเอาไปย่อวาดในวงกลม 84 px = ย่อ ~4 เท่าโดยไม่มี mipmap → ขอบหยัก "ภาพแตก"
	# ตอนนี้ตัดเป็นภาพจริงแล้วย่อด้วย LANCZOS เหลือ 2 เท่าของขนาดจอ + สร้าง mipmap ให้เลย
	var rect := Rect2i(Vector2i(cx - side * 0.5, top - side * 0.06), Vector2i(maxi(2, int(side)), maxi(2, int(side))))
	var src: Image = base.get_image()
	if src == null:
		var at := AtlasTexture.new()
		at.atlas = base
		at.region = Rect2(rect)
		return at
	if src.is_compressed():
		src.decompress()
	rect = rect.intersection(Rect2i(Vector2i.ZERO, src.get_size()))
	if rect.size.x < 2 or rect.size.y < 2:
		return null
	var cut := src.get_region(rect)
	var want := int(PORTRAIT_D * 2.0)
	if cut.get_width() > want:
		cut.resize(want, want, Image.INTERPOLATE_LANCZOS)
	cut.generate_mipmaps()
	return ImageTexture.create_from_image(cut)


# =========================================================
# เควสที่ติดตาม (ใต้หลอดเลือด)
# =========================================================
func _build_quest_tracker() -> void:
	quest_block = VBoxContainer.new()
	quest_block.name = "QuestTracker"
	# ★ รอบ 102 ★ เลื่อนลงให้พ้นหลอดเลือด/แถบ EXP (เดิม 118 = ชนกันจนอ่านยาก)
	quest_block.position = Vector2(MARGIN + 6, QUEST_TRACKER_Y)
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
	quest_title = UITheme.make_label("", 24, UITheme.TEXT)
	quest_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	quest_title.add_theme_constant_override("outline_size", 3)
	quest_title.custom_minimum_size.x = 380
	quest_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	_ensure_side_block()
	if log == null:
		quest_block.visible = false
		return
	# ★ รอบ 163 ★ เควสหลัก (เนื้อเรื่อง) อยู่บนเสมอ · เควสรอง (ใบประกาศล่า/เควสเสริม/Runeblade) อยู่ใต้ ตัวเล็กกว่า
	var main_id := _latest_active(log, false)
	var side_id := _latest_active(log, true)
	var main_shown := false
	if main_id != &"":
		main_shown = _show_active(log, main_id, quest_title, quest_lines, 24, 20, 3, "")
	if not main_shown:
		main_shown = _show_next_quest_hint(log)
	var side_shown := false
	if side_id != &"":
		side_shown = _show_active(log, side_id, _side_title, _side_lines, 18, 16, 2, "เควสรอง · ")
	elif not main_shown or not _side_hint_only_when_idle():
		side_shown = _show_side_hint(log)
	_side_row.visible = side_shown
	if not main_shown and side_shown:
		# ไม่มีเควสหลักให้ทำ → ซ่อนหัวเควสหลัก ให้เควสรองขึ้นแทน
		quest_title.text = ""
		GameWindow.clear_container(quest_lines)
	_main_row.visible = main_shown
	quest_block.visible = main_shown or side_shown


## ★ รอบ 163 ★ คำใบ้เควสรองที่ยังไม่รับ (เช่น «ใบประกาศใบแรก») โชว์ก็ต่อเมื่อไม่มีเควสหลักให้ทำ → false = โชว์คู่กันเสมอ
func _side_hint_only_when_idle() -> bool:
	return false


## ★ รอบ 163 ★ เควสรอง = ใบประกาศล่า · สาย Runeblade (rb*) · เควสเสริมในรายชื่อ SIDE_QUESTS
const SIDE_QUESTS := [&"m3_guild_bounty", &"rb15_song_for_brokk", &"c6_11_letter_home"]


static func is_side_quest(qid: StringName) -> bool:
	var sid := String(qid)
	return sid.begins_with("bounty_") or sid.begins_with("rb") or qid in SIDE_QUESTS


## เควสที่รับล่าสุดของกลุ่มนั้น (&"" = ไม่มี)
func _latest_active(log: QuestLog, side: bool) -> StringName:
	for i in range(log.active.size() - 1, -1, -1):
		var qid: StringName = log.active[i]
		if is_side_quest(qid) == side and GameData.get_quest(qid) != null:
			return qid
	return &""


func _show_active(log: QuestLog, qid: StringName, title: Label, lines_box: VBoxContainer,
		title_size: int, line_size: int, max_lines: int, prefix: String) -> bool:
	var q := GameData.get_quest(qid)
	if q == null:
		return false
	title.text = prefix + q.title
	title.add_theme_font_size_override("font_size", title_size)
	title.add_theme_color_override("font_color", UITheme.TEXT)
	GameWindow.clear_container(lines_box)
	var shown := 0
	for line in log.progress_lines(qid):
		# ★ รอบ 102 ★ เดิมใช้ TEXT_DIM (#81958a) ทับฉากสว่าง ๆ แล้วแทบมองไม่เห็น
		var l := UITheme.make_label(String(line).replace("[x]", "✓").replace("[ ]", "").strip_edges(), line_size, QUEST_LINE)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override("outline_size", 4)
		l.custom_minimum_size.x = 380
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lines_box.add_child(l)
		shown += 1
		if shown >= max_lines:
			break
	if log.is_ready(qid):
		var done := UITheme.make_label("ครบแล้ว — กลับไปส่งเควส", line_size, UITheme.GOOD)
		done.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
		done.add_theme_constant_override("outline_size", 3)
		lines_box.add_child(done)
	return true


## ★ รอบ 116 ★ ป้าย «ภารกิจถัดไป» — ผู้เล่นส่งเควสครบ/ยังไม่ถึงเลเวล จะได้รู้ว่าต้องทำอะไรต่อ
## ★ รอบ 163 ★ นับเฉพาะเควสหลัก (เควสรองไปอยู่ป้ายล่าง) · คืน true ถ้ามีป้ายให้โชว์
func _show_next_quest_hint(log: QuestLog) -> bool:
	var q := _next_quest(log)
	if q == null:
		return false
	quest_title.text = "ภารกิจถัดไป"
	quest_title.add_theme_font_size_override("font_size", 24)
	quest_title.add_theme_color_override("font_color", NEXT_TITLE)
	GameWindow.clear_container(quest_lines)
	quest_lines.add_child(_hint_label(q, 20))
	return true


## ★ รอบ 163 ★ เควสรองที่รับได้ตอนนี้ (ถึงเลเวลแล้ว) → ป้ายล่าง «เควสรอง · …»
func _show_side_hint(log: QuestLog) -> bool:
	var q := _next_quest(log, true)
	if q == null or PlayerState.stats.level < q.required_level:
		return false
	_side_title.text = "เควสรอง · ภารกิจแนะนำ"
	_side_title.add_theme_font_size_override("font_size", 18)
	_side_title.add_theme_color_override("font_color", NEXT_TITLE)
	GameWindow.clear_container(_side_lines)
	_side_lines.add_child(_hint_label(q, 16))
	return true


func _hint_label(q: QuestData, size: int) -> Label:
	var where := NpcDirectory.map_name_of(q.giver_name, _quest_chapter(q.id))
	var who: String = q.giver_name if where == "" else "%s (%s)" % [q.giver_name, where]
	var text: String
	if PlayerState.stats.level < q.required_level:
		text = "บรรลุ Lv %d แล้วไปคุยกับ %s เพื่อรับภารกิจ" % [q.required_level, who]
	else:
		text = "ไปคุยกับ %s เพื่อรับภารกิจ «%s»" % [who, q.title]
	var l := UITheme.make_label(text, size, NEXT_LINE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	l.custom_minimum_size.x = 380
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## ★ รอบ 163 ★ แถวเควสรอง (สร้างครั้งแรกที่ใช้ — ต่อท้ายกล่องเควสเดิม)
var _main_row: Control
var _side_row: HBoxContainer
var _side_title: Label
var _side_lines: VBoxContainer


func _ensure_side_block() -> void:
	if _side_row != null:
		return
	_main_row = quest_block.get_child(0) as Control
	_side_row = HBoxContainer.new()
	_side_row.name = "SideQuest"
	_side_row.add_theme_constant_override("separation", 8)
	_side_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_block.add_child(_side_row)
	var g := PetrolWidgets.glyph("quest", 16.0, UITheme.TEXT_DIM)
	g.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	g.custom_minimum_size = Vector2(22, 16)
	_side_row.add_child(g)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	_side_row.add_child(col)
	var gap := Control.new()
	gap.custom_minimum_size.y = 6
	col.add_child(gap)
	_side_title = UITheme.make_label("", 18, UITheme.TEXT)
	_side_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_side_title.add_theme_constant_override("outline_size", 3)
	_side_title.custom_minimum_size.x = 380
	_side_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_side_title)
	_side_lines = VBoxContainer.new()
	_side_lines.add_theme_constant_override("separation", 0)
	col.add_child(_side_lines)
	if not Events.quest_changed.is_connected(_refresh_quest):
		Events.quest_changed.connect(_refresh_quest)


## เควสถัดไปที่ "เปิดให้รับได้แล้วหรือรอแค่เลเวล" — เลเวลต่ำสุดก่อน · ไม่นับใบประกาศ/ทำซ้ำ
## ★ รอบ 163 ★ side = false → เฉพาะเควสหลัก · side = true → เฉพาะเควสรอง (รวม rb*)
func _next_quest(log: QuestLog, side: bool = false) -> QuestData:
	var best: QuestData = null
	var best_key: Array = []
	var lv: int = PlayerState.stats.level
	for q in GameData.all_quests():
		if q == null or q.repeatable:
			continue
		var sid := String(q.id)
		if is_side_quest(q.id) != side:
			continue
		if log.is_active(q.id) or log.is_done(q.id):
			continue
		var ok := true
		for prev in q.required_quests:
			if not log.is_done(prev):
				ok = false
				break
		if not ok:
			continue
		if q.required_flag != &"" and not PlayerState.has_flag(q.required_flag):
			continue
		if q.required_job != &"" and PlayerState.stats.job_id != q.required_job \
				and not (q.reward_job != &"" and PlayerState.stats.has_profession(q.reward_job)):
			continue
		var key: Array = [0 if lv >= q.required_level else 1, q.required_level, sid]
		if best == null or key < best_key:
			best = q
			best_key = key
	return best


## บทของเควสจาก id (c3_… = 3 · m*/hans*/tony* = 1 · อื่น ๆ 0)
static func _quest_chapter(qid: StringName) -> int:
	var sid := String(qid)
	if sid.begins_with("c") and sid.length() > 2 and sid[1].is_valid_int():
		return int(sid[1])
	if sid.begins_with("m") or sid.begins_with("hans") or sid.begins_with("tony"):
		return 1
	return 0


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
	map_name_label = UITheme.make_label("", 24, UITheme.TEXT)
	map_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	map_name_label.add_theme_constant_override("outline_size", 3)
	row.add_child(map_name_label)
	var right := PetrolWidgets.ornament(44.0, UITheme.ACCENT, 3.0)
	right.custom_minimum_size = Vector2(44, 10)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(right)

	region_label = UITheme.make_label("", 19, UITheme.TEXT)
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
		exp_row.position = Vector2(MARGIN, vp.y - 30)
	if exp_bar != null:
		exp_bar.position = Vector2(MARGIN, vp.y - 12)
		exp_bar.size = Vector2(vp.x - MARGIN * 2.0, 4)
		var mid := get_node_or_null("ExpDiamond") as Control
		if mid != null:
			mid.position = Vector2(vp.x * 0.5 - 12, vp.y - 17)
			mid.size = Vector2(24, 14)
	var clock_row := get_node_or_null("ClockRow") as Control
	if clock_row != null:
		clock_row.reset_size()
		var w: float = maxf(clock_row.size.x, clock_row.get_combined_minimum_size().x)
		clock_row.position = Vector2((vp.x - w) * 0.5, vp.y - 40)
	# ชื่อแมพ: ชิดขวา ใต้แถบเมนู (แถบเมนูสูง ~70)
	if map_block != null:
		map_block.reset_size()
		var mw: float = maxf(map_block.size.x, map_block.get_combined_minimum_size().x)
		var top := 12.0 + IconMenuBar.BTN_H + 6.0
		if UI.menu_bar != null and UI.menu_bar.visible:
			top = UI.menu_bar.position.y + maxf(UI.menu_bar.size.y, IconMenuBar.BTN_H) + 6.0
		map_block.position = Vector2(vp.x - 12.0 - mw, top)
		# มินิแมพมุมจอขยับลงมาอยู่ใต้ชื่อแมพ



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
	preload("res://scripts/entities/crack_overlay_fx.gd").watchdog()   # ★ รอบ 151 ★ กันสโลว์โมชั่นค้าง
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
	# ★ รอบ 105 ★ ทิ้งชื่อที่สะพานเกียลล์ (C6-3) = ชื่ออาชีพว่างจนกว่าจะสลักชื่อใหม่ (Ninth Edge) หรือจบ C6-10
	var job_name: String = s.job().display_name
	if PlayerState.has_flag(&"name_left") and not PlayerState.has_flag(&"chapter6_done") and s.job_id != &"ninth_edge":
		job_name = "— ไร้นาม —"
	# ★ รอบ 170 ★ สั้นลง «Lv. 74 / Job 57 Runeblade» — ชื่ออาชีพภาษาอังกฤษจาก id (swordsman → Swordsman)
	if job_name != "— ไร้นาม —":
		job_name = String(s.job_id).capitalize()
	level_label.text = "Lv. %d / Job %d %s" % [s.level, s.job_level, job_name]
	level_label.add_theme_color_override("font_color", Color("#ffd86b") if s.job_id == &"ninth_edge" else UITheme.TEXT)


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
			var t := "%s %ds" % [n, int(info.time_left)]
			if (child as Label).text != t:   # ★ รอบ 131 ★ ตั้งข้อความเฉพาะตอนวินาทีเปลี่ยน (เดิมตั้งทุกเฟรม = จัดวางใหม่ทุกเฟรม)
				(child as Label).text = t


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


## ★ รอบ 164 ★ ตราขั้นกิลด์ข้างรูปหน้า — เปลี่ยนภาพเฉพาะตอนขั้นเปลี่ยน
func _refresh_rank_badge() -> void:
	if _rank_badge == null or PlayerState.bounties == null:
		return
	var letter := PlayerState.bounties.rank_letter()
	if letter == _rank_badge_letter:
		return
	_rank_badge_letter = letter
	_rank_badge.texture = GuildRankWindow.rank_icon(letter)
	_rank_badge.tooltip_text = "ขั้นกิลด์ %s «%s» — คลิกดูสิทธิ์พิเศษ" % [letter, PlayerState.bounties.rank_title()]
