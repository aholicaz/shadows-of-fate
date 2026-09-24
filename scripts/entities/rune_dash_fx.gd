## Air-cut sprite animations for Runeblade; legacy effects for other jobs.
extends Node2D
const GEOMETRY = preload("res://scripts/entities/weapon_blade_geometry.gd")
const SPEED_SHEET = preload("res://Sprites/effects/dash_silver_speed_sheet.png")
const GOLD_SHEET = preload("res://Sprites/effects/dash_gold_thrust_sheet.png")
const GOLD_ORIGINS = [Vector2(60, 370), Vector2(38, 370), Vector2(42, 369), Vector2(46, 369)]
const DODGE_FX_DURATION := 4.0 / 20.0
const THRUST_DURATION := 0.42
const THRUST_SIZE := 500.0
const AIR_DASH = preload("res://Sprites/effects/air_cut_candidates/dash_sheet.png")
const AIR_THRUST = preload("res://Sprites/effects/air_cut_candidates/thrust_sheet.png")
var caster: Node2D
var facing := 1
var dodge := false
var age := 0.0
var ending := -1.0
var speed: AnimatedSprite2D
var gold: AnimatedSprite2D
var echo_style := false
var thrust: AnimatedSprite2D
var _thrust_start := -1.0

func _ready() -> void:
	# Remain a child of the actor for transforms and relative draw order.
	z_index = -5
	show_behind_parent = true
	process_priority = 100
	echo_style = preload("res://scripts/entities/runeblade_echo_art.gd").active(caster)
	speed = _air_sprite(AIR_DASH) if echo_style else _make_sprite(SPEED_SHEET, 20.0)
	gold = _make_sprite(GOLD_SHEET, 18.0)
	if echo_style and not dodge:
		thrust = _air_sprite(AIR_THRUST)
		thrust.z_index = 0
	update_visual()

func _air_sprite(sheet: Texture2D) -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.set_animation_loop(&"default", false)
	var cell := sheet.get_size() / Vector2(4, 2)
	for i in range(8):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(Vector2(i % 4, i / 4) * cell, cell).grow(-2)
		atlas.filter_clip = true
		frames.add_frame(&"default", atlas)
	var result := AnimatedSprite2D.new()
	result.sprite_frames = frames
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var edge_material := ShaderMaterial.new()
	edge_material.shader = preload("res://Sprites/effects/air_cut_candidates/soft_cell_edge.gdshader")
	result.material = edge_material
	add_child(result)
	return result

func _make_sprite(sheet: Texture2D, fps: float) -> AnimatedSprite2D:
	var animation := SpriteFrames.new()
	animation.set_animation_speed(&"default", fps)
	animation.set_animation_loop(&"default", not dodge)
	for i in range(4):
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		# Exclude the sheet's one-pixel divider while retaining the transparent glow.
		frame.region = Rect2(2 + 768 * (i % 2), 2 + 512 * (i / 2), 764, 508)
		frame.filter_clip = true
		animation.add_frame(&"default", frame)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = animation
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	sprite.play()
	return sprite

func _process(delta: float) -> void:
	age += delta
	if not is_instance_valid(caster) or caster._dead:
		queue_free()
		return
	var moving: bool = caster.is_dodging() and not caster._dodge_wall_stopped if dodge else caster._dash_time > 0.0
	# Dodge gets one four-frame burst, with no loop or extra fade tail.
	if dodge and (age >= DODGE_FX_DURATION or not moving):
		hide()
		queue_free()
		return
	if not moving and ending < 0.0: ending = age
	var thrust_pending: bool = is_instance_valid(thrust) and _thrust_start>=0.0 and age-_thrust_start<THRUST_DURATION
	if ending >= 0.0 and age - ending > 0.12 and not thrust_pending:
		queue_free()
		return
	update_visual()

