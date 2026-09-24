## Painted eight-frame critical sparkle; no sound, damage, or combat RNG.
extends Node2D
const ART = preload("res://scripts/entities/runeblade_echo_art.gd")
const DURATION := 0.28
var sprite: AnimatedSprite2D
var age := 0.0

static func spawn(target: Node2D) -> Node2D:
	var burst = load("res://scripts/entities/critical_burst_fx.gd").new()
	burst.name = "CriticalSilverSparkle"
	target.get_parent().add_child(burst)
	burst.add_to_group("critical_gold_bursts")
	var bounds: Rect2 = target.body_rect()
	burst.global_position = bounds.get_center()
	burst.z_index = 59
	burst.build(clampf(maxf(bounds.size.x,bounds.size.y)/170.0,0.75,1.6))
	return burst

func build(size_factor: float) -> void:
	# User-selected sheet has wider frame coverage; preserve the on-monster size.
	sprite = ART.slash_sprite(210.0*size_factor,-1,"critical")
	add_child(sprite)
	ART.slash_phase(sprite,0,DURATION)

func _process(delta: float) -> void:
	age += delta
	if age>=DURATION:
		queue_free()
		return
	if is_instance_valid(sprite): ART.slash_phase(sprite,age,DURATION)
