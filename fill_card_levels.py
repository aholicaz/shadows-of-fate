#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fill_card_levels.py — เติมช่อง `monster_level` ในไฟล์การ์ด data/cards/*.tres

ทำไมต้องมี (รอบ 90)
  สมุดการ์ดเรียงลำดับด้วย "เลเวลของมอนเจ้าของการ์ด" — ของเดิมไปเปิดไฟล์มอนมาอ่านทีละใบ
  ไฟล์มอน 1 ตัวลากชีทภาพตามมาด้วย 30-50 MB → เปิดสมุดการ์ดครั้งเดียว = โหลดชีทมอนครบ 30 ตัว (1.6 GB)
  ตอนนี้เก็บ "แค่ตัวเลขเลเวล" ไว้บนการ์ดเลย เรียงได้โดยไม่ต้องแตะไฟล์มอน

รันซ้ำได้ · รันใหม่ทุกครั้งที่แก้เลเวลมอน
รัน: python3 fill_card_levels.py            (ดูอย่างเดียว)
     python3 fill_card_levels.py --apply    (แก้จริง)
"""
import io
import os
import re
import shutil
import sys

APPLY = "--apply" in sys.argv
ROOT = os.path.dirname(os.path.abspath(__file__))
CARD_DIR = os.path.join(ROOT, "data", "cards")
MON_DIR = os.path.join(ROOT, "data", "monsters")
BAK = os.path.join(ROOT, "_to_delete", "originals_cards_r90")


def rd(p):
    return io.open(p, encoding="utf-8").read()


def monster_levels():
    """{id มอน: เลเวล} — อ่านจากไฟล์ตรง ๆ ไม่ต้องเปิด Godot"""
    out = {}
    for f in sorted(os.listdir(MON_DIR)):
        if not f.endswith(".tres"):
            continue
        t = rd(os.path.join(MON_DIR, f))
        mid = re.search(r'^id = &"([^"]+)"', t, re.M)
        mid = mid.group(1) if mid else f[:-5]      # ไม่มีบรรทัด id = ใช้ค่าเริ่มต้น = ชื่อไฟล์
        lv = re.search(r"^level = (\d+)", t, re.M)
        out[mid] = int(lv.group(1)) if lv else 1   # ไม่มีบรรทัด level = ค่าเริ่มต้นใน MonsterData
    return out


def main():
    if not APPLY:
        print("★ โหมดดูอย่างเดียว ★ ใส่ --apply ถึงจะแก้จริง\n")
    levels = monster_levels()
    print("อ่านเลเวลมอนได้ %d ตัว\n" % len(levels))
    if APPLY:
        os.makedirs(BAK, exist_ok=True)

    done = same = miss = 0
    for f in sorted(os.listdir(CARD_DIR)):
        if not f.endswith(".tres"):
            continue
        p = os.path.join(CARD_DIR, f)
        s = rd(p)
        mid = re.search(r'^monster_id = &"([^"]+)"', s, re.M)
        if not mid:
            print("  ! %-26s ไม่ได้ผูกกับมอน — ข้าม" % f[:-5])
            miss += 1
            continue
        lv = levels.get(mid.group(1))
        if lv is None:
            print("  ! %-26s ไม่เจอมอน %s — ข้าม" % (f[:-5], mid.group(1)))
            miss += 1
            continue

        want = "monster_level = %d" % lv
        cur = re.search(r"^monster_level = .*$", s, re.M)
        if cur:
            if cur.group(0) == want:
                same += 1
                continue
            out = re.sub(r"^monster_level = .*$", want, s, flags=re.M)
        else:
            # วางต่อจาก rarity (ไม่งั้นต่อจาก monster_id)
            anchor = re.search(r"^rarity = .*$", s, re.M) or re.search(r"^monster_id = .*$", s, re.M)
            out = s[:anchor.end()] + "\n" + want + s[anchor.end():]

        print("  + %-26s Lv.%d" % (f[:-5], lv))
        if APPLY:
            bak = os.path.join(BAK, f)
            if not os.path.exists(bak):
                shutil.copy2(p, bak)
            io.open(p, "w", encoding="utf-8", newline="\n").write(out)
        done += 1

    print("\nเติม %d ใบ · ถูกอยู่แล้ว %d ใบ · ข้าม %d" % (done, same, miss))
    if APPLY and done:
        print("สำรองไฟล์เดิมไว้ที่ %s" % os.path.relpath(BAK, ROOT))
    elif not APPLY:
        print("(ยังไม่ได้แก้จริง)")


if __name__ == "__main__":
    main()
