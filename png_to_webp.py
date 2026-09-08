#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
png_to_webp.py — แปลงภาพต้นฉบับ PNG → WebP (รอบ 90)

★ วัดจริงจากชีท Stormscar/idle.png 4096x2048 (11.31 MB) ★

  รูปแบบ            ขนาด     เล็กลง   คุณภาพ
  ------------------------------------------------------------
  PNG optimize      10.08 MB  1.1x    ไม่เสียเลย
  WebP lossless      7.92 MB  1.4x    ★ ไม่เสียเลยสักพิกเซล ★   ← ค่าเริ่มต้นของสคริปต์นี้
  WebP q95           2.98 MB  3.8x    35.4 dB (ผิดเฉลี่ย 2.94/255)
  WebP q90           2.47 MB  4.6x    34.2 dB (ผิดเฉลี่ย 3.57/255)

  โหมดปกติ (lossless) = **ภาพเหมือนเดิมทุกพิกเซล** แค่บีบอัดเก่งกว่า PNG
  ใส่ --quality 95 ถ้ายอมเสียนิดเดียวเพื่อให้เล็กลง 3.8 เท่า (เท่า ๆ กับที่ BC7 เสียอยู่แล้ว)

★ ทำไมถึงคุ้ม ★
  · โฟลเดอร์ Sprites 750 MB → ราว 530 MB (lossless) หรือ ~200 MB (q95)
  · GitHub เบาลงทุกครั้งที่คอมมิตต่อจากนี้
  · ไฟล์เกมเวอร์ชันเว็บเล็กลง = โหลดเร็วขึ้น
  · **ไม่มีผลกับ VRAM** — VRAM ขึ้นกับ compress/mode กับขนาดภาพ ไม่ใช่รูปแบบไฟล์ต้นฉบับ

★ สคริปต์นี้ทำอะไรบ้าง (เยอะ — อ่านก่อนรัน) ★
  1. แปลง Sprites/**/*.png → .webp
  2. ไล่แก้ทุกที่ที่อ้างชื่อไฟล์เดิม: .tres · .tscn · .gd · .godot ไม่ต้องยุ่ง (import ใหม่เอง)
  3. ย้าย .png และ .png.import เดิมไปไว้ที่ _to_delete/originals_png_r90/ (ไม่ได้ลบทิ้ง)
  4. สร้าง .webp.import ให้โดยยกค่าจาก .png.import เดิมมาทั้งหมด (mipmaps · compress/mode คงเดิม)

★ ก่อนรัน ★
  · ปิด Godot
  · คอมมิตงานที่ค้างไว้ก่อน (เผื่ออยากย้อน)
  · รันแบบดูอย่างเดียวก่อนเสมอ

รัน: python3 png_to_webp.py                     (ดูอย่างเดียว)
     python3 png_to_webp.py --apply             (แปลงจริง · lossless ไม่เสียคุณภาพ)
     python3 png_to_webp.py --apply --quality 95
     python3 png_to_webp.py --apply --only Sprites/monster
