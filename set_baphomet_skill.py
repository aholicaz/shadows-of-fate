#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
★ รอบ 78 ★ ใส่สกิล "เคียวเงามรณะ" ให้บาฟโฟเมท (data/monsters/baphomet.tres)

แก้เฉพาะช่องสกิลที่ระบุ — ค่าอื่นไม่แตะ (สำรองที่ _to_delete/originals_skill_r78/)
ปรับตัวเลขได้ที่ VALUES ข้างล่าง หรือแก้ใน Godot Inspector กลุ่ม "สกิลมอนสเตอร์" / "สกิล — คลื่นเคียวมืดวิ่งบนพื้น"

ใช้:  python3 set_baphomet_skill.py           → ดูก่อน
      python3 set_baphomet_skill.py --apply   → แก้จริง
"""
import os, re, sys, shutil

ROOT = os.path.dirname(os.path.abspath(__file__))
TARGET = os.path.join(ROOT, "data", "monsters", "baphomet.tres")
BACKUP = os.path.join(ROOT, "_to_delete", "originals_skill_r78")
APPLY = "--apply" in sys.argv

VALUES = [
    # ---- สกิลมอนสเตอร์ (ของเดิม) ----
    ("skill_name",            '"เคียวเงามรณะ"'),
    ("skill_anim",            '&"Skill"'),
    ("skill_range",           "560.0"),      # เริ่มร่ายเมื่อผู้เล่นอยู่ในระยะนี้
    ("skill_damage_mult",     "2.0"),        # ดาเมจต่อลูก = ตีปกติ ×2
    ("skill_windup",          "0.5"),
    ("skill_duration",        "1.2"),        # ท่าร่ายทั้งหมด (บอสยืนนิ่งช่วงนี้ = โอกาสตี)
    ("skill_cooldown",        "8.0"),
    ("skill_chance",          "0.7"),
    ("skill_knockback",       "380.0"),
    # ---- คลื่นเคียวมืด (ใหม่รอบ 78) ----
    ("skill_wave_count",      "2"),          # ปล่อย 2 ระลอก
    ("skill_wave_both_sides", "true"),       # หน้า+หลังพร้อมกัน (กันยืนตีข้างหลัง)
    ("skill_wave_speed",      "540.0"),
    ("skill_wave_range",      "900.0"),
    ("skill_wave_interval",   "0.38"),
    ("skill_wave_delay",      "0.45"),       # ให้ตรงจังหวะฟันเคียวในท่า Skill
    ("skill_wave_hit_width",  "42.0"),
    ("skill_wave_hit_height", "72.0"),       # ผู้เล่นกระโดดสูง ≈ 90 → ข้ามได้ถ้ากดทัน
    ("skill_wave_max_hits",   "1"),          # โดนได้ลูกเดียวต่อการร่าย
    ("skill_wave_height",     "150.0"),
]


def main():
    if not os.path.exists(TARGET):
        print("! ไม่พบ", TARGET); return
    text = open(TARGET, encoding="utf-8").read()
    orig = text
    for key, val in VALUES:
        line = "%s = %s" % (key, val)
        pat = re.compile(r"^%s = .*$" % re.escape(key), re.M)
        m = pat.search(text)
        if m:
            if m.group(0) == line:
                print("  = %s (เท่าเดิม)" % line); continue
            print("  ~ %s   (เดิม: %s)" % (line, m.group(0).split("=", 1)[1].strip()))
            text = pat.sub(line.replace("\\", "\\\\"), text, count=1)
        else:
            print("  + %s" % line)
            if not text.endswith("\n"):
                text += "\n"
            text += line + "\n"
    if text == orig:
        print("\nตั้งไว้ครบแล้ว ไม่ต้องแก้"); return
    if not APPLY:
        print("\nยังไม่ได้แก้ — รันซ้ำด้วย --apply"); return
    os.makedirs(BACKUP, exist_ok=True)
    shutil.copy2(TARGET, os.path.join(BACKUP, "baphomet.tres"))
    open(TARGET, "w", encoding="utf-8", newline="\n").write(text)
    print("\n→ บันทึกแล้ว (สำรองที่ %s)" % os.path.relpath(BACKUP, ROOT))


if __name__ == "__main__":
    main()
