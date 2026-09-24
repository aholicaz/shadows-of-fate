## BountyBoardWindow — ★ รอบ 163 ★ หน้าต่าง «บอร์ดใบประกาศล่า» (แทนเมนูในกล่องสนทนาเดิม)
##
## บน   = ขั้นกิลด์ปัจจุบัน (ไอคอน · ฉายา · หลอดแต้มไปขั้นถัดไป · ส่วนลดที่ใช้อยู่) + ปุ่ม «ดูขั้นกิลด์»
## กลาง = ใบประกาศ 3 ใบของเมืองนี้วางเป็นการ์ด (ช่อง 1 ล่ามอน · ช่อง 2 ล่า/เก็บวัตถุดิบ · ช่อง 3 ล่าบอส)
##        การ์ดบอกเป้าหมาย · หลอดความคืบหน้า · รางวัล (ไอคอน) · แต้มกิลด์ · ปุ่มตามสถานะ
##        ยังไม่รับ = «รับใบนี้» + «เปลี่ยนใบ» · กำลังทำ = หลอด + «ยกเลิก» · ครบ = ปุ่มทอง «ส่งงาน»
##        ช่องพัก = นับถอยหลัง m:ss · ช่องบอสยังล็อก = «ส่งใบธรรมดาอีก N ใบ»
## ล่าง = เมือง · ส่งแล้วทั้งหมด · คำอธิบายสั้น
## ระบบข้างหลังเป็นของเดิมทั้งหมด (BountyBoard · QuestLog · PlayerState.turn_in_quest)
class_name BountyBoardWindow
extends GameWindow

const WIN_SIZE := Vector2(1060, 600)
const CARD_W := 322.0
const KIND_NAMES := {"kill": "ใบล่ามอน", "collect": "ใบเก็บวัตถุดิบ", "boss": "ใบล่าบอส"}
const KIND_COLORS := {"kill": Color("#b5a16c"), "collect": Color("#7fc4a8"), "boss": Color("#e07b6b")}

var town: StringName = &""
var _rank_icon: TextureRect
var _rank_name: Label
var _rank_bar: ProgressBar
var _rank_text: Label
var _rank_perk: Label
var _cards: HBoxContainer
var _foot: Label
var _tick := 0.0


func _init() -> void:
	window_title = "บอร์ดใบประกาศล่า"


func _ready() -> void:
	super._ready()
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Events.quest_changed.connect(refresh)
	Events.quest_progress.connect(func(_q, _c, _n): refresh())
	Events.inventory_changed.connect(refresh)
	Events.zeny_changed.connect(func(_z): refresh())
	get_viewport().size_changed.connect(_place)


func open_board(p_town: StringName) -> void:
	town = p_town
	set_title("─◆  บอร์ดใบประกาศล่า · %s  ◆─" % Game.map_display_name(town))
	show_window()


func _process(delta: float) -> void:
	# นับถอยหลังช่องที่พักอยู่ (อัปเดตวินาทีละครั้ง)
	if not visible:
		return
	_tick += delta
	if _tick >= 1.0:
		_tick = 0.0
		var board: BountyBoard = PlayerState.bounties
		if board == null:
			return
		for i in range(BountyBoard.SLOTS):
			if board.cooldown_left(town, i) > 0.0 or _was_cooling(i):
				refresh()
				return


var _cooling: Dictionary = {}


func _was_cooling(i: int) -> bool:
	return bool(_cooling.get(i, false))


# =========================================================
# สร้างหน้าต่าง
# =========================================================
func _build_content() -> void:
	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", UITheme.panel_style(Color("#0f2422f2"), UITheme.ACCENT, 4, 1, 10.0))
	content.add_child(head)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	head.add_child(h)
	_rank_icon = TextureRect.new()
	_rank_icon.custom_minimum_size = Vector2(64, 64)
	_rank_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rank_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_rank_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	h.add_child(_rank_icon)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	_rank_name = UITheme.make_label("", 20, UITheme.GOLD_BRIGHT)
	info.add_child(_rank_name)
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 10)
	info.add_child(bar_row)
	_rank_bar = UITheme.make_bar(UITheme.ACCENT, 12.0)
	_rank_bar.custom_minimum_size.x = 360
	_rank_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_row.add_child(_rank_bar)
	_rank_text = UITheme.make_label("", 14, UITheme.TEXT_DIM)
	bar_row.add_child(_rank_text)
	_rank_perk = UITheme.make_label("", 14, UITheme.GOOD)
	info.add_child(_rank_perk)
	var rank_btn := UITheme.make_button("ดูขั้นกิลด์ ▸", 130)
	rank_btn.custom_minimum_size.y = 40
	rank_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rank_btn.pressed.connect(func(): Events.guild_rank_opened.emit())
	h.add_child(rank_btn)

	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 12)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_cards)

	content.add_child(UITheme.separator())
	_foot = UITheme.make_label("", 14, UITheme.TEXT_DIM)
	content.add_child(_foot)


