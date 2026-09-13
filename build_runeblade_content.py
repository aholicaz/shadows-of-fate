"""Author resource files for the Runeblade campaign; no save files are touched."""
from pathlib import Path
import json
def q(s): return json.dumps(s, ensure_ascii=False)
def arr(values): return 'Array[StringName]([' + ', '.join('&'+q(v) for v in values)+'])'
quests = [
('rb1_unsung_iron','R1 สิ่งที่ค้อนมิได้สอน','บรอกก์',1,['c2_8_hammer_truth'],'chapter2_done',[(2,'ผู้อาวุโสญอร์ดา',1,'นำชิ้นรูนไร้เสียงไปให้ญอร์ดา')],'รูนบนค้อนรู้จักแต่การดูด... นำชิ้นรูนไร้เสียงนี้ไปให้ญอร์ดาที่วานาเฮม นางอาจรู้ว่ามันเคยคืนพลังอย่างไร','ญอร์ดาอ่านรูนแล้วสินะ จงกลับไปฟังนาง เหล็กมีรูปแล้ว แต่ยังไม่มีคำสัตย์','rb_iron'),
('rb2_unbound_rune','R2 อักขระที่ปฏิเสธนาย','ผู้อาวุโสญอร์ดา',38,['rb1_unsung_iron','c3_1_open_gate'],'',[(4,'rb_rune_tablet',1,'อ่านศิลารูนข้างลานพิธีในเมือง')],'รูนนี้ไม่ยอมรับยศของผู้ถือ อ่านศิลาข้างลานพิธี แล้วนำมันติดตัวไปยังบึงหมอกเงิน','คมที่ไร้จังหวะย่อมแตกหัก แรงที่ไร้การควบคุมย่อมย้อนคืน จำคำนี้ไว้','rb_rune'),
('rb3_beneath_marsh','R3 เสียงจากใต้บึง','ผู้อาวุโสญอร์ดา',42,['rb2_unbound_rune','c3_3_mist_that_lingers','c3_4_song_of_child'],'',[(4,'rb_clue_stone',1,'ตรวจศิลารูนแตกในบึง'),(4,'rb_clue_shadow',1,'ตรวจเงารูปเขาในน้ำ'),(4,'rb_clue_bell',1,'ฟังกระดิ่งใต้รากใหญ่')],'ตามเสียงรูนในบึงหมอกเงิน ศิลา เงา และเสียงกระดิ่งจะนำเจ้าไปสู่ประตู','ใต้บึงมีวิหารที่อสูรเขาทมิฬยึดครอง เจ้าพบประตูแล้ว แต่ต้องเรียนรู้การควบคุมก่อน','rb_clues'),
('rb4_edge_and_force','R4 คมและแรง','ผู้อาวุโสญอร์ดา',48,['rb3_beneath_marsh','c3_6_withering'],'',[(5,'rb_trial_rhythm',1,'ผ่านบททดสอบจังหวะของคม'),(5,'rb_trial_force',1,'ผ่านบททดสอบน้ำหนักของดาบ')],'ไปยังศิลาทดสอบทางขวาของเมือง ใช้คอมโบปกติ และเปิดแผลด้วย Rending Wave ก่อนตามด้วย Bash ไม่จำเป็นต้องติดคริ','รูนทั้งสองประสานแล้ว เมื่อเจ้าเลเวล 50 ประตูใต้บึงจะเปิดให้ จงระวังลูกอสูรที่ไล่ต้อนจากด้านหลัง','rb_trials'),
('rb5_oath_eater','R5 ผู้กินคำสัตย์','ผู้อาวุโสญอร์ดา',50,['rb4_edge_and_force'],'',[(5,'rb_baphomet_defeated',1,'ปราบ Baphomet ในวิหารใต้ราก'),(5,'rb_core_freed',1,'ปลดวงจรรูนหลังบัลลังก์')],'เปิดซุ้มรากช่วงตะวันออกของบึงหมอกเงิน ทำลายเสาพันธนาการทั้งสาม แล้วปราบ Baphomet และปลดวงจรหลังบัลลังก์','เจ้าคืนอิสระให้รูนแล้ว กลับมาที่ลานเมืองเพื่อจารึกคำสัตย์ของตนเอง','rb_core'),
('rb6_runeblade','R6 คำสัตย์แห่งดาบรูน','ผู้อาวุโสญอร์ดา',50,['rb5_oath_eater'],'',[(4,'rb_ceremony',1,'อ่านคำสัตย์ที่ลานพิธีกลางวานาเฮม')],'บรอกก์ให้รูปแก่เหล็ก เจ้าให้ทิศทางแก่พลัง อ่านคำสัตย์ ณ ลานพิธี แล้วกลับมาหาข้า','ตั้งแต่นี้ เจ้าคือ Runeblade — อัศวินดาบรูน เลือกวิถีคมต่อเนื่องหรือดาบทลายได้ในผังสกิล และขอคืนแต้มอาชีพได้ที่ศิลารูน','runeblade_awakened'),
('rb7_ninth_inscription','R7 อักขระที่เก้า','ผู้อาวุโสญอร์ดา',50,['rb6_runeblade'],'',[(4,'rb_ninth_inscription',1,'อ่านอักขระจางที่ศิลาลานพิธี')],'รูนของเจ้ายังมีวงจรที่ไม่สว่าง อ่านบรรทัดสุดท้ายที่ศิลา บางทีการเดินทางนี้เพิ่งเริ่มต้น','เมื่อถึงเลเวล 90 จงกลับมาตรวจอักขระอีกครั้ง เส้นทางอาชีพขั้นถัดไปยังรอเรื่องราวจากดินแดนทางเหนือ','rb_next_job_hint')]
for sid,title,giver,level,prev,flag,objs,offer,done,outflag in quests:
    text='[gd_resource type="Resource" script_class="QuestData" format=3]\n\n[ext_resource type="Script" path="res://scripts/resources/quest_data.gd" id="q"]\n[ext_resource type="Script" path="res://scripts/resources/objective_data.gd" id="o"]\n'
    for i,(kind,target,count,label) in enumerate(objs):
        text+=f'\n[sub_resource type="Resource" id="O{i}"]\nscript = ExtResource("o")\nkind = {kind}\ntarget = &{q(target)}\ncount = {count}\ntext = {q(label)}\n'
    text+='\n[resource]\nscript = ExtResource("q")\n'
    for key,value in dict(id=sid,title=title,giver_name=giver,description=offer,dialog_offer=offer,dialog_progress='ตรวจเป้าหมายในสมุดเควส แล้วกลับมาคุยเมื่อครบ',dialog_complete=done,required_flag=flag,set_flag_on_complete=outflag).items(): text+=f'{key} = {q(value)}\n'
    text+=f'required_level = {level}\nrequired_job = &"'+('runeblade' if sid.startswith('rb7') else 'swordsman')+'"\nrequired_quests = '+arr(prev)+'\n'
    text+='objectives = Array[ExtResource("o")](['+', '.join(f'SubResource("O{i}")' for i in range(len(objs)))+'])\n'
    if sid=='rb6_runeblade': text+='reward_job = &"runeblade"\n'
    Path(f'data/quests/{sid}.tres').write_text(text,encoding='utf-8')

