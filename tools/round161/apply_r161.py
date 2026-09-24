#!/usr/bin/env python3
"""รอบ 161 — ปรับบทเควส/บทพูด NPC ทั้งเกม + เควสข้ามเมือง 2 เควส + ระบบ 2 ภาษา (ไทย/English)

    python3 tools/round161/apply_r161.py            → แก้ไฟล์จริง (สำรองไว้ที่ _to_delete/ก่อนรอบ161/)
    python3 tools/round161/apply_r161.py --check    → แค่รายงาน ไม่เขียนไฟล์

idempotent: รันซ้ำได้ ไฟล์ที่ตรงแล้วจะไม่ถูกแตะ · ไม่เปลี่ยนเป้าหมาย/ธง/รางวัลของเควสเดิม
ข้อมูลบททั้งหมดอยู่ใน r161_data.json (ไฟล์เดียวกันนี้) · คำแปลอังกฤษถูกเขียนเป็น locale/en.po
"""
import json, os, re, shutil, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
CHECK = "--check" in sys.argv
D = json.load(open(os.path.join(HERE, "r161_data.json"), encoding="utf-8"))
BK = os.path.join(ROOT, "_to_delete", "ก่อนรอบ161")
LOG = []
WARN = []


def log(s): LOG.append(s)
def warn(s): WARN.append(s)


# ---------------------------------------------------------------- IO
def read(rel):
    with open(os.path.join(ROOT, rel), "rb") as f:
        return f.read().decode("utf-8")


def write(rel, text, old=None):
    if old is not None and text == old:
        return False
    if CHECK:
        log("[check] would write " + rel)
        return True
    p = os.path.join(ROOT, rel)
    if os.path.exists(p):
        b = os.path.join(BK, rel)
        if not os.path.exists(b):
            os.makedirs(os.path.dirname(b), exist_ok=True)
            shutil.copy2(p, b)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "wb") as f:
        f.write(text.encode("utf-8"))
    log("wrote " + rel)
    return True


# ---------------------------------------------------------------- Godot string literal
def parse_str(s, i):
    """s[i] == '"' → (value, index after closing quote)"""
    assert s[i] == '"', s[i:i + 20]
    out = []
    i += 1
    while i < len(s):
        c = s[i]
        if c == "\\":
            n = s[i + 1]
            out.append({"n": "\n", "t": "\t", "r": "", '"': '"', "\\": "\\"}.get(n, "\\" + n))
            i += 2
            continue
        if c == '"':
            return "".join(out), i + 1
        out.append(c)
        i += 1
    raise ValueError("unterminated string")


def enc(v):
    v = v.replace("\r", "")
    return '"' + v.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t") + '"'


def pages(v):
    """แบ่งหน้าแบบเดียวกับ dump_npc_lines.py (บรรทัดว่าง = หน้าใหม่)"""
    return [p.strip() for p in re.split(r"\n\s*\n", (v or "").replace("\r", "")) if p.strip()]


def game_pages(v):
    """แบ่งหน้าแบบในเกม: Loc.clean(text).split("\\n\\n", false) + strip_edges"""
    return [p.strip() for p in (v or "").replace("\r", "").split("\n\n") if p.strip()]


def find_prop(block, key):
    m = re.search(r'(?m)^%s = "' % re.escape(key), block)
    if not m:
        return None
    val, end = parse_str(block, m.end() - 1)
    return m.start(), end, val


def set_prop(block, key, val, nl, after_key="npc_name"):
    f = find_prop(block, key)
    if f:
        st, en, old = f
        if old.replace("\r", "") == val:
            return block
        return block[:st] + "%s = %s" % (key, enc(val)) + block[en:]
    m = re.search(r'(?m)^%s = .*$' % re.escape(after_key), block)
    line = "%s = %s" % (key, enc(val))
    if m:
        return block[:m.end()] + nl + line + block[m.end():]
    return insert_at_end(block, line, nl)


def insert_at_end(block, line, nl):
    body = block.rstrip("\r\n")
    tail = block[len(body):]
    return body + nl + line + tail


# ---------------------------------------------------------------- quests
QFIELD = {"offer": "dialog_offer", "desc": "description", "progress": "dialog_progress",
          "complete": "dialog_complete", "choice": "choice_prompt", "cutscene": "cutscene_text"}


def patch_quest_file(qid, fields, cut_pages=None):
    rel = "data/quests/%s.tres" % qid
    if not os.path.exists(os.path.join(ROOT, rel)):
        warn("ไม่พบ " + rel)
        return
    src = read(rel)
    nl = "\r\n" if "\r\n" in src else "\n"
    ri = src.index("[resource]")
    head, res = src[:ri], src[ri:]
    for k, v in fields.items():
        if k == "opts":
            line = "choice_options = Array[String]([%s])" % ", ".join(enc(x) for x in v)
            m = re.search(r"(?m)^choice_options = Array\[String\]\(\[.*?\]\)", res, re.S)
            if m:
                res = res[:m.start()] + line + res[m.end():]
            else:
                res = insert_at_end(res, line, nl)
            continue
        res = set_prop(res, QFIELD[k], v, nl, after_key="giver_name")
    if cut_pages:
        bk = os.path.join(BK, rel)
        bres = open(bk, "rb").read().decode("utf-8") if os.path.exists(bk) else res
        bres = bres[bres.index("[resource]"):]
        f = find_prop(bres, "cutscene_text")
        if f:
            ps = pages(f[2])
            for idx, txt in cut_pages.items():
                if idx - 1 < len(ps):
                    ps[idx - 1] = txt
            res = set_prop(res, "cutscene_text", "\n\n".join(ps), nl)
    # ข้อความเป้าหมาย (sub_resource text = "...")
    def fix_obj(block):
        out, pos = [], 0
        for m in re.finditer(r'(?m)^text = "', block):
            if m.start() < pos:
                continue
            val, end = parse_str(block, m.end() - 1)
            new = D["OBJ_FIX"].get(val.replace("\r", ""))
            out.append(block[pos:m.start()])
            out.append("text = " + (enc(new) if new else block[m.end() - 1:end]))
            pos = end
        out.append(block[pos:])
        return "".join(out)
    head = fix_obj(head)
    new = head + res
    write(rel, new, src)


