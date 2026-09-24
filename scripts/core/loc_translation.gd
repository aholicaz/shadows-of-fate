## LocTranslation — ตัวแปลภาษาอังกฤษของทั้งเกม ★ รอบ 162 ★
##
## Godot แปล Label / Button / RichTextLabel / หัวหน้าต่าง / tooltip ให้อัตโนมัติ
## โดยส่งข้อความ "ที่แสดงจริง" มาถามที่ _get_message() — คลาสนี้ตอบได้ 3 ชั้น:
##   1) ตรงตัว     — ข้อความตรงกับ msgid ใน locale/*.po
##   2) แม่แบบ     — msgid ที่มี %s %d %.1f (ข้อความที่สคริปต์ประกอบด้วย "..." % [ค่า])
##                   เช่น "ต้องเลเวล %d ขึ้นไป" ↔ "ต้องเลเวล 30 ขึ้นไป" → "Requires Level 30 ..."
##                   ค่าที่เป็นข้อความไทย (%s) ถูกแปลต่ออีกชั้น (ชื่อไอเทม/มอน/NPC)
##   3) แปลเป็นท่อน — ข้อความที่ต่อกันด้วย + (ชื่อ + " x3" ฯลฯ) → แทนทีละท่อนที่รู้จัก ยาวก่อนสั้น
## ข้อความที่ยังเหลือภาษาไทยจะถูกจดไว้ที่ user://untranslated_en.txt (ส่งให้ Claude แปลเพิ่ม)
## ใช้เฉพาะโหมด English — Loc ลงทะเบียนตัวนี้ตอนเลือก English เท่านั้น (กับดัก 190)
class_name LocTranslation
extends Translation

const MISS_PATH := "user://untranslated_en.txt"
const CACHE_MAX := 6000

var _po: Array = []
var _cache := {}
var _templates: Array = []      # [RegEx, msgstr(พร้อม spec), Array ชนิด spec, ความยาวข้อความคงที่]
var _frag := {}                 # 2 ตัวอักษรแรก → [[ไทย, อังกฤษ], ...] เรียงยาว→สั้น
var _extra := {}                # ข้อความ (ตัดช่องว่าง/บรรทัดหัวท้าย) → คำแปล
var _seg := RegEx.new()         # ตัวคั่นท่อน ·  •  |  — ช่องว่างคู่
var _tags := RegEx.new()        # [b] [color=..] ฯลฯ
var _be := RegEx.new()          # เดือนอังกฤษ + ปี พ.ศ.
var _th := RegEx.new()
var _spec := RegEx.new()
var _missed := {}


func _init() -> void:
	locale = "en"
	_th.compile("[\\x{0E00}-\\x{0E7F}]")
	_be.compile("\\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) (25[0-9]{2})\\b")
	_tags.compile("\\[/?[a-z_]+(=[^\\]]*)?\\]")
	_spec.compile("%[-+ 0#]*\\d*(?:\\.\\d+)?[sdifxXc]")


func setup(po_list: Array) -> void:
	_po = po_list
	_seg.compile("(\\s*[·•|]\\s*|\\s{2,}|\\s[—–]\\s)")
	for t in po_list:
		for id in t.get_message_list():
			var s := String(id)
			if s == "" or _th.search(s) == null:
				continue
			var en := String(t.get_message(id))
			if en == "":
				continue
			var ls := s.split("\n")
			var le := en.split("\n")
			if ls.size() > 1 and ls.size() == le.size():
				for i in ls.size():
					_register(ls[i], le[i])
			else:
				_register(s, en)
	for k in _frag:
		_frag[k].sort_custom(func(a, b): return a[0].length() > b[0].length())
	_templates.sort_custom(func(a, b): return a[3] > b[3])


func _register(s: String, en: String) -> void:
	if _th.search(s) == null:
		return
	if s.contains("[/"):
		var s2 := _tags.sub(s, "", true)
		var e2 := _tags.sub(en, "", true)
		if s2 != s and _th.search(s2) != null:
			_register(s2, e2)
	if _spec.search(s) != null:
		_add_template(s, en)
		return
	var c := s.strip_edges()
	if c.length() < 2:
		return
	if not _extra.has(c):
		_extra[c] = en.strip_edges()
	var k := c.substr(0, 2)
	if not _frag.has(k):
		_frag[k] = []
	_frag[k].append([c, en.strip_edges()])


func template_count() -> int:
	return _templates.size()


