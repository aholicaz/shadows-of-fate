#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""วาดชีทเอฟเฟกต์ "คลื่นเคียวมืด" ของบาฟโฟเมท (รอบ 78) — 8 เฟรม 192x160 · ขอบล่าง = พื้น · หน้าคลื่นหันขวา"""
import math, random, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

W, H, N = 192, 160, 8
random.seed(78)

# ★ รอบ 79 ★ ชุดสี — python3 make_dark_wave.py out.png [dark|fire|thorn]
PALETTES = {
    "dark":  dict(shadow=(20, 0, 30, 150),   glow=(150, 60, 255, 140), outer=(110, 36, 180, 240),
                  mid=(44, 8, 80, 250),      core=(12, 2, 24, 255),    edge=(255, 150, 255, 210),
                  flame=(175, 80, 255, 210), spark=(235, 190, 255, 210)),
    "fire":  dict(shadow=(40, 10, 0, 150),   glow=(255, 140, 40, 150), outer=(230, 90, 20, 240),
                  mid=(150, 30, 10, 250),    core=(60, 8, 4, 255),     edge=(255, 240, 160, 220),
                  flame=(255, 170, 50, 220), spark=(255, 240, 180, 220)),
    "thorn": dict(shadow=(0, 25, 10, 150),   glow=(90, 220, 90, 140),  outer=(40, 150, 50, 240),
                  mid=(16, 80, 30, 250),     core=(6, 30, 10, 255),    edge=(200, 255, 150, 210),
                  flame=(120, 220, 80, 210), spark=(220, 255, 200, 210)),
}
PAL = PALETTES[sys.argv[2]] if len(sys.argv) > 2 else PALETTES["dark"]
sheet = Image.new("RGBA", (W * N, H), (0, 0, 0, 0))

def moon_mask(cx, cy, rx, ry, cut_dx, shrink=0.92):
    """เสี้ยวพระจันทร์: วงรีใหญ่ ลบด้วยวงรีที่เลื่อนไปทางซ้าย → ส่วนนูนหันขวา"""
    m = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(m)
    d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=255)
    c = Image.new("L", (W, H), 0)
    ImageDraw.Draw(c).ellipse((cx - cut_dx - rx * shrink, cy - ry * shrink,
                               cx - cut_dx + rx * shrink, cy + ry * shrink), fill=255)
    return ImageChops.subtract(m, c)

def paint(img, mask, color):
    layer = Image.new("RGBA", (W, H), color)
    img.paste(layer, (0, 0), mask)

for f in range(N):
    fr = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    t = f / N
    wob = math.sin(t * math.tau) * 3
    lean = 1.0 + 0.05 * math.sin(t * math.tau * 2)
    cx, cy = 96 + wob, H - 72
    rx, ry = 44, 72 * lean
    # ---- เงาบนพื้น ----
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse((40, H - 22, 160, H - 2), fill=PAL['shadow'])
    fr.alpha_composite(sh.filter(ImageFilter.GaussianBlur(3)))
    # ---- แสงเรือง (เสี้ยวใหญ่กว่า เบลอ) ----
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    paint(glow, moon_mask(cx, cy, rx + 14, ry + 10, 26, 0.9), PAL['glow'])
    fr.alpha_composite(glow.filter(ImageFilter.GaussianBlur(10)))
    # ---- ตัวเสี้ยว 3 ชั้น (ม่วงเข้ม → ม่วงดำ → ดำ) ----
    paint(fr, moon_mask(cx, cy, rx, ry, 24, 0.92), PAL['outer'])
    paint(fr, moon_mask(cx - 2, cy, rx - 6, ry - 8, 20, 0.92), PAL['mid'])
    paint(fr, moon_mask(cx - 4, cy, rx - 13, ry - 18, 16, 0.92), PAL['core'])
    # ---- ขอบคมสีชมพูตรงหน้าคลื่น ----
    edge = ImageChops.subtract(moon_mask(cx, cy, rx, ry, 24, 0.92), moon_mask(cx - 3, cy, rx - 3, ry - 3, 24, 0.92))
    paint(fr, edge, PAL['edge'])
    # ---- เปลวไฟมืดพลิ้วออกจากขอบนอก ----
    d = ImageDraw.Draw(fr)
    for k in range(9):
        a = math.radians(-80 + k * 20 + random.uniform(-5, 5))
        bx = cx + math.cos(a) * rx * 0.98
        by = cy + math.sin(a) * ry * 0.98
        hgt = random.uniform(12, 34) * (0.55 + 0.45 * abs(math.sin(t * math.tau + k * 0.9)))
        tip = (bx + math.cos(a) * hgt + random.uniform(-5, 5), by + math.sin(a) * hgt)
        bl = (bx + math.cos(a + 1.4) * 6, by + math.sin(a + 1.4) * 6)
        br = (bx + math.cos(a - 1.4) * 6, by + math.sin(a - 1.4) * 6)
        d.polygon([bl, tip, br], fill=PAL['flame'])
    # ---- ประกาย ----
    for k in range(12):
        px = random.uniform(cx - 60, cx + 70); py = random.uniform(cy - ry - 20, H - 8)
        r = random.uniform(1, 2.6)
        d.ellipse((px - r, py - r, px + r, py + r), fill=PAL['spark'])
    sheet.paste(fr, (f * W, 0))

out = sys.argv[1] if len(sys.argv) > 1 else "dark_wave.png"
sheet.save(out)
print("saved", out, sheet.size)
