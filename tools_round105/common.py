# -*- coding: utf-8 -*-
## ★★ รอบ 105 — ตัวช่วยร่วมของบท 4-6 ★★  (ต่อยอดจาก gen_round79.py)
##   w()     สร้างไฟล์เฉพาะที่ยังไม่มี (ไม่ทับของที่ผู้ใช้แก้แล้ว)
##   patch() แก้ไฟล์เดิมเฉพาะจุด เช็คก่อนทุกครั้ง + สำรอง *_ก่อนรอบ105.bak
##   *_tres  สร้างไฟล์ข้อมูล: ไอเทม · มอน · การ์ด · เควส · สกิล · แมพ (.tscn)
import os, shutil

LOG = []
TAG = "รอบ105"


def w(path, text, overwrite=False):
    if os.path.exists(path) and not overwrite:
        return False
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    open(path, "w", encoding="utf-8", newline="\n").write(text)
    LOG.append("สร้าง " + path)
    return True


def backup(path, tag=TAG):
    base, ext = os.path.splitext(path)
    bak = "%s_ก่อน%s%s.bak" % (base, tag, ext)
    if not os.path.exists(bak):
        shutil.copy(path, bak)


def patch(path, pairs, tag=TAG, markers=()):
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
    "skill": (120, 80, 40, 255), "junk4": (110, 130, 160, 255), "junk5": (180, 170, 90, 255), "junk6": (80, 90, 120, 255),
}


def icon_line(item_id):
    return '[ext_resource type="Texture2D" path="res://%s/%s.png" id="2_icon"]' % (ICON_DIR, item_id)


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


# =========================================================
# ไอเทม
# =========================================================
def junk_tres(item_id, name, desc, sell, tint="junk"):
    ICON_JOBS.append((item_id, "".join(x[0] for x in item_id.split("_"))[:2].upper(), COLOR[tint]))
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
''' % (ITEM_SCRIPT, icon_line(item_id), item_id, name, esc(desc), sell * 3, sell)


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
''' % (ITEM_SCRIPT, icon_line(item_id), item_id, name, esc(desc))


