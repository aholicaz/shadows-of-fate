"""Register the artist's September 18 PNGs; never resample or overwrite the art."""
from pathlib import Path
import hashlib, json, re, shutil, statistics
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/sep18_integration'
# Idle, walking cycle, attack/contact, hit, death; all numbers are source frames (1-based).
CONFIG = {
 'crystal_stag': ((1,6),(9,24),(1,15,9),(3,8),(9,32),(500,420,640,500)),
 'reflection': ((1,8),(9,32),(3,24,7),(3,8),(9,32),(500,280,570,380)),
 'garden_keeper': ((1,8),(9,24),(4,27,9),(3,8),(9,32),(525,300,600,410)),
 'light_eater_bloom': ((1,8),(9,24),(3,28,23),(4,10),(11,32),(500,480,620,570)),
 'light_moth': ((1,6),(9,24),(4,28,15),(3,8),(9,32),(410,490,480,560)),
 'hollow_moth': ((1,8),(9,32),(2,28,15),(3,8),(9,32),(370,390,450,480)),
}

def backup(path):
    dst=OUT/'before'/path.relative_to(ROOT)
    if not dst.exists():
        dst.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(path,dst)

def image(path): return Image.open(path).convert('RGBA')

def register(paths, frames, roi):
    """Track a reviewed torso patch, excluding feet, weapon, wing and tail edges.
    Search Y to tolerate gait, but only compensate horizontal whole-body drift.
    A three-tap filter leaves the original vertical gait completely intact.
    """
    def small(p):
        a=np.asarray(image(p).resize((278,209)),dtype=np.float32)/255
        return a[:,:,:3]*a[:,:,3:4]
    base=small(paths[0]); x0,y0,x1,y1=[round(x/4) for x in roi]
    patch=base[y0:y1,x0:x1]; raw=[]
    for f in frames:
        arr=small(paths[f-1]); candidates=[]
        for dx in range(-36,37):
            for dy in range(-12,13):
                sample=arr[y0+dy:y1+dy,x0+dx:x1+dx]
                if sample.shape==patch.shape:
                    candidates.append((float(np.mean((sample-patch)**2)),dx))
        raw.append(min(candidates)[1]*4)
    # Do not blend the last raw position into the first: drifting sheets are not
    # periodic until registration has removed their accumulated translation.
    smooth=[raw[0]]+[round((raw[i-1]+2*raw[i]+raw[i+1])/4) for i in range(1,len(raw)-1)]+[raw[-1]]
    return dict(zip(frames,smooth)),raw

def set_field(text,key,value):
    text=re.sub(r'^'+key+r' = .*?(?=^[A-Za-z_]\w* = |^\[|\Z)','',text,flags=re.M|re.S)
    return text.rstrip()+'\n'+key+' = '+value+'\n'

