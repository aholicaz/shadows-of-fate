## NPC — คนในเมือง (ร้านค้า / ช่างตีบวก / หมอ / เซฟเกม)
##
## โครงสร้าง Scene:
##   NPC (Area2D)  <- ใส่สคริปต์นี้
##   ├── Sprite2D หรือ AnimatedSprite2D
##   ├── CollisionShape2D
##   └── Label   (ชื่อ NPC — ไม่ใส่ก็ได้)
##
## ★ รอบ 102 ★ ใส่ class_name ให้อ้างถึงได้จากที่อื่น (เทสต์ + ตัวช่วยแบบ static เช่น warp_label)
class_name NPC
extends Area2D

## ★ รอบ 57 ★ SAVE_POINT กลายเป็น "เสาวาป" แล้ว (วาปข้ามแมพ + บันทึกเกม)
enum NPCType { DIALOG, SHOP, REFINER, HEALER, SAVE_POINT, QUEST }

@export var npc_name: String = "พ่อค้า"
@export var type: NPCType = NPCType.SHOP
## ★ ข้อความคุยเล่น ★ เว้นบรรทัดว่าง 1 บรรทัด = ขึ้นหน้าใหม่ในกล่องสนทนา
@export_multiline var dialog: String = "สวัสดี นักผจญภัย"

## ★★ บทพูดชุดพิเศษตามธงเนื้อเรื่อง (รอบ 30) ★★
##
## ใส่แบบ  {"saw_ceremony": "บทพูดชุดใหม่...", "beat_boss": "อีกชุด..."}
## ระบบจะไล่จาก "ล่างขึ้นบน" — ธงตัวท้ายสุดที่ตั้งไว้แล้วชนะ
## ไม่มีธงไหนตรงเลย = ใช้ช่อง Dialog ปกติ
##
## ตัวอย่างของตาแก่กุนนาร์:
##   {
##     "saw_ceremony": "ถ้าธอร์ปกป้องพวกเรา... แล้วเหตุใดทุกครั้งที่สายฟ้าฟาด\n\nป่าจึงเงียบลงเหมือนมีบางสิ่งตายไป?",
##     "beat_stormscar": "เจ้าเห็นแสงมันไหลลงดินใช่ไหม..."
##   }
@export var dialog_by_flag: Dictionary = {}

@export_group("รูปตัวละครในกล่องสนทนา")
## ★ รูปครึ่งตัว (หัวถึงเอว) พื้นหลังโปร่งใส สูงประมาณ 400-500 px ★
## ลากไฟล์ภาพมาใส่ช่องนี้ได้เลย
@export var portrait: Texture2D
## หรือใส่เป็น path ก็ได้ เช่น "res://Sprites/portraits/hans.png"
## (ใช้ตอนไม่อยากลากไฟล์ใน Inspector — ช่องบนมาก่อนถ้าใส่ทั้งคู่)
@export var portrait_file: String = ""
## รูปอยู่ฝั่งไหนของจอ — 0 = ซ้าย · 1 = ขวา
@export_enum("ซ้าย", "ขวา") var portrait_side: int = 0

## ★ ของที่ร้านนี้ขาย (ใส่ id ของไอเทม) ★
@export var shop_items: Array[StringName] = [
	&"red_potion", &"orange_potion", &"blue_potion",
	&"novice_sword", &"cotton_shirt", &"phracon",
]

## ค่าบริการรักษา (สำหรับ HEALER)
@export var heal_price: int = 100
## ★ รอบ 45 — NPC ประเภทอื่น (เช่นนักบวช) ก็มีร้านได้ ★ ติ๊กแล้วเมนู "ซื้อขาย" จะโผล่ (ใช้ Shop Items ข้างบน)
@export var has_shop: bool = false
## ★ รอบ 56 ★ มีเมนู "เจาะรูการ์ด" ไหม (ช่างตีเหล็ก REFINER มีให้อัตโนมัติอยู่แล้ว)
@export var has_socket: bool = false
## ★ รอบ 57 ★ มีเมนู "ตีบวก" ไหม (ช่างตีเหล็ก REFINER มีให้อัตโนมัติอยู่แล้ว)
@export var has_refine: bool = false