def equip_tres(e):
    lines = [
        '[gd_resource type="Resource" script_class="ItemData" load_steps=3 format=3]', '',
        ITEM_SCRIPT, icon_line(e["id"]), '', '[resource]', 'script = ExtResource("1_item")',
        'id = &"%s"' % e["id"], 'display_name = "%s"' % e["name"], 'description = "%s"' % esc(e["desc"]),
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
    if e.get("pct"):
        lines.append("percent_effects = {\n%s\n}" % ",\n".join('"%s": %.1f' % (k, v) for k, v in e["pct"].items()))
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


# =========================================================
# มอนสเตอร์
# =========================================================
# element: NEUTRAL0 FIRE1 WATER2 EARTH3 WIND4 POISON5 HOLY6 SHADOW7 GHOST8 UNDEAD9
# race: FORMLESS0 UNDEAD1 BRUTE2 PLANT3 INSECT4 FISH5 DEMON6 DEMIHUMAN7 ANGEL8 DRAGON9 · size S0 M1 L2 · ai PASSIVE0 AGGR1 STAT2
def monster_tres(m, junk_list):
    junks = [j for j in junk_list if j[4] == m["id"]]
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
    if m.get("card"):
        subs.append('[sub_resource type="Resource" id="Drop_%s_card"]\nscript = ExtResource("2_drop")\nitem_id = &"card_%s"\nchance = %.1f\n'
                    % (m["id"], m["id"], 2.0 if m.get("boss") else 0.5))
        refs.append('SubResource("Drop_%s_card")' % m["id"])

    frames_path = m.get("frames_path", "res://data/sprites/monsters/%s_frames.tres" % m["id"])
    ext = ['[ext_resource type="Script" path="res://scripts/resources/monster_data.gd" id="1_monster"]',
           '[ext_resource type="Script" path="res://scripts/resources/drop_entry.gd" id="2_drop"]',
           '[ext_resource type="SpriteFrames" path="%s" id="3_frames"]' % frames_path]
    ai = m["ai"]
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
        'element = %d' % m["el"], 'race = %d' % m["race"], 'size = %d' % m["size"], 'ai_type = %d' % ai,
        'move_speed = %.1f' % m["spd"],
        'jump_force = %.1f' % m.get("jump", -280),
        'jump_while_chasing = %s' % ("true" if m.get("jump") else "false"),
        'detect_range = %.1f' % (m.get("detect", 460 if ai == 1 else (620 if ai == 2 else 260))),
        'attack_range = %.1f' % m.get("range", 70 + m["hb"][0]),
        'leash_range = 800.0', 'wander_range = %.1f' % (0.0 if ai == 2 else 260.0),
        'hop_while_wandering = %s' % ("true" if m.get("jump") else "false"),
        'attack_windup = 0.4', 'attack_duration = 0.5', 'attack_cooldown = %.1f' % m.get("atk_cd", 1.8),
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
        body += ['skill_name = "%s"' % v["name"], 'skill_anim = &"%s"' % v.get("anim", "Skill"), 'skill_range = 600.0',
                 'skill_damage_mult = %.1f' % v["mult"], 'skill_windup = 0.5', 'skill_duration = 1.3',
                 'skill_cooldown = %.1f' % v["cd"], 'skill_chance = %.2f' % v["chance"], 'skill_knockback = 360.0',
                 'skill_wave_count = %d' % v["count"], 'skill_wave_both_sides = %s' % ("true" if v["both"] else "false"),
                 'skill_wave_speed = %.1f' % v["speed"], 'skill_wave_range = %.1f' % v["rng"],
                 'skill_wave_delay = %.2f' % v["delay"], 'skill_wave_height = %.1f' % v["height"],
                 'skill_wave_frames = ExtResource("4_wave")']
    # ★ รอบ 105 ★ เงื่อนไขพิเศษ
    if m.get("tint"):
        body.append('tint = Color(%s)' % m["tint"])
    if m.get("calm_flag"):
        body.append('calm_if_flag = &"%s"' % m["calm_flag"])
    if m.get("calm_item"):
        body.append('calm_if_item = &"%s"' % m["calm_item"])
    if m.get("lines"):
        body.append('spawn_lines = PackedStringArray(%s)' % ", ".join('"%s"' % esc(t) for t in m["lines"]))
    if m.get("death_lines"):
        body.append('death_lines = PackedStringArray(%s)' % ", ".join('"%s"' % esc(t) for t in m["death_lines"]))
    return '[gd_resource type="Resource" script_class="MonsterData" load_steps=%d format=3]\n\n%s\n\n%s\n[resource]\n%s\n' % (
        len(ext) + len(subs) + 1, "\n".join(ext), "\n".join(subs), "\n".join(body))


def frames_tres(m):
    """SpriteFrames ชั่วคราว 6 ท่า — วาดจริงแล้ววางภาพใน Sprites/monster/<id>/ แล้วรัน make_monster_frames.py <id> --force"""
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
        'monster_id = &"%s"' % m["id"], 'fits_slot = %d' % c["slot"], 'rarity = %d' % c["r"], 'monster_level = %d' % m["lv"],
        'id = &"card_%s"' % m["id"], 'display_name = "การ์ด%s"' % m["name"],
        'description = "%s"' % esc(c["txt"]), 'icon = ExtResource("2_icon")', 'type = 5', 'slot = 0', 'max_stack = 99',
        'buy_price = 0', 'sell_price = %d' % (m["lv"] * 1500),
    ]
    for k in ["atk", "matk", "flee", "hit", "crit", "max_hp", "max_sp", "mdef", "bonus_str", "bonus_agi", "bonus_vit", "bonus_int", "bonus_dex", "bonus_luk"]:
        if c.get(k):
            lines.append("%s = %d" % (k, c[k]))
    if c.get("def"):
        lines.append("def = %d" % c["def"])
    if c.get("pct"):
        lines.append("percent_effects = {\n%s\n}" % ",\n".join('"%s": %.1f' % (k, v) for k, v in c["pct"].items()))
    return "\n".join(lines) + "\n"


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
# สกิล (Ninth Edge)
# =========================================================
def skill_tres(s):
    ICON_JOBS.append(("skill_" + s["id"], s.get("code", s["id"][:2].upper()), COLOR["skill"]))
    lines = [
        '[gd_resource type="Resource" script_class="SkillData" load_steps=3 format=3]',
        '[ext_resource type="Script" path="res://scripts/resources/skill_data.gd" id="s"]',
        '[ext_resource type="Texture2D" path="res://%s/skill_%s.png" id="i"]' % (ICON_DIR, s["id"]),
        '[resource]', 'script = ExtResource("s")',
        'id = &"%s"' % s["id"], 'display_name = "%s"' % s["name"], 'description = "%s"' % esc(s["desc"]),
        'icon = ExtResource("i")', 'max_level = %d' % s.get("max", 5),
        'job_ids = Array[StringName]([%s])' % ", ".join('&"%s"' % j for j in s["jobs"]),
        'required_level = %d' % s["lv"], 'type = %d' % s["type"],
        'sp_cost_base = %d' % s.get("sp", 0), 'sp_cost_per_level = 0.0', 'cooldown = %.1f' % s.get("cd", 0.0),
        'damage_mult_base = %.2f' % s.get("mult", 0.0), 'damage_mult_per_level = %.2f' % s.get("mult_lv", 0.0),
        'required_skills = {%s}' % ", ".join('"%s": %d' % (k, v) for k, v in s.get("req", {}).items()),
    ]
    if s.get("passive"):
        lines.append('passive_effects = {%s}' % ", ".join('"%s": %.1f' % (k, v) for k, v in s["passive"].items()))
    if s.get("targets"):
        lines.append('max_targets = %d' % s["targets"])
    if s.get("range"):
        lines.append('range_x = %.1f' % s["range"])
    return "\n".join(lines) + "\n"


