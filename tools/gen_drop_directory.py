# -*- coding: utf-8 -*-
"""สร้าง scripts/core/drop_directory.gd — ตารางว่าไอเทมแต่ละชิ้น "ดรอปจากมอนตัวไหน / ขายที่เมืองไหน" (★ รอบ 132 ★)
รันใหม่เมื่อเพิ่มมอน/ดรอป/ร้าน:  python tools/gen_drop_directory.py   (จากโฟลเดอร์โปรเจกต์)
ใช้ในหน้าต่างคราฟต์ (บอกที่หาวัตถุดิบ) โดยไม่ต้องโหลดไฟล์มอน (ซึ่งลากชีทภาพมาด้วย)"""
import re, glob, os
def rd(p): return open(p, encoding='utf-8', errors='replace').read()
atlas = rd('scripts/core/map_atlas.gd')
mon_map = {}
for m in re.finditer(r'&"(\w+)":\s*\{[^}]*?"monsters":\s*\[([^\]]*)\]', atlas, re.S):
    for mon in re.findall(r'&"(\w+)"', m.group(2)):
        mon_map.setdefault(mon, m.group(1))
mon_name = {}; drops = {}
for p in sorted(glob.glob('data/monsters/*.tres')):
    s = rd(p); mid = os.path.basename(p)[:-5]
    nm = re.search(r'^display_name = "([^"]*)"', s, re.M)
    mon_name[mid] = nm.group(1) if nm else mid
    boss = bool(re.search(r'^is_boss = true', s, re.M))
    for m in re.finditer(r'\[sub_resource type="Resource" id="[^"]+"\]\nscript = ExtResource\("[^"]+"\)\nitem_id = &"(\w+)"\n((?:[a-z_]+ = .*\n)*)', s):
        iid = m.group(1); c = re.search(r'chance = ([\d.]+)', m.group(2))
        drops.setdefault(iid, []).append((mid, float(c.group(1)) if c else 10.0, boss))
shops = {}
for p in sorted(glob.glob('scenes/maps/*.tscn')):
    if 'ก่อน' in p: continue
    town = os.path.basename(p)[:-5]
    s = rd(p)
    for m in re.finditer(r'shop_items = Array\[StringName\]\(\[([^\]]*)\]\)', s):
        for iid in re.findall(r'&"(\w+)"', m.group(1)):
            shops.setdefault(iid, [])
            if town not in shops[iid]: shops[iid].append(town)
lines = ['## DropDirectory — ไอเทมชิ้นนี้หาได้จากไหน (★ รอบ 132 ★ สร้างโดย tools/gen_drop_directory.py — ห้ามแก้มือ)',
         '## ใช้ในหน้าต่างคราฟต์: บอกมอน/แมพ/ร้านที่หาวัตถุดิบ โดยไม่ต้องโหลดไฟล์มอน (ซึ่งลากชีทภาพมาด้วย)',
         'class_name DropDirectory', 'extends RefCounted', '',
         '## item_id → [[monster_id, "ชื่อมอน", map_id, โอกาส%, บอส?], ...] เรียงโอกาสมาก→น้อย',
         'const SOURCES := {']
for iid in sorted(drops):
    rows = sorted(drops[iid], key=lambda r: -r[1])
    body = ', '.join('[&"%s", "%s", &"%s", %.2f, %s]' % (mid, mon_name.get(mid, mid).replace('"', ''), mon_map.get(mid, ''), ch, 'true' if b else 'false') for mid, ch, b in rows)
    lines.append('\t&"%s": [%s],' % (iid, body))
lines += ['}', '', '## item_id → [town_map_id, ...] ที่มีขาย', 'const SHOPS := {']
for iid in sorted(shops):
    lines.append('\t&"%s": [%s],' % (iid, ', '.join('&"%s"' % t for t in shops[iid])))
lines += ['}', '', '',
          'static func sources_of(item_id: StringName) -> Array:', '\treturn SOURCES.get(item_id, [])', '', '',
          'static func shops_of(item_id: StringName) -> Array:', '\treturn SHOPS.get(item_id, [])', '', '',
          '## ข้อความสั้น ๆ "ดรอปจาก X (แมพ) · Y" หรือ "ขายที่ ..." — ใช้ในหน้าต่างคราฟต์',
          'static func describe(item_id: StringName, max_sources: int = 3) -> String:',
          '\tvar parts: Array[String] = []',
          '\tvar n := 0',
          '\tfor row in sources_of(item_id):',
          '\t\tif n >= max_sources:', '\t\t\tbreak',
          '\t\tvar map_name: String = Game.map_display_name(StringName(row[2])) if String(row[2]) != "" else ""',
          '\t\tparts.append("%s%s%s" % [String(row[1]), " (บอส)" if bool(row[4]) else "", (" — " + map_name) if map_name != "" else ""])',
          '\t\tn += 1',
          '\tvar towns := shops_of(item_id)',
          '\tif towns.size() >= 4:',
          '\t\tparts.append("ขายที่ร้านในเมือง")',
          '\telif not towns.is_empty():',
          '\t\tvar names: Array[String] = []',
          '\t\tfor t in towns:', '\t\t\tnames.append(Game.map_display_name(StringName(t)))',
          '\t\tparts.append("ขายที่ " + " / ".join(names))',
          '\tif item_id == &"phracon" or item_id == &"emveretarcon":',
          '\t\tparts.append("ใบประกาศล่าของกิลด์")',
          '\treturn " · ".join(parts) if not parts.is_empty() else "ยังไม่มีที่มา"', '']
open('scripts/core/drop_directory.gd', 'w', encoding='utf-8', newline='\n').write('\n'.join(lines))
print('items with sources:', len(drops), 'shop items:', len(shops))
