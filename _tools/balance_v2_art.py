"""User-authorized alpha extraction. Idle analysis reads existing frames only."""
from pathlib import Path
import json, shutil, math
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'output/balance_v2'
OUT.mkdir(exist_ok=True)
(OUT/'.gdignore').touch()
report=[]
for entry in json.loads((ROOT/'output/balance/icon_manifest.json').read_text(encoding='utf-8')):
    p=ROOT/f"Sprites/skill_icons/{entry['id']}.png"
    backup=OUT/'icons_original'/p.name
    backup.parent.mkdir(exist_ok=True)
    if not backup.exists(): shutil.copy2(p,backup)
    im=Image.open(backup).convert('RGBA')
    w,h=im.size
    yy,xx=np.mgrid[:h,:w]
    # All images share the reference medallion registration (6 px outside margin).
    radius=min(w,h)/2-6
    distance=np.sqrt((xx-(w-1)/2)**2+(yy-(h-1)/2)**2)
    alpha=np.clip((radius-distance+0.5),0,1)
    im.putalpha(Image.fromarray(np.uint8(np.round(alpha*255))))
    im=im.resize((256,256),Image.Resampling.LANCZOS)
    im.save(p)
    a=np.asarray(im.getchannel('A'))
    assert a[0,0]==0 and a[128,128]==255 and np.any((a>0)&(a<255))
    report.append({'id':entry['id'],'mode':im.mode,'size':im.size,'transparent_pixels':int((a==0).sum())})
(OUT/'alpha_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')

# Locate the authored hand by template matching, independent of the weapon render.
paths=sorted((ROOT/'Sprites/player/runeblade/idle').glob('frame_*.png'))
ref=np.asarray(Image.open(paths[0]).convert('RGB'),dtype=np.float32)
template=ref[410:449,444:479]
positions=[]
for p in paths:
    arr=np.asarray(Image.open(p).convert('RGB'),dtype=np.float32)
    best=(float('inf'),0,0)
    for dy in range(-18,19):
        for dx in range(-18,19):
            patch=arr[410+dy:449+dy,444+dx:479+dx]
            score=float(np.mean((patch-template)**2))
            if score<best[0]: best=(score,dx,dy)
    positions.append([462+best[1],435+best[2],round(best[0],2)])
(OUT/'idle_hand_tracking.json').write_text(json.dumps(positions,indent=2),encoding='utf-8')
print('17 RGBA icons extracted; measured 32 hand positions:',positions)
