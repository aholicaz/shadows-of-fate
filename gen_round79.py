# -*- coding: utf-8 -*-
## ★★ รอบ 79 — บทที่ 3 วานาเฮม «สงครามที่ไม่มีใครจำ» ★★
##
## สร้าง: แมพ 6 · มอน 8 + บอส 1 · NPC 8 · จุดอ่าน 5 · ไอเทม (ขยะ 18 · การ์ด 9 · ของสวมใส่ 13 · ของเควส 4) · เควส 10
## ต่อสาย: ประตูจากเตาหลอมร้าง (ล็อกธง chapter2_done) · เสาวาปนิดาเวลลิร์/พรอนเทรา · ทะเบียนแมพใน game.gd
##
## รันได้ซ้ำ ไม่พัง (แบบเดียวกับ gen_round31.py):
##   - ไฟล์ใหม่ = สร้างเฉพาะที่ยังไม่มี (ไม่ทับของที่ผู้ใช้แก้แล้ว)
##   - ไฟล์เดิม = แก้เฉพาะจุด เช็คก่อนทุกครั้ง (สำรอง *_ก่อนรอบ79.bak)
##   - ไอคอน/สไปรท์ชั่วคราว = สร้างด้วย PIL ถ้ามี · ไม่มีก็ข้าม (zip มีไฟล์ png มาให้แล้ว)
##
## ★ ปิด Godot ก่อนรัน ★   python3 gen_round79.py
import os, re, shutil, struct, zlib

ROOT = os.path.dirname(os.path.abspath(__file__))
os.chdir(ROOT)
LOG = []
CHAPTER = 3
REGION = "วานาเฮม"


def w(path, text, overwrite=False):
    if os.path.exists(path) and not overwrite:
        return False
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    open(path, "w", encoding="utf-8", newline="\n").write(text)
    LOG.append("สร้าง " + path)
    return True


def backup(path, tag):
    base, ext = os.path.splitext(path)
    bak = "%s_ก่อน%s%s.bak" % (base, tag, ext)
    if not os.path.exists(bak):
        shutil.copy(path, bak)


def patch(path, pairs, tag="รอบ79", markers=()):
    if not os.path.exists(path):
        print("  ! ไม่มีไฟล์", path); return
    s = open(path, encoding="utf-8").read()
    hits = 0
    for i, (old, new) in enumerate(pairs):
        if new in s:
            continue
        if i < len(markers) and markers[i] and markers[i] in s:
            continue
        if old not in s:
            print("  ! ไม่เจอใน %s: %s" % (path, old[:70].replace("\n", "|")))
            continue
        s = s.replace(old, new, 1)
        hits += 1
    if hits:
        backup(path, tag)
        open(path, "w", encoding="utf-8", newline="\n").write(s)
        LOG.append("แก้ %s (%d จุด)" % (path, hits))


ITEM_SCRIPT = '[ext_resource type="Script" path="res://scripts/resources/item_data.gd" id="1_item"]'
ICON_DIR = "Sprites/items/placeholder"
ICON_JOBS = []
COLOR = {
    "junk": (96, 120, 100, 255), "weapon": (178, 52, 52, 255), "shield": (70, 96, 150, 255),
    "head": (150, 110, 50, 255), "armor": (60, 110, 90, 255), "cloak": (110, 70, 130, 255),
    "shoes": (100, 80, 60, 255), "acc": (190, 150, 40, 255), "card": (40, 40, 60, 255), "quest": (60, 140, 120, 255),
}


def icon_line(item_id):
    return '[ext_resource type="Texture2D" path="res://%s/%s.png" id="2_icon"]' % (ICON_DIR, item_id)


# =========================================================
# 1) ไอเทมขยะ / วัตถุดิบ (type 3) — มอนละ 2 ชิ้น
# =========================================================
def junk_tres(item_id, name, desc, sell):
    ICON_JOBS.append((item_id, "".join(x[0] for x in item_id.split("_"))[:2].upper(), COLOR["junk"]))
    return '''[gd_resource type="Resource" script_class="ItemData" load_steps=3 format=3]

%s
%s

[resource]
script = ExtResource("1_item")
id = &"%s"
display_name = "%s"
description = "%s"
icon = ExtResource("2_icon")
type = 3
buy_price = %d
sell_price = %d
''' % (ITEM_SCRIPT, icon_line(item_id), item_id, name, desc, sell * 3, sell)


# (id, ชื่อ, คำอธิบาย, ราคาขาย, มอน, โอกาส%, max_count)
JUNK = [
    ("root_fiber",       "เส้นใยราก",        "เส้นใยเหนียวจากรากเลื้อย ดึงยังไงก็ไม่ขาด",                    120, "root_crawler", 45, 2),
    ("pale_sap",         "ยางไม้ซีด",        "ยางไม้สีซีดเหมือนไม่มีชีวิต ต้นไม้ที่นี่ผลิตยางแบบนี้มานานแล้ว",   210, "root_crawler", 15, 1),
    ("thorn_fang",       "เขี้ยวหนาม",       "เขี้ยวที่มีหนามงอกซ้อน กัดแล้วดึงออกยาก",                       180, "thorn_hound",  40, 1),
    ("bramble_pelt",     "หนังพงหนาม",       "หนังสัตว์ที่มีหนามพืชงอกทะลุออกมา สัตว์กับป่ากลายเป็นสิ่งเดียวกัน", 320, "thorn_hound",  15, 1),
    ("mist_essence",     "แก่นหมอก",         "หมอกสีเงินที่จับตัวเป็นก้อน เย็นเฉียบ ค่อย ๆ ระเหยถ้าไม่เก็บในขวด",  260, "mist_sprite",  40, 2),
    ("silver_dust",      "ผงเงิน",           "ผงแวววาวที่ภูตหมอกทิ้งไว้ ชาววานีร์ใช้ทำยา",                     150, "mist_sprite",  25, 2),
    ("bog_bone",         "กระดูกบึง",        "กระดูกที่แช่บึงมานาน ดำและหนักผิดปกติ",                          200, "bog_lurker",   45, 2),
    ("aesir_helm_rusted","หมวกเอซีร์ขึ้นสนิม","หมวกทหารเก่าขึ้นสนิม ตราค้อนสายฟ้าที่ข้างหมวกยังเห็นชัด...",       900, "bog_lurker",   18, 1),
    ("withered_bark",    "เปลือกไม้เหี่ยว",  "เปลือกไม้แห้งกรอบทั้งที่ต้นยังยืนอยู่ เหมือนถูกดูดชีวิตจากข้างใน",  240, "withered_treant", 50, 3),
    ("heartwood_chip",   "เศษแก่นไม้",       "เศษแก่นไม้ที่ยังมีเส้นแสงเขียวจาง ๆ ชีวิตสุดท้ายของต้นไม้",       700, "withered_treant", 12, 1),
    ("sentinel_core",    "แกนผู้พิทักษ์วานีร์","ก้อนหินกลมเรืองแสงเขียว ใครสร้างผู้พิทักษ์พวกนี้ และสร้างไว้กันใคร", 1100, "vanir_sentinel", 35, 1),
    ("carved_stone",     "หินสลักลายวานีร์", "เศษหินสลักลายเถาวัลย์ ลวดลายเก่ากว่าตราค้อนใด ๆ ที่เคยเห็น",    400, "vanir_sentinel", 30, 2),
    ("spectral_plume",   "ขนนกวิญญาณ",       "ขนนกจากหมวกทหาร ยังโปร่งแสงเหมือนเจ้าของ",                     600, "war_wraith",   40, 1),
    ("storm_medal",      "เหรียญตราสายฟ้า",  "เหรียญเชิดชูเกียรติของกองทัพเอซีร์ จารึกว่า «ผู้พิชิตวานาเฮม»",   1800, "war_wraith",   8,  1),
    ("matriarch_thorn",  "หนามราชินี",       "หนามยาวเท่าแขน แข็งกว่าเหล็ก ปลายยังมียางพิษซึม",                2600, "thorn_matriarch", 100, 2),
    ("royal_bloom",      "ดอกไม้ราชินี",     "ดอกไม้สีแดงเข้มที่บานอยู่บนตัวราชินีหนาม ไม่เหี่ยวแม้เด็ดออกมาแล้ว", 5000, "thorn_matriarch", 40, 1),
    ("gullveig_ash",     "เถ้ากุลล์ไวก์",    "เถ้าที่ยังอุ่นอยู่ตลอดเวลา ถูกเผาสามครั้ง... และยังไม่ยอมมอด",       9000, "gullveig_ember", 100, 1),
    ("ember_heart",      "หัวใจเพลิง",       "ก้อนแสงสีทองแดงเต้นตุบ ๆ เหมือนหัวใจ ร้อนจนถือนานไม่ได้",           15000, "gullveig_ember", 60, 1),
]

# ของเควส (type 4)
QUEST_ITEMS = [
    ("vanir_seal", "ตราวานีร์", "ตราประทับลายเถาวัลย์ของชาววานีร์ — ผู้ถือคือแขกของนครแห่งราก"),
    ("spring_vial", "ขวดน้ำจากบ่อ", "น้ำใสจากบ่อน้ำแห่งชีวิต... เหลืออยู่แค่ก้นขวด และแสงในน้ำก็จางลงทุกวัน"),
    ("frida_song", "บทเพลงของฟรีดา", "กระดาษจดเนื้อเพลงที่เด็กหญิงร้อง — ท่อนสุดท้ายต่างจากที่วิหารสอน"),
    ("eskil_chronicle", "พงศาวดารของเอสกิล", "สมุดบันทึกประวัติศาสตร์ฉบับทางการ หน้าเรื่องสงครามวานีร์ถูกเขียนใหม่หลายรอบ"),
]


def quest_item_tres(item_id, name, desc):
    ICON_JOBS.append((item_id, "Q", COLOR["quest"]))
    return '''[gd_resource type="Resource" script_class="ItemData" load_steps=3 format=3]

%s
%s

[resource]
script = ExtResource("1_item")
id = &"%s"
display_name = "%s"
description = "%s"
icon = ExtResource("2_icon")
type = 4
buy_price = 0
sell_price = 0
''' % (ITEM_SCRIPT, icon_line(item_id), item_id, name, desc)


