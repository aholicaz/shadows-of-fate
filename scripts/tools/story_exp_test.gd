extends Node
func _ready() -> void:
	SaveManager.end_session()
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://output/story_exp_balance_2026-09-22.json"))
	assert(rows.size() == 42)
	var job_changes := {}
	for change in JSON.parse_string(FileAccess.get_file_as_string("res://output/game_audit/balance_changes.json")):
		if change.kind == "quest": job_changes[change.id] = int(change.new_job)
	var money_changes := {}
	for change in JSON.parse_string(FileAccess.get_file_as_string("res://output/story_job_money_balance.json")):
		job_changes[change.id] = int(change.new_job)
		money_changes[change.id] = int(change.new_zeny)
	for row in rows:
		var quest := GameData.get_quest(StringName(row.id))
		assert(quest != null and not quest.repeatable)
		assert(quest.reward_exp == int(row.new))
		assert(quest.reward_exp < int(row.old))
		assert(quest.reward_exp <= floori(PlayerStats.exp_needed_at(int(row.reference_level)) * float(row.share)))
		assert(quest.reward_job_exp == int(job_changes.get(row.id, row.job)))
		assert(quest.reward_zeny == int(money_changes[row.id]))
		assert(quest.reward_text().contains("EXP %d / Job %d" % [quest.reward_exp, quest.reward_job_exp]))
	for lv in [59, 60, 70, 80, 96, 100, 110]:
		assert(PlayerStats.exp_needed_at(lv) == int(round(35.0 * pow(lv, 1.9) * (1.0 + maxf(0.0, lv - 70.0) * 0.035))))
	print("STORY_EXP_PASS: 42 reduced quests, reference percentage caps, reviewed Job EXP, matching labels, unchanged level curve")
	get_tree().quit()
