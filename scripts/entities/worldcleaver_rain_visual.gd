## Independent cosmetic rainfall; never consumes the combat random stream.
extends Node2D
const START_HEIGHT := 585.0
const COUNT := 4
var field: Node2D
var swords: Array[Node2D] = []
var drops: Array[Dictionary] = []
var cosmetic_seed := 0
var echo_style := false
var seals: Array[Sprite2D] = []

func _ready() -> void:
	echo_style = preload("res://scripts/entities/runeblade_echo_art.gd").active(field.caster)
	var rng := RandomNumberGenerator.new()
	if cosmetic_seed == 0: rng.randomize()
	else: rng.seed = cosmetic_seed
	var weapon := PlayerState.equipment.weapon()
	if weapon == null: weapon = ItemInstance.create(&"iron_blade")
	for wave in range(field.pulses):
		# Shuffle horizontal lanes independently of the staggered release order.
		var lanes := range(COUNT)
		for i in range(COUNT - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var temp: int = lanes[i]
			lanes[i] = lanes[j]
			lanes[j] = temp
		for i in range(COUNT):
			var sword := preload("res://scripts/entities/planted_weapon_visual.gd").new()
			sword.configure(weapon, echo_style)
			sword.scale = Vector2.ONE * rng.randf_range(1.10, 1.45)
			sword.modulate = Color(1.35, 1.15, 0.8, 0)
			if echo_style: sword.modulate = Color(1,1,1,0)
			add_child(sword)
			swords.append(sword)
			if echo_style:
				var seal := Sprite2D.new()
				seal.texture = preload("res://scripts/entities/runeblade_echo_art.gd").RUNE
				seal.scale = Vector2(0.34,0.13)
				seal.hide()
				add_child(seal)
				seals.append(seal)
			var x := lerpf(-field.radius * 0.86, field.radius * 0.86, lanes[i] / float(COUNT - 1))
			drops.append({"start": wave * field.interval + i * 0.032 + rng.randf_range(0, 0.018),
				"fall": rng.randf_range(0.13, 0.19), "x": x + rng.randf_range(-32, 32),
				"drift": rng.randf_range(-22, 22)})
	update_visual()

func _process(_delta: float) -> void:
	update_visual()

func update_visual() -> void:
	for i in range(swords.size()):
		var d := drops[i]
		var phase: float = field.elapsed - d.start
		var progress := clampf(phase / d.fall, 0, 1)
		var fade := clampf(1.0 - maxf(0.0, phase - d.fall) / 0.20, 0, 1)
		swords[i].visible = phase >= 0 and phase < d.fall + 0.20
		swords[i].position = Vector2(d.x + d.drift * (1.0 - progress), lerpf(-START_HEIGHT, -8, progress * progress))
		swords[i].modulate.a = fade * clampf(phase / 0.018, 0, 1)
		if echo_style:
			seals[i].visible = phase>=d.fall and phase<d.fall+0.20
			seals[i].position = Vector2(d.x,-3)
			seals[i].modulate.a = fade*0.7
	queue_redraw()

func _draw() -> void:
	if echo_style: return
	for i in range(swords.size()):
		if not swords[i].visible: continue
		var d := drops[i]
		var phase: float = field.elapsed - d.start
		var fade := swords[i].modulate.a
		var tip := swords[i].position
		if phase < d.fall:
			for width in [24.0, 11.0, 3.0]:
				var a := 0.07 if width > 20 else (0.20 if width > 8 else 0.8)
				var tail := tip - Vector2(0, 330)
				draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-width, -105), tail, tip + Vector2(width, -105)]), Color(1, 0.68, 0.20, a * fade))
			for j in range(5):
				var spark := tip + Vector2(sin(i * 4.7 + j * 3.0) * 22, -j * 48 - 18)
				draw_line(spark, spark - Vector2(0, 12), Color(1, 0.89, 0.55, fade * 0.7), 1.5, true)
		else:
			var t := clampf((phase - d.fall) / 0.12, 0, 1)
			var ring := PackedVector2Array()
			for j in range(33):
				var angle := TAU * j / 32.0
				ring.append(Vector2(tip.x + cos(angle) * (12 + t * 65), -5 + sin(angle) * (5 + t * 15)))
			draw_polyline(ring, Color(1, 0.64, 0.18, 1 - t), 3, true)
			draw_line(Vector2(tip.x, 0), Vector2(tip.x, -95 * (1 - t)), Color(1, 0.94, 0.65, (1 - t) * 0.8), 5, true)
			for j in range(5):
				var point := Vector2(tip.x, -5) + Vector2(sin(j * 9 + i) * 65 * t, -100 * sin(t * PI) * (0.5 + j * 0.1))
				draw_line(point, point + Vector2(0, 7), Color(1, 0.79, 0.3, 1 - t), 2, true)
