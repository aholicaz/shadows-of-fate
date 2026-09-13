"""Assemble original SpriteFlow PNGs; no source pixels are altered."""
from pathlib import Path
import json, shutil, re, hashlib

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / 'output/spriteflow/downloads'
OUT = ROOT / 'output/runeblade_full'
OUT.mkdir(parents=True, exist_ok=True)
sources = {
 'rb_idle_1626': (562,771,705), 'runeblade_idle': (560,767,694),
 'rb_walk_2017': (552,765,698), 'rb_run_2018': (552,767,703),
 'rb_dash_0811': (550,762,693), 'rb_hitdie_2055': (556,761,689),
 'rb_basic_2102': (556,703,573), 'rb_skill_2108': (556,703,571),
 'rb_skill_2055': (556,761,690), 'rb_skill_2044': (562,774,710),
 'rb_skill_2020': (562,775,712),
}
anims = {}
def add(name, source, indices, fps=8, loop=False, hit=None):
    anims[name] = dict(frames=[(source,i) for i in indices],fps=fps,loop=loop,hit=hit)
def seq(a,b): return list(range(a,b+1))
add('Idle_Runeblade','rb_idle_1626',seq(1,32),8,True)
# Two breathing cycles make the expressive sigh occasional, then return continuously.
anims['Idle_Runeblade']['frames'] *= 2
anims['Idle_Runeblade']['frames'] += [('runeblade_idle',i) for i in seq(1,32)]
add('Walk_Runeblade','rb_walk_2017',seq(5,24),12,True)
add('Run_Runeblade','rb_run_2018',seq(5,32),16,True)
add('Dash_Runeblade','rb_dash_0811',seq(5,27),48)
add('Jump_Runeblade','rb_dash_0811',seq(14,20),12)
add('Hit_Runeblade','rb_hitdie_2055',seq(3,11),24)
add('Death_Runeblade','rb_hitdie_2055',seq(12,32),14)
add('Attack_Runeblade_1','rb_basic_2102',seq(1,7),14,False,3)
add('Attack_Runeblade_2','rb_basic_2102',seq(8,14),14,False,3)
add('Attack_Runeblade_3','rb_basic_2102',seq(15,27),26,False,3)
add('Anvil_Runeblade','rb_skill_2108',seq(17,30),20,False,6)
add('Faultline_Runeblade','rb_skill_2055',seq(12,26),20,False,6)
add('Worldcleaver_Runeblade','rb_skill_2020',seq(15,29),16,False,4)
add('Erasing_Runeblade','rb_skill_2044',seq(18,29),20,False,3)
add('Lunge_Runeblade','rb_skill_2044',seq(4,10),16)
add('Wave_Runeblade','rb_skill_2108',seq(8,17),16,False,1)
for n,(a,b) in enumerate([(4,10),(11,17),(18,26)],1):
    add(f'Flurry_Runeblade_{n}','rb_skill_2044',seq(a,b),36)
add('Flurry_Runeblade','rb_skill_2044',seq(4,26)*2,36)
# Expose complete untrimmed sources in the inspection scene for later art replacement.
for source in sources:
    add('Source_'+source,source,seq(1,32),8,True)

routes = {'Idle':'Idle_Runeblade','Walk':'Walk_Runeblade','Run':'Run_Runeblade','Dash':'Dash_Runeblade','Jump':'Jump_Runeblade','Land':'Jump_Runeblade','Hit':'Hit_Runeblade','Death':'Death_Runeblade','Attack':'Attack_Runeblade_1'}
skills = {'anvil_cleave':'Anvil_Runeblade','faultline':'Faultline_Runeblade','worldcleaver':'Worldcleaver_Runeblade','erasing_cut':'Erasing_Runeblade','rune_lunge':'Lunge_Runeblade','rune_flurry':'Flurry_Runeblade','bash':'Anvil_Runeblade','magnum_break':'Wave_Runeblade','slash':'Lunge_Runeblade'}
ext, ids, checks = [], {}, []
for source in sources:
    for i in seq(1,32):
        origin = STAGE/source/f'frame_{i:02}.png'
        if not origin.exists():
            candidates = sorted((STAGE/source).glob('*.png'))
            origin = candidates[i-1]
        target = ROOT/f'Sprites/player/runeblade/{source}/frame_{i:02}.png'
        target.parent.mkdir(parents=True,exist_ok=True)
        if not target.exists():
            shutil.copyfile(origin,target)
        eid = f'f{len(ids)+1}'
        ids[(source,i)] = eid
        ext.append(f'[ext_resource type="Texture2D" path="res://{target.relative_to(ROOT).as_posix()}" id="{eid}"]')
        checks.append({'file':target.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})

