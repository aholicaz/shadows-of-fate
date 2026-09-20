# -*- coding: utf-8 -*-
"""★ รอบ 134 ★ สูตรอาวุธบอส + เครื่องประดับ 19 สูตร (idempotent) และใส่ category ให้สูตรเดิม"""
import os, re
R = [
 # id, result, chapter, category, materials, zeny
 ("clip",                 "clip",                 1, "accessory",   [("royal_jelly",2),("chewed_carrot",40),("fabre_silk",30),("phracon",3)], 800),
 ("rapier",               "rapier",               1, "boss_weapon", [("tiny_crown",2),("royal_jelly",3),("stinger",60),("fabre_silk",60),("phracon",8)], 2500),
 ("ring",                 "ring",                 1, "accessory",   [("storm_scale",2),("orc_tooth",50),("wolf_claw",30),("phracon",6)], 4000),
 ("storm_pendant",        "storm_pendant",        1, "accessory",   [("charged_horn",2),("storm_scale",3),("honey_drop",40),("phracon",8)], 6000),
 ("katana",               "katana",               1, "boss_weapon", [("storm_scale",4),("broken_axe_blade",60),("undead_bone",60),("phracon",12)], 10000),
 ("storm_runeblade",      "storm_runeblade",      1, "boss_weapon", [("charged_horn",3),("storm_scale",5),("orc_tooth",80),("wolf_fang",40),("phracon",15)], 12000),
 ("marsh_cutter",         "marsh_cutter",         3, "boss_weapon", [("royal_bloom",3),("matriarch_thorn",2),("bog_bone",80),("thorn_fang",40),("phracon",15)], 18000),
 ("flame_sword",          "flame_sword",          3, "boss_weapon", [("cursed_scythe_shard",3),("baphomet_horn",2),("imp_tail",60),("small_horn",40),("phracon",20)], 22000),
 ("spring_amulet",        "spring_amulet",        3, "accessory",   [("ember_heart",2),("silver_dust",50),("mist_essence",30),("phracon",10)], 12000),
 ("ash_ring",             "ash_ring",             3, "accessory",   [("gullveig_ash",3),("ember_heart",1),("withered_bark",50),("phracon",12)], 15000),
 ("ember_of_gullveig",    "ember_of_gullveig",    3, "boss_weapon", [("ember_heart",3),("gullveig_ash",5),("heartwood_chip",80),("spectral_plume",40),("phracon",20)], 25000),
 ("echo_ring",            "echo_ring",            4, "accessory",   [("hrungnir_shard",1),("giant_bone",40),("echo_shard",40),("emveretarcon",10)], 40000),
 ("stone_hrungnir_blade", "stone_hrungnir_blade", 4, "boss_weapon", [("hrungnir_shard",3),("lightning_dust",60),("wall_fragment",80),("troll_tooth",40),("emveretarcon",15)], 55000),
 ("radiant_ring",         "radiant_ring",         5, "accessory",   [("radiant_core",2),("moth_dust",50),("nymph_pearl",30),("emveretarcon",12)], 50000),
 ("light_crystal_sword",  "light_crystal_sword",  5, "boss_weapon", [("radiant_core",3),("prism_shard",60),("crystal_antler",40),("emveretarcon",15)], 70000),
 ("conduit_edge",         "conduit_edge",         5, "boss_weapon", [("radiant_core",4),("forsaken_ash",30),("light_scale",80),("emveretarcon",18)], 80000),
 ("name_blade",           "name_blade",           6, "boss_weapon", [("throne_splinter",3),("erased_ink",60),("warden_letter",40),("emveretarcon",18)], 150000),
 ("odin_ring",            "odin_ring",            6, "accessory",   [("throne_splinter",3),("garm_chain_link",5),("nidhogg_scale",60),("river_gold",30),("emveretarcon",20)], 180000),
 ("garm_fang",            "garm_fang",            6, "boss_weapon", [("garm_chain_link",5),("throne_splinter",3),("hel_fang",80),("nidhogg_scale",40),("emveretarcon",20)], 200000),
]
made = 0
for rid, res, ch, cat, mats, zeny in R:
    for iid, _ in mats + [(res, 1)]:
        assert os.path.exists('data/items/%s.tres' % iid), iid
    p = 'data/recipes/%s.tres' % rid
    if os.path.exists(p):
        continue
    mat_lines = ',\n'.join('&"%s": %d' % (i, n) for i, n in mats)
    txt = ('[gd_resource type="Resource" script_class="RecipeData" load_steps=2 format=3]\n\n'
           '[ext_resource type="Script" path="res://scripts/resources/recipe_data.gd" id="1_recipe"]\n\n'
           '[resource]\nscript = ExtResource("1_recipe")\n'
           'id = &"%s"\nresult_item_id = &"%s"\nresult_count = 1\nchapter = %d\ncategory = &"%s"\n'
           'materials = {\n%s\n}\nzeny = %d\nbonus_min = 25.0\nbonus_max = 45.0\nrequired_flag = &""\nnote = ""\n'
           % (rid, res, ch, cat, mat_lines, zeny))
    open(p, 'w', encoding='utf-8', newline='\n').write(txt)
    made += 1
# ใส่ category ให้สูตรเดิมที่ยังไม่มี
ACC = {'brooch', 'forge_core_pendant', 'heart_pendant'}
fixed = 0
for f in os.listdir('data/recipes'):
    p = 'data/recipes/' + f; s = open(p, encoding='utf-8').read()
    if 'category = ' in s: continue
    rid = f[:-5]
    cat = 'accessory' if rid in ACC else 'general'
    s = s.replace('\nmaterials = {', '\ncategory = &"%s"\nmaterials = {' % cat, 1)
    open(p, 'w', encoding='utf-8', newline='\n').write(s); fixed += 1
print('made', made, 'category added', fixed, 'total', len(os.listdir('data/recipes')))