old=['sword_mastery','hp_recovery','bash','slash','magnum_break','endure','battle_cry','first_aid']
specs=[
('runic_vessel','กายารูน',4,0,0,0,0,{},'Max HP +2% และ Max SP +3% ต่อระดับ'),
('rune_guard','เกราะอักขระ',2,12,12,0,0,{},'โล่รับดาเมจ 4–12% Max HP นาน 3 วินาที'),
('blade_rhythm','จังหวะคมดาบ',4,0,0,0,0,{},'โจมตีปกติโดนสะสม 5 ชั้น เพิ่ม ASPD ชั้นละ 0.6–3% จังหวะเริ่มลดหลังหยุดตี 3 วินาที'),
('keen_inscription','รูนคมสังหาร',4,0,0,0,0,{'blade_rhythm':5},'คริ +2 จุดเปอร์เซ็นต์ และตัวคูณคริ +0.04 ต่อระดับ'),
('rune_flurry','หกคมอักขระ',0,16,6,2.4,.3,{'keen_inscription':5},'ฟัน 6 ฮิต รวม 240–360% ATK แต่ละฮิตติดคริได้ สร้างตราครั้งเดียวต่อท่า'),
('unbroken_edge','คมดาบไม่สิ้นสุด',2,30,24,0,0,{'rune_flurry':5},'ใช้ 3 ตรา บัฟ 8 วินาที ASPD +5–25% ทุกโจมตีปกติที่โดนครบ 3 ครั้งมีเงาดาบ 80% ไม่คริ ไม่สร้างตรา'),
('tempered_might','พลังเหล็กกล้า',4,0,0,0,0,{},'ดาบหนักแรงขึ้น 4% และมองข้าม DEF 5% ต่อระดับ ดาบหนักไม่คริ'),
('anvil_cleave','ดาบฟาดทั่ง',0,18,5,4.5,.5,{'tempered_might':5},'ฟาดหนัก 450–650% ATK สูงสุด 3 ตัว เตรียมท่า 0.4 วินาที ไม่คริ'),
('faultline','รอยแยกอักขระ',0,24,10,5,.5,{'anvil_cleave':5},'รอยรูนปะทุด้านหน้า 550 px หลัง 0.25 วินาที 500–700% ATK สูงสุด 6 ตัว ไม่คริ'),
('worldcleaver','ดาบผ่าโลก',0,36,18,10,1,{'faultline':5},'ใช้ 3 ตรา ฟาด 1000–1400% ATK ระยะ 650 px สูงสุด 6 ตัว ไม่คริ เตรียม 0.7 วินาที ยกเลิกด้วยพุ่งหลบได้ใน 0.35 วินาทีแรก')]
for sid,name,kind,sp,cd,dmg,per,req,desc in specs:
    text='[gd_resource type="Resource" script_class="SkillData" format=3]\n[ext_resource type="Script" path="res://scripts/resources/skill_data.gd" id="s"]\n[ext_resource type="Texture2D" path="res://Sprites/effects/rending_wave_icon.svg" id="i"]\n[resource]\nscript = ExtResource("s")\n'
    text+=f'id = &{q(sid)}\ndisplay_name = {q(name)}\ndescription = {q(desc)}\nicon = ExtResource("i")\nmax_level = 5\njob_ids = {arr(["runeblade"])}\nrequired_level = 50\ntype = {kind}\nsp_cost_base = {sp}\nsp_cost_per_level = 0.0\ncooldown = {float(cd)}\ndamage_mult_base = {float(dmg)}\ndamage_mult_per_level = {float(per)}\nrequired_skills = '+json.dumps(req)+'\n'
    if sid=='runic_vessel': text+='passive_effects = {"max_hp_percent": 2.0, "max_sp_percent": 3.0}\n'
    if sid=='keen_inscription': text+='passive_effects = {"crit": 2.0, "crit_damage_percent": 4.0}\n'
    Path(f'data/skills/{sid}.tres').write_text(text,encoding='utf-8')
