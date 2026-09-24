# ★ รอบ 167 ★ ขยายภาพสกิลมอนให้สมกับขนาดตัว (รันซ้ำได้ — เปลี่ยนเฉพาะช่องที่ยังเป็นค่าเดิม)
# ตาราง ค่าเดิม → ค่าใหม่ อยู่ใน fx_table.json ข้างไฟล์นี้ · สำรองไฟล์เดิมที่ _to_delete/ก่อนรอบ167/
# หลัก: ภาพคลื่นสูงราว 55 เปอร์เซ็นต์ของตัวมอน (ที่มองเห็นจริง ขั้นต่ำ 140 สูงสุด 380 px) · เสาสายฟ้า/ศิลาราว 90 เปอร์เซ็นต์ของตัว
#       ช่องโดนคลื่นกว้างขึ้นตามภาพ แต่ไม่เกิน 40 เปอร์เซ็นต์ของความกว้างภาพ และไม่เกิน 140 (ยังพุ่งหลบทะลุได้)
# วิธีใช้: python tools/round167/apply_skillfx.py   (ที่รากโปรเจกต์)
import os, sys, re, shutil, json

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.abspath(os.path.join(HERE, "..", ".."))
BK = os.path.join(ROOT, "_to_delete", "ก่อนรอบ167")
FX = json.load(open(os.path.join(HERE, "fx_table.json"), encoding="utf-8"))

changed = 0
for mid, fields in FX.items():
    p = os.path.join(ROOT, "data", "monsters", mid + ".tres")
    raw = open(p, "rb").read().decode("utf-8")
    crlf = "\r\n" in raw
    s = raw.replace("\r\n", "\n")
    new = s
    for f, (old, val) in fields.items():
        m = re.search(r"^" + f + r" = (.+)$", new, re.M)
        cur = float(m.group(1)) if m else None
        if cur is not None and abs(cur - val) < 0.01:
            continue                                   # แก้แล้ว
        if cur is not None and abs(cur - old) > 0.01:
            print("!! ข้าม", mid, f, "ค่าตอนนี้", cur, "ไม่ใช่ค่าเดิม", old)
            continue
        line = "%s = %s" % (f, repr(float(val)))
        if m:
            new = new[:m.start()] + line + new[m.end():]
        else:                                          # ยังเป็นค่าเริ่มต้น (ไม่มีบรรทัด) → เติมท้ายบล็อก [resource]
            i = new.find("\n[resource]\n")
            if i < 0:
                print("!! ไม่เจอ [resource]", mid)
                continue
            j = new.find("\n[", i + 12)
            if j < 0:
                new = new.rstrip("\n") + "\n" + line + "\n"
            else:
                new = new[:j].rstrip("\n") + "\n" + line + "\n" + new[j:]
    if new != s:
        b = os.path.join(BK, "data", "monsters", mid + ".tres")
        os.makedirs(os.path.dirname(b), exist_ok=True)
        if not os.path.exists(b):
            shutil.copy2(p, b)
        open(p, "wb").write((new.replace("\n", "\r\n") if crlf else new).encode("utf-8"))
        changed += 1
        print("แก้", mid, ", ".join(fields))
print("เสร็จ: แก้", changed, "ไฟล์")

# ---------------- โค้ด 2 จุด ----------------
CODE = {
    "scripts/entities/monster_base.gd": [(
        "\td.hp_bar_offset_y *= CHAMPION_SCALE\n\tdata = d\n",
        "\td.hp_bar_offset_y *= CHAMPION_SCALE\n\tSkillFxScale.apply(d, CHAMPION_SCALE)   # ★ รอบ 167 ★ ตัวใหญ่ขึ้น = ภาพสกิลใหญ่ตาม\n\tdata = d\n")],
    "scripts/entities/boss_zone_skill.gd": [(
        "\tfor z in fx.zones:\n\t\tfx._end = maxf(fx._end, float(z[\"at\"]) + STRIKE_TIME + 0.15)\n",
        "\t# ★ รอบ 167 ★ บอสตัวสูงกว่ากรอบ → ยืดกรอบขึ้นไปให้สูงเกินตัวบอส 10%\n"
        "\t# (ความกว้าง/จังหวะ/ช่องปลอดภัยเท่าเดิม · โดนเฉพาะที่เท้า จึงไม่ยากขึ้น)\n"
        "\tvar tall: float = actor.body_size().y * 1.1 if actor.has_method(\"body_size\") else 0.0\n"
        "\tfor z in fx.zones:\n"
        "\t\tvar zr: Rect2 = z[\"rect\"]\n"
        "\t\tif String(z[\"kind\"]) == \"pillar\" and tall > zr.size.y:\n"
        "\t\t\tz[\"rect\"] = Rect2(zr.position.x, zr.end.y - tall, zr.size.x, tall)\n"
        "\tfor z in fx.zones:\n\t\tfx._end = maxf(fx._end, float(z[\"at\"]) + STRIKE_TIME + 0.15)\n")],
}
for rel, reps in CODE.items():
    p = os.path.join(ROOT, rel)
    raw = open(p, "rb").read().decode("utf-8")
    crlf = "\r\n" in raw
    s = raw.replace("\r\n", "\n")
    new = s
    for old, rep in reps:
        if rep in new:
            continue
        if old not in new:
            print("!! ไม่เจอจุดแพตช์", rel)
            continue
        new = new.replace(old, rep, 1)
    if new != s:
        b = os.path.join(BK, rel)
        os.makedirs(os.path.dirname(b), exist_ok=True)
        if not os.path.exists(b):
            shutil.copy2(p, b)
        open(p, "wb").write((new.replace("\n", "\r\n") if crlf else new).encode("utf-8"))
        print("แก้", rel)
