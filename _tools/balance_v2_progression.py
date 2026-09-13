from pathlib import Path
import shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'output/balance_v2'
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'.gdignore').touch()
def edit(path,fn):
    p=ROOT/path
    b=OUT/'before'/path
    b.parent.mkdir(parents=True,exist_ok=True)
    if not b.exists(): shutil.copy2(p,b)
    p.write_text(fn(p.read_text(encoding='utf-8')),encoding='utf-8')
def rep(s,a,b):
    assert a in s,a[:100]
    return s.replace(a,b)

def stats(s):
    s=rep(s,'@export var skill_points: int = 0','''@export var skill_points: int = 0
## Archived profession records; current profession remains in the public fields above.
@export var job_progress: Dictionary = {}
var progression_version := 1

func profession_state(id: StringName) -> Dictionary:
	if id == job_id: return {"level":job_level,"exp":job_exp_current,"points":skill_points}
	return job_progress.get(String(id), {"level":0,"exp":0,"points":0}).duplicate()

func has_profession(id: StringName) -> bool:
	return id == job_id or job_progress.has(String(id))

func points_for(id: StringName) -> int:
	return int(profession_state(id).points)

func add_skill_points(id: StringName, amount: int) -> void:
	if id == job_id:
		skill_points = maxi(0,skill_points+amount)
		return
	var record := profession_state(id)
	record.points = maxi(0,int(record.points)+amount)
	job_progress[String(id)] = record

func all_skill_points() -> int:
	var total := skill_points
	for id in job_progress:
		if StringName(id) != job_id: total += int(job_progress[id].get("points",0))
	return total

func change_profession(id: StringName) -> void:
	if id == job_id or GameData.get_job(id)==null: return
	job_progress[String(job_id)] = profession_state(job_id)
	var next: Dictionary = job_progress.get(String(id), {"level":1,"exp":0,"points":0})
	job_id = id
	job_level = maxi(1,int(next.level))
	job_exp_current = int(next.exp)
	skill_points = int(next.points)
	job_progress.erase(String(id))

func earned_job_levels() -> int:
	var total := job_level-1
	for id in job_progress:
		if StringName(id)!=job_id: total += maxi(0,int(job_progress[id].get("level",1))-1)
	return total

## One-time conversion: preserve learned ranks and total unspent points, never mint points.
func migrate_job_progress(book: SkillBook, flags: Dictionary) -> void:
	if progression_version>=1: return
	progression_version=1
	if job_id not in [&"runeblade",&"ninth_edge"]: return
	var old_level := job_level
	var sword_end := clampi(int(flags.get(&"runeblade_start_job_level",50)),1,mini(50,old_level))
	var stages: Array = [[&"swordsman",sword_end]]
	if job_id==&"ninth_edge":
		var rune_end := clampi(int(flags.get(&"ninth_edge_start_job_level",80)),sword_end,old_level)
		stages.append([&"runeblade",rune_end-sword_end+1])
		job_level=old_level-rune_end+1
	else: job_level=old_level-sword_end+1
	for stage in stages:
		var owner: StringName=stage[0]
		var spent := 0
		for id in book.learned:
			if SkillBook.profession_of(id)==owner: spent+=book.level_of(id)
		var remaining := mini(skill_points,maxi(0,int(stage[1])-1-spent))
		skill_points-=remaining
		job_progress[String(owner)]={"level":int(stage[1]),"exp":0,"points":remaining}
''')
    s=rep(s,'var jb := job_level - 1','var jb := earned_job_levels()')
    s=rep(s,'return int(round(28.0 * pow(job_level, 1.85)))','''var offset := 12 if job_id==&"runeblade" else (30 if job_id==&"ninth_edge" else 0)
	return int(round(28.0 * pow(job_level+offset, 1.85)))''')
    s=rep(s,'"job_id": String(job_id), "level": level, "exp": exp_current,','"job_progress_version": 1, "job_progress": job_progress.duplicate(true),\n\t\t"job_id": String(job_id), "level": level, "exp": exp_current,')
    s=rep(s,'job_id = StringName(d.get("job_id", "swordsman"))','''job_id = StringName(d.get("job_id", "swordsman"))
	progression_version = int(d.get("job_progress_version",0))
	job_progress = d.get("job_progress",{}).duplicate(true)
	job_progress.erase(String(job_id))''')
    return s
