extends Node
## ★ เทสต์รอบ 90 — มอนโหลดตอนใช้จริง · หน่วยความจำภาพ · เรียงการ์ดไม่โหลดมอน ★

func _tex_mb() -> float:
	return Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0


func _settle() -> void:
	for i in 8:
		await get_tree().process_frame


var _has_gpu := true

func run() -> void:
	var score := [0, 0]
	var check := func(n: String, c: bool, e: String = "") -> void:
		if c: score[0] += 1
		else:
			score[1] += 1
			print("  x FAIL: ", n, " ", e)

	# =========================================================
	# 1) เปิดเกมแล้วยังไม่มีมอนตัวไหนถูกโหลด
	# =========================================================
	print("\n-- 1) ตอนเปิดเกม --")
	await _settle()
	var boot_mb := _tex_mb()
	# --headless ไม่มีตัวเรนเดอร์ ตัววัดจะคืน 0 เสมอ → ข้อสอบเรื่องหน่วยความจำจะข้ามไป
	# (ตรรกะแคช/การปล่อย ยังถูกตรวจครบทุกข้อ)
	_has_gpu = boot_mb > 0.0
	print("  หน่วยความจำภาพตอนเปิดเกม %.1f MB%s" % [boot_mb, "" if _has_gpu else "  (โหมด headless — ข้อสอบหน่วยความจำถูกข้าม)"])
	check.call("★ ยังไม่มีมอนตัวไหนถูกโหลด ★", GameData.monsters.is_empty(),
		"โหลดไปแล้ว %d ตัว" % GameData.monsters.size())
	check.call("รู้จักมอนครบ 30 ตัว (จากชื่อไฟล์ ไม่ต้องเปิดไฟล์)", GameData.monster_ids().size() == 30,
		"%d" % GameData.monster_ids().size())
	check.call("★ หน่วยความจำภาพตอนเปิดเกมต่ำกว่า 400 MB ★", not _has_gpu or boot_mb < 400.0, "%.1f MB" % boot_mb)

	# =========================================================
	# 2) เรียกใช้แล้วค่อยโหลด · โหลดแล้วจำไว้
	# =========================================================
	print("\n-- 2) โหลดตอนเรียกใช้ --")
	var w: MonsterData = GameData.get_monster(&"wolf")
	await _settle()
	var after_one := _tex_mb()
	check.call("ขอหมาป่าแล้วได้ข้อมูลมา", w != null)
	check.call("ได้ตัวที่ขอจริง (id ตรง)", w != null and w.id == &"wolf", "%s" % (w.id if w else "null"))
	check.call("★ โหลดแล้วกินหน่วยความจำภาพเพิ่มขึ้นจริง ★", not _has_gpu or after_one > boot_mb,
		"%.1f → %.1f MB" % [boot_mb, after_one])
	check.call("จำไว้ในแคชแล้ว", GameData.monsters.has(&"wolf"))
	check.call("มีมอนในแคชแค่ตัวเดียว", GameData.monsters.size() == 1, "%d" % GameData.monsters.size())

	var w2: MonsterData = GameData.get_monster(&"wolf")
	check.call("ขอซ้ำได้ตัวเดิม (ไม่โหลดใหม่)", w2 == w)
	print("  หมาป่าตัวเดียวใช้ %.1f MB" % (after_one - boot_mb))

	# =========================================================
	# 3) ขอมอนที่ไม่มี — ต้องไม่พังและไม่ไปโหลดทั้งโฟลเดอร์ซ้ำ ๆ
	# =========================================================
	print("\n-- 3) ขอมอนที่ไม่มี --")
	var before_miss := GameData.monsters.size()
	var none: MonsterData = GameData.get_monster(&"ไม่มีตัวนี้จริง ๆ")
	check.call("ขอมอนที่ไม่มี ได้ null (ไม่พัง)", none == null)
	# ★ สำคัญ ★ ห้ามไปไล่โหลดทั้งโฟลเดอร์ (เคยเป็นบั๊ก — พิมพ์ id ผิดทีเดียวกินไป 1.4 GB)
	check.call("★ ขอ id ที่ไม่มี ต้องไม่ไปโหลดมอนตัวอื่นเลย ★",
		GameData.monsters.size() == before_miss,
		"แคชโตจาก %d เป็น %d" % [before_miss, GameData.monsters.size()])

	# =========================================================
	# 4) คืนหน่วยความจำตอนเปลี่ยนแมพ
	# =========================================================
	print("\n-- 4) คืนหน่วยความจำ --")
	GameData.get_monster(&"poring")
	GameData.get_monster(&"fabre")
	await _settle()
	var three := _tex_mb()
	check.call("ตอนนี้มี 3 ตัวในแคช", GameData.monsters.size() == 3, "%d" % GameData.monsters.size())

	var dropped: int = GameData.release_monsters_except([&"wolf"])
	await _settle()
	var after_rel := _tex_mb()
	check.call("ปล่อยไป 2 ตัว", dropped == 2, "%d" % dropped)
	check.call("เหลือหมาป่าตัวเดียวในแคช", GameData.monsters.size() == 1 and GameData.monsters.has(&"wolf"))
	check.call("★ หน่วยความจำภาพลดลงจริงหลังปล่อย ★", not _has_gpu or after_rel < three,
		"%.1f → %.1f MB" % [three, after_rel])
	print("  ปล่อย 2 ตัวคืนมา %.1f MB" % (three - after_rel))

	GameData.release_monsters_except([])
	await _settle()
	check.call("ปล่อยหมดแล้วแคชว่าง", GameData.monsters.is_empty())

	# =========================================================
	# 5) สมุดการ์ดเรียงลำดับได้โดยไม่โหลดมอน  ★ หัวใจของรอบนี้ ★
	# =========================================================
	print("\n-- 5) เรียงการ์ดไม่โหลดมอน --")
	var before_cards := _tex_mb()
	var all_cards: Array = GameData.all_cards()
	await _settle()
	var after_cards := _tex_mb()
	check.call("ได้การ์ดครบ 30 ใบ", all_cards.size() == 30, "%d" % all_cards.size())
	check.call("★ เรียงการ์ดแล้วไม่มีมอนตัวไหนถูกโหลด ★", GameData.monsters.is_empty(),
		"โหลดไป %d ตัว" % GameData.monsters.size())
	check.call("★ หน่วยความจำภาพไม่เพิ่มขึ้นเลย ★", not _has_gpu or after_cards - before_cards < 1.0,
		"เพิ่ม %.1f MB" % (after_cards - before_cards))

	# ยังเรียงจากน้อยไปมากถูกต้องเหมือนเดิม
	var ordered := true
	var last := -1
	for c: CardData in all_cards:
		var lv: int = c.sort_level()
		if lv < last:
			ordered = false
		last = lv
	check.call("เรียงจากเลเวลน้อยไปมากถูกต้อง", ordered)

	# =========================================================
	# 6) เลเวลบนการ์ดตรงกับเลเวลมอนจริง (fill_card_levels.py)
	# =========================================================
	print("\n-- 6) เลเวลบนการ์ดตรงกับมอนจริง --")
	var no_level: PackedStringArray = []
	var wrong: PackedStringArray = []
	for c: CardData in all_cards:
		if c.monster_level <= 0:
			no_level.append(String(c.id))
			continue
		var m: MonsterData = GameData.get_monster(c.monster_id)
		if m != null and m.level != c.monster_level:
			wrong.append("%s: การ์ด %d แต่มอน %d" % [c.id, c.monster_level, m.level])
	check.call("★ ทุกใบมีเลเวลเก็บไว้แล้ว ★", no_level.is_empty(), ", ".join(no_level))
	check.call("★ เลเวลบนการ์ดตรงกับเลเวลมอนทุกใบ ★", wrong.is_empty(), " · ".join(wrong))
	GameData.release_monsters_except([])
	await _settle()

	# =========================================================
	# 7) หน้าที่ต้องเห็นมอนครบ ยังเห็นครบ
	# =========================================================
	print("\n-- 7) บังคับโหลดครบ (ห้อง GM) --")
	var all_m: Dictionary = GameData.load_all_monsters()
	await _settle()
	check.call("โหลดครบ 30 ตัว", all_m.size() == 30, "%d" % all_m.size())
	# ★ ตรวจกฎ "ชื่อไฟล์ = id" จากไฟล์จริง ★ ระบบไม่มีทางถอยแล้ว ถ้าผิดกฎมอนตัวนั้นจะหาย
	var bad_name: PackedStringArray = []
	for mid: StringName in GameData.monster_ids():
		var m: MonsterData = GameData.get_monster(mid)
		if m == null:
			bad_name.append("%s (โหลดไม่ได้)" % mid)
		elif m.id != mid:
			bad_name.append("%s.tres มี id=%s" % [mid, m.id])
	check.call("★ ชื่อไฟล์ = id ครบทุกตัว (กฎบังคับของระบบโหลดตอนใช้) ★",
		bad_name.is_empty(), " · ".join(bad_name))
	var full := _tex_mb()
	print("  โหลดครบ 30 ตัว = %.1f MB (มากกว่าตอนเปิดเกม %.0f เท่า)" % [full, full / maxf(1.0, boot_mb)])
	check.call("★ พิสูจน์ว่าของเดิมกินหนักจริง: ครบ 30 ตัวหนักกว่าตอนเปิดเกมอย่างน้อย 3 เท่า ★",
		not _has_gpu or full > boot_mb * 3.0, "%.1f vs %.1f MB" % [full, boot_mb])

	GameData.release_monsters_except([])
	await _settle()
	var back := _tex_mb()
	check.call("★ ปล่อยแล้วกลับมาใกล้เคียงตอนเปิดเกม ★", not _has_gpu or back < boot_mb * 1.35,
		"%.1f (เปิดเกม %.1f) MB" % [back, boot_mb])

	# =========================================================
	# 8) แคชแมพลดลง (ไม่ให้ชีทมอนค้างหลายแมพ)
	# =========================================================
	print("\n-- 8) แคชแมพ --")
	check.call("แคชแมพบนคอมเหลือ 2", Game.MAX_CACHED_DESKTOP == 2, "%d" % Game.MAX_CACHED_DESKTOP)
	check.call("★ บนเว็บไม่แคชแมพเลย ★", Game.MAX_CACHED_WEB == 0, "%d" % Game.MAX_CACHED_WEB)

	print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
	get_tree().quit()
