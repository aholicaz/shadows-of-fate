#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_monster_fit.py — วัด "ความสูงจริงของตัวมอนในแต่ละท่า" จากไฟล์ภาพจริง

ใช้ตรวจว่าระบบ auto-fit (รอบ 83 — คิดสเกลจากท่าอ้างอิงท่าเดียว) จะทำให้ท่าไหนใหญ่/เล็กผิดปกติไหม
เพราะถ้าชีทแต่ละท่าวาดตัวมอนคนละขนาด การใช้สเกลเดียวจะทำให้บางท่าบวมขึ้นมาก

รัน: python3 check_monster_fit.py            (ทุกตัว)
     python3 check_monster_fit.py wolf orc_warrior
"""
import os
import re
import sys

import numpy as np
from PIL import Image

Image.MAX_IMAGE_PIXELS = None
ROOT = os.path.dirname(os.path.abspath(__file__))
ALPHA_MIN = 20
REF_ORDER = ["idle", "stand", "run", "walk"]
# เพดานกันตัวบวม — ต้องตรงกับ fit_max_overshoot ใน MonsterData (รอบ 86)
MAX_OVERSHOOT = 1.35

_img_cache = {}


def read(p):
    try:
        return open(p, encoding="utf-8").read()
    except OSError:
        return ""


def alpha_of(path):
    if path not in _img_cache:
        try:
            im = Image.open(path).convert("RGBA")
            _img_cache[path] = np.array(im)[:, :, 3]
        except Exception:
            _img_cache[path] = None
    return _img_cache[path]


def frames_of(tres_text, animations_block=None):
    """คืน {ชื่อท่า: [(path, x, y, w, h), ...]} — w/h = 0 แปลว่าใช้ทั้งภาพ

    รองรับทั้ง 2 แบบที่โปรเจกต์นี้ใช้จริง:
      · ไฟล์ SpriteFrames แยก (data/sprites/...) ที่หั่นด้วย AtlasTexture
      · SpriteFrames ที่ฝังเป็น SubResource ในไฟล์มอนเอง โดยแต่ละเฟรมเป็นรูปทั้งใบ
    """
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


def tallest_of(rows):
    """ความสูงเนื้อภาพที่สูงที่สุดในท่านั้น + ค่ากลาง (median = ตัวจริงตอนยืน)"""
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
        return 0, 0
    hs.sort()
    return max(hs), hs[len(hs) // 2]


def main():
    want = [a for a in sys.argv[1:] if not a.startswith("-")]
    print("%-18s %-8s %-9s %s" % ("มอน", "DispH", "ท่าอ้างอิง", "ท่า: สูงสุด/กลาง → บนจอหลังใส่เพดาน (เท่าของ DispH)"))
    print("-" * 108)
    bad = []
    for f in sorted(os.listdir(os.path.join(ROOT, "data", "monsters"))):
        if not f.endswith(".tres"):
            continue
        mid = f[:-5]
        if want and mid not in want:
            continue
        t = read(os.path.join(ROOT, "data", "monsters", f))
        dh = re.search(r"^display_height = ([0-9.]+)", t, re.M)
        dh = float(dh.group(1)) if dh else 0.0
        if dh <= 0:
            continue
        sfm = re.search(r'sprite_frames = ExtResource\("([^"]+)"\)', t)
        anims = {}
        if sfm:
            pm = re.search(r'\[ext_resource type="SpriteFrames"[^\]]*path="([^"]+)" id="%s"\]' % re.escape(sfm.group(1)), t)
            if pm:
                anims = frames_of(read(os.path.join(ROOT, pm.group(1).replace("res://", ""))))
        if not anims:
            # SpriteFrames ฝังอยู่ในไฟล์มอนเอง
            sub = re.search(r'\[sub_resource type="SpriteFrames" id="[^"]+"\](.*?)(?=\n\[node |\n\[resource\]|\Z)', t, re.S)
            if sub:
                anims = frames_of(t, sub.group(1))
        if not anims:
            continue
        info = {}
        for name, rows in anims.items():
            hi, mid_h = tallest_of(rows)
            if hi > 0:
                info[name] = (hi, mid_h)
        if not info:
            continue
        ref = None
        for wnt in REF_ORDER:
            for name in info:
                if name.lower() == wnt:
                    ref = name
                    break
            if ref:
                break
        if ref is None:
            ref = list(info)[0]
        ref_h = info[ref][0]
        parts = []
        worst = 1.0
        for name, (hi, med) in sorted(info.items(), key=lambda x: -x[1][0]):
            # สเกลที่เกมใช้จริง: ยึดท่าอ้างอิง เว้นแต่ท่านี้สูงเกินเพดาน → ย่อแยกท่า
            fit_from = ref_h if hi <= ref_h * MAX_OVERSHOOT else hi
            ratio = hi * (dh / fit_from) / dh
            worst = max(worst, ratio)
            mark = " (ย่อแยกท่า)" if fit_from != ref_h else ""
            parts.append("%s %d/%d→%.2f×%s" % (name, hi, med, ratio, mark))
        line = "%-18s %-8.0f %-9s %s" % (mid, dh, ref, "  ".join(parts))
        print(line)
        if worst > MAX_OVERSHOOT + 0.01:
            bad.append((mid, ref, worst))
    print("-" * 108)
    if bad:
        print("★ ตัวที่ยังบวมเกิน %.2f เท่า (%d ตัว) ★" % (MAX_OVERSHOOT, len(bad)))
        for mid, ref, w in sorted(bad, key=lambda x: -x[2]):
            print("   %-18s ท่าอ้างอิง %-8s บวมสุด %.2f เท่า" % (mid, ref, w))
    else:
        print("✓ ไม่มีตัวไหนบวมเกิน %.2f เท่าของ Display Height" % MAX_OVERSHOOT)


if __name__ == "__main__":
    main()