def run_quests():
    cut = {}
    for m, npc, key, val in D["N"]:
        mm = re.match(r"(.+)_cutscene_(\d+)$", key)
        if mm:
            cut.setdefault(mm.group(1), {})[int(mm.group(2))] = val
    ids = set(D["Q"]) | set(cut)
    for qid in sorted(ids):
        patch_quest_file(qid, D["Q"].get(qid, {}), cut.get(qid))
    # เป้าหมายที่ต้องแก้ในเควสที่ไม่ได้แก้บท
    for fn in sorted(os.listdir(os.path.join(ROOT, "data/quests"))):
        if fn.endswith(".tres") and fn[:-5] not in ids:
            src = read("data/quests/" + fn)
            if any(('"%s"' % o) in src for o in D["OBJ_FIX"]):
                patch_quest_file(fn[:-5], {})


def new_quest_text(qid, q, nl):
    kinds = {"KILL": 0, "COLLECT": 1, "TALK": 2, "VISIT": 3, "READ": 4, "FLAG": 5, "SKILL_HIT": 6}
    L = ['[gd_resource type="Resource" script_class="QuestData" load_steps=%d format=3]' % (2 + len(q["objectives"])), "",
         '[ext_resource type="Script" path="res://scripts/resources/quest_data.gd" id="1_quest"]',
         '[ext_resource type="Script" path="res://scripts/resources/objective_data.gd" id="2_obj"]', ""]
    for i, (k, t, c, txt) in enumerate(q["objectives"]):
        L += ['[sub_resource type="Resource" id="Obj_%d"]' % i, 'script = ExtResource("2_obj")', "kind = %d" % kinds[k],
              'target = &%s' % enc(t), "count = %d" % c, "text = %s" % enc(txt), ""]
    L += ["[resource]", 'script = ExtResource("1_quest")', 'id = &"%s"' % qid, "title = " + enc(q["title"]),
          "description = " + enc(q["desc"]), "giver_name = " + enc(q["giver"]), "turn_in_name = " + enc(q["turn_in"]),
          "dialog_offer = " + enc(q["offer"]), "dialog_progress = " + enc(q["progress"]), "dialog_complete = " + enc(q["complete"]),
          "objectives = Array[ExtResource(\"2_obj\")]([%s])" % ", ".join('SubResource("Obj_%d")' % i for i in range(len(q["objectives"]))),
          'kill_monster_id = &""', "required_level = %d" % q["required_level"],
          'required_job = &"%s"' % q["required_job"],
          "required_quests = Array[StringName]([%s])" % ", ".join('&"%s"' % r for r in q["required_quests"]),
          'set_flag_on_complete = &"%s"' % q["flag"],
          "reward_zeny = %d" % q["zeny"], "reward_exp = %d" % q["exp"], "reward_job_exp = %d" % q["job_exp"], ""]
    return nl.join(L)


def run_new_quests():
    for qid, q in D["NEW_QUESTS"].items():
        rel = "data/quests/%s.tres" % qid
        txt = new_quest_text(qid, q, "\n")
        p = os.path.join(ROOT, rel)
        old = read(rel) if os.path.exists(p) else None
        write(rel, txt, old)


# ---------------------------------------------------------------- scenes (NPC)
def split_blocks(src):
    idx = [m.start() for m in re.finditer(r"(?m)^\[", src)]
    idx.append(len(src))
    head = src[:idx[0]]
    return head, [src[idx[i]:idx[i + 1]] for i in range(len(idx) - 1)]


def npc_block_index(blocks, name):
    for i, b in enumerate(blocks):
        f = find_prop(b, "npc_name")
        if f and f[2] == name:
            return i
    return -1


def parse_flag_dict(block):
    m = re.search(r"(?m)^dialog_by_flag = \{", block)
    if not m:
        return None
    i = m.end()
    items = []
    while True:
        while block[i] in " \t\r\n,":
            i += 1
        if block[i] == "}":
            return m.start(), i + 1, items
        k, i = parse_str(block, i)
        while block[i] in " \t\r\n:":
            i += 1
        v, i = parse_str(block, i)
        items.append([k, v])


def set_flag_dict(block, items, nl):
    txt = "dialog_by_flag = {" + nl + ("," + nl).join("%s: %s" % (enc(k), enc(v)) for k, v in items) + nl + "}"
    f = parse_flag_dict(block)
    if f:
        st, en, old = f
        if [[a, b.replace("\r", "")] for a, b in old] == items:
            return block
        return block[:st] + txt + block[en:]
    return insert_at_end(block, txt, nl)