# =========================================================
# refresh
# =========================================================
func refresh() -> void:
	if _cards == null or not visible or town == &"":
		return
	var board: BountyBoard = PlayerState.bounties
	if board == null:
		return
	board.ensure_board(town)
	_refresh_head(board)
	GameWindow.clear_container(_cards)
	var specs: Array = board.specs_of(town)
	_cooling.clear()
	for i in range(BountyBoard.SLOTS):
		var spec: Dictionary = specs[i] if i < specs.size() else {}
		_cards.add_child(_make_card(board, i, spec))
	_foot.text = "ส่งใบประกาศแล้ว %d ใบ · ใบล่า/ใบเก็บของ +%d แต้ม · ใบล่าบอส +%d แต้ม · ใบบอสเปิดเมื่อส่งใบธรรมดาของเมืองนี้ครบ %d ใบ · ส่งแล้วช่องนั้นพักสักครู่" % [
		board.total_turned_in, BountyBoard.POINTS_NORMAL, BountyBoard.POINTS_BOSS, BountyBoard.BOSS_UNLOCK_TURNINS]


func _refresh_head(board: BountyBoard) -> void:
	var letter := board.rank_letter()
	_rank_icon.texture = GuildRankWindow.rank_icon(letter)
	if _rank_icon.texture == null:
		var p := "res://Sprites/ui/guild_rank/rank_%s.png" % letter.to_lower()
		_rank_icon.texture = (load(p) as Texture2D) if ResourceLoader.exists(p) else null
	_rank_name.text = "ขั้น %s — «%s»" % [letter, board.rank_title()]
	var idx := board.rank_index()
	var cur_min := int(BountyBoard.RANKS[idx][1])
	var next_pts := board.next_rank_points()
	if next_pts > 0:
		_rank_bar.max_value = float(next_pts - cur_min)
		_rank_bar.value = float(board.points - cur_min)
		_rank_text.text = "แต้มกิลด์ %d · อีก %d แต้มเลื่อนเป็นขั้น %s" % [board.points, next_pts - board.points, String(BountyBoard.RANKS[idx + 1][0])]
	else:
		_rank_bar.max_value = 1.0
		_rank_bar.value = 1.0
		_rank_text.text = "แต้มกิลด์ %d · ขั้นสูงสุดแล้ว" % board.points
	_rank_perk.text = "สิทธิ์ตอนนี้: ส่วนลด %d%% (ร้าน · วาร์ป · รักษา · ขอพร · ตีบวก · ย่อยการ์ด) · พรแห่งธอร์ +%s" % [
		board.discount_percent(), BountyBoard.bless_bonus_text(idx)]


