#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_sheet_size.py — ชีทมอนแต่ละใบ "ละเอียดเกินที่จอต้องใช้" กี่เท่า

ทำไมต้องคิดให้ดี ไม่ใช่ย่อมั่ว
  เกมตั้ง stretch/mode = canvas_items → Godot วาดที่ความละเอียดจริงของหน้าต่าง
  มอนที่ตั้ง display_height = 320 (หน่วยจอ 720p) บนจอ 1440p จะกินจริง 320 x 2 = 640 พิกเซล
  บนจอ 4K = 320 x 3 = 960 พิกเซล  ← ถ้าย่อชีทต่ำกว่านี้ = เบลอบนจอใหญ่

  กล้อง `zoom` ถูกล็อกไม่ให้เกิน 1.0 (map_base._apply_fit_zoom) จึงไม่มีการ "ซูมเข้า"
  ตัวคูณสูงสุดจึงมาจากความละเอียดจออย่างเดียว

เกณฑ์
  ต้องใช้ (4K)  = ความสูงเนื้อภาพต้องได้ display_height x 3.0
  พอดี (1440p) = display_height x 2.0
  เกินจาก 4K เท่าไหร่ = ย่อได้เท่านั้นโดยตาไม่เห็นความต่าง

รัน: python3 check_sheet_size.py
     python3 check_sheet_size.py --target 4k     (ค่าเริ่มต้น · เผื่อจอ 4K)
     python3 check_sheet_size.py --target 1440p  (ย่อแรงกว่า ประหยัดกว่า)
"""
import os
import re
import sys

import numpy as np
from PIL import Image

Image.MAX_IMAGE_PIXELS = None
ROOT = os.path.dirname(os.path.abspath(__file__))
ALPHA_MIN = 20
VIEWPORT_H = 720.0

TARGETS = {"1080p": 1080.0 / VIEWPORT_H, "1440p": 1440.0 / VIEWPORT_H, "4k": 2160.0 / VIEWPORT_H}
target = "4k"
for i, a in enumerate(sys.argv):
    if a == "--target" and i + 1 < len(sys.argv):
        target = sys.argv[i + 1].lower()
SCALE = TARGETS.get(target, TARGETS["4k"])

_cache = {}


def read(p):
    try:
        return open(p, encoding="utf-8").read()
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
    """{ท่า: [(path, x, y, w, h)]} — w/h = 0 แปลว่าใช้ทั้งภาพ (ยืมจาก check_monster_fit.py)"""
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


def anims_for(mid):
    t = read(os.path.join(ROOT, "data", "monsters", mid + ".tres"))
    if not t:
        return 0.0, {}
    dh = re.search(r"^display_height = ([0-9.]+)", t, re.M)
    dh = float(dh.group(1)) if dh else 0.0
    sfm = re.search(r'sprite_frames = ExtResource\("([^"]+)"\)', t)
    if sfm:
        pm = re.search(r'\[ext_resource type="SpriteFrames"[^\]]*path="([^"]+)" id="%s"\]' % re.escape(sfm.group(1)), t)
        if pm:
            return dh, frames_of(read(os.path.join(ROOT, pm.group(1).replace("res://", ""))))
    sub = re.search(r'\[sub_resource type="SpriteFrames"[^\]]*\](.*?)(?=\n\[|\Z)', t, re.S)
    if sub:
        return dh, frames_of(t, sub.group(1))
    return dh, {}


def content_h(rows):
    """ความสูงเนื้อภาพ (ค่ากลาง) ของท่านั้น — ค่ากลางกันเฟรมกางปีกลากค่าสูงเกิน"""
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


def main():
    print("เป้าความละเอียดจอ: %s (ตัวคูณ %.1f เท่าของหน่วยจอ 720p)\n" % (target, SCALE))
    print("%-20s %6s %7s %8s %8s  %s" % ("มอน", "DispH", "ต้องใช้", "มีจริง", "ย่อได้", "ไฟล์ชีท"))
    print("-" * 104)

    # รวมต่อ "ไฟล์ภาพ" เพราะย่อทีเดียวทั้งไฟล์ — ไฟล์เดียวอาจถูกใช้หลายท่า/หลายตัว
    per_file = {}    # path -> [ตัวคูณย่อที่ปลอดภัยที่สุด, [ผู้ใช้]]
    rows_out = []

    mons = sorted(f[:-5] for f in os.listdir(os.path.join(ROOT, "data", "monsters")) if f.endswith(".tres"))
    for mid in mons:
        dh, anims = anims_for(mid)
        if dh <= 0 or not anims:
            continue
        need = dh * SCALE
        for anim, rows in sorted(anims.items()):
            have = content_h(rows)
            if have <= 0:
                continue
            shrink = have / need if need > 0 else 1.0
            files = sorted(set(r[0] for r in rows))
            for f in files:
                cur, users = per_file.get(f, (99.0, []))
                per_file[f] = (min(cur, shrink), users + ["%s/%s" % (mid, anim)])
            if shrink >= 1.15:
                rows_out.append((shrink, "%-20s %6.0f %7.0f %8d  ย่อ %4.2fx  %s [%s]"
                                 % (mid, dh, need, have, shrink, os.path.basename(files[0]), anim)))

    rows_out.sort(reverse=True)
    for _s, line in rows_out:
        print(line)

    print("\n" + "=" * 104)
    print("สรุปต่อไฟล์ภาพ (ย่อได้ = ตัวคูณที่ปลอดภัยที่สุดของทุกท่าที่ใช้ไฟล์นั้น)\n")
    tot_now = tot_after = 0
    plan = []
    for f, (shrink, users) in sorted(per_file.items(), key=lambda kv: -kv[1][0]):
        p = os.path.join(ROOT, f)
        if not os.path.exists(p):
            continue
        try:
            w, h = Image.open(p).size
        except Exception:
            continue
        sz = os.path.getsize(p)
        tot_now += sz
        if shrink < 1.15:
            tot_after += sz
            continue
        k = 1.0 / shrink
        nw, nh = int(round(w * k)), int(round(h * k))
        tot_after += int(sz * k * k)
        plan.append((shrink, f, w, h, nw, nh, sz))
        print("  %-52s %5dx%-5d → %4dx%-5d (ย่อ %.2fx) %5.1f MB"
              % (f.replace("Sprites/", ""), w, h, nw, nh, shrink, sz / 1048576))

    print("\nไฟล์ที่ย่อได้ %d ไฟล์ · รวมภาพที่ตรวจ %.0f MB → ประมาณ %.0f MB (ลด %.0f MB)"
          % (len(plan), tot_now / 1048576, tot_after / 1048576, (tot_now - tot_after) / 1048576))


if __name__ == "__main__":
    main()
