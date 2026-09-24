## GuildRankWindow — ★ รอบ 158 ★ หน้า «ขั้นกิลด์นักผจญภัย»
##
## บน = ขั้นปัจจุบัน (ไอคอนใหญ่ · แต้ม · หลอดไปขั้นถัดไป · สิทธิ์ที่ใช้อยู่ตอนนี้)
## ล่าง = การ์ด 7 ขั้น F→S เห็นทันทีว่าแต่ละขั้นได้อะไร (ผ่านแล้ว = ขอบทอง · ขั้นปัจจุบัน = เรืองแสง · ยังไม่ถึง = จาง)
## ตัวเลขสิทธิ์อยู่ที่ BountyBoard.RANK_PERKS / RANK_STAT_POINTS · ไอคอน Sprites/ui/guild_rank/painted/rank_<ตัวอักษร>.png
## เปิดจาก Events.guild_rank_opened (เมนู «สถานะกิลด์» ที่บอร์ดใบประกาศ)
class_name GuildRankWindow
extends GameWindow

const ICON_DIR := "res://Sprites/ui/guild_rank/painted/"
const CARD_SIZE := Vector2(132, 318)
const RANK_COLORS := [Color("#d09a62"), Color("#c3ccd6"), Color("#e8f1fb"), Color("#ffd873"), Color("#7fc4ff"), Color("#ff7f86"), Color("#e6b8ff")]

var _big_icon: TextureRect
var _head_name: Label
var _head_points: Label
var _rank_bar: ProgressBar
var _bar_text: Label
var _perk_now: Label
var _cards_row: HBoxContainer
var _icon_cache: Dictionary = {}


func _init() -> void:
	window_title = "ขั้นกิลด์นักผจญภัย"


static func rank_icon(letter: String) -> Texture2D:
	var path := ICON_DIR + "rank_%s.png" % letter.to_lower()
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _icon(letter: String) -> Texture2D:
	if not _icon_cache.has(letter):
		_icon_cache[letter] = rank_icon(letter)
	return _icon_cache[letter]


func _build_content() -> void:
	# ---------- หัว: ขั้นปัจจุบัน ----------
	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", UITheme.panel_style(Color(UITheme.PANEL, 0.95), UITheme.ACCENT, 6, 1, 10.0))
	content.add_child(head)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	head.add_child(hbox)
	_big_icon = TextureRect.new()
	_big_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_big_icon.custom_minimum_size = Vector2(112, 112)
	_big_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_big_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(_big_icon)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)
	_head_name = UITheme.make_label("", 24, UITheme.GOLD_BRIGHT)
	info.add_child(_head_name)
	_head_points = UITheme.make_label("", 14, UITheme.TEXT)
	info.add_child(_head_points)
	var bar_box := HBoxContainer.new()
	bar_box.add_theme_constant_override("separation", 10)
	info.add_child(bar_box)
	_rank_bar = ProgressBar.new()
	_rank_bar.custom_minimum_size = Vector2(420, 16)
	_rank_bar.show_percentage = false
	_rank_bar.add_theme_stylebox_override("background", UITheme.bar_bg_style())
	_rank_bar.add_theme_stylebox_override("fill", UITheme.bar_fill_style(UITheme.ACCENT))
	bar_box.add_child(_rank_bar)
	_bar_text = UITheme.make_label("", 13, UITheme.TEXT_DIM)
	bar_box.add_child(_bar_text)
	_perk_now = UITheme.make_label("", 14, UITheme.GOOD)
	_perk_now.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_perk_now.custom_minimum_size.x = 760
	info.add_child(_perk_now)

	# ---------- การ์ด 7 ขั้น ----------
	_cards_row = HBoxContainer.new()
	_cards_row.add_theme_constant_override("separation", 8)
	content.add_child(_cards_row)

	var foot := UITheme.make_label("ส่วนลดใช้กับ: ซื้อของร้าน · ค่าวาร์ป · ค่าขอพร · ค่ารักษา · ค่าย่อยการ์ด · ค่าตีบวก   |   แต้มกิลด์ได้จากใบประกาศล่า (ใบธรรมดา +%d · ใบบอส +%d)" % [BountyBoard.POINTS_NORMAL, BountyBoard.POINTS_BOSS], 12, UITheme.TEXT_DIM)
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.custom_minimum_size.x = 960
	content.add_child(foot)


