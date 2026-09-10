## SpriteFit — วัด "ขอบภาพจริง" ของ SpriteFrames ครั้งเดียวทั้งเกม (รอบ 44)
##
## ทำไมต้องมี: ระบบ auto-fit ของผู้เล่น/มอน ต้องรู้ว่าในแต่ละเฟรม ตัวละครอยู่ตรงไหนของผ้าใบ
## (ตัดพื้นที่โปร่งใสทิ้ง) → ต้องเรียก Texture2D.get_image() ซึ่ง "ดึงภาพกลับจากการ์ดจอ"
## ช้ามาก (หลาย ms ต่อเฟรมภาพ) และเดิมทำใหม่ทุกครั้งที่มอนเกิด / ผู้เล่นถูกสร้างใหม่หลังเปลี่ยนแมพ
## = เกมกระตุกทุกครั้งที่มอนเกิดหรือเล่นท่าใหม่ครั้งแรก
##
## ตอนนี้: จำผลไว้ตรงกลาง (static) คีย์ = path ของ SpriteFrames + ชื่อท่า
## วัดครั้งเดียวตลอดการรันเกม และ map_base อุ่นเครื่องล่วงหน้าตอนโหลดแมพ (ระหว่างจอมืด)
class_name SpriteFit
extends RefCounted

## เฟรมที่ขอบต่างจากค่ากลางของท่าไม่เกินนี้ (พิกเซลในภาพต้นฉบับ) ถือว่าเป็น "ขอบเบลอ/เงา" ใช้ค่ากลางแทน
const SNAP := 12.0

## ★★ รอบ 94 ★★ วัด "ลำตัว" แยกจาก "อาวุธ"
##
## ปัญหา: auto-fit เดิมคิดสเกลจาก "ความสูงของทุกอย่างที่วาด" ซึ่งรวมดาบที่ชูขึ้นด้วย
## ท่าที่ชูดาบสูงจะถูกย่อลงทั้งตัว → ตัวละครโต/เล็กสลับไปมาระหว่างคอมโบ
## (วัดจริงจากท่าฟันชุดใหม่: ลำตัวบนจอแกว่ง 189-235 px ทั้งที่ควรเท่ากันหมด)
##
## แก้: นับพิกเซลทึบทีละแถว — แถวที่กว้างเกิน BODY_ROW_RATIO ของ "แถวค่ากลาง" = "ลำตัว"
## ดาบเป็นเส้นบาง ๆ กินไม่กี่พิกเซลต่อแถว จึงถูกคัดออกเอง
##
## ★★ รอบ 97 ★★ เทียบกับ "แถวค่ากลาง (median)" ไม่ใช่ "แถวกว้างสุด"
## บั๊กรอบ 94: เกณฑ์เดิมคิดจากแถวกว้างสุด — แต่ในท่ายืนถือดาบ (Idle_blade) แถวกว้างสุดคือ
## "แถวที่ดาบยื่นออกไปในแนวนอน" (กว้าง 3 เท่าของลำตัว) → เกณฑ์สูงเกิน → **เท้าหลัง**
## (แคบกว่าดาบมาก) ตกเกณฑ์ → ลำตัวท่ายืนถูกวัดขาดไป 69 px (519 แทน 588 = -12%)
## ท่าฟันกางขากว้าง เท้าผ่านเกณฑ์ → วัดครบ → ท่าฟันเลยถูกย่อให้ "เท่ากับลำตัวที่วัดขาด"
## = ตัวละครเล็กลง ~10% ทุกครั้งที่ฟัน (ที่ผู้ใช้เห็นว่า "ท่าฟันโดนลดไซส์")
## แถวค่ากลางคือความกว้างลำตัวปกติ ดาบยื่นกี่แถวก็ไม่ดึงเกณฑ์ขึ้น
const BODY_ROW_RATIO := 0.25
## สแกนแบบข้ามพิกเซล (เร็วขึ้นราว 9 เท่า) — ละเอียดพอสำหรับหาขอบลำตัว
const BODY_SCAN_STEP := 3
## แถวที่ทึบน้อยกว่านี้ถือว่าเป็นเงา/ขอบเบลอ ไม่ใช่เนื้อภาพ
const BODY_MIN_ROW_PIXELS := 2

