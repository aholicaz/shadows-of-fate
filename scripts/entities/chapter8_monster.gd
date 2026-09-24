extends "res://scripts/entities/monster_base.gd"
var tower_pattern: Node2D
var tower_casts := 0

func _cast_skill() -> void:
	var floor_controller := get_parent().get_parent()
	if data.is_boss and floor_controller.has_method("claim_boss_skill"):
		if not floor_controller.claim_boss_skill():
			_skill_cd = 0.6
			return
	var source := String(data.get_meta("tower_source", ""))
	if not data.get_meta("tower_guardian", false):
		# Preserve signature skills whose dispatch in MonsterBase is keyed to campaign IDs.
		if source in ["baphomet", "gullveig_ember", "stone_hrungnir"] and (source == "gullveig_ember" or tower_casts % 2 == 0):
			state = State.ATTACK
			velocity.x = 0
			_skill_cd = data.skill_cooldown
			var effect: Node2D
			if source == "stone_hrungnir":
				effect = preload("res://scripts/entities/hrungnir_earthbreak.gd").cast(self)
			else:
				var mode := "scythe" if source == "baphomet" else ("meteor" if tower_casts % 2 == 0 else "flame_jet")
				effect = preload("res://scripts/entities/boss_signature_skill.gd").cast(self, mode, facing)
			tower_casts += 1
			await effect.finished
			if state != State.DEAD:
				state = State.IDLE
				_attack_timer = 1.0
			return
		if source in ["kiln_sentinel", "oath_warden"]:
			await _tower_cast(0)
			return
		tower_casts += 1
		super._cast_skill()
		return
	var mode: int = preload("res://scripts/world/chapter8_tower_data.gd").NEW_IDS.find(source)
	await _tower_cast(maxi(0, mode))

func _tower_cast(mode: int) -> void:
	state = State.ATTACK
	velocity.x = 0
	_skill_cd = data.skill_cooldown
	_play("Skill", true)
	tower_pattern = preload("res://scripts/entities/chapter8_pattern.gd").new()
	tower_pattern.caster = self
	tower_pattern.kind = mode
	tower_pattern.combo = tower_casts
	tower_pattern.enraged = hp <= data.max_hp / 2
	if tower_pattern.enraged: _skill_cd *= 0.85
	tower_casts += 1
	get_parent().add_child(tower_pattern)
	Events.floating_text(global_position + Vector2(0, -330), data.skill_name, Color("ffd39b"), 20, 0)
	await tower_pattern.finished
	if state != State.DEAD:
		state = State.IDLE
		_attack_timer = 1.1

func _become_corpse(_played: String) -> void:
	# Tower owns encounter lifecycle; no campaign respawn/corpse timers.
	queue_free()

func _exit_tree() -> void:
	if is_instance_valid(tower_pattern): tower_pattern.queue_free()
