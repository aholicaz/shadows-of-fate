## Eight outward gold rays, using the same painted light as the player's skills.
## Cosmetic only; the burst survives the target's death and consumes no combat RNG.
extends Node2D

const ART = preload("res://data/sprites/fx_rending_wave.tres")

static func spawn(target: Node2D) -> Node2D:
	var burst = load("res://scripts/entities/critical_burst_fx.gd").new()
	burst.name = "CriticalGoldBurst"
	target.get_parent().add_child(burst)
	burst.add_to_group("critical_gold_bursts")
	var bounds: Rect2 = target.body_rect()
	burst.global_position = bounds.get_center()
	burst.z_index = 59
	burst.build(clampf(maxf(bounds.size.x, bounds.size.y) / 170.0, 0.75, 1.6))
	return burst

func build(size_factor: float) -> void:
	for i in range(8):
		var ray := Node2D.new()
		ray.rotation = TAU * float(i) / 8.0 + deg_to_rad(22.5)
		ray.scale.y = 0.65
		add_child(ray)
		var light := Sprite2D.new()
		light.texture = ART.get_frame_texture(&"wave", i % 3)
		light.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		# Point the sharp tip inward (-X), while the burst travels outward (+X).
		light.rotation_degrees = 45.0
		light.scale = Vector2.ONE * 0.24 * size_factor
		light.position.x = 28.0 * size_factor
		light.modulate.a = 0.0
		ray.add_child(light)
		var flight := create_tween()
		flight.set_parallel(true)
		flight.tween_property(light, "position:x", (135.0 if i % 2 == 0 else 112.0) * size_factor, 0.23).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flight.tween_property(light, "scale", light.scale * 0.5, 0.23)
		var fade := create_tween()
		fade.tween_property(light, "modulate:a", 1.0, 0.022)
		fade.tween_property(light, "modulate:a", 0.0, 0.208)
	var cleanup := create_tween()
	cleanup.tween_interval(0.25)
	cleanup.tween_callback(queue_free)
