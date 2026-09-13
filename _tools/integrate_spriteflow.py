"""Install reviewed Spriteflow PNG frames without changing their pixels."""
from pathlib import Path
from PIL import Image
import json, re, shutil, statistics, sys

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / 'output/spriteflow'
CANVAS = (1600, 1400)
ANCHOR = (800, 1100)

def clip(source, start, end, fps, contact=None):
    return dict(source=source, frames=list(range(start,end+1)), fps=fps, contact=contact)

CONFIG = {
 'war_wraith': {
  'Idle':clip('war_wraith_idle_walk',1,8,8),
  'Walk':clip('war_wraith_idle_walk',9,24,8),
  'Attack':clip('war_wraith_attack',1,18,8,10),
  'Hit':clip('war_wraith_hit_die',1,6,12),
  'Die':clip('war_wraith_hit_die',7,24,8)},
 'thorn_hound': {
  'Idle':clip('thorn_hound_idle_walk',1,6,8),
  'Walk':clip('thorn_hound_idle_walk',9,24,8),
  'Attack':clip('thorn_hound_all',10,19,8,12),
  'Hit':clip('thorn_hound_all',20,23,12),
  'Die':clip('thorn_hound_all',24,32,8)},
 'thorn_matriarch': {
  'Idle':clip('thorn_matriarch_idle_walk',1,8,8),
  'Walk':clip('thorn_matriarch_idle_walk',9,32,8),
  'Attack':clip('thorn_matriarch_attack_hit_die',1,10,8,7),
  'Hit':clip('thorn_matriarch_attack_hit_die',11,16,12),
  'Die':clip('thorn_matriarch_attack_hit_die',17,32,8)},
 'vanir_sentinel': {
  'Idle':clip('vanir_sentinel_idle_walk',1,12,8),
  'Walk':clip('vanir_sentinel_walk',1,32,8),
  'Attack':clip('vanir_sentinel_attack',1,24,8,9),
  'Hit':clip('vanir_sentinel_walk_hit_die',7,16,12),
  'Die':clip('vanir_sentinel_walk_hit_die',17,27,8)},
}

CONFIG.update({
 'withered_treant': {
  'Idle':clip('withered_treant_idle_walk',1,10,8),
  'Walk':clip('withered_treant_idle_walk',11,32,8),
  'Attack':clip('withered_treant_attack',1,26,8,13),
  'Hit':clip('withered_treant_hit_die',1,12,12),
  'Die':clip('withered_treant_hit_die',13,32,8)},
 'root_crawler': {
  'Idle':clip('root_crawler_idle_walk',1,10,8),
  'Walk':clip('root_crawler_idle_walk',11,32,8),
  'Attack':clip('root_crawler_attack_hit_die',4,12,8,7),
  'Hit':clip('root_crawler_attack_hit_die',13,17,12),
  'Die':clip('root_crawler_attack_hit_die',18,32,8)},
 'bog_lurker': {
  'Idle':clip('bog_lurker_idle_walk',1,8,8),
  'Walk':clip('bog_lurker_idle_walk',9,32,8),
  'Attack':clip('bog_lurker_attack_hit_die',1,12,8,8),
  'Hit':clip('bog_lurker_attack_hit_die',13,18,12),
  'Die':clip('bog_lurker_attack_hit_die',19,32,8)},
 'mist_sprite': {
  'Idle':clip('mist_sprite_idle_fly',1,8,8),
  'Walk':clip('mist_sprite_idle_fly',9,32,8),
  'Attack':clip('mist_sprite_attack_hit_die',1,13,8,12),
  'Hit':clip('mist_sprite_attack_hit_die',16,17,12),
  'Die':clip('mist_sprite_attack_hit_die',16,26,8)},
})

fire_cast = clip('gullveig_ember_attack',1,32,12)
fire_cast['frames'] = list(range(1,15))+list(range(15,28))+list(range(15,28))+list(range(28,33))
fire_cast['authored_timing'] = True
fire_cast['trim_left'] = {f:315 for f in [10,11,12,23,24,25,26,27]}
CONFIG['gullveig_ember'] = {
 'Idle':clip('gullveig_ember_idle',1,32,8),
 'Walk':clip('gullveig_ember_idle',1,32,8),
 'Attack':fire_cast,
 'Hit':clip('gullveig_ember_idle',1,1,12),
 'Die':clip('gullveig_ember_idle',1,1,8),
}

def geometry(source):
    rows=[]
    for i in range(1,4):
        im=Image.open(WORK/'downloads'/source/f'frame_{i:02}.png').convert('RGBA')
        alpha=im.getchannel('A').point(lambda a:255 if a>20 else 0)
        x0,y0,x1,y1=alpha.getbbox()
        # Fixed source registration, measured from three initial standing poses.
        feet=alpha.crop((0,y1-max(20,int((y1-y0)*.08)),im.width,y1)).getbbox()
        rows.append(((feet[0]+feet[2])/2,y1,y1-y0))
    values=tuple(round(statistics.median(row[k] for row in rows)) for k in range(3))
    # A hovering flame spirit has no feet: register her torso, not the trailing fire tip.
    if source.startswith('gullveig_ember_'): values=(560,values[1],values[2])
    return values

