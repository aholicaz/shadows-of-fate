#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
link_card_art.py — เชื่อมภาพการ์ดใน Sprites/card/*.webp เข้ากับไฟล์การ์ด data/cards/*.tres

ทำอะไร (ต่อการ์ด 1 ใบ)
  1) ใส่ช่อง `illustration` ชี้ไปที่ Sprites/card/card_<id>.webp  ← ช่องนี้คือ "ภาพการ์ดเต็มใบ"
     (ระบบไล่ลำดับ illustration → icon → รูปมอน · ดู CardView.card_texture)
  2) ถ้าช่อง `icon` เดิมชี้ไปที่โฟลเดอร์ placeholder/ จะถอดออก
     ไม่งั้นช่องเก็บของจะยังโชว์ภาพชั่วคราวแทนภาพจริง (ช่องเก็บของอ่าน icon ก่อน)
     ★ icon ที่เป็นภาพจริงของผู้ใช้ (ไม่ได้อยู่ใน placeholder/) จะไม่แตะ ★
  3) เติม/แก้ ext_resource + load_steps ให้ถูกต้อง (พร้อม uid ที่อ่านจากไฟล์ .import)

ทำซ้ำได้ — ใบที่เชื่อมไว้ถูกแล้วจะข้าม

รัน: python3 link_card_art.py            (ดูอย่างเดียว)
     python3 link_card_art.py --apply    (แก้จริง)
     เพิ่ม --replace-old-icons ถ้าอยากให้ถอดไอคอนเล็กเดิมที่เป็นภาพจริงออกด้วย
     (ช่องเก็บของจะได้ใช้ภาพการ์ดชุดใหม่เหมือนกันหมด — ใช้กับ drops · fabre · poring · king_poring)
"""
import io
import os
import re
import shutil
import sys

APPLY = "--apply" in sys.argv
# ถอดไอคอนเล็กเดิมที่เป็น "ภาพจริงของผู้ใช้" ออกด้วย เพื่อให้ทุกที่ใช้ภาพการ์ดชุดใหม่เหมือนกันหมด
REPLACE_OLD = "--replace-old-icons" in sys.argv
ROOT = os.path.dirname(os.path.abspath(__file__))
ART_DIR = os.path.join(ROOT, "Sprites", "card")
CARD_DIR = os.path.join(ROOT, "data", "cards")
BAK = os.path.join(ROOT, "_to_delete", "originals_cards_r89")

SCRIPT_UID = "uid://b3076eptxjrrr"   # scripts/resources/card_data.gd


def rd(p):
    return io.open(p, encoding="utf-8").read()


def art_uid(webp_path):
    """อ่าน uid ของภาพจากไฟล์ .import (ไม่มีก็คืน "" — Godot จะใช้ path แทน)"""
    imp = webp_path + ".import"
    if not os.path.exists(imp):
        return ""
    m = re.search(r'^uid="([^"]+)"', rd(imp), re.M)
    return m.group(1) if m else ""


def free_ext_id(text, base="art"):
    used = set(re.findall(r'\[ext_resource[^\]]*id="([^"]+)"', text))
    i = 1
    while "%s_%d" % (base, i) in used:
        i += 1
    return "%s_%d" % (base, i)


def link_one(tres_path, webp_rel, uid):
    """คืน (ข้อความใหม่, บันทึกสิ่งที่ทำ) — คืน (None, เหตุผล) ถ้าไม่ต้องแก้"""
    s = rd(tres_path)
    notes = []
    out = s
    res_path = "res://" + webp_rel.replace(os.sep, "/")

    # ---------- 1) ext_resource ของภาพการ์ด ----------
    m = re.search(r'^\[ext_resource type="Texture2D"[^\]]*path="%s"[^\]]*id="([^"]+)"\]$'
                  % re.escape(res_path), out, re.M)
    if m:
        art_id = m.group(1)
    else:
        art_id = free_ext_id(out)
        line = '[ext_resource type="Texture2D" %spath="%s" id="%s"]' % (
            ('uid="%s" ' % uid) if uid else "", res_path, art_id)
        # แทรกต่อจากบรรทัด ext_resource สุดท้าย (หรือหลังหัวไฟล์ถ้ายังไม่มีเลย)
        exts = list(re.finditer(r'^\[ext_resource[^\]]*\]$', out, re.M))
        if exts:
            at = exts[-1].end()
            out = out[:at] + "\n" + line + out[at:]
        else:
            head = re.search(r'^\[gd_resource[^\]]*\]$', out, re.M)
            out = out[:head.end()] + "\n\n" + line + out[head.end():]
        notes.append("ใส่ภาพ")

    # ---------- 2) ช่อง illustration ----------
    want = 'illustration = ExtResource("%s")' % art_id
    if re.search(r'^illustration = .*$', out, re.M):
        cur = re.search(r'^illustration = .*$', out, re.M).group(0)
        if cur != want:
            out = re.sub(r'^illustration = .*$', want, out, flags=re.M)
            notes.append("แก้ illustration")
    else:
        # วางต่อจาก monster_id (เหมือนใบที่ทำไว้แล้ว) ไม่งั้นต่อจาก script =
        anchor = re.search(r'^monster_id = .*$', out, re.M) or re.search(r'^script = .*$', out, re.M)
        out = out[:anchor.end()] + "\n" + want + out[anchor.end():]
        notes.append("ใส่ illustration")

    # ---------- 3) ถอด icon ที่เป็น placeholder ----------
    im = re.search(r'^icon = ExtResource\("([^"]+)"\)$', out, re.M)
    if im:
        icon_id = im.group(1)
        em = re.search(r'^\[ext_resource type="Texture2D"[^\]]*path="([^"]+)"[^\]]*id="%s"\]$'
                       % re.escape(icon_id), out, re.M)
        icon_path = em.group(1) if em else ""
        is_ph = "/placeholder/" in icon_path
        if is_ph or (REPLACE_OLD and icon_path):
            out = re.sub(r'^icon = ExtResource\("%s"\)\n' % re.escape(icon_id), "", out, flags=re.M)
            # ถอด ext_resource ทิ้งได้ก็ต่อเมื่อไม่มีใครอ้างถึงอีกแล้ว
            if em and len(re.findall(r'ExtResource\("%s"\)' % re.escape(icon_id), out)) == 0:
                out = re.sub(r'^\[ext_resource type="Texture2D"[^\]]*id="%s"\]\n' % re.escape(icon_id),
                             "", out, flags=re.M)
            notes.append("ถอดไอคอนชั่วคราว" if is_ph else "ถอดไอคอนเดิม")
        elif icon_path:
            notes.append("(คงไอคอนเดิม %s)" % icon_path.replace("res://Sprites/", ""))

    # ---------- 4) load_steps ----------
    n_ext = len(re.findall(r'^\[ext_resource', out, re.M))
    n_sub = len(re.findall(r'^\[sub_resource', out, re.M))
    steps = n_ext + n_sub + 1
    if re.search(r'load_steps=\d+', out):
        out = re.sub(r'load_steps=\d+', "load_steps=%d" % steps, out, count=1)
    else:
        out = re.sub(r'^\[gd_resource type="Resource" script_class="CardData" ',
                     '[gd_resource type="Resource" script_class="CardData" load_steps=%d ' % steps,
                     out, count=1, flags=re.M)

    if out == s:
        return None, "ถูกต้องอยู่แล้ว"
    return out, " · ".join(notes) if notes else "จัด load_steps"


def main():
    if not APPLY:
        print("★ โหมดดูอย่างเดียว ★ ใส่ --apply ถึงจะแก้จริง\n")
    if not os.path.isdir(ART_DIR):
        print("ไม่มีโฟลเดอร์ %s" % ART_DIR)
        return

    arts = sorted(f for f in os.listdir(ART_DIR) if f.lower().endswith(".webp"))
    if APPLY:
        os.makedirs(BAK, exist_ok=True)

    done = skipped = missing = 0
    for f in arts:
        cid = os.path.splitext(f)[0]                 # card_wolf
        tres = os.path.join(CARD_DIR, cid + ".tres")
        if not os.path.exists(tres):
            print("  ! ไม่มีไฟล์การ์ด %s.tres — ข้ามภาพ %s" % (cid, f))
            missing += 1
            continue
        webp_rel = os.path.join("Sprites", "card", f)
        out, note = link_one(tres, webp_rel, art_uid(os.path.join(ART_DIR, f)))
        if out is None:
            print("  = %-24s %s" % (cid, note))
            skipped += 1
            continue
        print("  + %-24s %s" % (cid, note))
        if APPLY:
            bak = os.path.join(BAK, cid + ".tres")
            if not os.path.exists(bak):
                shutil.copy2(tres, bak)
            io.open(tres, "w", encoding="utf-8", newline="\n").write(out)
        done += 1

    print("\nเชื่อม %d ใบ · ถูกอยู่แล้ว %d ใบ · ไม่มีไฟล์การ์ด %d" % (done, skipped, missing))
    if APPLY and done:
        print("สำรองไฟล์เดิมไว้ที่ %s" % os.path.relpath(BAK, ROOT))
    elif not APPLY:
        print("(ยังไม่ได้แก้จริง)")


if __name__ == "__main__":
    main()
