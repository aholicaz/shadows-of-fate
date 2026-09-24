extends Node
## รอบ 161 — บทเควสใหม่ + เควสข้ามเมือง + ระบบ 2 ภาษา
var fails := 0
var passes := 0

func ok(c: bool, m: String) -> void:
	if c:
		passes += 1
		print("  PASS ", m)
	else:
		fails += 1
		print("  FAIL ", m)

func _ready() -> void:
	await get_tree().process_frame
	print("== r161 test ==")
	# 1) สคริปต์ที่แก้ คอมไพล์ผ่าน
	for p in ["res://scripts/core/loc.gd", "res://scripts/world/npc.gd", "res://scripts/ui/dialogue_box.gd", "res://scripts/ui/system_window.gd",
			"res://scripts/world/runeblade_campaign.gd", "res://scripts/world/blackhorn_rootcrypt.gd", "res://scripts/world/ch456_campaign.gd",
			"res://scripts/world/lore_object.gd", "res://scripts/resources/quest_data.gd", "res://scripts/core/quest_log.gd",
			"res://scripts/resources/objective_data.gd", "res://scripts/core/game.gd"]:
		var s: Script = load(p)
		ok(s != null and s.can_instantiate(), "compile " + p.get_file())
	# 2) Loc
	Loc.set_locale("th")
	ok(Loc.current() == "th", "ภาษาเริ่มต้น = ไทย")
	ok(Loc.t("พูดคุย") == "พูดคุย", "ไทยคืนข้อความเดิม")
	ok(Loc.t("ก\r\n\r\nข") == "ก\n\nข", "clean ตัด \\r")
	Loc.set_locale("en")
	ok(Loc.current() == "en", "เปลี่ยนเป็น English")
	ok(Loc.t("พูดคุย") == "Talk", "UI: พูดคุย → Talk")
	ok(Loc.t("ผู้อาวุโสสกาดี") == "Elder Skadi", "ชื่อ NPC แปล")
	var sk := Loc.t("ตาข้าบอด มองไม่เห็นเจ้าหรอก... แต่ข้าได้กลิ่นค้อนของธอร์ติดตัวเจ้ามา — ปนกับกลิ่นของคนที่เริ่มไม่แน่ใจในค้อนนั้นแล้ว")
	ok(sk.begins_with("My eyes are blind"), "ทักทายสกาดีแปล: " + sk.left(40))
	ok(Loc.t("ข้อความที่ไม่มีในไฟล์แปล") == "ข้อความที่ไม่มีในไฟล์แปล", "ไม่มีคำแปล = คืนไทย")
	var lab := Label.new()
	add_child(lab)
	lab.text = "เด็กเอลฟ์อิลวา"
	ok(lab.atr(lab.text) == "Ylva", "Label แปลอัตโนมัติ (auto translate)")
	lab.queue_free()
	# 3) เควสทั้งหมด
	var qs := GameData.all_quests()
	ok(qs.size() >= 96, "โหลดเควส %d" % qs.size())
	var smile := 0
	var empty_offer := 0
	for q in qs:
		for t in [q.dialog_offer, q.dialog_progress, q.dialog_complete, q.description, q.cutscene_text]:
			if "☺" in t: smile += 1
		if q.dialog_offer.strip_edges() == "": empty_offer += 1
		# ทุกหน้าของบทชวนแปลได้
		for part in Loc.clean(q.dialog_offer).split("\n\n", false):
			var tp := String(part).strip_edges()
			if tp != "" and Loc.t(tp) == tp:
				fails += 1
				print("  FAIL ยังไม่แปล ", q.id, ": ", tp.left(30))
		if Loc.t(q.title) == q.title: print("  (title ไม่แปล) ", q.id)
	ok(smile == 0, "ไม่มี ☺ ในเควส")
	ok(empty_offer == 0, "ทุกเควสมีบทชวน")
	var rb15 := GameData.get_quest(&"rb15_song_for_brokk")
	var c611 := GameData.get_quest(&"c6_11_letter_home")
	ok(rb15 != null and rb15.turn_in_npc() == "บรอกก์" and rb15.giver_name == "ผู้อาวุโสญอร์ดา", "rb15 ญอร์ดาให้ → ส่งที่บรอกก์")
	ok(c611 != null and c611.turn_in_npc() == "อิงกริด" and c611.giver_name == "นักล่าที่หายไป (ผี)", "c6_11 ผีนักล่าให้ → ส่งที่อิงกริด")
	ok(GameData.get_quest(&"c4_1_gate_of_giants").turn_in_npc() == "ผู้อาวุโสสกาดี", "เควสเดิม turn_in = คนให้")
	var tony := GameData.get_quest(&"tony_fabre")
	ok("20" in tony.dialog_progress and tony.kill_count == 20, "โทนี่: บอก 20 ตัว ตรงระบบ")
	var c49 := GameData.get_quest(&"rb9_wall_that_held_the_sky")
	ok(not ("Tempered" in c49.dialog_offer) and "ดาบฟาดทั่ง" in c49.dialog_offer, "rb9 ชื่อสกิลไทยตามเกม")
	Loc.set_locale("th")
	# 4) ฉาก NPC
	var checks := {
		"res://scenes/maps/utgard_town.tscn": {"ผู้อาวุโสสกาดี": "ตาข้าบอด"},
		"res://scenes/maps/nidavellir_town.tscn": {"บรอกก์": "...คนบนดิน"},
		"res://scenes/maps/prontera_town.tscn": {"อิงกริด": "ท่านนักผจญภัย"},
		"res://scenes/maps/eljudnir.tscn": {"นักล่าที่หายไป (ผี)": "...คนเป็น"},
		"res://scenes/maps/emberhaven.tscn": {"สวาลา ผู้เก็บชื่อ": "ยินดีต้อนรับสู่อัมเบอร์เฮเวน"},
		"res://scenes/maps/ljosalf_city.tscn": {"ทหารยามโซล": "(ยิ้มกว้าง)"},
	}
	var npcs := {}
	for path in checks:
		var ps: PackedScene = load(path)
		ok(ps != null, "โหลดฉาก " + path.get_file())
		if ps == null: continue
		var root := ps.instantiate()
		for want in checks[path]:
			var found = null
			for n in root.find_children("*", "", true, false):
				if "npc_name" in n and n.npc_name == want:
					found = n
			ok(found != null and String(found.greeting).begins_with(checks[path][want]), "%s ทักทายใหม่" % want)
			if found: npcs[want] = found
		# ไม่มี ☺ ในบทพูด
		var sm := 0
		for n in root.find_children("*", "", true, false):
			if "npc_name" in n:
				if "☺" in String(n.dialog) or "☺" in String(n.greeting): sm += 1
				for k in n.dialog_by_flag: if "☺" in String(n.dialog_by_flag[k]): sm += 1
		ok(sm == 0, "ไม่มี ☺ ใน " + path.get_file())
		root.queue_free()
	# 5) เควสข้ามเมือง: คนชวน / คนรับส่ง
	var ing = npcs.get("อิงกริด")
	var ghost = npcs.get("นักล่าที่หายไป (ผี)")
	var brokk = npcs.get("บรอกก์")
	ok(ing != null and &"c6_11_letter_home" in ing.quest_ids, "อิงกริดมี c6_11 ใน quest_ids")
	ok(ghost != null and &"c6_11_letter_home" in ghost.quest_ids, "ผีนักล่ามี c6_11")
	ok(ing.dialog_by_flag.has("ingrid_knows_truth") and brokk.dialog_by_flag.has("rb_told_brokk"), "บทพูดตามธงใหม่ อิงกริด/บรอกก์")
	ok(ghost._offers_quest(&"c6_11_letter_home") and not ing._offers_quest(&"c6_11_letter_home"), "ผีชวน · อิงกริดไม่ชวน")
	ok(ing._takes_turn_in(&"c6_11_letter_home") and not ghost._takes_turn_in(&"c6_11_letter_home"), "อิงกริดรับส่ง · ผีไม่รับส่ง")
	ok(brokk._takes_turn_in(&"rb15_song_for_brokk") and not brokk._offers_quest(&"rb15_song_for_brokk"), "บรอกก์รับส่ง rb15 ไม่ชวน")
	ok(ing._offers_quest(&"m9_missing_hunter") and ing._takes_turn_in(&"m9_missing_hunter"), "เควสเดิมของอิงกริดปกติ")
	# 6) ความคืบหน้า TALK
	var qlog = PlayerState.quests
	for pre in c611.required_quests: if not pre in qlog.completed: qlog.completed.append(pre)
	PlayerState.stats.level = 90
	ok(qlog.can_accept(&"c6_11_letter_home", 90), "c6_11 รับได้หลัง c6_4")
	qlog.accept(&"c6_11_letter_home")
	ok(not qlog.is_ready(&"c6_11_letter_home"), "ยังไม่ครบก่อนคุยอิงกริด")
	qlog.on_talked_to("อิงกริด")
	ok(qlog.is_ready(&"c6_11_letter_home"), "คุยอิงกริดแล้วครบ")
	# 7) กล่องสนทนาแปลตอนแสดง
	Loc.set_locale("en")
	var tpage := "ข้าเริ่มตีเหล็กอีกครั้งแล้ว... คราวนี้ข้าสลักเส้นคืนพลังไว้ในทุกชิ้น"
	UI.talk([{"name": "บรอกก์", "text": tpage, "choices": ["รับเควส", "ไว้ก่อน"]}])
	await get_tree().process_frame
	await get_tree().process_frame
	var box = UI.dialogue
	ok(box._full_text.begins_with("I've started forging again"), "กล่องสนทนาโชว์อังกฤษ: " + box._full_text.left(30))
	ok(box._name_label.text == "Brokk", "ชื่อผู้พูดอังกฤษ")
	box._pick(1)
	Loc.set_locale("th")
	print("== r161: %d ผ่าน %d ล้ม ==" % [passes, fails])
	get_tree().quit(1 if fails > 0 else 0)