def run_scenes():
    by_scene = {}
    for m, npc, key, val in D["N"]:
        if re.search(r"_cutscene_\d+$", key):
            continue
        by_scene.setdefault(m, {}).setdefault(npc, []).append((key, val))
    for m, npc, flag, val in D["NEW_FLAG_LINES"]:
        by_scene.setdefault(m, {}).setdefault(npc, []).append(("__newflag__" + flag, val))
    for m, npc, qid in D["ADD_QUEST_IDS"]:
        by_scene.setdefault(m, {}).setdefault(npc, []).append(("__quest__", qid))
    for scene, npcs in sorted(by_scene.items()):
        rel = "scenes/maps/%s.tscn" % scene
        src = read(rel)
        nl = "\r\n" if "\r\n" in src else "\n"
        head, blocks = split_blocks(src)
        # ฐานสำหรับแทนรายหน้า = ไฟล์ก่อนรอบ 161 (สำรอง) — รันซ้ำแล้วเลขหน้าไม่เลื่อน
        bk = os.path.join(BK, rel)
        base_blocks = split_blocks(open(bk, "rb").read().decode("utf-8"))[1] if os.path.exists(bk) else blocks
        for npc, edits in npcs.items():
            bi = npc_block_index(blocks, npc)
            if bi < 0:
                warn("ไม่พบ NPC %s ใน %s" % (npc, rel))
                continue
            b = blocks[bi]
            bb = base_blocks[npc_block_index(base_blocks, npc)] if npc_block_index(base_blocks, npc) >= 0 else b
            dialog_pages = None
            fd = parse_flag_dict(bb)
            flags = [[k, v.replace("\r", "")] for k, v in (fd[2] if fd else [])]
            flags_changed = False
            for key, val in edits:
                if key == "greeting":
                    b = set_prop(b, "greeting", val, nl)
                elif key == "__quest__":
                    mq = re.search(r"(?m)^quest_ids = Array\[StringName\]\(\[(.*?)\]\)", b)
                    if mq:
                        if ('&"%s"' % val) not in mq.group(1):
                            inner = mq.group(1).strip()
                            new_inner = (inner + ", " if inner else "") + '&"%s"' % val
                            b = b[:mq.start(1)] + new_inner + b[mq.end(1):]
                    else:
                        b = insert_at_end(b, 'quest_ids = Array[StringName]([&"%s"])' % val, nl)
                elif key.startswith("__newflag__"):
                    fl = key[len("__newflag__"):]
                    for it in flags:
                        if it[0] == fl:
                            if it[1] != val:
                                it[1] = val
                                flags_changed = True
                            break
                    else:
                        flags.append([fl, val])
                        flags_changed = True
                else:
                    mk = re.match(r"(.+)_(\d+)$", key)
                    if not mk:
                        warn("คีย์แปลก %s %s" % (npc, key))
                        continue
                    base, idx = mk.group(1), int(mk.group(2))
                    if base == "dialog":
                        if dialog_pages is None:
                            f = find_prop(bb, "dialog")
                            dialog_pages = pages(f[2]) if f else []
                        if idx - 1 < len(dialog_pages):
                            dialog_pages[idx - 1] = val
                        else:
                            warn("หน้า dialog เกิน %s %s" % (npc, key))
                    else:
                        for it in flags:
                            if it[0] == base:
                                ps = pages(it[1])
                                if idx - 1 < len(ps):
                                    ps[idx - 1] = val
                                    nv = "\n\n".join(ps)
                                    if nv != it[1]:
                                        it[1] = nv
                                        flags_changed = True
                                break
                        else:
                            warn("ไม่พบธง %s ของ %s" % (base, npc))
            if dialog_pages is not None:
                b = set_prop(b, "dialog", "\n\n".join(dialog_pages), nl)
            if flags_changed or any(k.startswith("__newflag__") or re.match(r"(.+)_(\d+)$", k) and not k.startswith("dialog_") for k, _ in edits if k != "greeting" and k != "__quest__"):
                b = set_flag_dict(b, flags, nl)
            blocks[bi] = b
        write(rel, head + "".join(blocks), src)


# ---------------------------------------------------------------- scripts
def patch_text(rel, pairs, must=True):
    src = read(rel)
    new = src
    for old, rep in pairs:
        if rep in new:
            continue            # แพตช์แล้ว (รันซ้ำไม่ซ้อน)
        if old not in new:
            (warn if must else log)("ไม่พบข้อความใน %s: %s" % (rel, old[:60]))
            continue
        new = new.replace(old, rep)
    write(rel, new, src)


def crlf(rel, s):
    src = read(rel)
    return s.replace("\n", "\r\n") if "\r\n" in src else s


