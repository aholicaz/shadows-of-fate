## CardAlbumWindow — อัลบั้มการ์ดมอนสเตอร์ (กด V)
##
## แท็บ "อัลบั้ม"  : โชว์การ์ดทุกใบในเกม ใบที่ยังไม่ได้จะเป็นเงาดำ
## แท็บ "จัดการ"   : ใส่การ์ดลงอุปกรณ์ / ถอดการ์ดออก
class_name CardAlbumWindow
extends GameWindow

## ★ รอบ 102 ★ แถวละ 7 ใบ (เดิม 5 → เหลือที่ว่างครึ่งหน้า)
const COLUMNS := 7
## ขนาดขั้นต่ำ — ขนาดจริงคำนวณจากความกว้างที่มีใน _fit_grid() (สัดส่วนใบการ์ดคงเดิม)
const MINI_SIZE := Vector2(70, 81)
## ★ รอบ 102 (รอบสอง) ★ ใบการ์ด "ยืดเต็มระยะ" ชิดแผงข้าง ไม่เหลือที่โล่งครึ่งหน้า
const MINI_MIN := 70.0
const MINI_MAX := 150.0
const CARD_RATIO := 90.0 / 78.0     # สูง ÷ กว้าง ของใบการ์ด (คงสัดส่วนเดิมไว้)
const GRID_SEP := 6
const SCROLLBAR_ROOM := 16.0

var _tab_album: Button
var _tab_manage: Button
var _tab_bonus: Button            # ★ รอบ 154 ★ โบนัสสมุด
var _bonus_page: VBoxContainer
var _bonus_list: VBoxContainer
var _album_total: Label
var _deposit_box: VBoxContainer
var _mode_bonus := false
var _album_page: HBoxContainer
var _manage_page: VBoxContainer

var _grid: GridContainer
var _grid_scroll: ScrollContainer
var _cell := Vector2.ZERO
var _card_view: CardView
var _progress: Label
var _socket_box: VBoxContainer
var _manage_list: VBoxContainer

var _selected: StringName = &""
var _mode_album := true


func _ready() -> void:
	window_title = "อัลบั้มการ์ดมอนสเตอร์"
	super._ready()
	custom_minimum_size = Vector2(640, 0)
	Events.inventory_changed.connect(refresh)
	Events.equipment_changed.connect(refresh)
	Events.stats_changed.connect(refresh)   # ★ รอบ 154 ★ ฝังการ์ดแล้วโบนัสเปลี่ยน