def backup(path):
    target=WORK/'before'/path.relative_to(ROOT)
    if not target.exists():
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(path,target)

def install(mid, anims):
    framepath=ROOT/f'data/sprites/monsters/{mid}_frames.tres'
    datapath=ROOT/f'data/monsters/{mid}.tres'
    oldframes=framepath.read_text(encoding='utf-8')
    data=datapath.read_text(encoding='utf-8')
    if mid!='war_wraith' and not (WORK/'before'/framepath.relative_to(ROOT)).exists():
        textures=re.findall(r'path="(res://[^\"]+\.png)"',oldframes)
        assert textures and all('/placeholder/' in t for t in textures), f'{mid} already has real sprites'
    sources={c['source'] for c in anims.values()}
    metrics={s:geometry(s) for s in sources}
    refheight=metrics[anims['Idle']['source']][2]
    # Monster SpriteFit counts faint alpha > 0; compensate without editing PNGs.
    raw_reference_height=max(Image.open(WORK/'downloads'/anims['Idle']['source']/f'frame_{f:02}.png').getchannel('A').getbbox()[3]-Image.open(WORK/'downloads'/anims['Idle']['source']/f'frame_{f:02}.png').getchannel('A').getbbox()[1] for f in anims['Idle']['frames'])
    anims=dict(anims,Run=anims['Walk'],Skill=anims['Attack'])
    uid=re.search(r'uid="[^"]+"',oldframes.splitlines()[0])
    text=['[gd_resource type="SpriteFrames" format=3'+(' '+uid.group() if uid else '')+']','']
    ids={}
    atlas=[]
    for name,c in anims.items():
        source=c['source']; ax,ay,_=metrics[source]
        for f in c['frames']:
            key=(source,f)
            if key in ids:continue
            eid=f'frame_{len(ids)+1:03}'
            ids[key]=eid
            src=WORK/'downloads'/source/f'frame_{f:02}.png'
            dst=ROOT/'Sprites/monsters/spriteflow'/mid/source/f'frame_{f:02}.png'
            dst.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(src,dst)
            with Image.open(src) as im: w,h=im.size
            text += [f'[ext_resource type="Texture2D" path="res://{dst.relative_to(ROOT).as_posix()}" id="{eid}"]']
            trim=c.get('trim_left',{}).get(f,0)
            atlas += ['',f'[sub_resource type="AtlasTexture" id="atlas_{eid}"]',f'atlas = ExtResource("{eid}")',f'region = Rect2({trim}, 0, {w-trim}, {h})',f'margin = Rect2({ANCHOR[0]-ax+trim}, {ANCHOR[1]-ay}, {CANVAS[0]-w+trim}, {CANVAS[1]-h})','filter_clip = true']
    text += atlas+['','[resource]','animations = [']
    scale_values={}
    summary={}
    for name,c in anims.items():
        durations=[1.0]*len(c['frames'])
        if name in ('Attack','Skill') and not c.get('authored_timing',False):
            windup=float(re.search(r'^attack_windup = ([\d.]+)',data,re.M)[1])
            recovery=float(re.search(r'^attack_duration = ([\d.]+)',data,re.M)[1])
            before=c['frames'].index(c['contact']) if c['contact'] else 0
            if before>0:
                durations=[windup*c['fps']/before]*before+[recovery*c['fps']/(len(durations)-before)]*(len(durations)-before)
            else: durations=[(windup+recovery)*c['fps']/len(durations)]*len(durations)
        text += ['{','"frames": [']
        for f,d in zip(c['frames'],durations):
            text += [f'{{"duration": {d:.9f}, "texture": SubResource("atlas_{ids[(c["source"],f)]}")}},']
        text += [f'], "loop": {str(name in ("Idle","Walk","Run")).lower()}, "name": &"{name}", "speed": {float(c["fps"])}','},']
        scale_values[name]=raw_reference_height/metrics[c['source']][2]
        summary[name]=dict(source=c['source'],frames=c['frames'],fps=c['fps'],duration=sum(durations)/c['fps'],scale=scale_values[name])
    text += [']','']
    backup(framepath); backup(datapath)
    framepath.write_text('\n'.join(text),encoding='utf-8')
    fields={'fit_fixed_anchor_enabled':'true','fit_fixed_anchor':f'Vector2({ANCHOR[0]}, {ANCHOR[1]})','fit_uniform_scale':'true', 'fit_animation_scales':'Dictionary[StringName, float]({'+', '.join(f'&"{k}": {v:.8f}' for k,v in scale_values.items())+'})'}
    for key,value in fields.items():
        data=re.sub(r'^'+key+r' = .*?(?=^[A-Za-z_]\w* = |^\[|\Z)', '', data, flags=re.M|re.S)
        # Custom exports must follow script assignment in a text Resource.
        data=data.rstrip()+'\n'+key+' = '+value+'\n'
    datapath.write_text(data,encoding='utf-8')
    report={'monster':mid,'anchor':ANCHOR,'canvas':CANVAS,'sources':metrics,'animations':summary,'unique_frames':len(ids)}
    (WORK/f'{mid}_manifest.json').write_text(json.dumps(report,indent=2))
    print(mid,len(ids),'original PNG frames installed',flush=True)

if __name__=='__main__':
    for mid in sys.argv[1:]: install(mid,CONFIG[mid])
