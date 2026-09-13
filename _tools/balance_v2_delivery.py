"""Package rendered QA frames; never changes runtime artwork."""
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
out=root/'output/balance_v2'
frames=[]
for i in range(32):
    left=Image.open(out/f'idle_left_{i:02}.png').convert('RGB').crop((730,265,1070,580))
    right=Image.open(out/f'idle_right_{i:02}.png').convert('RGB').crop((240,265,580,580))
    frame=Image.new('RGB',(680,315),(12,22,37))
    frame.paste(left,(0,0))
    frame.paste(right,(340,0))
    frames.append(frame)
frames[0].save(out/'runeblade_idle.gif',save_all=True,append_images=frames[1:],duration=125,loop=0,disposal=2)
style=root/'Sprites/skill_icons/STYLE.md'
text=style.read_text(encoding='utf-8')
start=text.index('ไฟล์ `*.png` ทั้ง 17')
end=text.index('\n\nUI ต้องซ่อน',start)
text=text[:start]+'''ไฟล์ทั้ง 17 ภาพสร้างด้วย built-in ImageGen แล้วตัดเฉพาะพื้นนอกกรอบวงกลมด้วยโค้ดตามคำอนุมัติของผู้ใช้ “ใช้โค้ดตัดพื้นหลังเดิม” ภาพใช้งานเป็น **PNG RGBA 256×256 โปร่งใสจริง** พร้อมขอบ alpha ไล่ระดับและ mipmaps ภาพวาดภายในเหรียญคงเดิม ต้นฉบับก่อนตัดอยู่ `output/balance_v2/icons_original/`; ผลตรวจ alpha อยู่ `output/balance_v2/alpha_report.json`; ภาพเรนเดอร์จากเกมอยู่ `output/balance_v2/skill_icon_gallery.png`.

รายการภาพและ prompt ต้นฉบับ: `output/balance/icon_manifest.json`. `_tools/install_balance_icons.py` เป็นตัวติดตั้งเก่าและป้องกันการเขียนทับภาพโปร่งใสแล้ว อย่ารันตัวสร้างแพตช์ V2 ซ้ำ เพราะเป็นสคริปต์ย้ายข้อมูลครั้งเดียว ไม่ใช่ระบบ build.'''+text[end:]
style.write_text(text,encoding='utf-8')
print('Saved 32-frame paired idle preview and updated icon contract.')