# =========================================================
# ★★ เสาวาป (รอบ 57) ★★ — ใช้กับ NPC ชนิด SAVE_POINT
# ปลายทางเพิ่มทีหลังแค่เติม id แมพในลิสต์ (ต้องมีใน Game.MAPS)
# ถ้าอยากให้ปลายทางไหน "ปลดล็อกก่อนถึงไปได้" ใส่ธงเนื้อเรื่องใน Warp Flags
# =========================================================
@export_group("เสาวาป")
## แมพปลายทางที่วาปไปได้ (เรียงตามลำดับที่อยากให้โชว์)
## ★ รอบ 102 ★ ปล่อยว่าง = วาปได้ทุกแมพตามกติกาใน MapAtlas (แนะนำ)
## กรอกไว้ = จำกัดให้เหลือเฉพาะรายชื่อนี้ (ยังต้องผ่านเงื่อนไขระยะ/เคยไป/ล่าครบ/มีเงินอยู่ดี)
@export var warp_targets: Array[StringName] = []
## ปลายทางไหนต้องปลดล็อกก่อน — { map_id: ธงเนื้อเรื่อง } (ไม่ใส่ = ไปได้เลย)
@export var warp_flags: Dictionary = {}
## จุดเกิดที่จะไปโผล่ในแมพปลายทาง (ไม่มีชื่อนี้ในแมพ ระบบใช้ default ให้เอง)
@export var warp_spawn_point: StringName = &"default"
## เสาวาปนี้บันทึกเกมให้ด้วยไหม (เดิม SavePoint ทำหน้าที่นี้)
@export var warp_saves_game: bool = true
## ★ รอบ 45 — ประโยคทักตอนเปิดเมนู พูดคุย / ซื้อขาย / ไม่คุย ★
@export var greeting: String = "มีอะไรให้ช่วยไหม"

# =========================================================
# ★★ เสียงพากย์ (รอบ 59) ★★
# วางไฟล์  Sprites/voice/<Voice Id>/<ประโยค>.ogg  แล้วระบบเล่นให้เองตอนขึ้นบรรทัดนั้นในกล่องสนทนา
# ชื่อประโยค: greeting · dialog_1.. · <ธง>_1.. · <เควส>_offer_1.. · <เควส>_offer_ask · <เควส>_progress
#            · <เควส>_complete · <เควส>_choice · <เควส>_cutscene_1.. · heal_full · heal_poor · heal_done
# ดูรายการทั้งหมดพร้อมคำพูด:  python3 dump_npc_lines.py
# =========================================================
@export_group("เสียงพากย์")
## โฟลเดอร์เสียงของตัวละครนี้ (ว่าง = ไม่มีเสียงพากย์) เช่น hans · tony · maria
@export var voice_id: String = ""

## ★ เควสที่ NPC คนนี้เป็นคนให้ ★ (ใส่ id ของเควสจาก data/quests/)
## ใส่ได้กับ NPC ทุกแบบ ไม่ใช่แค่แบบ QUEST — คุยแล้วจะถามเรื่องเควสก่อน แล้วค่อยเปิดร้าน
@export var quest_ids: Array[StringName] = []

## ★★ รอบ 76 — ชื่ออื่นที่ของชิ้นนี้ "รับทำพิธี/รับเงื่อนไขคุยด้วย" ★★
##
## ใช้ตอนเปลี่ยนชื่อของในฉาก แต่เควสเก่ายังอ้างชื่อเดิม
## (เสาหินกลางพรอนเทรา รอบ 57 เปลี่ยนชื่อจาก «ศิลาสลักแห่งธอร์» → «เสาวาปแห่งธอร์»
##  แต่เควส M2 ยังสั่งให้ไปทำพิธีที่ «ศิลาสลักแห่งธอร์» → เควสค้าง ทำต่อไม่ได้)
##
## ต่างจากชื่อจริงตรงที่ **ไม่นับให้อัตโนมัติตอนกดคุย** — จะโผล่เป็น "ปุ่มทำพิธี" ในเมนูแทน
## (ตามข้อความของเงื่อนไขในสมุดเควส) ผู้เล่นเลือกเองถึงจะนับ
@export var quest_talk_names: Array[StringName] = []

## ★★ รอบ 47 — เครื่องหมายเควสเหนือหัว ! ? ★★
## ใหญ่ขึ้น มีวงป้ายรองให้เห็นชัดบนฉากหลังทุกสี และลอยอยู่ "เหนือป้ายชื่อ" ไม่ทับตัวละคร
const MARK_SIZE := 74.0        # ขนาดวงป้าย (พิกเซล)
const MARK_FONT := 50          # ขนาดตัวอักษร ! ?
const MARK_GAP := 16.0         # ห่างจากขอบบนของป้ายชื่อขึ้นไป
const MARK_FALLBACK_TOP := -174.0   # NPC ที่ไม่มีป้ายชื่อ ใช้ระดับเดียวกับป้ายชื่อในแม่แบบ
const MARK_BOB := 7.0          # ลอยขึ้น-ลงกี่พิกเซล
const MARK_BOB_SPEED := 2.4

## ★★ รอบ 102 — ป้ายชื่อ NPC ★★
const NAME_FONT := 21          # ขนาดตัวอักษรชื่อ (ค่าเริ่มต้นของ Label = 16 เล็กเกินไป)
const NAME_OUTLINE := 6        # ขอบดำ ให้อ่านออกบนฉากสว่าง
const NAME_MIN_WIDTH := 220.0  # ความกว้างขั้นต่ำของป้าย (ชื่อยาวจะได้ไม่ถูกตัด)
const NAME_CLEAR := 26.0       # ช่องไฟระหว่างหัวรูปกับป้ายชื่อ

