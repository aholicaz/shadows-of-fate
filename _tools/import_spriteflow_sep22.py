"""Install reviewed Sept 22 monsters and the missing Sept 16 Drowned clips.

Original PNGs stay byte-identical. Registration lives in AtlasTexture margins.
Only actors in CONFIG are touched; unrelated artwork and stats are preserved.
"""
from pathlib import Path
import hashlib, json, re, shutil, statistics
from PIL import Image
from import_spriteflow_chapter6 import set_field

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'output/sep22_sprites'

def clip(source,a,b,fps=8,contacts=()):
    return {'source':source,'frames':list(range(a,b+1)),'fps':fps,'contacts':list(contacts)}

CONFIG={
 'drowned':{
  'Idle':clip('idle-loop-0844',1,32),
  'Walk':clip('walk-cycle-loop-1027',1,32),
  'Attack':clip('unnamed-sep16-1020',10,20,12,[16]),
  'Hit':clip('unnamed-sep16-1020',21,23,12),
  'Die':clip('unnamed-sep16-1020',24,32)},
 'cinder_hound':{
  'Idle':clip('idle-walk-1010',1,8),
  'Walk':clip('idle-walk-1010',9,24),
  'Attack':clip('attack-sprite-animation-1019',3,25,12,[16]),
  'Hit':clip('hit-and-die-1031',3,10,12),
  'Die':clip('hit-and-die-1031',11,32)},
 'slag_mantis':{
  'Idle':clip('idle-walk-loop-1446',1,6),
  'Walk':clip('idle-walk-loop-1446',9,24),
  'Attack':clip('triple-attack-1441',5,28,12,[10,17,23]),
  'Hit':clip('hit-and-die-1351',4,12,12),
  'Die':clip('hit-and-die-1351',13,32)},
 'chainbound_ogre':{
  'Idle':clip('idle-walk-loop-1556',1,4),
  'Walk':clip('idle-walk-loop-1556',5,24),
  'Attack':clip('attack-slash-hit-1608',4,28,12,[15,22]),
  'Hit':clip('hit-and-die-1619',3,6,12),
  'Die':clip('hit-and-die-1619',7,31)},
 'kiln_sentinel':{
  'Idle':clip('idle-walk-1550',1,3),
  'Walk':clip('idle-walk-1550',5,28),
  'Attack':clip('attack-slash-hit-1556',4,28,12,[12,20]),
  'Hit':clip('hit-and-die-1608',4,10,12),
  'Die':clip('hit-and-die-1608',11,32),
  'Skill':clip('attack-slash-hit-1556',13,28,12,[20])},
 'ash_knight':{
  # The new idle/walk was still processing in the gallery; keep those clips until it finishes.
  'Attack':clip('attack-slash-three-1619',4,29,12,[9,14,22]),
  'Hit':clip('hit-and-die-1612',3,8,12),
  'Die':clip('hit-and-die-1612',9,32)},
}

def backup(p):
    dst=OUT/'before'/p.relative_to(ROOT)
    if not dst.exists(): dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dst)

def geometry(paths):
    boxes=[Image.open(p).getchannel('A').point(lambda a:255 if a>20 else 0).getbbox() for p in paths[:2]]
    return [statistics.median((b[0]+b[2])/2 for b in boxes),statistics.median(b[3] for b in boxes),statistics.median(b[3]-b[1] for b in boxes)]

