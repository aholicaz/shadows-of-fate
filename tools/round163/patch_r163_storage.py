# รอบ 163 — คลังล้นจอ: วางหน้าต่างซ้ำหลังจัดวางเฟรมแรก (idempotent · สำรอง _ก่อนรอบ163)
import os, shutil, sys
os.chdir(sys.argv[1] if len(sys.argv) > 1 else ".")
p = "scripts/ui/storage_window.gd"
raw = open(p, encoding="utf-8", newline="").read()
crlf = "\r\n" in raw
s = raw.replace("\r\n", "\n")
if "★ รอบ 163 ★" in s:
    print("skip", p); raise SystemExit
old_show = "func show_window() -> void:\n\t_clear_selection()\n\tsuper.show_window()\n\t_place()\n"
new_show = ("func show_window() -> void:\n\t_clear_selection()\n\tsuper.show_window()\n\t_place()\n"
            "\t# ★ รอบ 163 ★ เฟรมแรกขนาดขั้นต่ำของข้อความตัดบรรทัดยังไม่นิ่ง → หน้าต่างโตเกินจอ (สูง 978) → วางซ้ำ\n"
            "\tfor i in 2:\n\t\tawait get_tree().process_frame\n\t\tif not is_instance_valid(self) or not visible:\n\t\t\treturn\n\t\t_place()\n")
old_place = "\tsize = Vector2(minf(1320.0, viewport_size.x - 40.0), minf(680.0, viewport_size.y - 40.0))\n"
new_place = old_place + "\treset_size()   # ★ รอบ 163 ★ หดกลับก่อน แล้วค่อยตั้งขนาดใหม่ (Container ไม่หดเอง)\n" + old_place
for a, b in [(old_show, new_show), (old_place, new_place)]:
    assert s.count(a) == 1, a[:50]
    s = s.replace(a, b)
bak = "scripts/ui/storage_window_ก่อนรอบ163.gd.bak"
if not os.path.exists(bak): shutil.copy2(p, bak)
if crlf: s = s.replace("\n", "\r\n")
open(p, "w", encoding="utf-8", newline="").write(s)
print("patched", p)