func _build_content() -> void:
	# ---------- แท็บ ----------
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	content.add_child(tabs)

	_tab_album = UITheme.make_button("อัลบั้ม", 110)
	_tab_album.pressed.connect(func(): _set_mode(true))
	tabs.add_child(_tab_album)

	_tab_manage = UITheme.make_button("จัดการการ์ด", 130)
	_tab_manage.pressed.connect(func(): _set_mode(false))
	tabs.add_child(_tab_manage)

	_tab_bonus = UITheme.make_button("โบนัสสมุด", 120)   # ★ รอบ 154 ★
	_tab_bonus.pressed.connect(_set_bonus_mode)
	tabs.add_child(_tab_bonus)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(spacer)

	_progress = UITheme.make_label("", 14, UITheme.ACCENT)
	tabs.add_child(_progress)

	# ★ รอบ 154 ★ แถบรวมโบนัสจากการ์ดที่ฝังเข้าสมุด
	_album_total = UITheme.make_label("", 13, UITheme.TEXT)
	_album_total.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_album_total)

	content.add_child(UITheme.separator())

	# ---------- หน้าอัลบั้ม ----------
	# ★ รอบ 102 ★ กระจายเต็มกรอบ (เดิมกองมุมซ้าย เหลือที่ว่างครึ่งหน้า)
	_album_page = HBoxContainer.new()
	_album_page.add_theme_constant_override("separation", 14)
	_album_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_album_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_album_page)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, 330)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_album_page.add_child(scroll)
	_grid_scroll = scroll
	scroll.resized.connect(_fit_grid)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", GRID_SEP)
	_grid.add_theme_constant_override("v_separation", GRID_SEP)
	# ★ ใบการ์ดขนาดคงที่ ★ ถ้า EXPAND_FILL ที่ว่างจะไปกองข้างขวาข้างเดียว → กลางไว้ดีกว่า
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.add_child(_grid)

	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 6)
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_album_page.add_child(side)

	_card_view = CardView.new()
	side.add_child(_card_view)

	_deposit_box = VBoxContainer.new()   # ★ รอบ 154 ★ ฝังเข้าสมุด
	_deposit_box.add_theme_constant_override("separation", 4)
	side.add_child(_deposit_box)

	_socket_box = VBoxContainer.new()
	_socket_box.add_theme_constant_override("separation", 4)
	side.add_child(_socket_box)

	# ---------- หน้าจัดการ ----------
	_manage_page = VBoxContainer.new()
	_manage_page.add_theme_constant_override("separation", 6)
	_manage_page.hide()
	content.add_child(_manage_page)

	_manage_page.add_child(UITheme.make_label(
		"อุปกรณ์ที่ใส่การ์ดอยู่ — กด [ถอด] เพื่อเอาการ์ดคืนเข้ากระเป๋า", 12, UITheme.TEXT_DIM))

	var mscroll := ScrollContainer.new()
	mscroll.custom_minimum_size.y = 330
	mscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_manage_page.add_child(mscroll)

	_manage_list = VBoxContainer.new()
	_manage_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_manage_list.add_theme_constant_override("separation", 4)
	mscroll.add_child(_manage_list)

	# ---------- ★ รอบ 154 ★ หน้าโบนัสสมุด ----------
	_bonus_page = VBoxContainer.new()
	_bonus_page.add_theme_constant_override("separation", 6)
	_bonus_page.hide()
	content.add_child(_bonus_page)
	_bonus_page.add_child(UITheme.make_label(
		"ฝังการ์ดเข้าสมุด = ใช้การ์ด 1 ใบแลกโบนัสถาวร (ใบละ 1 ครั้ง) · เลือกการ์ดในแท็บอัลบั้มแล้วกด «ฝังเข้าสมุด»", 12, UITheme.TEXT_DIM))
	var bscroll := ScrollContainer.new()
	bscroll.custom_minimum_size.y = 330
	bscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bonus_page.add_child(bscroll)
	_bonus_list = VBoxContainer.new()
	_bonus_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bonus_list.add_theme_constant_override("separation", 2)
	bscroll.add_child(_bonus_list)


## ★★ รอบ 102 (รอบสอง) — ใบการ์ดยืดเต็มความกว้าง ★★
## คิดขนาดใบจากความกว้างจริงของกล่องเลื่อน แล้วคูณสัดส่วนเดิมเป็นความสูง
## (ภาพในใบใช้ PRESET_FULL_RECT อยู่แล้ว → โตตามช่องเอง ไม่ต้องแตะที่อื่น)
func _fit_grid() -> void:
	if _grid == null or _grid_scroll == null:
		return
	var avail: float = _grid_scroll.size.x - SCROLLBAR_ROOM
	if avail <= 0.0:
		return
	var w: float = floorf((avail - float(COLUMNS - 1) * float(GRID_SEP)) / float(COLUMNS))
	w = clampf(w, MINI_MIN, MINI_MAX)
	var cell := Vector2(w, floorf(w * CARD_RATIO))
	if _cell.distance_to(cell) < 0.5:
		return
	_cell = cell
	_apply_cell()


## เอาขนาดที่คิดได้ไปใส่ทุกใบ (แต่ละใบ = VBox { ปุ่มรูปการ์ด, ป้ายชื่อ })
func _apply_cell() -> void:
	if _grid == null or _cell == Vector2.ZERO:
		return
	for c in _grid.get_children():
		var box := c as VBoxContainer
		if box == null or box.get_child_count() < 1:
			continue
		var btn := box.get_child(0) as Control
		if btn != null:
			btn.custom_minimum_size = _cell
		if box.get_child_count() >= 2:
			var name_label := box.get_child(1) as Control
			if name_label != null:
				name_label.custom_minimum_size.x = _cell.x


