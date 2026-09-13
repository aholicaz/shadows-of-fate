"""Focused balance edits; preserves IDs and unrelated story/map work."""
from pathlib import Path
import re, json, shutil
from balance_audit import ROOT, read

def save(p, text):
    original = ROOT/'output/balance/original'/p.relative_to(ROOT)
    if p.exists() and not original.exists():
        original.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(p, original)
    p.write_text(text, encoding='utf-8')

def replace(path, old, new):
    p = ROOT/path
    text = p.read_text(encoding='utf-8-sig')
    assert text.count(old) == 1, (path, old[:90], text.count(old))
    save(p, text.replace(old, new))

def values(path, fields):
    p = ROOT/path
    text = p.read_text(encoding='utf-8-sig')
    pre, main = text.split('[resource]',1)
    for k,v in fields.items():
        v = json.dumps(v, ensure_ascii=False)
        line = f'{k} = {v}'
        if re.search(rf'^{k} = .*$', main, re.M):
            main = re.sub(rf'^{k} = .*$', lambda m:line, main, flags=re.M)
        else: main += '\n'+line+'\n'
    save(p, pre+'[resource]'+main)

replace('scripts/core/combat.gd', 'return float(row[defense_element])',
'''# Elements describe effects, never a hidden immunity or fourfold HP wall.
\treturn 1.0''')
replace('scripts/resources/item_data.gd','@export var damage_percent: float = 0.0', '''@export var damage_percent: float = 0.0
## Bonuses distinguish sustained critical attacks from deliberate skill casts.
@export var skill_damage_percent: float = 0.0
@export var crit_damage_percent: float = 0.0
## 0 neutral, 1 fire (burn), 4 wind/lightning (chain).
@export_enum("Neutral:0", "Fire:1", "Lightning:4") var attack_element: int = 0''')
replace('scripts/core/equipment.gd','\t_add(b, &"damage_percent", d.damage_percent)', '''\t_add(b, &"damage_percent", d.damage_percent)
\t_add(b, &"skill_damage_percent", d.skill_damage_percent)
\t_add(b, &"crit_damage_percent", d.crit_damage_percent)''')
replace('scripts/core/player_stats.gd','var crit_damage: float = 1.5','var crit_damage: float = 1.5\nvar skill_damage_percent: float = 0.0')
replace('scripts/core/player_stats.gd','\tcrit_damage = 1.5 + _pct(&"crit_damage_percent") / 100.0', '''\tcrit = clampf(crit, 0.0, 100.0)
\tcrit_damage = 1.5 + clampf(_pct(&"crit_damage_percent"), 0.0, 100.0) / 100.0
\tskill_damage_percent = clampf(_pct(&"skill_damage_percent"), 0.0, 80.0)''')
replace('scripts/core/player_stats.gd','aspd = maxf(0.2, aspd_raw * (1.0 + (_pct(&"aspd_percent") + _flat(&"aspd_percent")) / 100.0))','aspd = clampf(aspd_raw * (1.0 + (_pct(&"aspd_percent") + _flat(&"aspd_percent")) / 100.0), 0.2, 5.0)')
replace('scripts/core/player_stats.gd','return int(round(35.0 * pow(level, 1.9)))','return int(round(35.0 * pow(level, 1.9) * (1.0 + maxf(0.0, level - 70.0) * 0.035)))')
replace('scripts/core/refine_system.gd','const SUCCESS_RATE := [100.0, 100.0, 100.0, 90.0, 80.0, 65.0, 50.0, 35.0, 25.0, 15.0]','const SUCCESS_RATE := [100.0, 100.0, 100.0, 100.0, 90.0, 80.0, 70.0, 60.0, 50.0, 40.0]')
replace('scripts/core/refine_system.gd','''\tvar value_factor: float = 1.0 + (d.buy_price / 2000.0 if d != null else 0.0)
\treturn int(BASE_COST * (inst.refine + 1) * pow(COST_GROWTH, inst.refine) * value_factor)''','''\tvar level := clampi(d.required_level if d != null else 1, 1, 99)
\tvar tier := float(level - 1) / 98.0
\tvar base := lerpf(1000.0, 20000.0, tier)
\treturn clampi(int(round(base * (1.0 + 1.5 * clampi(inst.refine, 0, 9) / 9.0) / 100.0)) * 100, 1000, 50000)''')
replace('scripts/core/refine_system.gd','''## ค่าธรรมเนียมซีนี = BASE_COST * (refine+1) * COST_GROWTH^refine
const BASE_COST := 500
const COST_GROWTH := 1.6''','''## Per attempt: equipment level and refine rank only; 1,000–50,000 z.''')
replace('scripts/resources/item_data.gd','func is_equipment() -> bool:', '''## Every rank scales with base equipment power; old per-rank values remain a floor.
func refine_atk_gain() -> int:
\tif type != Type.WEAPON or not refinable: return 0
\treturn maxi(refine_atk_per_level, int(ceil(atk * 0.05)))

func refine_def_gain() -> int:
\tif type != Type.ARMOR or not refinable: return 0
\treturn maxi(refine_def_per_level, int(ceil(def * 0.06)))

func is_equipment() -> bool:''')
for path in ['scripts/core/refine_system.gd','scripts/resources/item_instance.gd','scripts/core/equipment.gd']:
    p = ROOT/path
    text = p.read_text(encoding='utf-8-sig').replace('d.refine_atk_per_level','d.refine_atk_gain()').replace('d.refine_def_per_level','d.refine_def_gain()')
    save(p,text)