func update_visual() -> void:
	if not is_instance_valid(caster) or speed == null: return
	var alpha := 1.0 if ending < 0.0 else clampf(1.0 - (age - ending) / 0.12, 0, 1)
	# Synchronize with movement time, including pauses and captured previews.
	var speed_phase := age * 20.0
	var gold_phase := age * 18.0
	speed.set_frame_and_progress(mini(int(speed_phase), 3) if dodge else int(speed_phase) % 4, fposmod(speed_phase, 1.0))
	gold.set_frame_and_progress(int(gold_phase) % 4, fposmod(gold_phase, 1.0))
	speed.offset = -Vector2(80, 100)
	# The dodge pose crouches lower than the standing thrust.
	speed.position = to_local(caster.foot_position() + Vector2(-facing * 8, -190 if dodge else -275))
	speed.scale = Vector2(-facing * (0.32 if dodge else 0.50), 0.48 if dodge else 0.90)
	speed.modulate.a = alpha * 0.85
	if echo_style:
		# Five selected phases keep the dodge brief, including its dissolution.
		var phases := [0, 2, 4, 6, 7]
		speed.frame = phases[clampi(int(age / DODGE_FX_DURATION * 5), 0, 4)]
		speed.visible = dodge and age < DODGE_FX_DURATION
		speed.offset = Vector2.ZERO
		speed.position = to_local(caster.foot_position() + Vector2(-facing * 20, -100))
		speed.scale = Vector2(-facing * 0.72, 0.55)
		speed.modulate.a = 0.7
	if is_instance_valid(thrust):
		var visual = caster.get_node_or_null("EquipVisual")
		var layer = visual._layers.get(Equipment.EquipSlot.WEAPON) if visual != null else null
		var axis: Vector2 = (blade_tip()-layer.global_position).normalized() if is_instance_valid(layer) else Vector2(facing,0)
		# Release on the authored hand pose, not the equipped blade's geometry.
		# Curved/short blades can never satisfy the old 0.97 horizontal-axis test.
		var authored_lunge: bool = caster.sprite.animation == &"Lunge_Runeblade"
		var forward: bool = caster.sprite.frame >= 4 if authored_lunge else (is_instance_valid(layer) and axis.dot(Vector2(facing,0))>0.97 and (blade_tip().x-caster.global_position.x)*facing>80.0)
		if forward and caster._dash_time>0.0 and _thrust_start < 0.0: _thrust_start=age
		preload("res://scripts/entities/runeblade_echo_art.gd").slash_phase(thrust,age-_thrust_start if _thrust_start>=0.0 else -1.0,THRUST_DURATION)
		# Extend the light slightly beyond the equipped tip; tail trails behind.
		if forward:
			# Horizontal thrust pose. Explicit bases preserve mirroring without
			# Node2D's negative-scale/rotation decomposition reversing the light.
			var cell := thrust.sprite_frames.get_frame_texture(&"default",0).get_size()
			var k := THRUST_SIZE / cell.x
			# Pin each painted spearhead to the same point beyond the real blade.
			var tips := [Vector2(0.15,0.60),Vector2(0.07,0.60),Vector2(0.04,0.60),Vector2(0.02,0.60),Vector2(0.07,0.52),Vector2(0.07,0.52),Vector2(0.04,0.52),Vector2(0.06,0.52)]
			thrust.offset = cell * (Vector2(0.5,0.5) - tips[thrust.frame])
			thrust.global_transform = Transform2D(Vector2(-facing*k,0),Vector2(0,k*0.7),blade_tip()+Vector2(facing*45.0,0))
			thrust.modulate.a = 0.85
	gold.visible = not dodge and not echo_style
	if gold.visible:
		gold.offset = -GOLD_ORIGINS[gold.frame]
		gold.position = to_local(blade_tip())
		gold.scale = Vector2(-facing * 0.65, 0.65)
		gold.modulate.a = alpha

func blade_tip() -> Vector2:
	var visual = caster.get_node_or_null("EquipVisual")
	if visual != null:
		var layer = visual._layers.get(Equipment.EquipSlot.WEAPON)
		var item = visual._layer_data.get(Equipment.EquipSlot.WEAPON)
		if is_instance_valid(layer) and layer.visible and item != null and item.equip_texture != null:
			var p: Vector4 = GEOMETRY.POINTS.get(item.equip_texture.resource_path, Vector4.ZERO)
			if p != Vector4.ZERO:
				return layer.to_global(Vector2(p.x, p.y) + layer.offset)
			# Unknown weapon art still follows the hand instead of dropping to hip height.
			return layer.global_position + Vector2(facing * 155,0)
	return caster.foot_position() + Vector2(facing * 155, -105)