def run_scripts():
    # ---- ระบบภาษา ----
    loc = open(os.path.join(HERE, "loc.gd.txt"), encoding="utf-8").read()
    p = os.path.join(ROOT, "scripts/core/loc.gd")
    write("scripts/core/loc.gd", loc, read("scripts/core/loc.gd") if os.path.exists(p) else None)

    patch_text("scripts/core/game.gd", [(
        "func _ready() -> void:\r\n\tprocess_mode = Node.PROCESS_MODE_ALWAYS\r\n",
        "func _ready() -> void:\r\n\tprocess_mode = Node.PROCESS_MODE_ALWAYS\r\n\tLoc.init()   # ★ รอบ 161 ★ ภาษา (ไทย/English)\r\n")]
        if "\r\n" in read("scripts/core/game.gd") else [(
        "func _ready() -> void:\n\tprocess_mode = Node.PROCESS_MODE_ALWAYS\n",
        "func _ready() -> void:\n\tprocess_mode = Node.PROCESS_MODE_ALWAYS\n\tLoc.init()   # ★ รอบ 161 ★ ภาษา (ไทย/English)\n")])

    patch_text("scripts/ui/dialogue_box.gd", [
        ("\t_name_label.text = speaker\n", "\t_name_label.text = Loc.t(speaker)   # ★ รอบ 161 ★\n"),
        ("\t_full_text = String(line.get(\"text\", \"\"))\n", "\t_full_text = Loc.t(String(line.get(\"text\", \"\")))   # ★ รอบ 161 ★ แปล + ตัด \\r\n"),
        ("\tvar info := String(line.get(\"info\", \"\"))\n", "\tvar info: String = Loc.t(String(line.get(\"info\", \"\")))\n"),
        ("UITheme.make_button(String(choices[i]), 150)", "UITheme.make_button(Loc.t(String(choices[i])), 150)"),
        ("_hint.text = \"Esc = ยกเลิก\" if", "_hint.text = Loc.t(\"Esc = ยกเลิก\") if"),
    ] if "\r\n" not in read("scripts/ui/dialogue_box.gd") else [
        (a.replace("\n", "\r\n"), b.replace("\n", "\r\n")) for a, b in [
        ("\t_name_label.text = speaker\n", "\t_name_label.text = Loc.t(speaker)   # ★ รอบ 161 ★\n"),
        ("\t_full_text = String(line.get(\"text\", \"\"))\n", "\t_full_text = Loc.t(String(line.get(\"text\", \"\")))   # ★ รอบ 161 ★ แปล + ตัด \\r\n"),
        ("\tvar info := String(line.get(\"info\", \"\"))\n", "\tvar info: String = Loc.t(String(line.get(\"info\", \"\")))\n"),
        ("UITheme.make_button(String(choices[i]), 150)", "UITheme.make_button(Loc.t(String(choices[i])), 150)"),
        ("_hint.text = \"Esc = ยกเลิก\" if", "_hint.text = Loc.t(\"Esc = ยกเลิก\") if"),
    ]])

    patch_text("scripts/world/lore_object.gd", [("for part in body.split(\"\\n\\n\", false):", "for part in Loc.clean(body).split(\"\\n\\n\", false):")])

    patch_text("scripts/resources/objective_data.gd", [("\tif text != \"\":" + ("\r\n" if "\r\n" in read("scripts/resources/objective_data.gd") else "\n") + "\t\treturn text",
                                                        "\tif text != \"\":" + ("\r\n" if "\r\n" in read("scripts/resources/objective_data.gd") else "\n") + "\t\treturn Loc.t(text)   # ★ รอบ 161 ★")])

    qd_nl = "\r\n" if "\r\n" in read("scripts/resources/quest_data.gd") else "\n"
    patch_text("scripts/resources/quest_data.gd", [(
        "@export var giver_name: String = \"\"" + qd_nl,
        "@export var giver_name: String = \"\"" + qd_nl +
        "## ★ รอบ 161 ★ ส่งเควสกับ NPC คนอื่น (เว้นว่าง = ส่งกับคนให้เควส) — เช่น ผีนักล่าฝากข่าวถึงอิงกริด" + qd_nl +
        "@export var turn_in_name: String = \"\"" + qd_nl)])
    if "func turn_in_npc()" not in read("scripts/resources/quest_data.gd"):
        s = read("scripts/resources/quest_data.gd")
        write("scripts/resources/quest_data.gd", s.rstrip("\r\n") + qd_nl + qd_nl + qd_nl +
              "## ★ รอบ 161 ★ ชื่อ NPC ที่ต้องกลับไปส่งเควสนี้" + qd_nl +
              "func turn_in_npc() -> String:" + qd_nl + "\treturn turn_in_name if turn_in_name != \"\" else giver_name" + qd_nl, s)

    patch_text("scripts/core/quest_log.gd", [("% [q.title, q.giver_name])", "% [q.title, q.turn_in_npc()])   # ★ รอบ 161 ★")])

    # ---- npc.gd ----
    n = "\r\n" if "\r\n" in read("scripts/world/npc.gd") else "\n"
    pairs = [
        ("for part in current_dialog().split(\"\\n\\n\", false):", "for part in Loc.clean(current_dialog()).split(\"\\n\\n\", false):"),
        ("for part in q.dialog_offer.split(\"\\n\\n\", false):", "for part in Loc.clean(q.dialog_offer).split(\"\\n\\n\", false):"),
        ("for part in q.cutscene_text.split(\"\\n\\n\", false):", "for part in Loc.clean(q.cutscene_text).split(\"\\n\\n\", false):"),
        # เครื่องหมายบนหัว
        ("\tfor qid in quest_ids:" + n + "\t\tif qlog.is_ready(qid):" + n + "\t\t\t_show_mark(\"?\"",
         "\tfor qid in quest_ids:" + n + "\t\tif qlog.is_ready(qid) and _takes_turn_in(qid):   # ★ รอบ 161 ★" + n + "\t\t\t_show_mark(\"?\""),
        ("\t\tif qlog.can_accept(qid, lv):" + n + "\t\t\t_show_mark(\"!\", Color(\"#ffe14a\"))",
         "\t\tif qlog.can_accept(qid, lv) and _offers_quest(qid):   # ★ รอบ 161 ★" + n + "\t\t\t_show_mark(\"!\", Color(\"#ffe14a\"))"),
        # _handle_quests
        ("\tfor qid in story_quests:" + n + "\t\tif qlog.is_ready(qid):" + n + "\t\t\tawait _ask_turn_in",
         "\tfor qid in story_quests:" + n + "\t\tif qlog.is_ready(qid) and _takes_turn_in(qid):   # ★ รอบ 161 ★" + n + "\t\t\tawait _ask_turn_in"),
        ("\tfor qid in story_quests:" + n + "\t\tif qlog.can_accept(qid, lv):" + n + "\t\t\tawait _ask_accept",
         "\tfor qid in story_quests:" + n + "\t\tif qlog.can_accept(qid, lv) and _offers_quest(qid):   # ★ รอบ 161 ★" + n + "\t\t\tawait _ask_accept"),
        # _runeblade_menu
        ("\t\tif PlayerState.quests.is_active(id) or PlayerState.quests.can_accept(id,PlayerState.stats.level):",
         "\t\tif PlayerState.quests.is_active(id) or (PlayerState.quests.can_accept(id,PlayerState.stats.level) and _offers_quest(id)):   # ★ รอบ 161 ★"),
        ("choices.append(q.title + (\" — ส่งเควส\" if PlayerState.quests.is_ready(id) else \"\"))",
         "choices.append(q.title + (\" — ส่งเควส\" if PlayerState.quests.is_ready(id) and _takes_turn_in(id) else \"\"))"),
        ("\tif PlayerState.quests.is_ready(quest.id): await _ask_turn_in(quest)",
         "\tif PlayerState.quests.is_ready(quest.id) and _takes_turn_in(quest.id): await _ask_turn_in(quest)"),
        ("\"เส้นทางเริ่มหลังจบบท 2 เปิดดันเมื่อเลเวล 50 และผ่านคมและแรง ตรวจเงื่อนไขเควสบท 3 ในสมุดเควส หากเปลี่ยนอาชีพแล้ว อ่านอักขระที่เก้า ณ ศิลาลานพิธี\"",
         "\"ตอนนี้ยังไม่มีงานบนเส้นทางดาบรูนให้เจ้า — เส้นทางนี้เริ่มกับบรอกก์ที่นิดาเวลลิร์หลังเจ้ารู้ความจริงเรื่องค้อน ดูเงื่อนไขเควสถัดไปได้ในสมุดเควส\""),
    ]
    patch_text("scripts/world/npc.gd", pairs)
    s = read("scripts/world/npc.gd")
    if "func _offers_quest(" not in s:
        add = n.join([
            "", "",
            "## ★ รอบ 161 ★ เควสที่ส่งกับ NPC อีกคน (QuestData.turn_in_name) — คนให้เควสเป็นคนชวน · คนรับส่งเป็นคนส่ง",
            "func _offers_quest(qid: StringName) -> bool:",
            "\tvar q := GameData.get_quest(qid)",
            "\tif q == null:",
            "\t\treturn false",
            "\treturn q.turn_in_name == \"\" or q.giver_name == npc_name or q.turn_in_name != npc_name",
            "",
            "",
            "func _takes_turn_in(qid: StringName) -> bool:",
            "\tvar q := GameData.get_quest(qid)",
            "\tif q == null:",
            "\t\treturn false",
            "\treturn q.turn_in_name == \"\" or q.turn_in_name == npc_name",
            ""])
        write("scripts/world/npc.gd", s.rstrip("\r\n") + add, s)

    # ---- system_window.gd — แถวเลือกภาษา ----
    s = read("scripts/ui/system_window.gd")
    if "Loc.LOCALES" not in s:
        sn = "\r\n" if "\r\n" in s else "\n"
        anchor = "\t# ---------- ออกจากเกม ----------"
        block = sn.join([
            "\t# ---------- ★ รอบ 161 — ภาษา / Language ★ ----------",
            "\tvar lang_row := HBoxContainer.new()",
            "\tlang_row.add_theme_constant_override(\"separation\", 6)",
            "\tcontent.add_child(lang_row)",
            "\tvar lang_label := UITheme.make_label(\"ภาษา / Language\", 13, UITheme.TEXT)",
            "\tlang_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL",
            "\tlang_row.add_child(lang_label)",
            "\tvar lang_group := ButtonGroup.new()",
            "\tfor code in Loc.LOCALES:",
            "\t\tvar lb := UITheme.make_button(String(Loc.LOCALE_NAMES[code]), 90)",
            "\t\tlb.toggle_mode = true",
            "\t\tlb.button_group = lang_group",
            "\t\tlb.button_pressed = Loc.current() == code",
            "\t\tlb.pressed.connect(func(): Loc.set_locale(code))",
            "\t\tlang_row.add_child(lb)",
            "\tcontent.add_child(UITheme.make_label(\"English: บทเควสและบทพูด NPC แปลแล้ว · เมนู/ไอเทม/สกิลยังเป็นภาษาไทย (ไฟล์แปล locale/en.po)\", 11, UITheme.TEXT_DIM))",
            "", ""])
        if anchor in s:
            write("scripts/ui/system_window.gd", s.replace(anchor, block + anchor, 1), s)
        else:
            warn("system_window.gd: ไม่พบจุดแทรกแถวภาษา")

    # ---- สาย Runeblade ----
    rc = "scripts/world/runeblade_campaign.gd"
    patch_text(rc, [
        ('_add_quests("บรอกก์", [&"rb1_unsung_iron"])', '_add_quests("บรอกก์", [&"rb1_unsung_iron", &"rb15_song_for_brokk"])'),
        ('&"rb6_runeblade",&"rb7_ninth_inscription"])', '&"rb6_runeblade",&"rb7_ninth_inscription",&"rb15_song_for_brokk"])'),
        ('Events.say("รับเควส คมและแรง คมและแรงกับญอร์ดาก่อน")', 'Events.say("รับเควส «คมและแรง» จากญอร์ดาก่อน แล้วค่อยมาฝึกที่นี่")'),
        ('"รับเควส คมและแรง คมและแรงกับญอร์ดาก่อน แล้วกลับมาทดสอบที่นี่"', '"รับเควส «คมและแรง» จากญอร์ดาก่อน แล้วค่อยมาฝึกที่นี่"'),
        ('"รอยแตกบนศิลาตรงกับชิ้นรูน... มีรอยเขาสองข้าง\\nเส้นอักขระขาดตรงทางคืนพลัง เหมือนวงจรที่บรอกก์พบใต้ภูเขา แต่รอยนี้ถูกสกัดออกด้วยมือผู้สร้าง"',
         '"ศิลาแตกเป็นรูปเดียวกับชิ้นรูนของซินดริ และมีรอยเขาสัตว์ขนาดใหญ่ขูดไว้สองรอย\\nเส้นคืนพลังบนศิลาถูกสกัดออก — แบบเดียวกับที่ถูกขูดออกจากค้อนของธอร์"'),
        ('"ในน้ำมีเงารูปเขา แต่บนฝั่งไม่มีใครยืนอยู่\\nเงาดึงแสงจากรูนเข้าหาตัว น้ำกลับนิ่งสนิท... สิ่งใต้บึงกำลังกินพลังที่ควรไหลคืนสู่ราก"',
         '"ในน้ำมีเงาของสิ่งที่มีเขา ทั้งที่บนฝั่งไม่มีใครยืนอยู่\\nแสงจากรูนในมือเจ้าถูกดูดเข้าหาเงานั้น... มีบางอย่างใต้บึงกำลังกินพลังที่ควรไหลคืนสู่ราก"'),
        ('"เสียงกระดิ่งดังใต้บึง ทางลงอยู่ในซุ้มรากข้าง ๆ\\nใต้ฐานกระดิ่งมีข้อความ: จงเลือกคำสัตย์ด้วยตนเอง ผู้มอบดาบแก่เสียงเรียก ย่อมเหลือเพียงเปลือก"',
         '"กระดิ่งของอัศวินดาบรูนยังดังอยู่ใต้บึง ทางลงอยู่ในซุ้มรากข้าง ๆ นี้\\nใต้ฐานกระดิ่งสลักไว้ว่า «จงเลือกคำสัตย์ด้วยตัวเอง ผู้ที่ถือดาบเพียงเพราะมีคนสั่ง จะเหลือแค่เปลือก»"'),
        ('"วงจรรูนยังมีอักขระที่เก้า... เมื่อถึงเลเวล 90 เสียงจากแดนเหนือจะเรียกหาเจ้า เส้นทางขั้นถัดไปยังไม่เปิดในบทนี้\\nคืนแต้มฟรีครั้งแรก หลังจากนั้น 10,000 z"',
         '"บรรทัดล่างสุดของศิลายังมีอักขระที่เก้าจาง ๆ อยู่... มันจะชัดขึ้นเมื่อเจ้าเดินทางไกลพอ\\nคืนแต้มสกิล Runeblade: ครั้งแรกฟรี ครั้งต่อไป 10,000 z"'),
        ('"ข้าจะเป็นผู้เลือกทิศทางของดาบด้วยตนเอง กลับไปหาญอร์ดาเพื่อรับอาชีพ Runeblade"',
         '"«ดาบเล่มนี้จะไปในทางที่ข้าเลือกเอง ไม่ใช่ทางที่ใครสั่ง» — ถ้อยคำสุดท้ายบนศิลา\\n(กลับไปหาญอร์ดาเพื่อทำพิธีเป็น Runeblade)"'),
        ('"คมที่ไร้จังหวะย่อมแตกหัก แรงที่ไร้การควบคุมย่อมย้อนคืน\\nรูนเก้าดวง... มีเพียงสามดวงที่เรายังอ่านออก"',
         '"ศิลาคำสัตย์ของอัศวินดาบรูน — มีชื่อสลักเรียงกันหลายร้อยชื่อ ส่วนใหญ่ถูกขูดจนอ่านไม่ออก\\nบรรทัดบนสุด: «คมที่ไร้จังหวะย่อมแตกหัก แรงที่ไร้การควบคุมย่อมย้อนคืน»\\nบรรทัดล่างสุดเป็นวงรูนเก้าดวง... อ่านออกเพียงสามดวง"'),
        ('"ประตูต้องการรูนประสานจากเควสคมและแรง และผู้ถือเลเวล 50 ขึ้นไป"',
         '"ซุ้มรากไม่ยอมเปิด... รูนในมือเจ้ายังตื่นไม่พอ\\n(ต้องผ่านเควส «คมและแรง» และเลเวล 50 ขึ้นไป)"'),
        ('"ทดสอบฟรี ฟื้น HP/SP เมื่อจบ หลีกแนวโจมตีสีแดงแล้วสวนในช่วงสีทอง", "choices":["จังหวะของคม: คอมโบครบ 3 ชุด", "น้ำหนักของดาบ: เปิดแผล แล้ว Bash ช่วงหุ่นเก็บท่า", "ออก"]',
         '"ลานฝึกของอัศวินดาบรูน — หุ่นจะฟาดใส่พื้นที่สีแดง หลบให้พ้นแล้วสวนกลับตอนวงสีทองขึ้น (ฝึกฟรี · จบแล้วฟื้น HP/SP)", "choices":["จังหวะของคม — คอมโบครบ 3 ชุด", "น้ำหนักของดาบ — เปิดแผล แล้วฟันแรงตอนวงสีทอง", "ออก"]'),
    ])
    bc = "scripts/world/blackhorn_rootcrypt.gd"
    patch_text(bc, [
        ('"Baphomet — ผู้กินคำสัตย์"', '"บาฟโฟเมท ผู้กินคำสัตย์"'),
        ('"รับเควส ผู้กินคำสัตย์ จากญอร์ดาก่อนเข้าห้อง"', '"รับเควส «ผู้กินคำสัตย์» จากญอร์ดาก่อนเข้าห้อง"'),
        ('"วงจรยังถูก Baphomet ยึดครอง"', '"วงจรยังถูกบาฟโฟเมทยึดไว้"'),
        ('"Baphomet พ่ายแพ้! กด F ที่วงจรหลังบัลลังก์เพื่อคืนอิสระให้รูน"', '"บาฟโฟเมทพ่ายแพ้! กด F ที่วงจรหลังบัลลังก์ เพื่อคืนพลังให้รูน"'),
        ('"เจ้ากลับทิศทางของวงจร พลังไหลคืนสู่ราก... แก่นรูนที่คืนอิสระสว่างขึ้น\\n\\nใต้บัลลังก์มีอักขระเก้าดวง สามดวงตอบรับ อีกหกดวงชี้ไปทางเหนือ — เมื่อเจ้าเติบโตถึงเลเวล 90 จงฟังเสียงเรียกอีกครั้ง"',
         '"เจ้าหมุนวงจรกลับทิศ... พลังที่เคยถูกดูดขึ้นไปตามราก ไหลคืนลงสู่แผ่นดิน รูนของอัศวินที่ถูกล่ามไว้สว่างขึ้นทีละดวง แล้วดับลงอย่างสงบ\\n\\nใต้บัลลังก์มีวงรูนเก้าดวง สามดวงสว่างตอบรับดาบของเจ้า อีกหกดวงยังมืด — ชี้ไปทางเหนือ"'),
    ])
    patch_text("scripts/world/ch456_campaign.gd", [
        ('ตามหาเตาหลอมไร้คำสั่งในบท 7 เพื่อเป็น Ninth Edge', 'ตามหาเตาหลอมไร้คำสั่งที่มุสเปลเฮม เพื่อเป็น Ninth Edge')])


