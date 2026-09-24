# ★ รอบ 162 ★ สร้าง locale/en_game.po จาก names_en.py + out/*.json
# วิธีเพิ่มคำแปล: python tools/round162/extract_r162.py  → ดู tools/round162/todo2.json (ข้อความไทยที่ยังไม่มีคำแปล)
#                 แปลแล้วใส่ไฟล์ใหม่ tools/round162/out/extra_<ชื่อ>.json  {"ไทย": "English"}  (คง %s %d [tag] \n ให้ครบ)
#                 python tools/round162/build_po.py   → เขียน locale/en_game.po ใหม่ (รันซ้ำได้)
import json,sys,re,os
HERE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.abspath(os.path.join(HERE,"..",".."))
sys.path.insert(0,HERE)
from names_en import NAMES,TEMPLATES
allm={}
out=os.path.join(HERE,"out")
for f in sorted(os.listdir(out)):
    if f.startswith("chunk") and f.endswith(".json"): allm.update(json.load(open(os.path.join(out,f),encoding="utf-8")))
for f in sorted(os.listdir(out)):
    if f.startswith("extra") and f.endswith(".json"): allm.update(json.load(open(os.path.join(out,f),encoding="utf-8")))
allm.update(NAMES); allm.update(TEMPLATES)
po=open(os.path.join(ROOT,"locale","en.po"),encoding="utf-8").read().replace("\r\n","\n")
have=set(json.loads('"'+m+'"') for m in re.findall(r'^msgid "(.*)"$',po,re.M))
allm={k:v for k,v in allm.items() if k not in have and k.strip()}
SPEC=re.compile(r"%[-+ 0#]*\d*(?:\.\d+)?[sdifxXc%]")
bad=[k for k,v in allm.items() if SPEC.findall(k)!=SPEC.findall(v) or k.count("\n")!=v.count("\n")]
for k in bad: print("!! %s/บรรทัดไม่ตรง:",repr(k[:60]))
def q(s): return json.dumps(s,ensure_ascii=False)
with open(os.path.join(ROOT,"locale","en_game.po"),"w",encoding="utf-8",newline="\n") as f:
    f.write('msgid ""\nmsgstr ""\n"Content-Type: text/plain; charset=UTF-8\\n"\n"Language: en\\n"\n\n')
    for k in sorted(allm): f.write(f"msgid {q(k)}\nmsgstr {q(allm[k])}\n\n")
print("locale/en_game.po:",len(allm),"ข้อความ")