func _card_panel(accent: Color, glow: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(CARD_W, 0)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var s := UITheme.panel_style(Color("#0c1f1ee6"), accent if glow else UITheme.BORDER, 5, 2 if glow else 1, 12.0)
	s.border_width_top = 4
	s.border_color = accent if glow else Color(accent, 0.55)
	if glow:
		s.shadow_color = Color(accent, 0.35)
		s.shadow_size = 8
	p.add_theme_stylebox_override("panel", s)
	return p


func _make_card(board: BountyBoard, slot: int, spec: Dictionary) -> Control:
	var kind := "boss" if slot == BountyBoard.BOSS_SLOT else ("kill" if spec.is_empty() else String(spec.get("kind", "kill")))
	var accent: Color = KIND_COLORS.get(kind, UITheme.ACCENT)
	var qlog := PlayerState.quests
	var qid: StringName = StringName(spec.get("id", "")) if not spec.is_empty() else &""
	var q: QuestData = GameData.get_quest(qid) if qid != &"" else null
	var ready := q != null and qlog.is_ready(qid)
	var active := q != null and qlog.is_active(qid)
	var p := _card_panel(accent, ready)
	p.name = "Card%d" % slot
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	p.add_child(box)

	# หัวการ์ด: ชนิด + แต้ม
	var top := HBoxContainer.new()
	box.add_child(top)
	var kl := UITheme.make_label("%d · %s" % [slot + 1, KIND_NAMES.get(kind, "ใบประกาศ")], 15, accent)
	kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(kl)
	if not spec.is_empty():
		top.add_child(_chip("แต้มกิลด์ +%d" % int(spec.get("points", 1)), UITheme.GOLD_BRIGHT))

	# ช่องว่าง: พัก / ล็อกบอส / ไม่มีมอนเหมาะ
	if spec.is_empty() or q == null:
		var wait := board.cooldown_left(town, slot)
		var fill := Control.new()
		fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(fill)
		var msg := ""
		var sub := ""
		if wait > 0.0:
			_cooling[slot] = true
			msg = "พักบอร์ด"
			sub = "ใบใหม่จะออกในอีก %s นาที" % BountyBoard.cooldown_text(wait)
		elif slot == BountyBoard.BOSS_SLOT and not board.boss_unlocked(town):
			msg = "🔒 ใบล่าบอส"
			sub = "กิลด์จะออกให้คนที่ไว้ใจ — ส่งใบธรรมดาของเมืองนี้อีก %d ใบ" % board.boss_turnins_left(town)
		else:
			msg = "ยังไม่มีใบ"
			sub = "ไม่มีมอนเลเวลใกล้เคียงในบทนี้"
		var ml := UITheme.make_label(msg, 22, UITheme.TEXT_DIM)
		ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(ml)
		var sl := UITheme.make_label(sub, 14, UITheme.TEXT_DIM)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sl.custom_minimum_size.x = CARD_W - 30.0
		box.add_child(sl)
		var fill2 := Control.new()
		fill2.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(fill2)
		return p

	# ภาพ + ชื่อเป้าหมาย
	var mrow := HBoxContainer.new()
	mrow.add_theme_constant_override("separation", 10)
	box.add_child(mrow)
	# ★ รอบ 170 ★ ใบล่า/ใบบอส = รูปหน้ามอนในวงกลม (ตัดจากเฟรมแรกของท่า Idle แบบรูปหน้า NPC) · ใบเก็บของ = ไอคอนวัตถุดิบ
	mrow.add_child(_target_badge(spec, accent))
	var tcol := VBoxContainer.new()
	tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tcol.alignment = BoxContainer.ALIGNMENT_CENTER
	mrow.add_child(tcol)
	var m := GameData.get_monster_info(StringName(spec.get("monster", &"")))
	var title := UITheme.make_label(BountyBoard.short_label(spec), 18, UITheme.TEXT)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = CARD_W - 110.0
	tcol.add_child(title)
	var where := ""
	if m != null:
		where = "%s Lv %d" % [m.display_name, m.level]
	tcol.add_child(UITheme.make_label(where, 13, UITheme.TEXT_DIM))

	# ความคืบหน้า
	var need: int = q.steps()[0].need() if not q.steps().is_empty() else 1
	var have: int = qlog.count_of(qid) if (active or ready) else (PlayerState.inventory.count_of(StringName(spec.get("item", ""))) if kind == "collect" else 0)
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 8)
	box.add_child(prow)
	var bar := UITheme.make_bar(UITheme.GOOD if ready else accent, 12.0)
	bar.max_value = float(need)
	bar.value = float(mini(have, need))
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prow.add_child(bar)
	var state_txt := "%d / %d" % [mini(have, need), need]
	prow.add_child(UITheme.make_label(state_txt, 15, UITheme.GOOD if ready else UITheme.TEXT))
	var status := "ยังไม่ได้รับใบ" if not (active or ready) else ("ครบแล้ว — ส่งงานได้" if ready else "กำลังทำ")
	box.add_child(UITheme.make_label(status, 13, UITheme.GOOD if ready else (UITheme.GOLD_BRIGHT if active else UITheme.TEXT_DIM)))

	# รางวัล
	box.add_child(UITheme.separator())
	box.add_child(UITheme.make_label("รางวัล", 13, UITheme.TEXT_DIM))
	var rewards := HFlowContainer.new()
	rewards.add_theme_constant_override("h_separation", 6)
	rewards.add_theme_constant_override("v_separation", 4)
	box.add_child(rewards)
	if q.reward_exp > 0:
		rewards.add_child(_chip("EXP %s" % HUD._comma(q.reward_exp), UITheme.TEXT))
	if q.reward_zeny > 0:
		rewards.add_child(_chip("%s z" % HUD._comma(q.reward_zeny), Color("#ffe9a0")))
	if q.reward_item_id != &"":
		rewards.add_child(_item_chip(q.reward_item_id, q.reward_item_count))
	var ex := StringName(spec.get("extra_id", &""))
	if ex != &"":
		rewards.add_child(_item_chip(ex, int(spec.get("extra_count", 1))))

	var fill3 := Control.new()
	fill3.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(fill3)

	# ปุ่ม
	if ready:
		var b := UITheme.make_gold_button("ส่งงาน")
		b.name = "TurnIn"
		b.custom_minimum_size.y = 44
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_turn_in.bind(qid))
		box.add_child(b)
	elif active:
		var b2 := UITheme.make_button("ยกเลิกใบนี้")
		b2.name = "Abandon"
		b2.custom_minimum_size.y = 40
		b2.pressed.connect(_abandon.bind(qid))
		box.add_child(b2)
	else:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		box.add_child(row)
		var acc := UITheme.make_gold_button("รับใบนี้")
		acc.name = "Accept"
		acc.custom_minimum_size.y = 44
		acc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		acc.add_theme_font_size_override("font_size", 18)
		acc.pressed.connect(_accept.bind(qid))
		row.add_child(acc)
		var cost := board.reroll_cost(town)
		var rr := UITheme.make_button("เปลี่ยนใบ\n%s z" % HUD._comma(cost))
		rr.name = "Reroll"
		rr.custom_minimum_size = Vector2(96, 44)
		rr.add_theme_font_size_override("font_size", 12)
		rr.disabled = PlayerState.zeny < cost
		rr.pressed.connect(_reroll.bind(slot))
		row.add_child(rr)
	return p