# ---------------------------------------------------------------- en.po
def po_esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t")


def build_po():
    tr = {}      # thai -> english
    missing = []   # (where, thai)

    def add(th, en, where):
        th = (th or "").replace("\r", "").strip()
        if not th:
            return
        if en is None or not en.strip():
            missing.append((where, th))
            return
        en = en.replace("\r", "").strip()
        if th in tr and tr[th] != en:
            WARN.append("คำแปลซ้ำไม่ตรงกัน (%s): %s" % (where, th[:40]))
            return
        tr[th] = en

    def add_field(th, en, where):
        """ทั้งช่อง + รายหน้า (ต้องมีจำนวนหน้าเท่ากัน)"""
        if not (th or "").strip():
            return
        add(th, en, where)
        tp, ep = game_pages(th), game_pages(en or "")
        if len(tp) > 1:
            if en and len(tp) == len(ep):
                for a, b in zip(tp, ep):
                    add(a, b, where + " (หน้า)")
            else:
                WARN.append("จำนวนหน้าไม่ตรง %s: ไทย %d / อังกฤษ %d" % (where, len(tp), len(ep)))
                for a in tp:
                    missing.append((where, a))

    EQ, EO = D["EN_Q"], D["EN_OBJ"]
    qdir = os.path.join(ROOT, "data/quests")
    for fn in sorted(os.listdir(qdir)):
        if not fn.endswith(".tres"):
            continue
        qid = fn[:-5]
        src = read("data/quests/" + fn)
        ri = src.index("[resource]")
        res = src[ri:]
        e = EQ.get(qid, {})
        for key, ek in [("title", "title"), ("description", "desc"), ("dialog_offer", "offer"), ("dialog_progress", "progress"),
                        ("dialog_complete", "complete"), ("choice_prompt", "choice"), ("cutscene_text", "cutscene")]:
            f = find_prop(res, key)
            if f:
                add_field(f[2], e.get(ek), "%s.%s" % (qid, key))
        m = re.search(r"(?m)^choice_options = Array\[String\]\(\[(.*?)\]\)", res, re.S)
        if m:
            opts, i, body = [], 0, m.group(1)
            while True:
                j = body.find('"', i)
                if j < 0:
                    break
                v, i = parse_str(body, j)
                opts.append(v)
            eo = e.get("opts") or []
            for k2, o in enumerate(opts):
                add(o, eo[k2] if k2 < len(eo) else None, qid + ".choice_options")
        for mm in re.finditer(r'(?m)^text = "', src[:ri]):
            v, _ = parse_str(src, mm.end() - 1)
            add(v, EO.get(v.replace("\r", "").strip()), qid + ".objective")
    # NPC ในฉาก
    EN, NAMES = D["EN_N"], D["EN_NAMES"]
    sdir = os.path.join(ROOT, "scenes/maps")
    for fn in sorted(os.listdir(sdir)):
        if not fn.endswith(".tscn"):
            continue
        scene = fn[:-5]
        src = read("scenes/maps/" + fn)
        if "npc_name = " not in src:
            continue
        _, blocks = split_blocks(src)
        for b in blocks:
            f = find_prop(b, "npc_name")
            if not f:
                continue
            name = f[2]
            add(name, NAMES.get(name), scene + ".npc_name")
            e = EN.get("%s|%s" % (scene, name), {})
            g = find_prop(b, "greeting")
            if g:
                add(g[2], e.get("greeting"), "%s|%s.greeting" % (scene, name))
            dl = find_prop(b, "dialog")
            if dl:
                add_field(dl[2], e.get("dialog"), "%s|%s.dialog" % (scene, name))
            fd = parse_flag_dict(b)
            if fd:
                for k, v in fd[2]:
                    add_field(v, e.get("flag:" + k), "%s|%s.flag:%s" % (scene, name, k))
    for k, v in D["EN_NAMES"].items():
        tr.setdefault(k, v)
    for k, v in D["EN_UI"].items():
        tr.setdefault(k, v)
    for k, v in D["EN_SCRIPT"].items():
        tr.setdefault(k.replace("\r", "").strip(), v)
    tr.setdefault("English: บทเควสและบทพูด NPC แปลแล้ว · เมนู/ไอเทม/สกิลยังเป็นภาษาไทย (ไฟล์แปล locale/en.po)",
                  "English: quest and NPC dialogue translated · menus/items/skills are still in Thai (translation file: locale/en.po)")
    # เขียน en.po
    L = ['msgid ""', 'msgstr ""', '"Project-Id-Version: Shadows of Fate\\n"', '"Language: en\\n"',
         '"MIME-Version: 1.0\\n"', '"Content-Type: text/plain; charset=UTF-8\\n"', '"Content-Transfer-Encoding: 8bit\\n"',
         '"X-Generator: tools/round161/apply_r161.py\\n"', ""]
    for th in sorted(tr):
        L += ['msgid "%s"' % po_esc(th), 'msgstr "%s"' % po_esc(tr[th]), ""]
    po = "\n".join(L)
    p = os.path.join(ROOT, "locale/en.po")
    write("locale/en.po", po, read("locale/en.po") if os.path.exists(p) else None)
    # รายการที่ยังไม่มีคำแปล (บท NPC/เควส) + ข้อความอื่นในเกม → .pot สำหรับแปลรอบหน้า
    extra = collect_other_strings()
    seen, P = set(), ['msgid ""', 'msgstr ""', '"Content-Type: text/plain; charset=UTF-8\\n"', ""]
    for where, th in missing + extra:
        th = th.replace("\r", "").strip()
        if not th or th in tr or th in seen:
            continue
        seen.add(th)
        P += ["#: " + where, 'msgid "%s"' % po_esc(th), 'msgstr ""', ""]
    pot = "\n".join(P)
    p = os.path.join(ROOT, "locale/ยังไม่แปล.pot")
    write("locale/ยังไม่แปล.pot", pot, read("locale/ยังไม่แปล.pot") if os.path.exists(p) else None)
    log("en.po: %d ข้อความ · ยังไม่แปล (บทเควส/NPC): %d · อื่น ๆ ในเกม: %d" % (len(tr), len({t for _, t in missing} - set(tr)), len(seen) - len({t for _, t in missing} - set(tr))))
    for w, t in missing[:40]:
        log("  ยังไม่แปล: %s — %s" % (w, t[:50]))


