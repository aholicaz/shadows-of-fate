#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_web.py — สลับค่า import ระหว่าง "เวอร์ชันเว็บ" กับ "เวอร์ชันคอม/Steam" (รอบ 91)

★ ทำไมต้องคนละค่า ★ (วัดจริง ชีท 4096x2048 · ดูคู่มือ 7.103.3)

              ไฟล์ที่ต้องโหลด   VRAM     เหมาะกับ
  โหมด 1 Lossy    2.5-4.3 MB    42.7 MB  **เว็บ/มือถือ** — เน็ตมือถือโหลดไหว
  โหมด 2 BC7      10.67 MB      10.7 MB  **คอม/Steam** — การ์ดจอไม่ต้องคลายภาพ

  เว็บของ Godot ต้องโหลดไฟล์เกม **ทั้งก้อนให้จบก่อน** ถึงเริ่มเล่นได้ และเก็บไว้ในแรมด้วย
  บนมือถือแท็บมีเพดานราว 1-1.5 GB → ตัวชี้เป็นชี้ตายคือ "ขนาดที่ต้องโหลด" ไม่ใช่ VRAM
  ส่วน VRAM ที่โหมด 1 กินมากกว่านั้น รอบ 90 แก้ไปแล้ว (มอนโหลดเฉพาะตัวที่แมพใช้)

★ ทำไมไม่ย่อขนาดภาพลงสำหรับเว็บ ★
  ลองแล้ว — `process/size_limit` ของ Godot ย่อภาพจริงแต่ **ไม่ย่อพิกัด region ในไฟล์ท่าทาง**
  ทดสอบ: ตั้ง size_limit=512 กับชีท 1024 → atlas เหลือ 512 แต่ region ยังเป็น (190,0,190,192)
  = เฟรมเพี้ยนทั้งชุด · และถ้าย่อภาพเองก็ต้องไปคูณ scale ของฉากหลัง/ตัวละครทุกจุดตามด้วย
  จึงเลือกวิธี "ขนาดเท่าเดิม แต่บีบอัดต่างกัน" ที่ไม่มีอะไรพัง

รัน: python3 build_web.py web        ← ตั้งค่าสำหรับ export เว็บ
     python3 build_web.py desktop    ← ตั้งค่ากลับสำหรับคอม/Steam
     python3 build_web.py status     ← ดูว่าตอนนี้เป็นโหมดไหน
"""
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
MODE = (sys.argv[1] if len(sys.argv) > 1 else "status").lower()

MIN_SIDE = 256
SKIP_DIRS = ("Sprites/ui/", "Sprites/font")

PROFILES = {
    # เว็บ: โหมด 1 Lossy — ไฟล์เล็กลง 4.7 เท่า (VRAM เท่าเดิม แต่รอบ 90 แก้เรื่องนั้นไปแล้ว)
    # คุณภาพแยกตามชนิดภาพ (ค่าที่ทดสอบในเบราว์เซอร์จริงแล้ว — ดูคู่มือ 7.104)
    "web": {"compress/mode": "1", "compress/high_quality": "false"},
    # คอม/Steam: BC7 — VRAM ลง 4 เท่า คุณภาพ 34.9 dB
    "desktop": {"compress/mode": "2", "compress/high_quality": "true", "compress/lossy_quality": "0.7"},
}

# คุณภาพของโหมดเว็บ แยกตามชนิดภาพ — แก้ตัวเลขตรงนี้ถ้าอยากได้ภาพคมขึ้น (ไฟล์จะใหญ่ขึ้นตาม)
WEB_QUALITY = {
    "monster": "0.65",    # ชีทมอน (ถูกย่อด้วย webtrim.py อยู่แล้ว)
    "big": "0.45",        # ภาพใหญ่อื่น ๆ เช่นฉากหลัง — เป็นภาพวาดเนียน ๆ ลดได้เยอะโดยไม่เห็น
    "small": "0.85",      # ภาพเล็ก เช่นไอคอน การ์ด รูปคุย — ต้องคมกว่าเพราะคนมองใกล้
}
BIG_SIDE = 1024           # ยาวด้านใดด้านหนึ่งเกินนี้ = นับเป็น "ภาพใหญ่"

try:
    from PIL import Image
    Image.MAX_IMAGE_PIXELS = None
except ImportError:
    Image = None


def rd(p):
    return io.open(p, encoding="utf-8").read()


def set_key(text, key, value):
    if re.search(r"^%s=" % re.escape(key), text, re.M):
        return re.sub(r"^%s=.*$" % re.escape(key), "%s=%s" % (key, value), text, flags=re.M)
    return text.rstrip("\n") + "\n%s=%s\n" % (key, value)


def each_import():
    for root, _d, files in os.walk(os.path.join(ROOT, "Sprites")):
        for f in sorted(files):
            if not f.endswith(".import"):
                continue
            p = os.path.join(root, f)
            s = rd(p)
            if 'importer="texture"' not in s:
                continue
            rel = os.path.relpath(p, ROOT).replace(os.sep, "/")
            if any(rel.startswith(d) for d in SKIP_DIRS):
                continue
            src = p[:-len(".import")]
            size = None
            if Image is not None:
                try:
                    size = Image.open(src).size
                    if size[0] < MIN_SIDE or size[1] < MIN_SIDE:
                        continue
                except Exception:
                    size = None
            yield p, s, rel, size


def quality_for(rel, size):
    """ภาพนี้ควรใช้คุณภาพเท่าไหร่ในเวอร์ชันเว็บ"""
    if rel.startswith("Sprites/monster"):
        return WEB_QUALITY["monster"]
    if size is not None and max(size) >= BIG_SIDE:
        return WEB_QUALITY["big"]
    return WEB_QUALITY["small"]


def status():
    counts = {}
    for _p, s, _rel, _sz in each_import():
        m = re.search(r"^compress/mode=(\d)", s, re.M)
        counts[m.group(1) if m else "?"] = counts.get(m.group(1) if m else "?", 0) + 1
    names = {"0": "0 Lossless (ตั้งต้น)", "1": "1 Lossy — เวอร์ชันเว็บ", "2": "2 VRAM/BC7 — เวอร์ชันคอม"}
    print("ค่า compress/mode ของภาพใหญ่ตอนนี้:")
    for k in sorted(counts):
        print("  %-28s %d ไฟล์" % (names.get(k, k), counts[k]))


def apply(profile):
    want = PROFILES[profile]
    n = 0
    per_q = {}
    for p, s, rel, size in each_import():
        out = s
        for k, v in want.items():
            out = set_key(out, k, v)
        if profile == "web":
            q = quality_for(rel, size)
            out = set_key(out, "compress/lossy_quality", q)
            per_q[q] = per_q.get(q, 0) + 1
        if out != s:
            io.open(p, "w", encoding="utf-8", newline="\n").write(out)
            n += 1
    print("ตั้งค่าโหมด «%s» ให้ %d ไฟล์" % (profile, n))
    print("ค่าที่ใช้: %s" % " · ".join("%s=%s" % kv for kv in want.items()))
    for q in sorted(per_q, reverse=True):
        print("  คุณภาพ %s → %d ไฟล์" % (q, per_q[q]))
    if n:
        print("★ ต้องสั่ง import ใหม่ก่อน export ★")


if MODE in PROFILES:
    apply(MODE)
elif MODE == "status":
    status()
else:
    print(__doc__)
