# รอบ 163 — ui_manager: โรงตีเหล็ก + บอร์ดใบประกาศ · npc: เมนูใบประกาศเปิดหน้าต่าง (idempotent · สำรอง _ก่อนรอบ163)
import os, shutil, sys
os.chdir(sys.argv[1] if len(sys.argv) > 1 else ".")
MARK = "★ รอบ 163 ★"

def patch(p, pairs):
    raw = open(p, encoding="utf-8", newline="").read()
    crlf = "\r\n" in raw
    s = raw.replace("\r\n", "\n")
    if MARK in s:
        print("skip", p); return
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:60])
        s = s.replace(a, b)
    base, ext = os.path.splitext(p)
    bak = "%s_ก่อนรอบ163%s.bak" % (base, ext)
    if not os.path.exists(bak): shutil.copy2(p, bak)
    if crlf: s = s.replace("\n", "\r\n")
    open(p, "w", encoding="utf-8", newline="").write(s)
    print("patched", p)

patch("scripts/ui/ui_manager.gd", [
    ("\tif OS.is_debug_build(): _add_window(&\"gm\", GMWindow.new(), Vector2(340, 60))\n",
     "\tif OS.is_debug_build(): _add_window(&\"gm\", GMWindow.new(), Vector2(340, 60))\n"
     "\t# ★ รอบ 163 ★ โรงตีเหล็ก (ตีบวก · เจาะรู · รูที่ 3 · คราฟต์ ในหน้าต่างเดียว) — ย้ายหน้าคราฟต์เดิมเข้าไปเป็นแท็บ\n"
     "\tvar smith := BlacksmithWindow.new()\n"
     "\t_add_window(&\"blacksmith\", smith, Vector2(80, 40))\n"
     "\tsmith.host_craft(windows[&\"craft\"] as CraftWindow)\n"
     "\t# ★ รอบ 163 ★ บอร์ดใบประกาศล่า (แทนเมนูในกล่องสนทนา)\n"
     "\t_add_window(&\"bounty\", BountyBoardWindow.new(), Vector2(110, 40))\n"),
    ("func _on_refine_opened() -> void:\n\topen(&\"refine\")\n",
     "func _on_refine_opened() -> void:\n\topen_blacksmith(\"refine\")   # ★ รอบ 163 ★ เดิม open(&\"refine\")\n\n\n"
     "## ★ รอบ 163 ★ เปิดโรงตีเหล็กที่แท็บ refine · socket · third · craft\n"
     "func open_blacksmith(tab_id: String) -> void:\n"
     "\tclose_all()\n"
     "\tvar w := windows.get(&\"blacksmith\") as BlacksmithWindow\n"
     "\tif w != null:\n"
     "\t\tw.open_tab(tab_id)\n\n\n"
     "## ★ รอบ 163 ★ บอร์ดใบประกาศของเมือง (NPC ที่ติ๊ก has_bounty_board)\n"
     "func open_bounty_board(town: StringName) -> void:\n"
     "\tclose_all()\n"
     "\tvar w := windows.get(&\"bounty\") as BountyBoardWindow\n"
     "\tif w != null:\n"
     "\t\tw.open_board(town)\n"),
    ("func _on_craft_opened() -> void:\n\tclose_all()\n\topen(&\"craft\")\n",
     "func _on_craft_opened() -> void:\n\topen_blacksmith(\"craft\")   # ★ รอบ 163 ★ คราฟต์เป็นแท็บในโรงตีเหล็ก\n"),
    ("func _on_socket_opened() -> void:\n\topen(&\"socket\")\n",
     "func _on_socket_opened() -> void:\n\topen_blacksmith(\"socket\")   # ★ รอบ 163 ★\n"),
    ("func open(id: StringName) -> void:\n",
     "func open(id: StringName) -> void:\n"
     "\tif id == &\"craft\":   # ★ รอบ 163 ★ หน้าคราฟต์อยู่ในโรงตีเหล็กแล้ว\n"
     "\t\topen_blacksmith(\"craft\")\n"
     "\t\treturn\n"),
    ("\tfor w: GameWindow in windows.values():\n\t\tif w.visible:\n\t\t\treturn true\n\treturn false\n",
     "\tfor w: GameWindow in windows.values():\n\t\tif w.is_visible_in_tree():   # ★ รอบ 163 ★ หน้าคราฟต์ฝังอยู่ในโรงตีเหล็ก (visible แต่พ่อซ่อน)\n\t\t\treturn true\n\treturn false\n"),
    ("\t\tif w.visible and w.get_global_rect().has_point(point):\n",
     "\t\tif w.is_visible_in_tree() and w.get_global_rect().has_point(point):   # ★ รอบ 163 ★\n"),
])

patch("scripts/world/npc.gd", [
    ("\tif chosen == MENU_BOUNTY:   # ★ รอบ 128 ★\n\t\tawait _bounty_menu()\n\t\treturn\n",
     "\tif chosen == MENU_BOUNTY:   # ★ รอบ 128 ★\n\t\tUI.open_bounty_board(PlayerState.current_map_id)   # ★ รอบ 163 ★ หน้าต่างบอร์ด (เมนูเดิม _bounty_menu ยังอยู่)\n\t\treturn\n"),
])
