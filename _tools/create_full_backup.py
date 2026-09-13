"""Create a verified ZIP64 snapshot, preserving worktree and Git history."""
from pathlib import Path
import os,json,zipfile,time,hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'output/backups'
OUT.mkdir(parents=True,exist_ok=True)
target=OUT/'ShadowsOfFate_2026-09-13.zip'
if target.exists(): raise SystemExit('Backup already exists; refusing to overwrite.')
excluded={'.godot','build','เว็บพร้อมอัพ','__pycache__'}
files=[]
for base,dirs,names in os.walk(ROOT):
    dirs[:]=[d for d in dirs if d not in excluded and Path(base)/d!=OUT]
    for name in names:
        p=Path(base)/name
        if '.git' in p.parts and (name.startswith('tmp_') or name.endswith('.lock')): continue
        if p.is_symlink(): raise RuntimeError('Symlink needs explicit handling: '+str(p))
        files.append(p)
total=sum(p.stat().st_size for p in files)
manifest=[]
done=0
last=time.monotonic()
with zipfile.ZipFile(target,'x',compression=zipfile.ZIP_DEFLATED,compresslevel=1,allowZip64=True) as z:
    for p in files:
        before=p.stat()
        rel=p.relative_to(ROOT).as_posix()
        # Already compressed artwork, archives and Git objects gain little from recompression.
        method=zipfile.ZIP_DEFLATED if p.suffix.lower() in {'.gd','.tres','.tscn','.json','.md','.py','.txt','.csv','.cfg','.godot','.svg','.html'} else zipfile.ZIP_STORED
        z.write(p,'ShadowsOfFate/'+rel,compress_type=method)
        after=p.stat()
        if (before.st_size,before.st_mtime_ns)!=(after.st_size,after.st_mtime_ns):
            raise RuntimeError('File changed during backup: '+rel)
        manifest.append({'path':rel,'bytes':before.st_size,'mtime_ns':before.st_mtime_ns})
        done+=before.st_size
        if time.monotonic()-last>20:
            print(f'Archived {done/2**30:.2f}/{total/2**30:.2f} GiB',flush=True)
            last=time.monotonic()
    z.writestr('BACKUP_MANIFEST.json',json.dumps(manifest,ensure_ascii=False,indent=2))
    z.writestr('RESTORE.txt','Extract the ShadowsOfFate folder and open project.godot using Godot 4.7.2. The .godot cache regenerates. Git history and uncommitted files are included. Excluded: .godot, build, web build output, __pycache__, output/backups. This is a project backup; external user save slots are not included.\n')
print('ZIP created. Verifying every entry CRC...',flush=True)
with zipfile.ZipFile(target) as z:
    bad=z.testzip()
    if bad: raise RuntimeError('CRC mismatch: '+bad)
with target.open('rb') as f: checksum=hashlib.file_digest(f,'sha256').hexdigest()
result=dict(path=str(target),files=len(files),source_bytes=total,zip_bytes=target.stat().st_size,sha256=checksum,crc_verified=True)
(OUT/'ShadowsOfFate_2026-09-13.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result),flush=True)
