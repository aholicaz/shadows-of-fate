extends Node
var checks := 0
var failures := 0
func check(ok: bool, title: String) -> void:
	checks+=1
	if ok: print("PASS: ",title)
	else:
		failures+=1
		push_error(title)

func _ready() -> void:
	get_tree().create_timer(30).timeout.connect(func(): push_error("V2 TEST TIMEOUT");get_tree().quit(1))
	PlayerState.new_game()
	PlayerState.set_process(false)
	var st := PlayerState.stats
	var book := PlayerState.skills
	st.level=70
	st.job_level=38
	st.skill_points=7
	st.job_exp_current=123
	book.learned={&"bash":5,&"slash":5}
	var earned := st.earned_job_levels()
	st.change_profession(&"runeblade")
	check(st.job_level==1 and st.skill_points==0 and st.job_exp_current==0,"new Runeblade starts Job 1 with an empty personal point bank")
	check(st.profession_state(&"swordsman")=={"level":38,"exp":123,"points":7},"previous job level EXP and unused points are frozen")
	check(st.earned_job_levels()==earned,"promotion preserves already earned job stat bonuses")
	check(not book.can_learn(&"blade_rhythm",st),"swordsman points cannot purchase Runeblade skills")
	check(book.learn(&"bash",st) and st.points_for(&"swordsman")==6 and st.skill_points==0,"old job points can still upgrade old job skills")
	var required := st.job_exp_to_next()
	check(required>2000,"new profession curve prevents instant multi-level jumps from a normal kill")
	check(st.add_job_exp(required)==1 and st.job_level==2 and st.skill_points==1,"one Runeblade job level grants exactly one Runeblade point")
	check(st.profession_state(&"swordsman").level==38 and st.points_for(&"swordsman")==6,"earning current job EXP cannot advance the frozen old job")
	check(book.learn(&"blade_rhythm",st) and st.skill_points==0 and st.points_for(&"swordsman")==6,"Runeblade upgrade debits only its own bank")
	st.skill_points=2
	book.learned[&"blade_rhythm"]=9
	check(book.learn(&"blade_rhythm",st) and book.level_of(&"blade_rhythm")==10,"Runeblade skill can reach rank 10")
	check(not book.learn(&"blade_rhythm",st) and st.skill_points==1,"rank 10 cannot consume an eleventh point")
	var sword_refund := st.points_for(&"swordsman")+book.level_of(&"bash")+book.level_of(&"slash")
	book.reset(st)
	check(st.points_for(&"swordsman")==sword_refund and st.skill_points==11,"reset returns invested ranks to their profession of origin")
	check(not st.has_profession(&"ninth_edge"),"refund does not unlock a secret profession")
	var total := st.all_skill_points()
	book.reset(st)
	check(st.all_skill_points()==total,"repeated reset cannot mint points")
	PlayerState.current_map_id=&"vanir_town"
	book.reset_runeblade()
	check(not st.has_profession(&"ninth_edge"),"rune-only reset does not create an empty unlocked secret bank")
	var save: Dictionary=JSON.parse_string(JSON.stringify(PlayerState.to_dict()))
	PlayerState.from_dict(save)
	check(PlayerState.stats.job_level==2 and PlayerState.stats.points_for(&"swordsman")==sword_refund and PlayerState.stats.skill_points==11,"new save round trip keeps profession banks separate")
	var legacy := {"stats":{"job_id":"runeblade","level":97,"job_level":70,"job_exp":9000,"skill_points":10},"skills":{"learned":{"bash":10,"slash":10,"sword_mastery":10,"rune_flurry":5,"keen_inscription":5},"hotkeys":["rune_flurry"]},"flags":{"runeblade_start_job_level":50}}
	PlayerState.from_dict(legacy)
	st=PlayerState.stats
	check(st.job_level==21 and st.profession_state(&"swordsman").level==50 and st.earned_job_levels()==69,"legacy shared job splits at the recorded promotion level")
	check(st.all_skill_points()==10 and PlayerState.skills.level_of(&"rune_flurry")==5 and PlayerState.skills.hotkey_at(0)==&"rune_flurry","migration preserves total unused points learned ranks and hotkeys")
	var once := st.to_dict()
	var migrated := PlayerState.to_dict()
	PlayerState.from_dict(migrated)
	check(PlayerState.stats.to_dict()==once,"migration is idempotent")
	legacy.stats={"job_id":"ninth_edge","level":97,"job_level":95,"skill_points":19}
	legacy.flags={"runeblade_start_job_level":50,"ninth_edge_start_job_level":80}
	PlayerState.from_dict(legacy)
	st=PlayerState.stats
	check(st.job_level==16 and st.profession_state(&"runeblade").level==31 and st.profession_state(&"swordsman").level==50,"legacy third profession splits all three independent jobs")
	check(st.all_skill_points()==19 and st.earned_job_levels()==94,"third-job migration neither loses bonuses nor duplicates points")
	for id in SkillBook.RUNE_SKILLS:
		var skill := GameData.get_skill(id)
		if SkillBook.profession_of(id)==&"runeblade": check(skill.max_level==10,"ten ranks: "+String(id))
		var im := skill.icon.get_image()
		check(im.get_format()==Image.FORMAT_RGBA8 and im.get_pixel(0,0).a==0 and im.get_pixel(128,128).a>0.99,"actual alpha: "+String(id))
	check(GameData.get_skill(&"rune_lunge").dash_range(1)>GameData.get_skill(&"slash").dash_range(10),"rune dash rank 1 exceeds the previous profession's maximum travel")
	check(GameData.get_skill(&"faultline").field_radius==320 and GameData.get_skill(&"worldcleaver").field_radius==520,"field collision radii read the enlarged skill data")
	print("BALANCE V2 PROGRESSION: %d checks; failures=%d"%[checks,failures])
	get_tree().quit(1 if failures else 0)
