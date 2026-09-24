extends Node
## ★ รอบ 162 ★ ระบบภาษา: โหมดไทยต้องไทยล้วน · โหมด English แปลตรงตัว/แม่แบบ/ท่อน + สำรวจหน้าต่างทั้งหมด
var ok := 0
var bad := 0
func chk(name: String, cond: bool, extra := "") -> void:
	if cond: ok += 1
	else:
		bad += 1
		print("  ✗ ", name, "  ", extra)

func _th(s: String) -> bool:
	for ch in s:
		var c := ch.unicode_at(0)
		if c >= 0x0E00 and c <= 0x0E7F: return true
	return false

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	Loc.init()
	var lab := Label.new(); add_child(lab)
	var samples := ["ยาแดง", "ต้องเลเวล 30 ขึ้นไปถึงจะใส่ ดาบสั้น ได้ (ตอนนี้ Lv.12)", "อิกดราซิล ชั้น 73", "การ์ดโพริง", "ยาแดง x3", "ซื้อ", "ข้าไม่ได้อยากให้เจ้าทำลายทะเบียนนั่น ข้าอยากได้ชื่อของคนในนั้น"]
	# ---- โหมดไทย ----
	Loc.set_locale("th")
	chk("TH on_off", Loc.on_off(false) == "ปิด")
	for s in samples:
		chk("TH ไม่แปล: " + s, String(lab.atr(s)) == s, String(lab.atr(s)))
		chk("TH Loc.t: " + s, Loc.t(s) == s)
	# ---- โหมด English ----
	Loc.set_locale("en")
	var want := {"ยาแดง": "Red Potion", "อิกดราซิล ชั้น 73": "Yggdrasil Floor 73", "การ์ดโพริง": "Poring Card", "ยาแดง x3": "Red Potion x3",
		"ต้องเลเวล 30 ขึ้นไปถึงจะใส่ ดาบสั้น ได้ (ตอนนี้ Lv.12)": "Requires Level 30 or higher to equip Short Sword (currently Lv.12)",
		"ร้านของพ่อค้าโทนี่": "Shop of Tony the Merchant", "โล่การ์ด": "Guard", "Monsters Lv.1-6  ·  ล่าแล้ว 0/3 ชนิด": "Monsters Lv.1-6  ·  Hunted 0/3 species",
		"อิกดราซิล ชั้น 100": "Yggdrasil Floor 100", "บันทึกเมื่อ 24 ก.ย. 2569 · 02:54": "Saved 24 Sep 2026 · 02:54"}
	chk("EN on_off", Loc.on_off(false) == "Off" and Loc.on_off(true) == "On")
	for s in want:
		var got := String(lab.atr(s))
		chk("EN " + s, got == want[s], got)
	for s in samples:
		chk("EN ไม่เหลือไทย: " + s, not _th(Loc.t(s)), Loc.t(s))
	var rtl := RichTextLabel.new(); rtl.bbcode_enabled = true; rtl.text = "[b]ยาแดง[/b]\nฟื้นฟู HP"; add_child(rtl)
	await get_tree().process_frame
	print("  RTL: ", rtl.get_parsed_text().replace("\n", " | "))
	chk("EN RichTextLabel แปล", not _th(rtl.get_parsed_text().split("\n")[0]), rtl.get_parsed_text())
	# ---- สำรวจทุกหน้าต่างในโหมด English ----
	var left := {}
	var total := 0
	for id in UI.windows.keys():
		UI.open(id)
		await get_tree().process_frame
		await get_tree().process_frame
	await get_tree().process_frame
	var th_after_switch := []
	for n in _all(UI.layer):
		var shown := ""
		if n is RichTextLabel: shown = n.get_parsed_text()
		elif n is Label or n is Button: shown = String(n.atr(n.text))
		else: continue
		if shown == "" or not n.is_visible_in_tree(): continue
		total += 1
		if _th(shown):
			for ln in shown.split("\n"):
				if _th(ln):
					left[ln.substr(0, 100)] = true
					print("    RAW[", n.get_class(), "]: ", String(n.text).substr(0, 300).replace("\n", " ⏎ "))
	print("  หน้าต่างที่เปิด: ", UI.windows.keys().size(), " · ข้อความที่เห็น ", total, " · ยังมีไทย ", left.size())
	for k in left.keys().slice(0, 40): print("    ไทย: ", k)
	chk("EN หน้าต่าง: ไทยเหลือไม่เกิน 3%", left.size() * 100 <= total * 3 + 1, "%d/%d" % [left.size(), total])
	# ---- กลับไทย: ทุกหน้าต่างต้องไม่มีอังกฤษที่มาจากคำแปล ----
	Loc.set_locale("th")
	await get_tree().process_frame
	var leaked := 0
	for n in _all(UI.layer):
		if n is Label or n is Button:
			if String(n.atr(n.text)) != String(n.text): leaked += 1
	chk("TH หน้าต่าง: ไม่มีคำแปลรั่ว", leaked == 0, str(leaked))
	# ---- แมพจริง 3 เมือง: HUD + ชื่อ NPC + ป้าย (ทั้งต้นไม้) ----
	for n in UI.windows.keys(): UI.close(n)
	var dummy := Node.new(); get_tree().root.add_child(dummy); get_tree().current_scene = dummy   # ให้ตัวเทสต์รอดตอนเปลี่ยนแมพ
	for mid in [&"prontera_town", &"vanir_town", &"emberhaven"]:
		Loc.set_locale("en")
		Game.change_map(mid)
		for i in 30: await get_tree().process_frame
		var guard := 0
		while Game._is_changing and guard < 900:
			await get_tree().process_frame
			guard += 1
		for i in 20: await get_tree().process_frame
		var seen := 0
		var th_left := {}
		for n in _all(get_tree().root):
			var shown := ""
			if n is RichTextLabel: shown = n.get_parsed_text()
			elif n is Label or n is Button: shown = String(n.atr(n.text))
			else: continue
			if shown == "" or not n.is_visible_in_tree(): continue
			seen += 1
			for ln in shown.split("\n"):
				if _th(ln): th_left[ln.substr(0, 90)] = true
		print("  แมพ ", mid, ": ข้อความ ", seen, " · ไทยค้าง ", th_left.size())
		for k in th_left.keys().slice(0, 8): print("    ไทย: ", k)
		chk("EN แมพ " + String(mid) + " ไม่มีไทยค้าง", th_left.size() == 0, str(th_left.keys().slice(0, 3)))
		Loc.set_locale("th")
		await get_tree().process_frame
		var leak := 0
		for n in _all(get_tree().root):
			if (n is Label or n is Button) and String(n.atr(n.text)) != String(n.text): leak += 1
		chk("TH แมพ " + String(mid) + " ไม่มีอังกฤษรั่ว", leak == 0, str(leak))
	var lt: LocTranslation = Loc._tr[0] if not Loc._tr.is_empty() else null
	chk("LocTranslation สร้างแล้ว", lt != null)
	if lt: print("  แม่แบบ: ", lt.template_count())
	print("== r162: %d ผ่าน %d ล้ม ==" % [ok, bad])
	get_tree().quit()

func _all(root: Node) -> Array:
	var out := [root]
	for c in root.get_children(): out.append_array(_all(c))
	return out