job=Path('data/jobs/swordsman.tres').read_text(encoding='utf-8')
Path('data/jobs/swordsman.tres').write_text(job.replace('job_change_level = 40','job_change_level = 50').replace('&"knight"','&"runeblade"'),encoding='utf-8')
job=job.replace('id = &"swordsman"','id = &"runeblade"').replace('display_name = "นักดาบ"','display_name = "Runeblade — อัศวินดาบรูน"').replace('job_change_level = 40','job_change_level = 90').replace('next_job_ids = Array[StringName]([&"knight"])','next_job_ids = Array[StringName]([])').replace('atk_mod = 1.15','atk_mod = 1.25').replace('sp_per_level = 2.5','sp_per_level = 3.0')
job=job[:job.index('skill_ids =')]+ 'skill_ids = '+arr(old+[s[0] for s in specs])+'\njob_change_level = 90\nnext_job_ids = Array[StringName]([])\n'
Path('data/jobs/runeblade.tres').write_text(job,encoding='utf-8')
for sid in old:
    path=Path(f'data/skills/{sid}.tres'); text=path.read_text(encoding='utf-8')
    if 'job_ids =' not in text: text+='\njob_ids = '+arr(['swordsman','runeblade'])+'\n'
    else: text=text.replace('[&"swordsman"]','[&"swordsman", &"runeblade"]')
    path.write_text(text,encoding='utf-8')

