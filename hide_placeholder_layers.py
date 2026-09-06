#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
★ รอบ 73 ★ ซ่อนแผ่นสีล้วนสมัย placeholder (Sky / FarLayer / Ground Visual) ในแมพที่มีภาพฉากจริงแล้ว

อาการ: พรอนเทรา — แผ่นสีน้ำตาล Terrain/Ground0/Visual (y 929..1089) ยื่นเลยขอบล่างภาพเมือง (987)
        และวาดทับขอบล่างของภาพ 58 px → เห็นแถบน้ำตาลใต้ภาพ + ภาพโดนบังส่วนล่าง
วิธี:   แมพไหนมีภาพจริง (Sprite2D / Polygon2D ที่มี texture) → Polygon2D สีล้วนชื่อ Sky / FarLayer / Visual
        ที่ยังมองเห็นอยู่ จะถูกตั้ง visible = false (เหมือนที่แมพอื่น ๆ ทำไว้แล้ว)

ใช้:  python3 hide_placeholder_layers.py          → แค่ดูว่าจะแก้อะไร
      python3 hide_placeholder_layers.py --apply  → แก้จริง (สำรองไว้ที่ _to_delete/originals_maps_r73/)
"""
import os, re, sys, shutil, glob

ROOT = os.path.dirname(os.path.abspath(__file__))
MAPS_DIR = os.path.join(ROOT, "scenes", "maps")
BACKUP = os.path.join(ROOT, "_to_delete", "originals_maps_r73")
APPLY = "--apply" in sys.argv
PLACEHOLDER_NAMES = {"Sky", "FarLayer", "FarTrees", "Visual"}
MIN_WIDTH_FRAC = 0.25   # ต้องกว้าง >= 25% ของแมพ (เกณฑ์เดียวกับ art_span ใน map_base.gd) — แผ่นเล็ก ๆ อย่างพื้นลอย Plat0..N ไม่แตะ

NODE_RE = re.compile(r'^\[node name="([^"]+)" type="([^"]+)"(?: parent="([^"]+)")?[^\]]*\]$', re.M)


def split_nodes(text):
    """คืน list ของ (start, end, name, type, parent, body) ต่อโหนด"""
    out = []
    matches = list(NODE_RE.finditer(text))
    for i, m in enumerate(matches):
        start = m.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        out.append([start, end, m.group(1), m.group(2), m.group(3) or "", text[m.end():end]])
    return out


def poly_width(body):
    """ความกว้างของ polygon ในโลก (คิด scale ของโหนดเอง)"""
    m = re.search(r"polygon = PackedVector2Array\(([^)]*)\)", body)
    if not m:
        return 0.0
    nums = [float(x) for x in re.findall(r"-?\d+\.?\d*(?:e-?\d+)?", m.group(1))]
    xs = nums[0::2]
    if not xs:
        return 0.0
    sx = 1.0
    ms = re.search(r"scale = Vector2\(([^,]+),", body)
    if ms:
        sx = abs(float(ms.group(1)))
    return (max(xs) - min(xs)) * sx


def map_width(text):
    m = re.search(r"map_bounds = Rect2\([^,]+,[^,]+,\s*([^,]+),", text)
    return float(m.group(1)) if m else 0.0


def has_real_art(nodes):
    for _, _, name, typ, parent, body in nodes:
        if typ in ("Sprite2D", "TextureRect") and "texture = " in body and "visible = false" not in body:
            return True
        if typ == "Polygon2D" and "texture = " in body and "visible = false" not in body:
            return True
    return False


def main():
    changed_any = False
    for path in sorted(glob.glob(os.path.join(MAPS_DIR, "*.tscn"))):
        text = open(path, encoding="utf-8").read()
        nodes = split_nodes(text)
        if not has_real_art(nodes):
            print("  - %s: ยังไม่มีภาพฉากจริง — ไม่แตะ" % os.path.basename(path))
            continue
        targets = []
        min_w = map_width(text) * MIN_WIDTH_FRAC
        for start, end, name, typ, parent, body in nodes:
            if typ != "Polygon2D" or name not in PLACEHOLDER_NAMES:
                continue
            if "texture = " in body:
                continue  # มีภาพ = ของจริง
            if "visible = false" in body:
                continue  # ซ่อนอยู่แล้ว
            if poly_width(body) < min_w:
                continue  # แผ่นเล็ก (พื้นลอย ฯลฯ) — ไม่ใช่ฉากหลัง
            targets.append((start, end, name, parent, body))
        if not targets:
            print("  ✓ %s: ไม่มีแผ่นสีค้าง" % os.path.basename(path))
            continue
        print("  ★ %s: ซ่อนแผ่นสีล้วน %s" % (os.path.basename(path), ", ".join("%s/%s" % (p, n) for _, _, n, p, _ in targets)))
        changed_any = True
        if not APPLY:
            continue
        # แทรก visible = false บรรทัดแรกหลังหัวโหนด (แก้จากท้ายไปหน้าเพื่อไม่ให้ index เพี้ยน)
        for start, end, name, parent, body in sorted(targets, key=lambda t: -t[0]):
            header_end = text.index("]\n", start) + 2
            text = text[:header_end] + "visible = false\n" + text[header_end:]
        os.makedirs(BACKUP, exist_ok=True)
        shutil.copy2(path, os.path.join(BACKUP, os.path.basename(path)))
        open(path, "w", encoding="utf-8", newline="\n").write(text)
        print("      → บันทึกแล้ว (สำรองที่ %s)" % os.path.relpath(BACKUP, ROOT))
    if changed_any and not APPLY:
        print("\nยังไม่ได้แก้ — รันซ้ำด้วย --apply เพื่อแก้จริง")
    elif not changed_any:
        print("\nทุกแมพเรียบร้อย ไม่ต้องแก้")


if __name__ == "__main__":
    main()
