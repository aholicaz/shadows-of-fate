## แสงฉากผูกกับตำแหน่งในภาพจริง ไม่เปลี่ยนพื้นหรือแสงรวมของแมพ
class_name MapAmbientFX
extends Node2D

@export var lantern_positions: PackedVector2Array = PackedVector2Array()
@export var flame_size := Vector2(20, 42)
@export var light_radius := 190.0
@export var light_energy := 0.22
## เปิดในฉากมืดเพื่อให้โคมส่องทั้งภาพฉากและสิ่งมีชีวิตบน canvas เดียวกัน
@export var light_background := false
@export var shaft_positions: PackedVector2Array = PackedVector2Array()
@export var shaft_size := Vector2(420, 1050)
@export var shaft_angle := 12.0
@export var shaft_color := Color(0.66, 0.81, 1.0, 0.085)
@export var drifting_embers := false
@export var mist_regions: Array[Rect2] = []
@export var mist_color := Color(0.56, 0.65, 0.75, 0.14)
## กรอบในพิกัดแมพ ใช้ mask จากรอยรูนบนภาพฉากจริง
@export var rune_regions: Array[Rect2] = []
@export var rune_warm_ink := false
@export var rune_color := Color(0.35, 0.68, 1.0, 0.4)
@export var rune_unlock_flag: StringName = &""
## หิ่งห้อย / ละอองราก เคลื่อนช้าและหรี่แสงตลอดอายุ ไม่กระพริบพร้อมกัน
@export var mote_regions: Array[Rect2] = []
@export var mote_color := Color(0.55, 0.9, 0.65, 0.6)
@export var mote_drift := Vector2(10, -5)
@export_range(1, 60, 1) var motes_per_region := 16
## แสงชีวภาพจากเห็ดหรือแร่ ไม่มีเปลวไฟสีส้ม
@export var glow_positions: PackedVector2Array = PackedVector2Array()
@export var glow_color := Color(0.42, 0.6, 1.0, 0.3)
@export var glow_radius := 130.0
@export var glow_energy := 0.13
## กรอบภาพน้ำ / ผ้าที่ห้อย / อากาศร้อน ใช้ภาพเดิมเป็นผิว ไม่สร้างแผ่นสีทับ
@export var water_regions: Array[Rect2] = []
@export var wind_regions: Array[Rect2] = []
@export var heat_regions: Array[Rect2] = []

const FLAME_SHADER = preload("res://Sprites/shaders/flame.gdshader")
const SHAFT_SHADER = preload("res://Sprites/shaders/light_shaft.gdshader")
const MIST_SHADER = preload("res://Sprites/shaders/ambient_mist.gdshader")
const RUNE_SHADER = preload("res://Sprites/shaders/rune_glow.gdshader")
const MOTION_SHADER = preload("res://Sprites/shaders/environment_motion.gdshader")
var _lamps: Array[Dictionary] = []
var _runes: Array[Sprite2D] = []
var _glows: Array[Dictionary] = []
var _time := 0.0