var _player_inside := false
var _prompt: Label
var _mark: Control
var _mark_glyph: Label
var _mark_disc: _MarkDisc
var _mark_base_y := 0.0


func _ready() -> void:
	add_to_group("npc")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var label := get_node_or_null("Label") as Label
	if label != null:
		label.text = npc_name
		# ★★ รอบ 102 ★★ ป้ายชื่อ NPC เล็กไป และบางตัว (เช่น เสาวาป) รูปสูงกว่าป้ายจนบัง
		label.add_theme_font_size_override("font_size", NAME_FONT)
		label.add_theme_color_override("font_color", Color("#f2ead8"))
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", NAME_OUTLINE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# กว้างพอสำหรับชื่อยาว ๆ (เดิม 120 px ชื่อยาวจะถูกตัด)
		var half: float = maxf(NAME_MIN_WIDTH, float(label.offset_right - label.offset_left)) * 0.5
		label.offset_left = -half
		label.offset_right = half
		_lift_name_above_art(label)

	_prompt = Label.new()
	_prompt.text = "[F] คุย"
	_prompt.position = Vector2(-24, -80)
	_prompt.add_theme_color_override("font_color", Color("#ffe14a"))
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 5)
	_prompt.hide()
	add_child(_prompt)

	_build_mark(label)

	Events.quest_changed.connect(_refresh_mark)
	_refresh_mark()


## ★ รอบ 47 — สร้างป้าย ! ? เหนือหัว (วงรอง + ตัวอักษรใหญ่) ★
## ★ ยกป้ายชื่อขึ้นให้พ้นยอดรูป ★
## แม่แบบ npc.tscn ตั้งป้ายไว้ที่ y = −174 ตายตัว · NPC ที่รูปสูงกว่านั้น (เสาวาป ฯลฯ) จะโดนรูปทับ
## ตรงนี้วัดยอดรูปจริงจากทุกโหนดภาพที่เป็นลูก แล้วเลื่อนป้ายขึ้นถ้าจำเป็น (ไม่เคยเลื่อนลง)
func _lift_name_above_art(label: Label) -> void:
	var top := INF
	for c in get_children():
		var n2d := c as Node2D
		if n2d == null or not n2d.visible:
			continue
		var h := 0.0
		var sp := c as Sprite2D
		if sp != null and sp.texture != null:
			h = sp.texture.get_height() * (1.0 if sp.region_enabled == false else 1.0)
			if sp.region_enabled:
				h = sp.region_rect.size.y
			if sp.hframes > 1 or sp.vframes > 1:
				h /= float(maxi(1, sp.vframes))
			top = minf(top, n2d.position.y + (-h * 0.5 * absf(n2d.scale.y) if sp.centered else 0.0))
			continue
		var asp := c as AnimatedSprite2D
		if asp != null and asp.sprite_frames != null:
			var anim := asp.animation
			if not asp.sprite_frames.has_animation(anim):
				var names := asp.sprite_frames.get_animation_names()
				if names.is_empty():
					continue
				anim = names[0]
			if asp.sprite_frames.get_frame_count(anim) <= 0:
				continue
			var tex := asp.sprite_frames.get_frame_texture(anim, 0)
			if tex == null:
				continue
			h = tex.get_height()
			top = minf(top, n2d.position.y + (-h * 0.5 * absf(n2d.scale.y) if asp.centered else 0.0))
	if top == INF:
		return
	var want: float = top - NAME_CLEAR
	if want < label.offset_top:
		var height: float = label.offset_bottom - label.offset_top
		label.offset_top = want
		label.offset_bottom = want + height


func _build_mark(name_label: Label) -> void:
	# วางให้ "ขอบล่างของวง" อยู่เหนือขอบบนของป้ายชื่อ — NPC ตัวสูง/เตี้ยก็ไม่ทับชื่อ
	var name_top: float = name_label.offset_top if name_label != null else MARK_FALLBACK_TOP
	_mark_base_y = name_top - MARK_GAP - MARK_SIZE

	_mark = Control.new()
	_mark.name = "QuestMark"
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark.size = Vector2(MARK_SIZE, MARK_SIZE)
	_mark.position = Vector2(-MARK_SIZE * 0.5, _mark_base_y)
	_mark.hide()
	add_child(_mark)

	_mark_disc = _MarkDisc.new()
	_mark_disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark.add_child(_mark_disc)

	_mark_glyph = Label.new()
	_mark_glyph.text = "!"
	_mark_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark_glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mark_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mark_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mark_glyph.add_theme_font_size_override("font_size", MARK_FONT)
	_mark_glyph.add_theme_color_override("font_color", Color("#ffe14a"))
	_mark_glyph.add_theme_color_override("font_outline_color", Color.BLACK)
	_mark_glyph.add_theme_constant_override("outline_size", 8)
	_mark.add_child(_mark_glyph)


