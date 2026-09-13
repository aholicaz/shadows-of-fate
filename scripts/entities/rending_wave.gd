## Gameplay hitbox is independent of the replaceable SpriteFrames artwork.
extends Node2D

var _skill: SkillData
var _caster: Node2D
var _dir := 1
var _level := 1
var _travel := 0.0
var _origin := Vector2.ZERO
var _hits: Array[Node] = []
var _custom_visual := false
var _age := 0.0
var _fire_material: ShaderMaterial
var _visual_scale := 1.0
var _visual_offset := Vector2.ZERO
var _art: AnimatedSprite2D

func _process(delta: float) -> void:
	_age += delta
	if is_instance_valid(_art):
		_art.self_modulate.a = clampf(_age / 0.035, 0.0, 1.0) * clampf((_skill.wave_distance - _travel) / 75.0, 0.0, 1.0)
	if not _custom_visual:
		if _fire_material != null:
			_fire_material.set_shader_parameter("phase", _age)
			_fire_material.set_shader_parameter("fade", clampf((_skill.wave_distance - _travel) / 75.0, 0.0, 1.0))
		queue_redraw()

static func spawn(skill: SkillData, caster: Node2D, direction: int, level: int,
		book: PlayerSkillFX = null) -> Node2D:
	var wave = load("res://scripts/entities/rending_wave.gd").new()
	wave._skill = skill
	wave._caster = caster
	wave._dir = -1 if direction < 0 else 1
	wave._level = level
	caster.get_parent().add_child(wave)
	var foot: Vector2 = caster.foot_position() if caster.has_method("foot_position") else caster.global_position
	wave.global_position = foot + Vector2(0, skill.effect_offset.y)
	wave._origin = wave.global_position
	wave.z_index = skill.effect_z
	wave.name = "RendingWave"
	wave._setup_visual(book)
	if not wave._custom_visual:
		wave._setup_fire()
	return wave

func _setup_fire() -> void:
	_visual_scale = _skill.effect_height / 320.0
	# Anchor the art to the feet; the combat sweep retains its own center and size.
	_visual_offset.y = -_skill.effect_height * 0.5 - _skill.effect_offset.y
	var fire := Polygon2D.new()
	fire.polygon = PackedVector2Array([Vector2(-245, -190), Vector2(110, -190),
		Vector2(110, 170), Vector2(-245, 170)])
	fire.uv = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	fire.scale = Vector2(_dir, 1) * _visual_scale
	fire.position = _visual_offset
	fire.show_behind_parent = true
	_fire_material = ShaderMaterial.new()
	_fire_material.shader = preload("res://shaders/rending_wave_fire.gdshader")
	fire.material = _fire_material
	add_child(fire)

