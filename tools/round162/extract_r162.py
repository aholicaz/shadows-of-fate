# รอบ 162 — ดึงข้อความไทยทั้งเกมที่ยังไม่มีคำแปลใน locale/*.po
import re,os,json,sys
TH=re.compile(r"[฀-๿]")
def po_ids(p):
    ids=set()
    if not os.path.exists(p): return ids
    cur=None; mode=None
    for line in open(p,encoding="utf-8"):
        line=line.rstrip("\r\n")
        if line.startswith("msgid "): cur=[json.loads(line[6:])]; mode="id"
        elif line.startswith("msgstr "):
            if cur is not None: ids.add("".join(cur))
            mode="str"
        elif line.startswith('"') and mode=="id": cur.append(json.loads(line))
    return ids
def unesc_godot(s):
    out=[];i=0
    while i<len(s):
        c=s[i]
        if c=="\\" and i+1<len(s):
            n=s[i+1]; out.append({"n":"\n","t":"\t","\"":"\"","\\":"\\","r":""}.get(n,"\\"+n)); i+=2
        else: out.append(c); i+=1
    return "".join(out).replace("\r","")
STR=re.compile(r'(&?)"((?:[^"\\]|\\.)*)"',re.S)
found={}
def add(s,src):
    s=s.replace("\r","")
    if not TH.search(s): return
    found.setdefault(s,src)
for root in ("data","scenes"):
    for r,ds,fs in os.walk(root):
        for f in fs:
            if f.endswith((".tres",".tscn")):
                p=os.path.join(r,f); t=open(p,encoding="utf-8").read()
                for m in STR.finditer(t):
                    if m.group(1): continue
                    add(unesc_godot(m.group(2)),p)
SKIP_CALL=re.compile(r'\b(print|prints|printerr|push_error|push_warning|assert|print_debug)\s*\(')
for r,ds,fs in os.walk("scripts"):
    if r.startswith(("scripts/tools","scripts/example")): continue
    for f in fs:
        if not f.endswith(".gd"): continue
        p=os.path.join(r,f)
        for line in open(p,encoding="utf-8"):
            st=line.strip()
            if st.startswith("#") or SKIP_CALL.search(line): continue
            for m in STR.finditer(line):
                pre=line[:m.start()]
                if "#" in pre and pre.count('"')%2==0 and pre.find("#")>=0:
                    # '#' outside a string before this literal => comment
                    q=0;cm=False
                    for ch in pre:
                        if ch=='"': q^=1
                        elif ch=="#" and not q: cm=True;break
                    if cm: continue
                if m.group(1): continue
                add(unesc_godot(m.group(2)),p)
have=set()
for p in os.listdir("locale"):
    if p.endswith(".po"): have|=po_ids(os.path.join("locale",p))
have={h.replace("\r","") for h in have}
import re as _re
todo={s:src for s,src in found.items() if s not in have and s.strip() not in have and not src.endswith("monster_quest_catalog.gd") and "[sub_resource" not in s and not _re.fullmatch(r"อิกดราซิล ชั้น \d+",s) and not (s.startswith("การ์ด") and s[5:] in have)}
json.dump([{"s":s,"src":src} for s,src in sorted(todo.items(),key=lambda x:(x[1],x[0]))],open("tools/round162/todo2.json","w",encoding="utf-8"),ensure_ascii=False,indent=0)
print("found",len(found),"have",len(have),"todo",len(todo),"chars",sum(len(s) for s in todo))
import collections
c=collections.Counter(src.split("/")[0]+"/"+src.split("/")[1] for src in todo.values()); print(c.most_common())