func _add_template(s: String, en: String) -> void:
	var pat := "^"
	var kinds: Array = []
	var pos := 0
	var lit_len := 0
	for m in _spec.search_all(s):
		var lit := s.substr(pos, m.get_start() - pos).replace("%%", "%")
		pat += _esc(lit)
		lit_len += lit.length()
		var sp := m.get_string()
		var kind := sp.right(1)
		kinds.append(kind)
		if kind == "d" or kind == "i" or kind == "x" or kind == "X":
			pat += "([-+]?[0-9A-Fa-f,]+)"
		elif kind == "f":
			pat += "([-+]?[0-9.,]+)"
		else:
			pat += "(.*?)"
		pos = m.get_end()
	var tail := s.substr(pos).replace("%%", "%")
	pat += _esc(tail) + "$"
	lit_len += tail.length()
	if lit_len < 2:
		return
	var re := RegEx.new()
	if re.compile(pat) != OK:
		return
	_templates.append([re, en, kinds, lit_len])


static func _esc(t: String) -> String:
	var out := ""
	for ch in t:
		if "\\.^$|?*+()[]{}/".contains(ch):
			out += "\\" + ch
		else:
			out += ch
	return out


func _get_message(src_message: StringName, _context: StringName) -> StringName:
	var s := String(src_message)
	if s == "" or _th.search(s) == null:
		return StringName()
	if _cache.has(s):
		return _cache[s]
	var r := tr_text(s, 0)
	if _cache.size() > CACHE_MAX:
		_cache.clear()
	var out := StringName(r) if r != s else StringName()
	_cache[s] = out
	return out


## แปลข้อความหนึ่งก้อน (ใช้ได้ทั้งจาก Loc.t และ _get_message)
func tr_text(s: String, depth: int) -> String:
	s = s.replace("\r", "")
	if _th.search(s) == null:
		return s
	var r := _exact(s)
	if r != "":
		return r
	if s.contains("\n"):
		var outl := PackedStringArray()
		for ln in s.split("\n"):
			outl.append(tr_text(ln, depth))
		r = "\n".join(outl)
	else:
		r = _line(s, depth)
	if depth == 0:
		r = _ce_year(r)
		if _th.search(r) != null:
			_note_miss(s)
	return r


## "24 Sep 2569" → "24 Sep 2026" (ปี พ.ศ. → ค.ศ. หลังชื่อเดือนอังกฤษ)
func _ce_year(r: String) -> String:
	var ms := _be.search_all(r)
	for i in range(ms.size() - 1, -1, -1):
		var m: RegExMatch = ms[i]
		var y := int(m.get_string(2)) - 543
		r = r.substr(0, m.get_start(2)) + str(y) + r.substr(m.get_end(2))
	return r


## บรรทัดเดียว: แม่แบบทั้งบรรทัด → แยกท่อนตามตัวคั่น → แปลเป็นคำ
func _line(s: String, depth: int) -> String:
	if depth < 4:
		var r := _by_template(s, depth)
		if r != "":
			return r
		r = _peeled(s, depth)
		if r != "":
			return r
		var parts := _split_keep(s)
		if parts.size() > 1:
			var out := ""
			for p in parts:
				if _th.search(p) == null:
					out += p
				else:
					var e := _exact(p)
					if e == "":
						e = _by_template(p, depth)
					if e == "":
						e = _by_fragments(p)
					out += e
			return out
	return _by_fragments(s)


## ลอกหัว/ท้ายที่ไม่ใช่ภาษาไทย ("[GM] ", "» ", "[color=..]", ตัวเลข) แล้วลองตรงตัว/แม่แบบกับแกนกลาง
func _peeled(s: String, depth: int) -> String:
	var m := _th.search(s)
	if m == null:
		return ""
	var a := m.get_start()
	var b := s.length()
	for i in range(s.length() - 1, -1, -1):
		if _is_thai(s.unicode_at(i)):
			b = i + 1
			break
	var starts := [0]
	var p := 0
	while true:
		var tm := _tags.search(s, p)
		if tm == null or tm.get_start() != p:
			break
		p = tm.get_end()
		starts.append(p)
	var ends := [s.length()]
	var q := s.length()
	while q > 0:
		var found := false
		for tm2 in _tags.search_all(s):
			if tm2.get_end() == q:
				q = tm2.get_start()
				ends.append(q)
				found = true
				break
		if not found:
			break
	var cands := [[a, s.length()], [0, b], [a, b]]
	for i0 in starts:
		for i1 in ends:
			if i1 > i0:
				cands.append([i0, i1])
	for pair in cands:
		var i0: int = pair[0]
		var i1: int = pair[1]
		if i0 == 0 and i1 == s.length():
			continue
		var core := s.substr(i0, i1 - i0)
		var e := _exact(core)
		if e == "":
			e = _by_template(core, depth + 1)
		if e != "":
			return s.substr(0, i0) + e + s.substr(i1)
	return ""


