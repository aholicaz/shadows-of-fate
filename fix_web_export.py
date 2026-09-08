#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fix_web_export.py — รอบ 90: เว็บโหลดนาน / เด้งออก / เล่นไม่ได้

★ ทำไมเว็บถึงพัง ★ (วัดจริง ไม่ได้เดา)

  1) หน่วยความจำภาพตอนเปิดเกม = 1,511 MB
     GameData เรียก load() ไฟล์มอนครบ 30 ตัวตั้งแต่หน้าไตเติล และห้อง GM ก็เรียกซ้ำอีก
     → ชีทมอนทุกตัวขึ้นการ์ดจอพร้อมกัน แท็บเบราว์เซอร์มีเพดานราว 2-4 GB → **เด้งออก**
     (แก้แล้วในรอบนี้ที่ตัวโค้ด — เหลือ 118 MB · ดูคู่มือ 7.103)

  2) ไฟล์เกมที่ต้องดาวน์โหลดใหญ่มาก
     เว็บของ Godot ต้องโหลด .pck **ทั้งก้อนให้จบก่อน** ถึงจะเริ่มเล่นได้ และเก็บไว้ในแรมด้วย
     ตอนนี้ .godot/imported = 891 MB · วิดีโอ .ogv อีก 43 MB ที่ไม่ได้ถูกกรองออก
     → รอโหลดนานมาก และแรมยิ่งไม่พอ

  3) วิดีโอ .ogv (Theora) บนเว็บถอดรหัสด้วย CPU ล้วน เฟรมใหญ่ = ค้าง/แครชกลางคัตซีน

สคริปต์นี้แก้ให้ (แก้ export_presets.cfg ของพรีเซ็ต Web)
  · กรอง *.ogv ออกจากไฟล์เกมเวอร์ชันเว็บ  (คัตซีนจะถูกข้ามไปเอง เกมเล่นต่อได้ปกติ)
  · เปิด thread_support = true  → โหลดไฟล์แบบเบื้องหลัง ไม่แช่แข็งแท็บจนเบราว์เซอร์คิดว่าค้าง
  · เปิด vram_texture_compression/for_mobile = true  → ใช้ ETC2 บนเว็บ (คู่กับ compress/mode=2)
  · ปิด extensions_support (ไม่ได้ใช้ ทำให้ไฟล์ใหญ่ขึ้นเปล่า ๆ)

★ thread_support ต้องมีหัว HTTP ด้วย ★
  เว็บที่ใช้เธรดต้องเปิด cross-origin isolation ฝั่งเซิร์ฟเวอร์:
      Cross-Origin-Opener-Policy: same-origin
      Cross-Origin-Embedder-Policy: require-corp
  itch.io มีสวิตช์ "SharedArrayBuffer support" ให้ติ๊กในหน้าตั้งค่าเกม
  ถ้าเปิดหัวพวกนี้ไม่ได้ ให้รันสคริปต์ด้วย --no-threads

รัน: python3 fix_web_export.py            (ดูอย่างเดียว)
     python3 fix_web_export.py --apply     (แก้จริง)
     python3 fix_web_export.py --apply --no-threads
"""
import io
import os
import re
import sys

APPLY = "--apply" in sys.argv
NO_THREADS = "--no-threads" in sys.argv
ROOT = os.path.dirname(os.path.abspath(__file__))
CFG = os.path.join(ROOT, "export_presets.cfg")

WANT = {
    "variant/thread_support": "false" if NO_THREADS else "true",
    "variant/extensions_support": "false",
    "vram_texture_compression/for_mobile": "true",
}
DROP_FROM_WEB = ["*.ogv"]


def main():
    if not APPLY:
        print("★ โหมดดูอย่างเดียว ★ ใส่ --apply ถึงจะแก้จริง\n")
    if not os.path.exists(CFG):
        print("ไม่เจอ export_presets.cfg — เปิด Godot แล้วสร้างพรีเซ็ต Web ก่อน")
        return

    s = io.open(CFG, encoding="utf-8").read()

    # หาบล็อกของพรีเซ็ต Web (ตั้งแต่ [preset.N] ที่ platform="Web" ไปจนถึง [preset.N+1])
    blocks = list(re.finditer(r"^\[preset\.(\d+)\]$", s, re.M))
    web_i = None
    for i, m in enumerate(blocks):
        end = blocks[i + 1].start() if i + 1 < len(blocks) else len(s)
        if re.search(r'^platform="Web"$', s[m.start():end], re.M):
            web_i = m.group(1)
            break
    if web_i is None:
        print("ไม่เจอพรีเซ็ตที่ platform=\"Web\"")
        return
    print("เจอพรีเซ็ต Web = preset.%s\n" % web_i)

    out = s
    n = 0

    # ---------- 1) กรองไฟล์ที่ไม่ต้องใส่ในเวอร์ชันเว็บ ----------
    head = re.search(r"^\[preset\.%s\]$" % web_i, out, re.M)
    tail = re.search(r"^\[preset\.%s\.options\]$" % web_i, out, re.M)
    seg = out[head.start():tail.start()]
    ex = re.search(r'^exclude_filter="([^"]*)"$', seg, re.M)
    if ex:
        cur = [x.strip() for x in ex.group(1).split(",") if x.strip()]
        added = [d for d in DROP_FROM_WEB if d not in cur]
        if added:
            new_val = ", ".join(cur + added)
            seg2 = seg[:ex.start()] + 'exclude_filter="%s"' % new_val + seg[ex.end():]
            out = out[:head.start()] + seg2 + out[tail.start():]
            print("  + กรองออกจากเวอร์ชันเว็บ: %s" % ", ".join(added))
            n += 1
        else:
            print("  = กรองไฟล์ครบแล้ว")

    # ---------- 2) ตัวเลือกของพรีเซ็ต ----------
    tail = re.search(r"^\[preset\.%s\.options\]$" % web_i, out, re.M)
    nxt = re.search(r"^\[preset\.\d+\]$", out[tail.end():], re.M)
    o_start, o_end = tail.end(), (tail.end() + nxt.start()) if nxt else len(out)
    opts = out[o_start:o_end]
    for k, v in WANT.items():
        m = re.search(r"^%s=(.*)$" % re.escape(k), opts, re.M)
        if m:
            if m.group(1).strip() == v:
                print("  = %s ถูกอยู่แล้ว (%s)" % (k, v))
                continue
            opts = opts[:m.start()] + "%s=%s" % (k, v) + opts[m.end():]
        else:
            opts = opts.rstrip("\n") + "\n%s=%s\n" % (k, v)
        print("  + %s = %s" % (k, v))
        n += 1
    out = out[:o_start] + opts + out[o_end:]

    if n == 0:
        print("\nตั้งไว้ถูกหมดแล้ว ไม่มีอะไรต้องแก้")
        return
    if APPLY:
        bak = CFG + ".r90.bak"
        if not os.path.exists(bak):
            io.open(bak, "w", encoding="utf-8", newline="\n").write(s)
        io.open(CFG, "w", encoding="utf-8", newline="\n").write(out)
        print("\nแก้ %d จุด · สำรองของเดิมไว้ที่ export_presets.cfg.r90.bak" % n)
        if not NO_THREADS:
            print("★ อย่าลืมเปิด SharedArrayBuffer / COOP+COEP ที่ฝั่งเว็บด้วย ★"
                  " ถ้าเปิดไม่ได้ให้รันซ้ำด้วย --no-threads")
    else:
        print("\nจะแก้ %d จุด (ยังไม่ได้แก้จริง)" % n)


if __name__ == "__main__":
    main()