## ป้ายลอยขึ้นลงเบา ๆ ให้สะดุดตา (ทำงานเฉพาะตอนป้ายโชว์อยู่)
func _process(_delta: float) -> void:
	if _mark == null or not _mark.visible:
		return
	var t: float = float(Time.get_ticks_msec()) * 0.001 * MARK_BOB_SPEED
	_mark.position.y = _mark_base_y + sin(t) * MARK_BOB


## เครื่องหมายเหนือหัว: ! = มีเควสให้รับ · ? = เอาไปส่งได้แล้ว
func _refresh_mark() -> void:
	if _mark == null:
		return
	if PlayerState.quests == null:
		_mark.hide()
		return
	# ★ รอบ 76 ★ ของที่ "ทำพิธีได้ตอนนี้" ก็ขึ้นเครื่องหมายให้หาเจอ (เช่น เสาหินของ M2)
	if not pending_ritual().is_empty():
		_show_mark("!", Color("#7dc4ff"))       # พิธี/จุดที่ต้องไปทำ = ฟ้า
		return
	if quest_ids.is_empty():
		_mark.hide()
		return
	var qlog := PlayerState.quests
	var lv: int = PlayerState.stats.level if PlayerState.stats != null else 1

	for qid in quest_ids:
		if qlog.is_ready(qid):
			_show_mark("?", Color("#7dffa8"))   # เอาไปส่งได้แล้ว = เขียว
			return
	for qid in quest_ids:
		if qlog.can_accept(qid, lv):
			_show_mark("!", Color("#ffe14a"))   # มีเควสให้รับ = เหลือง
			return
	_mark.hide()


func _show_mark(glyph: String, tint: Color) -> void:
	_mark_glyph.text = glyph
	_mark_glyph.add_theme_color_override("font_color", tint)
	if _mark_disc != null:
		_mark_disc.tint = tint
		_mark_disc.queue_redraw()
	_mark.position.y = _mark_base_y
	_mark.show()


## รูปที่จะโชว์ในกล่องสนทนา (ไม่มีก็คืน null — กล่องจะไม่โชว์ช่องรูป)
func portrait_texture() -> Texture2D:
	if portrait != null:
		return portrait
	if portrait_file != "" and ResourceLoader.exists(portrait_file):
		return load(portrait_file) as Texture2D
	return null


## บทพูดของ NPC คนนี้ 1 บรรทัด (ใส่ชื่อ + รูป + ฝั่งให้อัตโนมัติ)
func line(text: String, info: String = "", choices: Array = [], voice_key: String = "") -> Dictionary:
	var d := {
		"name": npc_name,
		"portrait": portrait_texture(),
		"side": portrait_side,
		"text": text,
	}
	if info != "":
		d["info"] = info
	if not choices.is_empty():
		d["choices"] = choices
	var v := voice_path(voice_key)
	if v != "":
		d["voice"] = v
	return d


## ★ รอบ 59 ★ "voice_id/key" ของประโยคนี้ ("" = NPC ไม่มีเสียงพากย์ หรือไม่ได้ระบุประโยค)
func voice_path(key: String) -> String:
	if voice_id == "" or key == "":
		return ""
	return voice_id + "/" + key


## เล่นเสียงพากย์ทันที (ใช้กับประโยคที่ไม่ได้ผ่านกล่องสนทนา เช่นหมอรักษา)
func say_voice(key: String) -> void:
	var v := voice_path(key)
	if v == "" or Game.voice == null:
		return
	Game.voice.play_path(v)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		_prompt.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside:
		return
	if event.is_action_pressed("interact"):
		interact()
		get_viewport().set_input_as_handled()


