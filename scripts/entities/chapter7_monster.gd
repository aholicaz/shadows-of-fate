extends "res://scripts/entities/monster_base.gd"
## Chapter 7's supplied artwork is a single pose; skill timing must use seconds,
## not nonexistent hit frames. A stationary warning gives a fair dodge window.
var cast_origin := Vector2.ZERO
var warning: Node2D
var chapter7_casts := 0
func _ground_slam_origin() -> Vector2:
	return cast_origin
func _cast_skill() -> void:
	state=State.ATTACK;velocity.x=0;_skill_cd=data.skill_cooldown
	chapter7_casts+=1
	_play("Skill",true)
	cast_origin=foot_position()+Vector2(facing*150,0)
	if data.id==&"oath_warden" and chapter7_casts%2==1 and is_instance_valid(_player):
		cast_origin.x=clampf(_player.foot_position().x,foot_position().x-600,foot_position().x+600)
	warning=preload("res://scripts/entities/chapter7_slam_warning.gd").new()
	warning.position=cast_origin;warning.radius=data.skill_slam_radius
	warning.duration=data.skill_windup
	get_parent().add_child(warning)
	Events.floating_text(global_position+Vector2(0,data.hp_bar_offset_y-35),data.skill_name,Color("#ffb760"),22,0)
	await get_tree().create_timer(data.skill_windup).timeout
	if is_instance_valid(warning):warning.queue_free()
	if state==State.DEAD:return
	_ground_slam_hit(true,0)
	await get_tree().create_timer(maxf(.2,data.skill_duration-data.skill_windup)).timeout
	if state!=State.DEAD:
		state=State.IDLE;_attack_timer=maxf(_attack_timer,.8)
func _exit_tree() -> void:
	if is_instance_valid(warning):warning.queue_free()
func _become_corpse(played: String) -> void:
	super._become_corpse(played)
	# No standing "dead" character while this chapter uses single-pose sources.
	sprite.hide()
