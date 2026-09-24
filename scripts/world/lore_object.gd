## LoreObject — ของในแมพที่ "กด F แล้วอ่านได้" (รอบ 30)
##
## ใช้ทำ: ชั้นหนังสือในวิหาร · หลุมศพ · รอยไหม้บนเปลือกไม้ · ป้ายบอกทาง ·
##        เป้สะพายของนักล่าที่หายไป · ศิลาจารึก
##
## ★ วิธีใช้ ★
##   1) ลาก scenes/world/lore_object.tscn เข้าไปวางในแมพ
##   2) ตั้งช่อง Lore Id (ชื่ออะไรก็ได้ แต่ต้องไม่ซ้ำ เช่น "shrine_bookshelf")
##   3) พิมพ์ข้อความลงช่อง Text — เว้นบรรทัดว่าง = ขึ้นหน้าใหม่ในกล่องสนทนา
##   4) ถ้าจะให้มันเดินเควส ให้ใส่เงื่อนไขชนิด READ ในไฟล์เควส แล้วใส่ Target = Lore Id เดียวกัน
##
## อยากให้เห็นรูปด้วย ก็แค่เพิ่ม Sprite2D เป็นลูกของโหนดนี้
class_name LoreObject
extends Area2D

## ★ ชื่อเฉพาะของจุดนี้ ★ ใช้ผูกกับเงื่อนไขเควสชนิด READ และใช้จำว่าอ่านไปแล้ว
@export var lore_id: StringName = &"lore"
## ชื่อที่โชว์บนกล่องสนทนา (เว้นว่าง = ไม่โชว์ชื่อ)
@export var title: String = ""
## ★ ข้อความ ★ เว้นบรรทัดว่าง = ขึ้นหน้าใหม่
@export_multiline var text: String = "..."
## ข้อความชุดที่สอง สำหรับตอนกลับมาอ่านซ้ำ (เว้นว่าง = ใช้ข้อความเดิม)
@export_multiline var text_again: String = ""

@export_group("เงื่อนไขและผลลัพธ์")
## ★ ต้องมีธงนี้ก่อนถึงจะอ่านได้ ★ เว้นว่าง = อ่านได้เลย
@export var required_flag: StringName = &""
## ข้อความตอนที่ยังอ่านไม่ได้
@export var locked_text: String = "ยังไม่มีอะไรน่าสนใจตรงนี้"
## ★ อ่านแล้วตั้งธงนี้ ★ เว้นว่าง = ไม่ตั้ง
@export var set_flag: StringName = &""
## ★ อ่านแล้วได้ไอเทมนี้ ★ (ครั้งแรกครั้งเดียว) เว้นว่าง = ไม่ให้
@export var give_item: StringName = &""
@export var give_item_count: int = 1

## ★ รอบ 105 ★ เดินถึงแล้วนับเลย ไม่ต้องกด F (ใช้ทำเงื่อนไข "ไปให้ถึงจุดนี้") — โชว์ Title สั้น ๆ บนจอแทนกล่องสนทนา
@export var auto_read: bool = false
## ★ รอบ 135 ★ เงื่อนไข "ห้ามฆ่า": ถ้าฆ่ามอนชนิดนี้ "หลังเข้าแมพนี้" จุดนี้จะไม่นับให้เควส (ต้องออกแมพแล้วเดินใหม่)
## นับจากตอนเข้าแมพ ไม่ใช่ตั้งแต่ต้นเกม — ที่ฆ่าไปก่อนหน้าไม่ถือว่าผิด
@export var no_kill_monster: StringName = &""
@export var no_kill_text: String = "มีตัวที่ล้มตายระหว่างทาง... ออกจากที่นี่แล้วเดินผ่านใหม่โดยไม่ฆ่า"

@export_group("ข้อความบนหัว")
## ป้ายที่ลอยอยู่เหนือของชิ้นนี้ (เว้นว่าง = ไม่โชว์)
@export var label_text: String = ""
@export var prompt_text: String = "กด F เพื่อดู"

var _player_inside := false
var _kills_at_entry := 0   # ★ รอบ 135 ★
var _prompt: Label
var _label: Label


func _ready() -> void:
	add_to_group("lore_object")
	monitoring = true
	monitorable = false
	if get_node_or_null("Shape") == null and get_child_count() == 0:
		_build_default_shape()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_labels()
	_build_quest_mark()   # ★ รอบ 156 ★
	if no_kill_monster != &"":   # ★ รอบ 135 ★ จำยอดฆ่าตอนเข้าแมพ
		_kills_at_entry = PlayerState.kill_count(no_kill_monster)


func _build_default_shape() -> void:
	var col := CollisionShape2D.new()
	col.name = "Shape"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(120, 200)
	col.shape = rect
	add_child(col)


func _build_labels() -> void:
	if label_text != "":
		_label = UITheme.make_label(label_text, 26, Color("ece7d8"))
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.add_theme_color_override("font_outline_color", Color.BLACK)
		_label.add_theme_constant_override("outline_size", 5)
		_label.position = Vector2(-180, -200)
		_label.custom_minimum_size.x = 360
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_label)
		preload("res://scripts/ui/quest_location_style.gd").apply(_label)

	_prompt = UITheme.make_label(prompt_text, 20, Color("#9be7ff"))
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 5)
	_prompt.position = Vector2(-90, -140)
	_prompt.custom_minimum_size.x = 180
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.hide()
	add_child(_prompt)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		if auto_read:   # ★ รอบ 105 ★
			_auto_read()
			return
		if _prompt != null:
			_prompt.show()


