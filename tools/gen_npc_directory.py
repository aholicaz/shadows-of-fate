#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""รอบ 116 — สร้าง scripts/core/npc_directory.gd (NPC ชื่อนี้อยู่แมพไหน) จาก scenes/maps/*.tscn
รันใหม่ทุกครั้งที่เพิ่ม/ย้าย NPC:   python3 tools/gen_npc_directory.py   (รันจากโฟลเดอร์โปรเจกต์)
ใช้โดย HUD «ภารกิจถัดไป» เพื่อบอกว่าต้องไปคุยกับใครที่เมืองไหน"""
import re, glob, os
maps = {}
npcs = {}
for f in sorted(glob.glob("scenes/maps/*.tscn")):
    map_id = os.path.basename(f)[:-5]
    s = open(f, encoding="utf-8").read()
    m = re.search(r'^display_name = "([^"]+)"', s, re.M)
    maps[map_id] = m.group(1) if m else map_id
    for n in re.findall(r'^npc_name = "([^"]+)"', s, re.M):
        npcs.setdefault(n, [])
        if map_id not in npcs[n]:
            npcs[n].append(map_id)
lines = [
    "## NpcDirectory — NPC ชื่อนี้อยู่แมพไหน (★ รอบ 116 ★ สร้างอัตโนมัติด้วย tools/gen_npc_directory.py — อย่าแก้มือ รันสคริปต์ใหม่แทน)",
    "class_name NpcDirectory",
    "",
    "const MAP_NAMES := {",
]
for k in sorted(maps):
    lines.append('\t&"%s": "%s",' % (k, maps[k]))
lines += ["}", "", "const NPC_MAPS := {"]
for k in sorted(npcs):
    lines.append('\t"%s": [%s],' % (k, ", ".join('&"%s"' % m for m in npcs[k])))
lines += ["}", "", "",
    "## แมพทั้งหมดที่มี NPC ชื่อนี้ (ว่าง = ไม่รู้จัก)",
    "static func maps_of(npc_name: String) -> Array:",
    "\treturn NPC_MAPS.get(npc_name, [])",
    "", "",
    "## ชื่อแมพที่ NPC อยู่ — ถ้ามีหลายที่ เลือกแมพในบทที่ระบุ (chapter 0 = เอาที่แรก) · คืน \"\" ถ้าไม่รู้จัก",
    "static func map_name_of(npc_name: String, chapter: int = 0) -> String:",
    "\tvar ids: Array = maps_of(npc_name)",
    "\tif ids.is_empty():",
    "\t\treturn \"\"",
    "\tvar pick: StringName = ids[0]",
    "\tif chapter > 0:",
    "\t\tfor id in ids:",
    "\t\t\tif MapAtlas.chapter_of(id) == chapter:",
    "\t\t\t\tpick = id",
    "\t\t\t\tbreak",
    "\treturn String(MAP_NAMES.get(pick, String(pick)))",
    ""]
open("scripts/core/npc_directory.gd", "w", encoding="utf-8", newline="\n").write("\n".join(lines))
print("NPC %d ตัว · แมพ %d" % (len(npcs), len(maps)))
