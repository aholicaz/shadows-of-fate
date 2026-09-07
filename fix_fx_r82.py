#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fix_fx_r82.py — รอบ 82: จัดชีทเอฟเฟกต์ใหม่ 2 ตัว (magnum_break · slime_burst) ให้เป็นตารางเท่ากัน
                แล้วอัปเดตไฟล์ท่าทาง/สกิล/มอนให้ตรงกับสัดส่วนภาพใหม่

ภาพใหม่ที่ผู้ใช้วางมา (2172x724 ทั้งคู่) เป็นแบบ "อัดชิดกัน ความกว้างไม่เท่ากัน"
ตัดด้วยตารางเท่ากันไม่ได้ → ต้องจัดใหม่ก่อน (ดู _tools/repack_fx_sheet.py)

รันในโฟลเดอร์โปรเจกต์:  python3 fix_fx_r82.py            (ดูอย่างเดียว)
                        python3 fix_fx_r82.py --apply    (แก้จริง)
"""
import os, re, sys, shutil, subprocess

APPLY = "--apply" in sys.argv
ROOT = os.path.dirname(os.path.abspath(__file__))
TOOL = os.path.join(ROOT, "_tools", "repack_fx_sheet.py")

MAGNUM_PNG = os.path.join(ROOT, "Sprites", "effects", "magnum_break.png")
SLIME_PNG = os.path.join(ROOT, "Sprites", "effects", "slime_burst.png")
FX_MAGNUM = os.path.join(ROOT, "data", "sprites", "fx_magnum.tres")
SKILL_MAGNUM = os.path.join(ROOT, "data", "skills", "magnum_break.tres")
KING_PORING = os.path.join(ROOT, "data", "monsters", "king_poring.tres")

MAGNUM_FRAMES = 12
SLIME_FRAMES = 8
MAGNUM_FPS = 24.0

# ★ ขนาดบนจอ ★ คิดจากสัดส่วนภาพใหม่ (ตัวละครสูง 240 px บนจอ)
# แมกนัม: อยากให้ "วงไฟที่พื้น" กว้างใกล้ ๆ ระยะโดนของสกิล (range_x 270 → กว้าง 540)
MAGNUM_HEIGHT = 620.0
PLAYER_FEET_Y = 120.0     # เท้าอยู่ต่ำกว่าจุดกำเนิดตัวละครเท่าไหร่ (capsule 240 / 2)
PAD = 8                   # ขอบว่างที่ repack ใส่ให้แต่ละช่อง

SLIME_HEIGHT_DEFAULT = 210.0   # ค่าเริ่มต้นใน monster_data.gd
KING_PORING_HEIGHT = 225.0


def already_grid(png, n):
    """ชีทนี้เป็นตาราง n ช่องเท่ากันอยู่แล้วหรือยัง — ทุกช่องต้องมีภาพ และภาพอยู่กึ่งกลางช่อง"""
    import numpy as np
    from PIL import Image
    Image.MAX_IMAGE_PIXELS = None
    w, h = png_size(png)
    if w % n != 0:
        return False
    cw = w // n
    a = np.array(Image.open(png).convert("RGBA"))[:, :, 3]
    for i in range(n):
        col = (a[:, i * cw:(i + 1) * cw] > 20).any(axis=0)
        xs = np.nonzero(col)[0]
        if len(xs) == 0:
            return False
        cx = (xs[0] + xs[-1] + 1) / 2.0
        if abs(cx - cw / 2.0) / (cw / 2.0) > 0.30:
            return False
    return True


def sh(cmd):
    print("  $ " + " ".join(cmd))
    if APPLY:
        r = subprocess.run(cmd, capture_output=True, text=True)
        print("    " + (r.stdout or "").strip().replace("\n", "\n    "))
        if r.returncode != 0:
            print("    !! " + (r.stderr or "").strip())
            sys.exit(1)


def png_size(path):
    import struct
    with open(path, "rb") as f:
        d = f.read(33)
    return struct.unpack(">II", d[16:24])


def write(path, text):
    if not APPLY:
        print("  (ยังไม่เขียน) %s" % os.path.relpath(path, ROOT))
        return
    bak_dir = os.path.join(ROOT, "_to_delete", "originals_fx_r82")
    os.makedirs(bak_dir, exist_ok=True)
    bak = os.path.join(bak_dir, os.path.basename(path))
    if os.path.exists(path) and not os.path.exists(bak):
        shutil.copy2(path, bak)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("  เขียน %s" % os.path.relpath(path, ROOT))


# =========================================================
# 1) จัดชีทใหม่
# =========================================================
def repack_sheets():
    print("\n== 1) จัดชีทเอฟเฟกต์ให้เป็นตารางเท่ากัน ==")
    for png, n, gap in [(MAGNUM_PNG, MAGNUM_FRAMES, "0.35"), (SLIME_PNG, SLIME_FRAMES, "0.65")]:
        if not os.path.exists(png):
            print("  ข้าม (ไม่มีไฟล์) %s" % png)
            continue
        w, h = png_size(png)
        print("  %s เดิม %dx%d" % (os.path.basename(png), w, h))
        if already_grid(png, n):
            print("    เป็นตารางเท่ากันอยู่แล้ว (ทุกช่องมีภาพ อยู่กึ่งกลาง) — ข้าม")
            continue
        sh([sys.executable, TOOL, png, str(n), "--min-gap", gap, "--pad", str(PAD)])


# =========================================================
# 2) ไฟล์ท่าทางของแมกนัม
# =========================================================
def existing_grid():
    """ถ้า fx_magnum.tres เป็นตารางเท่ากันอยู่แล้ว คืน (กว้างช่อง, สูงช่อง) — ผู้ใช้ปรับจำนวนเฟรม/ความเร็วเองได้"""
    if not os.path.exists(FX_MAGNUM):
        return None
    src = open(FX_MAGNUM, encoding="utf-8").read()
    regs = [tuple(float(v) for v in m.split(",")) for m in re.findall(r"region = Rect2\(([^)]*)\)", src)]
    if len(regs) < 2:
        return None
    w0, h0 = regs[0][2], regs[0][3]
    for i, r in enumerate(regs):
        if r[1] != 0 or r[2] != w0 or r[3] != h0 or abs(r[0] - i * w0) > 0.5:
            return None
    sw, sh = png_size(MAGNUM_PNG)
    if sh != int(h0) or sw % int(w0) != 0 or len(regs) * w0 > sw:
        return None
    print("  fx_magnum.tres เป็นตาราง %d เฟรม ช่องละ %dx%d อยู่แล้ว — ไม่แตะ"
          % (len(regs), int(w0), int(h0)))
    return int(w0), int(h0)


def rebuild_fx_magnum():
    print("\n== 2) ไฟล์ท่าทางของแมกนัม ==")
    keep = existing_grid()
    if keep is not None:
        return keep
    w, h = png_size(MAGNUM_PNG)
    cw = w // MAGNUM_FRAMES
    print("  ชีท %dx%d → ช่องละ %dx%d · %d เฟรม" % (w, h, cw, h, MAGNUM_FRAMES))

    subs = []
    frames = []
    for i in range(MAGNUM_FRAMES):
        subs.append('[sub_resource type="AtlasTexture" id="fx_%d"]\n'
                    'atlas = ExtResource("1_tex")\n'
                    'region = Rect2(%d, 0, %d, %d)\n' % (i, i * cw, cw, h))
        frames.append('{\n"duration": 1.0,\n"texture": SubResource("fx_%d")\n}' % i)

    text = ('[gd_resource type="SpriteFrames" load_steps=%d format=3 uid="uid://cxfs627ufui2s"]\n\n'
            '[ext_resource type="Texture2D" uid="uid://b21o5u6avcowk" '
            'path="res://Sprites/effects/magnum_break.png" id="1_tex"]\n\n'
            '%s\n[resource]\nanimations = [{\n"frames": [%s],\n"loop": 0,\n"name": &"burst",\n"speed": %.1f\n}]\n'
            % (MAGNUM_FRAMES + 2, "\n".join(subs), ", ".join(frames), MAGNUM_FPS))
    write(FX_MAGNUM, text)
    return cw, h


# =========================================================
# 3) ขนาด/ตำแหน่งเอฟเฟกต์ในไฟล์สกิล
# =========================================================
def patch_skill_magnum(cw, ch):
    print("\n== 3) ปรับขนาดเอฟเฟกต์ในสกิลแมกนัม ==")
    # ★ เคารพขนาดที่ผู้ใช้ตั้งไว้เอง ★ ถ้าในไฟล์มี effect_height อยู่แล้วให้ใช้ค่านั้น
    # (สคริปต์แค่คำนวณ offset ให้วงไฟตกที่เท้าพอดีตามขนาดนั้น)
    src0 = open(SKILL_MAGNUM, encoding="utf-8").read()
    m = re.search(r"^effect_height = ([0-9.]+)", src0, flags=re.M)
    height = float(m.group(1)) if m else MAGNUM_HEIGHT
    globals()["MAGNUM_HEIGHT"] = height
    k = MAGNUM_HEIGHT / ch
    on_w = cw * k
    # ให้ "ขอบล่างของภาพ (หักขอบว่าง)" ไปอยู่ที่ระดับเท้าพอดี
    offset_y = PLAYER_FEET_Y + PAD * k - MAGNUM_HEIGHT / 2.0
    print("  บนจอ %.0f x %.0f px (ตัวละครสูง 240) · offset y %.0f" % (on_w, MAGNUM_HEIGHT, offset_y))

    src = open(SKILL_MAGNUM, encoding="utf-8").read()
    out = re.sub(r"^effect_height = .*$", "effect_height = %.1f" % MAGNUM_HEIGHT, src, flags=re.M)
    out = re.sub(r"^effect_offset = .*$", "effect_offset = Vector2(0, %.0f)" % offset_y, out, flags=re.M)
    if "effect_offset" not in out:
        out = out.rstrip("\n") + "\neffect_offset = Vector2(0, %.0f)\n" % offset_y
    if out == src:
        print("  ไม่มีอะไรต้องแก้")
    else:
        write(SKILL_MAGNUM, out)


# =========================================================
# 4) ขนาดเอฟเฟกต์ระเบิดของคิงโพริง
# =========================================================
def patch_king_poring():
    print("\n== 4) ปรับขนาดเอฟเฟกต์ระเบิดของคิงโพริง ==")
    if not os.path.exists(KING_PORING):
        print("  ไม่มีไฟล์ — ข้าม")
        return
    w, h = png_size(SLIME_PNG)
    cw = w // SLIME_FRAMES
    print("  ชีทสไลม์ %dx%d → ช่องละ %dx%d · บนจอ %.0f x %.0f"
          % (w, h, cw, h, cw * KING_PORING_HEIGHT / h, KING_PORING_HEIGHT))
    src = open(KING_PORING, encoding="utf-8").read()
    out = re.sub(r"^skill_explosion_height = .*$",
                 "skill_explosion_height = %.1f" % KING_PORING_HEIGHT, src, flags=re.M)
    if out == src:
        print("  ไม่มีอะไรต้องแก้")
    else:
        write(KING_PORING, out)


def main():
    if not APPLY:
        print("★ โหมดดูอย่างเดียว ★ ใส่ --apply ถึงจะแก้จริง\n")
    repack_sheets()
    if APPLY or os.path.exists(MAGNUM_PNG):
        cw, ch = rebuild_fx_magnum()
        patch_skill_magnum(cw, ch)
    patch_king_poring()
    print("\nเสร็จ" + ("" if APPLY else " (ยังไม่ได้แก้จริง)"))


if __name__ == "__main__":
    main()