static var _cache: Dictionary = {}
static var measured_count: int = 0   # ไว้ดูสถิติ/เทสต์
static var decompressed_count: int = 0   # ★ รอบ 92 ★ นับชีทที่ต้องคลายบีบอัดก่อนวัด (ไว้ดูสถิติ/เทสต์)


## ★★ รอบ 92 ★★ ดึงภาพของเฟรมมาแบบที่ "อ่านพิกเซลได้แน่นอน"
##
## ปัญหา: ภาพที่ import เป็น VRAM Compressed (compress/mode=2 — BC7/S3TC/ETC2 ที่ตั้งให้เวอร์ชันคอมรอบ 90)
##   · Image.get_used_rect() บนภาพบีบอัด อ่านพิกเซลไม่ได้ → คืน "ทั้งผืน" แทนขอบตัวจริง
##   · AtlasTexture.get_image() ที่ต้องตัด region จากผืนบีบอัด → คืน null ไปเลย
##   ทั้งสองทางทำให้ทุกท่าถูกวัดว่าสูงเท่าช่องภาพ (512) → สเกลผิด เท้าลอย/จม ต่างกันไปทีละท่า
##
## แก้: ถ้าเป็น AtlasTexture ให้ดึง "ผืนเต็ม" มาคลายบีบอัดก่อน แล้วค่อยตัด region เอง (ของเดิม engine ขึ้น "Cannot blit_rect in compressed image" แล้วคืนภาพว่าง)
## ผืนที่คลายแล้วเก็บไว้แค่ระหว่างวัดท่าเดียว (atlas_pool) ไม่ค้างในหน่วยความจำ
## (ชีท 4096x2048 คลายแล้ว = 32 MB — ถ้าเก็บทุกชีทไว้จะกินแรมหลาย GB)
static func _frame_image(tex: Texture2D, atlas_pool: Dictionary) -> Image:
	if tex is AtlasTexture:
		var at: AtlasTexture = tex
		if at.atlas == null:
			return null
		var key := at.atlas.get_rid()
		var base: Image = atlas_pool.get(key)
		if base == null:
			base = at.atlas.get_image()
			if base == null:
				return null
			if base.is_compressed():
				base.decompress()
				decompressed_count += 1
			atlas_pool[key] = base
		var reg := Rect2i(at.region)
		if reg.size.x <= 0 or reg.size.y <= 0:
			return null
		# กันขอบ region ล้นผืน (ไฟล์ท่าทางที่ถูกย่อแล้วพิกัดปัดเศษ)
		reg = reg.intersection(Rect2i(0, 0, base.get_width(), base.get_height()))
		if reg.size.x <= 0 or reg.size.y <= 0:
			return null
		return base.get_region(reg)
	var img := tex.get_image()
	if img != null and img.is_compressed():
		img.decompress()
		decompressed_count += 1
	return img


