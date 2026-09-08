#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
shrink_sheets.py — ย่อชีทที่ "ละเอียดเกินที่จอจะใช้จริง" (รอบ 90)

★ ทำไมไม่ย่อทุกใบเหลือ 2048 ★
  เกมตั้ง stretch/mode = canvas_items → Godot วาดที่ความละเอียดจริงของหน้าต่าง
  มอนที่ display_height = 320 บนจอ 4K กินจริง 320 x 3 = 960 พิกเซล
  ชีท 4096x2048 (ช่องละ ~512) จึง **ไม่ได้ใหญ่เกิน** สำหรับจอใหญ่
  ย่อเหลือ 2048 = ช่องละ 256 = เล็กกว่าที่จอ 4K ต้องใช้ 3.75 เท่า → เบลอชัดเจน

  สคริปต์นี้จึงย่อ "เฉพาะใบที่วัดแล้วว่าเกินจริง" (ดูผลจาก check_sheet_size.py)
  โดยคุมไม่ให้เนื้อภาพต่ำกว่าที่จอเป้าหมายต้องใช้

★ ย่อชีทแล้วต้องแก้อะไรอีก ★
  ชีทถูกหั่นด้วย AtlasTexture ที่จำพิกัด region ไว้เป็นตัวเลขพิกเซล
  ย่อภาพแล้วไม่แก้พิกัด = เฟรมเพี้ยนหมด → สคริปต์นี้แก้ region ในไฟล์ SpriteFrames ให้ด้วย
  (ไฟล์ไหนที่ทุกเฟรมใช้ "ทั้งภาพ" ไม่ต้องแก้อะไร)

รัน: python3 shrink_sheets.py                       (ดูอย่างเดียว · เป้า 4K)
     python3 shrink_sheets.py --apply               (ย่อจริง)
     python3 shrink_sheets.py --target 1440p --apply (ย่อแรงกว่า ประหยัดกว่า)
