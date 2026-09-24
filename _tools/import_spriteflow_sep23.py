"""Sept 23 Chapter 7 additions. Preserve original PNGs and existing stats."""
import json, re
import import_spriteflow_sep22 as pipeline
from import_spriteflow_chapter6 import set_field

ROOT=pipeline.ROOT
OUT=ROOT/'output/sep23_sprites'
clip=pipeline.clip

def install():
    ash=dict(pipeline.CONFIG['ash_knight'])
    ash.update(Idle=clip('idle-walk-loop-1624',1,6),Walk=clip('idle-walk-loop-1624',9,24))
    skill=clip('attack-slash-combo-1657',10,26,12,[16])
    data=(ROOT/'data/monsters/oath_warden.tres').read_text(encoding='utf-8')
    wind=float(re.search(r'^skill_windup = ([\d.]+)',data,re.M)[1])
    tail=float(re.search(r'^skill_duration = ([\d.]+)',data,re.M)[1])
    skill['durations']=[wind*12/6]*6+[tail*12/11]*11
    pipeline.OUT=OUT
    pipeline.CONFIG={
      'ash_knight':ash,
      'ember_oracle':{
        'Idle':clip('idle-walk-cycle-1657',1,6),
        'Walk':clip('idle-walk-cycle-1657',9,24),
        'Attack':clip('spell-cast-attack-1000',3,30,12,[15]),
        'Hit':clip('hit-and-die-1648',4,6,12),
        'Die':clip('hit-and-die-1648',7,32)},
      'oath_warden':{
        'Idle':clip('idle-walk-1648',1,4),
        'Walk':clip('idle-walk-1648',9,24),
        'Attack':clip('attack-slash-combo-1657',2,26,12,[4,16]),
        'Hit':clip('hit-and-die-0959',3,6,12),
        'Die':clip('hit-and-die-0959',7,32),
        'Skill':skill}}
    pipeline.install()
    report=json.loads((OUT/'manifest.json').read_text())
    for mid in ['ember_oracle','oath_warden']:
        p=ROOT/f'data/monsters/{mid}.tres';data=p.read_text(encoding='utf-8')
        if mid=='ember_oracle':
            if 'id="sep23_orb"' not in data:
                pos=data.index('[sub_resource')
                data=data[:pos]+'[ext_resource type="Texture2D" path="res://data/sprites/gullveig_fireball_texture.tres" id="sep23_orb"]\n\n'+data[pos:]
            ax,ay,_=report[mid]['source_geometry']['spell-cast-attack-1000']
            # Bright orb center on the outstretched hand in source frame 15.
            hand=[800-ax+200,1100-ay+389]
            fields={'ranged_attack':'true','ranged_attack_range':'650.0',
              'projectile_texture':'ExtResource("sep23_orb")','projectile_speed':'1000.0',
              'projectile_range':'1200.0','projectile_height':'65.0',
              'projectile_hit_size':'Vector2(42, 42)','projectile_fire_effect':'true',
              'projectile_orb_style':'true','projectile_orb_color':'Color(1.0, 0.43, 0.055, 1)',
              'projectile_aim_at_player':'false','projectile_down_angle':'0.0',
              'projectile_hand_positions':f'Dictionary[int, Vector2]({{12: Vector2({hand[0]}, {hand[1]})}})',
              'skill_hand_projectiles':'false'}
            report[mid]['projectile']={'source_frame':15,'animation_frame':12,'hand_canvas':hand,'shots':1,'speed':1000,'aim_at_player':False}
        else:
            ax,ay,_=report[mid]['source_geometry']['attack-slash-combo-1657']
            fields={'skill_hit_frames':'PackedInt32Array(6)',
              'ground_slam_anchor':f'Vector2({800-ax+270}, {1100-ay+817})'}
        for k,v in fields.items():data=set_field(data,k,v)
        p.write_text(data,encoding='utf-8')
    (OUT/'manifest.json').write_text(json.dumps(report,indent=2))

if __name__=='__main__':install()