## สแกนหา "ขอบบน-ล่างของลำตัว" และ "ปลายอาวุธยื่นไปข้างหน้าไกลแค่ไหน" ของเฟรมเดียว
## คืน {} ถ้าอ่านไม่ได้ · พิกัดอยู่ในระบบพิกัดของเฟรมนั้น (0 = ขอบบนของเฟรม)
static func _scan_body(img: Image) -> Dictionary:
	if img == null:
		return {}
	if img.is_compressed():
		img.decompress()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	if w <= 0 or h <= 0:
		return {}
	var data := img.get_data()
	var step := BODY_SCAN_STEP
	var row_count := PackedInt32Array()
	var row_max_x := PackedInt32Array()
	var row_min_x := PackedInt32Array()
	var ys := PackedInt32Array()
	var best_row := 0
	for y in range(0, h, step):
		var n := 0
		var lo := -1
		var hi := -1
		var base := y * w
		for x in range(0, w, step):
			if data[(base + x) * 4 + 3] > 20:     # ช่องอัลฟาของพิกเซล (x, y)
				n += 1
				if lo < 0:
					lo = x
				hi = x
		if n >= BODY_MIN_ROW_PIXELS:
			ys.append(y)
			row_count.append(n)
			row_min_x.append(lo)
			row_max_x.append(hi)
			best_row = maxi(best_row, n)
	if ys.is_empty() or best_row <= 0:
		return {}

	# ---------- ★ รอบ 97 ★ กรอบที่มองเห็นจริง (alpha > 20) — สแกนหยาบแล้วเก็บขอบให้เป๊ะ ----------
	var vis_top: int = ys[0]
	var vis_bot: int = ys[ys.size() - 1]
	var vis_lo: int = w
	var vis_hi: int = 0
	for i in range(ys.size()):
		vis_lo = mini(vis_lo, row_min_x[i])
		vis_hi = maxi(vis_hi, row_max_x[i])
	# ขอบบน/ล่าง: ไล่แถวเต็มความละเอียดในช่วง ±step รอบขอบหยาบ
	var t := vis_top
	for y in range(maxi(0, vis_top - step + 1), vis_top):
		if _row_has_alpha(data, w, y, 0, w):
			t = y
			break
	var b := vis_bot
	for y in range(mini(h - 1, vis_bot + step - 1), vis_bot, -1):
		if _row_has_alpha(data, w, y, 0, w):
			b = y
			break
	var l := vis_lo
	for x in range(maxi(0, vis_lo - step + 1), vis_lo):
		if _col_has_alpha(data, w, x, t, b):
			l = x
			break
	var rgt := vis_hi
	for x in range(mini(w - 1, vis_hi + step - 1), vis_hi, -1):
		if _col_has_alpha(data, w, x, t, b):
			rgt = x
			break
	var vis_rect := Rect2i(l, t, rgt - l + 1, b - t + 1)

	# ---------- ลำตัว = แถวที่กว้างพอ (ดาบบาง ๆ ตกเกณฑ์ไปเอง) ----------
	# ★ รอบ 97 ★ เกณฑ์คิดจาก "แถวค่ากลาง" ไม่ใช่แถวกว้างสุด (ดูคำอธิบายบนหัวไฟล์)
	var sorted_counts := row_count.duplicate()
	sorted_counts.sort()
	var median_row: int = sorted_counts[sorted_counts.size() >> 1]
	var need := maxf(1.0, float(median_row) * BODY_ROW_RATIO)
	var b_top := -1
	var b_bot := -1
	var b_lo := w
	var b_hi := 0
	for i in range(ys.size()):
		if float(row_count[i]) < need:
			continue
		if b_top < 0:
			b_top = ys[i]
		b_bot = ys[i]
		b_lo = mini(b_lo, row_min_x[i])
		b_hi = maxi(b_hi, row_max_x[i])
	if b_top < 0:
		return {}

	# ---------- ★ รอบ 97 ★ กึ่งกลางลำตัวจริง = ค่ากลางของ "กึ่งกลางแต่ละแถวลำตัว" ----------
	# (b_lo+b_hi)/2 ยังโดนดาบดึง เพราะแถวที่ดาบยื่นแนวนอนก็เป็นแถวลำตัว → ใช้ค่ากลางของทุกแถวแทน
	# แถวที่มีดาบยื่นมีไม่กี่แถว ดึงค่ากลางไม่ได้
	var centers: PackedFloat32Array = PackedFloat32Array()
	for i in range(ys.size()):
		if float(row_count[i]) >= need:
			centers.append(float(row_min_x[i] + row_max_x[i]) * 0.5)
	centers.sort()
	var body_cx_med: float = centers[centers.size() >> 1] if not centers.is_empty() else float(b_lo + b_hi) * 0.5

	# ---------- ปลายอาวุธยื่นพ้นกึ่งกลางลำตัวไปทางขวาไกลสุดเท่าไหร่ ----------
	var body_cx := float(b_lo + b_hi) * 0.5
	var far := 0.0
	for i in range(ys.size()):
		far = maxf(far, float(row_max_x[i]) - body_cx)

	return {
		"body_h": float(b_bot + step - b_top),
		"reach": far,
		"rect": vis_rect,
		"body_cx": body_cx_med,
	}