replace('scripts/ui/item_info_popup.gd','["ลดคูลดาวน์", d.cooldown_reduction_percent]]:', '["ลดคูลดาวน์", d.cooldown_reduction_percent], ["ดาเมจสกิล", d.skill_damage_percent], ["ดาเมจคริ", d.crit_damage_percent]]:')
replace('scripts/ui/item_info_popup.gd','\tif d.aspd_percent != 0.0: stats.append("ASPD %+.0f%%" % d.aspd_percent)', '''\tif d.aspd_percent != 0.0: stats.append("ASPD %+.0f%%" % d.aspd_percent)
\tif d.attack_element == 1: stats.append("ไฟ: โจมตีติดเผาไหม้ 3 วินาที ไม่ซ้อนทับ")
\tif d.attack_element == 4: stats.append("สายฟ้า: โอกาส 25% ชิ่งใส่ศัตรูใกล้เคียง 2 ตัว (พัก 0.6 วิ)")''')
replace('scripts/ui/equipment_window.gd','"crit_damage_percent": "ดาเมจคริ",','"crit_damage_percent": "ดาเมจคริ", "skill_damage_percent": "ดาเมจสกิล",')

# Give existing drops a consistent build role at every progression tier.
speed = {
'rapier':(5,4,6),'katana':(6,4,7),'marsh_cutter':(7,5,8),'aesir_warblade':(8,6,9),
'frost_edge':(9,7,10),'prism_blade':(10,8,11),'stag_horn_saber':(10,8,12),
'conduit_edge':(11,9,12),'mist_saber':(11,9,12),'garm_fang':(12,10,14),
}
heavy = {'iron_blade':8,'claymore':10,'runic_blade':12,'root_sword':12,'sentinel_blade':14,
'flame_sword':16,'ember_of_gullveig':18,'troll_cleaver':18,'wall_greatsword':20,
'stone_hrungnir_blade':20,'light_crystal_sword':22,'ferryman_oar_blade':22,'bone_greatsword':24,'name_blade':24}
for id,(agi,crit,aspd) in speed.items():
    values(f'data/items/{id}.tres',dict(bonus_agi=agi,crit=crit,aspd_percent=float(aspd),crit_damage_percent=10.0,damage_percent=0.0))