func _set_mode(album: bool) -> void:
	_mode_album = album
	_mode_bonus = false
	_album_page.visible = album
	_manage_page.visible = not album
	_bonus_page.visible = false
	refresh()


func _set_bonus_mode() -> void:   # ★ รอบ 154 ★
	_mode_album = false
	_mode_bonus = true
	_album_page.visible = false
	_manage_page.visible = false
	_bonus_page.visible = true
	refresh()


# =========================================================
func refresh() -> void:
	if _grid == null or not visible:
		return

	var all := GameData.all_cards()
	_progress.text = "เก็บได้ %d / %d ใบ · ฝังแล้ว %d" % [PlayerState.cards_collected(), all.size(), PlayerState.card_album.size()]
	_tab_album.add_theme_color_override("font_color", UITheme.ACCENT if _mode_album else UITheme.TEXT_DIM)
	_tab_manage.add_theme_color_override("font_color", UITheme.ACCENT if (not _mode_album and not _mode_bonus) else UITheme.TEXT_DIM)
	_tab_bonus.add_theme_color_override("font_color", UITheme.ACCENT if _mode_bonus else UITheme.TEXT_DIM)
	var total_text := CardAlbum.describe(CardAlbum.total(PlayerState.card_album))
	_album_total.text = "โบนัสสมุด: " + (total_text if total_text != "" else "ยังไม่ได้ฝังการ์ดใบไหน")
	_album_total.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT if total_text != "" else UITheme.TEXT_DIM)

	if _mode_bonus:
		_build_bonus_list(all)
	elif _mode_album:
		_build_album(all)
	else:
		_build_manage()


func _build_album(all: Array[CardData]) -> void:
	GameWindow.clear_container(_grid)

	if all.is_empty():
		_grid.add_child(UITheme.make_label("ยังไม่มีการ์ดในเกม", 13, UITheme.TEXT_DIM))
		return

	for card in all:
		var owned := PlayerState.card_known(card.id)   # ★ รอบ 154 ★ ฝังแล้วก็ยังโชว์ในสมุด

		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)

		var btn := Button.new()
		btn.custom_minimum_size = MINI_SIZE
		btn.focus_mode = Control.FOCUS_NONE
		btn.tooltip_text = card.display_name if owned else "ยังไม่เก็บได้"
		btn.modulate = Color.WHITE if owned else Color(0.22, 0.24, 0.32)

		var highlight := card.id == _selected
		btn.add_theme_stylebox_override("normal", UITheme.slot_style(highlight))
		btn.add_theme_stylebox_override("hover", UITheme.slot_style(true))
		btn.add_theme_stylebox_override("pressed", UITheme.slot_style(true))

		var cid := card.id
		btn.pressed.connect(func(): _select(cid))
		cell.add_child(btn)
		# รูปการ์ดจัดกึ่งกลางช่องเสมอ
		var art: TextureRect = UITheme.make_slot_icon(btn, 4.0)[0]
		art.texture = CardView.card_texture(card)
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		if PlayerState.card_deposited(card.id):   # ★ รอบ 154 ★ ป้าย «ฝังแล้ว»
			btn.add_child(_seal_badge())

		var name_label := UITheme.make_label(
			card.display_name.replace("การ์ด", "").strip_edges() if owned else "???",
			10, card.rarity_color() if owned else UITheme.TEXT_DIM)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.clip_text = true
		name_label.custom_minimum_size.x = MINI_SIZE.x
		cell.add_child(name_label)

		_grid.add_child(cell)

	# ★ refresh() สร้างใบใหม่ทุกครั้ง → ต้องเอาขนาดที่คิดไว้มาใส่ซ้ำ ไม่งั้นกลับไปเป็นขนาดขั้นต่ำ
	_apply_cell()
	_update_side()


func _select(card_id: StringName) -> void:
	_selected = card_id
	refresh()