def install():
    hashes={}; report={}
    OUT.mkdir(parents=True,exist_ok=True)
    for mid in CONFIG:
        dirs={}
        for p in sorted((ROOT/'Sprites/monsters/spriteflow'/mid).rglob('*.png')):
            d=p.parent.relative_to(ROOT).as_posix()
            dirs.setdefault(d,{'names':[]})['names'].append(p.name)
        sources={}
        for d,info in dirs.items():
            paths=[ROOT/d/name for name in info['names']]
            key='idle' if ('idle' in d or (mid=='crystal_stag' and 'asset-' in d)) else 'hit' if ('hit' in d and 'three-hit' not in d) else 'attack'
            assert key not in sources, f'{mid}: review additional {key} source before importing'
            assert len(paths)==32, f'{mid}: expected 32 original frames in {d}'
            sources[key]=paths
            for p in paths: hashes[p.relative_to(ROOT).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
        idle,walk,attack,hit,die,roi=CONFIG[mid]
        spec={'Idle':('idle',*idle,8,None),'Walk':('idle',*walk,8,None),
              'Attack':('attack',attack[0],attack[1],12,attack[2]),
              'Hit':('hit',*hit,12,None),'Die':('hit',*die,8,None)}
        spec['Run']=spec['Walk']; spec['Skill']=spec['Attack']
        if mid=='crystal_stag': spec['Skill']=('attack',16,27,10,19)
        dx,raw=register(sources['idle'],list(range(walk[0],walk[1]+1)),roi)
        metrics={}
        for source,paths in sources.items():
            boxes=[image(p).getchannel('A').point(lambda a:255 if a>20 else 0).getbbox() for p in paths[:3 if source=='idle' else 2]]
            # Fixed baseline from neutral poses; attacks and deaths retain their own motion.
            metrics[source]=(statistics.median((b[0]+b[2])/2 for b in boxes),statistics.median(b[3] for b in boxes),statistics.median(b[3]-b[1] for b in boxes))
        fp=ROOT/f'data/sprites/monsters/{mid}_frames.tres'; dp=ROOT/f'data/monsters/{mid}.tres'
        backup(fp);backup(dp)
        old=fp.read_text(encoding='utf-8');data=dp.read_text(encoding='utf-8')
        uid=re.search(r'uid="[^"]+"',old.splitlines()[0])
        lines=['[gd_resource type="SpriteFrames" format=3'+(' '+uid[0] if uid else '')+']','']
        ids={}; atlas=[]; animations=[]; manifest={}
        for name,(source,start,end,fps,contact) in spec.items():
            frames=list(range(start,end+1)); durations=[1.0]*len(frames)
            if name in ('Attack','Skill'):
                prefix='skill' if name=='Skill' and re.search(r'^skill_duration = ',data,re.M) else 'attack'
                wind=float(re.search(r'^'+prefix+r'_windup = ([\d.]+)',data,re.M)[1]); recovery=float(re.search(r'^'+prefix+r'_duration = ([\d.]+)',data,re.M)[1])
                before=frames.index(contact)
                durations=[wind*fps/before]*before+[recovery*fps/(len(frames)-before)]*(len(frames)-before)
            entries=[]
            for f,duration in zip(frames,durations):
                shift=dx.get(f,0) if name in ('Walk','Run') else 0
                key=(source,f,shift)
                if key not in ids:
                    eid=f'f{len(ids)+1}';ids[key]=eid;p=sources[source][f-1]
                    lines.append(f'[ext_resource type="Texture2D" path="res://{p.relative_to(ROOT).as_posix()}" id="{eid}"]')
                    ax,ay,_=metrics[source]
                    atlas.extend(['',f'[sub_resource type="AtlasTexture" id="a{eid}"]',f'atlas = ExtResource("{eid}")','region = Rect2(0, 0, 1112, 834)',f'margin = Rect2({800-ax-shift}, {1100-ay}, 488, 566)','filter_clip = true'])
                entries.append(f'{{"duration": {duration:.9f}, "texture": SubResource("a{ids[key]}")}}')
            animations.append('{"frames": ['+',\n'.join(entries)+f'], "loop": {str(name in ("Idle","Walk","Run")).lower()}, "name": &"{name}", "speed": {float(fps)}'+'}')
            manifest[name]={'source':source,'frames':frames,'seconds':sum(durations)/fps}
        fp.write_text('\n'.join(lines+atlas+['','[resource]','animations = ['+',\n'.join(animations)+']','']),encoding='utf-8')
        # SpriteFit counts any nonzero alpha; nearly invisible export halos must
        # not shrink the visible body below the artist's configured height.
        raw_boxes=[image(sources['idle'][f-1]).getchannel('A').getbbox() for f in range(idle[0],idle[1]+1)]
        raw_height=max(b[3]-b[1] for b in raw_boxes)
        fields={'fit_fixed_anchor_enabled':'true','fit_fixed_anchor':'Vector2(800, 1100)','fit_uniform_scale':'true','fit_animation_anchors':'Dictionary[StringName, Vector2]({})','fit_animation_scales':'Dictionary[StringName, float]({'+', '.join(f'&"{n}": {raw_height/metrics[s[0]][2]:.8f}' for n,s in spec.items())+'})'}
        for k,v in fields.items():data=set_field(data,k,v)
        dp.write_text(data,encoding='utf-8')
        report[mid]={'animations':manifest,'source_geometry':metrics,'walk_dx':dx,'raw_body_dx':raw,'body_tracking_roi':roi}
        print(mid,'walk compensation:',list(dx.values()),flush=True)
    (OUT/'source_hashes.json').write_text(json.dumps(hashes,indent=2))
    (OUT/'manifest.json').write_text(json.dumps(report,indent=2))

if __name__=='__main__': install()
