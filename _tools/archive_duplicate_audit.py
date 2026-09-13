"""Prove archive duplicates against retained workspace files; read-only."""
from pathlib import Path
from collections import defaultdict
import hashlib,json,os
root=Path(__file__).resolve().parents[1]
archive=root/'_to_delete'
sizes=defaultdict(list)
for p in archive.rglob('*'):
    if p.is_file() and not p.is_symlink() and p.name!='.gdignore': sizes[p.stat().st_size].append(p)
retained=defaultdict(list)
for base,dirs,files in os.walk(root):
    dirs[:]=[d for d in dirs if d not in ('.git','.godot','_to_delete','__pycache__','build') and not (Path(base)/d).is_symlink()]
    for name in files:
        p=Path(base)/name
        if p.is_symlink(): continue
        if p.stat().st_size in sizes: retained[p.stat().st_size].append(p)
def digest(p):
    with p.open('rb') as f: return hashlib.file_digest(f,'sha256').hexdigest()
matches=[]
for size,paths in retained.items():
    hashes={digest(p):p for p in paths}
    for p in sizes[size]:
        h=digest(p)
        if h in hashes: matches.append(dict(delete=str(p),retain=str(hashes[h]),sha256=h,bytes=size))
out=root/'output/maintenance_2026-09-13/archive_duplicates.json'
out.write_text(json.dumps(matches,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(dict(verified_duplicates=len(matches),mib=round(sum(x['bytes'] for x in matches)/2**20,2))))
