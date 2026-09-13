## Animated imagegen speed ribbons and golden thrust, behind the entire character.
extends Node2D
const GEOMETRY = preload("res://scripts/entities/weapon_blade_geometry.gd")
const SPEED_SHEET = preload("res://Sprites/effects/dash_silver_speed_sheet.png")
const GOLD_SHEET = preload("res://Sprites/effects/dash_gold_thrust_sheet.png")
const GOLD_ORIGINS = [Vector2(60, 370), Vector2(38, 370), Vector2(42, 369), Vector2(46, 369)]
const DODGE_FX_DURATION := 4.0 / 20.0
var caster: Node2D
var facing := 1
var dodge := false
var age := 0.0
var ending := -1.0
var speed: AnimatedSprite2D
var gold: AnimatedSprite2D

func _ready() -> void:
	# Remain a child of the actor for transforms and relative draw order.
	z_index = -5
	show_behind_parent = true
	process_priority = 100
	speed = _make_sprite(SPEED_SHEET, 20.0)
	gold = _make_sprite(GOLD_SHEET, 18.0)
	update_visual()

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
	if ending >= 0.0 and age - ending > 0.12:
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
	gold.visible = not dodge
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
	return caster.foot_position() + Vector2(facing * 155, -105)
