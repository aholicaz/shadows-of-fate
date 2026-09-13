"""Read-only source image and Git payload inventory."""
from pathlib import Path
import json, subprocess
from collections import defaultdict
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'output/maintenance_2026-09-13'
OUT.mkdir(parents=True,exist_ok=True)
rows=[]
groups=defaultdict(lambda: [0,0,0])
for p in (ROOT/'Sprites').rglob('*'):
    if p.suffix.lower() not in ('.png','.webp','.jpg','.jpeg'): continue
    with Image.open(p) as im: w,h=im.size
    rel=p.relative_to(ROOT).as_posix()
    group='/'.join(rel.split('/')[:3])
    size=p.stat().st_size
    rows.append(dict(path=rel,bytes=size,width=w,height=h,rgba_mib=round(w*h*4/2**20,2)))
    groups[group][0]+=1
    groups[group][1]+=size
    groups[group][2]+=w*h*4
paths=subprocess.check_output(['git','ls-files','-z','--cached','--others','--exclude-standard'],cwd=ROOT).decode('utf-8').split('\0')
large=[]
total=0
for rel in set(paths):
    p=ROOT/rel
    if not rel or not p.is_file(): continue
    size=p.stat().st_size
    total+=size
    if size>50*2**20: large.append(dict(path=rel,mib=round(size/2**20,2)))
report=dict(images=sorted(rows,key=lambda r:-r['bytes']),groups={k:dict(count=v[0],source_mib=round(v[1]/2**20,2),rgba_mib=round(v[2]/2**20,2)) for k,v in sorted(groups.items(),key=lambda kv:-kv[1][1])},git_candidate_mib=round(total/2**20,2),git_files_over_50_mib=large)
(OUT/'asset_sizes.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k!='images'},ensure_ascii=False,indent=2))
