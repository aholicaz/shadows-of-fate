from pathlib import Path
import re,json,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'output/balance_v2'
def edit(path,fn):
    p=ROOT/path;b=OUT/'before'/path;b.parent.mkdir(parents=True,exist_ok=True)
    if not b.exists():shutil.copy2(p,b)
    p.write_text(fn(p.read_text(encoding='utf-8')),encoding='utf-8')
def rep(s,a,b):
    assert a in s,a[:100]
    return s.replace(a,b)
def field(s,k,v):
    pat=rf'^{re.escape(k)} = (?:\{{[^}}]*\}}|[^\n]*)'
    if re.search(pat,s,re.M):return re.sub(pat,lambda m:f'{k} = {v}',s,flags=re.M)
    return s+f'\n{k} = {v}\n'
config={
'bash':{'range_x':350.0,'range_y':320.0,'max_targets':6,'effect_hit_size':'Vector2(360, 320)','effect_max_targets':6,'effect_stick_on_hit':'false','effect_height':380.0,'description':'ฟาดดาบ 2 จังหวะ กวาดศัตรูด้านหน้าสูงสุด 6 ตัว'},
'slash':{'range_x':240.0,'dash_range_y':300.0,'dash_distance':550.0,'dash_distance_per_level':15.0,'max_targets':0,'max_targets_by_level':'{}','description':'พุ่งทะลุฝูงมอน 550–685 px ฟันแต่ละตัวที่ขวางทาง ไม่หยุดเมื่อโดนมอน'},
'magnum_break':{'wave_distance':900.0,'range_x':900.0,'range_y':280.0,'max_targets':10,'effect_hit_size':'Vector2(140, 280)','effect_height':400.0,'description':'คลื่นดาบระยะ 900 px ทะลุสูงสุด 10 ตัว เปิดแผลให้รับดาเมจกายภาพเพิ่ม 20–35% นาน 5 วิ แผลไม่ซ้อน ยิงติดกำแพง'},
'rune_lunge':{'dash_distance':900.0,'dash_distance_per_level':15.0,'range_x':280.0,'dash_range_y':340.0,'max_targets':0,'damage_mult_per_level':0.6,'description':'พุ่งทะลุฝูงมอน 900–1035 px ฟัน 340–880% ATK ต่อเป้าหมาย ติดคริได้ เมื่อโดนเสริมหกคมครั้งถัดไป +20% ภายใน 3 วิ หยุดเฉพาะกำแพง'},
'rune_flurry':{'range_x':400.0,'range_y':330.0,'max_targets':8,'description':'เข้าประชิดได้ 480 px แล้วกวาด 6 คม ระยะฟัน 400 px รวม 540–1080% ATK สูงสุด 8 ตัว คริได้ ฟันเร็วขึ้นตาม ASPD สร้างรูนครั้งเดียว'},
'anvil_cleave':{'range_x':440.0,'range_y':340.0,'max_targets':8,'description':'ฟาดกวาดระยะ 440 px รวม 500–1040% ATK สูงสุด 8 ตัว ไม่คริ เปิดแผลรับดาเมจเพิ่ม 15% นาน 4 วิ'},
'faultline':{'range_x':320.0,'range_y':340.0,'field_radius':320.0,'field_offset':420.0,'max_targets':10,'description':'ดาบที่สวมอยู่ปักด้านหน้า 420 px วงอักขระหมุนฟัน 6 ครั้ง รัศมี 320 px รวม 720–1440% ATK สูงสุด 10 ตัวต่อครั้ง ไม่คริ เคลื่อนที่ต่อได้ สร้างรูนครั้งเดียว'},
'worldcleaver':{'range_x':520.0,'range_y':420.0,'field_radius':520.0,'field_offset':220.0,'max_targets':12,'description':'ใช้ 3 รูน เรียกฝนดาบ 5 ระลอก รวม 1400–2750% ATK รัศมี 520 px สูงสุด 12 ตัวต่อระลอก ไม่คริ เตรียม 0.7 วิ ยกเลิกด้วยหลบใน 0.35 วิแรกได้'},
'erasing_cut':{'range_x':500.0,'range_y':350.0,'max_targets':8,'description':'ใช้ 3 ตรา ฟันลบนามระยะ 500 px สูงสุด 8 ตัว รวม 900–1500% ATK ไม่คริ ได้ผลจากพลังเหล็กกล้า'},
'rune_guard':{'description':'โล่รับดาเมจ 4–22% Max HP นาน 3 วินาที'},
'blade_rhythm':{'description':'ตีปกติโดนสะสม 5 ชั้น เพิ่ม ASPD ชั้นละ 0.6–6% จังหวะลดหลังหยุดตี 3 วิ'},
'unbroken_edge':{'description':'ใช้ 3 ตรา เพิ่ม ASPD 5–50% นาน 8 วิ ตีปกติครบ 3 ครั้งมีเงาดาบ 80% ATK ไม่สร้างตรา'},
'ninth_inscription':{'description':'ใช้ 4 ตรา วงอักขระรัศมี 500 px นาน 3 วิ โจมตีในวงคริ 100% และมองข้าม DEF จบแล้วระเบิด 2000–2800% ATK ต้องมีกายาอักขระที่เก้า Lv.5'},
}
rune_ids=['runic_vessel','rune_guard','blade_rhythm','keen_inscription','rune_flurry','rune_lunge','unbroken_edge','tempered_might','anvil_cleave','faultline','worldcleaver']
# Entry skills are available immediately; later nodes state their real dependency.
for id in rune_ids:
    config.setdefault(id,{})['max_level']=10