## ★ รอบ 170 ★ ป้ายภาพเป้าหมาย: มอน = วงกลมขอบทองแบบรูปหน้า NPC · วัตถุดิบ = ไอคอนในกรอบสี่เหลี่ยม
const PORTRAIT_D := 76.0
static var _portrait_cache: Dictionary = {}


func _target_badge(spec: Dictionary, accent: Color) -> Control:
	var is_collect := String(spec.get("kind", "")) == "collect"
	if is_collect:
		var frame := PanelContainer.new()
		frame.add_theme_stylebox_override("panel", UITheme.panel_style(Color("#102725"), Color(accent, 0.6), 4, 1, 4.0))
		var art := TextureRect.new()
		art.custom_minimum_size = Vector2(64, 64)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var it := GameData.get_item(StringName(spec.get("item", "")))
		art.texture = it.icon if it != null else null
		frame.add_child(art)
		return frame
	var holder := Control.new()
	holder.name = "MonsterPortrait"
	holder.custom_minimum_size = Vector2(PORTRAIT_D, PORTRAIT_D)
	var ring := Panel.new()
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color("#173430")
	rs.border_color = accent
	rs.set_border_width_all(2)
	rs.set_corner_radius_all(int(PORTRAIT_D))
	ring.add_theme_stylebox_override("panel", rs)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(ring)
	var face := PetrolWidgets.circle_portrait(PORTRAIT_D, monster_portrait(StringName(spec.get("monster", &""))))
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(face)
	return holder


