#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_missing_assets.py — หา "ไฟล์ที่ถูกอ้างถึงแต่ไม่มีอยู่จริง" ทั้งโปรเจกต์ (รอบ 91)

★ ทำไมต้องมี ★
  ตอนแก้ภาพแล้วเปลี่ยนชื่อไฟล์/ย้ายที่ ไฟล์ .tres ที่อ้างถึงจะไม่ถูกแก้ตาม
  ในโปรแกรม Godot มันแค่ขึ้นเตือนแล้วเล่นต่อได้ **แต่ตอน export เกมจริงมันคือช่องว่าง**
  (เช่น ดาบหายจากมือ · ท่าตาย/ท่าโดนตีของมอนไม่มีภาพ)
  เจอครั้งแรกตอน export เว็บรอบ 91 — โผล่มา 4 จุด ทั้งที่บนเครื่องเล่นได้ปกติ

★ โหมดซ่อมอัตโนมัติ (--fix-obvious) ★
  ซ่อมให้เฉพาะกรณีที่ "เดาไม่ผิดแน่" เท่านั้น:
    · ในโฟลเดอร์เดียวกันมีไฟล์ภาพที่ **ไม่มีใครอ้างถึงเลย** อยู่ **ไฟล์เดียว**
    · และขนาดภาพนั้นใหญ่พอสำหรับ region ที่ไฟล์นั้นถูกใช้อยู่
  ถ้าเข้าเงื่อนไขไม่ครบ = แค่รายงาน ไม่แตะ (ให้คนตัดสินใจ)

รัน: python3 check_missing_assets.py               (รายงานอย่างเดียว)
     python3 check_missing_assets.py --fix-obvious (ซ่อมเฉพาะที่ชัดเจน)
"""
import io
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
FIX = "--fix-obvious" in sys.argv
BAK = os.path.join(ROOT, "_to_delete", "originals_refs_r91")
SKIP_DIRS = {".godot", ".git", "_to_delete", "__pycache__", "build"}
IMG_EXT = (".png", ".webp", ".jpg", ".jpeg", ".svg")

try:
    from PIL import Image
    Image.MAX_IMAGE_PIXELS = None
except ImportError:
    Image = None


def rd(p):
    try:
        return io.open(p, encoding="utf-8", errors="replace").read()
    except OSError:
        return ""


def walk_files(exts):
    for root, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for f in files:
            if f.endswith(exts):
                yield os.path.join(root, f)


def main():
    if not FIX:
        print("★ โหมดรายงานอย่างเดียว ★ ใส่ --fix-obvious ถึงจะซ่อมให้\n")

    # ---------- 1) รวบรวมทุก res:// ที่ถูกอ้างถึง ----------
    refs = {}          # res path -> [ไฟล์ที่อ้าง]
    for p in walk_files((".tres", ".tscn", ".godot", ".cfg")):
        for m in re.finditer(r'path="(res://[^"]+)"', rd(p)):
            refs.setdefault(m.group(1), []).append(os.path.relpath(p, ROOT))

    missing = {}
    for res, users in refs.items():
        rel = res[len("res://"):]
        if rel.startswith(".godot/"):
            continue
        if not os.path.exists(os.path.join(ROOT, rel)):
            missing[res] = users

    if not missing:
        print("ไม่มีไฟล์ที่อ้างถึงแล้วหาย — เรียบร้อยดี")
        return

    print("★ เจอไฟล์ที่ถูกอ้างถึงแต่ไม่มีอยู่จริง %d รายการ ★\n" % len(missing))

    # ---------- 2) ไฟล์ภาพที่ไม่มีใครอ้างถึง (ตัวที่น่าจะเป็นของแทน) ----------
    referenced = set(r[len("res://"):] for r in refs)
    orphan_by_dir = {}
    for p in walk_files(IMG_EXT):
        rel = os.path.relpath(p, ROOT).replace(os.sep, "/")
        if rel in referenced:
            continue
        orphan_by_dir.setdefault(os.path.dirname(rel), []).append(rel)

    fixed = 0
    for res in sorted(missing):
        rel = res[len("res://"):]
        users = missing[res]
        print("  ✗ %s" % rel)
        print("      ถูกอ้างโดย: %s" % ", ".join(sorted(set(users))[:3]))

        d = os.path.dirname(rel)
        cands = orphan_by_dir.get(d, [])
        if len(cands) != 1 or not rel.lower().endswith(IMG_EXT):
            print("      → เดาแทนไม่ได้ (ไฟล์ที่ไม่มีใครใช้ในโฟลเดอร์นี้: %d) — ต้องดูเอง\n"
                  % len(cands))
            continue
        cand = cands[0]

        # ต้องใหญ่พอสำหรับ region ที่ถูกใช้อยู่
        need_w = need_h = 0
        for u in set(users):
            s = rd(os.path.join(ROOT, u))
            eid = re.search(r'\[ext_resource type="Texture2D"[^\]]*path="%s" id="([^"]+)"\]'
                            % re.escape(res), s)
            if not eid:
                continue
            for m in re.finditer(r'\[sub_resource type="AtlasTexture" id="[^"]+"\](.*?)(?=\n\[|\Z)',
                                 s, re.S):
                if 'ExtResource("%s")' % eid.group(1) not in m.group(1):
                    continue
                r = re.search(r"region = Rect2\(([^)]*)\)", m.group(1))
                if r:
                    n = [float(x) for x in r.group(1).split(",")]
                    need_w = max(need_w, n[0] + n[2])
                    need_h = max(need_h, n[1] + n[3])
        ok = True
        if Image is not None:
            try:
                cw, ch = Image.open(os.path.join(ROOT, cand)).size
                ok = cw >= need_w and ch >= need_h
                print("      ผู้ต้องสงสัย: %s (%dx%d · ต้องการอย่างน้อย %.0fx%.0f) %s"
                      % (os.path.basename(cand), cw, ch, need_w, need_h, "✔ พอ" if ok else "✗ เล็กไป"))
            except Exception:
                pass
        if not ok:
            print("      → ขนาดไม่พอ ไม่ซ่อมให้\n")
            continue

        if FIX:
            os.makedirs(BAK, exist_ok=True)
            for u in sorted(set(users)):
                up = os.path.join(ROOT, u)
                s = rd(up)
                out = s.replace(res, "res://" + cand)
                if out == s:
                    continue
                b = os.path.join(BAK, u.replace(os.sep, "__").replace("/", "__"))
                if not os.path.exists(b):
                    shutil.copy2(up, b)
                # uid เดิมชี้ไฟล์เก่า ต้องถอดออกให้ Godot หาใหม่จาก path
                out = re.sub(r'(\[ext_resource type="Texture2D") uid="[^"]*"( [^\]]*path="res://%s")'
                             % re.escape(cand), r"\1\2", out)
                io.open(up, "w", encoding="utf-8", newline="\n").write(out)
                print("      ✔ แก้ %s → %s" % (u, os.path.basename(cand)))
            fixed += 1
        else:
            print("      → ซ่อมได้ (ใส่ --fix-obvious)")
        print()

    print("=" * 70)
    if FIX:
        print("ซ่อมแล้ว %d รายการ · เหลือต้องดูเอง %d" % (fixed, len(missing) - fixed))
        if fixed:
            print("สำรองไฟล์เดิมไว้ที่ %s" % os.path.relpath(BAK, ROOT))
            print("★ เปิด Godot ให้ import ใหม่ แล้วเช็คในห้อง GM (F10) ว่าท่าที่เคยหายกลับมาครบ ★")
    else:
        print("(ยังไม่ได้ซ่อม)")


if __name__ == "__main__":
    main()