# Distinct vector icons remain editable, and do not need raster sprite generation.
symbols = {
'runic_vessel':'<path d="M48 75L19 45Q12 19 33 22L48 35L63 22Q85 20 77 45Z"/>',
'rune_guard':'<path d="M21 22L48 13L75 22V49Q69 73 48 84Q25 70 21 49Z"/><path d="M48 28V62M34 45H62"/>',
'blade_rhythm':'<path d="M15 30H65L54 20M22 48H78L67 38M15 67H65L54 57"/>',
'keen_inscription':'<path d="M48 10L56 37L82 48L56 59L48 86L40 59L14 48L40 37Z"/>',
'rune_flurry':'<path d="M17 16Q74 34 28 78M33 14Q90 35 44 82M49 17Q101 40 61 78"/>',
'unbroken_edge':'<path d="M48 48C20 8 3 62 26 65C46 68 55 13 75 29C97 48 66 89 48 48Z"/>',
'tempered_might':'<path d="M14 35H83L70 49H56V63L74 74H22L39 62V49H29Z"/>',
'anvil_cleave':'<path d="M35 12L60 9L55 57L42 71L31 55ZM15 81H80M20 61L12 50M75 61L86 49"/>',
'faultline':'<path d="M53 11L33 35L59 47L31 72L49 85M10 78H29M56 78H87"/>',
'worldcleaver':'<path d="M48 9V67M35 48L48 67L61 48M9 78L30 69L48 81L66 69L87 78"/>'}
for sid,symbol in symbols.items():
    color='#79dded' if sid in ['blade_rhythm','keen_inscription','rune_flurry','unbroken_edge'] else '#ffc66b'
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96"><rect width="96" height="96" rx="15" fill="#1c2635"/><g fill="none" stroke="{color}" stroke-width="5" stroke-linejoin="round" stroke-linecap="round">{symbol}</g></svg>'
    Path(f'Sprites/effects/{sid}_icon.svg').write_text(svg,encoding='utf-8')
    p=Path(f'data/skills/{sid}.tres'); s=p.read_text(encoding='utf-8').replace('rending_wave_icon.svg',f'{sid}_icon.svg')
    if sid in ['rune_guard','unbroken_edge']:
        s+=f'\nduration_base = {3.0 if sid=="rune_guard" else 8.0}\nduration_per_level = 0.0\n'
    if sid in ['anvil_cleave','faultline','worldcleaver']:
        s+=f'\nmax_targets = {3 if sid=="anvil_cleave" else 6}\nrange_x = {180.0 if sid=="anvil_cleave" else (550.0 if sid=="faultline" else 650.0)}\n'
    p.write_text(s,encoding='utf-8')
p=Path('data/jobs/runeblade.tres'); s=p.read_text(encoding='utf-8'); s=s.replace('นักรบผู้เชี่ยวชาญดาบ เลือดหนา พลังโจมตีสูง เหมาะกับการยืนแนวหน้า','อัศวินผู้จารึกรูนด้วยพลังของตน เลือกคมต่อเนื่องหรือดาบทลาย อักขระขั้นถัดไปรอเมื่อเลเวล 90'); p.write_text(s,encoding='utf-8')
p=Path('data/quests/rb6_runeblade.tres'); s=p.read_text(encoding='utf-8'); s+='\nchoice_prompt = "เจ้าจะจารึกคำสัตย์ใดลงในดาบ? เปลี่ยนสายภายหลังได้"\nchoice_options = Array[String](["คมดาบจะไม่หยุดก่อนทุกคนปลอดภัย — แนะนำสายตีไวคริ", "ข้าจะฟาดสิ่งกีดขวางให้พัง — แนะนำสายดาบหนัก"])\nchoice_flags = Array[StringName]([&"rb_prefers_edge", &"rb_prefers_sunder"])\n'; p.write_text(s,encoding='utf-8')