edit('scripts/core/player_stats.gd',stats)

def book(s):
    s=rep(s,'const HOTKEY_COUNT := 4','''const HOTKEY_COUNT := 4

static func profession_of(id: StringName) -> StringName:
	if id in NINTH_SKILLS: return &"ninth_edge"
	if id in RUNE_SKILLS: return &"runeblade"
	return &"swordsman"
''')
    s=rep(s,'refund += level_of(id)\n\t\tlearned.erase(id)','PlayerState.stats.add_skill_points(profession_of(id),level_of(id))\n\t\tlearned.erase(id)')
    s=s.replace('\tvar refund := 0\n','').replace('\tPlayerState.stats.skill_points += refund\n','')
    s=rep(s,'if stats.skill_points <= 0:   # ★ รอบ 108 ★ แต้มเดียวกันทุกสกิล','if stats.points_for(profession_of(skill_id)) <= 0:')
    s=s.replace('\tif skill_id == &"worldcleaver" and level_of(&"unbroken_edge") > 0: return false\n','').replace('\tif skill_id == &"unbroken_edge" and level_of(&"worldcleaver") > 0: return false\n','')
    s=rep(s,'if not s.job_ids.is_empty() and stats.job_id not in s.job_ids:', 'if not stats.has_profession(profession_of(skill_id)):')
    a=s.index('\tif skill_id in RUNE_SKILLS:',s.index('func learn_blocker'))
    b=s.index('\tvar s := GameData.get_skill',a)
    s=s[:a]+s[b:]
    s=rep(s,'if stats.skill_points <= 0:\n\t\treturn "ไม่มีแต้มสกิล (ได้ 1 แต้มทุกครั้งที่เลเวลอาชีพขึ้น — เพดานจ๊อบ %d)" % stats.max_job_level()', 'if stats.points_for(profession_of(skill_id)) <= 0:\n\t\treturn "ไม่มีแต้มของอาชีพนี้ • แต้มแต่ละอาชีพใช้แทนกันไม่ได้"')
    s=rep(s,'stats.skill_points -= 1   # ★ รอบ 108 ★ สกิลรูนก็ใช้แต้มนี้','stats.add_skill_points(profession_of(skill_id),-1)')
    s=rep(s,'refund += int(learned[id])   # ★ รอบ 108 ★ คืนทุกสกิลรวมสกิลรูน','stats.add_skill_points(profession_of(id),int(learned[id]))')
    s=s.replace('\tstats.skill_points += refund\n','')
    return s
edit('scripts/core/skill_book.gd',book)

def state(s):
    rewards='''	if q.reward_exp > 0:
		var jx: int = q.reward_job_exp if q.reward_job_exp > 0 else int(round(q.reward_exp * 0.7))
		gain_exp(q.reward_exp, jx)
'''
    s=rep(s,rewards,'')
    s=rep(s,'\t# ★ รอบ 105 ★ เปลี่ยนอาชีพได้ทุกอาชีพ',rewards+'\t# ★ รอบ 105 ★ เปลี่ยนอาชีพได้ทุกอาชีพ')
    s=rep(s,'\t\tstats.job_id = q.reward_job','\t\tstats.change_profession(q.reward_job)')
    s=rep(s,'\trefresh(false)\n\t_emit_all()','\tstats.migrate_job_progress(skills,story_flags)\n\trefresh(false)\n\t_emit_all()')
    s=rep(s,'var before := stats.skill_points','var before := stats.all_skill_points()')
    s=rep(s,'(stats.skill_points - before)','(stats.all_skill_points() - before)')
    return s
edit('scripts/core/player_state.gd',state)
def gm(s):
    s=rep(s,'\tst.job_id = job_id','\tst.change_profession(job_id)')
    a=s.index('\t# สกิลที่อาชีพใหม่เรียนไม่ได้')
    b=s.index('\tPlayerState.refresh()',a)
    s=s[:a]+'\t# Profession switches preserve learned skills and their own point banks.\n'+s[b:]
    return s
edit('scripts/ui/gm_window.gd',gm)
print('Profession progression, save migration and refunds updated.')