for id,power in heavy.items():
    values(f'data/items/{id}.tres',dict(skill_damage_percent=float(power),bonus_str=4+power//4,max_sp=20+power*2,cooldown_reduction_percent=3.0,damage_percent=0.0))
for id in ['flame_sword','ember_of_gullveig']: values(f'data/items/{id}.tres',dict(attack_element=1))
values('data/items/conduit_edge.tres',dict(attack_element=4))
for id in ['brooch','wolf_cloak','boots','mist_cloak','root_boots','frost_wolf_coat','troll_boots','moth_wing_cape','silent_step','mist_shroud','river_walker']:
    d=read(ROOT/f'data/items/{id}.tres'); tier=max(1,d.get('required_level',1)//20)
    values(f'data/items/{id}.tres',dict(bonus_agi=2+tier,aspd_percent=float(3+tier),crit=1+tier,damage_percent=0.0))
for id in ['ring','ash_ring','heart_pendant','echo_ring','radiant_ring','odin_ring']:
    d=read(ROOT/f'data/items/{id}.tres'); tier=max(1,d.get('required_level',1)//20)
    values(f'data/items/{id}.tres',dict(skill_damage_percent=float(3+tier),cooldown_reduction_percent=float(2+tier),max_sp=15+tier*10,damage_percent=0.0))
for id in ['dwarven_mail','bark_armor','sentinel_plate','jotun_helm','wall_plate','crystal_cloak','elven_plate','bone_armor','hel_half_plate']:
    d=read(ROOT/f'data/items/{id}.tres'); tier=max(1,d.get('required_level',1)//20)
    values(f'data/items/{id}.tres',dict(skill_damage_percent=float(3+tier),bonus_str=2+tier,max_sp=15+tier*10))

# New boss chase items reuse existing registered weapon/icon art.
for id,template,fields in [
 ('storm_runeblade','runic_blade',dict(display_name='ดาบรูนอสูรสายฟ้า',description='ล่าจากอสูรสายฟ้า: ดาบสายตีไวคริ สายฟ้าชิ่ง 25% ไปยังศัตรูใกล้เคียง 2 ตัว',required_level=30,atk=76,bonus_agi=7,crit=6,aspd_percent=10.0,crit_damage_percent=12.0,attack_element=4,matk=0,bonus_int=0,card_slots=1)),
 ('storm_pendant','brooch',dict(display_name='สร้อยหัวใจสายฟ้า',description='ล่าจากอสูรสายฟ้า: เพิ่มความเร็วและความรุนแรงของคริติคอล',required_level=30,bonus_agi=4,crit=4,aspd_percent=5.0,crit_damage_percent=10.0,card_slots=1)),
 ('forge_core_pendant','ring',dict(display_name='สร้อยแก่นเตาหลอม',description='ล่าจากผู้พิทักษ์เตาหลอม: สะสมพลังไว้ปล่อยสกิลหนัก',required_level=38,bonus_str=5,skill_damage_percent=10.0,cooldown_reduction_percent=5.0,max_sp=50,card_slots=1)),
]:
    p=ROOT/f'data/items/{id}.tres'
    assert not p.exists(), id
    text=(ROOT/f'data/items/{template}.tres').read_text(encoding='utf-8-sig')
    text=re.sub(r' uid="uid://[^"]+"','',text)
    text=text.replace(f'id = &"{template}"',f'id = &"{id}"')
    save(p,text); values(f'data/items/{id}.tres',fields)

def drop(monster,item,chance):
    p=ROOT/f'data/monsters/{monster}.tres'; text=p.read_text(encoding='utf-8-sig')
    if f'item_id = &"{item}"' in text: return
    script=re.search(r'path="res://scripts/resources/drop_entry.gd" id="([^"]+)"',text)[1]
    resource=f'Balance_{item}'
    text=text.replace('[resource]',f'[sub_resource type="Resource" id="{resource}"]\nscript = ExtResource("{script}")\nitem_id = &"{item}"\nchance = {chance:.1f}\n\n[resource]')
    text=re.sub(r'^(drops = .*?)\]\)$',lambda m:m[1]+f', SubResource("{resource}")])',text,flags=re.M)
    save(p,text)
for mon,item,chance in [('stormscar','storm_runeblade',18),('stormscar','storm_pendant',22),('forge_guardian','forge_core_pendant',22),('wolf','brooch',3),('steel_beetle','iron_blade',4),('mist_sprite','mist_cloak',5),('vanir_sentinel','sentinel_blade',5),('frost_wolf','frost_edge',4),('ice_troll','troll_cleaver',4),('echo_wraith','echo_ring',4),('stone_hrungnir','stone_hrungnir_blade',18)]: drop(mon,item,chance)

# Reward budgets depend on monster level/role, not exponential chapter prices.
sources={}
for p in (ROOT/'data/monsters').glob('*.tres'):
    d=read(p); lv=max(1,d.get('level',1)); boss=d.get('is_boss',False)
    for id in re.findall(r'item_id = &"([^"]+)"',p.read_text(encoding='utf-8-sig')):
        sources.setdefault(id,[]).append((lv,boss))
    curve=35*lv**1.9
    budget=round(curve*(0.08 if boss else 1/(50+1.5*lv)))
    exp=min(d.get('exp_reward',0),budget)
    coin=round(200+lv*30 if boss else 10+lv*4)
    fields=dict(exp_reward=exp,zeny_min=min(d.get('zeny_min',0),round(coin*.7)),zeny_max=min(d.get('zeny_max',0),round(coin*1.3)))
    if d.get('job_exp_reward',0)>0: fields['job_exp_reward']=min(d['job_exp_reward'],round(exp*.7))
    values(str(p.relative_to(ROOT)),fields)
for p in (ROOT/'data/items').glob('*.tres'):
    d=read(p); typ=d.get('type',3); old=d.get('sell_price',40)
    if old<=0 or typ==4: continue
    fields={}
    if typ in [1,2]:
        lv=max(1,d.get('required_level',1)); buy=min(d.get('buy_price',100),round(800+12*lv*lv))
        sell=min(old,round((80+lv*28)*(1.2 if typ==1 else 1)),buy//5)
        fields=dict(buy_price=buy,sell_price=sell)
    elif typ==3 and p.stem in sources:
        lv=min(v[0] for v in sources[p.stem]); boss=all(v[1] for v in sources[p.stem])
        budget=round(100+lv*12 if boss else 4+lv**1.3)
        fields['sell_price']=min(old,budget)
    if fields: values(str(p.relative_to(ROOT)),fields)

for id,fields in {
 'rune_flurry':dict(description='พุ่งเข้าประชิดสูงสุด 360 px แล้วฟัน 6 ครั้ง รวม 540–780% ATK สูงสุด 3 ตัว ติดคริได้ ความเร็วท่าเพิ่มตาม ASPD สร้างรูนครั้งเดียว',damage_mult_base=5.4,damage_mult_per_level=0.6,cooldown=5.0,max_targets=3,range_x=230.0,hit_count=6),
 'faultline':dict(display_name='ดาบปักอักขระ',description='ปาดาบปักด้านหน้า 320 px หมุนฟัน 6 ครั้งใน 2.4 วิ รวม 720–1040% ATK รัศมี 190 px สูงสุด 6 ตัวต่อครั้ง ไม่คริ เคลื่อนที่ต่อได้หลังปาดาบ สร้างรูนได้ครั้งเดียว',damage_mult_base=7.2,damage_mult_per_level=0.8,cooldown=9.0,hit_count=6),
 'worldcleaver':dict(display_name='ฝนดาบผ่าโลก',description='ใช้ 3 รูน เรียกฝนดาบ 5 ระลอกใน 1 วิ รวม 1400–2000% ATK รัศมี 360 px สูงสุด 6 ตัวต่อระลอก ไม่คริ เตรียม 0.7 วิ ยกเลิกด้วยพุ่งหลบใน 0.35 วิแรกได้',damage_mult_base=14.0,damage_mult_per_level=1.5,hit_count=5),
 'anvil_cleave':dict(description='ฟาดหนัก 500–740% ATK สูงสุด 3 ตัว เตรียม 0.28 วิ ไม่คริ เปิดแผลให้ท่าถัดไปแรงขึ้น 15% นาน 4 วิ',damage_mult_base=5.0,damage_mult_per_level=0.6,range_x=230.0),
}.items(): values(f'data/skills/{id}.tres',fields)
print('Balance data, equipment, refinement and economy updated.')