for id,values in config.items():
    def update(s):
        for k,v in values.items():
            value=json.dumps(v,ensure_ascii=False) if k=='description' else str(v)
            s=field(s,k,value)
        return s
    edit(f'data/skills/{id}.tres',update)
edit('scripts/resources/skill_data.gd',lambda s:rep(s,'@export var range_y: float = 80.0','@export var range_y: float = 80.0\n@export var field_radius: float = 0.0\n@export var field_offset: float = 0.0'))
def player(s):
    s=rep(s,'\t\tif _dash_max_targets > 0 and _dash_hits.size() >= _dash_max_targets:\n\t\t\t_dash_time = 0.0\n\t\t\treturn','\t\tif _dash_max_targets > 0 and _dash_hits.size() >= _dash_max_targets:\n\t\t\treturn')
    a=s.index('\t# The rune follow-up should leave enemies in front')
    b=s.index('\n\nfunc is_dashing',a)
    s=s[:a]+s[b:]
    # A hit quota limits damage, never travel, including subsequent frames.
    s=rep(s,'func _dash_damage() -> void:\n','func _dash_damage() -> void:\n\tif _dash_max_targets>0 and _dash_hits.size()>=_dash_max_targets: return\n')
    return s
edit('scripts/entities/player.gd',player)
def combat(s):
    s=rep(s,'const INSCRIPTION_RADIUS := 350.0','const INSCRIPTION_RADIUS := 500.0')
    s=rep(s,'approach_left = 360.0','approach_left = 480.0')
    s=rep(s,'field_center(320.0 if id == &"faultline" else 160.0, dir)','field_center(s.field_offset, dir)')
    s=rep(s,'var reach := 230.0 if id in [&"rune_flurry",&"anvil_cleave"] else 240.0','var reach := s.range_x')
    s=rep(s,'var cap := 1 if id == &"erasing_cut" else 3','var cap := s.max_targets_at(lv)')
    s=rep(s,'var box := Rect2(Vector2(origin.x if dir>0 else origin.x-reach,origin.y-250),Vector2(reach,260))','var skill := GameData.get_skill(id)\n\tvar height := skill.range_y\n\tvar box := Rect2(Vector2(origin.x-90 if dir>0 else origin.x-reach,origin.y-height),Vector2(reach+90,height+30))')
    return s
edit('scripts/entities/runeblade_combat.gd',combat)
def fields(s):
    s=rep(s,'var pulses := 6','var target_cap := 10\nvar height := 340.0\nvar weapon_visual: Node2D\nvar pulses := 6')
    s=rep(s,'\tposition = at','\tposition = at\n\tvar skill := GameData.get_skill(id)\n\tradius = skill.field_radius\n\theight = skill.range_y\n\ttarget_cap = skill.max_targets_at(PlayerState.skills.level_of(id))')
    s=s.replace('\t\tradius = 360.0\n','')
    s=rep(s,'\tz_index = 64','''	z_index = 64
	if source==&"faultline":
		weapon_visual=preload("res://scripts/entities/planted_weapon_visual.gd").new()
		weapon_visual.configure(PlayerState.equipment.weapon())
		add_child(weapon_visual)''')
    s=rep(s,'\telapsed += delta','\telapsed += delta\n\tif is_instance_valid(weapon_visual):\n\t\tweapon_visual.position.y=-maxf(0,0.16-elapsed)*1700\n\t\tweapon_visual.modulate.a=clampf((0.16+pulses*interval+0.18-elapsed)/0.25,0,1)')
    s=rep(s,'Vector2(-radius, -270), Vector2(radius * 2, 300)','Vector2(-radius, -height), Vector2(radius * 2, height+30)')
    s=rep(s,'if hits >= 6: break','if hits >= target_cap: break')
    a=s.index('\t\tvar angle := elapsed * 12.0')
    b=s.index('\n\telse:',a)
    s=s[:a]+'''		# Moving elliptical ribbons orbit the equipped blade, as in the skill icon.
		for band in range(3):
			var ribbon := PackedVector2Array()
			for j in range(45):
				var a := elapsed*5.0+band*TAU/3.0+j/44.0*PI*1.5
				ribbon.append(Vector2(cos(a)*radius*(0.78+band*0.07),-90-band*25+sin(a)*42))
			draw_polyline(ribbon,Color(color,alpha*0.12),18,true)
			draw_polyline(ribbon,Color(color,alpha*0.85),4,true)
			draw_polyline(ribbon,Color(0.9,1,1,alpha*0.95),1.5,true)
'''+s[b:]
    return s
edit('scripts/entities/runic_blade_field.gd',fields)
print('AoE, travel, rank caps and live resource-driven field geometry updated.')
