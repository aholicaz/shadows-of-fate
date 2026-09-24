# รอบ 159 — เควสเชื่อม «ใบประกาศใบแรก» (m3_guild_bounty) · idempotent · สำรอง _ก่อนรอบ159
import os, shutil, sys

MARK = "★ รอบ 159 ★"
os.chdir(sys.argv[1] if len(sys.argv) > 1 else ".")


def patch(path, pairs):
    raw = open(path, encoding="utf-8", newline="").read()
    crlf = "\r\n" in raw
    txt = raw.replace("\r\n", "\n")
    if MARK in txt:
        print("skip (already)", path)
        return
    for old, new in pairs:
        if txt.count(old) != 1:
            raise SystemExit("anchor not unique/missing in %s: %r" % (path, old[:60]))
        txt = txt.replace(old, new)
    base, ext = os.path.splitext(path)
    bak = "%s_ก่อนรอบ159%s.bak" % (base, ext)
    if not os.path.exists(bak):
        shutil.copy2(path, bak)
    if crlf:
        txt = txt.replace("\n", "\r\n")
    open(path, "w", encoding="utf-8", newline="").write(txt)
    print("patched", path)


# 1) บอร์ดกิลด์: ส่งใบใดก็ได้ครั้งแรก → ธง guild_first_bounty (เงื่อนไขเควส m3)
patch("scripts/core/bounty_board.gd", [(
    "\tpoints += pts\n\ttotal_turned_in += 1\n",
    "\tpoints += pts\n\ttotal_turned_in += 1\n"
    "\tPlayerState.set_flag(FIRST_BOUNTY_FLAG)   # ★ รอบ 159 ★ เควส m3_guild_bounty «ใบประกาศใบแรก»\n",
), (
    "const POINTS_BOSS := 3\n",
    "const POINTS_BOSS := 3\n"
    "## ★ รอบ 159 ★ ธงที่ตั้งเมื่อส่งใบประกาศใบแรก (เควสบท 1 «ใบประกาศใบแรก» ใช้เป็นเงื่อนไข)\n"
    "const FIRST_BOUNTY_FLAG := &\"guild_first_bounty\"\n",
)])

# 2) เซฟเก่าที่เคยส่งใบประกาศไปแล้ว → ตั้งธงให้ (โหลดธงเสร็จแล้วค่อยเช็ค)
patch("scripts/core/player_state.gd", [(
    "\tvar returned_cards := _return_moved_cards()\n",
    "\t# ★ รอบ 159 ★ เซฟเก่าที่ส่งใบประกาศไปแล้ว นับว่าผ่านเงื่อนไข «ใบประกาศใบแรก»\n"
    "\tif bounties != null and bounties.total_turned_in > 0:\n"
    "\t\tstory_flags[BountyBoard.FIRST_BOUNTY_FLAG] = true\n"
    "\tvar returned_cards := _return_moved_cards()\n",
)])

# 3) NPC: มีเควสใหม่ให้รับ → ชวนรับก่อนบอกความคืบหน้าเควสที่ค้าง
#    (บียอร์นถือ m3 ค้างไว้ได้นาน — ไม่งั้น m11 ราชาวุ้นจะไม่ถูกเสนอจนกว่าจะส่ง m3)
#    + จบเควส m3 แล้วเปิดหน้าขั้นกิลด์ (รอบ 158) ให้ดูต่อ
patch("scripts/world/npc.gd", [(
    "\t# 2) มีเควสที่รับไว้แล้วแต่ยังไม่ครบ -> บอกความคืบหน้า\n",
    "\t# ★ รอบ 159 ★ มีเควสใหม่ให้รับ → ชวนก่อน (เดิมเควสที่ค้างอยู่บังเควสใหม่ของ NPC คนเดียวกัน)\n"
    "\tfor qid in story_quests:\n"
    "\t\tif qlog.can_accept(qid, lv):\n"
    "\t\t\tawait _ask_accept(GameData.get_quest(qid))\n"
    "\t\t\treturn true\n\n"
    "\t# 2) มีเควสที่รับไว้แล้วแต่ยังไม่ครบ -> บอกความคืบหน้า\n",
), (
    "\t\tawait _after_turn_in(q)\n",
    "\t\tawait _after_turn_in(q)\n"
    "\t\t# ★ รอบ 159 ★ จบเควส «ใบประกาศใบแรก» → เปิดหน้าขั้นกิลด์ให้ดูต่อทันที\n"
    "\t\tif q.id == GUILD_INTRO_QUEST and is_instance_valid(self):\n"
    "\t\t\tEvents.guild_rank_opened.emit()\n",
), (
    "const MENU_BOUNTY := \"ใบประกาศล่า\"",
    "## ★ รอบ 159 ★ เควสบท 1 ที่พาผู้เล่นมารู้จักใบประกาศล่า + ขั้นกิลด์\n"
    "const GUILD_INTRO_QUEST := &\"m3_guild_bounty\"\n"
    "const MENU_BOUNTY := \"ใบประกาศล่า\"",
)])

# 4) พรอนเทรา: บียอร์นให้เควส m3
patch_path = "scenes/maps/prontera_town.tscn"
raw = open(patch_path, encoding="utf-8", newline="").read()
old = 'quest_ids = Array[StringName]([&"m11_king_poring"])'
if "m3_guild_bounty" in raw:
    print("skip (already)", patch_path)
else:
    assert raw.count(old) == 1, "bjorn quest_ids anchor"
    bak = "scenes/maps/prontera_town_ก่อนรอบ159.tscn.bak"
    if not os.path.exists(bak):
        shutil.copy2(patch_path, bak)
    raw = raw.replace(old, 'quest_ids = Array[StringName]([&"m11_king_poring", &"m3_guild_bounty"])')
    open(patch_path, "w", encoding="utf-8", newline="").write(raw)
    print("patched", patch_path)
