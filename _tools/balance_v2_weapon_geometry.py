from pathlib import Path
from PIL import Image
import numpy as np,json,re,math
ROOT=Path(__file__).resolve().parents[1]
poses=json.loads((ROOT/'output/balance_v2/idle_hand_tracking.json').read_text())
paths=sorted((ROOT/'Sprites/player/runeblade/idle').glob('frame_*.png'))
ref=np.asarray(Image.open(paths[0]).convert('RGB'),dtype=np.float32)
template=ref[384:414,443:471]
angles=[]
for p,pose in zip(paths,poses):
    arr=np.asarray(Image.open(p).convert('RGB'),dtype=np.float32)
    best=(float('inf'),0,0)
    for dy in range(-15,16):
        for dx in range(-15,16):
            score=float(np.mean((arr[384+dy:414+dy,443+dx:471+dx]-template)**2))
            if score<best[0]:best=(score,dx,dy)
    vec=(pose[0]-(457+best[1]),pose[1]-(400+best[2]))
    angle=math.degrees(math.atan2(vec[1],vec[0])-math.atan2(35,5))
    angles.append(round(max(-8,min(8,angle)),2))
text='extends RefCounted\n\n# Authored 32-frame Idle: source-pixel grip and measured wrist rotation.\nconst IDLE := [\n'
for p,a in zip(poses,angles): text+=f'\tVector3({p[0]}, {p[1]}, {a}),\n'
text+=']\n'
(ROOT/'scripts/entities/runeblade_hand_track.gd').write_text(text,encoding='utf-8')

geometry={}
for p in (ROOT/'data/items').glob('*.tres'):
    s=p.read_text(encoding='utf-8')
    if not re.search(r'^type = 1$',s,re.M):continue
    resources={m[1]:m[0] for m in re.findall(r'\[ext_resource type="Texture2D"[^\]\n]*path="([^"]+)"[^\]\n]*id="([^"]+)"',s)}
    tex=re.search(r'^equip_texture = ExtResource\("([^"]+)"\)',s,re.M)
    grip=re.search(r'equip_grip = Vector2\(([^,]+), ([^)]+)\)',s)
    if not tex or not grip:continue
    path=resources.get(tex[1]); asset=ROOT/path.removeprefix('res://') if path else None
    if not asset or not asset.exists():continue
    im=Image.open(asset).convert('RGBA');arr=np.asarray(im)
    yy,xx=np.where(arr[:,:,3]>180)
    gx,gy=float(grip[1]),float(grip[2])
    index=np.argmax((xx-gx)**2+(yy-gy)**2)
    geometry[path]=[int(xx[index]),int(yy[index]),gx,gy]
out='extends RefCounted\n# Actual blade-tip and grip pixels, read from existing equipped weapon art.\nconst POINTS := {\n'
for path,g in geometry.items():out+=f'\t"{path}": Vector4({g[0]}, {g[1]}, {g[2]}, {g[3]}),\n'
out+='}\n'
(ROOT/'scripts/entities/weapon_blade_geometry.gd').write_text(out,encoding='utf-8')
print('Tracked idle rotation:',angles,'; weapon geometries:',len(geometry))
