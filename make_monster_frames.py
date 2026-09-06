#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
★ รอบ 77 ★ สร้างไฟล์ท่าทาง (SpriteFrames) ให้มอนแต่ละตัว — แบบเดียวกับ stormscar_frames.tres

ทำไม: มอนบางตัวเก็บท่าทางไว้ "ข้างในไฟล์มอน" (sub_resource) แก้ยาก และบาฟโฟเมทไม่มีท่าทางเลย
      ตัวนี้สร้างไฟล์ `data/sprites/monsters/<id>_frames.tres` แยกออกมา 1 ไฟล์ต่อมอน 1 ตัว
      เปิดใน Godot แล้วลากภาพใส่ได้เลย (หน้าต่าง SpriteFrames ด้านล่างจอ)

ท่ามาตรฐานที่สร้างให้ (ชื่อเดียวกับที่เกมมองหา — ดู ANIM_FALLBACK ใน monster_base.gd):
    Idle · Run · Attack · Hit · Die · Skill

★ ใส่ภาพยังไง ★  วางไฟล์ไว้ที่ `Sprites/monster/<ชื่อโฟลเดอร์ของมอน>/` แล้วรันสคริปต์นี้ใหม่ด้วย --force
  - ไฟล์เดี่ยว ชื่อมีคำว่า idle / run / attack / hit / die / skill → ใช้เป็น 1 เฟรม
  - ไฟล์ชีทหลายเฟรม ตั้งชื่อ  attack_x8.png  = แบ่ง 8 เฟรมแนวนอน · `run_x12x2.png` = 12 คอลัมน์ 2 แถว
  - โฟลเดอร์ย่อยชื่อ run/ (มี frame_01.png, frame_02.png ...) → เรียงตามชื่อไฟล์
  - ไม่เจอภาพ = ใส่ภาพชั่วคราว (กล่องสีจาง ๆ) ไว้ก่อน เกมจะได้ไม่พัง

ใช้:
    python3 make_monster_frames.py                    # ดูสถานะทุกตัว ไม่แก้อะไร
    python3 make_monster_frames.py --apply            # สร้างให้ตัวที่ยังไม่มี
    python3 make_monster_frames.py baphomet --apply   # เจาะจงตัวเดียว
    python3 make_monster_frames.py baphomet --apply --force   # สร้างทับของเดิม (สำรองให้)