## ★ รอบ 105 ★ ถึงจุดนี้แล้ว = อ่านให้เองเงียบ ๆ (ครั้งแรกครั้งเดียว) — ไม่เปิดกล่องสนทนา ไม่ขวางการเล่น
func _auto_read() -> void:
	if required_flag != &"" and not PlayerState.has_flag(required_flag):
		return
	if _no_kill_failed():   # ★ รอบ 135 ★
		return
	if PlayerState.has_flag(_read_flag()):
		# ★ รอบ 135 ★ เคยผ่านจุดนี้มาก่อนรับเควส — ยังต้องเดินความคืบหน้าเควสให้ (เดิม return เฉย ๆ = เควส «เด็กที่ถาม» ค้าง)
		if PlayerState.quests != null:
			PlayerState.quests.on_read(lore_id)
		return
	PlayerState.set_flag(_read_flag())
	if give_item != &"" and give_item_count > 0:
		PlayerState.gain_item_id(give_item, give_item_count)
	if set_flag != &"":
		PlayerState.set_flag(set_flag)
	if title != "":
		Events.say(title if text.strip_edges() == "" else "%s — %s" % [title, text.get_slice("\n", 0)])
	if PlayerState.quests != null:
		PlayerState.quests.on_read(lore_id)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		if _prompt != null:
			_prompt.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside or UI == null:
		return
	if UI.is_asking() or UI.is_any_window_open():
		return
	if not (event.is_action_pressed("interact") or event.is_action_pressed("pickup")):
		return
	# ★ ของที่ตกอยู่มาก่อน ★ กัน F แย่งกันกับการเก็บของ
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("nearest_pickup") and player.nearest_pickup() != null:
		return
	get_viewport().set_input_as_handled()
	read()


## อ่านของชิ้นนี้ (เรียกจากโค้ดอื่นได้ด้วย)
func read() -> void:
	# ---------- ยังอ่านไม่ได้ ----------
	if required_flag != &"" and not PlayerState.has_flag(required_flag):
		await UI.talk([{"name": title, "text": locked_text}])
		return

	var first_time: bool = not PlayerState.has_flag(_read_flag())
	var body: String = text
	if not first_time and text_again.strip_edges() != "":
		body = text_again

	var pages: Array = []
	for part in Loc.clean(body).split("\n\n", false):
		var t := String(part).strip_edges()
		if t != "":
			pages.append({"name": title, "text": t})
	if pages.is_empty():
		pages.append({"name": title, "text": body})
	await UI.talk(pages)

	# ---------- ผลลัพธ์ (ครั้งแรกครั้งเดียว) ----------
	if first_time:
		PlayerState.set_flag(_read_flag())
		if give_item != &"" and give_item_count > 0:
			PlayerState.gain_item_id(give_item, give_item_count)
	if set_flag != &"":
		PlayerState.set_flag(set_flag)

	# ★ เดินความคืบหน้าเควสชนิด READ ★
	if PlayerState.quests != null and not _no_kill_failed():   # ★ รอบ 135 ★
		PlayerState.quests.on_read(lore_id)


## ธงที่ใช้จำว่าอ่านชิ้นนี้ไปแล้ว
func _read_flag() -> StringName:
	return StringName("read_%s" % String(lore_id))


## ★ รอบ 135 ★ ฆ่ามอนต้องห้ามไปหลังเข้าแมพหรือเปล่า — ถ้าใช่ บอกผู้เล่นแล้วคืน true (จุดนี้ไม่นับ)
func _no_kill_failed() -> bool:
	if no_kill_monster == &"":
		return false
	if PlayerState.kill_count(no_kill_monster) <= _kills_at_entry:
		return false
	var relevant := false
	if PlayerState.quests != null:
		for qid in PlayerState.quests.active:
			var q := GameData.get_quest(qid)
			if q == null:
				continue
			for o in q.steps():
				if o.kind == ObjectiveData.Kind.READ and o.target == lore_id:
					relevant = true
	if relevant:
		Events.say(no_kill_text)
	return relevant


# =========================================================
# ★★ รอบ 156 ★★ เครื่องหมาย ! ฟ้า เหนือป้าย/เสาที่เควสสั่งให้มาอ่านเป็นขั้นถัดไป
# =========================================================
var _quest_mark: Label
var _mark_t := 0.0

func _build_quest_mark() -> void:
	_quest_mark = UITheme.make_label("!", 48, Color("#7dc4ff"))
	_quest_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quest_mark.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.1, 0.95))
	_quest_mark.add_theme_constant_override("outline_size", 12)
	_quest_mark.custom_minimum_size = Vector2(60, 0)
	_quest_mark.position = Vector2(-30, -270 if label_text != "" else -200)
	_quest_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_mark.z_index = 20
	_quest_mark.hide()
	add_child(_quest_mark)
	Events.quest_changed.connect(_refresh_quest_mark)
	_refresh_quest_mark()


func _refresh_quest_mark() -> void:
	if _quest_mark == null or PlayerState.quests == null:
		return
	_quest_mark.visible = PlayerState.quests.step_waiting(ObjectiveData.Kind.READ, lore_id)


func _process(delta: float) -> void:
	if _quest_mark != null and _quest_mark.visible:
		_mark_t += delta
		_quest_mark.position.y = (-270.0 if label_text != "" else -200.0) + sin(_mark_t * 3.0) * 6.0