static func _row_has_alpha(data: PackedByteArray, w: int, y: int, x0: int, x1: int) -> bool:
	var base := y * w
	for x in range(x0, x1):
		if data[(base + x) * 4 + 3] > 20:
			return true
	return false


static func _col_has_alpha(data: PackedByteArray, w: int, x: int, y0: int, y1: int) -> bool:
	for y in range(y0, y1 + 1):
		if data[(y * w + x) * 4 + 3] > 20:
			return true
	return false


static func _key(frames: SpriteFrames, anim: StringName) -> String:
	# ★ ห้ามใช้ instance id ของ SpriteFrames ★ player_frames.tres ตั้ง resource_local_to_scene
	# → ผู้เล่นทุกตัวที่ถูกสร้าง (ทุกครั้งที่เปลี่ยนแมพ) ได้สำเนา SpriteFrames ใหม่ path ว่าง
	# ใช้ "ภาพเฟรมแรก + จำนวนเฟรม" เป็นตัวระบุแทน — ภาพ (Texture) ถูกแชร์กันเสมอ
	var base := frames.resource_path
	if base == "" and frames.has_animation(anim) and frames.get_frame_count(anim) > 0:
		var tex := frames.get_frame_texture(anim, 0)
		if tex != null:
			base = tex.resource_path if tex.resource_path != "" else "tex:" + str(tex.get_instance_id())
			if tex is AtlasTexture and (tex as AtlasTexture).atlas != null:
				var at: Texture2D = (tex as AtlasTexture).atlas
				base = (at.resource_path if at.resource_path != "" else "tex:" + str(at.get_instance_id())) \
					+ "@" + str((tex as AtlasTexture).region)
			base += "x" + str(frames.get_frame_count(anim))
	if base == "":
		base = "id:" + str(frames.get_instance_id())
	return base + "#" + String(anim)