func _update_side() -> void:
	var card := GameData.get_card(_selected)
	var owned := card != null and PlayerState.card_known(card.id)
	_card_view.show_card(card, owned)

	GameWindow.clear_container(_socket_box)
	GameWindow.clear_container(_deposit_box)
	if card == null or not owned:
		return
	_build_deposit(card)

	var in_bag := PlayerState.inventory.count_of(card.id)
	if in_bag <= 0:
		_socket_box.add_child(UITheme.make_label("(ใบนี้ใส่ในอุปกรณ์อยู่แล้ว)", 11, UITheme.TEXT_DIM))
		return

	var targets := PlayerState.sockets_for_card(card.id)
	if targets.is_empty():
		_socket_box.add_child(UITheme.make_label(
			"ไม่มี%sที่มีช่องว่าง" % card.slot_name(), 11, UITheme.BAD))
		return

	_socket_box.add_child(UITheme.make_label("ใส่ลงใน:", 12, UITheme.TEXT_DIM))
	for t in targets:
		var btn := UITheme.make_button(t.label)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var inst: ItemInstance = t.instance
		var cid := card.id
		btn.pressed.connect(func(): PlayerState.socket_card(cid, inst))
		_socket_box.add_child(btn)


# =========================================================
func _build_manage() -> void:
	GameWindow.clear_container(_manage_list)
	var found := false

	for slot in PlayerState.equipment.slots.keys():
		var inst: ItemInstance = PlayerState.equipment.get_item(slot)
		if inst != null and not inst.cards.is_empty():
			_add_manage_row(inst, "%s (สวมอยู่)" % Equipment.SLOT_NAMES[slot])
			found = true

	for i in range(PlayerState.inventory.size):
		var inst2 := PlayerState.inventory.get_slot(i)
		if inst2 != null and not inst2.cards.is_empty():
			_add_manage_row(inst2, "ในกระเป๋า")
			found = true

	if not found:
		_manage_list.add_child(UITheme.make_label(
			"ยังไม่ได้ใส่การ์ดในอุปกรณ์ชิ้นไหนเลย\nไปที่แท็บอัลบั้ม เลือกการ์ดที่มี แล้วกดปุ่มใส่ได้เลย",
			13, UITheme.TEXT_DIM))


func _add_manage_row(inst: ItemInstance, where: String) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.PANEL_LIGHT, UITheme.BORDER, 4))
	_manage_list.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)

	var head := HBoxContainer.new()
	var title := UITheme.make_label(inst.display_name(), 14, UITheme.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(UITheme.make_label(where, 11, UITheme.TEXT_DIM))
	box.add_child(head)

	for i in range(inst.cards.size()):
		var card := GameData.get_card(inst.cards[i])
		if card == null:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var icon := TextureRect.new()
		icon.texture = CardView.card_texture(card)
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)

		var info := UITheme.make_label(
			"%s — %s" % [card.display_name, card.describe().replace("\n", ", ")],
			12, UITheme.TEXT)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(info)

		var btn := UITheme.make_button("ถอด", 60)
		var target := inst
		var index := i
		btn.pressed.connect(func(): PlayerState.unsocket_card(target, index))
		row.add_child(btn)

		box.add_child(row)


# =========================================================
# ★★ รอบ 154 ★★ ฝังการ์ดเข้าสมุด
# =========================================================
func _seal_badge() -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITheme.ACCENT
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.position = Vector2(-2, -4)
	var l := UITheme.make_label("ฝังแล้ว", 9, UITheme.BG)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


func _build_deposit(card: CardData) -> void:
	var bonus := CardAlbum.bonus_of(card.id)
	if bonus.is_empty():
		return
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel_style(Color("#1a2f23"), UITheme.ACCENT, 5))
	_deposit_box.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	box.add_child(UITheme.make_label("★ ฝังเข้าสมุด (ถาวร · ใบละ 1 ครั้ง)", 11, UITheme.ACCENT))
	box.add_child(UITheme.make_label(CardAlbum.describe(bonus), 15, UITheme.GOLD_BRIGHT))
	if PlayerState.card_deposited(card.id):
		box.add_child(UITheme.make_label("✓ ฝังแล้ว — ได้รับโบนัสนี้อยู่", 11, UITheme.GOOD))
		return
	var in_bag := PlayerState.inventory.count_of(card.id)
	var btn := UITheme.make_gold_button("ฝังเข้าสมุด (ใช้การ์ด 1 ใบ)")
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.disabled = in_bag <= 0
	if in_bag <= 0:
		btn.tooltip_text = "ต้องมีการ์ดใบนี้ในกระเป๋า (ใบที่ใส่ในอุปกรณ์ต้องถอดก่อน)"
	btn.pressed.connect(_on_deposit_pressed.bind(card.id))
	_deposit_box.add_child(btn)


