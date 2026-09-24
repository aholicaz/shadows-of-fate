#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""★ รอบ 181 ★ Ninth Edge ชุดสกิลใหม่ + เอาเงื่อนไขรูนออก (Runeblade + Ninth Edge)
ใช้: python3 patch_r181.py <โฟลเดอร์โปรเจกต์>
- idempotent: ไฟล์ที่มี marker «รอบ 181» แล้วจะข้าม · สำรอง <ไฟล์>_ก่อนรอบ181.bak ก่อนแก้
- รักษา CRLF ของไฟล์เดิม
"""
import os, re, sys, shutil

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
MARK = "รอบ 181"
log = []

def load(rel):
    p = os.path.join(ROOT, rel)
    raw = open(p, "rb").read().decode("utf-8")
    crlf = "\r\n" in raw
    return p, raw.replace("\r\n", "\n"), crlf

def save(p, text, crlf, original):
    bak = re.sub(r"(\.[^.]+)$", r"_ก่อนรอบ181\1.bak", p)
    if not os.path.exists(bak):
        shutil.copyfile(p, bak)
    out = text.replace("\n", "\r\n") if crlf else text
    open(p, "wb").write(out.encode("utf-8"))

def rep(text, old, new, rel, count=1):
    n = text.count(old)
    if n < 1:
        raise SystemExit("ไม่พบข้อความใน %s:\n%s" % (rel, old[:200]))
    if count and n != count:
        raise SystemExit("พบ %d ครั้ง (คาด %d) ใน %s:\n%s" % (n, count, rel, old[:200]))
    return text.replace(old, new)

def patch(rel, fn, marker=MARK):
    p, text, crlf = load(rel)
    if marker in text:
        log.append("ข้าม (ทำแล้ว) " + rel)
        return
    new = fn(text, rel)
    save(p, new, crlf, text)
    log.append("แก้ " + rel)

# ---------------------------------------------------------------- runeblade_combat.gd
def f_combat(t, rel):
    t = rep(t, "var named_marks: Dictionary = {}\n",
        "var named_marks: Dictionary = {}\n"
        "# ★ รอบ 181 ★ ไม่ต้องมีรูนก่อนใช้สกิลแล้ว — รูนที่สะสม = โบนัสดาเมจท่าใหญ่ ดวงละ +10% ใช้เองอัตโนมัติ · ไม่หายเองเมื่อหยุดตี\n"
        "const RUNE_SPENDERS := [&\"worldcleaver\", &\"erasing_cut\", &\"ninefold_cyclone\", &\"ninth_inscription\"]\n"
        "const RUNE_BONUS := 0.10\n"
        "var ninth: Node2D   ## ชุดสกิล Ninth Edge ใหม่ (ninth_edge_skills.gd)\n", rel)
    t = rep(t, "\tif source != &\"erasing_cut\": return 1.0\n",
        "\tif source not in [&\"erasing_cut\", &\"ninth_inscription\"]: return 1.0\n", rel)
    t = rep(t, "\tif source == &\"erasing_cut\":\n\t\tif int(named_marks",
        "\tif source in [&\"erasing_cut\", &\"ninth_inscription\"]:\n\t\tif int(named_marks", rel)
    t = rep(t, "\tif source not in [&\"basic\", &\"basic_finisher\"] or PlayerState.skills.level_of(&\"named_edge\") <= 0: return\n",
        "\tif source not in [&\"basic\", &\"basic_finisher\", &\"erasing_step\", &\"oathchain\", &\"ninefold_cyclone\"] or PlayerState.skills.level_of(&\"named_edge\") <= 0: return\n", rel)
    t = rep(t, "\tlayer.add_child(hud)\n",
        "\tlayer.add_child(hud)\n"
        "\t# ★ รอบ 181 ★ ชุดสกิล Ninth Edge ใหม่ · จังหวะคมดาบเลิกสะสมชั้น\n"
        "\tninth = preload(\"res://scripts/entities/ninth_edge_skills.gd\").new()\n"
        "\tadd_child(ninth)\n"
        "\tninth.setup(self)\n"
        "\tPlayerState.active_buffs.erase(&\"rb_rhythm\")\n"
        "\tcall_deferred(\"_migrate_r181\")\n", rel)
    t = rep(t, "\tif not PlayerState.is_rune_job() or source in [&\"rune_echo\", &\"twin_echo\", &\"element_burn\", &\"element_chain\"]: return\n",
        "\tif not PlayerState.is_rune_job() or source in [&\"rune_echo\", &\"twin_echo\", &\"mirror_echo\", &\"element_burn\", &\"element_chain\"]: return\n", rel)
    t = rep(t, "\t\tif PlayerState.skills.level_of(&\"blade_rhythm\") > 0:\n\t\t\trhythm = mini(5,rhythm+1)\n\t\t\t_rhythm_buff()\n",
        "\t\t# ★ รอบ 181 ★ จังหวะคมดาบเป็นพาสซีฟ ASPD ติดตัวแล้ว (ไม่สะสมชั้น ไม่มีตัวนับบนจอ)\n", rel)
    t = rep(t, "\telif source not in [&\"worldcleaver\", &\"unbroken_edge\", &\"faultline\", &\"erasing_cut\", &\"twin_inscription\", &\"ninth_inscription\"] and charged_cast != cast_serial:\n",
        "\telif source not in [&\"worldcleaver\", &\"unbroken_edge\", &\"faultline\", &\"erasing_cut\", &\"twin_inscription\", &\"ninth_inscription\", &\"ninefold_cyclone\"] and charged_cast != cast_serial:\n", rel)
    t = rep(t, "\tcharge_lock = 0.2\n\n",
        "\tcharge_lock = 0.2\n\n"
        "## ★ รอบ 181 ★ ท่าใหญ่ใช้รูนที่มีทั้งหมดเป็นโบนัส (ไม่มีรูนก็กดได้ปกติ)\n"
        "func spend_runes(id: StringName) -> float:\n"
        "\tif id not in RUNE_SPENDERS or charges <= 0: return 1.0\n"
        "\tvar mult := 1.0 + RUNE_BONUS * charges\n"
        "\tEvents.floating_text(player.global_position + Vector2(0,-170), \"รูน ×%d  +%d%%\" % [charges, roundi(RUNE_BONUS * charges * 100.0)], Color(\"#9fd4ff\"), 18, 0)\n"
        "\tcharges = 0\n"
        "\treturn mult\n\n"
        "func refund_rune() -> void:\n"
        "\tcharges = mini(max_charges(), charges + 1)\n\n"
        "## ★ รอบ 181 ★ อ่านรอยพันธะรวมเข้าคมยืนยันนาม — คืนแต้มที่เคยลงไว้\n"
        "func _migrate_r181() -> void:\n"
        "\tif PlayerState.skills == null or PlayerState.stats == null: return\n"
        "\tvar lv := PlayerState.skills.level_of(&\"wallbreaker_stance\")\n"
        "\tif lv <= 0: return\n"
        "\tPlayerState.stats.add_skill_points(&\"ninth_edge\", lv)\n"
        "\tPlayerState.skills.learned.erase(&\"wallbreaker_stance\")\n"
        "\tPlayerState.refresh()\n"
        "\tEvents.skills_changed.emit()\n"
        "\tEvents.say(\"อ่านรอยพันธะรวมเข้ากับคมยืนยันนามแล้ว — คืนแต้มสกิล %d แต้ม\" % lv)\n\n", rel)
    t = rep(t, "\tif idle > 10:\n\t\tdecay += delta\n\t\tif decay >= 3:\n\t\t\tcharges = maxi(0,charges-1)\n\t\t\tdecay = 0\n\telse: decay = 0\n",
        "\t# ★ รอบ 181 ★ รูนไม่ลดเองเมื่อหยุดตีแล้ว\n", rel)
    t = rep(t,
        "\thud.text = \"รูน  %s%s   จังหวะ %d/5%s%s\" % [\"◆\".repeat(charges),\"◇\".repeat(max_charges()-charges),rhythm,\"   โล่ %d\"%shield if shield>0 else \"\",\n"
        "\t\t(\"   อักขระคู่ %.1f\" % twin_time if twin_time > 0 else \"\") + (\"   ★ อักขระที่เก้า %.1f\" % inscription_time if inscription_time > 0 else \"\")]\n",
        "\t# ★ รอบ 181 ★ แถบเดียว: รูน (= โบนัสท่าใหญ่ถัดไป) · โล่ · ร่างเงา\n"
        "\thud.text = \"รูน  %s%s%s%s\" % [\"◆\".repeat(charges),\"◇\".repeat(max_charges()-charges),\n"
        "\t\t(\"   ท่าใหญ่ถัดไป +%d%%\" % roundi(charges * RUNE_BONUS * 100.0)) if charges > 0 else \"\", \"   โล่ %d\"%shield if shield>0 else \"\"]\n"
        "\tif is_instance_valid(ninth) and ninth.shade_time > 0.0: hud.text += \"   ร่างเงา %.1f\" % ninth.shade_time\n", rel)
    t = rep(t, "\tif casting or not PlayerState.is_rune_job(): return\n\tvar check := PlayerState.can_use_skill(id)\n",
        "\tif casting or not PlayerState.is_rune_job(): return\n"
        "\t# ★ รอบ 181 ★ ก้าวลบเงากดซ้ำฟรีภายใน 1.2 วิ (คูลดาวน์เริ่มไปแล้ว)\n"
        "\tif is_instance_valid(ninth) and ninth.can_recast(id):\n"
        "\t\tninth.cast(id, GameData.get_skill(id), PlayerState.skills.level_of(id), 1.0, true)\n"
        "\t\treturn\n"
        "\tvar check := PlayerState.can_use_skill(id)\n", rel)
    t = rep(t,
        "\t# ★ รอบ 105 ★ ค่ารูนของแต่ละสกิล: อัลติเมต 3 · อักขระคู่ 2 · ฟันลบนาม 3 · อักขระที่เก้า 4\n"
        "\tvar rune_cost: int = {&\"unbroken_edge\": 3, &\"worldcleaver\": 3, &\"twin_inscription\": 2, &\"erasing_cut\": 3, &\"ninth_inscription\": 4}.get(id, 0)\n"
        "\tvar ultimate := rune_cost > 0\n"
        "\tif ultimate and charges < rune_cost:\n"
        "\t\tEvents.say(\"ต้องมีตรารูนครบ %d ดวง\" % rune_cost)\n"
        "\t\treturn\n"
        "\tvar s := GameData.get_skill(id)\n"
        "\tvar lv := PlayerState.skills.level_of(id)\n",
        "\t# ★ รอบ 181 ★ เลิกเงื่อนไข «ต้องมีรูนครบ» — ทุกสกิลกดได้ทันที ใช้แค่ SP + คูลดาวน์ (รูน = โบนัส)\n"
        "\tvar s := GameData.get_skill(id)\n"
        "\tvar lv := PlayerState.skills.level_of(id)\n"
        "\tif is_instance_valid(ninth) and ninth.handles(id):\n"
        "\t\tif not PlayerState.commit_skill_use(id): return\n"
        "\t\tninth.cast(id, s, lv, spend_runes(id))\n"
        "\t\treturn\n"
        "\tvar rune_mult := 1.0\n", rel)
    t = rep(t, "\t\tplayer._play_support_sfx(id, \"buff\")\n\t\tcharges = 0\n\t\tedge_time = 8\n",
        "\t\tplayer._play_support_sfx(id, \"buff\")\n\t\tedge_time = 8\n", rel)
    # อักขระคู่ / อักขระที่เก้าแบบเก่า → ไปอยู่ใน ninth_edge_skills.gd แล้ว
    i0 = t.index("\t# ★ รอบ 105 ★ อักขระคู่ — 6 วิ")
    i1 = t.index("\tcasting = true\n\tplayer.is_attacking = true\n")
    t = t[:i0] + "\t# ★ รอบ 181 ★ อักขระคู่ / อักขระที่เก้าแบบเดิม ย้ายไปเป็น ร่างเงาสะท้อน / พิพากษานามที่เก้า (ninth_edge_skills.gd)\n" + t[i1:]
    t = rep(t, "\t\tcharges = 0\n\t\tcommitted_heavy = true\n",
        "\t\trune_mult = spend_runes(id)\n\t\tcommitted_heavy = true\n", rel)
    t = rep(t, "\t\tfield.configure(self, id, s.damage_mult(lv), center, dir)\n",
        "\t\tfield.configure(self, id, s.damage_mult(lv) * rune_mult, center, dir)\n", rel)
    t = rep(t, "\tif id == &\"erasing_cut\": charges -= 3   # ★ รอบ 105 ★ ฟันลบนาม ใช้ 3 รูน ฟันหนักครั้งเดียว ลบโล่/บัฟของมอน\n", "", rel)
    t = rep(t, "func strike(id: StringName, mult: float, reach: float, cap: int, dir: int) -> void:\n",
        "func strike(id: StringName, mult: float, reach: float, cap: int, dir: int) -> Array:   # ★ รอบ 181 ★ คืนรายชื่อที่โดน\n", rel)
    t = rep(t, "\tvar hit := 0\n\tfor enemy in enemies:\n", "\tvar hit := 0\n\tvar hit_list: Array = []\n\tfor enemy in enemies:\n", rel)
    t = rep(t, "\t\thit += 1\n\t\tif hit >= cap: break\n", "\t\thit += 1\n\t\thit_list.append(enemy)\n\t\tif hit >= cap: break\n\treturn hit_list\n", rel)
    return t

# ---------------------------------------------------------------- player.gd
def f_player(t, rel):
    return rep(t, "\t\tif runeblade != null and runeblade.approach_left > 0.0:\n\t\t\trunebl" "ade.approach_step(delta)\n\t\t\treturn\n",
        "\t\tif runeblade != null and runeblade.approach_left > 0.0:\n\t\t\truneblade.approach_step(delta)\n\t\t\treturn\n"
        "\t\t# ★ รอบ 181 ★ กงจักรนามเก้า — เดินได้ระหว่างหมุน / กดหลบยกเลิก\n"
        "\t\tif runeblade != null and is_instance_valid(runeblade.ninth) and runeblade.ninth.drive(delta):\n"
        "\t\t\treturn\n", rel)

# ---------------------------------------------------------------- monster_base.gd
def f_monster(t, rel):
    t = rep(t, "\tvar wb := PlayerState.skills.level_of(&\"wallbreaker_stance\")\n",
        "\t# ★ รอบ 181 ★ อ่านรอยพันธะรวมเข้าคมยืนยันนาม (ใช้ระดับที่สูงกว่า ไม่ทบกัน)\n"
        "\tvar wb := maxi(PlayerState.skills.level_of(&\"wallbreaker_stance\"), PlayerState.skills.level_of(&\"named_edge\"))\n", rel)
    t = rep(t, "\tif state == State.ATTACK or state == State.HURT:\n\t\tvelocity.x = move_toward",
        "\t# ★ รอบ 181 ★ โดนโซ่พันธะ (Ninth Edge) — ยืนนิ่งช่วงสั้น ไม่เดิน ไม่เริ่มท่าใหม่ (บอสไม่โดน)\n"
        "\tif Time.get_ticks_msec() < int(get_meta(\"rb_stun_until\", 0)):\n"
        "\t\tvelocity.x = move_toward(velocity.x, 0.0, data.move_speed * 4.0 * delta)\n"
        "\t\tmove_and_slide()\n"
        "\t\treturn\n\n"
        "\tif state == State.ATTACK or state == State.HURT:\n\t\tvelocity.x = move_toward", rel)
    return t

# ---------------------------------------------------------------- skill_book.gd
def f_book(t, rel):
    t = rep(t, "const NINTH_SKILLS := [&\"ninth_vessel\",&\"named_edge\",",
        "## ★ รอบ 181 ★ เพิ่ม ก้าวลบเงา · โซ่พันธะ · กงจักรนามเก้า (อ่านรอยพันธะยังอยู่ในรายการเพื่อคืนแต้มเซฟเก่า)\n"
        "const NINTH_SKILLS := [&\"ninth_vessel\",&\"named_edge\",&\"erasing_step\",&\"oathchain\",&\"ninefold_cyclone\",", rel)
    t = rep(t, "\t&\"ninth_vessel\",&\"named_edge\",&\"twin_inscription\"",
        "\t&\"ninth_vessel\",&\"named_edge\",&\"erasing_step\",&\"oathchain\",&\"ninefold_cyclone\",&\"twin_inscription\"", rel)
    return t

# ---------------------------------------------------------------- skill_window.gd
def f_window(t, rel):
    t = rep(t, "\t\t\t&\"blade_rhythm\": stats_lines.append(\"ASPD +%.1f%% ต่อชั้น · สูงสุด 5 ชั้น\"%(lv*0.6))\n",
        "\t\t\t&\"blade_rhythm\": stats_lines.append(\"ASPD +%.1f%% ติดตัวตลอด\"%(lv*2.5))   # ★ รอบ 181 ★\n", rel)
    t = rep(t, "\t\t\t&\"unbroken_edge\": stats_lines.append(\"ใช้ 3 ตรา · ASPD +%d%% · 8 วินาที\"%(lv*5))\n",
        "\t\t\t&\"unbroken_edge\": stats_lines.append(\"ASPD +%d%% · 8 วินาที\"%(lv*5))\n", rel)
    t = rep(t, "\t\t\t&\"named_edge\": stats_lines.append(\"โอกาสคริ +%d จุดเปอร์เซ็นต์ · มองข้าม DEF %d%%\"%[lv*3,lv*6])\n",
        "\t\t\t&\"named_edge\": stats_lines.append(\"โอกาสคริ +%d จุด · มองข้าม DEF %d%%\\nดาเมจเพิ่มตาม DEF ศัตรู สูงสุด +%d%% · ตรานามครบ 3 ชั้น +%d%%\"%[lv*2,lv*4,lv*4,lv*8])\n"
        "\t\t\t&\"erasing_step\": stats_lines.append(\"ฟันผ่าน %.0f%% + รอยแผลระเบิด %.0f%% ATK\\nกดซ้ำได้ใน 1.2 วิ (แรง 60%%) · อมตะ 0.25 วิ\"%[s.damage_mult(lv)*100,(3.8+0.8*(lv-1))*100])\n"
        "\t\t\t&\"oathchain\": stats_lines.append(\"ดึง + ฟัน %.0f%% ATK · สตัน 0.8 วิ\\nระยะโซ่ 800 · ดึงรอบเป้า 320\"%(s.damage_mult(lv)*100))\n"
        "\t\t\t&\"ninefold_cyclone\": stats_lines.append(\"9 ครั้ง × %.0f%% + ปิดท้าย %.0f%% ATK\\nเดินได้ 80%% ระหว่างหมุน · กดหลบยกเลิกได้\"%[(1.1+0.2*(lv-1))*100,(4.0+1.0*(lv-1))*100])\n"
        "\t\t\t&\"erasing_cut\": stats_lines.append(\"พุ่ง 260 แล้วฟัน %.0f%% ATK ระยะ 560\\nฆ่าได้คืนรูน 1 ดวง\"%(s.damage_mult(lv)*100))\n", rel)
    t = rep(t, "\t\t\t&\"twin_inscription\": stats_lines.append(\"ใช้ 2 ตรา · เงาดาบ %.0f%% ATK · 6 วินาที\"%((0.45+0.05*lv)*100))\n",
        "\t\t\t&\"twin_inscription\": stats_lines.append(\"ร่างเงา 10 วินาที · ทำท่าตาม %.0f%%\"%((0.35+0.05*lv)*100))\n", rel)
    t = rep(t, "\t\t\t&\"ninth_inscription\": stats_lines.append(\"ใช้ 4 ตรา · วงสลัก 3 วินาที\\nระเบิด %.0f%% ATK\"%((20.0+2.0*(lv-1))*100))\n",
        "\t\t\t&\"ninth_inscription\": stats_lines.append(\"วาร์ปฟัน 9 × %.0f%% + ระเบิด %.0f%% ATK\\nอมตะตลอดท่า\"%[(2.6+0.3*(lv-1))*100,(18.0+2.5*(lv-1))*100])\n", rel)
    t = rep(t, "\tif s.id in SkillBook.RUNE_SKILLS:\n\t\tstats_lines.clear()\n",
        "\tif s.id in SkillBook.RUNE_SKILLS:\n\t\tstats_lines.clear()\n"
        "\t\tif s.id in [&\"worldcleaver\", &\"erasing_cut\", &\"ninefold_cyclone\", &\"ninth_inscription\"]:\n"
        "\t\t\tlines.append(\"[color=#9fd4ff]ใช้รูนที่สะสมไว้เป็นโบนัส +10%/ดวง (ไม่มีรูนก็ใช้ได้)[/color]\")\n", rel)
    return t

def f_tree(t, rel):
    return rep(t,
        "\t&\"ninth_vessel\":Vector2(0,0), &\"named_edge\":Vector2(1,0), &\"wallbreaker_stance\":Vector2(2,0),\n"
        "\t&\"twin_inscription\":Vector2(0,1), &\"erasing_cut\":Vector2(1,1), &\"ninth_inscription\":Vector2(1,2)\n",
        "\t# ★ รอบ 181 ★ ชุด Ninth Edge ใหม่\n"
        "\t&\"ninth_vessel\":Vector2(0,0), &\"named_edge\":Vector2(1,0), &\"erasing_step\":Vector2(2,0),\n"
        "\t&\"oathchain\":Vector2(0,1), &\"ninefold_cyclone\":Vector2(1,1), &\"erasing_cut\":Vector2(2,1),\n"
        "\t&\"twin_inscription\":Vector2(0,2), &\"ninth_inscription\":Vector2(1,2)\n", rel)

def f_objective(t, rel):
    return rep(t, "\t\"ninth\": [&\"erasing_cut\", &\"ninth_inscription\", &\"twin_inscription\", &\"twin_echo\"],\n",
        "\t\"ninth\": [&\"erasing_cut\", &\"ninth_inscription\", &\"twin_inscription\", &\"twin_echo\", &\"erasing_step\", &\"oathchain\", &\"ninefold_cyclone\", &\"mirror_echo\"],   # ★ รอบ 181 ★\n", rel)

def f_rbtest(t, rel):
    return rep(t,
        "\tplayer.runeblade.cast(&\"worldcleaver\")\n\tcheck(PlayerState.stats.sp==sp and PlayerState.skill_cooldown_left(&\"worldcleaver\")==0,\"ultimate with no runes spends nothing\")\n",
        "\t# ★ รอบ 181 ★ ไม่ต้องมีรูนแล้ว — ท่าใหญ่กดได้ทันที (รูน = โบนัส)\n"
        "\tplayer.runeblade.cast(&\"worldcleaver\")\n"
        "\tawait get_tree().create_timer(0.5).timeout\n"
        "\tcheck(PlayerState.stats.sp<sp and PlayerState.skill_cooldown_left(&\"worldcleaver\")>0,\"ultimate casts without runes (round 181)\")\n"
        "\twhile player.runeblade.casting: await get_tree().physics_frame\n"
        "\tawait get_tree().create_timer(2.4).timeout   # ให้ฝนดาบ 5 ระลอกตกจบก่อนเทสต์ท่าถัดไป\n", rel)

# ---------------------------------------------------------------- data/*.tres
def tres_set(t, key, value, rel):
    pat = re.compile(r"^%s = .*$" % re.escape(key), re.M)
    if not pat.search(t):
        raise SystemExit("ไม่มีช่อง %s ใน %s" % (key, rel))
    return pat.sub(lambda m: "%s = %s" % (key, value), t, count=1)

def q(s): return '"' + s + '"'

def f_job(t, rel):
    t = rep(t, "&\"wallbreaker_stance\", ", "", rel)
    t = rep(t, "&\"named_edge\", ", "&\"named_edge\", &\"erasing_step\", &\"oathchain\", &\"ninefold_cyclone\", ", rel)
    return "; ★ รอบ 181 ★ ชุดสกิล Ninth Edge ใหม่\n" + t if False else t

def tres_patch(rel, fields, extra_after=None):
    def fn(t, r):
        for k, v in fields.items():
            t = tres_set(t, k, v, r)
        if extra_after:
            anchor, add = extra_after
            t = rep(t, anchor, anchor + add, r)
        return t
    p, text, crlf = load(rel)
    new = fn(text, rel)
    if new == text:
        log.append("ข้าม (ทำแล้ว) " + rel)
        return
    save(p, new, crlf, text)
    log.append("แก้ " + rel)

def main():
    patch("scripts/entities/runeblade_combat.gd", f_combat)
    patch("scripts/entities/player.gd", f_player)
    patch("scripts/entities/monster_base.gd", f_monster)
    patch("scripts/core/skill_book.gd", f_book)
    patch("scripts/ui/skill_window.gd", f_window)
    patch("scripts/ui/skill_tree_canvas.gd", f_tree)
    patch("scripts/resources/objective_data.gd", f_objective)
    if os.path.exists(os.path.join(ROOT, "runeblade_test.gd")): patch("runeblade_test.gd", f_rbtest)
    # job: skill list (ไม่มีคอมเมนต์ใน .tres — เช็กด้วยชื่อสกิลใหม่)
    p, text, crlf = load("data/jobs/ninth_edge.tres")
    if "erasing_step" in text:
        log.append("ข้าม (ทำแล้ว) data/jobs/ninth_edge.tres")
    else:
        save(p, f_job(text, "ninth_edge.tres"), crlf, text)
        log.append("แก้ data/jobs/ninth_edge.tres")
    tres_patch("data/skills/blade_rhythm.tres", {
        "description": q("พาสซีฟ · ASPD +2.5% ต่อระดับ ติดตัวตลอด (ไม่ต้องสะสมชั้นแล้ว)")},
        None)
    p, text, crlf = load("data/skills/blade_rhythm.tres")
    if "passive_effects" not in text:
        text2 = rep(text, "required_skills = {\"rune_flurry\": 1}\n", "required_skills = {\"rune_flurry\": 1}\npassive_effects = {\"aspd_percent\": 2.5}\n", "blade_rhythm.tres")
        save(p, text2, crlf, text)
        log.append("แก้ blade_rhythm passive_effects")
    tres_patch("data/skills/unbroken_edge.tres", {
        "description": q("เพิ่ม ASPD 5–50% นาน 8 วิ ตีปกติครบ 3 ครั้งมีเงาดาบ 80% ATK · กดได้ทันทีไม่ต้องใช้รูน")})
    tres_patch("data/skills/worldcleaver.tres", {
        "description": q("เรียกฝนดาบ 5 ระลอก รวม 1400–2750% ATK รัศมี 520 px สูงสุด 12 ตัวต่อระลอก ไม่คริ เตรียม 0.7 วิ ยกเลิกด้วยหลบใน 0.35 วิแรกได้ · ใช้รูนที่สะสมไว้เป็นโบนัส +10%/ดวง"),
        "sp_cost_base": "44", "cooldown": "22.0"})
    tres_patch("data/skills/named_edge.tres", {
        "description": q("คริ +2 จุดและเจาะ DEF 4% ต่อระดับ · ดาเมจกายภาพเพิ่มตามเกราะศัตรู DEF ทุก 100 เพิ่ม 2% ต่อระดับ สูงสุด 4% ต่อระดับ (รวมอ่านรอยพันธะเดิม) · ตีธรรมดา ก้าวลบเงา โซ่พันธะ กงจักรนามเก้า ติดตรานาม 8 วินาที ครบ 3 ชั้น คมตัดพันธะและพิพากษานามที่เก้าใช้ตราเพิ่มดาเมจ 8–40%")})
    tres_patch("data/skills/erasing_cut.tres", {
        "description": q("พุ่งเข้าหาเป้า 260 แล้วฟันเสี้ยวจันทร์ระยะ 560 สูงสุด 8 ตัว · 1000–1600% ATK ไม่คริ · เปิดแผลรับดาเมจกายภาพ +15% นาน 5 วินาที · เป้ามีตรานามครบ 3 ชั้น +8–40% · ฆ่าได้คืนรูน 1 ดวง · ใช้รูนที่สะสมไว้เป็นโบนัส +10%/ดวง")})
    tres_patch("data/skills/twin_inscription.tres", {
        "display_name": q("ร่างเงาสะท้อน"),
        "description": q("วางร่างเงาไว้ที่จุดยืน 10 วินาที · ทุกครั้งที่ใช้ ก้าวลบเงา / โซ่พันธะ / กงจักรนามเก้า / คมตัดพันธะ ร่างเงาจะฟันตามไปทางตัวเรา 40–60% ของท่านั้น · ยืนอีกฝั่งของฝูงเพื่อตีขนาบ · ไม่ทำท่าอัลติตาม"),
        "cooldown": "20.0"})
    tres_patch("data/skills/ninth_inscription.tres", {
        "display_name": q("พิพากษานามที่เก้า"),
        "description": q("อัลติ · วาร์ปฟันไล่เป้าในระยะ 900 รวม 9 ครั้ง ครั้งละ 260–380% ATK แล้วระเบิดรัศมี 500 1800–2800% ATK · อมตะตลอดท่า · ใช้รูนที่สะสมไว้เป็นโบนัส +10%/ดวง"),
        "type": "1", "cooldown": "40.0", "required_skills": '{"ninefold_cyclone": 1}'})
    print("\n".join(log))

main()
