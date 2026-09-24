"""Chapter 6: reviewed source ranges; preserve every downloaded PNG byte."""
from pathlib import Path
import hashlib, json, re, shutil, statistics
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/chapter6_sprites'
# source names; idle/walk ranges; attack range/contact; reaction/death ranges.
CONFIG = {
 'hel_hound': ('idle-walk-0856','attack-hit-swing-0903','hit-and-die-0927',(1,8),(9,24),(4,27,18),(2,8),(9,32)),
 'mist_ghost': ('idle-fly-1039','mist-ball-attack-1100','hit-and-die-1011',(1,8),(9,24),(4,29,19),(2,8),(9,32)),
 'ferryman': ('idle-walk-cycle-1121','attack-action-1109','hit-die-1515',(1,8),(9,32),(3,28,13),(3,6),(7,32)),
 'name_warden': ('idle-walk-loop-1135','attack-slash-hit-1152','hit-and-die-1202',(1,4),(9,24),(4,25,17),(3,8),(9,32)),
 'erased_voice': ('idle-fly-1616','attack-strike-1702','attack-death-animation-1555',(1,8),(9,24),(4,25,12),(3,8),(9,24)),
 'false_judge': ('idle-walk-set-2042','spell-attack-2047','hit-and-die-2051',(1,8),(9,24),(3,27,13),(3,8),(9,32)),
 'chained_garm': ('hero-idle-walk-2102','attack-sprite-animation-2106','hit-and-die-2057',(1,8),(9,24),(4,31,20),(3,8),(9,32)),
 'nidhogg_spawn': ('idle-walk-2353','attack-strike-2112','attack-hit-die-2105',(1,6),(9,24),(4,26,16),(3,8),(9,32)),
 'garm_freed': ('idle-walk-cycle-2041','attack-hit-strike-2049','hit-and-die-2056',(1,8),(9,24),(4,27,16),(3,8),(9,32)),
 'drowned': ('idle-loop-0844',None,None,(1,32),(1,2),(1,3,2),(1,2),(1,3)),
}
RANGED = {
 'mist_ghost': ((250,340),(0.43,0.61,0.65),100),
 'erased_voice': ((215,395),(0.22,0.66,1.0),65),
 'false_judge': ((220,615),(0.73,0.84,0.57),80),
}

def set_field(text,key,value):
    text=re.sub(r'^'+key+r' = .*?(?=^[A-Za-z_]\w* = |^\[|\Z)','',text,flags=re.M|re.S)
    return text.rstrip()+'\n'+key+' = '+value+'\n'

def backup(p):
    if not p.exists(): return
    dst=OUT/'before'/p.relative_to(ROOT)
    if not dst.exists(): dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dst)

def geometry(paths):
    boxes=[Image.open(p).getchannel('A').point(lambda a:255 if a>20 else 0).getbbox() for p in paths[:2]]
    return [statistics.median((b[0]+b[2])/2 for b in boxes),statistics.median(b[3] for b in boxes),statistics.median(b[3]-b[1] for b in boxes)]

