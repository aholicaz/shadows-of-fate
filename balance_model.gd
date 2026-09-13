## Deterministic expected-value rotation estimate, not a claim about player feel.
extends Node
var baseline: Dictionary

func _ready() -> void:
	baseline=JSON.parse_string(FileAccess.get_file_as_string("res://output/balance/before.json"))
	PlayerState.new_game()
	PlayerState.set_process(false)
	var live:=GameData.items.duplicate()
	var rows:=[]
	for old in [true,false]:
		if old:
			for id in baseline.items:
				var item:=ItemData.new()
				item.id=StringName(id)
				for key in baseline.items[id]:
					var value=baseline.items[id][key]
					if value is float or value is int or value is bool: item.set(key,value)
				GameData.items[StringName(id)]=item
		else: GameData.items=live.duplicate()
		for fast in [true,false]:
			rows.append(model(old,fast))
	GameData.items=live
	var file:=FileAccess.open("res://output/balance/rotation_model.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(rows,"\t"))
	file.close()
	for row in rows: print(JSON.stringify(row))
	get_tree().quit()

func model(old: bool, fast: bool) -> Dictionary:
	var s:=PlayerStats.new()
	s.job_id=&"runeblade"
	s.level=60
	s.job_level=60
	var bases: Array=[44,44,20,10,30,25] if fast else [51,15,25,20,44,15]
	for i in range(6): s.set("base_"+String(PlayerStats.STAT_NAMES[i]),bases[i])
	PlayerState.stats=s
	PlayerState.equipment=Equipment.new()
	var ids: Array=["frost_edge","","vanir_circlet","frost_wolf_coat","mist_cloak","root_boots","brooch","brooch"] if fast else ["ember_of_gullveig","","vanir_circlet","sentinel_plate","ember_cape","miner_boots","ash_ring","ring"]
	for i in range(ids.size()):
		if ids[i]=="":continue
		var item:=GameData.get_item(StringName(ids[i]))
		var inst:=ItemInstance.create(StringName(ids[i]),1,4 if item.refinable else 0)
		PlayerState.equipment.slots[i]=inst
	PlayerState.skills=SkillBook.new()
	PlayerState.skills.learned[&"sword_mastery"]=10
	if fast: PlayerState.skills.learned[&"keen_inscription"]=5
	PlayerState.active_buffs.clear()
	PlayerState.refresh()
	# Reconstruct the old fixed refine gains; every other derived value uses runtime code.
	if old:
		var w: ItemData=PlayerState.equipment.weapon().data()
		s.weapon_atk=w.atk+4*w.refine_atk_per_level
		var extra:=0
		for i in range(1,8):
			var inst: ItemInstance=PlayerState.equipment.slots[i]
			if inst!=null: extra+=inst.refine*inst.data().refine_atk_per_level
		s.flat_bonus[&"atk"]=float(s.flat_bonus.get(&"atk",0))+extra
		s.recalculate()
	var hit:=Combat.hit_rate(s.hit,100+60+35)/100.0
	var crit:=s.crit/100.0
	var basic:=s.atk*hit*((1-crit)*Combat.def_reduction(68)+crit*s.crit_damage)*(1+s.damage_percent/100)
	var skill_factor:=1+s.skill_damage_percent/100
	var power:=s.atk*hit*Combat.def_reduction(int(68*0.75))*1.2*(1+s.damage_percent/100)*skill_factor
	var time:=0.0
	var damage:=0.0
	var basic_count:=0
	var runes:=0
	var sp:=float(s.max_sp)
	var spent:=0
	var casts:={}
	var ready:={}
	var edge_end:=0.0
	var wound_end:=0.0
	# Fixed 18-second contact window, full initial SP, zero initial runes. Per-cast locks
	# replace basic attacks; SP and rune requirements are enforced. No on-hit elements/cards.
	while time<18:
		var chosen:=""
		var list: Array=["unbroken_edge","rune_flurry"] if fast else ["worldcleaver","faultline","anvil_cleave"]
		for id in list:
			var d: Dictionary=baseline.skills[id] if old else current_skill(id)
			var cost:=int(d.sp_cost_base)
			if time<float(ready.get(id,0)) or sp<cost:continue
			if id in ["unbroken_edge","worldcleaver"] and runes<3:continue
			chosen=id
			break
		var lock:=s.attack_interval()
		var wound:=1.15 if time<wound_end else 1.0
		if chosen!="":
			var d: Dictionary=baseline.skills[chosen] if old else current_skill(chosen)
			var mult:=float(d.damage_mult_base)+4*float(d.damage_mult_per_level)
			spent+=int(d.sp_cost_base)
			sp-=int(d.sp_cost_base)
			ready[chosen]=time+float(d.cooldown)*(1-s.cooldown_reduction/100)
			casts[chosen]=int(casts.get(chosen,0))+1
			match chosen:
				"unbroken_edge":
					runes=0;edge_end=time+8;lock=0.01
				"rune_flurry":
					lock=0.55 if old else 0.10+6*clampf(0.09/sqrt(maxf(1,s.aspd)),0.04,0.09)
					damage+=basic*mult*skill_factor*wound
					runes=mini(3,runes+1)
				"anvil_cleave":
					lock=0.7 if old else 0.46
					damage+=power*mult*wound
					if not old:wound_end=time+4
					runes=mini(3,runes+1)
				"faultline":
					lock=0.55 if old else 0.45
					var delivered:=1.0 if old else clampf((18-time-0.41)/2.4,0,1)
					damage+=power*mult*wound*delivered
					runes=mini(3,runes+1)
				"worldcleaver":
					lock=1.0 if old else 0.9
					var delivered:=1.0 if old else clampf((18-time-0.86),0,1)
					damage+=power*mult*wound*delivered
					runes=0
		else:
			basic_count+=1
			damage+=basic*(1.25 if basic_count%3==0 else 1.0)*wound
			if time<edge_end:
				lock/=1.25
				if basic_count%3==0:damage+=s.atk*hit*Combat.def_reduction(68)*0.8
			if basic_count%3==0:runes=mini(3,runes+1)
		sp=minf(s.max_sp,sp+s.sp_regen*lock)
		time+=lock
	return {"version":"before" if old else "after","build":"critical" if fast else "heavy","level":60,"job":60,"base_stats":bases,"equipment":ids,"refine":4,"atk":s.atk,"aspd":s.aspd,"crit":s.crit,"crit_multiplier":s.crit_damage,"skill_bonus":s.skill_damage_percent,"basic_expected_damage":round(basic),"rotation_18s_damage":round(damage),"sp_spent":spent,"casts":casts,"basic_attacks":basic_count,"contact_dps_estimate":round(damage/18)}

func current_skill(id: String) -> Dictionary:
	var d:=GameData.get_skill(StringName(id))
	return {"sp_cost_base":d.sp_cost_base,"cooldown":d.cooldown,"damage_mult_base":d.damage_mult_base,"damage_mult_per_level":d.damage_mult_per_level}
