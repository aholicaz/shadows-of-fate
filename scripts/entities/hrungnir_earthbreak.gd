extends Node2D
signal finished
const FANGS = preload("res://Sprites/effects/hrungnir/stone_fangs_frames.tres")
const WINDUP := 1.2
const WAVE_TIME := 0.55
const RADIUS := 1180.0
const HEIGHT := 125.0
const RECOVERY := 0.8
const FX_TIME := 0.8
var caster: Node2D
var elapsed := 0.0
var resolved := false
var done := false
var impact_started := false
var previous_radius := 0.0
var original_speed := 1.0
# Source ground-contact anchors, calibrated independently of airborne debris.
const BASELINE_Y := [433.0,435.0,442.0,442.0,382.0,380.0,381.0,380.0]

static func cast(actor: Node2D) -> Node2D:
	var fx = load("res://scripts/entities/hrungnir_earthbreak.gd").new()
	fx.caster = actor
	fx.global_position = actor.foot_position()
	actor.get_parent().add_child(fx)
	fx.add_to_group("hrungnir_earthbreak")
	fx.z_index = actor.z_index + 1
	fx.original_speed = actor.sprite.speed_scale
	# Existing Skill poses are retained; hold the windup until the actual slam.
	actor.sprite.pause()
	Events.floating_text(actor.global_position + Vector2(0,actor.data.hp_bar_offset_y-26),"ทุบพิภพแตก",Color("ffd685"),24,0)
	return fx

func _finish() -> void:
	if done: return
	done = true
	if is_instance_valid(caster): caster.sprite.speed_scale = original_speed
	finished.emit()
	queue_free()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(caster) or caster.is_queued_for_deletion() or caster.hp <= 0 or PlayerState.is_dead():
		_finish()
		return
	elapsed += delta
	if elapsed < WINDUP:
		var count: int = caster.sprite.sprite_frames.get_frame_count(caster.sprite.animation)
		caster.sprite.frame = mini(int(elapsed/WINDUP*4),mini(3,count-1))
	if elapsed >= WINDUP:
		if not impact_started:
			impact_started = true
			caster.sprite.frame = mini(4,caster.sprite.sprite_frames.get_frame_count(caster.sprite.animation)-1)
			caster.sprite.play()
		var radius := wave_radius(elapsed)
		var player := get_tree().get_first_node_in_group("player")
		if not resolved and is_instance_valid(player) and elapsed <= WINDUP+WAVE_TIME+delta:
			var point: Vector2 = player.foot_position()
			if wave_reaches(point-global_position, previous_radius, radius):
				resolved = true
				if player.is_invincible() and player.has_method("dodge_contact"): player.dodge_contact()   # ★ รอบ 182 ★
				if not player.is_invincible():
					var hit := Combat.monster_skill_hits_player(caster.data,PlayerState.stats,caster.data.skill_damage_mult)
					if not hit.miss: player.take_damage(hit.damage,200,1 if point.x>=global_position.x else -1)
		previous_radius = radius
	if elapsed >= WINDUP+WAVE_TIME+RECOVERY: _finish()
	queue_redraw()

static func wave_radius(time: float) -> float:
	return RADIUS * clampf((time-WINDUP)/WAVE_TIME,0,1)

static func wave_reaches(local_point: Vector2, inner: float, outer: float) -> bool:
	return absf(local_point.x)<=outer and absf(local_point.x)>=maxf(0,inner-45) and absf(local_point.y)<=HEIGHT

func _draw() -> void:
	if elapsed < WINDUP: return
	var age := elapsed-WINDUP
	if age >= FX_TIME: return
	var index := clampi(int(age/FX_TIME*8),0,7)
	var texture := FANGS.get_frame_texture(&"default",index)
	var size := Vector2(1200,900)
	var fade := clampf((FX_TIME-age)/0.25,0,1)
	# One registered outward-facing sheet, mirrored across the boss.
	# Keep the centre open so the boss's slam remains readable.
	for direction in [-1,1]:
		draw_set_transform(Vector2.ZERO,0,Vector2(direction,1))
		draw_texture_rect(texture,Rect2(Vector2(65,25-size.y*0.96),size),false,Color(1,1,1,fade))
		draw_set_transform(Vector2.ZERO)