func _setup_visual(book: PlayerSkillFX) -> void:
	var frames: SpriteFrames = _skill.effect_frames
	var anim: StringName = _skill.effect_anim
	var height := _skill.effect_height
	var tint := Color.WHITE
	if book != null and book.frames != null:
		frames = book.frames
		anim = book.anim
		height = book.height
		tint = book.tint
	if frames == null:
		return
	if not frames.has_animation(anim) or frames.get_frame_count(anim) == 0:
		for candidate in frames.get_animation_names():
			if frames.get_frame_count(candidate) > 0:
				anim = candidate
				break
	if not frames.has_animation(anim) or frames.get_frame_count(anim) == 0:
		return
	var texture := frames.get_frame_texture(anim, 0)
	if texture == null:
		return
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	# Artist sheets can face left; other replacement sheets retain the right-facing default.
	var faces_left: bool = frames.get_meta("source_faces_left", false)
	sprite.flip_h = (_dir > 0) if faces_left else (_dir < 0)
	var factor := maxf(1.0, height) / maxf(1.0, texture.get_height())
	sprite.scale = Vector2.ONE * factor
	if frames.has_meta("foot_anchor"):
		var anchor: Vector2 = frames.get_meta("foot_anchor")
		var offset_from_center := (anchor - Vector2(0.5, 0.5)) * texture.get_size() * factor
		if sprite.flip_h:
			offset_from_center.x *= -1.0
		sprite.position = -offset_from_center - Vector2(0, _skill.effect_offset.y)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.modulate = tint
	_art = sprite
	add_child(sprite)
	sprite.play(anim)
	_custom_visual = true

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_caster) or bool(_caster.get("_dead")):
		queue_free()
		return
	var step := minf(maxf(1.0, _skill.wave_speed) * delta, _skill.wave_distance - _travel)
	var previous := global_position
	var next := previous + Vector2(_dir * step, 0)
	# Sweep the front of the hitbox into terrain. Never hit through a wall.
	var half_width := _skill.effect_hit_size.x * 0.5
	var query := PhysicsRayQueryParameters2D.create(previous,
		next + Vector2(_dir * half_width, 0), 1)
	var wall := get_world_2d().direct_space_state.intersect_ray(query)
	var blocked := not wall.is_empty()
	if blocked:
		next.x = float(wall.position.x) - _dir * half_width
		if (next.x - previous.x) * _dir < 0:
			next = previous
	var size := _skill.effect_hit_size
	var box := Rect2(Vector2(minf(previous.x, next.x) - half_width,
		previous.y - size.y * 0.5), Vector2(absf(next.x-previous.x) + size.x, size.y))
	var enemies := get_tree().get_nodes_in_group("enemy")
	enemies.sort_custom(func(a: Node, b: Node) -> bool:
		return (a as Node2D).global_position.x * _dir < (b as Node2D).global_position.x * _dir)
	for enemy in enemies:
		if enemy in _hits or not enemy.has_method("take_damage_from_player"):
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		var rect := SkillEffect._enemy_rect(enemy)
		if (rect.get_center().x - _origin.x) * _dir < 0 or not box.intersects(rect, true):
			continue
		# Also test line of sight to the near edge when the hitbox overlaps a wall.
		var near_x: float = rect.position.x if _dir > 0 else rect.end.x
		var sight := PhysicsRayQueryParameters2D.create(previous,
			Vector2(near_x, previous.y), 1)
		if not get_world_2d().direct_space_state.intersect_ray(sight).is_empty():
			continue
		if enemy.has_method("take_skill_damage"):
			enemy.take_skill_damage(_skill.damage_mult(_level),false,_dir,&"magnum_break",_skill.wound_bonus(_level),_skill.wound_duration)
		else:
			enemy.take_damage_from_player(_skill.damage_mult(_level), false, _dir,
				_skill.wound_bonus(_level), _skill.wound_duration)
		_hits.append(enemy)
		if _skill.max_targets_at(_level) > 0 and _hits.size() >= _skill.max_targets_at(_level):
			queue_free()
			return
	global_position = next
	_travel += step
	queue_redraw()
	if blocked or _travel >= _skill.wave_distance:
		queue_free()

func _draw() -> void:
	if _custom_visual:
		return
	var fade := clampf((_skill.wave_distance - _travel) / 75.0, 0.0, 1.0)
	draw_set_transform(_visual_offset, 0.0, Vector2(_dir, 1) * _visual_scale)
	# Deterministic particles: cosmetic animation never consumes combat's RNG.
	for i in range(30):
		var phase := fposmod(_age * (1.3 + (i % 3) * 0.22) + i * 0.618, 1.0)
		var y := sin(i * 7.13) * 140.0 - phase * 32.0
		var pos := Vector2(42.0 - phase * 226.0, y)
		var alpha := (1.0 - phase) * fade
		var radius := 1.2 + (i % 3) * 0.7
		draw_circle(pos, radius * 3.0, Color(1.0, 0.30, 0.015, alpha * 0.12))
		draw_line(pos, pos + Vector2(6.0 + phase * 7.0, 3.0),
			Color(1.0, 0.84, 0.17, alpha), radius, true)
	draw_set_transform(Vector2.ZERO)