func interact() -> void:
	# ★ เดินความคืบหน้าเควสชนิด "คุยกับ NPC" ★ (รอบ 30)
	# ทำก่อนอย่างอื่น เผื่อการคุยครั้งนี้ทำให้เควสครบพอดี แล้วส่งเควสได้เลยในครั้งเดียว
	if PlayerState.quests != null:
		PlayerState.quests.on_talked_to(npc_name)

	# ★ รอบ 57 — เสาวาป ★ (เดิมเป็นศิลาเซฟ กดแล้วเซฟทันที ตอนนี้มีเมนูให้เลือกปลายทาง)
	if type == NPCType.SAVE_POINT:
		await open_warp_menu()
		return

	# ★★ รอบ 45 — เมนูก่อนคุย: พูดคุย / ซื้อขาย / ไม่คุย ★★
	var options: Array = [MENU_TALK]
	var ritual := pending_ritual()               # ★ รอบ 76 ★ ปุ่มทำพิธีของเควส (ถ้ามี)
	if not ritual.is_empty():
		options.push_front(String(ritual["text"]))
	if has_shop_menu():
		options.append(MENU_SHOP)
	if has_refine_menu():
		options.append(MENU_REFINE)
	if has_socket_menu():
		options.append(MENU_SOCKET)
	options.append(MENU_LEAVE)
	var pick: int = await UI.talk([line(greeting, "", options, "greeting")])
	if not is_instance_valid(self) or pick < 0 or pick >= options.size():
		return
	var chosen: String = options[pick]
	if chosen == MENU_LEAVE:
		return
	if not ritual.is_empty() and chosen == String(ritual["text"]):
		do_ritual(ritual)
		return
	if chosen == MENU_SHOP:
		open_shop()
		return
	if chosen == MENU_REFINE:
		Events.refine_npc_opened.emit()
		return
	if chosen == MENU_SOCKET:
		Events.socket_npc_opened.emit()
		return

	# ---- พูดคุย: เรื่องเควสมาก่อน แล้วค่อยบริการ/บทพูด ----
	var quest_handled: bool = await _handle_quests()
	if quest_handled or not is_instance_valid(self):
		return

	match type:
		NPCType.HEALER:
			if PlayerState.stats.hp >= PlayerState.stats.max_hp \
					and PlayerState.stats.sp >= PlayerState.stats.max_sp:
				Events.say("%s: เลือดกับพลังเต็มอยู่แล้วนะ" % npc_name)
				say_voice("heal_full")
			elif PlayerState.zeny < heal_price:
				Events.say("%s: ค่ารักษา %d ซีนี ซีนีไม่พอนะ" % [npc_name, heal_price])
				say_voice("heal_poor")
			else:
				PlayerState.add_zeny(-heal_price)
				PlayerState.heal_hp(PlayerState.stats.max_hp)
				PlayerState.restore_sp(PlayerState.stats.max_sp)
				Events.say("%s: หายดีแล้ว!" % npc_name)
				say_voice("heal_done")

		_:
			# ★ คุยผ่านกล่องสนทนา ★ เว้นบรรทัดว่าง = ขึ้นหน้าใหม่
			var pages: Array = []
			var vkey := current_dialog_key()       # dialog / ชื่อธง → ไฟล์เสียง <vkey>_1, _2 ...
			for part in current_dialog().split("\n\n", false):
				var t := String(part).strip_edges()
				if t != "":
					pages.append(line(t, "", [], "%s_%d" % [vkey, pages.size() + 1]))
			if pages.is_empty():
				pages.append(line(current_dialog(), "", [], vkey + "_1"))
			await UI.talk(pages)


const MENU_TALK := "พูดคุย"
const MENU_SHOP := "ซื้อขาย"
const MENU_REFINE := "ตีบวก"
const MENU_SOCKET := "เจาะรูการ์ด"
const MENU_LEAVE := "ไม่คุย"
const MENU_SAVE := "บันทึกเกม"


## มีเมนูซื้อขายไหม — ร้านค้า หรือ NPC ที่ติ๊ก Has Shop
func has_shop_menu() -> bool:
	return type == NPCType.SHOP or has_shop


## มีเมนูเจาะรูการ์ดไหม — ช่างตีเหล็ก (REFINER) มีให้เลย หรือ NPC ที่ติ๊ก Has Socket
func has_socket_menu() -> bool:
	return type == NPCType.REFINER or has_socket


## มีเมนูตีบวกไหม — ช่างตีเหล็ก (REFINER) มีให้เลย หรือ NPC ที่ติ๊ก Has Refine
func has_refine_menu() -> bool:
	return type == NPCType.REFINER or has_refine


# =========================================================
# ★★ เสาวาป (รอบ 57) ★★
# =========================================================
## ปลายทางที่ "เปิดให้ไปได้ตอนนี้" — คืน Array ของ
##   { id, name, cost, hops, ok, why }
##
## ★★ รอบ 102 — กติกาใหม่ ★★  (เดิมโชว์เฉพาะรายชื่อที่พิมพ์ไว้ใน Warp Targets และไม่มีค่าใช้จ่าย)
##   1. วาปได้ทุกแมพในโลก **ยกเว้นแมพที่ติดกัน** (ห่าง 1 ทอด = เดินเอา ไม่ต้องเสียเงิน)
##   2. ต้องเคยไปถึงแมพนั้นมาก่อน
##   3. ต้องล่ามอนในแมพนั้น "ครบทุกชนิด" แล้ว
##   4. เสียค่าวาป เริ่ม 2000 เพิ่มตามระยะทาง เพดาน 25000 (ดู MapAtlas.warp_cost)
##
## `warp_targets` / `warp_flags` เดิมยังใช้ได้: ถ้ากรอกไว้ = จำกัดให้เหลือเฉพาะรายชื่อนั้น
## (ปล่อยว่าง = ใช้ทั้งโลกตามกติกาข้างบน) — เสาเก่าในฉากจึงไม่พังและยังคุมด้วยมือได้เหมือนเดิม
func warp_options() -> Array:
	var here := PlayerState.current_map_id
	var all: Array = MapAtlas.warp_destinations(here)
	var limited := not warp_targets.is_empty()
	var out: Array = []
	for d in all:
		var id: StringName = d["id"]
		if limited and not warp_targets.has(id):
			continue
		if warp_flags.has(id) and not PlayerState.has_flag(StringName(warp_flags[id])):
			continue                      # ยังไม่ปลดล็อกด้วยธงเนื้อเรื่อง
		out.append(d)
	return out