def install():
    report={};hashes={}
    for mid,(idle,attack,hit,ir,wr,ar,hr,dr) in CONFIG.items():
        sources={}
        for key,name in [('idle',idle),('attack',attack),('hit',hit)]:
            if not name:
                sources[key]=[ROOT/f'Sprites/monsters/chapter6/runtime/{mid}.png']*32
                continue
            dst=ROOT/'Sprites/monsters/spriteflow'/mid/name;dst.mkdir(parents=True,exist_ok=True)
            paths=sorted((OUT/'downloads'/name).glob('frame_*.png'));assert len(paths)==32
            for p in paths:
                dest=dst/p.name;shutil.copy2(p,dest)
                digest=hashlib.sha256(dest.read_bytes()).hexdigest()
                assert digest==hashlib.sha256(p.read_bytes()).hexdigest()
                hashes[dest.relative_to(ROOT).as_posix()]=digest
            sources[key]=[dst/p.name for p in paths]
        metrics={key:geometry(paths) for key,paths in sources.items()}
        spec={'Idle':('idle',*ir,8,None),'Walk':('idle' if mid!='drowned' else 'attack',*wr,8,None),
              'Attack':('attack',ar[0],ar[1],12,ar[2]),'Hit':('hit',*hr,12,None),'Die':('hit',*dr,8,None)}
        spec['Run']=spec['Walk'];spec['Skill']=spec['Attack']
        fp=ROOT/f'data/sprites/monsters/{mid}_frames.tres';dp=ROOT/f'data/monsters/{mid}.tres'
        backup(fp);backup(dp)
        old=fp.read_text(encoding='utf-8') if fp.exists() else ''
        data=dp.read_text(encoding='utf-8') if dp.exists() else ''
        uid=re.search(r'uid="[^"]+"',old.splitlines()[0]) if old else None
        lines=['[gd_resource type="SpriteFrames" format=3'+(' '+uid[0] if uid else '')+']','']
        ids={};atlas=[];animations=[];manifest={}
        for name,(source,start,end,fps,contact) in spec.items():
            frames=list(range(start,end+1));durations=[1.0]*len(frames)
            # Boss spells retain their existing windup and recovery contract.
            if name=='Skill' and re.search(r'^skill_duration = ',data,re.M):
                wind=float(re.search(r'^skill_windup = ([\d.]+)',data,re.M)[1]);recovery=float(re.search(r'^skill_duration = ([\d.]+)',data,re.M)[1])
                before=frames.index(contact)
                durations=[wind*fps/before]*before+[recovery*fps/(len(frames)-before)]*(len(frames)-before)
            entries=[]
            for f,duration in zip(frames,durations):
                key=(source,f)
                if key not in ids:
                    eid=f'f{len(ids)+1}';ids[key]=eid;p=sources[source][f-1]
                    lines.append(f'[ext_resource type="Texture2D" path="res://{p.relative_to(ROOT).as_posix()}" id="{eid}"]')
                    ax,ay,_=metrics[source];w,h=Image.open(p).size
                    atlas.extend(['',f'[sub_resource type="AtlasTexture" id="a{eid}"]',f'atlas = ExtResource("{eid}")',f'region = Rect2(0, 0, {w}, {h})',f'margin = Rect2({800-ax}, {1100-ay}, {1600-w}, {1400-h})','filter_clip = true'])
                entries.append(f'{{"duration": {duration:.9f}, "texture": SubResource("a{ids[key]}")}}')
            animations.append('{"frames": ['+',\n'.join(entries)+f'], "loop": {str(name in ("Idle","Walk","Run")).lower()}, "name": &"{name}", "speed": {float(fps)}'+'}')
            manifest[name]={'source':str(sources[source][0].parent.relative_to(ROOT)),'frames':frames,'seconds':sum(durations)/fps}
        fp.write_text('\n'.join(lines+atlas+['','[resource]','animations = ['+',\n'.join(animations)+']','']),encoding='utf-8')
        raw_height=max((b:=Image.open(sources['idle'][f-1]).getchannel('A').getbbox())[3]-b[1] for f in range(ir[0],ir[1]+1))
        scales={n:raw_height/metrics[s[0]][2] for n,s in spec.items()}
        fields={'fit_fixed_anchor_enabled':'true','fit_fixed_anchor':'Vector2(800, 1100)','fit_uniform_scale':'true',
                'fit_animation_anchors':'Dictionary[StringName, Vector2]({})',
                'fit_animation_scales':'Dictionary[StringName, float]({'+', '.join(f'&"{n}": {v:.8f}' for n,v in scales.items())+'})'}
        if mid!='drowned':
            fields.update(attack_hit_frames=f'PackedInt32Array({ar[2]-ar[0]})',attack_follow_anim='true',
                          attack_windup=str((ar[2]-ar[0])/12),attack_duration=str((ar[1]-ar[2]+1)/12))
        if mid in RANGED:
            point,color,height=RANGED[mid];ax,ay,_=metrics['attack']
            data=data.replace('[sub_resource','[ext_resource type="Texture2D" path="res://data/sprites/gullveig_fireball_texture.tres" id="chapter6_orb"]\n\n[sub_resource',1) if 'id="chapter6_orb"' not in data else data
            fields.update(ranged_attack='true',ranged_attack_range='650.0',projectile_texture='ExtResource("chapter6_orb")',
                projectile_speed='1000.0',projectile_range='1200.0',projectile_height=str(float(height)),
                projectile_hit_size='Vector2(42, 42)',projectile_fire_effect='true',projectile_orb_style='true',
                projectile_orb_color='Color('+', '.join(map(str,color))+', 1)',projectile_aim_at_player='false',projectile_down_angle='0.0',
                projectile_hand_positions=f'Dictionary[int, Vector2]({{{ar[2]-ar[0]}: Vector2({800-ax+point[0]}, {1100-ay+point[1]})}})',skill_hand_projectiles='false')
        if data:
            for k,v in fields.items():data=set_field(data,k,v)
            dp.write_text(data,encoding='utf-8')
        report[mid]={'animations':manifest,'source_geometry':metrics,'fit_scales':scales,'ranged':mid in RANGED,
                     'fallback': 'Only Idle is new; other actions retain legacy art.' if mid=='drowned' else None}
        print(mid,flush=True)
    (OUT/'source_hashes.json').write_text(json.dumps(hashes,indent=2))
    (OUT/'manifest.json').write_text(json.dumps(report,indent=2))

if __name__=='__main__':install()