## ★ รอบ 170 ★ รูปหน้ามอน = เฟรมแรกของท่า Idle ตัดเป็นสี่เหลี่ยมจัตุรัส (แคชต่อ id)
##   ตัวสูง (สูง > กว้าง×1.15) หรือหัวแคบกว่าตัว (ช่วงบน 30% กว้าง < 70%) เช่นนางฟ้าน้ำ/ออร์ค/ลูนาติก = หัว+ไหล่ช่วงบน 50%
##   ตัวเตี้ย/กว้าง (โพริง หมาป่า กวาง) = ทั้งตัวพอดีวง
static func monster_portrait(monster_id: StringName) -> Texture2D:
	if _portrait_cache.has(monster_id):
		return _portrait_cache[monster_id]
	var tex: Texture2D = _make_portrait(monster_id)
	_portrait_cache[monster_id] = tex
	return tex


static func _make_portrait(monster_id: StringName) -> Texture2D:
	var m := GameData.get_monster(monster_id)
	if m == null or m.sprite_frames == null:
		return null
	var frames: SpriteFrames = m.sprite_frames
	var anim := &"Idle"
	if not frames.has_animation(anim):
		var names := frames.get_animation_names()
		if names.is_empty():
			return null
		anim = names[0]
	if frames.get_frame_count(anim) <= 0:
		return null
	var img := _frame_image(frames.get_frame_texture(anim, 0))
	if img == null or img.get_width() < 4 or img.get_height() < 4:
		return null
	# หาขอบตัวจริงบนภาพย่อ (alpha > 0.1 · ไม่นับขยะ alpha=1 ของบางชีท — กับดัก 122)
	var small := Image.new()
	small.copy_from(img)
	var sc := 128.0 / maxf(img.get_width(), img.get_height())
	var sw := maxi(4, int(img.get_width() * sc))
	var sh := maxi(4, int(img.get_height() * sc))
	small.resize(sw, sh, Image.INTERPOLATE_BILINEAR)
	var x0 := sw
	var y0 := sh
	var x1 := -1
	var y1 := -1
	for y in range(sh):
		for x in range(sw):
			if small.get_pixel(x, y).a > 0.1:
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
				y0 = mini(y0, y)
				y1 = maxi(y1, y)
	if x1 < 0:
		return null
	var bw := float(x1 - x0 + 1)
	var bh := float(y1 - y0 + 1)
	var side: float
	var cx: float
	var top: float
	# ความกว้างช่วงบน 30% ของตัว เทียบทั้งตัว (หัวแคบกว่าตัว = ท่าทางคน/ยืน)
	var bx0 := sw
	var bx1 := -1
	var sx := 0.0
	var n := 0
	for y in range(y0, y0 + maxi(1, int(bh * 0.3))):
		for x in range(x0, x1 + 1):
			if small.get_pixel(x, y).a > 0.1:
				bx0 = mini(bx0, x)
				bx1 = maxi(bx1, x)
				sx += x
				n += 1
	var band := float(bx1 - bx0 + 1) / bw if bx1 >= bx0 else 1.0
	if bh > bw * 1.15 or (bh > bw * 0.95 and band < 0.7):
		# ตัวสูง/หัวแคบ: หัว+ไหล่ แบบรูปหน้า NPC — กึ่งกลางแนวนอนตามช่วงบน (ไม่ให้อาวุธ/หางดึงเอียง)
		side = bh * 0.5
		cx = sx / n if n > 0 else (x0 + bw * 0.5)
		top = y0 - side * 0.05
	else:
		side = maxf(bw, bh) * 1.08
		cx = x0 + bw * 0.5
		top = y0 + bh * 0.5 - side * 0.5
	var inv := 1.0 / sc
	var rect := Rect2i(int((cx - side * 0.5) * inv), int(top * inv), int(side * inv), int(side * inv))
	# ขยายภาพให้มีขอบใส ๆ ถ้าช่องตัดเกินขอบภาพ
	var out := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var src := img
	if src.get_format() != Image.FORMAT_RGBA8:
		src.convert(Image.FORMAT_RGBA8)
	var clip := rect.intersection(Rect2i(Vector2i.ZERO, src.get_size()))
	if clip.size.x < 2 or clip.size.y < 2:
		return null
	out.blit_rect(src, clip, clip.position - rect.position)
	var want := int(PORTRAIT_D * 2.0)
	out.resize(want, want, Image.INTERPOLATE_LANCZOS)
	out.generate_mipmaps()
	return ImageTexture.create_from_image(out)