def install():
    report={};hashes={}
    for mid,base_spec in CONFIG.items():
        spec=dict(base_spec)
        if 'Walk' in spec:spec['Run']=spec['Walk']
        spec.setdefault('Skill',spec['Attack'])
        # The runtime may request either name; both point at the same death clip.
        spec['Death']=spec['Die']
        sources={}
        for source in {s['source'] for s in spec.values()}:
            src=OUT/'downloads'/source
            if not src.exists():src=ROOT/'Sprites/monsters/spriteflow'/mid/source
            paths=sorted(src.glob('frame_*.png'));assert len(paths)==32,(source,len(paths))
            dst=ROOT/'Sprites/monsters/spriteflow'/mid/source;dst.mkdir(parents=True,exist_ok=True)
            for p in paths:
                target=dst/p.name
                if p.resolve()!=target.resolve():shutil.copy2(p,target)
                digest=hashlib.sha256(target.read_bytes()).hexdigest()
                assert digest==hashlib.sha256(p.read_bytes()).hexdigest()
                hashes[target.relative_to(ROOT).as_posix()]=digest
            sources[source]=[dst/p.name for p in paths]
        metrics={s:geometry(paths) for s,paths in sources.items()}
        fp=ROOT/f'data/sprites/monsters/{mid}_frames.tres';dp=ROOT/f'data/monsters/{mid}.tres'
        backup(fp);backup(dp)
        old=fp.read_text(encoding='utf-8');data=dp.read_text(encoding='utf-8')
        uid=re.search(r'uid="[^"]+"',old.splitlines()[0])
        lines=['[gd_resource type="SpriteFrames" format=3'+(' '+uid[0] if uid else '')+']','']
        atlas=[];animations=[];ids={};manifest={}
        # Preserve untouched animation definitions for an incomplete generation.
        if 'Idle' not in spec:
            legacy=ROOT/'Sprites/monsters/chapter7/runtime'/f'{mid}.png'
            lines.append(f'[ext_resource type="Texture2D" path="res://{legacy.relative_to(ROOT).as_posix()}" id="legacy"]')
            w,h=Image.open(legacy).size;ax,ay,body=geometry([legacy,legacy]);metrics['legacy']=[ax,ay,body]
            atlas.extend(['','[sub_resource type="AtlasTexture" id="legacy_canvas"]','atlas = ExtResource("legacy")',f'region = Rect2(0, 0, {w}, {h})',f'margin = Rect2({800-ax}, {1100-ay}, {1600-w}, {1400-h})'])
            for name in ['Idle','Walk','Run']:
                animations.append('{"frames": [{"duration": 1.0, "texture": SubResource("legacy_canvas")}], "loop": true, "name": &"'+name+'", "speed": 1.0}')
            raw_height=Image.open(legacy).getchannel('A').getbbox();raw_height=raw_height[3]-raw_height[1]
            scales={n:raw_height/body for n in ['Idle','Walk','Run']}
        else:
            idle=spec['Idle'];raw_height=max((b:=Image.open(sources[idle['source']][f-1]).getchannel('A').getbbox())[3]-b[1] for f in idle['frames'])
            scales={}
        for name,s in spec.items():
            source=s['source'];frames=s['frames'];fps=s['fps'];durations=s.get('durations',[1.0]*len(frames))
            if name=='Skill' and mid=='kiln_sentinel':
                wind=float(re.search(r'^skill_windup = ([\d.]+)',data,re.M)[1]);tail=float(re.search(r'^skill_duration = ([\d.]+)',data,re.M)[1])
                before=frames.index(s['contacts'][0]);durations=[wind*fps/before]*before+[tail*fps/(len(frames)-before)]*(len(frames)-before)
            entries=[]
            for f,duration in zip(frames,durations):
                key=(source,f)
                if key not in ids:
                    eid=f's22_{len(ids)+1}';ids[key]=eid;p=sources[source][f-1]
                    lines.append(f'[ext_resource type="Texture2D" path="res://{p.relative_to(ROOT).as_posix()}" id="{eid}"]')
                    ax,ay,_=metrics[source];w,h=Image.open(p).size
                    atlas.extend(['',f'[sub_resource type="AtlasTexture" id="a{eid}"]',f'atlas = ExtResource("{eid}")',f'region = Rect2(0, 0, {w}, {h})',f'margin = Rect2({800-ax}, {1100-ay}, {1600-w}, {1400-h})','filter_clip = true'])
                entries.append(f'{{"duration": {duration:.9f}, "texture": SubResource("a{ids[key]}")}}')
            animations.append('{"frames": ['+',\n'.join(entries)+f'], "loop": {str(name in ("Idle","Walk","Run")).lower()}, "name": &"{name}", "speed": {float(fps)}'+'}')
            manifest[name]={**s,'seconds':sum(durations)/fps}
            scales[name]=raw_height/metrics[source][2]
        fp.write_text('\n'.join(lines+atlas+['','[resource]','animations = ['+',\n'.join(animations)+']','']),encoding='utf-8')
        attack=spec['Attack'];contacts=[attack['frames'].index(f) for f in attack['contacts']]
        fields={'fit_fixed_anchor_enabled':'true','fit_fixed_anchor':'Vector2(800, 1100)','fit_uniform_scale':'true',
                'fit_animation_anchors':'Dictionary[StringName, Vector2]({})',
                'fit_animation_scales':'Dictionary[StringName, float]({'+', '.join(f'&"{n}": {v:.8f}' for n,v in scales.items())+'})',
                'attack_hit_frames':'PackedInt32Array('+', '.join(map(str,contacts))+')','attack_follow_anim':'true',
                'attack_windup':str(contacts[0]/attack['fps']),
                'attack_duration':str((len(attack['frames'])-contacts[-1])/attack['fps']),
                # Multi-strike artwork splits one attack budget; no accidental triple damage.
                'attack_hit_damage_mult':str(1.0/len(contacts))}
        if mid=='kiln_sentinel':
            fields['skill_hit_frames']='PackedInt32Array(7)'
            # Source frame 20: hammer head center at (340,790), registered canvas.
            ax,ay,_=metrics['attack-slash-hit-1556']
            fields['ground_slam_anchor']=f'Vector2({800-ax+340}, {1100-ay+790})'
        for k,v in fields.items():data=set_field(data,k,v)
        dp.write_text(data,encoding='utf-8')
        report[mid]={'animations':manifest,'source_geometry':metrics,'fit_scales':scales,'attack_frames':contacts,
                     'pending_idle_walk': 'Idle/walk generation 1624 was processing at last gallery observation.' if mid=='ash_knight' and 'Idle' not in spec else None}
        print(mid,flush=True)
    (OUT/'source_hashes.json').write_text(json.dumps(hashes,indent=2))
    (OUT/'manifest.json').write_text(json.dumps(report,indent=2))

if __name__=='__main__':install()
