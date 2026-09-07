#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fix_render_quality.py — รอบ 88: ภาพคมชัดตอนขยายจอ / เล่นบน Steam

ต้นเหตุที่ "ภาพแตก" ตอนขยายจอ:
  1) project.godot ตั้ง default_texture_filter = 0 (Nearest = ไม่เกลี่ยพิกเซล — เหมาะกับเกมพิกเซลอาร์ต
     แต่เกมนี้เป็นภาพวาดความละเอียดสูงที่ถูกย่อ 0.3-0.8 เท่า → ขอบเป็นรอยหยัก/ยิบ ๆ)
  2) ภาพทุกไฟล์ปิด mipmaps → ย่อภาพใหญ่ (ชีท 4096 px แสดง 300 px) โดยไม่มี mipmap = ระยิบระยับ/ยิบ
  3) ไอคอนบางจุดในโค้ดบังคับ NEAREST (สมุดการ์ด · ช่องของ) → ไอคอน 2048 px ย่อเหลือ 48 px แตกละเอียด

สคริปต์นี้ทำอะไร
  · project.godot: default_texture_filter 0 → 2 (Linear + Mipmaps) · เปิดเกมแบบขยายเต็มจอ (maximized)
  · Sprites/**/*.import ทุกไฟล์: mipmaps/generate=true  (Godot จะ import ใหม่ตอนเปิดโปรเจกต์ครั้งถัดไป)
  · โค้ด UI 3 จุด: NEAREST → LINEAR_WITH_MIPMAPS

★ ปิด Godot ก่อนรัน ★ (แก้ project.godot)
รัน: python3 fix_render_quality.py            (ดูอย่างเดียว)
     python3 fix_render_quality.py --apply    (แก้จริง)
"""
import io
import os
import re
import sys

APPLY = "--apply" in sys.argv
ROOT = os.path.dirname(os.path.abspath(__file__))

UI_FILES = [
    "scripts/ui/card_album_window.gd",
    "scripts/ui/card_view.gd",
    "scripts/ui/inventory_window.gd",
]


def rd(p):
    return io.open(p, encoding="utf-8").read()


def wr(p, s):
    if APPLY:
        io.open(p, "w", encoding="utf-8", newline="\n").write(s)


def patch_project():
    p = os.path.join(ROOT, "project.godot")
    s = rd(p)
    out = s
    # 1) ฟิลเตอร์ภาพ
    if re.search(r"^textures/canvas_textures/default_texture_filter=\d", out, re.M):
        out = re.sub(r"^textures/canvas_textures/default_texture_filter=\d",
                     "textures/canvas_textures/default_texture_filter=2", out, flags=re.M)
    else:
        out = out.replace("[rendering]\n", "[rendering]\n\ntextures/canvas_textures/default_texture_filter=2\n", 1)
    # 2) เปิดเกมแบบขยายเต็มจอ (maximized) — Steam ส่วนใหญ่คาดหวังแบบนี้ · กด F11 สลับ fullscreen ได้
    if "window/size/mode=" not in out:
        out = out.replace('window/stretch/mode="canvas_items"',
                          'window/size/mode=2\nwindow/stretch/mode="canvas_items"', 1)
    changed = out != s
    print("project.godot: %s" % ("แก้ default_texture_filter → 2 (Linear+Mipmaps) · window mode → maximized" if changed else "ไม่มีอะไรต้องแก้"))
    if changed:
        wr(p, out)
    return changed


def patch_imports():
    n_total = n_changed = 0
    for root, _d, files in os.walk(os.path.join(ROOT, "Sprites")):
        for f in files:
            if not f.endswith(".import"):
                continue
            p = os.path.join(root, f)
            s = rd(p)
            if 'importer="texture"' not in s:
                continue
            n_total += 1
            if "mipmaps/generate=false" in s:
                wr(p, s.replace("mipmaps/generate=false", "mipmaps/generate=true"))
                n_changed += 1
    print("ไฟล์ .import ของภาพ: %d ไฟล์ · เปิด mipmaps ให้ %d ไฟล์" % (n_total, n_changed))
    return n_changed


def patch_ui():
    n = 0
    for rel in UI_FILES:
        p = os.path.join(ROOT, rel)
        if not os.path.exists(p):
            continue
        s = rd(p)
        out = s.replace("CanvasItem.TEXTURE_FILTER_NEAREST", "CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS")
        if out != s:
            wr(p, out)
            n += 1
            print("  %s: NEAREST → LINEAR_WITH_MIPMAPS" % rel)
    print("โค้ด UI: แก้ %d ไฟล์" % n)
    return n


def main():
    if not APPLY:
        print("★ โหมดดูอย่างเดียว ★ ใส่ --apply ถึงจะแก้จริง (ปิด Godot ก่อน)\n")
    patch_project()
    patch_imports()
    patch_ui()
    if APPLY:
        print("\nเสร็จ — เปิด Godot แล้วรอ import ภาพใหม่ (ภาพ ~750 MB อาจใช้เวลาหลายนาทีครั้งแรก)")
    else:
        print("\n(ยังไม่ได้แก้จริง)")


if __name__ == "__main__":
    main()
