# -*- coding: utf-8 -*-
"""สร้างไฟล์สูตรคราฟต์ data/recipes/*.tres (★ รอบ 132 ★) — idempotent: ไม่ทับไฟล์ที่มีอยู่แล้ว"""
import os
R = [
 # id, result, chapter, materials, zeny, note
 ("muffler",            "muffler",            1, [("fabre_silk",80),("wolf_claw",40),("phracon",5)], 3000, "ชิ้นปิดเซ็ต «ชุดพรานหนัง»"),
 ("wolf_cloak",         "wolf_cloak",         1, [("wolf_fang",60),("wolf_claw",60),("honey_drop",30),("phracon",8)], 5000, "ชิ้นปิดเซ็ต «ชุดนักผจญภัย»"),
 ("brooch",             "brooch",             1, [("stinger",60),("fabre_silk",40),("royal_jelly",1),("phracon",5)], 4000, ""),
 ("iron_greaves",       "iron_greaves",       2, [("iron_ore",100),("golem_plate",40),("hot_gear",20),("phracon",10)], 12000, "ชิ้นปิดเซ็ต «ชุดเหล็กคนแคระ»"),
 ("belt",               "belt",               2, [("orc_bandana",60),("dirt_clump",60),("steel_shell",30),("phracon",8)], 10000, "ชิ้นปิดเซ็ต «ชุดนักขุด»"),
 ("forge_saber",        "forge_saber",        2, [("guardian_core",1),("golem_plate",60),("magma_core",40),("slug_slime",40),("phracon",15)], 20000, "ชิ้นปิดเซ็ต «ชุดเตาหลอม»"),
 ("forge_core_pendant", "forge_core_pendant", 2, [("guardian_core",2),("hot_gear",40),("ember_wing",40),("phracon",12)], 25000, ""),
 ("root_boots",         "root_boots",         3, [("root_fiber",100),("pale_sap",50),("bramble_pelt",40),("phracon",15)], 30000, "ชิ้นปิดเซ็ต «ชุดรากวานาเฮม»"),
 ("thorn_shield",       "thorn_shield",       3, [("bramble_pelt",120),("thorn_fang",60),("matriarch_thorn",2),("phracon",20)], 45000, "ชิ้นปิดเซ็ต «ชุดผู้พิทักษ์วานีร์»"),
 ("mammoth_wool_cloak", "mammoth_wool_cloak", 4, [("mammoth_wool",100),("frozen_tear",50),("hawk_down",40),("emveretarcon",8)], 70000, "ชิ้นปิดเซ็ต «ชุดหมาป่าน้ำแข็ง»"),
 ("wall_greatsword",    "wall_greatsword",    4, [("wall_fragment",120),("stone_core",40),("ice_bloom",20),("emveretarcon",12)], 100000, "ชิ้นปิดเซ็ต «ชุดกำแพงโยตุน»"),
 ("heart_pendant",      "heart_pendant",      4, [("hrungnir_shard",2),("lightning_dust",60),("stone_core",30),("emveretarcon",10)], 80000, ""),
 ("elven_plate",        "elven_plate",        5, [("hollow_thread",120),("prism_shard",60),("light_scale",60),("emveretarcon",15)], 120000, "ชิ้นปิดเซ็ต «ชุดผลึกอัลฟ์เฮม»"),
 ("mist_shroud",        "mist_shroud",        6, [("ghost_thread",100),("mist_wisp",60),("emveretarcon",12)], 110000, "ชิ้นปิดเซ็ต «ชุดหมอกแสง»"),
 ("ferryman_oar_blade", "ferryman_oar_blade", 6, [("oar_splinter",120),("drowned_helm",40),("frost_marrow",40),("emveretarcon",18)], 200000, "ชิ้นปิดเซ็ต «ชุดผีจมกยอลล์»"),
 ("hel_half_plate",     "hel_half_plate",     6, [("hel_fang",120),("hound_eye",60),("judge_seal",3),("emveretarcon",20)], 300000, "ชิ้นปิดเซ็ต «ชุดผู้พิพากษาเฮล»"),
 ("oathstep_boots",     "oathstep_boots",     7, [("command_link",100),("cinder_fang",60),("last_order_plate",20),("oath_core",1),("emveretarcon",20)], 1500000, "ชิ้นปิดเซ็ต «ชุดผู้ไร้พันธะ»"),
]
os.makedirs('data/recipes', exist_ok=True)
made = 0
for rid, res, ch, mats, zeny, note in R:
    for iid, _ in mats + [(res, 1)]:
        assert os.path.exists('data/items/%s.tres' % iid), iid
    p = 'data/recipes/%s.tres' % rid
    if os.path.exists(p):
        continue
    mat_lines = ',\n'.join('&"%s": %d' % (i, n) for i, n in mats)
    txt = ('[gd_resource type="Resource" script_class="RecipeData" load_steps=2 format=3]\n\n'
           '[ext_resource type="Script" path="res://scripts/resources/recipe_data.gd" id="1_recipe"]\n\n'
           '[resource]\nscript = ExtResource("1_recipe")\n'
           'id = &"%s"\nresult_item_id = &"%s"\nresult_count = 1\nchapter = %d\n'
           'materials = {\n%s\n}\nzeny = %d\nbonus_min = 25.0\nbonus_max = 45.0\nrequired_flag = &""\nnote = "%s"\n'
           % (rid, res, ch, mat_lines, zeny, note))
    open(p, 'w', encoding='utf-8', newline='\n').write(txt)
    made += 1
print('recipes made', made)
