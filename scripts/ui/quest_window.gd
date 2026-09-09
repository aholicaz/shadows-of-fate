## QuestWindow — สมุดเควส (กด U)
## โชว์เควสที่กำลังทำ ความคืบหน้า และเควสที่ทำเสร็จแล้ว
class_name QuestWindow
extends GameWindow

## ★ รอบ 102 ★ เว้นขอบซ้าย-ขวาของหน้าเควส (เดิมข้อความชิดขอบกรอบ)
const PAD_X := 18
## สีของเควสที่ทำเสร็จแล้ว — เทาเดิม (#81958a) จมพื้นจนอ่านแทบไม่ออก จึงยกให้สว่างขึ้น
const DONE_DIM := Color("#a8bcb0")

var _list: VBoxContainer
var _empty: Label
var _empty_pad: Control


func _ready() -> void:
	window_title = "สมุดเควส"
	super._ready()
	custom_minimum_size = Vector2(420, 260)
	Events.quest_changed.connect(refresh)
	Events.stats_changed.connect(refresh)


func _build_content() -> void:
	# ★ รอบ 102 ★ ตัวหนังสือใหญ่ขึ้นทั้งหน้า + เว้นขอบซ้าย-ขวา (เดิมชิดขอบจนอ่านยาก)
	var head_pad := MarginContainer.new()
	head_pad.add_theme_constant_override("margin_left", PAD_X)
	head_pad.add_theme_constant_override("margin_right", PAD_X)
	content.add_child(head_pad)
	head_pad.add_child(UITheme.make_label(
		"คุยกับ NPC ที่มีเครื่องหมาย ! เพื่อรับเควส  ·  ? = เอาไปส่งได้แล้ว",
		14, UITheme.TEXT_DIM))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 300
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var list_pad := MarginContainer.new()
	list_pad.add_theme_constant_override("margin_left", PAD_X)
	list_pad.add_theme_constant_override("margin_right", PAD_X)
	list_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_pad)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_pad.add_child(_list)

	# ★ รอบ 102 ★ ป้าย "ยังไม่มีเควส"
	# · เดิมอยู่ "หลัง" กล่องเลื่อนที่กินพื้นที่เต็ม → ถูกดันไปอยู่ก้นหน้าต่าง
	# · ★ ห้ามเอาไปไว้ใน _list ★ เพราะ refresh() ล้าง _list ทุกครั้ง (ป้ายจะโดน free ตามไปด้วย)
	#   จึงวางไว้ใน content แล้วเลื่อนขึ้นไปอยู่ใต้หัวเรื่องแทน
	_empty = UITheme.make_label("ยังไม่มีเควส — ลองไปคุยกับ NPC ในเมืองดู", 15, UITheme.TEXT_DIM)
	var empty_pad := MarginContainer.new()
	empty_pad.add_theme_constant_override("margin_left", PAD_X)
	empty_pad.add_theme_constant_override("margin_top", 10)
	empty_pad.add_child(_empty)
	content.add_child(empty_pad)
	content.move_child(empty_pad, 1)
	_empty_pad = empty_pad


func refresh() -> void:
	if _list == null:
		return
	GameWindow.clear_container(_list)

	var log := PlayerState.quests
	if log == null:
		return

	var shown := 0

	# ---------- กำลังทำ ----------
	for qid in log.active:
		var q := GameData.get_quest(qid)
		if q == null:
			continue
		shown += 1
		_add_row(q, log.count_of(qid), log.is_ready(qid), false)

	# ---------- ทำเสร็จแล้ว ----------
	if not log.completed.is_empty():
		_list.add_child(UITheme.separator())
		_list.add_child(UITheme.make_label("เควสที่ทำเสร็จแล้ว", 12, UITheme.TEXT_DIM))
		for qid in log.completed:
			var q := GameData.get_quest(qid)
			if q == null:
				continue
			shown += 1
			_add_row(q, q.kill_count, false, true)

	_empty.visible = shown == 0
	if _empty_pad != null:
		_empty_pad.visible = shown == 0


func _add_row(q: QuestData, progress: int, ready: bool, done: bool) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.slot_style(ready))
	_list.add_child(panel)

	# ★ เว้นขอบในกล่องเควสด้วย ★ เดิมข้อความแปะติดเส้นกรอบเลย
	var pad := MarginContainer.new()
	for side in ["margin_left", "margin_right"]:
		pad.add_theme_constant_override(side, 14)
	for side in ["margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 8)
	panel.add_child(pad)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	pad.add_child(box)

	var head := HBoxContainer.new()
	box.add_child(head)

	var title_color: Color = DONE_DIM if done else (UITheme.GOOD if ready else UITheme.ACCENT)
	var title := UITheme.make_label(q.title, 17, title_color)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)

	var tag_text := "เสร็จแล้ว" if done else ("ส่งได้แล้ว!" if ready else "กำลังทำ")
	head.add_child(UITheme.make_label(tag_text, 13, title_color))

	box.add_child(UITheme.make_label("จาก: %s" % q.giver_name, 13, UITheme.TEXT_DIM))

	# ---------- ★ ความคืบหน้า (รองรับหลายเงื่อนไข) ★ ----------
	var steps := q.steps()
	for i in range(steps.size()):
		var o: ObjectiveData = steps[i]
		var got: int = o.need() if done else PlayerState.quests.count_of(q.id, i)
		var step_ok: bool = done or got >= o.need()

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		box.add_child(row)

		var obj := UITheme.make_label(o.line(got), 15,
			DONE_DIM if done else (UITheme.GOOD if step_ok else UITheme.TEXT))
		obj.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(obj)

		# แถบความคืบหน้าโชว์เฉพาะเงื่อนไขที่ต้องทำหลายครั้ง
		if o.need() > 1:
			var bar := UITheme.make_bar(UITheme.GOOD if step_ok else UITheme.EXP, 12)
			bar.custom_minimum_size = Vector2(170, 14)
			bar.max_value = o.need()
			bar.value = mini(got, o.need())
			row.add_child(bar)

	box.add_child(UITheme.make_label("รางวัล: %s" % q.reward_text(), 13, Color("#ffe9a0")))
