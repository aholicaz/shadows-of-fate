## Loc — ระบบ 2 ภาษา (ไทย / English) ★ รอบ 161 · แก้รอบ 162 ★
##
## หลักการ: ข้อความภาษาไทยที่อยู่ในไฟล์เกม (.tres / .tscn / สคริปต์) คือ "คีย์" (msgid) เลย
## คำแปลภาษาอังกฤษอยู่ใน res://locale/en.po (สร้างจาก tools/round161/apply_r161.py)
##   Loc.t("ข้อความไทย")  → คืนข้อความตามภาษาที่เลือก (ไม่มีคำแปล = คืนภาษาไทยเดิม)
##   Loc.clean(text)       → ตัด \r (ไฟล์ CRLF บน Windows ทำให้ split("\n\n") แยกหน้าไม่ได้ — กับดัก 183)
##   Loc.set_locale("en")  → เปลี่ยนภาษา + จำไว้ใน user://ui_layout.cfg [lang] locale
## กล่องสนทนา (dialogue_box.gd) เรียก Loc.t กับ ชื่อ/ข้อความ/ตัวเลือก ทุกบรรทัดอยู่แล้ว
## Label ทั่วไปของ Godot แปลเองอัตโนมัติ ถ้าข้อความตรงกับ msgid ใน en.po (auto translate)
class_name Loc
extends RefCounted

const LAYOUT_PATH := "user://ui_layout.cfg"
const LOCALES := ["th", "en"]
const LOCALE_NAMES := {"th": "ไทย", "en": "English"}
const PO_FILES := ["res://locale/en.po", "res://locale/en_game.po"]   # รอบ 161 = เควส/บท NPC · รอบ 162 = ข้อความที่เหลือทั้งเกม

static var _inited := false
static var _tr: Array = []        # [LocTranslation] — สร้างครั้งแรกที่เลือก English
static var _added := false


## ★ รอบ 162: แก้ "โหมดไทยมีอังกฤษปน" — Godot ตั้ง fallback locale = "en" ไว้
## ถ้าลงทะเบียนคำแปลอังกฤษค้างไว้ตลอด Label ในโหมดไทยจะไปดึงอังกฤษมาแทน
## → ลงทะเบียนคำแปลเฉพาะตอนเลือก English เท่านั้น · โหมดไทยถอดออกหมด
static func init() -> void:
	if _inited:
		return
	_inited = true
	var lang := "th"
	var cfg := ConfigFile.new()
	if cfg.load(LAYOUT_PATH) == OK:
		lang = String(cfg.get_value("lang", "locale", "th"))
	if not lang in LOCALES:
		lang = "th"
	_apply(lang)


static func _apply(code: String) -> void:
	var want := code == "en"
	if want and _tr.is_empty():
		var pos: Array = []
		for p in PO_FILES:
			if ResourceLoader.exists(p):
				var res = load(p)
				if res is Translation:
					pos.append(res)
		var lt := LocTranslation.new()
		lt.setup(pos)
		_tr.append(lt)
	if want and not _added:
		for t in _tr:
			TranslationServer.add_translation(t)
		_added = true
	elif not want and _added:
		for t in _tr:
			TranslationServer.remove_translation(t)
		_added = false
	TranslationServer.set_locale(code)


static func current() -> String:
	init()
	return "en" if TranslationServer.get_locale().begins_with("en") else "th"


static func set_locale(code: String) -> void:
	init()
	if not code in LOCALES:
		return
	_apply(code)
	var cfg := ConfigFile.new()
	cfg.load(LAYOUT_PATH)   # ไม่มีไฟล์ก็ไม่เป็นไร — ค่าเดิม (เพลง/เสียง/ปุ่ม) อยู่ไฟล์เดียวกัน
	cfg.set_value("lang", "locale", code)
	cfg.save(LAYOUT_PATH)


static func clean(text: String) -> String:
	return text.replace("\r", "")


static func t(text: String) -> String:
	if text == "":
		return text
	var c := clean(text)
	if current() == "th":
		return c
	var out := String(TranslationServer.translate(c))
	if out != c:
		return out
	var s := c.strip_edges()
	if s != c:
		var out2 := String(TranslationServer.translate(s))
		if out2 != s:
			return out2
	return c


## ปุ่มเปิด/ปิด — คำว่า "ปิด" ในเกมใช้ทั้ง "ปิดหน้าต่าง" (Close) และ "ปิดอยู่" (Off) → ปุ่มสลับเรียกตัวนี้แทน
static func on_off(on: bool) -> String:
	if current() == "en":
		return "On" if on else "Off"
	return "เปิด" if on else "ปิด"