def gd(value):
    if isinstance(value,str):return json.dumps(value)
    if isinstance(value,bool):return str(value).lower()
    if isinstance(value,list):return '['+', '.join(map(gd,value))+']'
    if isinstance(value,dict):return '{'+', '.join(gd(k)+': '+gd(v) for k,v in value.items())+'}'
    return str(value)

registrations, frame_regs, baked, hits, entries = {}, {}, [], {}, []
for name,a in anims.items():
    src = a['frames'][0][0]; x,y,h = sources[src]
    registrations[name] = f'{{"anchor": Vector2({x},{y}), "height": {h}.0}}'
    frame_regs[name] = [{'anchor':[sources[s][0],sources[s][1]],'height':sources[s][2]} for s,i in a['frames']]
    # Authored root-height corrections for perspective steps and the prone landing.
    # These are broad motion phases, not per-frame silhouette normalization.
    for reg,(source,number) in zip(frame_regs[name],a['frames']):
        if source=='rb_basic_2102':
            reg['anchor'][1] = 703 if number<=3 else 720 if number<=14 else 712 if number<=17 else 754 if number<=23 else 735 if number==24 else 710 if number<=27 else 703
        elif source=='rb_hitdie_2055' and number>=21:
            reg['anchor'][1] = 790 if number==21 else 819
        elif source=='rb_skill_2108' and number>=17:
            reg['anchor'][1] = 710 if number<=22 else 762 if number<=26 else 729 if number==27 else 706
    # Artist removed the baked swords; all skill sources use equipped sockets.
    if a['hit'] is not None:hits[name]=a['hit']
    weights = [1.0]*len(a['frames'])
    timing = {'Anvil_Runeblade':(.28,.25),'Faultline_Runeblade':(.25,.25),'Worldcleaver_Runeblade':(.7,.25),'Erasing_Runeblade':(.3,.25),'Wave_Runeblade':(.22,.15)}
    if name in timing:
        windup,recovery=timing[name]
        hit=a['hit']
        before=(len(weights)-hit)*windup/recovery/hit
        weights[:hit]=[before]*hit
    frames = ',\n'.join('{"duration": '+str(weights[j])+', "texture": ExtResource("'+ids[p]+'")}' for j,p in enumerate(a['frames']))
    entries.append('{"frames": [\n'+frames+'\n], "loop": '+gd(a['loop'])+', "name": &'+gd(name)+', "speed": '+str(float(a['fps']))+'}')

# Current calibrated source sockets; never derive breathing from the sigh track.
weapon_tracks=json.loads((ROOT/'data/sprites/runeblade_weapon_tracks.json').read_text())
hands=[weapon_tracks[src][i-1] for src,i in anims['Idle_Runeblade']['frames']]
text='[gd_resource type="SpriteFrames" load_steps='+str(len(ext)+1)+' format=3]\n\n'+'\n'.join(ext)+'\n\n[resource]\nanimations = [\n'+',\n'.join(entries)+'\n]\n'
text+='metadata/rb_routes = '+gd(routes)+'\nmetadata/rb_skill_routes = '+gd(skills)+'\n'
text+='metadata/rb_registration = {'+', '.join(gd(k)+': '+v for k,v in registrations.items())+'}\n'
text+='metadata/rb_frame_registration = '+gd(frame_regs)+'\nmetadata/rb_baked_weapon = '+gd(baked)+'\nmetadata/rb_hit_frames = '+gd(hits)+'\nmetadata/rb_idle_hands = '+gd(hands)+'\n'
text+='metadata/runeblade_idle_anchor = Vector2(562,771)\nmetadata/runeblade_idle_height = 705.0\n'
(ROOT/'data/sprites/runeblade_frames.tres').write_text(text,encoding='utf-8')
(OUT/'manifest.json').write_text(json.dumps({'sources':sources,'animations':anims,'routes':routes,'skills':skills,'files':checks},indent=2),encoding='utf-8')
print(f'Imported {len(ids)} original PNGs, {len(anims)} animations; original hashes recorded.')