func _ready() -> void:
	set_meta("ignore_map_bounds", true)
	var quad := GradientTexture2D.new()
	quad.width = 128
	quad.height = 128
	quad.gradient = Gradient.new()
	var glow := GradientTexture2D.new()
	glow.width = 256
	glow.height = 256
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1.0, 0.5)
	glow.gradient = Gradient.new()
	glow.gradient.offsets = PackedFloat32Array([0, 0.18, 0.5, 1])
	glow.gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.12), Color(1, 1, 1, 0)])
	_build_motes(glow)
	for i in range(glow_positions.size()):
		var halo := Sprite2D.new()
		halo.name = "LivingGlow%d" % i
		halo.texture = glow
		halo.position = glow_positions[i]
		halo.scale = Vector2.ONE * glow_radius * 2.0 / 256.0
		halo.z_index = -39
		halo.modulate = glow_color
		var blend := CanvasItemMaterial.new()
		blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		blend.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		halo.material = blend
		add_child(halo)
		var light := PointLight2D.new()
		light.name = "LivingLight%d" % i
		light.texture = glow
		light.texture_scale = glow_radius * 2.0 / 256.0
		light.position = halo.position
		light.color = Color(glow_color, 1.0)
		light.energy = glow_energy
		light.range_z_min = -100 if light_background else -20
		light.range_z_max = 100
		add_child(light)
		_glows.append({"halo": halo, "light": light, "phase": float(i) * 2.71})
	for i in range(lantern_positions.size()):
		var pos := lantern_positions[i]
		var halo := Sprite2D.new()
		halo.name = "LanternGlow%d" % i
		halo.texture = glow
		halo.position = pos
		halo.scale = Vector2.ONE * light_radius * 2.0 / 256.0
		halo.z_index = -40
		halo.modulate = Color(1.0, 0.42, 0.09, 0.24)
		var blend := CanvasItemMaterial.new()
		blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		blend.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		halo.material = blend
		add_child(halo)
		var flame := _shader_sprite(quad, FLAME_SHADER, flame_size, float(i) * 7.13)
		flame.name = "LanternFlame%d" % i
		flame.position = pos
		flame.z_index = -35
		add_child(flame)
		var light := PointLight2D.new()
		light.name = "LanternLight%d" % i
		light.texture = glow
		light.texture_scale = light_radius * 2.0 / 256.0
		light.position = pos
		light.color = Color(1.0, 0.58, 0.26)
		light.range_z_min = -100 if light_background else -20
		light.range_z_max = 100 if light_background else 20
		light.energy = light_energy
		add_child(light)
		_lamps.append({"halo": halo, "flame": flame, "light": light, "phase": float(i) * 7.13})
		if drifting_embers:
			var embers := CPUParticles2D.new()
			embers.name = "LanternEmbers%d" % i
			embers.position = pos
			embers.z_index = -34
			embers.texture = glow
			embers.material = blend
			embers.amount = 5
			embers.lifetime = 2.4
			embers.preprocess = 2.4
			embers.direction = Vector2.UP
			embers.spread = 22.0
			embers.gravity = Vector2(0, -6)
			embers.initial_velocity_min = 14.0
			embers.initial_velocity_max = 24.0
			embers.scale_amount_min = 0.012
			embers.scale_amount_max = 0.018
			var ramp := Gradient.new()
			ramp.offsets = PackedFloat32Array([0, 0.2, 0.65, 1])
			ramp.colors = PackedColorArray([Color(1, 0.75, 0.3, 0), Color(1, 0.6, 0.15, 0.7), Color(1, 0.4, 0.06, 0.4), Color(1, 0.2, 0.02, 0)])
			embers.color_ramp = ramp
			add_child(embers)
	for i in range(shaft_positions.size()):
		var shaft := _shader_sprite(quad, SHAFT_SHADER, shaft_size, float(i) * 3.7)
		shaft.name = "OverheadShaft%d" % i
		shaft.centered = false
		shaft.offset = Vector2(-64, 0)
		shaft.position = shaft_positions[i]
		shaft.rotation_degrees = shaft_angle
		shaft.modulate = shaft_color
		shaft.z_index = -50
		add_child(shaft)
	for i in range(mist_regions.size()):
		var region := mist_regions[i]
		var mist := _shader_sprite(quad, MIST_SHADER, region.size, float(i) * 9.1)
		mist.name = "DriftingMist%d" % i
		mist.position = region.get_center()
		mist.modulate = mist_color
		mist.z_index = -45
		add_child(mist)
	var sky := get_parent().get_node_or_null("Background/Sky") as Polygon2D
	if sky != null and sky.texture != null:
		_build_surface_motion(sky, water_regions, 0)
		_build_surface_motion(sky, wind_regions, 1)
		_build_surface_motion(sky, heat_regions, 2)
		for i in range(rune_regions.size()):
			var region := rune_regions[i]
			var atlas := AtlasTexture.new()
			atlas.atlas = sky.texture
			atlas.region = Rect2(region.position - sky.position, region.size)
			var rune := Sprite2D.new()
			rune.name = "LivingRune%d" % i
			rune.texture = atlas
			rune.position = region.get_center()
			rune.z_index = -48
			rune.modulate = rune_color
			if rune_unlock_flag != &"" and not PlayerState.has_flag(rune_unlock_flag):
				rune.modulate.a *= 0.15
			var rune_material := ShaderMaterial.new()
			rune_material.shader = RUNE_SHADER
			rune_material.set_shader_parameter("warm_ink", rune_warm_ink)
			rune_material.set_shader_parameter("uv_origin", atlas.region.position / sky.texture.get_size())
			rune_material.set_shader_parameter("uv_size", atlas.region.size / sky.texture.get_size())
			rune_material.set_shader_parameter("phase", float(i) * 2.7)
			rune.material = rune_material
			add_child(rune)
			_runes.append(rune)

