# ★ รอบ 162 ★ แพตช์ไฟล์เดิม (รันซ้ำได้ — ข้ามจุดที่แก้แล้ว) · สำรองไว้ที่ _to_delete/ก่อนรอบ162/
import os,sys,shutil
ROOT=sys.argv[1] if len(sys.argv)>1 else "."
BK=os.path.join(ROOT,"_to_delete","ก่อนรอบ162")
LANG_HINT_OLD='"English: บทเควสและบทพูด NPC แปลแล้ว · เมนู/ไอเทม/สกิลยังเป็นภาษาไทย (ไฟล์แปล locale/en.po)"'
LANG_HINT_NEW='"English: แปลทั้งเกมแล้ว · ถ้าเจอข้อความไทยค้าง เกมจะจดไว้ที่ user://untranslated_en.txt"'
PATCHES={
 "scripts/ui/system_window.gd":[
  ('_voice_btn.text = "เปิด" if Game.voice.enabled else "ปิด"','_voice_btn.text = Loc.on_off(Game.voice.enabled)'),
  ('_sfx_btn.text = "เปิด" if Game.sfx.enabled else "ปิด"','_sfx_btn.text = Loc.on_off(Game.sfx.enabled)'),
  ('_music_btn.text = "เปิด" if Game.music.enabled else "ปิด"','_music_btn.text = Loc.on_off(Game.music.enabled)'),
  ('\t\tlb.pressed.connect(func(): Loc.set_locale(code))\n','\t\tlb.pressed.connect(func():\n\t\t\tLoc.set_locale(code)   # ★ รอบ 162 ★ ปุ่มเปิด/ปิดเปลี่ยนภาษาตาม\n\t\t\t_refresh_voice()\n\t\t\t_refresh_sfx()\n\t\t\t_refresh_music())\n'),
  (LANG_HINT_OLD,LANG_HINT_NEW),
 ],
 "scripts/ui/touch_controls.gd":[
  ('\t\tMode.OFF: return "ปิด"','\t\tMode.OFF: return Loc.on_off(false)'),
 ],
 "data/items/guard.tres":[
  ('display_name = "การ์ด"\n','display_name = "โล่การ์ด"\n'),   # "การ์ด" = การ์ดมอน · โล่ชื่อซ้ำ → แปลอังกฤษแยกไม่ได้
 ],
}
changed=0
for rel,reps in PATCHES.items():
    p=os.path.join(ROOT,rel)
    raw=open(p,"rb").read().decode("utf-8")
    crlf="\r\n" in raw
    s=raw.replace("\r\n","\n")
    new=s
    for old,rep in reps:
        if rep in new: continue
        if old not in new:
            print("!! ไม่เจอจุดแพตช์ใน",rel,":",old[:60]); continue
        new=new.replace(old,rep,1)
    if new!=s:
        b=os.path.join(BK,rel); os.makedirs(os.path.dirname(b),exist_ok=True)
        if not os.path.exists(b): shutil.copy2(p,b)
        out=new.replace("\n","\r\n") if crlf else new
        open(p,"wb").write(out.encode("utf-8")); changed+=1; print("แก้",rel)
print("เสร็จ: แก้",changed,"ไฟล์")
