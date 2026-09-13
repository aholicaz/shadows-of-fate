## A bounded cast-owned field. Pulses cannot create runes repeatedly or survive death.
extends Node2D

var caster: Node2D
var controller: Node2D
var source: StringName
var total_mult := 0.0
var direction := 1
var radius := 190.0
var target_cap := 10
var height := 340.0
var weapon_visual: Node2D
var pulses := 6
var interval := 0.4
var elapsed := 0.0
var next_pulse := 0.0
var pulse_count := 0
var granted_rune := false
var color := Color("#67dcff")

func configure(rb: Node2D, id: StringName, mult: float, at: Vector2, dir: int) -> void:
	controller = rb
	caster = rb.player
	source = id
	total_mult = mult
	direction = dir
	# Store the world origin; parent movement must not move a planted sword.
	set_as_top_level(true)
	position = at
	var skill := GameData.get_skill(id)
	radius = skill.field_radius
	height = skill.range_y
	target_cap = skill.max_targets_at(PlayerState.skills.level_of(id))
	if id == &"worldcleaver":
		pulses = 5
		interval = 0.2
		color = Color("#ffcf73")
	# A short visual arrival precedes the first damaging pulse.
	next_pulse = 0.16
	z_index = 64
	if source==&"faultline":
		weapon_visual=preload("res://scripts/entities/planted_weapon_visual.gd").new()
		weapon_visual.configure(PlayerState.equipment.weapon())
		add_child(weapon_visual)

func _process(delta: float) -> void:
	if not is_instance_valid(caster) or caster._dead:
		queue_free()
		return
	elapsed += delta
	if is_instance_valid(weapon_visual):
		weapon_visual.position.y=-maxf(0,0.16-elapsed)*1700
		weapon_visual.modulate.a=clampf((0.16+pulses*interval+0.18-elapsed)/0.25,0,1)
	if pulse_count < pulses and elapsed >= next_pulse:
		pulse_count += 1
		next_pulse += interval
		strike()
	if elapsed > 0.16 + pulses * interval + 0.18:
		queue_free()
		return
	queue_redraw()

func strike() -> void:
	var area := Rect2(global_position + Vector2(-radius, -height), Vector2(radius * 2, height+30))
	var targets := get_tree().get_nodes_in_group("enemy")
	targets.sort_custom(func(a,b): return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position))
	var hits := 0
	for enemy in targets:
		if not enemy.has_method("take_damage_from_player") or (enemy.has_method("is_dead") and enemy.is_dead()): continue
		if not area.intersects(caster.enemy_rect(enemy)): continue
		var ray := PhysicsRayQueryParameters2D.create(global_position - Vector2(0,80), Vector2(enemy.global_position.x, global_position.y - 80), 1)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		var before: int = enemy.hp if "hp" in enemy else 0
		enemy.take_damage_from_player(total_mult / pulses, false, direction, 0, 0, source)
		# Record this cast, not the controller's current cast serial (other skills can overlap).
		if source == &"faultline" and not granted_rune and "hp" in enemy and enemy.hp < before:
			granted_rune = true
			controller._gain()
		hits += 1
		if hits >= target_cap: break

func _draw() -> void:
	var life := 0.16 + pulses * interval + 0.18
	var alpha := clampf((life - elapsed) / 0.25, 0.0, 1.0)
	var tint := Color(color, alpha)
	var ring := PackedVector2Array()
	for i in range(49):
		var a := TAU * i / 48.0
		ring.append(Vector2(cos(a) * radius, sin(a) * 30.0 - 4.0))
	draw_colored_polygon(ring, Color(color, alpha * 0.10))
	draw_polyline(ring, Color(color, alpha * 0.8), 3.0, true)
	var pulse_age := elapsed - (next_pulse - interval)
	if pulse_count > 0 and pulse_age >= 0 and pulse_age < 0.18:
		var burst := PackedVector2Array()
		var spread := lerpf(0.35,1.0,pulse_age/0.18)
		for i in range(49):
			var a := TAU*i/48.0
			burst.append(Vector2(cos(a)*radius*spread,sin(a)*35*spread-5))
		draw_polyline(burst,Color(color,alpha*(1.0-pulse_age/0.18)),7,true)
	for i in range(12):
		var a := TAU*i/12.0
		var mark := Vector2(cos(a)*radius*0.85,sin(a)*26-4)
		draw_line(mark-Vector2(0,6),mark+Vector2(0,6),tint,2,true)
		draw_line(mark,mark+Vector2(6,-4),tint,2,true)
	if source == &"faultline":
		# Moving elliptical ribbons orbit the equipped blade, as in the skill icon.
		for band in range(3):
			var ribbon := PackedVector2Array()
			for j in range(45):
				var a := elapsed*5.0+band*TAU/3.0+j/44.0*PI*1.5
				ribbon.append(Vector2(cos(a)*radius*(0.78+band*0.07),-90-band*25+sin(a)*42))
			draw_polyline(ribbon,Color(color,alpha*0.12),18,true)
			draw_polyline(ribbon,Color(color,alpha*0.85),4,true)
			draw_polyline(ribbon,Color(0.9,1,1,alpha*0.95),1.5,true)

	else:
		for i in range(7):
			var phase := fmod(elapsed * 4.0 + i * 0.17, 1.0)
			var x := lerpf(-radius * 0.85, radius * 0.85, i / 6.0)
			var tip := Vector2(x, lerpf(-390.0, -10.0, phase))
			draw_line(tip - Vector2(0,145), tip, Color(color, alpha * 0.22), 12.0, true)
			_draw_sword(tip, 115, tint)

func _draw_sword(tip: Vector2, length: float, tint: Color) -> void:
	var blade := PackedVector2Array([tip, tip+Vector2(-10,-22), tip+Vector2(-7,-length), tip+Vector2(7,-length), tip+Vector2(10,-22)])
	draw_colored_polygon(blade, Color(tint, tint.a * 0.72))
	draw_polyline(PackedVector2Array([tip+Vector2(0,-length),tip,tip+Vector2(7,-22)]), Color(1,1,1,tint.a), 2, true)
	draw_line(tip+Vector2(-24,-length),tip+Vector2(24,-length),tint,5,true)
	draw_line(tip+Vector2(0,-length),tip+Vector2(0,-length-28),tint,6,true)