func refresh() -> void:
	if _cards_row == null or not is_visible_in_tree():
		return
	var board: BountyBoard = PlayerState.bounties
	if board == null:
		return
	var idx := board.rank_index()
	var letter := board.rank_letter()
	_big_icon.texture = _icon(letter)
	_head_name.text = "ขั้น %s — «%s»" % [letter, board.rank_title()]
	_head_name.add_theme_color_override("font_color", RANK_COLORS[idx])
	_head_points.text = "แต้มกิลด์ %d · ส่งใบประกาศแล้ว %d ใบ" % [board.points, board.total_turned_in]
	var next := board.next_rank_points()
	if next > 0:
		var lo := int(BountyBoard.RANKS[idx][1])
		_rank_bar.max_value = maxf(1.0, float(next - lo))
		_rank_bar.value = float(board.points - lo)
		_bar_text.text = "อีก %d แต้ม → ขั้น %s" % [next - board.points, String(BountyBoard.RANKS[idx + 1][0])]
	else:
		_rank_bar.max_value = 1.0
		_rank_bar.value = 1.0
		_bar_text.text = "ขั้นสูงสุดแล้ว"
	_perk_now.text = "สิทธิ์ตอนนี้: ส่วนลด %d%% · พรแห่งธอร์นานขึ้น +%s · แต้มสเตตัสจากกิลด์รวม +%d" % [
		BountyBoard.discount_of(idx), BountyBoard.bless_bonus_text(idx), BountyBoard.stat_points_of(idx)]

	GameWindow.clear_container(_cards_row)
	for i in range(BountyBoard.RANKS.size()):
		_cards_row.add_child(_rank_card(i, idx, board.points))


func _rank_card(i: int, current: int, points: int) -> Control:
	var r: Array = BountyBoard.RANKS[i]
	var col: Color = RANK_COLORS[i]
	var reached := i <= current
	var is_now := i == current
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	var bg := Color(UITheme.PANEL_LIGHT, 0.95) if is_now else Color(UITheme.PANEL, 0.9)
	var border := col if is_now else (UITheme.ACCENT if reached else UITheme.BORDER)
	card.add_theme_stylebox_override("panel", UITheme.panel_style(bg, border, 8, 3 if is_now else 1, 8.0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)

	var icon := TextureRect.new()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.custom_minimum_size = Vector2(0, 92)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _icon(String(r[0]))
	if not reached:
		icon.modulate = Color(0.55, 0.55, 0.6, 0.75)
	box.add_child(icon)

	var name_l := UITheme.make_label("ขั้น %s" % String(r[0]), 18, col if reached else UITheme.TEXT_DIM)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_l)
	var title := UITheme.make_label(String(r[2]), 12, UITheme.TEXT if reached else UITheme.TEXT_DIM)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var need := UITheme.make_label("%d แต้ม" % int(r[1]), 12, UITheme.TEXT_DIM)
	need.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(need)
	box.add_child(HSeparator.new())

	var perk_color := UITheme.GOOD if reached else UITheme.TEXT
	for t in [
			"ส่วนลด −%d%%" % BountyBoard.discount_of(i),
			"พรธอร์ +%s" % BountyBoard.bless_bonus_text(i),
			("แต้มสเตตัส +%d" % BountyBoard.RANK_STAT_POINTS) if i > 0 else "แต้มสเตตัส —",
		]:
		var l := UITheme.make_label(t, 13, perk_color)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var state_text := "◆ ขั้นปัจจุบัน" if is_now else ("✓ ผ่านแล้ว" if reached else "อีก %d แต้ม" % (int(r[1]) - points))
	var st := UITheme.make_label(state_text, 13, col if is_now else (UITheme.GOOD if reached else UITheme.TEXT_DIM))
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(st)
	return card