# =========================================================
# เควส
# =========================================================
K_KILL, K_COLLECT, K_TALK, K_VISIT, K_READ, K_FLAG, K_SKILL_HIT = 0, 1, 2, 3, 4, 5, 6


def obj(kind, target, count=1, text="", consume=True):
    return {"kind": kind, "target": target, "count": count, "text": text, "consume": consume}


def quest_tres(q):
    subs, refs = [], []
    for i, o in enumerate(q["objs"]):
        lines = ['[sub_resource type="Resource" id="Obj_%d"]' % i, 'script = ExtResource("2_obj")',
                 'kind = %d' % o["kind"], 'target = &"%s"' % o["target"], 'count = %d' % o["count"]]
        if o["text"]:
            lines.append('text = "%s"' % esc(o["text"]))
        if o["kind"] == K_COLLECT and not o["consume"]:
            lines.append('consume = false')
        subs.append("\n".join(lines))
        refs.append('SubResource("Obj_%d")' % i)
    body = ['script = ExtResource("1_quest")', 'id = &"%s"' % q["id"], 'title = "%s"' % q["title"],
            'description = "%s"' % esc(q["desc"]), 'giver_name = "%s"' % q["giver"],
            'dialog_offer = "%s"' % esc(q["offer"]), 'dialog_progress = "%s"' % esc(q["progress"]),
            'dialog_complete = "%s"' % esc(q["complete"]),
            'objectives = Array[ExtResource("2_obj")]([%s])' % ", ".join(refs),
            'kill_monster_id = &""', 'required_level = %d' % q.get("lv", 1)]
    if q.get("job"):
        body.append('required_job = &"%s"' % q["job"])
    if q.get("reward_job"):
        body.append('reward_job = &"%s"' % q["reward_job"])
        body.append('reward_job_map = &"%s"' % q.get("reward_job_map", ""))
    if q.get("req"):
        body.append('required_quests = Array[StringName]([%s])' % ", ".join('&"%s"' % r for r in q["req"]))
    if q.get("req_flag"):
        body.append('required_flag = &"%s"' % q["req_flag"])
    if q.get("flag"):
        body.append('set_flag_on_complete = &"%s"' % q["flag"])
    if q.get("choice"):
        c = q["choice"]
        body += ['choice_prompt = "%s"' % esc(c["prompt"]),
                 'choice_options = Array[String]([%s])' % ", ".join('"%s"' % esc(o) for o in c["options"]),
                 'choice_flags = Array[StringName]([%s])' % ", ".join('&"%s"' % f for f in c["flags"])]
    if q.get("pan"):
        body += ['cutscene_pan_npc = "%s"' % q["pan"][0], 'cutscene_text = "%s"' % esc(q["pan"][1])]
    r = q.get("reward", {})
    if r.get("item"):
        body += ['reward_item_id = &"%s"' % r["item"][0], 'reward_item_count = %d' % r["item"][1]]
    body += ['reward_zeny = %d' % r.get("zeny", 0), 'reward_exp = %d' % r.get("exp", 0)]
    if r.get("jexp"):
        body.append('reward_job_exp = %d' % r["jexp"])
    return '''[gd_resource type="Resource" script_class="QuestData" load_steps=%d format=3]

[ext_resource type="Script" path="res://scripts/resources/quest_data.gd" id="1_quest"]
[ext_resource type="Script" path="res://scripts/resources/objective_data.gd" id="2_obj"]

%s

[resource]
%s
''' % (3 + len(subs), "\n\n".join(subs), "\n".join(body))


