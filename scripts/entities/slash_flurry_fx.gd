## Cosmetic frame-driven flashes. Never queries targets or applies damage.
extends Node

const ART = preload("res://data/sprites/fx_rending_wave.tres")
# The dedicated Slash sheet cuts at source cells 7, 11, 15, 18 and 22.
# Its animation starts at source cell 5.
const CUT_FRAMES = [2, 6, 10, 13, 17]
const ANGLES = [15.0, 75.0, 45.0, -10.0, 100.0]
const OFFSETS = [Vector2(75, -125), Vector2(95, -100), Vector2(80, -115), Vector2(90, -135), Vector2(100, -110)]
var caster: Node2D
var body: AnimatedSprite2D
var animation: StringName
var direction := 1
var next_cut := 0
var emitted := 0

static func spawn(player: Node2D, sprite: AnimatedSprite2D, facing: int) -> Node:
	var fx = load("res://scripts/entities/slash_flurry_fx.gd").new()
	fx.caster = player
	fx.body = sprite
	fx.animation = sprite.animation
	fx.direction = -1 if facing < 0 else 1
	player.add_child(fx)
	return fx

func _process(_delta: float) -> void:
	if not is_instance_valid(caster) or not is_instance_valid(body):
		queue_free()
		return
	if caster.get("_dead") or not caster.get("is_attacking") or body.animation != animation:
		queue_free()
		return
	var count := body.sprite_frames.get_frame_count(animation)
	for i in range(next_cut, CUT_FRAMES.size()):
		var trigger: int = CUT_FRAMES[i] if count >= 22 and String(animation).to_lower().ends_with("_slash") else roundi(float(count - 1) * (0.12 + i * 0.17))
		if body.frame < trigger:
			break
		burst(i)
		next_cut = i + 1
	if next_cut == CUT_FRAMES.size():
		queue_free()

func burst(index: int) -> void:
	var root := Node2D.new()
	root.name = "SlashGoldCut"
	root.z_index = 61
	caster.get_parent().add_child(root)
	root.add_to_group("slash_gold_flashes")
	var foot: Vector2 = caster.foot_position()
	root.global_position = foot + Vector2(OFFSETS[index].x * direction, OFFSETS[index].y)
	# Mirror the complete slash, including rotation and the short motion trail.
	root.scale.x = -direction
	var art := AnimatedSprite2D.new()
	art.sprite_frames = ART
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art.rotation_degrees = ANGLES[index]
	art.scale = Vector2(0.62, 0.40) * (1.15 if index == 4 else 1.0)
	root.add_child(art)
	art.play(&"wave", 3.2)
	art.frame = index % 3
	art.modulate.a = 0.0
	var fade := root.create_tween()
	fade.tween_property(art, "modulate:a", 0.95, 0.018)
	fade.tween_property(art, "modulate:a", 0.0, 0.14)
	fade.tween_callback(root.queue_free)
	var drift := root.create_tween()
	var motion := Vector2(-24, 24).rotated(deg_to_rad(ANGLES[index]))
	drift.tween_property(art, "position", motion, 0.158)
	emitted += 1
