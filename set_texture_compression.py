#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
set_texture_compression.py — รอบ 90: ตั้ง compress/mode ให้ภาพทุกไฟล์

★ compress/mode คืออะไร ★ (วัดจริงจากชีท Stormscar/idle.png 4096x2048 ด้วย Godot 4.4.1)

  ภาพ 1 ไฟล์มี "2 ขนาด" ที่คนละเรื่องกัน
    · ขนาดไฟล์  = ที่กินในเครื่อง/ในไฟล์เกมที่ผู้เล่นโหลด
    · ขนาด VRAM = ที่กินในการ์ดจอตอนภาพนั้นอยู่บนจอ  ← ตัวที่ทำเกมกระตุก/แครช

  โหมด                    ไฟล์      VRAM     คุณภาพ (PSNR)   ผิดเฉลี่ยต่อพิกเซล
  ------------------------------------------------------------------------------
  0 Lossless (ที่ใช้อยู่)  11.76 MB  42.7 MB  ไม่เสียเลย        0
  1 Lossy q0.70            2.52 MB  42.7 MB  30.4 dB          5.87 / 255
  1 Lossy q0.95            4.29 MB  42.7 MB  37.4 dB          2.48 / 255
  2 VRAM ธรรมดา (BC3)     10.67 MB  10.7 MB  28.0 dB          6.93 / 255   ← alpha เพี้ยนได้ถึง 31
  2 VRAM คุณภาพสูง (BC7)  10.67 MB  10.7 MB  34.9 dB          2.83 / 255   ★ ที่แนะนำ

  อ่านตารางนี้ยังไง
    · โหมด 1 (Lossy) = ย่อ "ไฟล์" 4.7 เท่า แต่ **VRAM เท่าเดิม** เพราะพอโหลดขึ้นการ์ดจอ
      Godot ต้องคลายกลับเป็น RGBA เต็ม ๆ อยู่ดี → ช่วยเรื่องดาวน์โหลด ไม่ช่วยเรื่องกระตุก
    · โหมด 2 (VRAM Compressed) = แปลงเป็นรูปแบบที่ **การ์ดจออ่านทั้งก้อนบีบอัดได้เลย ไม่ต้องคลาย**
      → VRAM ลง 4 เท่าถาวร แต่ "ไฟล์" แทบไม่เล็กลง (10.67 vs 11.76) เพราะมันคือข้อมูลดิบของ GPU
    · ทำไมเสียคุณภาพ: มันบีบทีละบล็อก 4x4 พิกเซล เก็บแค่ 2 สีหลัก + สูตรผสม
      ขอบที่สีตัดกันจัด ๆ กับไล่เฉดนุ่ม ๆ จะเห็นรอยได้ — BC7 เก็บละเอียดกว่ามาก จึงเลือกตัวนี้

  ที่เลือก: **โหมด 2 + high_quality = true (BC7)**  ผิดเฉลี่ย 2.83/255 = ตาไม่เห็น
  แต่ VRAM ของชีทมอนทั้งเกม 1,623 MB → 406 MB

★ ยกเว้นให้ ★
  · ภาพเล็กกว่า 256x256 — บล็อก 4x4 กินสัดส่วนเยอะ เห็นรอยง่าย และประหยัดได้ไม่กี่ MB
  · โฟลเดอร์ที่สั่งข้ามเอง (SKIP_DIRS) — ฟอนต์/ไอคอนหน้าต่างที่ต้องคมกริบ

รัน: python3 set_texture_compression.py            (ดูอย่างเดียว)
     python3 set_texture_compression.py --apply    (แก้จริง — ปิด Godot ก่อน)
     python3 set_texture_compression.py --apply --revert   (กลับเป็น Lossless เหมือนเดิม)

★ หลังรัน เปิด Godot แล้วมันจะ import ภาพใหม่ทั้งหมด (หลายนาที) ★
"""
import io
import os
import re
import sys

APPLY = "--apply" in sys.argv
REVERT = "--revert" in sys.argv
ROOT = os.path.dirname(os.path.abspath(__file__))

MIN_SIDE = 256          # ภาพเล็กกว่านี้ไม่แตะ
SKIP_DIRS = ("Sprites/ui/", "Sprites/font")

try:
    from PIL import Image
    Image.MAX_IMAGE_PIXELS = None
except ImportError:
    Image = None


def rd(p):
    return io.open(p, encoding="utf-8").read()


def set_key(text, key, value):
    if re.search(r"^%s=" % re.escape(key), text, re.M):
        return re.sub(r"^%s=.*$" % re.escape(key), "%s=%s" % (key, value), text, flags=re.M)
    return text.rstrip("\n") + "\n%s=%s\n" % (key, value)


def size_of(src):
    if Image is None:
        return (9999, 9999)
    try:
        return Image.open(src).size
    except Exception:
        return (0, 0)


def main():
    if not APPLY:
        print("★ โหมดดูอย่างเดียว ★ ใส่ --apply ถึงจะแก้จริง (ปิด Godot ก่อน)\n")
    mode = "0" if REVERT else "2"
    hq = "false" if REVERT else "true"
    print("จะตั้ง compress/mode=%s · high_quality=%s%s\n" % (mode, hq, "  (ย้อนกลับเป็นเดิม)" if REVERT else ""))

    changed = skipped_small = skipped_dir = already = 0
    saved_px = 0
    for root, _d, files in os.walk(os.path.join(ROOT, "Sprites")):
        for f in sorted(files):
            if not f.endswith(".import"):
                continue
            p = os.path.join(root, f)
            s = rd(p)
            if 'importer="texture"' not in s:
                continue
            rel = os.path.relpath(p, ROOT).replace(os.sep, "/")
            if any(rel.startswith(d) for d in SKIP_DIRS):
                skipped_dir += 1
                continue
            src = p[:-len(".import")]
            w, h = size_of(src)
            if w < MIN_SIDE or h < MIN_SIDE:
                skipped_small += 1
                continue

            out = set_key(s, "compress/mode", mode)
            out = set_key(out, "compress/high_quality", hq)
            if out == s:
                already += 1
                continue
            if APPLY:
                io.open(p, "w", encoding="utf-8", newline="\n").write(out)
            changed += 1
            saved_px += w * h

    mb_now = saved_px * 4 * 1.333 / 1048576
    mb_new = saved_px * 1 * 1.333 / 1048576
    print("แก้ %d ไฟล์ · ตั้งไว้ถูกแล้ว %d · ข้ามเพราะภาพเล็ก %d · ข้ามโฟลเดอร์ %d"
          % (changed, already, skipped_small, skipped_dir))
    if not REVERT:
        print("VRAM ของภาพชุดนี้: %.0f MB → %.0f MB (ลด %.0f MB)" % (mb_now, mb_new, mb_now - mb_new))
    if APPLY:
        print("\nเสร็จ — เปิด Godot แล้วรอ import ใหม่ (หลายนาที) · ถ้าไม่ชอบผลลัพธ์ รันซ้ำด้วย --revert")
    else:
        print("\n(ยังไม่ได้แก้จริง)")


if __name__ == "__main__":
    main()