"""
import io
import os
import re
import shutil
import sys

import numpy as np
from PIL import Image

Image.MAX_IMAGE_PIXELS = None
APPLY = "--apply" in sys.argv
ROOT = os.path.dirname(os.path.abspath(__file__))
BAK = os.path.join(ROOT, "_to_delete", "originals_sheets_r90")
ALPHA_MIN = 20
VIEWPORT_H = 720.0
MIN_GAIN = 1.15          # ย่อได้น้อยกว่านี้ไม่คุ้ม ไม่แตะ

TARGETS = {"1080p": 1080.0 / VIEWPORT_H, "1440p": 1440.0 / VIEWPORT_H, "4k": 2160.0 / VIEWPORT_H}
target = "4k"
for i, a in enumerate(sys.argv):
    if a == "--target" and i + 1 < len(sys.argv):
        target = sys.argv[i + 1].lower()
SCALE = TARGETS.get(target, TARGETS["4k"])

_cache = {}


def rd(p):
    try:
        return io.open(p, encoding="utf-8").read()
    except OSError:
        return ""


def alpha_of(path):
    if path not in _cache:
        try:
            _cache[path] = np.array(Image.open(path).convert("RGBA"))[:, :, 3]
        except Exception:
            _cache[path] = None
    return _cache[path]


def frames_of(tres_text, animations_block=None):
    ext = dict(re.findall(r'\[ext_resource type="Texture2D"[^\]]*path="([^"]+)" id="([^"]+)"\]', tres_text))
    ext = {v: k for k, v in ext.items()}
    subs = {}
    for m in re.finditer(r'\[sub_resource type="AtlasTexture" id="([^"]+)"\](.*?)(?=\n\[|\Z)', tres_text, re.S):
        body = m.group(2)
        a = re.search(r'atlas = ExtResource\("([^"]+)"\)', body)
        r = re.search(r'region = Rect2\(([^)]*)\)', body)
        if a and r:
            nums = [float(x) for x in r.group(1).split(",")]
            subs[m.group(1)] = (ext.get(a.group(1), ""), nums)
    src = animations_block if animations_block is not None else tres_text
    out = {}
    for blk in re.finditer(r'\{\s*"frames": \[(.*?)\],\s*"loop": \d+,\s*\n?"name": &"([^"]*)"', src, re.S):
        rows = []
        for kind, ref in re.findall(r'(SubResource|ExtResource)\("([^"]+)"\)', blk.group(1)):
            if kind == "SubResource" and ref in subs:
                pth, n = subs[ref]
                rows.append((pth.replace("res://", ""), int(n[0]), int(n[1]), int(n[2]), int(n[3])))
            elif kind == "ExtResource" and ref in ext:
                rows.append((ext[ref].replace("res://", ""), 0, 0, 0, 0))
        if rows:
            out[blk.group(2)] = rows
    return out


def content_h(rows):
    hs = []
    for path, x, y, w, h in rows:
        a = alpha_of(os.path.join(ROOT, path))
        if a is None:
            continue
        sub = (a if w <= 0 else a[y:y + h, x:x + w]) > ALPHA_MIN
        if not sub.any():
            continue
        nz = np.nonzero(sub.any(axis=1))[0]
        hs.append(int(nz[-1] - nz[0] + 1))
    if not hs:
        return 0
    hs.sort()
    return hs[len(hs) // 2]


def sheet_files():
    """{ไฟล์ SpriteFrames หรือไฟล์มอน: (ข้อความ, {ท่า: rows})} + display_height ของมอน"""
    out = []
    mdir = os.path.join(ROOT, "data", "monsters")
    for f in sorted(os.listdir(mdir)):
        if not f.endswith(".tres"):
            continue
        t = rd(os.path.join(mdir, f))
        dh = re.search(r"^display_height = ([0-9.]+)", t, re.M)
        dh = float(dh.group(1)) if dh else 0.0
        if dh <= 0:
            continue
        sfm = re.search(r'sprite_frames = ExtResource\("([^"]+)"\)', t)
        if sfm:
            pm = re.search(r'\[ext_resource type="SpriteFrames"[^\]]*path="([^"]+)" id="%s"\]'
                           % re.escape(sfm.group(1)), t)
            if pm:
                sp = pm.group(1).replace("res://", "")
                out.append((f[:-5], dh, sp, frames_of(rd(os.path.join(ROOT, sp)))))
                continue
        sub = re.search(r'\[sub_resource type="SpriteFrames"[^\]]*\](.*?)(?=\n\[|\Z)', t, re.S)
        if sub:
            out.append((f[:-5], dh, os.path.join("data", "monsters", f), frames_of(t, sub.group(1))))
    return out


def main():
    if not APPLY:
        print("★ โหมดดูอย่างเดียว ★ ใส่ --apply ถึงจะย่อจริง\n")
    print("เป้าความละเอียดจอ: %s (ต้องได้ %.1f เท่าของ display_height)\n" % (target, SCALE))

    # 1) หาตัวคูณย่อที่ปลอดภัยที่สุดต่อ "ไฟล์ภาพ"
    per_file = {}
    users_of = {}
    for mid, dh, sfpath, anims in sheet_files():
        need = dh * SCALE
        for anim, rows in anims.items():
            have = content_h(rows)
            if have <= 0 or need <= 0:
                continue
            gain = have / need
            for f in set(r[0] for r in rows):
                per_file[f] = min(per_file.get(f, 99.0), gain)
                users_of.setdefault(f, set()).add(sfpath)

    plan = {f: g for f, g in per_file.items() if g >= MIN_GAIN}
    if not plan:
        print("ไม่มีไฟล์ไหนละเอียดเกินเป้า %s — ไม่ต้องย่ออะไร" % target)
        return

    if APPLY:
        os.makedirs(BAK, exist_ok=True)

    # 2) ย่อภาพ
    print("%-56s %-11s %-11s %s" % ("ไฟล์", "เดิม", "ใหม่", "ลดขนาด"))
    print("-" * 100)
    factors = {}
    before = after = 0
    for f, gain in sorted(plan.items(), key=lambda kv: -kv[1]):
        p = os.path.join(ROOT, f)
        if not os.path.exists(p):
            continue
        im = Image.open(p)
        w, h = im.size
        k = 1.0 / gain
        # ปัดให้หารด้วย 4 ลงตัว (บล็อกของ VRAM compression เป็น 4x4)
        nw = max(4, int(round(w * k / 4)) * 4)
        nh = max(4, int(round(h * k / 4)) * 4)
        sx, sy = nw / float(w), nh / float(h)
        sz0 = os.path.getsize(p)
        before += sz0
        if APPLY:
            bak = os.path.join(BAK, f.replace(os.sep, "__").replace("/", "__"))
            if not os.path.exists(bak):
                shutil.copy2(p, bak)
            im.convert("RGBA").resize((nw, nh), Image.LANCZOS).save(p, optimize=True)
            sz1 = os.path.getsize(p)
        else:
            sz1 = int(sz0 * sx * sy)
        after += sz1
        factors[f] = (sx, sy)
        print("%-56s %5dx%-5d %5dx%-5d %6.1f → %5.1f MB"
              % (f.replace("Sprites/", "")[:56], w, h, nw, nh, sz0 / 1048576, sz1 / 1048576))

    # 3) แก้พิกัด region ในไฟล์ SpriteFrames ให้ตรงกับภาพใหม่
    print("\nแก้พิกัดเฟรม (region) ในไฟล์ท่าทาง")
    touched = set()
    for f in factors:
        touched |= users_of.get(f, set())
    n_fix = 0
    for sfpath in sorted(touched):
        p = os.path.join(ROOT, sfpath)
        s = rd(p)
        if not s:
            continue
        ext = dict(re.findall(r'\[ext_resource type="Texture2D"[^\]]*path="([^"]+)" id="([^"]+)"\]', s))
        # id -> ตัวคูณ (เฉพาะภาพที่ถูกย่อ)
        idfac = {}
        for path, eid in ext.items():
            rel = path.replace("res://", "")
            if rel in factors:
                idfac[eid] = factors[rel]
        if not idfac:
            continue

        def fix(m):
            body = m.group(0)
            a = re.search(r'atlas = ExtResource\("([^"]+)"\)', body)
            if not a or a.group(1) not in idfac:
                return body
            sx, sy = idfac[a.group(1)]

            def scale_rect(rm):
                n = [float(x) for x in rm.group(1).split(",")]
                n = [n[0] * sx, n[1] * sy, n[2] * sx, n[3] * sy]
                return "region = Rect2(%s)" % ", ".join("%g" % round(v) for v in n)

            return re.sub(r'region = Rect2\(([^)]*)\)', scale_rect, body)

        out = re.sub(r'\[sub_resource type="AtlasTexture" id="[^"]+"\](?:.*?)(?=\n\[|\Z)', fix, s, flags=re.S)
        if out != s:
            if APPLY:
                bak = os.path.join(BAK, sfpath.replace(os.sep, "__").replace("/", "__"))
                if not os.path.exists(bak):
                    shutil.copy2(p, bak)
                io.open(p, "w", encoding="utf-8", newline="\n").write(out)
            n_fix += 1
            print("  · %s" % sfpath)

    print("\nย่อ %d ไฟล์ · แก้ไฟล์ท่าทาง %d ไฟล์ · %.0f MB → %.0f MB (ลด %.0f MB)"
          % (len(factors), n_fix, before / 1048576, after / 1048576, (before - after) / 1048576))
    if APPLY:
        print("สำรองต้นฉบับไว้ที่ %s" % os.path.relpath(BAK, ROOT))
        print("★ เปิด Godot แล้วรอ import ใหม่ · เช็คมอนที่ถูกย่อในห้อง GM (F10) ★")
    else:
        print("(ยังไม่ได้ย่อจริง)")


if __name__ == "__main__":
    main()