func _on_deposit_pressed(card_id: StringName) -> void:
	var card := GameData.get_card(card_id)
	if card == null:
		return
	var left := PlayerState.inventory.count_of(card_id) - 1
	var ok: bool = await UI.ask("ฝังเข้าสมุด",
		"ฝัง%sเข้าสมุด?\nการ์ด 1 ใบจะหายไป แลกกับ %s ถาวร\n(เหลือในกระเป๋า %d ใบ)" % [card.display_name, CardAlbum.describe(CardAlbum.bonus_of(card_id)), left],
		"ฝังเลย", "ยกเลิก")
	if not ok:
		return
	var res := PlayerState.deposit_card(card_id)
	if not bool(res.get("ok", false)):
		Events.say(String(res.get("reason", "ฝังไม่ได้")))
	elif Game.sfx != null:
		Game.sfx.play_first(["card_socket", "craft_success", "refine_success"])
	refresh()


func _build_bonus_list(all: Array[CardData]) -> void:
	GameWindow.clear_container(_bonus_list)
	# ★ รอบ 158 ★ โบนัสครบชุดต่อบท — ความคืบหน้า + โบนัส (ทองเมื่อครบ)
	_bonus_list.add_child(UITheme.make_label("★ โบนัสฝังครบชุดบท (รวมการ์ดบอส)", 14, UITheme.GOLD_BRIGHT))
	for s: Dictionary in CardAlbum.CHAPTER_SETS:
		var have := CardAlbum.chapter_count(s, PlayerState.card_album)
		var need := (s["cards"] as Array).size()
		var done := have >= need
		var srow := HBoxContainer.new()
		srow.add_theme_constant_override("separation", 8)
		var sn := UITheme.make_label("ครบชุด%s  %d/%d" % [String(s["name"]), have, need], 13, UITheme.GOLD_BRIGHT if done else UITheme.TEXT)
		sn.custom_minimum_size.x = 250
		srow.add_child(sn)
		var sb := UITheme.make_label(CardAlbum.describe(s["bonus"]), 13, UITheme.GOLD_BRIGHT if done else UITheme.TEXT_DIM)
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		srow.add_child(sb)
		var ss := UITheme.make_label("✓ ได้แล้ว" if done else "ยังไม่ครบ", 12, UITheme.GOOD if done else UITheme.TEXT_DIM)
		ss.custom_minimum_size.x = 84
		srow.add_child(ss)
		var spad := Control.new()
		spad.custom_minimum_size.x = 14
		srow.add_child(spad)
		_bonus_list.add_child(srow)
	var sep := HSeparator.new()
	_bonus_list.add_child(sep)
	for card in all:
		var known := PlayerState.card_known(card.id)
		var deposited := PlayerState.card_deposited(card.id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var nm := UITheme.make_label(card.display_name if known else "???", 13, card.rarity_color() if known else UITheme.TEXT_DIM)
		nm.custom_minimum_size.x = 250
		nm.clip_text = true
		row.add_child(nm)
		var bonus_text := CardAlbum.describe(CardAlbum.bonus_of(card.id)) if known else "???"
		var bl := UITheme.make_label(bonus_text, 13, UITheme.GOLD_BRIGHT if deposited else UITheme.TEXT)
		bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bl)
		var state := "✓ ฝังแล้ว" if deposited else ("มี %d ใบ" % PlayerState.inventory.count_of(card.id) if PlayerState.inventory.count_of(card.id) > 0 else ("เคยได้" if known else "ยังไม่เจอ"))
		var st := UITheme.make_label(state, 12, UITheme.GOOD if deposited else UITheme.TEXT_DIM)
		st.custom_minimum_size.x = 84
		row.add_child(st)
		var pad := Control.new()
		pad.custom_minimum_size.x = 14   # เว้นที่ให้แถบเลื่อน
		row.add_child(pad)
		_bonus_list.add_child(row)
