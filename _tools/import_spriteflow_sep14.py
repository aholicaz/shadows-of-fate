"""Reviewed 18 Sep 14 clips. Preserve PNG bytes; author resource-only crops and sockets."""
from pathlib import Path
import json, re, hashlib, math
import integrate_spriteflow as p

def c(source,a,b,fps=10,contact=None): return p.clip(f'sep14_{source:02}',a,b,fps,contact)
CONFIG={
 'echo_wraith':dict(Idle=c(15,1,8,8),Walk=c(15,9,32,8),Attack=c(14,1,32,12,9),Hit=c(12,2,11,12),Die=c(12,12,32,10)),
 'snow_hawk':dict(Idle=c(13,1,10,8),Walk=c(13,11,32,10),Attack=c(11,1,32,16,8),Hit=c(8,2,13,12),Die=c(8,14,32,10)),
 'hollow_elf':dict(Idle=c(3,1,8,8),Walk=c(3,9,32,8),Attack=c(1,1,32,14,9),Hit=c(17,5,16,12),Die=c(17,17,32,10)),
 'water_nymph':dict(Idle=c(2,1,8,8),Walk=c(2,9,32,8),Attack=c(0,1,32,12,13),Hit=c(16,4,13,12),Die=c(16,14,32,10)),
 'light_forsaken':dict(Idle=c(9,1,8,8),Walk=c(9,9,32,8),Attack=c(5,1,32,12,10),Hit=c(4,2,8,12),Die=c(4,9,26,10)),
 'radiant_alfr':dict(Idle=c(10,1,10,8),Walk=c(10,11,32,8),Attack=c(7,1,32,12,11),Hit=c(6,2,12,12),Die=c(6,13,32,10)),
}
# Source-pixel muzzle positions at each visible discharge (one-based frames).
CASTS={
 'echo_wraith':([(9,442,296),(18,265,235)],(.24,.72,1.0),86),
 'light_forsaken':([(10,379,275),(19,369,275)],(.65,.08,1.0),100),
 'radiant_alfr':([(11,303,296)],(1.0,.68,.93),104),
 'water_nymph':([(13,336,273)],(.40,.83,1.0),90),
}
HEIGHTS={
 'frost_wolf':330,'snow_hawk':390,'snow_mammoth':680,'ice_troll':600,
 'stone_soldier':460,'echo_wraith':430,'wall_shieldbearer':600,'stone_hrungnir':850,
 'light_moth':310,'crystal_stag':470,'light_eater_bloom':400,'garden_keeper':440,
 'reflection':390,'water_nymph':420,'hollow_elf':380,'hollow_moth':330,
 'light_forsaken':650,'radiant_alfr':720,
}
OUT=p.WORK/'sep14';OUT.mkdir(exist_ok=True)
def field(text,key,value):
 text=re.sub(r'^'+key+r' = .*?(?=^[A-Za-z_]\w* = |^\[|\Z)','',text,flags=re.M|re.S)
 return text.rstrip()+f'\n{key} = {value}\n'

if __name__=='__main__':
 before={}
 for mid,height in HEIGHTS.items():
  path=p.ROOT/f'data/monsters/{mid}.tres'
  before[mid]=path.read_text(encoding='utf-8')
 (OUT/'before_data.json').write_text(json.dumps(before,ensure_ascii=False,indent=2),encoding='utf-8') if not (OUT/'before_data.json').exists() else None
 for mid,anims in CONFIG.items():
  if mid in CASTS:
   anims['Attack']['authored_timing']=True
  if mid=='water_nymph':anims['Attack']['trim_left']={f:310 for f in [13,14,15]}
  if mid=='light_forsaken':anims['Attack']['trim_left']={10:300}
  p.install(mid,anims,replace_existing=True)
 for mid,height in HEIGHTS.items():
  path=p.ROOT/f'data/monsters/{mid}.tres';text=path.read_text(encoding='utf-8')
  text=field(text,'display_height',f'{height}.0')
  hitbox=re.search(r'hitbox_size = Vector2\([^,]+,\s*([\d.]+)\)',text)
  text=field(text,'hp_bar_offset_y',str(-height-28+(float(hitbox[1])/2 if hitbox else 0)))
  if mid in CONFIG:text=field(text,'tint','Color(1, 1, 1, 1)')
  if mid in CASTS:
   releases,color,size=CASTS[mid]
   source=CONFIG[mid]['Attack']['source']; ax,ay,body_height=p.geometry(source)
   sockets=', '.join(f'{f-1}: Vector2({x+800-ax}, {y+1100-ay})' for f,x,y in releases)
   text=re.sub(r'^\[ext_resource[^\n]*id="sep14_orb"\]\n?', '', text, flags=re.M)
   text=text.replace('[sub_resource','[ext_resource type="Texture2D" path="res://data/sprites/gullveig_fireball_texture.tres" id="sep14_orb"]\n\n[sub_resource',1)
   values={'projectile_texture':'ExtResource("sep14_orb")','ranged_attack':'true','ranged_attack_range':'720.0',
    'projectile_speed':'1000.0','projectile_range':'1250.0','projectile_height':f'{size}.0',
    'projectile_hit_size':'Vector2(48, 48)','projectile_fire_effect':'true','projectile_orb_style':'true',
    'projectile_orb_color':f'Color({color[0]}, {color[1]}, {color[2]}, 1)',
    'projectile_aim_at_player':'false','projectile_hand_positions':'Dictionary[int, Vector2]({'+sockets+'})',
    'projectile_down_angle':str(round(math.degrees(math.atan2(max(0,(ay-sum(v[2] for v in releases)/len(releases))*height/body_height-150),650)),2)),
    'attack_hit_frames':'PackedInt32Array('+', '.join(str(f-1) for f,x,y in releases)+')',
    'attack_windup':str((releases[0][0]-1)/12),'attack_duration':str((33-releases[0][0])/12),
    'skill_hand_projectiles':'true' if mid in ['light_forsaken','radiant_alfr'] else 'false'}
   for key,value in values.items():text=field(text,key,value)
  path.write_text(text,encoding='utf-8')
 # Existing three-shot fire caster also follows the newly requested straight rule.
 path=p.ROOT/'data/monsters/gullveig_ember.tres';text=path.read_text(encoding='utf-8')
 for key,value in {'projectile_speed':'1000.0','projectile_aim_at_player':'false','projectile_down_angle':'22.7'}.items():text=field(text,key,value)
 path.write_text(text,encoding='utf-8')
 report={'monsters':list(CONFIG),'heights':HEIGHTS,'shots':{m:len(v[0]) for m,v in CASTS.items()},'sources':{}}
 for path in (p.ROOT/'Sprites/monsters/spriteflow').glob('*/sep14_*/frame_*.png'):
  original=p.WORK/'downloads'/path.parent.name/path.name
  assert original.read_bytes()==path.read_bytes(),path
  report['sources'][str(path.relative_to(p.ROOT))]=hashlib.sha256(path.read_bytes()).hexdigest()
 (OUT/'integration.json').write_text(json.dumps(report,indent=2))
 print('Integrated',len(report['sources']),'unchanged PNGs; resized',len(HEIGHTS),'monsters')
