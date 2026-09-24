# รอบ 163 — HUD เควสหลัก + เควสรอง (idempotent · สำรอง _ก่อนรอบ163)
import os, shutil, sys
here = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1] if len(sys.argv) > 1 else ".")
p = "scripts/ui/hud.gd"
raw = open(p, encoding="utf-8", newline="").read()
crlf = "\r\n" in raw
s = raw.replace("\r\n", "\n")
if "★ รอบ 163 ★ เควสหลัก" in s:
    print("skip", p); raise SystemExit
a = s.index("func _refresh_quest() -> void:\n")
b = s.index("## บทของเควสจาก id")
block = open(os.path.join(here, "hud_quest_block.gd.txt"), encoding="utf-8").read()
s = s[:a] + block + s[b:]
bak = "scripts/ui/hud_ก่อนรอบ163.gd.bak"
if not os.path.exists(bak): shutil.copy2(p, bak)
if crlf: s = s.replace("\n", "\r\n")
open(p, "w", encoding="utf-8", newline="").write(s)
print("patched", p)