# =========================================================
# แมพ (พื้นราบ ไม่มีแพลตฟอร์ม — เกมไม่มีกระโดดแล้ว)
# =========================================================
def _grp(g):
    return ' groups=["%s"]' % g if g else ""


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
    spawners = list(mp.get("spawners", []))
    if mp.get("mons"):
        spawners.insert(0, dict(mons=mp["mons"], count=mp.get("count", 4)))
    bosses = []
    for b in mp.get("boss", []):
        bosses.append(b if isinstance(b, dict) else dict(id=b, x=mp.get("boss_x", 2600)))
    mon_ids = []
    for sp in spawners:
        for mid in sp["mons"]:
            if mid not in mon_ids:
                mon_ids.append(mid)
    for b in bosses:
        if b["id"] not in mon_ids:
            mon_ids.append(b["id"])
    for mid in mon_ids:
        ext.append('[ext_resource type="Resource" path="res://data/monsters/%s.tres" id="md_%s"]' % (mid, mid))
    W, H = mp["w"], mp["h"]
    gy = mp["ground_y"]
    sky, far, gnd = mp["colors"]
    subs = ['[sub_resource type="RectangleShape2D" id="Rect_ground"]\nsize = Vector2(%d, 240)' % (W + 400)]
    head = ('[node name="Map" type="Node2D"]\nscript = ExtResource("map_base")\nmap_id = &"%s"\ndisplay_name = "%s"\nchapter = %d\nregion = "%s"\nmap_bounds = Rect2(-100, -200, %d, %d)\nplayer_scene = ExtResource("player")'
            % (mp["id"], mp["name"], mp["chapter"], mp["region"], W + 200, H + 200))
    if mp.get("enter_flag"):
        head += '\nenter_flag = &"%s"' % mp["enter_flag"]
    if mp.get("variant_flag"):
        head += '\nvariant_flag = &"%s"' % mp["variant_flag"]
    if mp.get("variant_always"):
        head += '\nvariant_always = true'
    if mp.get("variant_tint"):
        vt = mp["variant_tint"]
        if vt.count(",") == 2:
            vt += ", 1"
        head += '\nvariant_tint = Color(%s)' % vt
    if mp.get("variant_suffix"):
        head += '\nvariant_name_suffix = "%s"' % mp["variant_suffix"]
    nodes = [
        head,
        '[node name="Background" type="Node2D" parent="."]',
        '[node name="Sky" type="Polygon2D" parent="Background"]\nz_index = -100\nposition = Vector2(-100, -200)\ncolor = Color(%s, 1)\npolygon = PackedVector2Array(0, 0, %d, 0, %d, %d, 0, %d)'
        % (sky, W + 200, W + 200, H + 200, H + 200),
        '[node name="FarLayer" type="Polygon2D" parent="Background"]\nz_index = -90\nposition = Vector2(-100, %d)\ncolor = Color(%s, 1)\npolygon = PackedVector2Array(0, 0, %d, 0, %d, %d, 0, %d)'
        % (gy - 360, far, W + 200, W + 200, 360, 360),
    ]
    # ก้อนฉากหลังเพิ่มเติม (กำแพง/ซาก/เสา) — (name, x, y, w, h, color)
    for i, (bn, bx, by, bw, bh, bc) in enumerate(mp.get("props", [])):
        nodes.append('[node name="%s" type="Polygon2D" parent="Background"]\nz_index = -80\nposition = Vector2(%d, %d)\ncolor = Color(%s, 1)\npolygon = PackedVector2Array(0, 0, %d, 0, %d, %d, 0, %d)'
                     % (bn, bx, by, bc, bw, bw, bh, bh))
    nodes += [
        '[node name="Terrain" type="Node2D" parent="."]',
        '[node name="Ground" type="StaticBody2D" parent="Terrain"]\nposition = Vector2(%d, %d)\ncollision_layer = 1\ncollision_mask = 0' % (W // 2, gy + 120),
        '[node name="Shape" type="CollisionShape2D" parent="Terrain/Ground"]\nshape = SubResource("Rect_ground")',
        '[node name="Visual" type="Polygon2D" parent="Terrain/Ground"]\ncolor = Color(%s, 1)\npolygon = PackedVector2Array(%d, -120, %d, -120, %d, 120, %d, 120)'
        % (gnd, -(W + 400) // 2, (W + 400) // 2, (W + 400) // 2, -(W + 400) // 2),
    ]
    nodes.append('[node name="SpawnPoints" type="Node2D" parent="."]')
    for sp_name, sx in mp["spawns"]:
        nodes.append('[node name="%s" type="Marker2D" parent="SpawnPoints"]\nposition = Vector2(%d, %d)' % (sp_name, sx, gy - 60))
    nodes.append('[node name="Spawners" type="Node2D" parent="."]')
    for i, sp in enumerate(spawners):
        nodes.append('[node name="%s" type="Node2D" parent="Spawners"%s]\nscript = ExtResource("map_spawner")\nmonster_types = Array[ExtResource("monster_data")]([%s])\ncount_per_type = %d\nmonster_scene = ExtResource("monster_scene")\nmax_spawn_distance = 1700.0'
                     % (sp.get("name", "MapSpawner" if i == 0 else "MapSpawner%d" % (i + 1)), _grp(sp.get("group")),
                        ", ".join('ExtResource("md_%s")' % m for m in sp["mons"]), sp.get("count", 4)))
    for b in bosses:
        nodes.append('[node name="Boss_%s" type="Node2D" parent="Spawners"%s]\nposition = Vector2(%d, %d)\nscript = ExtResource("spawner")\nmonster_types = Array[ExtResource("monster_data")]([ExtResource("md_%s")])\nmonster_scene = ExtResource("monster_scene")\nmax_alive = 1\nspawn_width = 160'
                     % (b["id"], _grp(b.get("group")), b["x"], gy - 30, b["id"]))
    nodes.append('[node name="Portals" type="Node2D" parent="."]')
    for p in mp["portals"]:
        pname, px, tmap, tsp, label, dest = p[:6]
        extra = ""
        if len(p) > 6 and p[6]:
            extra = '\nrequired_flag = &"%s"\nlocked_text = "%s"' % (p[6], esc(p[7]))
        nodes.append('[node name="%s" parent="Portals" instance=ExtResource("portal")]\nposition = Vector2(%d, %d)\ntarget_map = &"%s"\ntarget_spawn_point = &"%s"\nlabel_text = "%s"\ndestination_name = "%s"%s'
                     % (pname, px, gy, tmap, tsp, label, dest, extra))
    if mp.get("npcs"):
        nodes.append('[node name="NPCs" type="Node2D" parent="."]')
        for n in mp["npcs"]:
            extra = ""
            if n.get("hidden"):
                extra += '\nvisible = false'
            if n.get("alpha"):
                extra += '\nmodulate = Color(1, 1, 1, %.2f)' % n["alpha"]
            if n.get("shop"):
                extra += '\nhas_shop = true' if n["type"] != 1 else ""
                extra += '\nshop_items = Array[StringName]([%s])' % ", ".join('&"%s"' % s for s in n["shop"])
            if n.get("heal"):
                extra += '\nheal_price = %d' % n["heal"]
            if n.get("socket"):
                extra += '\nhas_socket = true'
            if n.get("refine"):
                extra += '\nhas_refine = true'
            if n.get("warp"):
                extra += '\nwarp_targets = Array[StringName]([%s])' % ", ".join('&"%s"' % s for s in n["warp"])
            if n.get("greeting"):
                extra += '\ngreeting = "%s"' % esc(n["greeting"])
            if n.get("voice"):
                extra += '\nvoice_id = "%s"' % n["voice"]
            if n.get("quests"):
                extra += '\nquest_ids = Array[StringName]([%s])' % ", ".join('&"%s"' % q for q in n["quests"])
            if n.get("talk_names"):
                extra += '\nquest_talk_names = Array[StringName]([%s])' % ", ".join('&"%s"' % q for q in n["talk_names"])
            if n.get("show_if"):
                extra += '\nshow_if_flag = &"%s"' % n["show_if"]
            if n.get("hide_if"):
                extra += '\nhide_if_flag = &"%s"' % n["hide_if"]
            if n.get("by_flag"):
                extra += '\ndialog_by_flag = {\n%s\n}' % ",\n".join('"%s": "%s"' % (k, esc(v)) for k, v in n["by_flag"].items())
            nodes.append('[node name="%s" parent="NPCs" instance=ExtResource("npc")%s]\nposition = Vector2(%d, %d)\nnpc_name = "%s"\ntype = %d\ndialog = "%s"%s'
                         % (n["node"], _grp(n.get("group")), n["x"], gy - 60, n["name"], n["type"], esc(n["dialog"]), extra))
    if mp.get("lore"):
        nodes.append('[node name="Lore" type="Node2D" parent="."]')
        for l in mp["lore"]:
            extra = ""
            if l.get("hidden"):
                extra += '\nvisible = false'
            if l.get("flag"):
                extra += '\nrequired_flag = &"%s"\nlocked_text = "%s"' % (l["flag"], esc(l["locked"]))
            if l.get("set"):
                extra += '\nset_flag = &"%s"' % l["set"]
            if l.get("give"):
                extra += '\ngive_item = &"%s"' % l["give"]
            if l.get("again"):
                extra += '\ntext_again = "%s"' % esc(l["again"])
            if l.get("auto"):
                extra += '\nauto_read = true'
            nodes.append('[node name="%s" parent="Lore" instance=ExtResource("lore")%s]\nposition = Vector2(%d, %d)\nlore_id = &"%s"\ntitle = "%s"\ntext = "%s"\nlabel_text = "%s"%s'
                         % (l["node"], _grp(l.get("group")), l["x"], gy - 90, l["id"], l["title"], esc(l["text"]), l.get("label", ""), extra))
    return '[gd_scene load_steps=%d format=3]\n\n%s\n\n%s\n\n%s\n' % (
        len(ext) + len(subs) + 1, "\n".join(ext), "\n\n".join(subs), "\n\n".join(nodes))


# =========================================================
# ไอคอนชั่วคราว
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


def build_chapter(ch):
    """สร้างไฟล์ทั้งหมดของบทเดียว — ch คือโมดูล ch4/ch5/ch6 ที่มี JUNK · QUEST_ITEMS · EQUIP · MON · MAPS · QUESTS (+ SKILLS)"""
    for j in ch.JUNK:
        w("data/items/%s.tres" % j[0], junk_tres(j[0], j[1], j[2], j[3], getattr(ch, "JUNK_TINT", "junk")))
    for qi in ch.QUEST_ITEMS:
        w("data/items/%s.tres" % qi[0], quest_item_tres(*qi))
    for e in ch.EQUIP:
        w("data/items/%s.tres" % e["id"], equip_tres(e))
    for m in ch.MON:
        if not m.get("frames_path"):
            monster_png(m)
            w("data/sprites/monsters/%s_frames.tres" % m["id"], frames_tres(m))
        w("data/monsters/%s.tres" % m["id"], monster_tres(m, ch.JUNK))
        if m.get("card"):
            ICON_JOBS.append(("card_" + m["id"], "C" + m["code"][0], COLOR["card"]))
            w("data/cards/card_%s.tres" % m["id"], card_tres(m))
    for mp in ch.MAPS:
        w("scenes/maps/%s.tscn" % mp["id"], map_tscn(mp))
    for q in ch.QUESTS:
        w("data/quests/%s.tres" % q["id"], quest_tres(q))
    for s in getattr(ch, "SKILLS", []):
        w("data/skills/%s.tres" % s["id"], skill_tres(s))