## ภาพของเฟรม (รองรับ AtlasTexture บนชีทที่บีบอัด — ต้องคลายก่อนตัด · กับดัก 114)
static func _frame_image(t: Texture2D) -> Image:
	if t == null:
		return null
	if t is AtlasTexture:
		var at := t as AtlasTexture
		if at.atlas == null:
			return null
		var sheet: Image = at.atlas.get_image()
		if sheet == null:
			return null
		if sheet.is_compressed():
			sheet = sheet.duplicate()
			sheet.decompress()
		var r := Rect2i(at.region).intersection(Rect2i(Vector2i.ZERO, sheet.get_size()))
		if r.size.x < 2 or r.size.y < 2:
			return null
		return sheet.get_region(r)
	var img: Image = t.get_image()
	if img == null:
		return null
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	return img


func _chip(text: String, color: Color) -> Control:
	var pc := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(color, 0.1)
	s.border_color = Color(color, 0.5)
	s.set_border_width_all(1)
	s.set_corner_radius_all(9)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 1
	s.content_margin_bottom = 1
	pc.add_theme_stylebox_override("panel", s)
	pc.add_child(UITheme.make_label(text, 13, color))
	return pc


func _item_chip(id: StringName, n: int) -> Control:
	var pc := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#173430cc")
	s.border_color = UITheme.BORDER
	s.set_border_width_all(1)
	s.set_corner_radius_all(9)
	s.content_margin_left = 4
	s.content_margin_right = 8
	pc.add_theme_stylebox_override("panel", s)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	pc.add_child(row)
	var it := GameData.get_item(id)
	var ic := TextureRect.new()
	ic.custom_minimum_size = Vector2(22, 22)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ic.texture = it.icon if it != null else null
	row.add_child(ic)
	row.add_child(UITheme.make_label("%s ×%d" % [GameData.item_name(id), n], 13, UITheme.TEXT))
	pc.tooltip_text = it.description if it != null else ""
	return pc


# =========================================================
# ปุ่ม
# =========================================================
func _accept(qid: StringName) -> void:
	var q := GameData.get_quest(qid)
	if q != null and PlayerState.quests.accept(qid):
		Events.say("[รับใบประกาศ] %s" % q.title)
	refresh()


func _turn_in(qid: StringName) -> void:
	var board: BountyBoard = PlayerState.bounties
	if not board.can_receive_extra(qid):
		Events.say("กระเป๋าเต็ม — เก็บของให้ว่างก่อนแล้วค่อยมาส่งใบประกาศ")
		return
	if PlayerState.turn_in_quest(qid):
		Events.say("[กิลด์] แต้มกิลด์ %d · ขั้น %s" % [board.points, board.rank_letter()])
	refresh()


func _abandon(qid: StringName) -> void:
	if not await UI.ask("ยกเลิกใบประกาศ", "ยกเลิกใบนี้แล้วความคืบหน้าจะหาย และบอร์ดจะออกใบใหม่แทน", "ยืนยันยกเลิก", "ไว้ก่อน"):
		return
	PlayerState.bounties.abandon(qid)
	Events.say("ยกเลิกใบประกาศแล้ว")
	refresh()


func _reroll(slot: int) -> void:
	var board: BountyBoard = PlayerState.bounties
	var cost := board.reroll_cost(town)
	if not PlayerState.spend_zeny(cost):
		Events.say("เงินไม่พอ — เปลี่ยนใบต้องใช้ %s z" % HUD._comma(cost))
		return
	board.reroll(town, slot)
	Events.say("บอร์ดออกใบใหม่แล้ว")
	refresh()


# =========================================================
# วางหน้าต่าง
# =========================================================
func fit_to_content() -> void:
	_place()
	await get_tree().process_frame
	if is_instance_valid(self) and visible:
		_place()


func _place() -> void:
	if not is_inside_tree():
		return
	var vp := get_viewport_rect().size
	reset_size()
	size = Vector2(minf(WIN_SIZE.x, vp.x - 40.0), minf(WIN_SIZE.y, vp.y - 60.0))
	position = ((vp - size) * 0.5).floor()


func shell_hints() -> Array:
	return [["Esc", "ปิด"]]