func _shader_sprite(quad: Texture2D, shader: Shader, size: Vector2, seed_value: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = quad
	sprite.scale = size / Vector2(quad.get_size())
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("seed", seed_value)
	sprite.material = shader_material
	return sprite

func _process(delta: float) -> void:
	_time += delta
	for glow in _glows:
		var pulse := 0.72 + 0.2 * sin(_time * 1.3 + float(glow.phase)) + 0.08 * sin(_time * 2.7 + float(glow.phase))
		glow.halo.modulate.a = glow_color.a * pulse
		glow.light.energy = glow_energy * pulse
	var rune_strength := 1.0 if rune_unlock_flag == &"" or PlayerState.has_flag(rune_unlock_flag) else 0.15
	for rune in _runes:
		rune.modulate.a = move_toward(rune.modulate.a, rune_color.a * rune_strength, delta * 0.2)
	for lamp in _lamps:
		var p: float = lamp.phase
		var flicker := 0.9 + 0.07 * sin(_time * 6.1 + p) + 0.035 * sin(_time * 10.7 + p * 1.4)
		flicker -= 0.12 * pow(0.5 + 0.5 * sin(_time * 0.83 + p), 12.0)
		lamp.light.energy = light_energy * flicker
		lamp.halo.modulate.a = 0.24 * flicker
		lamp.flame.modulate.a = flicker
		lamp.flame.scale.y = flame_size.y / 128.0 * (0.94 + 0.06 * flicker)

func _build_motes(texture: Texture2D) -> void:
	for i in range(mote_regions.size()):
		var region := mote_regions[i]
		var motes := CPUParticles2D.new()
		motes.name = "DriftingMotes%d" % i
		motes.position = region.get_center()
		motes.z_index = -30
		motes.texture = texture
		var blend := CanvasItemMaterial.new()
		blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		blend.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		motes.material = blend
		motes.amount = motes_per_region
		motes.lifetime = 7.0
		motes.preprocess = 7.0
		motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		motes.emission_rect_extents = region.size * 0.5
		motes.direction = mote_drift.normalized()
		motes.spread = 38.0
		motes.gravity = Vector2.ZERO
		motes.initial_velocity_min = mote_drift.length() * 0.5
		motes.initial_velocity_max = mote_drift.length()
		motes.scale_amount_min = 0.014
		motes.scale_amount_max = 0.034
		var ramp := Gradient.new()
		ramp.offsets = PackedFloat32Array([0, 0.2, 0.48, 0.7, 1])
		ramp.colors = PackedColorArray([Color(mote_color, 0), mote_color, Color(mote_color, mote_color.a * 0.15), mote_color, Color(mote_color, 0)])
		motes.color_ramp = ramp
		add_child(motes)

func _build_surface_motion(sky: Polygon2D, regions: Array[Rect2], kind: int) -> void:
	for i in range(regions.size()):
		var region := regions[i]
		var atlas := AtlasTexture.new()
		atlas.atlas = sky.texture
		atlas.region = Rect2(region.position - sky.position, region.size)
		var surface := Sprite2D.new()
		surface.name = "SurfaceMotion%d_%d" % [kind, i]
		surface.texture = atlas
		surface.position = region.get_center()
		surface.z_index = -60
		var motion := ShaderMaterial.new()
		motion.shader = MOTION_SHADER
		motion.set_shader_parameter("uv_origin", atlas.region.position / sky.texture.get_size())
		motion.set_shader_parameter("uv_size", atlas.region.size / sky.texture.get_size())
		motion.set_shader_parameter("motion_kind", kind)
		motion.set_shader_parameter("phase", float(i) * 3.4)
		surface.material = motion
		add_child(surface)