func _split_keep(s: String) -> PackedStringArray:
	var out := PackedStringArray()
	var pos := 0
	for m in _seg.search_all(s):
		if m.get_start() > pos:
			out.append(s.substr(pos, m.get_start() - pos))
		out.append(m.get_string())
		pos = m.get_end()
	if pos < s.length():
		out.append(s.substr(pos))
	return out


func _exact(s: String) -> String:
	for t in _po:
		var m := String(t.get_message(s))
		if m != "":
			return m
	var c := s.strip_edges()
	if c != "" and _extra.has(c):
		var i0 := s.find(c)
		return s.substr(0, i0) + String(_extra[c]) + s.substr(i0 + c.length())
	if c != s and c != "":
		for t in _po:
			var m2 := String(t.get_message(c))
			if m2 != "":
				var lead := s.substr(0, s.find(c))
				var trail := s.substr(s.find(c) + c.length())
				return lead + m2 + trail
	return ""


func _by_template(s: String, depth: int) -> String:
	for tp in _templates:
		var m: RegExMatch = tp[0].search(s)
		if m == null:
			continue
		var en: String = tp[1]
		var kinds: Array = tp[2]
		var out := ""
		var pos := 0
		var gi := 1
		for sm in _spec.search_all(en):
			out += en.substr(pos, sm.get_start() - pos)
			var v := m.get_string(gi) if gi <= kinds.size() else ""
			if gi <= kinds.size() and kinds[gi - 1] == "s" and _th.search(v) != null:
				v = _line(v, depth + 1) if _exact(v) == "" else _exact(v)
			out += v
			gi += 1
			pos = sm.get_end()
		out += en.substr(pos)
		return out.replace("%%", "%")
	return ""


func _by_fragments(s: String) -> String:
	var res := ""
	var i := 0
	var n := s.length()
	while i < n:
		var c := s.unicode_at(i)
		if c >= 0x0E00 and c <= 0x0E7F:
			var hit = null
			var k := s.substr(i, 2)
			if _frag.has(k):
				for f in _frag[k]:
					var L: int = f[0].length()
					if s.substr(i, L) != f[0]:
						continue
					if L < 4:   # คำสั้น ต้องไม่อยู่กลางคำไทย
						if (i > 0 and _is_thai(s.unicode_at(i - 1))) or (i + L < n and _is_thai(s.unicode_at(i + L))):
							continue
					hit = f
					break
			if hit != null:
				var en: String = hit[1]
				if res != "" and en != "" and _space_between(res.unicode_at(res.length() - 1), en.unicode_at(0)):
					res += " "
				res += en
				i += String(hit[0]).length()
				if i < n and en != "" and _space_between(en.unicode_at(en.length() - 1), s.unicode_at(i)):
					res += " "
				continue
		res += s.substr(i, 1)
		i += 1
	return res


static func _is_thai(c: int) -> bool:
	return c >= 0x0E00 and c <= 0x0E7F


static func _is_word(c: int) -> bool:
	return _is_thai(c) or (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c > 0x7F and not _is_punct(c)


static func _is_punct(c: int) -> bool:
	# · « » — – → ★ ▲ ▼ ✦ • (สัญลักษณ์ที่ไม่ต้องเว้นวรรคเพิ่ม)
	return c in [0xB7, 0xAB, 0xBB, 0x2014, 0x2013, 0x2192, 0x2605, 0x25B2, 0x25BC, 0x2726, 0x2022]


static func _space_between(a: int, b: int) -> bool:
	var a_ok := _is_word(a) or char(a) in [")", "]", ".", "!", "?", ",", ":", ";", "%"]
	var b_ok := _is_word(b) or char(b) in ["(", "«"]
	return a_ok and b_ok


func _note_miss(s: String) -> void:
	if _missed.has(s) or _missed.size() > 3000:
		return
	_missed[s] = true
	var f := FileAccess.open(MISS_PATH, FileAccess.READ_WRITE if FileAccess.file_exists(MISS_PATH) else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(s.replace("\n", "\\n"))
	f.close()