## คืน {"frames": [ {bottom, dx, bottom_use, dx_use} ... ], "tallest": float}
## bottom = ระยะจากกึ่งกลางผ้าใบถึงปลายเท้า · dx = ตัวเยื้องจากกึ่งกลางไปทางขวาเท่าไหร่
## *_use = ค่าที่ควรใช้จริง (ค่ากลางของท่า เว้นแต่เฟรมนั้นต่างมากจริง ๆ)
## with_body = true → วัด "ลำตัว" กับ "ระยะอาวุธ" เพิ่ม (ช้ากว่านิดหน่อย ใช้เฉพาะผู้เล่น)
static func measure(frames: SpriteFrames, anim: StringName, shared_pool: Dictionary = {},
		with_body: bool = false) -> Dictionary:
	if frames == null or not frames.has_animation(anim):
		return {}
	# ★ รอบ 94 ★ แคชช่องเดียวต่อ (ชุดภาพ + ท่า) แต่ "อัปเกรดได้"
	# ของที่วัดลำตัวมาแล้วมีข้อมูลครบกว่า → ผู้ที่ไม่ต้องการลำตัว (มอน) ใช้ซ้ำได้เลย
	# ส่วนคนที่ต้องการลำตัวแต่ในแคชยังไม่มี ต้องวัดใหม่ทับของเดิม
	var key := _key(frames, anim)
	if _cache.has(key):
		var hit: Dictionary = _cache[key]
		if not with_body or bool(hit.get("body_measured", false)):
			return hit

	var list: Array = []
	var tallest := 0.0
	# ★ รอบ 92 ★ ผืนที่คลายบีบอัดแล้ว — ใช้ร่วมกันทุกเฟรมของท่านี้ (และทุกท่าถ้า warm() ส่ง pool มา) แล้วทิ้ง
	var atlas_pool: Dictionary = shared_pool
	for i in range(frames.get_frame_count(anim)):
		var tex := frames.get_frame_texture(anim, i)
		if tex == null:
			continue
		var tw := float(tex.get_width())
		var th := float(tex.get_height())
		var used := Rect2i(0, 0, int(tw), int(th))
		var img := _frame_image(tex, atlas_pool)
		var fd_body: Dictionary = _scan_body(img) if (with_body and img != null) else {}
		if img != null:
			# ★★ รอบ 97 ★★ ผู้เล่น (with_body): ใช้กรอบ "ที่มองเห็นจริง" จากการสแกน (alpha > 20)
			# แทน get_used_rect() ที่นับ alpha > 0 — ชีทที่ตัดด้วยเครื่องมือบางตัวมี "เส้น/แถบจาง alpha = 1"
			# ทิ้งไว้ในทุกช่อง และ **ไม่เท่ากันในแต่ละช่อง** (attack 3hit.png: ช่อง 1-2 ขยะ x 0-397 · ช่อง 3 x 118-397)
			# → จุดกึ่งกลางเลื่อน 38 px อยู่เฟรมเดียว = "ตัวเด้งมาข้างหน้าจังหวะนึง"
			# มอน (ไม่มี with_body) ยังใช้ get_used_rect() เหมือนเดิมทุกประการ — ท่าตายที่ค่อย ๆ จางของมอนบางตัว
			# (ผู้พิทักษ์เตาหลอม) พึ่งพิกเซลจาง ๆ พวกนั้นอยู่ ห้ามตัดทิ้ง (r88 จับได้)
			var r: Rect2i = fd_body.get("rect", Rect2i())
			if r.size.x <= 0 or r.size.y <= 0:
				r = img.get_used_rect()
			if r.size.x > 0 and r.size.y > 0:
				used = r
		tallest = maxf(tallest, float(used.size.y))
		# ★★ รอบ 97 ★★ ผู้เล่น (with_body): จัดกึ่งกลางด้วย "กึ่งกลางลำตัว" ไม่ใช่กึ่งกลางกรอบ (ลำตัว+ดาบ)
		# กรอบรวมดาบเลื่อนตามดาบที่เหวี่ยง (Attack_Blade_2: -5 → -61 · Attack_Blade_3: +52 → -32 หน่วยภาพ)
		# → ระบบดันลำตัวถอยไปมาให้กรอบอยู่กลาง = ตัวเลื่อนไปเลื่อนมาระหว่างฟัน
		# กึ่งกลางลำตัวเลื่อนแค่ตามท่าเอนจริง ๆ (−2…−10) และตรงกับแคปซูลชนที่อยู่กลางโหนดพอดี
		var dx_val: float = float(used.position.x) + float(used.size.x) * 0.5 - tw * 0.5
		if fd_body.has("body_cx"):
			dx_val = float(fd_body.body_cx) - tw * 0.5
		list.append({
			"bottom": float(used.position.y + used.size.y) - th * 0.5,
			"dx": dx_val,
			# ★ รอบ 87 ★ ความกว้างของเนื้อภาพ — ใช้ทำ "กรอบโดนตี" ให้กว้างเท่าตัวมอนที่วาดจริง
			"w": float(used.size.x),
			# ★ รอบ 94 ★ ความสูงลำตัว (ไม่รวมดาบ) และระยะที่อาวุธยื่นไปข้างหน้า
			"body_h": float(fd_body.get("body_h", 0.0)),
			"reach": float(fd_body.get("reach", 0.0)),
		})

	# ค่ากลาง (median) ของทั้งท่า — กันตัวเด้งจากขอบภาพที่คลาดกันเล็กน้อย (รอบ 39)
	var bots: Array = []
	var dxs: Array = []
	for fd in list:
		bots.append(fd.bottom)
		dxs.append(fd.dx)
	bots.sort()
	dxs.sort()
	var med_bottom: float = bots[bots.size() >> 1] if not bots.is_empty() else 0.0
	var med_dx: float = dxs[dxs.size() >> 1] if not dxs.is_empty() else 0.0
	for fd in list:
		fd["bottom_use"] = fd.bottom if absf(fd.bottom - med_bottom) > SNAP else med_bottom
		fd["dx_use"] = fd.dx if absf(fd.dx - med_dx) > SNAP else med_dx

	# ★ ความกว้างตัวแทนของท่านี้ ★ ใช้ค่ากลาง ไม่ใช่ค่าสูงสุด
	# เฟรมที่กางปีก/เหวี่ยงหางสุดตัวมีไม่กี่เฟรม ไม่ควรมากำหนดกรอบโดนตีของทั้งท่า
	var ws: Array = []
	for fd in list:
		ws.append(fd.w)
	ws.sort()
	var widest: float = ws[ws.size() >> 1] if not ws.is_empty() else 0.0

	# ★ รอบ 94 ★ ความสูงลำตัว "ค่ากลาง" ของท่านี้ — ใช้เทียบขนาดข้ามท่าให้เท่ากัน
	# ใช้ค่ากลาง ไม่ใช่ค่าสูงสุด เพราะเฟรมชูดาบ/ย่อตัวมีไม่กี่เฟรม ไม่ควรมากำหนดขนาดทั้งท่า
	var body_med := 0.0
	var reach_max := 0.0
	if with_body:
		var bs: Array = []
		for fd in list:
			if fd.body_h > 0.0:
				bs.append(fd.body_h)
			reach_max = maxf(reach_max, fd.reach)
		bs.sort()
		body_med = bs[bs.size() >> 1] if not bs.is_empty() else 0.0

	var info := {"frames": list, "tallest": tallest, "widest": widest,
		"body_med": body_med, "reach_max": reach_max, "body_measured": with_body}
	_cache[key] = info
	measured_count += 1
	return info


