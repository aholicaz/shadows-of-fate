#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
★ รอบ 75 ★ ต่อคลิปวิดีโอใหม่ 4 ไฟล์เข้ากับจุดคัทซีนในเกม

| ไฟล์ .ogv | ใส่ที่ | เล่นตอนไหน |
|---|---|---|
| boss_intro_stormscar     | มอน stormscar   → Intro Video      | เดินเข้าใกล้อสูรสายฟ้าครั้งแรก |
| boss_death_stormscar     | มอน stormscar   → Death Video      | อสูรสายฟ้าตาย (หลังท่าตายจบ) |
| boss_death_king_poring   | มอน king_poring → Death Video      | คิงโพริงตาย |
| m6_ceremony              | เควส m6_ceremony → Video On Complete | ส่งเควส M6 ก่อนกล้องแพนไปหากุนนาร์ |

แก้เฉพาะบรรทัดที่ระบุ — ค่าอื่นในไฟล์ไม่แตะ (มีสำรองที่ _to_delete/originals_video_r75/)

ใช้:  python3 set_cutscene_videos.py           → ดูก่อนว่าจะแก้อะไร
      python3 set_cutscene_videos.py --apply   → แก้จริง
"""
import os, re, sys, shutil

ROOT = os.path.dirname(os.path.abspath(__file__))
BACKUP = os.path.join(ROOT, "_to_delete", "originals_video_r75")
APPLY = "--apply" in sys.argv
VIDEO_DIR = "res://Sprites/video/"

# ไฟล์ .tres  ->  { ชื่อช่อง: ชื่อไฟล์คลิป }
JOBS = {
    "data/monsters/stormscar.tres": {
        "intro_video": "boss_intro_stormscar.ogv",
        "death_video": "boss_death_stormscar.ogv",
    },
    "data/monsters/king_poring.tres": {
        "death_video": "boss_death_king_poring.ogv",
    },
    "data/quests/m6_ceremony.tres": {
        "video_on_complete": "m6_ceremony.ogv",
    },
}


def set_prop(text, key, value):
    """ตั้งค่า key = "value" ในบล็อก [resource] — มีอยู่แล้วก็ทับ ไม่มีก็เติมท้าย"""
    pat = re.compile(r'^%s = .*$' % re.escape(key), re.M)
    line = '%s = "%s"' % (key, value)
    if pat.search(text):
        old = pat.search(text).group(0)
        if old == line:
            return text, "เท่าเดิม"
        return pat.sub(line.replace("\\", "\\\\"), text, count=1), "ทับของเดิม (%s)" % old.split("=", 1)[1].strip()
    if not text.endswith("\n"):
        text += "\n"
    return text + line + "\n", "เพิ่มใหม่"


def main():
    changed = False
    for rel, props in JOBS.items():
        path = os.path.join(ROOT, rel)
        if not os.path.exists(path):
            print("  ! ไม่พบไฟล์ %s — ข้าม" % rel)
            continue
        text = open(path, encoding="utf-8").read()
        orig = text
        notes = []
        for key, clip in props.items():
            full = VIDEO_DIR + clip
            vid_path = os.path.join(ROOT, "Sprites", "video", clip)
            if not os.path.exists(vid_path):
                print("  ! ไม่พบคลิป %s — ข้ามช่อง %s" % (clip, key))
                continue
            text, how = set_prop(text, key, full)
            notes.append("%s = %s [%s]" % (key, clip, how))
        if not notes:
            continue
        print("  %s %s" % ("★" if text != orig else "✓", rel))
        for n in notes:
            print("      %s" % n)
        if text == orig:
            continue
        changed = True
        if not APPLY:
            continue
        os.makedirs(BACKUP, exist_ok=True)
        shutil.copy2(path, os.path.join(BACKUP, os.path.basename(path)))
        open(path, "w", encoding="utf-8", newline="\n").write(text)
        print("      → บันทึกแล้ว")
    if changed and not APPLY:
        print("\nยังไม่ได้แก้ — รันซ้ำด้วย --apply เพื่อแก้จริง")
    elif not changed:
        print("\nทุกอย่างตั้งไว้แล้ว ไม่ต้องแก้")


if __name__ == "__main__":
    main()
