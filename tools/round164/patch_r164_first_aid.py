# รอบ 164 — First Aid → พาสซีฟ «ยาฟื้นฟูแรงขึ้น 5% ต่อเลเวล» (สูงสุด Lv10 = +50%) · idempotent · สำรอง _ก่อนรอบ164
import os, shutil, sys, re
os.chdir(sys.argv[1] if len(sys.argv) > 1 else ".")
MARK = "★ รอบ 164 ★"

def rw(p):
    raw = open(p, encoding="utf-8", newline="").read()
    return raw, "\r\n" in raw, raw.replace("\r\n", "\n")

def save(p, s, crlf):
    base, ext = os.path.splitext(p)
    bak = "%s_ก่อนรอบ164%s.bak" % (base, ext)
    if not os.path.exists(bak): shutil.copy2(p, bak)
    if crlf: s = s.replace("\n", "\r\n")
    open(p, "w", encoding="utf-8", newline="").write(s)
    print("patched", p)

def patch(p, pairs):
    raw, crlf, s = rw(p)
    if MARK in s:
        print("skip", p); return
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:70])
        s = s.replace(a, b)
    save(p, s, crlf)

# 1) ไฟล์สกิล: HEAL → PASSIVE · max 10 · potion_heal_percent 5/เลเวล
p = "data/skills/first_aid.tres"
raw, crlf, s = rw(p)
if "potion_heal_percent" in s:
    print("skip", p)
else:
    s = re.sub(r'^description = ".*"$', 'description = "ยาฟื้นฟู (ยาแดง ยาส้ม ยาน้ำเงิน ฯลฯ) ฟื้น HP/SP แรงขึ้น 5% ต่อเลเวล — เลเวล 10 = +50% · ติดตัวตลอด ไม่ต้องกด"', s, count=1, flags=re.M)
    s = re.sub(r'^type = \d+$', 'type = 4', s, count=1, flags=re.M)
    s = re.sub(r'^max_level = \d+$', 'max_level = 10', s, count=1, flags=re.M)
    s = s.rstrip("\n") + '\npassive_effects = {\n"potion_heal_percent": 5.0\n}\n'
    save(p, s, crlf)

# 2) PlayerState: ยาฟื้นแรงขึ้นตามพาสซีฟ · คูลดาวน์คิดจากปริมาณฐาน (ไม่ลงโทษคนอัปสกิล)
patch("scripts/core/player_state.gd", [
    ("func potion_heal_amounts(data: ItemData) -> Dictionary:\n\tif data == null or stats == null:\n\t\treturn {\"hp\": 0, \"sp\": 0}\n\treturn {\n\t\t\"hp\": data.heal_hp + int(stats.max_hp * data.heal_hp_percent / 100.0),\n\t\t\"sp\": data.heal_sp + int(stats.max_sp * data.heal_sp_percent / 100.0),\n\t}\n",
     "## ★ รอบ 164 ★ boosted = true → รวมโบนัสพาสซีฟ First Aid (potion_heal_percent) แล้ว · false = ค่าฐานของยา (ใช้คิดคูลดาวน์)\n"
     "func potion_heal_amounts(data: ItemData, boosted: bool = true) -> Dictionary:\n\tif data == null or stats == null:\n\t\treturn {\"hp\": 0, \"sp\": 0}\n"
     "\tvar mult := 1.0 + (potion_heal_bonus_percent() / 100.0 if boosted else 0.0)\n"
     "\treturn {\n\t\t\"hp\": int(round((data.heal_hp + int(stats.max_hp * data.heal_hp_percent / 100.0)) * mult)),\n\t\t\"sp\": int(round((data.heal_sp + int(stats.max_sp * data.heal_sp_percent / 100.0)) * mult)),\n\t}\n\n\n"
     "## ★ รอบ 164 ★ ยาฟื้นแรงขึ้นกี่ % (พาสซีฟ First Aid 5%/เลเวล · key potion_heal_percent ใน passive_effects)\n"
     "func potion_heal_bonus_percent() -> float:\n\tif skills == null:\n\t\treturn 0.0\n\treturn float(skills.passive_bonus().get(&\"potion_heal_percent\", 0.0))\n"),
    ("\tvar h := potion_heal_amounts(data)\n\treturn maxf(potion_cooldown_for(int(h.hp)), potion_cooldown_for(int(h.sp)))\n",
     "\tvar h := potion_heal_amounts(data, false)   # ★ รอบ 164 ★ คูลดาวน์ตามปริมาณฐาน\n\treturn maxf(potion_cooldown_for(int(h.hp)), potion_cooldown_for(int(h.sp)))\n"),
    ("\tstart_potion_cooldown(heal, sp_heal, data.potion_cooldown)   # ★ รอบ 115 ★\n",
     "\tvar base_amt := potion_heal_amounts(data, false)   # ★ รอบ 164 ★ คูลดาวน์ตามปริมาณฐาน (โบนัส First Aid ไม่ทำให้รอนานขึ้น)\n"
     "\tstart_potion_cooldown(int(base_amt.hp), int(base_amt.sp), data.potion_cooldown)   # ★ รอบ 115 ★\n"),
])