# =========================================================
# 2) ของสวมใส่ Lv 40-60 (13 ชิ้น)
# =========================================================
def equip_tres(e):
    lines = [
        '[gd_resource type="Resource" script_class="ItemData" load_steps=3 format=3]', '',
        ITEM_SCRIPT, icon_line(e["id"]), '', '[resource]', 'script = ExtResource("1_item")',
        'id = &"%s"' % e["id"], 'display_name = "%s"' % e["name"], 'description = "%s"' % e["desc"],
        'icon = ExtResource("2_icon")',
    ]
    if e["lv"] > 1:
        lines.append("required_level = %d" % e["lv"])
    lines.append("type = %d" % e["type"])
    lines.append("slot = %d" % e["slot"])
    if e["slot"] == 1:
        lines.append('weapon_type = &"sword"')
        lines.append('attack_animation = &"Attack_Blade"')
    lines.append("card_slots = %d" % e.get("cards", 1))
    lines.append("max_stack = 1")
    lines.append("buy_price = %d" % e["buy"])
    lines.append("sell_price = %d" % (e["buy"] * 2 // 5))
    for k in ["atk", "matk", "def", "mdef", "hit", "flee", "crit", "max_hp", "max_sp",
              "bonus_str", "bonus_agi", "bonus_vit", "bonus_int", "bonus_dex", "bonus_luk"]:
        if e.get(k):
            lines.append("%s = %d" % (k, e[k]))
    if e.get("aspd"):
        lines.append("aspd_percent = %.1f" % e["aspd"])
    if e["slot"] in (1, 2, 3, 4, 5, 6):
        lines.append("refinable = true")
        if e["slot"] == 1:
            lines.append("refine_atk_per_level = %d" % e.get("ref", 5))
    return "\n".join(lines) + "\n"


def E(id, name, desc, slot, lv, buy, tint, code, **st):
    d = {"id": id, "name": name, "desc": desc, "slot": slot, "lv": lv, "buy": buy, "type": 1 if slot == 1 else 2}
    d.update(st)
    ICON_JOBS.append((id, code, COLOR[tint]))
    return d


EQUIP = [
    # ---- อาวุธ ----
    E("root_sword", "ดาบราก", "ดาบที่ใบเป็นรากไม้แข็งพันกัน เบาและยืดหยุ่น", 1, 40, 78000, "weapon", "RS", atk=108, flee=4, ref=5),
    E("marsh_cutter", "ดาบตัดบึง", "ดาบใบกว้างของนักล่าบึง ฟันทะลุน้ำหนืด ๆ ได้", 1, 46, 110000, "weapon", "MC", atk=124, hit=6, ref=5),
    E("sentinel_blade", "ดาบผู้พิทักษ์", "ดาบหินสลักลายเถาวัลย์ที่ผู้พิทักษ์วานีร์ถือ หนักแต่มั่นคง", 1, 52, 160000, "weapon", "SB", atk=142, **{"def": 5}),
    E("aesir_warblade", "ดาบสงครามเอซีร์", "ดาบมาตรฐานกองทัพเอซีร์ ตราค้อนสายฟ้าบนด้าม... มาอยู่ในบึงวานาเฮมได้ยังไง", 1, 56, 220000, "weapon", "AW", atk=160, bonus_str=2, ref=6),
    E("ember_of_gullveig", "ดาบเพลิงกุลล์ไวก์", "ดาบที่ใบยังลุกไหม้เบา ๆ ไม่มีวันมอด — เผาสามครั้งก็ยังไม่ตาย", 1, 60, 400000, "weapon", "EG", atk=185, matk=30, bonus_int=2, ref=6),
    # ---- โล่ ----
    E("thorn_shield", "โล่หนาม", "โล่ที่ทำจากหนามราชินีสานกัน ใครตีก็เจ็บกลับ", 2, 54, 150000, "shield", "TS", max_hp=80, **{"def": 34}),
    # ---- หมวก ----
    E("vanir_circlet", "มงกุฎวานีร์", "มงกุฎเถาวัลย์เงินของชาววานีร์ เย็นสบายศีรษะ", 3, 48, 90000, "head", "VC", bonus_int=2, max_sp=40, **{"def": 16}),
    # ---- เกราะ ----
    E("bark_armor", "เกราะเปลือกไม้", "เกราะจากเปลือกไม้แก่นแข็ง เบากว่าเหล็กแต่กันได้ไม่แพ้กัน", 4, 42, 95000, "armor", "BA", max_hp=150, **{"def": 30}),
    E("sentinel_plate", "เกราะผู้พิทักษ์", "แผ่นหินเรืองแสงเขียวจากตัวผู้พิทักษ์ ประกอบเป็นเกราะ หนักมาก", 4, 52, 210000, "armor", "SP", max_hp=260, aspd=-6.0, bonus_vit=2, **{"def": 42}),
    # ---- ผ้าคลุม ----
    E("mist_cloak", "ผ้าคลุมหมอก", "ผ้าคลุมทอจากแก่นหมอก ห่มแล้วเหมือนตัวจางลง", 5, 44, 88000, "cloak", "MK", flee=10, mdef=5, **{"def": 10}),
    # ---- รองเท้า ----
    E("root_boots", "รองเท้าราก", "รองเท้าที่รากไม้พันขึ้นมาถึงข้อเท้า ยืนบนพื้นไหนก็ไม่ล้ม", 6, 46, 92000, "shoes", "RB", max_hp=120, bonus_agi=1, **{"def": 13}),
    # ---- เครื่องประดับ ----
    E("spring_amulet", "เครื่องรางบ่อน้ำ", "หยดน้ำจากบ่อน้ำแห่งชีวิตในกรอบเงิน ยังส่องแสงจาง ๆ", 7, 50, 180000, "acc", "SA", max_hp=150, bonus_vit=3, cards=0),
    E("ash_ring", "แหวนเถ้า", "แหวนที่หล่อจากเถ้ากุลล์ไวก์ อุ่นตลอดเวลา", 7, 58, 260000, "acc", "AR", atk=10, bonus_str=3, cards=0),
]

# =========================================================
# 3) มอนบท 3 (8 ตัว + บอส) — สไปรท์ชั่วคราว รอวาด
# =========================================================
# element: NEUTRAL0 FIRE1 WATER2 EARTH3 WIND4 POISON5 HOLY6 SHADOW7 GHOST8 UNDEAD9
# race: FORMLESS0 UNDEAD1 BRUTE2 PLANT3 INSECT4 FISH5 DEMON6 DEMIHUMAN7 ANGEL8 DRAGON9 · size S0 M1 L2 · ai PASSIVE0 AGGR1 STAT2
MON = [
    dict(id="root_crawler", name="รากเลื้อย", lv=39, hp=3600, atk=(200, 260), df=34, mdef=20, hit=64, flee=30, crit=2,
         el=3, race=3, size=1, ai=0, spd=85, exp=2200, zeny=(500, 900), h=170, hb=(46, 34), color=(90, 120, 60), code="RC",
         card=dict(slot=6, max_hp=150, bonus_vit=1, r=3, txt="รากที่ยึดพื้นไว้แน่น"),
         extra=[("red_potion", 8, 2), ("bark_armor", 0.8, 1)]),
    dict(id="thorn_hound", name="หมาป่าหนาม", lv=41, hp=4200, atk=(230, 300), df=30, mdef=16, hit=72, flee=44, crit=5,
         el=3, race=2, size=1, ai=1, spd=190, exp=2600, zeny=(600, 1000), h=180, hb=(48, 40), jump=-360, color=(70, 110, 50), code="TH",
         card=dict(slot=5, flee=8, bonus_agi=2, r=3, txt="วิ่งทะลุพงหนามโดยไม่เจ็บ"),
         extra=[("meat", 25, 2), ("root_boots", 0.8, 1)]),
    dict(id="mist_sprite", name="ภูตหมอก", lv=44, hp=3800, atk=(240, 320), df=22, mdef=48, hit=78, flee=62, crit=6,
         el=4, race=0, size=0, ai=1, spd=160, exp=3000, zeny=(650, 1100), h=150, hb=(36, 36), fly=True, color=(170, 190, 210), code="MS",
         card=dict(slot=7, flee=10, mdef=5, r=4, txt="จับต้องไม่ได้ดั่งหมอก"),
         extra=[("blue_potion", 12, 1), ("mist_cloak", 1.0, 1)]),
    dict(id="bog_lurker", name="ผีบึง", lv=46, hp=5600, atk=(260, 340), df=48, mdef=30, hit=74, flee=20, crit=2,
         el=2, race=1, size=1, ai=0, spd=70, exp=3400, zeny=(700, 1200), h=190, hb=(52, 46), kb=220, color=(50, 70, 60), code="BL",
         card=dict(slot=4, max_hp=200, mdef=4, r=3, txt="ร่างที่บึงกลืนไว้"),
         extra=[("orange_potion", 12, 1), ("marsh_cutter", 0.8, 1)]),
    dict(id="withered_treant", name="ต้นไม้เหี่ยว", lv=49, hp=7400, atk=(280, 370), df=56, mdef=26, hit=76, flee=8, crit=1,
         el=3, race=3, size=2, ai=0, spd=45, exp=4000, zeny=(800, 1400), h=280, hb=(70, 70), kb=280, color=(110, 90, 50), code="WT",
         card=dict(slot=2, pct={"def_percent": 6.0}, max_hp=120, r=4, txt="ยืนอยู่ได้แม้ข้างในตายแล้ว"),
         extra=[("white_potion", 10, 1), ("heartwood_chip", 0, 1)]),
    dict(id="vanir_sentinel", name="ผู้พิทักษ์วานีร์", lv=52, hp=6800, atk=(300, 400), df=64, mdef=40, hit=84, flee=24, crit=2,
         el=0, race=0, size=2, ai=1, spd=90, exp=4600, zeny=(900, 1600), h=250, hb=(62, 66), kb=260, color=(100, 160, 120), code="VS",
         card=dict(slot=1, atk=14, **{"def": 4}, r=4, txt="ผู้พิทักษ์ที่สร้างไว้กัน «เทพ» ไม่ใช่มอน"),
         extra=[("emveretarcon", 5, 2), ("sentinel_blade", 1.0, 1), ("sentinel_plate", 0.8, 1)]),
    dict(id="war_wraith", name="วิญญาณนักรบเอซีร์", lv=55, hp=6200, atk=(320, 430), df=40, mdef=60, hit=92, flee=58, crit=8,
         el=8, race=1, size=1, ai=1, spd=150, exp=5200, zeny=(1000, 1800), h=210, hb=(44, 56), color=(120, 130, 170), code="WW",
         card=dict(slot=1, crit=5, pct={"atk_percent": 5.0}, r=4, txt="ทหารที่ยังสู้ในสงครามที่ไม่มีใครจำ"),
         extra=[("white_potion", 15, 1), ("aesir_warblade", 1.0, 1), ("aesir_helm_rusted", 12, 1)],
         bolt=dict(count=3, start=140, spacing=140, mult=1.4, delay=0.35, cd=10.0, chance=0.5, name="สายฟ้าสงคราม")),
    dict(id="thorn_matriarch", name="ราชินีหนาม", lv=57, hp=16000, atk=(360, 470), df=62, mdef=44, hit=96, flee=30, crit=3,
         el=3, race=3, size=2, ai=1, spd=95, exp=14000, zeny=(4000, 7000), h=320, hb=(84, 92), kb=340, boss="ราชินีหนาม",
         color=(60, 130, 40), code="TM",
         card=dict(slot=2, **{"def": 12}, pct={"max_hp_percent": 6.0}, r=5, txt="หนามที่ปกป้องป่ามาก่อนมีเทพ"),
         extra=[("white_potion", 100, 3), ("emveretarcon", 5, 3), ("thorn_shield", 8, 1), ("vanir_circlet", 6, 1), ("marsh_cutter", 8, 1)],
         wave=dict(count=1, both=True, speed=480, rng=800, height=140, frames="fx_thorn_wave", mult=1.8, delay=0.5,
                   cd=9.0, chance=0.65, name="หนามทะลวงพื้น", anim="Skill")),
    dict(id="gullveig_ember", name="เพลิงกุลล์ไวก์", lv=60, hp=32000, atk=(420, 560), df=70, mdef=80, hit=110, flee=48, crit=6,
         el=1, race=8, size=2, ai=1, spd=110, exp=40000, zeny=(12000, 20000), h=360, hb=(80, 110), kb=380, boss="ผู้ถูกเผาสามครั้ง",
         color=(230, 120, 40), code="GE", fly=True, hover=60,
         card=dict(slot=4, mdef=12, pct={"max_hp_percent": 10.0}, r=5, txt="เพลิงที่เผาสามครั้งแล้วยังไม่มอด"),
         extra=[("white_potion", 100, 5), ("emveretarcon", 5, 5), ("ember_of_gullveig", 8, 1), ("ash_ring", 8, 1),
                ("sentinel_plate", 6, 1), ("spring_amulet", 6, 1)],
         wave=dict(count=3, both=True, speed=560, rng=1000, height=160, frames="fx_fire_wave", mult=2.0, delay=0.45,
                   cd=8.0, chance=0.75, name="เพลิงสามครั้ง", anim="Skill"),
         respawn=600),
]


def monster_tres(m):
    junks = [j for j in JUNK if j[4] == m["id"]]
    subs, refs = [], []
    n = 0
    for (jid, _n, _d, _s, _m, chance, maxc) in junks:
        subs.append('[sub_resource type="Resource" id="Drop_%s_%d"]\nscript = ExtResource("2_drop")\nitem_id = &"%s"\nchance = %.1f\n%s'
                    % (m["id"], n, jid, chance, ("max_count = %d\n" % maxc) if maxc > 1 else ""))
        refs.append('SubResource("Drop_%s_%d")' % (m["id"], n)); n += 1
    for (iid, chance, maxc) in m.get("extra", []):
        if chance <= 0:
            continue
        subs.append('[sub_resource type="Resource" id="Drop_%s_%d"]\nscript = ExtResource("2_drop")\nitem_id = &"%s"\nchance = %.1f\n%s'
                    % (m["id"], n, iid, chance, ("max_count = %d\n" % maxc) if maxc > 1 else ""))
        refs.append('SubResource("Drop_%s_%d")' % (m["id"], n)); n += 1
    subs.append('[sub_resource type="Resource" id="Drop_%s_card"]\nscript = ExtResource("2_drop")\nitem_id = &"card_%s"\nchance = %.1f\n'
                % (m["id"], m["id"], 2.0 if m.get("boss") else 0.5))
    refs.append('SubResource("Drop_%s_card")' % m["id"])

    ext = ['[ext_resource type="Script" path="res://scripts/resources/monster_data.gd" id="1_monster"]',
           '[ext_resource type="Script" path="res://scripts/resources/drop_entry.gd" id="2_drop"]',
           '[ext_resource type="SpriteFrames" path="res://data/sprites/monsters/%s_frames.tres" id="3_frames"]' % m["id"]]
    body = [
        'script = ExtResource("1_monster")',
        'id = &"%s"' % m["id"], 'display_name = "%s"' % m["name"],
        'sprite_frames = ExtResource("3_frames")',
        'hitbox_size = Vector2(%d, %d)' % m["hb"],
        'hp_bar_offset_y = %.1f' % (-(m["h"] * 0.38)),
        'display_height = %.1f' % m["h"],
        'level = %d' % m["lv"], 'max_hp = %d' % m["hp"],
        'atk_min = %d' % m["atk"][0], 'atk_max = %d' % m["atk"][1],
        'def = %d' % m["df"], 'mdef = %d' % m["mdef"], 'hit = %d' % m["hit"], 'flee = %d' % m["flee"], 'crit = %d' % m["crit"],
        'element = %d' % m["el"], 'race = %d' % m["race"], 'size = %d' % m["size"], 'ai_type = %d' % m["ai"],
        'move_speed = %.1f' % m["spd"],
        'jump_force = %.1f' % m.get("jump", -280),
        'jump_while_chasing = %s' % ("true" if m.get("jump") else "false"),
        'detect_range = %.1f' % (460 if m["ai"] == 1 else 260),
        'attack_range = %.1f' % (70 + m["hb"][0]),
        'leash_range = 800.0', 'wander_range = 260.0',
        'hop_while_wandering = %s' % ("true" if m.get("jump") else "false"),
        'attack_windup = 0.4', 'attack_duration = 0.5', 'attack_cooldown = 1.8',
        'knockback_force = %.1f' % m.get("kb", 170),
        'exp_reward = %d' % m["exp"], 'job_exp_reward = %d' % int(m["exp"] * 0.7),
        'zeny_min = %d' % m["zeny"][0], 'zeny_max = %d' % m["zeny"][1],
        'drops = Array[ExtResource("2_drop")]([%s])' % ", ".join(refs),
        'respawn_time = %.1f' % m.get("respawn", 120.0 if m.get("boss") else 18.0),
    ]
    if m.get("fly"):
        body += ['flying = true', 'hover_height = %.1f' % m.get("hover", 110.0), 'flying_no_hop = true']
    if m.get("boss"):
        body += ['is_boss = true', 'boss_title = "%s"' % m["boss"]]
    if m.get("bolt"):
        b = m["bolt"]
        body += ['skill_name = "%s"' % b["name"], 'skill_anim = &"Skill"', 'skill_range = 520.0',
                 'skill_damage_mult = %.1f' % b["mult"], 'skill_windup = 0.5', 'skill_duration = 1.0',
                 'skill_cooldown = %.1f' % b["cd"], 'skill_chance = %.2f' % b["chance"],
                 'skill_bolt_count = %d' % b["count"], 'skill_bolt_start = %.1f' % b["start"],
                 'skill_bolt_spacing = %.1f' % b["spacing"], 'skill_bolt_delay = %.2f' % b["delay"]]
    if m.get("wave"):
        v = m["wave"]
        ext.append('[ext_resource type="SpriteFrames" path="res://data/sprites/%s.tres" id="4_wave"]' % v["frames"])
        body += ['skill_name = "%s"' % v["name"], 'skill_anim = &"%s"' % v["anim"], 'skill_range = 600.0',
                 'skill_damage_mult = %.1f' % v["mult"], 'skill_windup = 0.5', 'skill_duration = 1.3',
                 'skill_cooldown = %.1f' % v["cd"], 'skill_chance = %.2f' % v["chance"], 'skill_knockback = 360.0',
                 'skill_wave_count = %d' % v["count"], 'skill_wave_both_sides = %s' % ("true" if v["both"] else "false"),
                 'skill_wave_speed = %.1f' % v["speed"], 'skill_wave_range = %.1f' % v["rng"],
                 'skill_wave_delay = %.2f' % v["delay"], 'skill_wave_height = %.1f' % v["height"],
                 'skill_wave_frames = ExtResource("4_wave")']
    return '[gd_resource type="Resource" script_class="MonsterData" load_steps=%d format=3]\n\n%s\n\n%s\n[resource]\n%s\n' % (
        len(ext) + len(subs) + 1, "\n".join(ext), "\n".join(subs), "\n".join(body))


def frames_tres(m):
    """SpriteFrames ชั่วคราว 6 ท่า (มาตรฐานรอบ 77) — วาดจริงแล้ววางภาพใน Sprites/monster/<id>/ แล้วรัน make_monster_frames.py <id> --force"""
    tex = 'ExtResource("1_tex")'
    def anim(name, n, loop, speed):
        fr = ", ".join(['{\n"duration": 1.0,\n"texture": %s\n}' % tex] * n)
        return '{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}' % (fr, "true" if loop else "false", name, speed)
    return '''[gd_resource type="SpriteFrames" load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://Sprites/monsters/placeholder/%s.png" id="1_tex"]

[resource]
animations = [%s]
''' % (m["id"], ", ".join([anim("Idle", 2, True, 6), anim("Run", 2, True, 10), anim("Attack", 3, False, 12),
                             anim("Hit", 2, False, 10), anim("Die", 3, False, 8), anim("Skill", 3, False, 10)]))


def monster_png(m):
    """สไปรท์ชั่วคราว (วงกลมสี + ตา + ตัวย่อ) — ใช้ PIL ถ้ามี"""
    d = "Sprites/monsters/placeholder"
    os.makedirs(d, exist_ok=True)
    p = os.path.join(d, m["id"] + ".png")
    if os.path.exists(p):
        return
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        return
    hsize = int(m["h"]); wsize = int(m["h"] * 0.8)
    im = Image.new("RGBA", (wsize, hsize), (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    c = m["color"] + (255,)
    dr.ellipse((6, int(hsize * 0.18), wsize - 6, hsize - 4), fill=c, outline=(20, 16, 12, 255), width=4)
    dr.ellipse((int(wsize * 0.25), 4, int(wsize * 0.75), int(hsize * 0.45)), fill=c, outline=(20, 16, 12, 255), width=4)
    ey = int(hsize * 0.22)
    for ex in (int(wsize * 0.38), int(wsize * 0.62)):
        dr.ellipse((ex - 7, ey - 7, ex + 7, ey + 7), fill=(255, 255, 255, 255))
        dr.ellipse((ex - 3, ey - 3, ex + 3, ey + 3), fill=(0, 0, 0, 255))
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", max(18, hsize // 6))
    except Exception:
        font = ImageFont.load_default()
    bbox = dr.textbbox((0, 0), m["code"], font=font)
    dr.text(((wsize - (bbox[2] - bbox[0])) / 2 - bbox[0], hsize * 0.6 - (bbox[3] - bbox[1]) / 2 - bbox[1]), m["code"],
            font=font, fill=(255, 255, 255, 255), stroke_width=3, stroke_fill=(20, 16, 12, 255))
    im.save(p)
    LOG.append("สร้างสไปรท์ชั่วคราว " + p)


def card_tres(m):
    c = m["card"]
    lines = [
        '[gd_resource type="Resource" script_class="CardData" load_steps=3 format=3]', '',
        '[ext_resource type="Script" path="res://scripts/resources/card_data.gd" id="1_card"]',
        icon_line("card_" + m["id"]), '',
        '[resource]', 'script = ExtResource("1_card")',
        'monster_id = &"%s"' % m["id"], 'fits_slot = %d' % c["slot"], 'rarity = %d' % c["r"],
        'id = &"card_%s"' % m["id"], 'display_name = "การ์ด%s"' % m["name"],
        'description = "%s"' % c["txt"], 'icon = ExtResource("2_icon")', 'type = 5', 'slot = 0', 'max_stack = 99',
        'buy_price = 0', 'sell_price = %d' % (m["lv"] * 1500),
    ]
    for k in ["atk", "matk", "flee", "hit", "crit", "max_hp", "mdef", "bonus_str", "bonus_agi", "bonus_vit", "bonus_int", "bonus_luk"]:
        if c.get(k):
            lines.append("%s = %d" % (k, c[k]))
    if c.get("def"):
        lines.append("def = %d" % c["def"])
    if c.get("pct"):
        lines.append("percent_effects = {\n%s\n}" % ",\n".join('"%s": %.1f' % (k, v) for k, v in c["pct"].items()))
    return "\n".join(lines) + "\n"


# =========================================================
# 4) เอฟเฟกต์สกิล — ชีทคลื่น (ไฟ/หนาม) มาพร้อม zip · ที่นี่สร้างแค่ .tres
# =========================================================
def wave_frames_tres(png):
    n, W, H = 8, 192, 160
    lines = ['[gd_resource type="SpriteFrames" load_steps=%d format=3]' % (n + 2), '',
             '[ext_resource type="Texture2D" path="res://Sprites/effects/%s.png" id="1_tex"]' % png, '']
    for i in range(n):
        lines += ['[sub_resource type="AtlasTexture" id="wave_%d"]' % i, 'atlas = ExtResource("1_tex")',
                  'region = Rect2(%d, 0, %d, %d)' % (i * W, W, H), '']
    fr = ", ".join('{\n"duration": 1.0,\n"texture": SubResource("wave_%d")\n}' % i for i in range(n))
    lines += ['[resource]', 'animations = [{', '"frames": [%s],' % fr, '"loop": true,', '"name": &"wave",', '"speed": 14.0', '}]']
    return "\n".join(lines) + "\n"


# =========================================================
# 5) แมพบท 3
# =========================================================
def esc(s):
    return s.replace("\n", "\\n")


def map_tscn(mp):
    ext = [
        '[ext_resource type="Script" path="res://scripts/world/map_base.gd" id="map_base"]',
        '[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="player"]',
        '[ext_resource type="PackedScene" path="res://scenes/monsters/monster.tscn" id="monster_scene"]',
        '[ext_resource type="Script" path="res://scripts/world/map_spawner.gd" id="map_spawner"]',
        '[ext_resource type="Script" path="res://scripts/world/monster_spawner.gd" id="spawner"]',
        '[ext_resource type="Script" path="res://scripts/resources/monster_data.gd" id="monster_data"]',
        '[ext_resource type="PackedScene" path="res://scenes/world/portal.tscn" id="portal"]',
        '[ext_resource type="PackedScene" path="res://scenes/npc/npc.tscn" id="npc"]',
        '[ext_resource type="PackedScene" path="res://scenes/world/lore_object.tscn" id="lore"]',
    ]
    for mid in mp.get("mons", []) + mp.get("boss", []):
        ext.append('[ext_resource type="Resource" path="res://data/monsters/%s.tres" id="md_%s"]' % (mid, mid))
    W, H = mp["w"], mp["h"]
    gy = mp["ground_y"]
    sky, far, gnd = mp["colors"]
    subs = ['[sub_resource type="RectangleShape2D" id="Rect_ground"]\nsize = Vector2(%d, 240)' % (W + 400)]
    plats = mp.get("plats", [])
    for i, (px, py, pw) in enumerate(plats):
        subs.append('[sub_resource type="RectangleShape2D" id="Rect_p%d"]\nsize = Vector2(%d, 32)' % (i, pw))
    nodes = [
        '[node name="Map" type="Node2D"]\nscript = ExtResource("map_base")\nmap_id = &"%s"\ndisplay_name = "%s"\nchapter = %d\nregion = "%s"\nmap_bounds = Rect2(-100, -200, %d, %d)\nplayer_scene = ExtResource("player")'
        % (mp["id"], mp["name"], CHAPTER, REGION, W + 200, H + 200)
        + ('\nenter_flag = &"%s"' % mp["enter_flag"] if mp.get("enter_flag") else ""),
        '[node name="Background" type="Node2D" parent="."]',
        '[node name="Sky" type="Polygon2D" parent="Background"]\nz_index = -100\nposition = Vector2(-100, -200)\ncolor = Color(%s, 1)\npolygon = PackedVector2Array(0, 0, %d, 0, %d, %d, 0, %d)'
        % (sky, W + 200, W + 200, H + 200, H + 200),
        '[node name="FarLayer" type="Polygon2D" parent="Background"]\nz_index = -90\nposition = Vector2(-100, %d)\ncolor = Color(%s, 1)\npolygon = PackedVector2Array(0, 0, %d, 0, %d, %d, 0, %d)'
        % (gy - 360, far, W + 200, W + 200, 360, 360),
        '[node name="Terrain" type="Node2D" parent="."]',
        '[node name="Ground" type="StaticBody2D" parent="Terrain"]\nposition = Vector2(%d, %d)\ncollision_layer = 1\ncollision_mask = 0' % (W // 2, gy + 120),
        '[node name="Shape" type="CollisionShape2D" parent="Terrain/Ground"]\nshape = SubResource("Rect_ground")',
        '[node name="Visual" type="Polygon2D" parent="Terrain/Ground"]\ncolor = Color(%s, 1)\npolygon = PackedVector2Array(%d, -120, %d, -120, %d, 120, %d, 120)'
        % (gnd, -(W + 400) // 2, (W + 400) // 2, (W + 400) // 2, -(W + 400) // 2),
    ]
    for i, (px, py, pw) in enumerate(plats):
        nodes.append('[node name="Plat%d" type="StaticBody2D" parent="Terrain"]\nposition = Vector2(%d, %d)\ncollision_layer = 1\ncollision_mask = 0' % (i, px, py))
        nodes.append('[node name="Shape" type="CollisionShape2D" parent="Terrain/Plat%d"]\nshape = SubResource("Rect_p%d")' % (i, i))
        nodes.append('[node name="Visual" type="Polygon2D" parent="Terrain/Plat%d"]\ncolor = Color(%s, 1)\npolygon = PackedVector2Array(%d, -16, %d, -16, %d, 16, %d, 16)'
                     % (i, gnd, -pw // 2, pw // 2, pw // 2, -pw // 2))
    nodes.append('[node name="SpawnPoints" type="Node2D" parent="."]')
    for sp_name, sx in mp["spawns"]:
        nodes.append('[node name="%s" type="Marker2D" parent="SpawnPoints"]\nposition = Vector2(%d, %d)' % (sp_name, sx, gy - 60))
    nodes.append('[node name="Spawners" type="Node2D" parent="."]')
    if mp.get("mons"):
        nodes.append('[node name="MapSpawner" type="Node2D" parent="Spawners"]\nscript = ExtResource("map_spawner")\nmonster_types = Array[ExtResource("monster_data")]([%s])\ncount_per_type = %d\nmonster_scene = ExtResource("monster_scene")\nmax_spawn_distance = 1700.0'
                     % (", ".join('ExtResource("md_%s")' % m for m in mp["mons"]), mp.get("count", 4)))
    for bid in mp.get("boss", []):
        nodes.append('[node name="Boss_%s" type="Node2D" parent="Spawners"]\nposition = Vector2(%d, %d)\nscript = ExtResource("spawner")\nmonster_types = Array[ExtResource("monster_data")]([ExtResource("md_%s")])\nmonster_scene = ExtResource("monster_scene")\nmax_alive = 1\nspawn_width = 160'
                     % (bid, mp["boss_x"], gy - 30, bid))
    nodes.append('[node name="Portals" type="Node2D" parent="."]')
    for p in mp["portals"]:
        pname, px, tmap, tsp, label, dest = p[:6]
        extra = ""
        if len(p) > 6 and p[6]:
            extra = '\nrequired_flag = &"%s"\nlocked_text = "%s"' % (p[6], p[7])
        nodes.append('[node name="%s" parent="Portals" instance=ExtResource("portal")]\nposition = Vector2(%d, %d)\ntarget_map = &"%s"\ntarget_spawn_point = &"%s"\nlabel_text = "%s"\ndestination_name = "%s"%s'
                     % (pname, px, gy, tmap, tsp, label, dest, extra))
    if mp.get("npcs"):
        nodes.append('[node name="NPCs" type="Node2D" parent="."]')
        for n in mp["npcs"]:
            extra = ""
            if n.get("shop"):
                extra += '\nhas_shop = true' if n["type"] != 1 else ""
                extra += '\nshop_items = Array[StringName]([%s])' % ", ".join('&"%s"' % s for s in n["shop"])
            if n.get("heal"):
                extra += '\nheal_price = %d' % n["heal"]
            if n.get("socket"):
                extra += '\nhas_socket = true'
            if n.get("warp"):
                extra += '\nwarp_targets = Array[StringName]([%s])' % ", ".join('&"%s"' % s for s in n["warp"])
            if n.get("greeting"):
                extra += '\ngreeting = "%s"' % n["greeting"]
            if n.get("voice"):
                extra += '\nvoice_id = "%s"' % n["voice"]
            if n.get("quests"):
                extra += '\nquest_ids = Array[StringName]([%s])' % ", ".join('&"%s"' % q for q in n["quests"])
            if n.get("by_flag"):
                extra += '\ndialog_by_flag = {\n%s\n}' % ",\n".join('"%s": "%s"' % (k, esc(v)) for k, v in n["by_flag"].items())
            nodes.append('[node name="%s" parent="NPCs" instance=ExtResource("npc")]\nposition = Vector2(%d, %d)\nnpc_name = "%s"\ntype = %d\ndialog = "%s"%s'
                         % (n["node"], n["x"], gy - 60, n["name"], n["type"], esc(n["dialog"]), extra))
    if mp.get("lore"):
        nodes.append('[node name="Lore" type="Node2D" parent="."]')
        for l in mp["lore"]:
            extra = ""
            if l.get("flag"):
                extra += '\nrequired_flag = &"%s"\nlocked_text = "%s"' % (l["flag"], l["locked"])
            if l.get("set"):
                extra += '\nset_flag = &"%s"' % l["set"]
            if l.get("give"):
                extra += '\ngive_item = &"%s"' % l["give"]
            nodes.append('[node name="%s" parent="Lore" instance=ExtResource("lore")]\nposition = Vector2(%d, %d)\nlore_id = &"%s"\ntitle = "%s"\ntext = "%s"\nlabel_text = "%s"%s'
                         % (l["node"], l["x"], gy - 90, l["id"], l["title"], esc(l["text"]), l["label"], extra))
    return '[gd_scene load_steps=%d format=3]\n\n%s\n\n%s\n\n%s\n' % (
        len(ext) + len(subs) + 1, "\n".join(ext), "\n\n".join(subs), "\n\n".join(nodes))


SIFA_SHOP = ["red_potion", "orange_potion", "white_potion", "blue_potion", "meat", "phracon", "emveretarcon",
             "root_sword", "marsh_cutter", "bark_armor", "mist_cloak", "root_boots", "vanir_circlet", "spring_amulet",
             "scale_mail", "iron_greaves", "rosary", "belt"]

MAPS = [
    dict(id="root_road", name="ทางสายราก", w=5000, h=1100, ground_y=880,
         colors=("0.12, 0.16, 0.14", "0.18, 0.26, 0.2", "0.28, 0.3, 0.22"),
         plats=[(900, 700, 340), (1900, 620, 320), (2900, 700, 360), (3900, 640, 320)],
         mons=["root_crawler", "thorn_hound"], count=5,
         spawns=[("default", 200), ("from_forge", 200), ("from_town", 4800)],
         portals=[("ToForge", 60, "cold_forge", "from_root_road", "← เตาหลอมร้าง", "เตาหลอมร้าง"),
                  ("ToTown", 4940, "vanir_town", "from_road", "→ วานาเฮม", "วานาเฮม นครแห่งราก")]),
    dict(id="vanir_town", name="วานาเฮม นครแห่งราก", w=3800, h=1000, ground_y=880, enter_flag="chapter3_visited",
         colors=("0.2, 0.28, 0.24", "0.3, 0.42, 0.3", "0.38, 0.36, 0.26"),
         spawns=[("default", 300), ("from_road", 200), ("from_marsh", 3600)],
         portals=[("ToRoad", 60, "root_road", "from_town", "← ทางสายราก", "ทางสายราก"),
                  ("ToMarsh", 3740, "silver_marsh", "from_town", "→ บึงหมอกเงิน", "บึงหมอกเงิน")],
         npcs=[
             dict(node="Njorda", x=380, name="ผู้อาวุโสญอร์ดา", type=0, voice="njorda",
                  greeting="แขกจากใต้ภูเขา... นั่งก่อน รากไม่รีบ",
                  dialog="ที่นี่คือวานาเฮม นครแห่งราก\n\nเมื่อก่อนน้ำในบ่อกลางเมืองล้นจนไหลออกไปเลี้ยงทั้งโลก\nตอนนี้เหลือแค่ก้นบ่อ... และไม่มีใครถามว่าทำไม",
                  quests=["c3_1_open_gate", "c3_4_song_of_child", "c3_6_withering", "c3_10_flame_that_never_dies"],
                  by_flag={"saw_dry_spring": "น้ำไม่ได้แห้งเอง เจ้าก็เห็นแล้ว\n\nมันถูก «ดึง» ขึ้นไป... ไปทางที่ต้นไม้ยักษ์ยืนอยู่",
                           "chapter3_done": "เจ้าเห็นแล้วว่าใต้บ่อน้ำมีอะไร\n\nสงครามครั้งนั้นไม่ได้จบ... มันแค่เปลี่ยนจากดาบเป็นรูน\n\nไปเถอะ ทางเหนือยังมีคนที่ต้องรู้เรื่องนี้"}),
             dict(node="Eskil", x=900, name="นักบันทึกเอสกิล", type=0, voice="eskil",
                  greeting="ผู้จาริกจากมิดการ์ด จงขอบคุณธอร์ที่นำเจ้ามาไกลถึงนี่",
                  dialog="ข้าเอสกิล นักบันทึกแห่งวิหาร ถูกส่งมาเขียนพงศาวดารวานาเฮมฉบับสมบูรณ์\n\nประวัติศาสตร์ต้องมีฉบับเดียว ลูกเอ๋ย... ไม่งั้นผู้คนจะสับสน",
                  quests=["c3_5_marsh_of_soldiers", "c3_8_stake_burned_thrice"],
                  by_flag={"recorded_truth": "...เจ้าเขียนสิ่งที่ไม่มีใครอยากอ่านลงในสมุดของข้า\n\nข้าจะส่งมันไปวิหารตามหน้าที่ แต่จะไม่มีใครได้อ่านมันหรอก\n\nจงขอบคุณธอร์... ที่ยังปล่อยให้เจ้าพูด",
                           "recorded_aesir_version": "ดีมาก ประวัติศาสตร์ฉบับนี้จะสงบและเป็นระเบียบ\n\nจงขอบคุณธอร์ที่เจ้าเลือกถูก"}),
             dict(node="Sifa", x=1400, name="แม่ค้าซิฟา", type=1, shop=SIFA_SHOP, voice="sifa",
                  greeting="ของจากรากทั้งนั้น รับอะไรดี",
                  dialog="แม่ค้าประจำนคร ของทุกชิ้นปลูกเองเก็บเอง\n\nปีนี้เก็บได้น้อยลงอีก... ต้นไม้ให้ผลน้อยลงทุกปีตั้งแต่บ่อน้ำเริ่มแห้ง",
                  quests=["c3_3_mist_that_lingers"]),
             dict(node="Galla", x=1900, name="ช่างรากไม้กัลลา", type=2, socket=True, voice="galla",
                  greeting="วางของบนตอ แล้วอย่าคุยตอนข้าตี",
                  dialog="ช่างของนครนี้ตีเหล็กด้วยไฟจากรากไม้ ไม่ใช่ถ่านหิน\n\nไฟรากอ่อนลงทุกปี... เหมือนต้นไม้ไม่มีแรงจะลุก",
                  quests=["c3_7_sentinels_still_standing"]),
             dict(node="SavePoint", x=2350, name="เสาวาปแห่งราก", type=4, warp=["nidavellir_town", "prontera_town"],
                  dialog="เสาหินพันด้วยรากไม้ ลายเถาวัลย์เก่าแก่... แต่บนยอดมีตราค้อนสลักทับไว้ใหม่ ๆ"),
             dict(node="Leif", x=2800, name="หมอสมุนไพรลีฟ", type=3, heal=800, voice="leif",
                  greeting="แผลจากหนาม หรือแผลจากคน",
                  dialog="สมุนไพรที่นี่ยังใช้ได้ แต่ต้องเดินไปเก็บไกลขึ้นทุกปี\n\nของดี ๆ ตายจากด้านในก่อนเสมอ ลูกเอ๋ย"),
             dict(node="Arvid", x=3250, name="ทหารยามอาร์วิด", type=0, voice="arvid",
                  greeting="ประตูนี้ไม่ได้ปิดมาสามร้อยปีแล้ว ไม่รู้จะเปิดหรือปิดดี",
                  dialog="ข้ายามของนคร... ยามที่ไม่มีอะไรให้เฝ้า\n\nมอนในป่าไม่ได้บุกเข้ามา พวกมันหนีออกจากบางอย่างในป่าลึก เหมือนกันกับที่มิดการ์ดใช่ไหม",
                  quests=["c3_2_roots_in_town", "c3_9_thorn_matriarch"]),
             dict(node="Frida", x=3500, name="เด็กหญิงฟรีดา", type=0, voice="frida",
                  greeting="พี่ฟังเพลงเป็นไหม",
                  dialog="♪ น้ำล้นบ่อ รากเลื้อยไกล ♪\n♪ เทพจากเหนือ ขี่พายุมา ♪\n♪ ขอน้ำเรา แล้วเอาไป... ♪\n\nยายบอกว่าท่อนสุดท้ายห้ามร้องให้นักบวชได้ยิน",
                  by_flag={"saw_mural": "พี่ไปดูภาพวาดมาแล้วเหรอ\n\nในเพลงก็เป็นแบบนั้นแหละ... พายุมาจากทางเหนือ ไม่ได้มาจากในป่า",
                           "chapter3_done": "...หนูไม่ร้องเพลงนั้นแล้ว\n\nพี่ไปเถอะ ยายบอกว่าพี่ต้องไปทางเหนือ"}),
         ],
         lore=[dict(node="WarMural", x=650, id="war_mural", title="ภาพจิตรกรรมบนกำแพงราก",
                    text="ภาพจิตรกรรมเก่าบนกำแพงราก สีลอกไปครึ่งหนึ่ง\n\nกองทัพถือธงค้อนสายฟ้า เดินทัพ «เข้ามา» ทางประตูเหนือของนครนี้\nชาววานีร์ยืนมือเปล่าอยู่หน้าบ่อน้ำ\n\n...ในวิหารสอนว่าวานีร์เป็นฝ่ายบุกก่อน",
                    label="ภาพวาดเก่า", set="saw_mural")]),
    dict(id="silver_marsh", name="บึงหมอกเงิน", w=5200, h=1200, ground_y=900,
         colors=("0.5, 0.55, 0.58", "0.36, 0.42, 0.44", "0.24, 0.3, 0.26"),
         plats=[(800, 720, 320), (1700, 600, 300), (2600, 700, 380), (3500, 580, 300), (4400, 700, 340)],
         mons=["mist_sprite", "bog_lurker"], count=5,
         spawns=[("default", 200), ("from_town", 200), ("from_grove", 5000)],
         portals=[("ToTown", 60, "vanir_town", "from_marsh", "← วานาเฮม", "วานาเฮม นครแห่งราก"),
                  ("ToGrove", 5140, "withered_grove", "from_marsh", "→ ป่าเหี่ยว", "ป่าเหี่ยว")]),
    dict(id="withered_grove", name="ป่าเหี่ยว", w=5000, h=1200, ground_y=900,
         colors=("0.3, 0.28, 0.2", "0.36, 0.3, 0.18", "0.3, 0.26, 0.16"),
         plats=[(1000, 700, 360), (2200, 620, 320), (3400, 700, 360)],
         mons=["withered_treant", "vanir_sentinel"], count=4,
         spawns=[("default", 200), ("from_marsh", 200), ("from_field", 4800)],
         portals=[("ToMarsh", 60, "silver_marsh", "from_grove", "← บึงหมอกเงิน", "บึงหมอกเงิน"),
                  ("ToField", 4940, "forgotten_battlefield", "from_grove", "→ สมรภูมิที่ถูกลืม", "สมรภูมิที่ถูกลืม")],
         lore=[dict(node="DrySpring", x=2600, id="dry_spring_grove", title="ลำธารที่แห้งขอด",
                    text="ลำธารแห้งขอด ก้อนหินยังมีคราบน้ำสูงถึงเอว\n\nไม่ใช่แห้งเพราะแล้ง — ต้นไม้รอบ ๆ เหี่ยวจากข้างใน เหมือนถูก «ดึง» ชีวิตออกไป\n\nรากทุกเส้นชี้ไปทางเดียวกัน... ทางเหนือ ทางที่ต้นไม้ยักษ์ยืนอยู่",
                    label="ลำธารแห้ง", set="saw_dry_spring")]),
    dict(id="forgotten_battlefield", name="สมรภูมิที่ถูกลืม", w=5400, h=1200, ground_y=900,
         colors=("0.22, 0.2, 0.24", "0.3, 0.26, 0.3", "0.28, 0.24, 0.2"),
         plats=[(1100, 700, 360), (2300, 620, 320), (3500, 700, 360)],
         mons=["war_wraith"], count=6, boss=["thorn_matriarch"], boss_x=4700,
         spawns=[("default", 200), ("from_grove", 200), ("from_spring", 5200)],
         portals=[("ToGrove", 60, "withered_grove", "from_field", "← ป่าเหี่ยว", "ป่าเหี่ยว"),
                  ("ToSpring", 5340, "spring_of_life", "from_field", "→ บ่อน้ำแห่งชีวิต", "บ่อน้ำแห่งชีวิต",
                   "killed_thorn_matriarch", "ราชินีหนามยังขวางทางอยู่ — พงหนามหนาเกินกว่าจะฝ่าไป")],
         lore=[dict(node="BurntStake", x=1800, id="burnt_stake", title="เสาที่ถูกเผาสามครั้ง",
                    text="เสาไม้ดำเป็นถ่าน มีรอยไหม้ซ้อนกันสามชั้น สามครั้ง\n\nจารึกที่โคนเสาถูกขูดออก แต่ยังอ่านได้ลาง ๆ:\n«กุลล์ไวก์ ผู้ปฏิเสธจะมอบบ่อน้ำ — ถูกเผาสามครั้ง และสามครั้งนางลุกขึ้น»\n\n...ในวิหารบอกว่านางคือแม่มดที่ยุยงสงคราม",
                    label="เสาไหม้", set="read_burnt_stake"),
               dict(node="BuriedBanner", x=3000, id="buried_banner", title="ธงที่ถูกฝัง",
                    text="ธงผืนใหญ่ถูกฝังไว้ใต้ดินตื้น ๆ ตราค้อนสายฟ้าเลือนไปครึ่งหนึ่ง\n\nรอบ ๆ มีหมวกทหารเอซีร์ขึ้นสนิมกองอยู่หลายสิบใบ ทุกใบหันหน้าไป «ทางบ่อน้ำ»\n\nกองทัพที่บุกเข้ามา... ไม่ใช่กองทัพที่ป้องกัน",
                    label="ธงเก่า", set="read_buried_banner")]),
    dict(id="spring_of_life", name="บ่อน้ำแห่งชีวิต", w=3200, h=1100, ground_y=880,
         colors=("0.16, 0.22, 0.26", "0.22, 0.34, 0.3", "0.26, 0.3, 0.24"),
         boss=["gullveig_ember"], boss_x=2500,
         spawns=[("default", 200), ("from_field", 200)],
         portals=[("ToField", 60, "forgotten_battlefield", "from_spring", "← สมรภูมิที่ถูกลืม", "สมรภูมิที่ถูกลืม")],
         lore=[dict(node="SiphonRune", x=1500, id="siphon_rune", title="รูนใต้บ่อน้ำ",
                    text="ก้นบ่อน้ำแห้งเผยวงจรรูนขนาดใหญ่สลักบนหิน\n\nเส้นทุกเส้นไหล «เข้า» สู่ศูนย์กลาง แล้วพุ่งขึ้นไปทางเหนือเป็นสายเดียว\n\n...วงจรเดียวกับบนหัวค้อนที่กำแพงเตาหลอมร้าง\nรูน «ดูด» — ที่นี่ไม่ได้ดูดเหล็ก มันดูดชีวิตของทั้งโลก",
                    label="รูนบนหิน", flag="killed_gullveig_ember", locked="เปลวเพลิงยังลุกโชนอยู่กลางบ่อ เข้าใกล้ไม่ได้", set="saw_siphon_rune")]),
]

# =========================================================
# 6) เควสบท 3 (10 เควส · มีตัวเลือก 3 เควส · แพนกล้อง 1)
# =========================================================
K_KILL, K_COLLECT, K_TALK, K_VISIT, K_READ, K_FLAG = range(6)


def obj(kind, target, count=1, text="", consume=True):
    return dict(kind=kind, target=target, count=count, text=text, consume=consume)


def quest_tres(q):
    subs, refs = [], []
    for i, o in enumerate(q["objs"]):
        lines = ['[sub_resource type="Resource" id="Obj_%d"]' % i, 'script = ExtResource("2_obj")',
                 'kind = %d' % o["kind"], 'target = &"%s"' % o["target"], 'count = %d' % o["count"]]
        if o["text"]:
            lines.append('text = "%s"' % o["text"])
        if o["kind"] == K_COLLECT and not o["consume"]:
            lines.append('consume = false')
        subs.append("\n".join(lines))
        refs.append('SubResource("Obj_%d")' % i)
    body = ['script = ExtResource("1_quest")', 'id = &"%s"' % q["id"], 'title = "%s"' % q["title"],
            'description = "%s"' % q["desc"], 'giver_name = "%s"' % q["giver"],
            'dialog_offer = "%s"' % q["offer"], 'dialog_progress = "%s"' % q["progress"],
            'dialog_complete = "%s"' % q["complete"],
            'objectives = Array[ExtResource("2_obj")]([%s])' % ", ".join(refs),
            'kill_monster_id = &""', 'required_level = %d' % q.get("lv", 1)]
    if q.get("req"):
        body.append('required_quests = Array[StringName]([%s])' % ", ".join('&"%s"' % r for r in q["req"]))
    if q.get("req_flag"):
        body.append('required_flag = &"%s"' % q["req_flag"])
    if q.get("flag"):
        body.append('set_flag_on_complete = &"%s"' % q["flag"])
    if q.get("choice"):
        c = q["choice"]
        body += ['choice_prompt = "%s"' % c["prompt"],
                 'choice_options = Array[String]([%s])' % ", ".join('"%s"' % o for o in c["options"]),
                 'choice_flags = Array[StringName]([%s])' % ", ".join('&"%s"' % f for f in c["flags"])]
    if q.get("pan"):
        body += ['cutscene_pan_npc = "%s"' % q["pan"][0], 'cutscene_text = "%s"' % esc(q["pan"][1])]
    r = q.get("reward", {})
    if r.get("item"):
        body += ['reward_item_id = &"%s"' % r["item"][0], 'reward_item_count = %d' % r["item"][1]]
    body += ['reward_zeny = %d' % r.get("zeny", 0), 'reward_exp = %d' % r.get("exp", 0)]
    return '''[gd_resource type="Resource" script_class="QuestData" load_steps=%d format=3]

[ext_resource type="Script" path="res://scripts/resources/quest_data.gd" id="1_quest"]
[ext_resource type="Script" path="res://scripts/resources/objective_data.gd" id="2_obj"]

%s

[resource]
%s
''' % (3 + len(subs), "\n\n".join(subs), "\n".join(body))


QUESTS = [
    dict(id="c3_1_open_gate", title="C3-1 ประตูที่เปิดค้างไว้", giver="ผู้อาวุโสญอร์ดา", lv=38, req_flag="chapter2_done",
         desc="ทำความรู้จักผู้คนในวานาเฮม — ทหารยาม แม่ค้า และนักบันทึกจากวิหาร",
         offer="คนแคระส่งเจ้ามาสินะ... ประตูนครนี้เปิดค้างมาสามร้อยปี ไม่มีใครมา ไม่มีใครไป ไปทักทายผู้คนก่อนเถอะ — ยามอาร์วิด แม่ค้าซิฟา และ... นักบันทึกจากวิหารที่มาอยู่กับเราสองปีแล้ว",
         progress="อาร์วิดอยู่หน้าประตูตะวันออก ซิฟาอยู่กลางตลาด ส่วนเอสกิล... แกอยู่ตรงที่มองเห็นทุกคน",
         complete="เจ้าคุยกับเอสกิลแล้ว... แกบอกไหมว่าใครส่งแกมา ไม่บอกสินะ นี่ตราวานีร์ ถือไว้ นครนี้จะถือว่าเจ้าเป็นแขก ไม่ใช่ทหาร",
         objs=[obj(K_TALK, "ทหารยามอาร์วิด"), obj(K_TALK, "แม่ค้าซิฟา"), obj(K_TALK, "นักบันทึกเอสกิล")],
         flag="vanir_intro", reward=dict(item=("vanir_seal", 1), zeny=3000, exp=6000)),

    dict(id="c3_2_roots_in_town", title="C3-2 รากที่เลื้อยเข้าเมือง", giver="ทหารยามอาร์วิด", lv=38, req=["c3_1_open_gate"],
         desc="รากเลื้อยกับหมาป่าหนามล้นเข้ามาจนถึงกำแพงเมือง ไปตัดให้บางลงบนทางสายราก",
         offer="รากเลื้อยเลื้อยเข้ามาถึงกำแพงแล้ว หมาป่าหนามก็ตามมา... ไม่ได้บุกหรอก พวกมันหนีอะไรสักอย่างในป่าลึกมา ช่วยตัดให้บางลงที",
         progress="รากเลื้อย 15 หมาป่าหนาม 10 บนทางสายรากที่เจ้าเดินมานั่นแหละ",
         complete="เบาลงเยอะ... เจ้าสังเกตไหม พวกมันวิ่งมาจากทิศเดียวกันหมด ทิศตะวันออก — ทางบ่อน้ำ",
         objs=[obj(K_KILL, "root_crawler", 15), obj(K_KILL, "thorn_hound", 10)],
         reward=dict(item=("bark_armor", 1), zeny=6000, exp=12000)),

    dict(id="c3_3_mist_that_lingers", title="C3-3 หมอกที่ไม่จาง", giver="แม่ค้าซิฟา", lv=42, req=["c3_2_roots_in_town"],
         desc="บึงหมอกเงินมีหมอกหนาผิดปกติ ล่าภูตหมอกและเก็บแก่นหมอกมาให้ซิฟาทำยา",
         offer="หมอกในบึงไม่จางมาตั้งแต่ปีที่บ่อน้ำเริ่มแห้ง ข้าต้องการแก่นหมอกห้าก้อนมาทำยา... และช่วยไล่ภูตพวกนั้นให้ห่างจากคนเก็บสมุนไพรด้วย",
         progress="ภูตหมอก 12 ตัว แก่นหมอก 5 ก้อน ในบึงหมอกเงินทางตะวันออกของเมือง",
         complete="ขอบใจ... หมอกพวกนี้ไม่ใช่หมอกธรรมดา มันคือ «ลมหายใจ» ของบึงที่กำลังจะตาย — เอาผ้าคลุมนี้ไป ทอจากแก่นหมอกเหมือนกัน",
         objs=[obj(K_KILL, "mist_sprite", 12), obj(K_COLLECT, "mist_essence", 5)],
         reward=dict(item=("mist_cloak", 1), zeny=8000, exp=16000)),

    dict(id="c3_4_song_of_child", title="C3-4 บทเพลงที่เด็กร้อง", giver="ผู้อาวุโสญอร์ดา", lv=42, req=["c3_1_open_gate"],
         desc="ฟังเพลงของเด็กหญิงฟรีดา แล้วไปดูภาพจิตรกรรมบนกำแพงรากให้เห็นกับตา",
         offer="ฟรีดาร้องเพลงเก่าของนคร... ท่อนสุดท้ายยายของนางห้ามร้องให้นักบวชได้ยิน ไปฟังดู แล้วไปดูภาพวาดบนกำแพงรากท้ายตลาด — ภาพที่เอสกิลขอให้เราลบทิ้ง",
         progress="ฟรีดาอยู่หน้าประตูตะวันออก ภาพวาดอยู่บนกำแพงรากท้ายตลาด",
         complete="เห็นแล้วสินะ... กองทัพในภาพเดินเข้ามาทางประตูเหนือ ไม่ได้ป้องกันอะไรทั้งนั้น",
         objs=[obj(K_TALK, "เด็กหญิงฟรีดา", text="ฟังเพลงของฟรีดา"), obj(K_READ, "war_mural", text="ดูภาพจิตรกรรมบนกำแพงราก")],
         choice=dict(prompt="ญอร์ดามองเจ้านิ่ง ๆ — «ภาพนั้น... เจ้าคิดว่ายังไง»",
                     options=["จิตรกรคงวาดผิด วิหารสอนไว้ชัดเจน", "...ภาพนี้ต่างจากที่วิหารสอน"],
                     flags=["mural_dismissed", "mural_doubt"]),
         reward=dict(item=("frida_song", 1), zeny=4000, exp=14000)),

    dict(id="c3_5_marsh_of_soldiers", title="C3-5 บึงที่กลืนนักรบ", giver="นักบันทึกเอสกิล", lv=45, req=["c3_3_mist_that_lingers"],
         desc="เอสกิลต้องการหมวกทหารจากบึงหมอกเงินไปประกอบพงศาวดาร ล่าผีบึงและเก็บหมวกเอซีร์ขึ้นสนิมมาให้",
         offer="พงศาวดารต้องมีหลักฐาน ลูกเอ๋ย ในบึงมีหมวกทหารเอซีร์ที่ถูกวานีร์ซุ่มโจมตีเมื่อสามร้อยปีก่อน เอามาให้ข้าสามใบ ...แล้วกำจัดผีพวกนั้นด้วย มันคือทหารของเราที่ตายอย่างไม่สมเกียรติ",
         progress="ผีบึง 15 ตน หมวกเอซีร์ขึ้นสนิม 3 ใบ จากบึงหมอกเงิน",
         complete="ดี... หมวกพวกนี้จะบันทึกว่า «ทหารเอซีร์ผู้ถูกทรยศ» เท่านั้น ไม่ต้องถามว่าทำไมหมวกทุกใบหันหน้าไปทางบ่อน้ำ ข้าจะเก็บมันไว้เอง",
         objs=[obj(K_KILL, "bog_lurker", 15), obj(K_COLLECT, "aesir_helm_rusted", 3)],
         flag="gave_helms_to_eskil", reward=dict(zeny=10000, exp=20000)),

    dict(id="c3_6_withering", title="C3-6 ต้นไม้ที่เหี่ยวจากข้างใน", giver="ผู้อาวุโสญอร์ดา", lv=48, req=["c3_4_song_of_child", "c3_3_mist_that_lingers"],
         desc="ป่าเหี่ยวมีต้นไม้ที่ตายจากข้างใน ตัดต้นที่ยังเดินได้ แล้วไปดูลำธารที่แห้งขอด",
         offer="ต้นไม้ในป่าเหี่ยวลุกขึ้นเดินได้ทั้งที่ข้างในตายแล้ว... ไปตัดพวกที่อาละวาด แล้วไปดูลำธารกลางป่าให้เห็นกับตา ว่าน้ำมันหายไป «ทางไหน»",
         progress="ต้นไม้เหี่ยว 10 ต้น แล้วดูลำธารกลางป่าเหี่ยว",
         complete="รากทุกเส้นชี้ไปทางเหนือ... ทางต้นไม้ยักษ์ นั่นแหละที่ชีวิตของโลกนี้ถูกดึงไป ตั้งแต่วันที่กองทัพเดินเข้าประตู",
         objs=[obj(K_KILL, "withered_treant", 10), obj(K_READ, "dry_spring_grove", text="ดูลำธารที่แห้งขอด")],
         flag="saw_dry_spring", reward=dict(item=("spring_vial", 1), zeny=12000, exp=26000)),

    dict(id="c3_7_sentinels_still_standing", title="C3-7 ผู้พิทักษ์ที่ยังยืนอยู่", giver="ช่างรากไม้กัลลา", lv=50, req=["c3_6_withering"],
         desc="ผู้พิทักษ์หินในป่าเหี่ยวคลั่ง เก็บแกนผู้พิทักษ์มาให้กัลลาซ่อมเกราะ",
         offer="ผู้พิทักษ์วานีร์... บรรพบุรุษข้าสร้างพวกมันไว้เฝ้าบ่อน้ำ ไม่ใช่เฝ้ากันมอน — เฝ้ากัน «เทพ» ตอนนี้แกนมันเสื่อม คลั่งไปหมด เอาแกนมาให้ข้าสามก้อน ข้าจะทำเกราะให้เจ้า",
         progress="ผู้พิทักษ์วานีร์ 8 ตน แกนผู้พิทักษ์ 3 ก้อน ในป่าเหี่ยว",
         complete="แกนยังเรืองแสงเขียว... สามร้อยปีแล้วมันยังทำหน้าที่ นี่เกราะจากแผ่นหินของมัน ใส่แล้วจำไว้ว่ามันสร้างมาเพื่อยืนขวางใคร",
         objs=[obj(K_KILL, "vanir_sentinel", 8), obj(K_COLLECT, "sentinel_core", 3)],
         reward=dict(item=("sentinel_plate", 1), zeny=14000, exp=30000)),

    dict(id="c3_8_stake_burned_thrice", title="C3-8 เสาที่ถูกเผาสามครั้ง", giver="นักบันทึกเอสกิล", lv=53, req=["c3_5_marsh_of_soldiers", "c3_7_sentinels_still_standing"],
         desc="เอสกิลให้ไปกวาดล้างวิญญาณนักรบในสมรภูมิที่ถูกลืม และตรวจดูเสาไหม้กับธงเก่าที่นั่นเพื่อประกอบพงศาวดาร",
         offer="สมรภูมิเก่ายังมีวิญญาณทหารเอซีร์ที่ไม่ยอมไป กำจัดให้พวกเขาได้พัก... ระหว่างนั้นไปดูเสาไหม้กับธงที่ถูกฝัง แล้วกลับมาบอกข้าว่าเจ้าเห็นอะไร ข้าจะ «บันทึกให้ถูกต้อง»",
         progress="วิญญาณนักรบเอซีร์ 12 ตน แล้วดูเสาไหม้กับธงที่ถูกฝังในสมรภูมิที่ถูกลืม",
         complete="เจ้าเห็นเสาแล้ว... กุลล์ไวก์ แม่มดที่ยุยงสงคราม ถูกเผาสามครั้งเพราะความผิดของนาง — นั่นคือฉบับที่วิหารบันทึก ทีนี้บอกข้า เจ้าจะให้ข้าเขียนแบบไหน",
         objs=[obj(K_KILL, "war_wraith", 12), obj(K_READ, "burnt_stake", text="ดูเสาที่ถูกเผาสามครั้ง"), obj(K_READ, "buried_banner", text="ดูธงที่ถูกฝัง")],
         choice=dict(prompt="เอสกิลเปิดสมุดพงศาวดาร ปากกาลอยอยู่เหนือหน้ากระดาษ — «วานาเฮม ปีแห่งสงคราม... ฝ่ายใดเริ่ม»",
                     options=["บันทึกว่าวานีร์เป็นฝ่ายเริ่ม (ตามวิหาร)", "บันทึกตามที่ข้าเห็น — เอซีร์เดินทัพเข้ามา"],
                     flags=["recorded_aesir_version", "recorded_truth"]),
         reward=dict(item=("eskil_chronicle", 1), zeny=16000, exp=36000)),

    dict(id="c3_9_thorn_matriarch", title="C3-9 ราชินีหนาม", giver="ทหารยามอาร์วิด", lv=55, req=["c3_8_stake_burned_thrice"],
         desc="ราชินีหนามขวางทางไปบ่อน้ำแห่งชีวิต ล้มนางเพื่อเปิดทาง",
         offer="ทางไปบ่อน้ำถูกพงหนามปิดตาย ราชินีหนามอยู่ในนั้น... นางปกป้องบ่อน้ำมาก่อนจะมีเทพองค์ไหน แต่ตอนนี้นางไม่แยกมิตรกับศัตรูแล้ว เจ้าต้องล้มนาง ข้าเสียใจ",
         progress="ราชินีหนามอยู่สุดทางตะวันออกของสมรภูมิที่ถูกลืม ระวังหนามทะลวงพื้น — กระโดดข้าม",
         complete="...นางล้มแล้ว ข้าได้ยินเสียงพงหนามถอนตัวจากที่นี่ เอาโล่นี้ไป สานจากหนามของนาง ให้นางได้ปกป้องเจ้าต่อ",
         objs=[obj(K_KILL, "thorn_matriarch", 1)],
         reward=dict(item=("thorn_shield", 1), zeny=20000, exp=45000)),

    dict(id="c3_10_flame_that_never_dies", title="C3-10 เพลิงที่ไม่มอด", giver="ผู้อาวุโสญอร์ดา", lv=58, req=["c3_9_thorn_matriarch"],
         desc="ดับเพลิงกุลล์ไวก์กลางบ่อน้ำแห่งชีวิต แล้วดูสิ่งที่ซ่อนอยู่ใต้ก้นบ่อ",
         offer="กลางบ่อน้ำมีเพลิงที่ลุกมาสามร้อยปี... กุลล์ไวก์ ผู้ปฏิเสธจะมอบบ่อน้ำ ถูกเผาสามครั้ง และสามครั้งนางลุกขึ้น ตอนนี้นางเหลือแค่เปลวไฟ ดับนางเถอะ แล้วดูว่าใต้เปลวไฟนั้น พวกเขาซ่อนอะไรไว้",
         progress="เพลิงกุลล์ไวก์อยู่กลางบ่อน้ำแห่งชีวิต ผ่านสมรภูมิที่ถูกลืมไปทางตะวันออก — นางปล่อยเพลิงสามระลอก กระโดดข้ามหรือพุ่งหลบ",
         complete="รูน «ดูด»... เหมือนที่คนแคระเห็นบนหัวค้อน ที่นี่มันไม่ได้ดูดเหล็ก ลูกเอ๋ย มันดูดชีวิตของทั้งโลกส่งขึ้นไปทางเหนือ... สามร้อยปีแล้ว",
         objs=[obj(K_KILL, "gullveig_ember", 1), obj(K_READ, "siphon_rune", text="ดูรูนใต้ก้นบ่อน้ำ")],
         choice=dict(prompt="ญอร์ดา: «เจ้าเห็นแล้วว่าใครดึงชีวิตจากโลกนี้... เจ้าจะเล่าให้คนที่มิดการ์ดฟังไหม»",
                     options=["ข้าจะบอกทุกคน", "...ยังไม่ใช่ตอนนี้ ยังไม่มีใครเชื่อ"],
                     flags=["will_tell_truth", "kept_silent_ch3"]),
         pan=("เด็กหญิงฟรีดา", "เสียงเพลงที่เคยได้ยินทุกวันเงียบไป\n\nเด็กหญิงฟรีดายืนอยู่หน้าประตู มองไปทางเหนือ\n\n...ทางที่รากทุกเส้นชี้ไป"),
         flag="chapter3_done", reward=dict(item=("gullveig_ash", 1), zeny=40000, exp=90000)),
]


# =========================================================
# 7) ไอคอน/ภาพชั่วคราว
# =========================================================
def make_icons():
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        return
    os.makedirs(ICON_DIR, exist_ok=True)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 26)
    except Exception:
        font = ImageFont.load_default()
    n = 0
    for item_id, code, color in ICON_JOBS:
        p = os.path.join(ICON_DIR, item_id + ".png")
        if os.path.exists(p):
            continue
        im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.rounded_rectangle((3, 3, 60, 60), radius=12, fill=color, outline=(20, 16, 12, 255), width=3)
        d.rounded_rectangle((9, 9, 54, 26), radius=8, fill=(255, 255, 255, 60))
        bbox = d.textbbox((0, 0), code, font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        d.text(((64 - tw) / 2 - bbox[0], (64 - th) / 2 - bbox[1] + 2), code, font=font,
               fill=(255, 255, 255, 255), stroke_width=2, stroke_fill=(20, 16, 12, 255))
        im.save(p)
        n += 1
    if n:
        LOG.append("สร้างไอคอนชั่วคราว %d รูปใน %s" % (n, ICON_DIR))


# =========================================================
# ทำงาน
# =========================================================
def main():
    print("[1] ไอเทมขยะ %d · ของเควส %d · ของสวมใส่ %d" % (len(JUNK), len(QUEST_ITEMS), len(EQUIP)))
    for j in JUNK:
        w("data/items/%s.tres" % j[0], junk_tres(j[0], j[1], j[2], j[3]))
    for qi in QUEST_ITEMS:
        w("data/items/%s.tres" % qi[0], quest_item_tres(*qi))
    for e in EQUIP:
        w("data/items/%s.tres" % e["id"], equip_tres(e))

    print("[2] เอฟเฟกต์คลื่นไฟ/หนาม")
    w("data/sprites/fx_fire_wave.tres", wave_frames_tres("fire_wave"))
    w("data/sprites/fx_thorn_wave.tres", wave_frames_tres("thorn_wave"))

    print("[3] มอนบท 3 %d ตัว" % len(MON))
    for m in MON:
        monster_png(m)
        w("data/sprites/monsters/%s_frames.tres" % m["id"], frames_tres(m))
        w("data/monsters/%s.tres" % m["id"], monster_tres(m))
        ICON_JOBS.append(("card_" + m["id"], "C" + m["code"][0], COLOR["card"]))
        w("data/cards/card_%s.tres" % m["id"], card_tres(m))

    print("[4] แมพบท 3 %d แมพ" % len(MAPS))
    for mp in MAPS:
        w("scenes/maps/%s.tscn" % mp["id"], map_tscn(mp))

    print("[5] เควสบท 3 %d เควส" % len(QUESTS))
    for q in QUESTS:
        w("data/quests/%s.tres" % q["id"], quest_tres(q))

    print("[6] ต่อสาย — ประตูจากเตาหลอมร้าง · เสาวาป · ทะเบียนแมพ")
    patch("scenes/maps/cold_forge.tscn", [
        ('[node name="from_hall" type="Marker2D" parent="SpawnPoints"]\nposition = Vector2(200, 820)\n',
         '[node name="from_hall" type="Marker2D" parent="SpawnPoints"]\nposition = Vector2(200, 820)\n\n'
         '[node name="from_root_road" type="Marker2D" parent="SpawnPoints"]\nposition = Vector2(2800, 820)\n'),
        ('[node name="ToHall" parent="Portals" instance=ExtResource("portal")]\n',
         '[node name="ToRootRoad" parent="Portals" instance=ExtResource("portal")]\n'
         'position = Vector2(2940, 880)\ntarget_map = &"root_road"\ntarget_spawn_point = &"from_forge"\n'
         'label_text = "→ ทางสายราก"\ndestination_name = "ทางสายราก (บทที่ 3)"\n'
         'required_flag = &"chapter2_done"\nlocked_text = "หลังกำแพงแบบร่างมีรอยแยก... รากไม้เลื้อยออกมาจากข้างใน แต่ยังไม่มีเหตุผลจะเข้าไป"\n\n'
         '[node name="ToHall" parent="Portals" instance=ExtResource("portal")]\n'),
    ], markers=('name="from_root_road"', 'name="ToRootRoad"'))
    patch("scenes/maps/nidavellir_town.tscn", [
        ('warp_targets = Array[StringName]([&"asgard_forest_2"])',
         'warp_targets = Array[StringName]([&"asgard_forest_2", &"vanir_town"])\nwarp_flags = {\n"vanir_town": "chapter3_visited"\n}'),
    ], markers=('&"vanir_town"',))
    # เสาวาปพรอนเทราไม่มีบรรทัด warp_targets ในฉาก (ใช้ค่าเริ่มต้น) → แทรกต่อจากบรรทัด dialog ของเสา
    patch("scenes/maps/prontera_town.tscn", [
        ('dialog = "เสาวาปโบราณ · เลือกปลายทางแล้วก้าวเข้าไปได้เลย"\n',
         'dialog = "เสาวาปโบราณ · เลือกปลายทางแล้วก้าวเข้าไปได้เลย"\n'
         'warp_targets = Array[StringName]([&"asgard_forest_2", &"vanir_town"])\nwarp_flags = {\n"vanir_town": "chapter3_visited"\n}\n'),
    ], markers=('&"vanir_town"',))
    patch("scripts/core/game.gd", [
        ('	&"dark_forest_2": "res://scenes/maps/dark_forest_2.tscn",\n}',
         '	&"dark_forest_2": "res://scenes/maps/dark_forest_2.tscn",\n'
         '	## ★ บทที่ 3 — วานาเฮม (รอบ 79) ★\n'
         '	&"root_road": "res://scenes/maps/root_road.tscn",\n'
         '	&"vanir_town": "res://scenes/maps/vanir_town.tscn",\n'
         '	&"silver_marsh": "res://scenes/maps/silver_marsh.tscn",\n'
         '	&"withered_grove": "res://scenes/maps/withered_grove.tscn",\n'
         '	&"forgotten_battlefield": "res://scenes/maps/forgotten_battlefield.tscn",\n'
         '	&"spring_of_life": "res://scenes/maps/spring_of_life.tscn",\n}'),
        ('	&"cold_forge": "เตาหลอมเย็น",\n}',
         '	&"cold_forge": "เตาหลอมเย็น",\n'
         '	&"root_road": "ทางสายราก",\n'
         '	&"vanir_town": "วานาเฮม นครแห่งราก",\n'
         '	&"silver_marsh": "บึงหมอกเงิน",\n'
         '	&"withered_grove": "ป่าเหี่ยว",\n'
         '	&"forgotten_battlefield": "สมรภูมิที่ถูกลืม",\n'
         '	&"spring_of_life": "บ่อน้ำแห่งชีวิต",\n}'),
        ('const TOWNS := [&"prontera_town", &"nidavellir_town"]',
         'const TOWNS := [&"prontera_town", &"nidavellir_town", &"vanir_town"]'),
    ], markers=('&"vanir_town": "res://', '&"vanir_town": "วานาเฮม', '&"vanir_town"]'))

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
