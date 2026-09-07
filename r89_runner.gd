extends Node
## ★ เทสต์รอบ 89 — เชื่อมภาพการ์ดเข้ากับไฟล์การ์ด ★

const ART_DIR := "res://Sprites/card/"
const CARD_DIR := "res://data/cards/"


func run() -> void:
	var score := [0, 0]
	var check := func(n: String, c: bool, e: String = "") -> void:
		if c: score[0] += 1
		else:
			score[1] += 1
			print("  x FAIL: ", n, " ", e)

	# =========================================================
	# 1) ไฟล์การ์ดโหลดได้ครบ
	# =========================================================
	print("\n-- 1) โหลดไฟล์การ์ด --")
	var names: PackedStringArray = []
	var da := DirAccess.open(CARD_DIR)
	check.call("เปิดโฟลเดอร์การ์ดได้", da != null)
	if da == null:
		print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
		get_tree().quit()
		return
	for f in da.get_files():
		if f.ends_with(".tres"):
			names.append(f.get_basename())
	names.sort()
	check.call("มีการ์ดครบ 30 ใบ", names.size() == 30, "%d" % names.size())

	var cards: Dictionary = {}
	var bad_load: PackedStringArray = []
	for n in names:
		var c: Resource = load(CARD_DIR + n + ".tres")
		if c == null or not (c is CardData):
			bad_load.append(n)
		else:
			cards[n] = c
	check.call("★ ทุกใบโหลดเป็น CardData ได้ ★", bad_load.is_empty(), ", ".join(bad_load))

	# =========================================================
	# 2) ภาพการ์ดในโฟลเดอร์ Sprites/card ถูกเชื่อมครบ
	# =========================================================
	print("\n-- 2) ภาพถูกเชื่อมครบ --")
	var arts: PackedStringArray = []
	var ad := DirAccess.open(ART_DIR)
	check.call("เปิดโฟลเดอร์ภาพการ์ดได้", ad != null)
	if ad != null:
		for f in ad.get_files():
			# ตอนรันจากไฟล์ที่ import แล้ว นามสกุลจะเป็น .webp ตรง ๆ
			if f.ends_with(".webp"):
				arts.append(f.get_basename())
	arts.sort()
	print("  ภาพการ์ดที่เจอ: %d ไฟล์" % arts.size())
	check.call("มีภาพการ์ดอย่างน้อย 20 ไฟล์", arts.size() >= 20, "%d" % arts.size())

	var not_linked: PackedStringArray = []
	var wrong_path: PackedStringArray = []
	for a in arts:
		if not cards.has(a):
			not_linked.append(a + " (ไม่มีไฟล์การ์ด)")
			continue
		var c: CardData = cards[a]
		if c.illustration == null:
			not_linked.append(a)
			continue
		var p: String = c.illustration.resource_path
		if p != ART_DIR + a + ".webp":
			wrong_path.append("%s → %s" % [a, p])
	check.call("★ ภาพทุกไฟล์ถูกเชื่อมเข้ากับการ์ดของตัวเอง ★", not_linked.is_empty(), ", ".join(not_linked))
	check.call("★ ชี้ไปที่ไฟล์ภาพถูกใบ ★", wrong_path.is_empty(), ", ".join(wrong_path))

	# =========================================================
	# 3) ไม่มีใบไหนค้างภาพชั่วคราวทั้งที่มีภาพจริงแล้ว
	# =========================================================
	print("\n-- 3) ไม่ค้างภาพชั่วคราว --")
	var ph_illu: PackedStringArray = []
	var ph_icon: PackedStringArray = []
	var no_art_yet: PackedStringArray = []
	for n in cards.keys():
		var c: CardData = cards[n]
		var has_art: bool = arts.has(n)
		if c.illustration != null and "/placeholder/" in c.illustration.resource_path:
			ph_illu.append(n)
		if c.icon != null and "/placeholder/" in c.icon.resource_path:
			# ใบที่ยังไม่มีภาพการ์ดจริง (มอนบท 3 ที่ยังไม่ได้วาด) ใช้ภาพชั่วคราวได้
			if has_art: ph_icon.append(n)
			else: no_art_yet.append(n)
	check.call("ไม่มีใบไหนใช้ภาพการ์ดชั่วคราว", ph_illu.is_empty(), ", ".join(ph_illu))
	check.call("★ ใบที่มีภาพจริงแล้ว ไม่ค้างไอคอนชั่วคราว ★", ph_icon.is_empty(), ", ".join(ph_icon))
	no_art_yet.sort()
	print("  ยังไม่มีภาพการ์ด %d ใบ (รอวาด): %s" % [no_art_yet.size(), ", ".join(no_art_yet)])

	# =========================================================
	# 4) ทุกใบมีรูปโชว์ (ระบบไล่ illustration → icon → รูปมอน)
	# =========================================================
	print("\n-- 4) ทุกใบมีรูปโชว์ --")
	var no_tex: PackedStringArray = []
	var from_illu := 0
	var from_icon := 0
	var from_mon := 0
	for n in names:
		if not cards.has(n):
			continue
		var c: CardData = cards[n]
		var t: Texture2D = CardView.card_texture(c)
		if t == null:
			no_tex.append(n)
		elif c.illustration != null:
			from_illu += 1
		elif c.icon != null:
			from_icon += 1
		else:
			from_mon += 1
	check.call("★ ทุกใบได้รูปมาโชว์ (ไม่มีช่องว่าง) ★", no_tex.is_empty(), ", ".join(no_tex))
	print("  ใช้ภาพการ์ด %d · ใช้ไอคอน %d · ดึงรูปมอน %d" % [from_illu, from_icon, from_mon])
	check.call("อย่างน้อย 20 ใบใช้ภาพการ์ดชุดใหม่", from_illu >= 20, "%d" % from_illu)

	# =========================================================
	# 5) ข้อมูลการ์ดยังครบเหมือนเดิม (แก้ไฟล์แล้วไม่ทำของหาย)
	# =========================================================
	print("\n-- 5) ข้อมูลการ์ดไม่หาย --")
	var no_id: PackedStringArray = []
	var no_name: PackedStringArray = []
	var no_mon: PackedStringArray = []
	var bad_rarity: PackedStringArray = []
	for n in names:
		if not cards.has(n):
			continue
		var c: CardData = cards[n]
		if String(c.id) == "": no_id.append(n)
		if c.display_name.strip_edges() == "": no_name.append(n)
		if String(c.monster_id) == "": no_mon.append(n)
		if c.rarity < 1 or c.rarity > 5: bad_rarity.append(n)
	check.call("ทุกใบมีรหัสไอเทม", no_id.is_empty(), ", ".join(no_id))
	check.call("ทุกใบมีชื่อ", no_name.is_empty(), ", ".join(no_name))
	check.call("ทุกใบผูกกับมอนสเตอร์", no_mon.is_empty(), ", ".join(no_mon))
	check.call("ระดับความหายากอยู่ในช่วง 1-5", bad_rarity.is_empty(), ", ".join(bad_rarity))

	# ตัวอย่างใบที่ผู้ใช้ทำค้างไว้ + ใบที่มีไอคอนเดิม
	var s: CardData = cards.get("card_stormscar")
	check.call("อสูรสายฟ้า: ชี้ภาพถูก", s != null and s.illustration != null
		and s.illustration.resource_path == ART_DIR + "card_stormscar.webp")
	check.call("อสูรสายฟ้า: ยังเป็นการ์ดหายาก 4", s != null and s.rarity == 4)
	var w: CardData = cards.get("card_wolf")
	check.call("หมาป่า (ใบที่ทำไว้ก่อนแล้ว) ยังชี้ภาพถูก", w != null and w.illustration != null
		and w.illustration.resource_path == ART_DIR + "card_wolf.webp")

	# =========================================================
	# 6) การ์ดยังใช้งานได้จริง (ลงทะเบียนใน GameData · ใส่ช่องได้)
	# =========================================================
	print("\n-- 6) ยังใช้งานได้จริง --")
	var missing_reg: PackedStringArray = []
	for n in names:
		if not cards.has(n):
			continue
		var c: CardData = cards[n]
		var got: ItemData = GameData.get_item(c.id)
		if got == null:
			missing_reg.append(String(c.id))
	check.call("★ การ์ดทุกใบยังลงทะเบียนใน GameData ★", missing_reg.is_empty(), ", ".join(missing_reg))

	var reg: ItemData = GameData.get_item(&"card_stormscar")
	check.call("ดึงการ์ดจาก GameData ได้เป็น CardData", reg is CardData)
	if reg is CardData:
		var rc: CardData = reg
		check.call("การ์ดจาก GameData มีภาพแล้ว", rc.illustration != null)
		check.call("การ์ดจาก GameData ยังบอกช่องที่ใส่ได้", rc.slot_name() != "-",
			"%d" % rc.fits_slot)

	# วาดการ์ดจริงบนจอ — ยืนยันว่า CardView ไม่พัง
	var cv := CardView.new()
	add_child(cv)
	await get_tree().process_frame
	cv.show_card(cards["card_stormscar"], true)
	await get_tree().process_frame
	var art: TextureRect = _find_texture_rect(cv)
	check.call("★ CardView วาดแล้วมีรูปติดอยู่จริง ★", art != null and art.texture != null)
	if art != null and art.texture != null:
		check.call("รูปบน CardView คือภาพการ์ดใบนั้น",
			art.texture.resource_path == ART_DIR + "card_stormscar.webp",
			art.texture.resource_path)
	cv.queue_free()

	print("\n== รวม: ผ่าน %d · ล้มเหลว %d ==" % score)
	get_tree().quit()


func _find_texture_rect(n: Node) -> TextureRect:
	if n is TextureRect:
		return n
	for c in n.get_children():
		var r := _find_texture_rect(c)
		if r != null:
			return r
	return null
