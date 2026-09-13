extends Node2D
var checks := 0
var failures: Array[String] = []
var actor
var transitions: Array[String] = []
func check(ok: bool,text: String) -> void:
	checks += 1
	if not ok: failures.append(text); push_error(text)
func _ready() -> void:
	UI.layer.hide()
	PlayerState.new_game()
	PlayerState.stats.job_id = &"runeblade"
	PlayerState.stats.level = 75
	actor = load("res://scenes/player/runeblade.tscn").instantiate()
	add_child(actor)
	actor.set_physics_process(false)
	actor.runeblade.set_process(false)
	actor.sprite.animation_changed.connect(func():transitions.append(String(actor.sprite.animation)))
	check(actor._has_anim("Dash") and actor._has_anim("Jump"),"Dedicated scene resolves movement aliases")
	var wave: SkillData = GameData.get_skill(&"magnum_break")
	var wave_anim: String = actor.skill_animation(&"magnum_break")
	var timing: Vector3 = actor._wave_animation_timing(wave,wave_anim)
	check(is_equal_approx(timing.x,wave.cast_windup),"Wave release mechanics unchanged")
	check(absf(actor._anim_time_to_frame(wave_anim,1)/timing.z-wave.cast_windup)<.001,"Wave visual contact matches release")
	for id in [&"anvil_cleave",&"rune_lunge",&"rune_flurry",&"faultline",&"worldcleaver",&"erasing_cut"]:
		PlayerState.skills.learned[id] = 1
		PlayerState.stats.sp = 10000
		PlayerState.cooldowns.clear()
		actor.runeblade.charges = 4
		actor._play("Idle",true)
		transitions.clear()
		actor.runeblade.cast(id)
		check(actor.sprite.animation==StringName(actor.skill_animation(id)),"Cast selects new pose: "+String(id))
		var elapsed := 0.0
		while actor.runeblade.casting and elapsed<3:
			# Isolate presentation: movement is disabled and there are no combat targets.
			actor.runeblade.approach_left = 0
			actor._dash_time = 0
			await get_tree().create_timer(.02).timeout
			elapsed += .02
		check(not actor.runeblade.casting,"Cast completes: "+String(id))
		if id==&"rune_flurry":
			var slices: Array[String] = []
			for pose in transitions:
				if pose.begins_with("Flurry_Runeblade_"):slices.append(pose)
			check(slices==["Flurry_Runeblade_1","Flurry_Runeblade_2","Flurry_Runeblade_3","Flurry_Runeblade_1","Flurry_Runeblade_2","Flurry_Runeblade_3"],"Six Flurry visual strikes")
		elif id in [&"anvil_cleave",&"faultline",&"worldcleaver",&"erasing_cut"]:
			var windup: float = {&"anvil_cleave":.28,&"faultline":.25,&"worldcleaver":.7,&"erasing_cut":.3}[id]
			var pose: String = actor.skill_animation(id)
			var hit: int = actor.sprite.sprite_frames.get_meta("rb_hit_frames")[pose]
			var speed: float = actor._anim_length(pose)/(windup+.25)
			check(absf(actor._anim_time_to_frame(pose,hit)/speed-windup)<.001,"Heavy contact timing: "+String(id))
	var result := {"checks":checks,"failures":failures}
	var file := FileAccess.open("res://output/runeblade_full/skill_audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	print("RUNEBLADE_SKILL_VISUAL_AUDIT ",JSON.stringify(result))
	get_tree().quit(0 if failures.is_empty() else 1)