def collect_other_strings():
    out = []
    for sub, keys in [("data/items", ["display_name", "description"]), ("data/monsters", ["display_name"]),
                      ("data/skills", ["display_name", "description"]), ("data/cards", ["display_name", "description"])]:
        d = os.path.join(ROOT, sub)
        if not os.path.isdir(d):
            continue
        for dp, _, files in os.walk(d):
            for fn in files:
                if not fn.endswith(".tres"):
                    continue
                s = read(os.path.relpath(os.path.join(dp, fn), ROOT))
                for k in keys:
                    f = find_prop(s, k)
                    if f and re.search(r"[\u0E00-\u0E7F]", f[2]):
                        out.append(("%s/%s.%s" % (sub, fn, k), f[2]))
    sdir = os.path.join(ROOT, "scenes/maps")
    for fn in sorted(os.listdir(sdir)):
        if fn.endswith(".tscn"):
            s = read("scenes/maps/" + fn)
            for k in ["title", "text", "text_again", "locked_text", "map_name", "display_name"]:
                for m in re.finditer(r'(?m)^%s = "' % k, s):
                    v, _ = parse_str(s, m.end() - 1)
                    if re.search(r"[\u0E00-\u0E7F]", v):
                        out.append(("scenes/maps/%s.%s" % (fn, k), v))
    return out


# ---------------------------------------------------------------- main
if __name__ == "__main__":
    run_scripts()
    run_new_quests()
    run_quests()
    run_scenes()
    build_po()
    print("\n".join(LOG))
    if WARN:
        print("\n== คำเตือน ==")
        print("\n".join(WARN))
    print("\nเสร็จ%s · ไฟล์เดิมสำรองที่ _to_delete/ก่อนรอบ161/" % (" (โหมดตรวจ ไม่ได้เขียน)" if CHECK else ""))
