#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
shrink_cards.py — ย่อภาพการ์ดใน Sprites/card/ ให้เล็กลงมาก ๆ แล้วตั้งชื่อตามมอน

ทำอะไร
  1) ย่อเป็น 640×960 (คงสัดส่วน 2:3 ของการ์ด) — ใหญ่กว่าที่เกมแสดงจริงราว 5 เท่า
     (ที่ใหญ่สุดตอนนี้คือกล่องรายละเอียดไอเทม 120×120 · สมุดการ์ด 84×96)
  2) เซฟเป็น .webp คุณภาพ 90 — ภาพการ์ดไม่มีพื้นโปร่ง เลยใช้ webp ได้เต็มที่
     (Godot 4 รองรับ .webp ในตัว ไม่ต้องตั้งอะไรเพิ่ม)
  3) ตั้งชื่อใหม่เป็น card_<id ของมอน>.webp ตามชื่อที่พิมพ์อยู่บนการ์ด
  4) ย้ายไฟล์ต้นฉบับ (+ .import ที่ค้าง) ไป _to_delete/originals_card_r85/

ผล: 55 MB → ~5.6 MB (เล็กลง ~90%)

ใช้:  python3 shrink_cards.py           (ดูอย่างเดียว)
      python3 shrink_cards.py --apply   (ทำจริง)
"""
import os
import sys
import shutil

from PIL import Image

APPLY = "--apply" in sys.argv
ROOT = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(ROOT, "Sprites", "card")
BAK = os.path.join(ROOT, "_to_delete", "originals_card_r85")

WIDTH, HEIGHT = 640, 960
QUALITY = 90

# ชื่อไฟล์เดิม (8 ตัวแรกของ uuid) -> id ของมอน · อ่านจากชื่อที่พิมพ์บนตัวการ์ด
NAME_MAP = {
    "08fe41f8": "ember_bat",
    "0b481715": "hornet",
    "1521bbee": "poring",
    "1b7a6068": "stormscar",
    "33776b7a": "magma_slug",
    "34e1c089": "baphomet_jr",
    "4102fd66": "king_poring",
    "4a6d22a2": "pitman",
    "67e911e9": "chonchon",
    "6dba4497": "lunatic",
    "9fdb0eac": "munak",          # บนการ์ดเขียน "Munuk" — id ในเกมคือ munak
    "add1101d": "forge_golem",
    "c6425591": "drops",
    "c9367358": "forge_guardian",
    "c94e23bf": "fabre",
    "cdabcd97": "steel_beetle",
    "d7e28850": "silent_wraith",
    "d890fb22": "wolf",
    "dd255cc1": "baphomet",
    "ee926dc0": "orc_warrior",
}


def key_of(fname):
    """ดึง 8 ตัวแรกของ uuid ออกจากชื่อไฟล์ exec-<uuid>.png"""
    base = os.path.splitext(fname)[0]
    if base.startswith("exec-"):
        return base[5:13]
    return None


def main():
    if not os.path.isdir(SRC):
        print("ไม่มีโฟลเดอร์ %s" % SRC)
        return
    if not APPLY:
        print("★ โหมดดูอย่างเดียว ★ ใส่ --apply ถึงจะทำจริง\n")

    files = sorted(f for f in os.listdir(SRC) if f.lower().endswith(".png"))
    if not files:
        print("ไม่มีไฟล์ .png ให้ย่อ (อาจย่อไปแล้ว)")
        return

    if APPLY:
        os.makedirs(BAK, exist_ok=True)

    before = after = 0
    done = skipped = 0
    for f in files:
        src = os.path.join(SRC, f)
        k = key_of(f)
        mid = NAME_MAP.get(k)
        if mid is None:
            print("  ข้าม %s — ไม่รู้ว่าเป็นการ์ดของมอนตัวไหน (เพิ่มใน NAME_MAP ก่อน)" % f)
            skipped += 1
            continue

        out_name = "card_%s.webp" % mid
        out = os.path.join(SRC, out_name)
        sz = os.path.getsize(src)
        before += sz

        im = Image.open(src).convert("RGB")
        print("  %-46s %4dx%-5d %6.2f MB  →  %-26s %dx%d"
              % (f, im.width, im.height, sz / 1048576, out_name, WIDTH, HEIGHT))
        if not APPLY:
            continue

        im.resize((WIDTH, HEIGHT), Image.LANCZOS).save(out, "WEBP", quality=QUALITY, method=6)
        after += os.path.getsize(out)
        # ย้ายต้นฉบับ + .import ที่ค้างไปโฟลเดอร์สำรอง (device_bash ลบไฟล์ไม่ได้)
        shutil.move(src, os.path.join(BAK, f))
        imp = src + ".import"
        if os.path.exists(imp):
            shutil.move(imp, os.path.join(BAK, f + ".import"))
        done += 1

    print()
    if APPLY:
        print("ย่อ %d ไฟล์ (ข้าม %d) · %.1f MB → %.1f MB  (เหลือ %.0f%%)"
              % (done, skipped, before / 1048576, after / 1048576,
                 after / before * 100 if before else 0))
        print("ต้นฉบับย้ายไปที่ %s" % os.path.relpath(BAK, ROOT))
    else:
        print("รวม %d ไฟล์ %.1f MB — ใส่ --apply เพื่อทำจริง" % (len(files), before / 1048576))


if __name__ == "__main__":
    main()