"""
import io
import os
import re
import shutil
import sys

from PIL import Image

Image.MAX_IMAGE_PIXELS = None
APPLY = "--apply" in sys.argv
ROOT = os.path.dirname(os.path.abspath(__file__))
BAK = os.path.join(ROOT, "_to_delete", "originals_png_r90")

QUALITY = 0        # 0 = lossless
ONLY = ""
for i, a in enumerate(sys.argv):
    if a == "--quality" and i + 1 < len(sys.argv):
        QUALITY = int(sys.argv[i + 1])
    if a == "--only" and i + 1 < len(sys.argv):
        ONLY = sys.argv[i + 1].replace("\\", "/").strip("/")

# ไฟล์ที่ห้ามแตะ — ไอคอนหน้าต่างเกมกับโลโก้ต้องเป็น PNG
SKIP = ("icon.png", "icon.svg")
TEXT_EXT = (".tres", ".tscn", ".gd", ".cfg", ".godot")


def rd(p):
    return io.open(p, encoding="utf-8", errors="replace").read()


def collect():
    out = []
    for root, _d, files in os.walk(os.path.join(ROOT, "Sprites")):
        for f in sorted(files):
            if not f.lower().endswith(".png") or f in SKIP:
                continue
            p = os.path.join(root, f)
            rel = os.path.relpath(p, ROOT).replace(os.sep, "/")
            if ONLY and not rel.startswith(ONLY):
                continue
            out.append(rel)
    return out


def convert(rel):
    src = os.path.join(ROOT, rel)
    dst = src[:-4] + ".webp"
    im = Image.open(src)
    im = im.convert("RGBA") if "A" in im.getbands() or im.mode == "P" else im.convert("RGB")
    if QUALITY <= 0:
        im.save(dst, "WEBP", lossless=True, quality=100, method=4)
    else:
        im.save(dst, "WEBP", quality=QUALITY, method=4)
    return dst


def make_import(rel):
    """สร้าง .webp.import โดยยกค่าจาก .png.import เดิม (ยกเว้น uid/path ที่ต้องให้ Godot สร้างใหม่)"""
    old = os.path.join(ROOT, rel + ".import")
    new = os.path.join(ROOT, rel[:-4] + ".webp.import")
    if not os.path.exists(old):
        return False
    s = rd(old)
    s = s.replace(rel, rel[:-4] + ".webp")
    # ให้ Godot สร้าง uid กับไฟล์ปลายทางใหม่เอง
    s = re.sub(r'^uid=".*"$', "", s, flags=re.M)
    s = re.sub(r'^path=".*"$', "", s, flags=re.M)
    s = re.sub(r"^dest_files=.*$", "dest_files=[]", s, flags=re.M)
    s = re.sub(r"\n{3,}", "\n\n", s)
    if APPLY:
        io.open(new, "w", encoding="utf-8", newline="\n").write(s)
    return True


def rewrite_refs(renames):
    """แก้ทุกไฟล์ข้อความที่อ้างชื่อไฟล์ .png เดิม"""
    hits = {}
    for root, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in (".godot", ".git", "_to_delete", "__pycache__", "build")]
        for f in files:
            if not f.endswith(TEXT_EXT):
                continue
            p = os.path.join(root, f)
            try:
                s = rd(p)
            except Exception:
                continue
            out = s
            for old in renames:
                if old in out:
                    out = out.replace(old, old[:-4] + ".webp")
            if out != s:
                hits[os.path.relpath(p, ROOT)] = sum(1 for o in renames if o in s)
                if APPLY:
                    io.open(p, "w", encoding="utf-8", newline="\n").write(out)
    return hits


def main():
    if not APPLY:
        print("★ โหมดดูอย่างเดียว ★ ใส่ --apply ถึงจะแปลงจริง (ปิด Godot ก่อน)\n")
    print("โหมด: %s%s\n" % ("WebP lossless (ไม่เสียคุณภาพ)" if QUALITY <= 0 else "WebP q%d" % QUALITY,
                            "  · เฉพาะ %s" % ONLY if ONLY else ""))

    pngs = collect()
    if not pngs:
        print("ไม่เจอไฟล์ .png ที่ต้องแปลง")
        return
    print("เจอ %d ไฟล์\n" % len(pngs))
    if APPLY:
        os.makedirs(BAK, exist_ok=True)

    before = after = 0
    done = []
    for i, rel in enumerate(pngs, 1):
        src = os.path.join(ROOT, rel)
        sz0 = os.path.getsize(src)
        before += sz0
        if APPLY:
            try:
                dst = convert(rel)
            except Exception as e:
                print("  ! แปลงไม่ได้ %s (%s)" % (rel, e))
                after += sz0
                continue
            sz1 = os.path.getsize(dst)
            make_import(rel)
        else:
            sz1 = int(sz0 * (0.70 if QUALITY <= 0 else 0.26))
        after += sz1
        done.append(rel)
        if i % 50 == 0 or i == len(pngs):
            print("  แปลงแล้ว %d/%d ..." % (i, len(pngs)))

    print("\nแก้ที่อ้างชื่อไฟล์เดิม")
    hits = rewrite_refs(done)
    for p, n in sorted(hits.items())[:12]:
        print("  · %-58s %d จุด" % (p, n))
    if len(hits) > 12:
        print("  · ... อีก %d ไฟล์" % (len(hits) - 12))
    print("  รวม %d ไฟล์" % len(hits))

    if APPLY:
        print("\nย้ายไฟล์ .png เดิมไปเก็บไว้")
        for rel in done:
            for suf in ("", ".import"):
                p = os.path.join(ROOT, rel + suf)
                if not os.path.exists(p):
                    continue
                b = os.path.join(BAK, (rel + suf).replace("/", "__"))
                if not os.path.exists(b):
                    shutil.move(p, b)
                else:
                    os.remove(p)

    print("\n%d ไฟล์ · %.0f MB → %.0f MB (ลด %.0f MB · %.2f เท่า)"
          % (len(done), before / 1048576, after / 1048576,
             (before - after) / 1048576, before / max(1, after)))
    if APPLY:
        print("ไฟล์ .png เดิมอยู่ที่ %s (ลบเองได้เมื่อมั่นใจแล้ว)" % os.path.relpath(BAK, ROOT))
        print("★ เปิด Godot แล้วรอ import ภาพใหม่ทั้งหมด (หลายนาที) ★")
    else:
        print("(ยังไม่ได้แปลงจริง — ตัวเลขเป็นการประมาณ)")


if __name__ == "__main__":
    main()
