extends Node
## Ground collision follows the authored airborne pose; no teleport or invulnerability.
var actor: CharacterBody2D
var skill: SkillData
var level := 1
var elapsed := 0.0
var direction := 1
var serial := 0
var released := false
var travelled := 0.0
var blocked := false
const RELEASE := 17.0 / 40.0
const DURATION := 32.0 / 40.0

func start(body: CharacterBody2D, data: SkillData, lv: int) -> void:
	actor = body
	skill = data
	level = lv
	direction = actor.facing
	actor._update_facing()
	actor.jump_slash_motion = self
	actor.runeblade.casting = true
	actor.is_attacking = true
	actor._attack_seq += 1
	serial = actor._attack_seq
	actor._rb_attack_tag = &"jump_slash"
	actor.reset_combo()
	actor._play("JumpSlash_Runeblade", true)
	actor.sprite.speed_scale = 1.0
	actor.attack_cooldown = DURATION

func step(delta: float) -> void:
	if not is_instance_valid(actor) or actor._dead or actor._attack_seq != serial:
		cancel()
		return
	elapsed += delta
	# Keep the sprite timeline and contact frame locked to the physics action.
	actor.sprite.pause()
	actor.sprite.frame = mini(31, int(elapsed * 40.0))
	var moving := elapsed >= 0.15 and elapsed < RELEASE and not blocked
	var distance := minf(skill.dash_distance - travelled, skill.dash_distance / (RELEASE - 0.15) * delta) if moving else 0.0
	actor.velocity = Vector2(direction * distance / maxf(delta, 0.001), 60.0)
	if not actor.is_on_floor(): actor.velocity.y += 1200.0 * delta
	var before := actor.global_position.x
	actor.move_and_slide()
	travelled += absf(actor.global_position.x - before)
	if actor.is_on_wall(): blocked = true
	if not actor.is_on_floor():
		cancel()
		return
	if elapsed >= RELEASE and not released:
		released = true
		actor._play_skill_sfx(&"magnum_break")
		var wave := preload("res://scripts/entities/jump_slash_wave.gd").new()
		wave.caster = actor
		wave.direction = direction
		wave.skill = skill
		wave.level = level
		actor.get_parent().add_child(wave)
		wave.global_position = actor.foot_position()
	if elapsed >= DURATION: cancel()

func cancel() -> void:
	if is_instance_valid(actor):
		actor.jump_slash_motion = null
		actor.runeblade.casting = false
		actor.velocity.x = 0.0
		actor.sprite.speed_scale = 1.0
		if actor._attack_seq == serial:
			actor.is_attacking = false
			actor.attack_cooldown = 0.0
			if not actor._dead: actor._play("Idle", true)
	queue_free()