"""
import os, re, sys, glob, shutil, struct, zlib

ROOT = os.path.dirname(os.path.abspath(__file__))
MON_DIR = os.path.join(ROOT, "data", "monsters")
OUT_DIR = os.path.join(ROOT, "data", "sprites", "monsters")
ART_DIR = os.path.join(ROOT, "Sprites", "monster")
PLACEHOLDER_DIR = os.path.join(ROOT, "Sprites", "monsters", "placeholder")
BACKUP = os.path.join(ROOT, "_to_delete", "originals_frames_r77")

APPLY = "--apply" in sys.argv
FORCE = "--force" in sys.argv
ONLY = [a for a in sys.argv[1:] if not a.startswith("--")]

# ชื่อท่า -> (คำที่ใช้หาไฟล์ภาพ, วนซ้ำไหม, fps, จำนวนเฟรมชั่วคราว)
ANIMS = [
    ("Idle",   ["idle", "stand"],                  True,  6.0, 2),
    ("Run",    ["run", "walk", "move"],            True, 10.0, 2),
    ("Attack", ["attack", "atk", "attact"],        False, 12.0, 3),
    ("Hit",    ["hit", "hurt", "damage"],          False, 10.0, 2),
    ("Die",    ["die", "death", "dead", "dying"],  False,  8.0, 3),
    ("Skill",  ["skill", "cast", "roar", "storm"], False, 10.0, 3),
]

# มอนบทที่ 2 เป็นต้นไป (แมพทางเหล็ก · นิดาเวลลิร์ · เหมืองถ่านไฟ · ห้องโถงเงียบ · เตาหลอมร้าง)
CHAPTER2 = ["steel_beetle", "pitman", "ember_bat", "magma_slug",
            "silent_wraith", "rune_watcher", "forge_golem", "forge_guardian"]
# ตัวที่ผู้ใช้สั่งเพิ่ม
EXTRA = ["baphomet"]
DEFAULT_LIST = EXTRA + CHAPTER2


# ---------------------------------------------------------------- อ่านค่าจากไฟล์มอน
def monster_info(mid):
    path = os.path.join(MON_DIR, mid + ".tres")
    if not os.path.exists(path):
        return None
    text = open(path, encoding="utf-8").read()

    def val(key, default=""):
        m = re.search(r'^%s = "?([^"\n]*)"?$' % re.escape(key), text, re.M)
        return m.group(1).strip() if m else default

    height = 200.0
    m = re.search(r"^display_height = ([0-9.]+)", text, re.M)
    if m:
        height = float(m.group(1))
    return {"id": mid, "path": path, "text": text,
            "name": val("display_name", mid), "height": height}


# ---------------------------------------------------------------- หาไฟล์ภาพ
def png_size(path):
    with open(path, "rb") as f:
        head = f.read(24)
    if len(head) < 24 or head[12:16] != b"IHDR":
        return (0, 0)
    return struct.unpack(">II", head[16:24])


def sheet_grid(filename):
    """ชื่อไฟล์บอกจำนวนเฟรมไหม — attack_x8.png = 8 คอลัมน์ · run_x12x2.png = 12 คอลัมน์ 2 แถว"""
    m = re.search(r"_x(\d+)(?:x(\d+))?(?=\.[^.]+$)", filename, re.I)
    if not m:
        return None
    return (int(m.group(1)), int(m.group(2) or 1))


def art_folders(info):
    """โฟลเดอร์ภาพที่น่าจะเป็นของมอนตัวนี้"""
    out = []
    if not os.path.isdir(ART_DIR):
        return out
    keys = {info["id"], info["id"].replace("_", " "), info["name"]}
    for d in sorted(os.listdir(ART_DIR)):
        full = os.path.join(ART_DIR, d)
        if os.path.isdir(full) and d.lower() in {str(k).lower() for k in keys}:
            out.append(full)
    return out


def find_art(info, words):
    """คืน list ของ (ไฟล์ภาพ, grid) สำหรับท่านี้ — ว่าง = ไม่เจอ"""
    for folder in art_folders(info):
        # 1) โฟลเดอร์ย่อยชื่อตรงกับท่า (run/, attack/ ...) → ทุกไฟล์เรียงตามชื่อ
        for sub in sorted(os.listdir(folder)):
            full = os.path.join(folder, sub)
            if os.path.isdir(full) and any(w in sub.lower() for w in words):
                pics = sorted(glob.glob(os.path.join(full, "*.png")))
                if pics:
                    return [(p, None) for p in pics]
        # 2) ไฟล์เดี่ยว/ชีท ในโฟลเดอร์ของมอน
        hits = []
        for f in sorted(glob.glob(os.path.join(folder, "*.png"))):
            base = os.path.basename(f).lower()
            if any(w in base for w in words):
                hits.append((f, sheet_grid(base)))
        if hits:
            return hits
    return []


# ---------------------------------------------------------------- ภาพชั่วคราว
def write_png(path, w, h, rgba):
    """เขียน PNG สีเดียวแบบง่าย ๆ (ไม่ต้องพึ่ง PIL)"""
    raw = b""
    row = bytes(rgba) * w
    border = bytes((255, 255, 255, 90)) * w
    for y in range(h):
        edge = y < 3 or y >= h - 3
        raw += b"\x00" + (border if edge else row)

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "wb").write(png)


def placeholder_for(info):
    """ภาพชั่วคราวของมอนตัวนี้ (ไม่มีก็สร้างให้ ขนาดตาม Display Height)"""
    path = os.path.join(PLACEHOLDER_DIR, info["id"] + ".png")
    if not os.path.exists(path) and APPLY:
        h = int(max(64.0, info["height"]))
        w = int(h * 0.8)
        seed = sum(ord(c) for c in info["id"])
        col = (90 + seed * 37 % 120, 70 + seed * 17 % 110, 110 + seed * 53 % 120, 200)
        write_png(path, w, h, col)
        print("      + สร้างภาพชั่วคราว %s (%dx%d)" % (os.path.relpath(path, ROOT), w, h))
    return path


# ---------------------------------------------------------------- สร้างไฟล์ .tres
def res_path(abs_path):
    return "res://" + os.path.relpath(abs_path, ROOT).replace(os.sep, "/")


def build_tres(info):
    ext_ids = {}        # ไฟล์ภาพ -> id ใน ext_resource
    ext_lines = []
    sub_lines = []
    anim_blocks = []
    placeholder = None
    found_any = False

    def ext_id(path):
        if path not in ext_ids:
            ext_ids[path] = "tex_%d" % len(ext_ids)
            ext_lines.append('[ext_resource type="Texture2D" path="%s" id="%s"]'
                             % (res_path(path), ext_ids[path]))
        return ext_ids[path]

    for anim, words, loop, fps, fallback_count in ANIMS:
        pics = find_art(info, words)
        frames = []
        if pics:
            found_any = True
            for pic, grid in pics:
                if grid is None:
                    frames.append('ExtResource("%s")' % ext_id(pic))
                    continue
                cols, rows = grid
                w, h = png_size(pic)
                fw, fh = w // max(1, cols), h // max(1, rows)
                for r in range(rows):
                    for c in range(cols):
                        sid = "Atlas_%d" % len(sub_lines)
                        sub_lines.append('[sub_resource type="AtlasTexture" id="%s"]\n'
                                         'atlas = ExtResource("%s")\n'
                                         'region = Rect2(%d, %d, %d, %d)'
                                         % (sid, ext_id(pic), c * fw, r * fh, fw, fh))
                        frames.append('SubResource("%s")' % sid)
        else:
            if placeholder is None:
                placeholder = placeholder_for(info)
            frames = ['ExtResource("%s")' % ext_id(placeholder)] * fallback_count

        body = ", ".join('{\n"duration": 1.0,\n"texture": %s\n}' % f for f in frames)
        anim_blocks.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}'
                           % (body, "true" if loop else "false", anim, fps))

    steps = len(ext_lines) + len(sub_lines) + 1
    out = '[gd_resource type="SpriteFrames" load_steps=%d format=3]\n\n' % steps
    out += "\n".join(ext_lines) + "\n\n"
    if sub_lines:
        out += "\n\n".join(sub_lines) + "\n\n"
    out += "[resource]\nanimations = [" + ", ".join(anim_blocks) + "]\n"
    return out, found_any


# ---------------------------------------------------------------- ต่อสายเข้าไฟล์มอน
def point_monster_at(info, frames_rel):
    """ตั้ง sprite_frames ของไฟล์มอนให้ชี้ไฟล์ท่าทางใหม่ + เก็บกวาดบรรทัดท่าทางเก่าที่ไม่ได้ใช้แล้ว"""
    text = info["text"]
    line_ext = '[ext_resource type="SpriteFrames" path="res://%s" id="frames_new"]' % frames_rel
    already = ('path="res://%s"' % frames_rel) in text and "sprite_frames = ExtResource" in text
    if not already:
        exts = list(re.finditer(r"^\[ext_resource .*\]$", text, re.M))
        if not exts:
            return text, "! ไม่มี ext_resource ในไฟล์มอน — ข้าม"
        at = exts[-1].end()
        text = text[:at] + "\n" + line_ext + text[at:]
        if re.search(r"^sprite_frames = .*$", text, re.M):
            text = re.sub(r"^sprite_frames = .*$", 'sprite_frames = ExtResource("frames_new")',
                          text, count=1, flags=re.M)
            how = "เปลี่ยนให้ชี้ไฟล์ใหม่"
        else:
            text = re.sub(r"^(display_name = .*)$", r'\1\nsprite_frames = ExtResource("frames_new")',
                          text, count=1, flags=re.M)
            how = "เพิ่มช่อง sprite_frames (เดิมไม่มีเลย)"
    else:
        how = "ชี้ถูกอยู่แล้ว"

    # ★ ลบบรรทัด ext_resource ของไฟล์ท่าทางเก่าที่ไม่มีใครอ้างถึงแล้ว ★
    dropped = []
    for m in list(re.finditer(r'^\[ext_resource type="SpriteFrames"[^\]]*id="([^"]+)"\]$', text, re.M)):
        rid = m.group(1)
        body = text[:m.start()] + text[m.end() + 1:]   # +1 = กินบรรทัดว่างที่เหลือด้วย
        if ('ExtResource("%s")' % rid) not in body:
            text = body
            dropped.append(rid)
    if dropped:
        how += " · เก็บกวาดบรรทัดเก่า %d" % len(dropped)

    # ★ นับ load_steps ใหม่ให้ตรง ★ (ext + sub + 1)
    n = len(re.findall(r"^\[ext_resource ", text, re.M)) + len(re.findall(r"^\[sub_resource ", text, re.M)) + 1
    first = text.split("\n", 1)[0]
    if "load_steps=" in first:
        text = re.sub(r"load_steps=\d+", "load_steps=%d" % n, text, count=1)
    else:
        text = text.replace("format=3", "load_steps=%d format=3" % n, 1)
    return text, how


def main():
    ids = ONLY if ONLY else DEFAULT_LIST
    os.makedirs(OUT_DIR, exist_ok=True)
    changed = False
    for mid in ids:
        info = monster_info(mid)
        if info is None:
            print("  ! ไม่มี data/monsters/%s.tres — ข้าม" % mid)
            continue
        out_path = os.path.join(OUT_DIR, mid + "_frames.tres")
        rel = os.path.relpath(out_path, ROOT).replace(os.sep, "/")
        exists = os.path.exists(out_path)
        if exists and not FORCE:
            print("  ✓ %-16s มีไฟล์ท่าทางแล้ว (%s) — ใส่ --force ถ้าจะสร้างทับ" % (mid, rel))
            continue
        content, found = build_tres(info)
        print("  ★ %-16s %s%s" % (mid, rel, "  ← เจอภาพจริงในโฟลเดอร์" if found else "  (ยังเป็นภาพชั่วคราว)"))
        changed = True
        if not APPLY:
            continue
        os.makedirs(BACKUP, exist_ok=True)
        if exists:
            shutil.copy2(out_path, os.path.join(BACKUP, os.path.basename(out_path)))
        open(out_path, "w", encoding="utf-8", newline="\n").write(content)
        new_text, how = point_monster_at(info, rel)
        if new_text != info["text"]:
            shutil.copy2(info["path"], os.path.join(BACKUP, os.path.basename(info["path"])))
            open(info["path"], "w", encoding="utf-8", newline="\n").write(new_text)
        print("      → เขียนแล้ว · ไฟล์มอน: %s" % how)
    if changed and not APPLY:
        print("\nยังไม่ได้เขียนไฟล์ — รันซ้ำด้วย --apply")
    elif not changed:
        print("\nมีไฟล์ท่าทางครบทุกตัวแล้ว")
    else:
        print("\n★ เปิด Godot แล้วดับเบิลคลิกไฟล์ใน data/sprites/monsters/ เพื่อลากภาพใส่แต่ละท่าได้เลย ★")


if __name__ == "__main__":
    main()