## ข้อความบนปุ่มปลายทาง 1 อัน
static func warp_label(d: Dictionary) -> String:
	if bool(d.get("ok", false)):
		return "ไป %s  (%s z)" % [String(d["name"]), HUD._comma(int(d["cost"]))]
	return "%s — %s" % [String(d["name"]), String(d.get("why", ""))]


## เปิดเมนูเสาวาป
func open_warp_menu() -> void:
	var targets := warp_options()
	var options: Array = []
	# ★ รอบ 76 ★ ปุ่มทำพิธีของเควสมาก่อนเสมอ (เช่น M2 «ทำพิธีที่ศิลาสลักแห่งธอร์»)
	var ritual := pending_ritual()
	if not ritual.is_empty():
		options.append(String(ritual["text"]))
	for t in targets:
		options.append(warp_label(t))
	if warp_saves_game:
		options.append(MENU_SAVE)
	options.append(MENU_LEAVE)

	var head: String = current_dialog()
	if targets.is_empty():
		head = "%s
(ยังไม่มีปลายทางให้ไป)" % head
	var pick: int = await UI.talk([line(head, "", options)])
	if not is_instance_valid(self) or pick < 0 or pick >= options.size():
		return
	var chosen: String = options[pick]
	if chosen == MENU_LEAVE:
		return
	if not ritual.is_empty():
		if chosen == String(ritual["text"]):
			do_ritual(ritual)
			return
		pick -= 1                     # ตัดปุ่มพิธีออกจากลำดับ แล้วค่อยเทียบกับรายการปลายทาง
	if chosen == MENU_SAVE:
		SaveManager.save_game(0)
		return
	if pick >= 0 and pick < targets.size():
		var t: Dictionary = targets[pick]
		# ★ รอบ 102 ★ ปลายทางที่ยังไม่ผ่านเงื่อนไขก็ยังโชว์อยู่ (จะได้รู้ว่าต้องทำอะไรอีก)
		# แต่กดแล้วไม่วาป — บอกเหตุผลแทน
		if not bool(t.get("ok", false)):
			Events.say("%s: %s" % [String(t["name"]), String(t.get("why", "ยังไปไม่ได้"))])
			return
		var cost := int(t.get("cost", 0))
		if not PlayerState.spend_zeny(cost):
			Events.say("เงินไม่พอ — ต้องใช้ %s z" % HUD._comma(cost))
			return
		var dest: StringName = t["id"]
		Events.say("กำลังวาปไป %s...  (−%s z)" % [String(t["name"]), HUD._comma(cost)])
		await Game.change_map(dest, warp_spawn_point)


# =========================================================
# ★★ รอบ 76 — "ปุ่มทำพิธี" ของเควสชนิดคุยด้วย ★★
#
# ปัญหา: เควส M2 สั่งให้ไปทำพิธีที่ «ศิลาสลักแห่งธอร์» แต่เสาหินในฉากถูกเปลี่ยนชื่อ
#        เป็น «เสาวาปแห่งธอร์» ตั้งแต่รอบ 57 → กดคุยยังไงเควสก็ไม่ขยับ ทำต่อไม่ได้
# แก้:   NPC/ของชิ้นไหนใส่ Quest Talk Names ไว้ ถ้ามีเควสที่กำลังทำต้องการชื่อนั้น
#        จะมี "ปุ่มทำพิธี" โผล่ในเมนู (ข้อความ = ข้อความของเงื่อนไขในสมุดเควส)
#        เลือกแล้วถึงนับให้ — ไม่แอบนับตอนเดินผ่าน
# =========================================================
## เงื่อนไขเควสที่ของชิ้นนี้ทำให้ได้ตอนนี้ — คืน {"name": ชื่อเป้าหมาย, "text": ข้อความปุ่ม}
## ไม่มี = คืน {} (Dictionary ว่าง)
func pending_ritual() -> Dictionary:
	if quest_talk_names.is_empty() or PlayerState == null or PlayerState.quests == null:
		return {}
	var qlog := PlayerState.quests
	for qid in qlog.active:
		var q := GameData.get_quest(qid)
		if q == null:
			continue
		var list := q.steps()
		for i in range(list.size()):
			var o := list[i]
			if o.kind != ObjectiveData.Kind.TALK or o.is_live():
				continue
			if not (o.target in quest_talk_names):
				continue
			if qlog.count_of(qid, i) >= o.need():
				continue
			var label := o.text.strip_edges()
			if label == "":
				label = "ทำพิธีที่ %s" % String(o.target)
			return {"name": o.target, "text": label, "quest": q.title}
	return {}


