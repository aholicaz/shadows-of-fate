#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
webtrim.py — ย่อชีทมอน "เฉพาะในสำเนาสำหรับเว็บ" (รอบ 91)

★ ปัญหาที่ต้องแก้ ★
  GitHub **ไม่รับไฟล์เดียวที่ใหญ่เกิน 100 MB** แต่ index.pck ของเวอร์ชันเว็บอยู่ที่ 189 MB
  ในนั้นเป็นชีทมอน 85 MB (ครึ่งหนึ่งของทั้งก้อน)

★ ทำไมย่อชีทมอนแล้วภาพในเกมไม่เล็กลง ★
  มอนใช้ระบบ auto-fit — `MonsterData.display_height` บอก "ให้สูงเท่านี้บนจอ"
  แล้ว `monster_base._fit_frames()` วัดความสูงเนื้อภาพจริงแล้วคิดสเกลเอง
  ชีทเล็กลงครึ่งหนึ่ง → วัดได้ครึ่งหนึ่ง → สเกลคูณสองอัตโนมัติ = **ขนาดบนจอเท่าเดิม**
  (ต่างจากฉากหลังที่ใส่ scale ไว้ตายตัวในไฟล์ฉาก — พวกนั้นห้ามย่อ ไม่งั้นเล็กลงจริง)

  ส่วนพิกัด region ในไฟล์ท่าทางต้องคูณตามด้วย ไม่งั้นเฟรมเพี้ยนทั้งชุด — สคริปต์นี้แก้ให้

★ ใช้กับสำเนาสำหรับเว็บเท่านั้น ★ อย่ารันในโปรเจกต์จริง (เวอร์ชันคอมควรได้ภาพเต็มความละเอียด)

รัน: python3 webtrim.py 0.5           (ดูอย่างเดียว)
     python3 webtrim.py 0.5 --apply
"""
import io
import os
import re
import sys

from PIL import Image

Image.MAX_IMAGE_PIXELS = None
ROOT = os.path.dirname(os.path.abspath(__file__))
APPLY = "--apply" in sys.argv
SCALE = 0.5
for a in sys.argv[1:]:
    try:
        SCALE = float(a)
        break
    except ValueError:
        pass

TARGET_DIRS = ("Sprites/monster",)


def rd(p):
    try:
        return io.open(p, encoding="utf-8").read()
    except OSError:
        return ""


def main():
    if not APPLY:
        print("★ โหมดดูอย่างเดียว ★ ใส่ --apply ถึงจะย่อจริง")
    print("ย่อเป็น %.0f%% ของเดิม · เฉพาะ %s\n" % (SCALE * 100, ", ".join(TARGET_DIRS)))

    # ---------- 1) ย่อภาพ ----------
    targets = {}
    for d in TARGET_DIRS:
        for root, _dd, files in os.walk(os.path.join(ROOT, d)):
            for f in sorted(files):
                if not f.lower().endswith((".png", ".webp", ".jpg")):
                    continue
                p = os.path.join(root, f)
                rel = os.path.relpath(p, ROOT).replace(os.sep, "/")
                targets[rel] = p

    before = after = 0
    factors = {}
    for rel, p in sorted(targets.items()):
        try:
            im = Image.open(p)
        except Exception:
            continue
        w, h = im.size
        nw, nh = max(4, int(round(w * SCALE / 4)) * 4), max(4, int(round(h * SCALE / 4)) * 4)
        if nw >= w:
            continue
        sz0 = os.path.getsize(p)
        before += sz0
        if APPLY:
            im.convert("RGBA").resize((nw, nh), Image.LANCZOS).save(p)
            after += os.path.getsize(p)
        else:
            after += int(sz0 * SCALE * SCALE)
        factors[rel] = (nw / float(w), nh / float(h))

    print("ย่อภาพ %d ไฟล์ · %.0f MB → %.0f MB" % (len(factors), before / 1048576, after / 1048576))

    # ---------- 2) คูณพิกัด region ตาม ----------
    n_fix = 0
    for root, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in (".godot", ".git", "_to_delete", "__pycache__", "build")]
        for f in files:
            if not f.endswith((".tres", ".tscn")):
                continue
            p = os.path.join(root, f)
            s = rd(p)
            if "AtlasTexture" not in s:
                continue
            ext = dict(re.findall(r'\[ext_resource type="Texture2D"[^\]]*path="([^"]+)" id="([^"]+)"\]', s))
            idfac = {}
            for path, eid in ext.items():
                r = path.replace("res://", "")
                if r in factors:
                    idfac[eid] = factors[r]
            if not idfac:
                continue

            def fix(m):
                body = m.group(0)
                a = re.search(r'atlas = ExtResource\("([^"]+)"\)', body)
                if not a or a.group(1) not in idfac:
                    return body
                sx, sy = idfac[a.group(1)]

                def sc(rm):
                    n = [float(x) for x in rm.group(1).split(",")]
                    n = [n[0] * sx, n[1] * sy, n[2] * sx, n[3] * sy]
                    return "region = Rect2(%s)" % ", ".join("%g" % round(v) for v in n)

                return re.sub(r"region = Rect2\(([^)]*)\)", sc, body)

            out = re.sub(r'\[sub_resource type="AtlasTexture" id="[^"]+"\](?:.*?)(?=\n\[|\Z)',
                         fix, s, flags=re.S)
            if out != s:
                if APPLY:
                    io.open(p, "w", encoding="utf-8", newline="\n").write(out)
                n_fix += 1

    print("แก้พิกัดเฟรมในไฟล์ท่าทาง %d ไฟล์" % n_fix)
    if not APPLY:
        print("\n(ยังไม่ได้ย่อจริง)")


if __name__ == "__main__":
    main()