# 3) SkillBook: เซฟเก่าที่ผูก First Aid ไว้ที่ปุ่มลัด → ถอดสกิลพาสซีฟออกจากปุ่ม
patch("scripts/core/skill_book.gd", [
    ("\tfor i in range(mini(h.size(), HOTKEY_COUNT)):\n\t\thotkeys[i] = StringName(h[i])\n",
     "\tfor i in range(mini(h.size(), HOTKEY_COUNT)):\n\t\thotkeys[i] = StringName(h[i])\n"
     "\t\t# ★ รอบ 164 ★ สกิลที่กลายเป็นพาสซีฟ (First Aid) ผูกปุ่มไม่ได้แล้ว\n"
     "\t\tvar hs := GameData.get_skill(hotkeys[i]) if hotkeys[i] != &\"\" else null\n"
     "\t\tif hs != null and hs.type == SkillData.SkillType.PASSIVE:\n\t\t\thotkeys[i] = &\"\"\n"),
])

# 4) Player: กดสกิลพาสซีฟไม่ใช้ SP
patch("scripts/entities/player.gd", [
    ("\tvar s := GameData.get_skill(skill_id)\n\tif s == null:\n\t\treturn\n\tif not PlayerState.commit_skill_use(skill_id):\n",
     "\tvar s := GameData.get_skill(skill_id)\n\tif s == null or s.type == SkillData.SkillType.PASSIVE:   # ★ รอบ 164 ★ พาสซีฟกดไม่ได้\n\t\treturn\n\tif not PlayerState.commit_skill_use(skill_id):\n"),
])

# 5) หน้าสกิล: ชื่อค่าพาสซีฟอ่านง่าย + บรรทัดเลเวลถัดไป
patch("scripts/ui/skill_window.gd", [
    ("\t\t\tfor k in pv.keys():\n\t\t\t\tstats_lines.append(\"%s %+.0f (ติดตัวตลอด)\" % [k, pv[k]])\n",
     "\t\t\tfor k in pv.keys():\n"
     "\t\t\t\tif String(k) == \"potion_heal_percent\":   # ★ รอบ 164 ★ First Aid\n"
     "\t\t\t\t\tstats_lines.append(\"ยาฟื้นฟู HP/SP แรงขึ้น +%.0f%% (ติดตัวตลอด)\" % pv[k])\n"
     "\t\t\t\telse:\n\t\t\t\t\tstats_lines.append(\"%s %+.0f (ติดตัวตลอด)\" % [k, pv[k]])\n"),
    ("\t\tif skill.damage_mult(maxi(1,lv))>0 and skill.type not in [SkillData.SkillType.PASSIVE,SkillData.SkillType.BUFF]:\n",
     "\t\tif skill.passive_effects.has(\"potion_heal_percent\"):   # ★ รอบ 164 ★\n"
     "\t\t\tnext += \"  •  ยาแรงขึ้น +%.0f%% → +%.0f%%\"%[float(skill.passive_values(lv).get(\"potion_heal_percent\",0.0)),float(skill.passive_values(lv+1).get(\"potion_heal_percent\",0.0))]\n"
     "\t\telif skill.damage_mult(maxi(1,lv))>0 and skill.type not in [SkillData.SkillType.PASSIVE,SkillData.SkillType.BUFF,SkillData.SkillType.HEAL]:\n"),
])

# 6) กล่องรายละเอียดไอเทม: โชว์ปริมาณที่ฟื้นจริงเมื่อมีโบนัส
patch("scripts/ui/item_info_popup.gd", [
    ("\tif d.heal_hp != 0 or d.heal_hp_percent != 0.0:\n\t\tstats.append(\"ฟื้น HP %d (+%.0f%%)\" % [d.heal_hp, d.heal_hp_percent])\n\tif d.heal_sp != 0 or d.heal_sp_percent != 0.0:\n\t\tstats.append(\"ฟื้น SP %d (+%.0f%%)\" % [d.heal_sp, d.heal_sp_percent])\n",
     "\tif d.heal_hp != 0 or d.heal_hp_percent != 0.0:\n\t\tstats.append(\"ฟื้น HP %d (+%.0f%%)\" % [d.heal_hp, d.heal_hp_percent])\n\tif d.heal_sp != 0 or d.heal_sp_percent != 0.0:\n\t\tstats.append(\"ฟื้น SP %d (+%.0f%%)\" % [d.heal_sp, d.heal_sp_percent])\n"
     "\t# ★ รอบ 164 ★ พาสซีฟ First Aid\n"
     "\tvar pot_bonus: float = PlayerState.potion_heal_bonus_percent() if (d.heal_hp != 0 or d.heal_sp != 0 or d.heal_hp_percent != 0.0 or d.heal_sp_percent != 0.0) else 0.0\n"
     "\tif pot_bonus > 0.0:\n"
     "\t\tvar real := PlayerState.potion_heal_amounts(d)\n"
     "\t\tstats.append(\"[color=#7dffa8]ปฐมพยาบาล +%.0f%% → ฟื้นจริง HP %d · SP %d[/color]\" % [pot_bonus, int(real.hp), int(real.sp)])\n"),
])