## กดปุ่มทำพิธี — นับเงื่อนไขให้ แล้วบอกผู้เล่นว่าเกิดอะไรขึ้น
func do_ritual(ritual: Dictionary) -> void:
	if ritual.is_empty() or PlayerState.quests == null:
		return
	PlayerState.quests.on_talked_to(String(ritual["name"]))
	Events.say("[เควส] %s" % String(ritual["text"]))


func open_shop() -> void:
	var ids: Array = []
	for id in shop_items:
		ids.append(id)
	Events.shop_opened.emit(ids)


## ★ บทพูดที่ควรใช้ตอนนี้ ★ ดูจากธงเนื้อเรื่องที่ตั้งไว้แล้ว
## ไล่จากท้ายลิสต์ขึ้นมา — ธงตัวหลังชนะตัวหน้า (เขียนเรียงตามลำดับเนื้อเรื่องได้เลย)
func current_dialog() -> String:
	var k := current_dialog_key()
	if k != "dialog":
		return String(dialog_by_flag[k]).strip_edges()
	return dialog


## ★ รอบ 59 ★ บทพูดชุดไหนกำลังใช้อยู่ — "dialog" (ปกติ) หรือชื่อธงใน dialog_by_flag
## ใช้เป็นชื่อไฟล์เสียงพากย์ด้วย: <key>_1.ogg, <key>_2.ogg ...
func current_dialog_key() -> String:
	if not dialog_by_flag.is_empty() and PlayerState != null:
		var keys: Array = dialog_by_flag.keys()
		for i in range(keys.size() - 1, -1, -1):
			var flag := StringName(keys[i])
			if PlayerState.has_flag(flag):
				var t := String(dialog_by_flag[keys[i]]).strip_edges()
				if t != "":
					return String(keys[i])
	return "dialog"


# =========================================================
# เควส
# =========================================================
## จัดการเควสของ NPC คนนี้ — คืน true ถ้ามีเรื่องเควสให้คุย
## หมายเหตุ: คุยจบแล้วยังเปิดร้าน/ตีบวกต่อได้ตามปกติ (NPC ที่มีเควสจะไม่ถูกบล็อก)
func _handle_quests() -> bool:
	if quest_ids.is_empty():
		return false
	var qlog := PlayerState.quests
	var lv: int = PlayerState.stats.level

	# 1) มีเควสที่ทำครบแล้ว -> ส่งเควส
	for qid in quest_ids:
		if qlog.is_ready(qid):
			await _ask_turn_in(GameData.get_quest(qid))
			return true

	# 2) มีเควสที่รับไว้แล้วแต่ยังไม่ครบ -> บอกความคืบหน้า
	for qid in quest_ids:
		if qlog.is_active(qid):
			var q := GameData.get_quest(qid)
			if q == null:
				continue
			await UI.talk([line(q.dialog_progress,
				"ความคืบหน้า: %s" % q.objective_text(qlog.count_of(qid)), [], String(qid) + "_progress")])
			return true

	# 3) มีเควสใหม่ให้รับ -> ถามว่ารับไหม
	for qid in quest_ids:
		if qlog.can_accept(qid, lv):
			await _ask_accept(GameData.get_quest(qid))
			return true

	return false


## ★ ชวนรับเควส — คุยกันเป็นบทสนทนา ★
func _ask_accept(q: QuestData) -> void:
	if q == null:
		return
	var qk := String(q.id)
	var script: Array = []
	# บทชวน (เว้นบรรทัดว่าง = ขึ้นหน้าใหม่) → เสียง <เควส>_offer_1, _offer_2 ...
	for part in q.dialog_offer.split("\n\n", false):
		var t := String(part).strip_edges()
		if t != "":
			script.append(line(t, "", [], "%s_offer_%d" % [qk, script.size() + 1]))
	if script.is_empty():
		script.append(line(q.dialog_offer, "", [], qk + "_offer_1"))
	if q.description != "" and q.description != q.dialog_offer:
		script.append(line(q.description, "", [], "%s_offer_%d" % [qk, script.size() + 1]))
	script.append(line("เอาไงล่ะ รับงานนี้มั้ย",
		"[ %s ]  เงื่อนไข: %s\nรางวัล: %s" % [q.title, q.objective_text(0), q.reward_text()],
		["รับเควส", "ไว้ก่อน"], qk + "_offer_ask"))

	var pick: int = await UI.talk(script)
	if pick == 0 and is_instance_valid(self):
		PlayerState.quests.accept(q.id)
		Events.say("[รับเควส] %s — %s" % [q.title, q.objective_text(0)])
		# ★ รอบ 59 — วิดีโอคัทซีนตอนรับเควส ★
		if q.video_on_accept != "":
			await UI.play_video(q.video_on_accept)


