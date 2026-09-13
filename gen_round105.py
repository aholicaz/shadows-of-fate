# -*- coding: utf-8 -*-
## ★★ รอบ 105 — บทที่ 4-6: โยตุนเฮม · อัลฟ์เฮม · นิฟล์เฮม + อาชีพขั้นที่ 3 Ninth Edge ★★
##
## สร้าง: แมพ 19 · มอน 28 (บอส/มินิบอส 6) · NPC 28 · เควส 30 + สาย Runeblade 7 (RB8-RB14) ·
##        ไอเทม (ขยะ 48 · ของเควส 14 · ของสวมใส่ 39 · การ์ด 28) · สกิล Ninth Edge 6 · อาชีพ ninth_edge
## ต่อสาย: ประตูจากวานาเฮม (ล็อก chapter3_done) · เสาวาปทุกเมือง · ทะเบียนแมพ game.gd / map_atlas.gd
## เอนจิน: tools_round105/engine.py (ดูหัวไฟล์นั้น — เงื่อนไขเควส SKILL_HIT · ร่างที่สองของแมพ · HUD ไร้นาม · ฯลฯ)
##
## รันได้ซ้ำ ไม่พัง (แบบเดียวกับ gen_round79.py):
##   - ไฟล์ใหม่ = สร้างเฉพาะที่ยังไม่มี (ไม่ทับของที่ผู้ใช้แก้แล้ว)
##   - ไฟล์เดิม = แก้เฉพาะจุด เช็คก่อนทุกครั้ง (สำรอง *_ก่อนรอบ105.bak)
##
## ★ ปิด Godot ก่อนรัน ★   python3 gen_round105.py
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
os.chdir(ROOT)
sys.path.insert(0, os.path.join(ROOT, "tools_round105"))

from common import LOG, w, patch, build_chapter, make_icons
import engine, ch4, ch5, ch6


def connect_world():
    print("[6] ต่อสาย — ประตูวานาเฮม → ช่องเขาน้ำแข็ง · เสาวาปทุกเมือง")
    # วานาเฮม: จุดเกิด from_pass + ประตูเหนือ (ล็อก chapter3_done) — วางก่อนประตูไปบึง
    patch("scenes/maps/vanir_town.tscn", [
        ('[node name="from_marsh" type="Marker2D" parent="SpawnPoints"',
         '[node name="from_pass" type="Marker2D" parent="SpawnPoints"]\nposition = Vector2(3350, 820)\n\n'
         '[node name="from_marsh" type="Marker2D" parent="SpawnPoints"'),
        ('[node name="ToMarsh" parent="Portals"',
         '[node name="ToFrostPass" parent="Portals" instance=ExtResource("portal")]\n'
         'position = Vector2(3480, 796)\ntarget_map = &"frost_pass"\ntarget_spawn_point = &"from_vanir"\n'
         'label_text = "↑ ช่องเขาน้ำแข็ง (บท 4)"\ndestination_name = "ช่องเขาน้ำแข็ง — โยตุนเฮม"\n'
         'required_flag = &"chapter3_done"\nlocked_text = "ประตูเหนือของวานาเฮมปิดสนิท ลมหนาวรั่วผ่านร่องประตู... ยังไม่มีเหตุผลจะไปทางเหนือ"\n\n'
         '[node name="ToMarsh" parent="Portals"'),
        ('warp_targets = Array[StringName]([&"nidavellir_town", &"prontera_town"])',
         'warp_targets = Array[StringName]([&"nidavellir_town", &"prontera_town", &"utgard_town", &"ljosalf_city", &"eljudnir"])'),
    ], markers=('name="from_pass"', 'name="ToFrostPass"', '&"utgard_town"'))
    for town in ("nidavellir_town", "prontera_town"):
        patch("scenes/maps/%s.tscn" % town, [
            ('warp_targets = Array[StringName]([&"asgard_forest_2", &"vanir_town"])',
             'warp_targets = Array[StringName]([&"asgard_forest_2", &"vanir_town", &"utgard_town", &"ljosalf_city", &"eljudnir"])'),
        ], markers=('&"utgard_town"',))


def main():
    print("[0] เอนจิน (tools_round105/engine.py)")
    engine.apply()
    for ch, no in ((ch4, 4), (ch5, 5), (ch6, 6)):
        print("[%d] บทที่ %d — %s: ไอเทม %d · มอน %d · แมพ %d · เควส %d · สกิล %d" % (
            no - 3, no, ch.REGION, len(ch.JUNK) + len(ch.QUEST_ITEMS) + len(ch.EQUIP), len(ch.MON), len(ch.MAPS), len(ch.QUESTS), len(getattr(ch, "SKILLS", []))))
        build_chapter(ch)
    connect_world()
    make_icons()
    print()
    if LOG:
        print("ทำไปทั้งหมด %d รายการ:" % len(LOG))
        for l in LOG:
            print("  ·", l)
    else:
        print("ทุกอย่างมีครบแล้ว ไม่ได้สร้าง/แก้อะไรเพิ่ม")


if __name__ == "__main__":
    main()
