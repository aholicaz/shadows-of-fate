extends Node2D
## Eight painted silhouettes, timed independently of body pose and damage.
const ART = preload("res://scripts/entities/runeblade_echo_art.gd")
var caster: Node2D
var direction := 1
var reach := 230.0
var index := 0
var style := "combo1"
var delay := 0.0
var follow := false
var follow_offset := Vector2.ZERO
var age := 0.0
var lifetime := 0.20
var seq := -1
var stroke: AnimatedSprite2D

func _ready() -> void:
	z_index = caster.z_index + 5 if style.begins_with("combo") else 0
	seq = caster._attack_seq if is_instance_valid(caster) else -1
	stroke = ART.slash_sprite(reach, direction, style)
	# Ground-cleave art travels from upper-left to lower-right in its source.
	# Mirror oppositely to open crescents so the cut travels away from the caster.
	if style == "slam": stroke.scale.x *= -1.0
	# Fixed swing plane; motion comes from eight changing drawings.
	stroke.rotation = direction * ([-0.55, 0.4, 0.0][posmod(index, 3)] if style.begins_with("combo") else 0.0)
	if style == "flurry": stroke.rotation = direction * [-0.5, 0.45, 0.0][posmod(index,3)]
	add_child(stroke)
	update_visual()

func _process(delta: float) -> void:
	if not is_instance_valid(caster) or caster._dead:
		queue_free()
		return
	if age < delay and (caster._attack_seq != seq or not caster.is_attacking):
		queue_free()
		return
	age += delta
	if age >= delay + lifetime:
		queue_free()
		return
	if follow: global_position = caster.global_position + follow_offset
	update_visual()

func update_visual() -> void:
	visible = age >= delay
	ART.slash_phase(stroke, age - delay, lifetime)
