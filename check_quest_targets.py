#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
★ รอบ 76 ★ ตรวจว่า "เงื่อนไขเควสทุกข้อทำได้จริงไหม"

เจอปัญหาจริงมาแล้ว: เควส M2 สั่งให้ไปทำพิธีที่ «ศิลาสลักแห่งธอร์»
แต่เสาหินในฉากถูกเปลี่ยนชื่อเป็น «เสาวาปแห่งธอร์» ตั้งแต่รอบ 57 → เควสค้าง เล่นต่อไม่ได้

สคริปต์นี้ไล่เช็คทุกเควสว่า:
  TALK   (kind 0? ดูตาราง) — มี NPC ชื่อนี้ (หรือ Quest Talk Names) อยู่ในฉากไหนสักฉาก
  KILL   — มี data/monsters/<id>.tres
  COLLECT— มี data/items/<id>.tres
  VISIT  — มี scenes/maps/<id>.tscn
  READ   — มีจุดอ่าน (LoreObject) id นี้ในฉากไหนสักฉาก

ใช้:  python3 check_quest_targets.py
"""
import os, re, glob

ROOT = os.path.dirname(os.path.abspath(__file__))
# ObjectiveData.Kind — เรียงตามลำดับใน scripts/resources/objective_data.gd
KIND = {0: "KILL", 1: "COLLECT", 2: "TALK", 3: "VISIT", 4: "READ", 5: "FLAG"}


def scene_names(prop):
    """เก็บค่าทั้งหมดของ prop (เช่น npc_name) จากทุกฉาก -> {ค่า: [ไฟล์]}"""
    out = {}
    for path in glob.glob(os.path.join(ROOT, "scenes", "**", "*.tscn"), recursive=True):
        text = open(path, encoding="utf-8", errors="ignore").read()
        # รับทั้ง  prop = "ชื่อ"  และ  prop = &"ชื่อ"  (StringName)
        for m in re.finditer(r'^%s = &?"([^"]*)"' % prop, text, re.M):
            out.setdefault(m.group(1), []).append(os.path.basename(path))
        # Array[StringName]([&"ก", &"ข"])
        for m in re.finditer(r'^%s = Array\[StringName\]\(\[([^\]]*)\]\)' % prop, text, re.M):
            for n in re.findall(r'&"([^"]*)"', m.group(1)):
                out.setdefault(n, []).append(os.path.basename(path))
    return out


def objectives(text):
    """คืน [(kind, target, ข้อความ)] จากไฟล์เควส (sub_resource ของ ObjectiveData)"""
    out = []
    for block in re.split(r"^\[sub_resource", text, flags=re.M)[1:]:
        block = block.split("\n[")[0]
        k = re.search(r"^kind = (\d+)", block, re.M)
        t = re.search(r'^target = &"([^"]*)"', block, re.M)
        x = re.search(r'^text = "([^"]*)"', block, re.M)
        if t is None:
            continue
        out.append((int(k.group(1)) if k else 0, t.group(1), x.group(1) if x else ""))
    # แบบเก่า: kill_monster_id ในบล็อก [resource]
    m = re.search(r'^kill_monster_id = &"([^"]+)"', text, re.M)
    if m and m.group(1):
        out.append((0, m.group(1), "(แบบเก่า kill_monster_id)"))
    return out


def main():
    npcs = scene_names("npc_name")
    aliases = scene_names("quest_talk_names")
    lore = scene_names("lore_id")
    lore.update(scene_names("read_id"))
    bad = 0
    for path in sorted(glob.glob(os.path.join(ROOT, "data", "quests", "*.tres"))):
        text = open(path, encoding="utf-8").read()
        qid = os.path.basename(path)[:-5]
        for kind, target, label in objectives(text):
            name = KIND.get(kind, str(kind))
            ok, why = True, ""
            if name == "TALK":
                ok = target in npcs or target in aliases
                why = "ไม่มี NPC ชื่อนี้ในฉากไหนเลย (และไม่มีใครใส่ Quest Talk Names ไว้)"
            elif name == "KILL":
                ok = os.path.exists(os.path.join(ROOT, "data", "monsters", target + ".tres"))
                why = "ไม่มี data/monsters/%s.tres" % target
            elif name == "COLLECT":
                ok = os.path.exists(os.path.join(ROOT, "data", "items", target + ".tres"))
                why = "ไม่มี data/items/%s.tres" % target
            elif name == "VISIT":
                ok = os.path.exists(os.path.join(ROOT, "scenes", "maps", target + ".tscn"))
                why = "ไม่มี scenes/maps/%s.tscn" % target
            elif name == "READ":
                ok = target in lore
                why = "ไม่มีจุดอ่าน (LoreObject) id นี้ในฉากไหนเลย"
            else:
                continue     # FLAG — ธงตั้งจากที่ไหนก็ได้ ตรวจอัตโนมัติไม่ได้
            if not ok:
                bad += 1
                print("  ✗ %-24s %-8s «%s»" % (qid, name, target))
                print("      %s%s" % (why, ("  · ข้อความ: " + label) if label else ""))
    if bad == 0:
        print("  ✓ เงื่อนไขเควสทุกข้อมีเป้าหมายอยู่จริง")
    else:
        print("\n  รวม %d ข้อที่ทำไม่ได้" % bad)
        print("  วิธีแก้: เปลี่ยน Target ในไฟล์เควสให้ตรงชื่อใหม่")
        print("         หรือใส่ชื่อเดิมไว้ที่ช่อง Quest Talk Names ของ NPC/ของชิ้นนั้นในฉาก")


if __name__ == "__main__":
    main()
