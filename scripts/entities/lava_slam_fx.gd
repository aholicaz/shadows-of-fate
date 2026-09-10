## ลาวาระเบิดที่พื้น: ภาพอย่างเดียว ดาเมจออกครั้งเดียวจาก MonsterBase ต่อการทุบ
class_name LavaSlamFX
extends Node2D

var radius := 210.0
var empowered := false
var age := 0.0
var lifetime := 0.85
var fragments: Array[Dictionary] = []
var lamp: PointLight2D
var ground_material: ShaderMaterial

static func spawn(parent: Node, at: Vector2, reach: float, skill: bool, index: int) -> LavaSlamFX:
	var fx := LavaSlamFX.new()
	fx.radius = reach
	fx.empowered = skill
	fx.position = at
	fx.set_meta("ignore_map_bounds", true)
	fx.set_meta("hit_index", index)
	parent.add_child(fx)
	return fx

func _ready() -> void:
	z_index = 12
	add_to_group("lava_slam_fx")
	var ground := Sprite2D.new()
	var quad := GradientTexture2D.new()
	quad.width = 128
	quad.height = 128
	quad.gradient = Gradient.new()
	ground.texture = quad
	ground.scale = Vector2(radius * 2.25, minf(100.0, radius * 0.25)) / 128.0
	ground.z_index = -1
	ground_material = ShaderMaterial.new()
	ground_material.shader = preload("res://Sprites/shaders/lava_slam.gdshader")
	ground_material.set_shader_parameter("seed", float(get_meta("hit_index", 0)) * 3.7)
	ground.material = ground_material
	add_child(ground)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7319 + int(get_meta("hit_index", 0)) * 193 + int(position.x)
	for i in range(65 if empowered else 38):
		fragments.append({"x": rng.randf_range(-radius * 0.8, radius * 0.8), "vx": rng.randf_range(-radius, radius) * 0.35,
			"vy": rng.randf_range(-35, 35), "lift": rng.randf_range(120, 360) * (1.2 if empowered else 1.0),
			"size": rng.randf_range(2.5, 8.5), "phase": rng.randf_range(0, TAU), "rock": i % 4 == 0})
	var glow := GradientTexture2D.new()
	glow.width = 128
	glow.height = 128
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1, 0.5)
	glow.gradient = Gradient.new()
	glow.gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	lamp = PointLight2D.new()
	lamp.texture = glow
	lamp.color = Color(1, 0.36, 0.055)
	lamp.texture_scale = radius * 2.4 / 128.0
	lamp.position.y = -45
	lamp.energy = 1.5
	add_child(lamp)

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	lamp.energy = 1.5 * pow(1.0 - age / lifetime, 2)
	ground_material.set_shader_parameter("age", age)
	queue_redraw()

func _draw() -> void:
	var t := age / lifetime
	var fade := pow(1.0 - t, 1.4)
	# Ballistic lava droplets with hot centers and dark rock fragments.
	for f in fragments:
		var delay := absf(float(f.x)) / radius * 0.12
		var flight := age - delay
		if flight < 0:
			continue
		var p := Vector2(float(f.x) + float(f.vx) * flight, float(f.vy) * flight - float(f.lift) * flight + 420.0 * flight * flight)
		if p.y > 14.0:
			continue
		var size: float = float(f.size) * (1.0 - t * 0.65)
		if f.rock:
			var rock := PackedVector2Array()
			for j in range(5):
				var a := TAU * j / 5.0 + float(f.phase) + age * 5.0
				rock.append(p + Vector2(cos(a), sin(a)) * size)
			draw_colored_polygon(rock, Color(0.12, 0.065, 0.04, fade))
			draw_line(rock[0], rock[2], Color(1, 0.33, 0.02, fade), 1.5, true)
		else:
			var trail := Vector2(float(f.vx), float(f.vy) - float(f.lift) + 840.0 * age).normalized()
			draw_line(p - trail * size * 3.0, p, Color(1, 0.17, 0.005, fade * 0.75), size * 1.5, true)
			draw_circle(p, size, Color(1, 0.37, 0.015, fade))
			draw_circle(p, size * 0.48, Color(1, 0.94, 0.49, fade))
	# Brief impact flare, no persistent full-screen flash.
	if age < 0.14:
		var flash := 1.0 - age / 0.14
		for i in range(9):
			var a := PI + PI * i / 8.0
			var tip := Vector2(cos(a) * 65, sin(a) * 110) * (1.0 - flash * 0.4)
			draw_colored_polygon(PackedVector2Array([Vector2(-10, 0), tip, Vector2(10, 0)]), Color(1, 0.68, 0.13, flash))