## วัดทุกท่าของ SpriteFrames นี้ล่วงหน้า (เรียกตอนโหลดแมพ จะได้ไม่กระตุกกลางเกม)
static func warm(frames: SpriteFrames, with_body: bool = false) -> int:
	if frames == null:
		return 0
	var n := 0
	# ★ รอบ 92 ★ pool เดียวทุกท่า — ชีทที่หลายท่าใช้ร่วมกัน (เช่น Hit+Die บนผืนเดียว) คลายบีบอัดครั้งเดียว
	var pool: Dictionary = {}
	for a in frames.get_animation_names():
		var k := _key(frames, a)
		if not _cache.has(k) or (with_body and not bool((_cache[k] as Dictionary).get("body_measured", false))):
			measure(frames, a, pool, with_body)
			n += 1
	pool.clear()
	return n


static func is_cached(frames: SpriteFrames, anim: StringName) -> bool:
	return frames != null and _cache.has(_key(frames, anim))


## วัดแนวฝ่าเท้าเฉพาะบริเวณที่กำหนด ไม่เอาสะเก็ดอาวุธหรือ alpha จางมาเป็นพื้น
static func measure_soles(frames: SpriteFrames, anim: StringName, region: Rect2i) -> PackedFloat32Array:
	var soles := PackedFloat32Array()
	var pool := {}
	for i in range(frames.get_frame_count(anim)):
		var img := _frame_image(frames.get_frame_texture(anim, i), pool)
		var sole := 0.0
		if img != null:
			var area := region.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			for y in range(area.end.y - 1, area.position.y - 1, -1):
				var opaque := 0
				for x in range(area.position.x, area.end.x):
					if img.get_pixel(x, y).a > 0.4:
						opaque += 1
				if opaque >= 10:
					sole = float(y + 1)
					break
		soles.append(sole)
	return soles


static func clear() -> void:
	_cache.clear()