func _ask_turn_in(q: QuestData) -> void:
	if q == null:
		return
	var pick: int = await UI.talk([
		line(q.dialog_complete,
			"[ %s ]  รางวัล: %s" % [q.title, q.reward_text()],
			["รับรางวัล", "ไว้ก่อน"], String(q.id) + "_complete"),
	])
	if pick == 0 and is_instance_valid(self):
		PlayerState.turn_in_quest(q.id)
		# ★ รอบ 59 — วิดีโอคัทซีนตอนส่งเควส (ก่อนตัวเลือก/แพนกล้อง) ★
		if q.video_on_complete != "":
			await UI.play_video(q.video_on_complete)
		if not is_instance_valid(self):
			return
		await _after_turn_in(q)


## ★ เหตุการณ์หลังส่งเควส (รอบ 38) ★ ตัวเลือกเนื้อเรื่อง + ฉากแพนกล้อง
func _after_turn_in(q: QuestData) -> void:
	# ---------- ตัวเลือกที่เกมจะจำไว้ (เช่น M2 สาบาน/เงียบ) ----------
	if q.choice_prompt != "" and not q.choice_options.is_empty():
		var choice: int = await UI.talk([line(q.choice_prompt, "", q.choice_options, String(q.id) + "_choice")])
		if not is_instance_valid(self):
			return
		if choice >= 0 and choice < q.choice_flags.size() and q.choice_flags[choice] != &"":
			PlayerState.set_flag(q.choice_flags[choice])

	# ---------- ฉากแพนกล้องไปหา NPC (เช่น M6 กล้องไปหยุดที่กุนนาร์) ----------
	if q.cutscene_pan_npc == "":
		return
	var target: Node2D = null
	for n in get_tree().get_nodes_in_group("npc"):
		if n != self and "npc_name" in n and String(n.npc_name) == q.cutscene_pan_npc:
			target = n
			break
	# เสียงพากย์ฉากนี้ใช้ voice_id ของ NPC ที่กล้องแพนไปหา (ไม่มีก็ใช้ของคนให้เควส)
	var cut_voice: String = voice_id
	if target != null and "voice_id" in target and String(target.voice_id) != "":
		cut_voice = String(target.voice_id)
	var pages: Array = []
	for part in q.cutscene_text.split("\n\n", false):
		var t := String(part).strip_edges()
		if t != "":
			var pg := {"name": q.cutscene_pan_npc, "side": 1, "text": t}
			if cut_voice != "":
				pg["voice"] = "%s/%s_cutscene_%d" % [cut_voice, String(q.id), pages.size() + 1]
			pages.append(pg)
	var player := get_tree().get_first_node_in_group("player")
	var cam: Camera2D = player.get_node_or_null("Camera2D") if player != null else null
	if target == null or cam == null:
		# หา NPC ไม่เจอ (คนละแมพ) — โชว์แค่ข้อความ
		if not pages.is_empty():
			await UI.talk(pages)
		return
	# แพนกล้องไปหา → คุย → แพนกลับ
	var off: Vector2 = target.global_position - (player as Node2D).global_position + Vector2(0, -40)
	var tw := create_tween()
	tw.tween_property(cam, "offset", off, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	if not is_instance_valid(self):
		return
	if not pages.is_empty():
		await UI.talk(pages)
	if not is_instance_valid(self) or cam == null:
		return
	var back := create_tween()
	back.tween_property(cam, "offset", Vector2.ZERO, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await back.finished


# =========================================================
# ★ รอบ 47 — วงป้ายรองหลังเครื่องหมาย ! ? ★
# วาดเอง (ไม่ต้องมีไฟล์ภาพ) — วงเข้มทึบ + ขอบสีตามชนิดเครื่องหมาย + เงาจาง ๆ
# ทำให้ ! ? อ่านออกทั้งบนฉากหลังสว่างและมืด
# =========================================================
class _MarkDisc extends Control:
	var tint := Color("#ffe14a")

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var r: float = minf(size.x, size.y) * 0.5
		# แสงเรืองจาง ๆ รอบนอก
		draw_circle(c, r, Color(tint.r, tint.g, tint.b, 0.16))
		# วงพื้นเข้ม
		draw_circle(c, r * 0.78, Color(0.05, 0.06, 0.1, 0.82))
		# ขอบสี
		draw_arc(c, r * 0.78, 0.0, TAU, 40, tint, 4.0, true)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()
