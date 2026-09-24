extends Node2D
var caster: Node2D
var direction := 1
var skill: SkillData
var level := 1
var elapsed := 0.0
var hit: Dictionary = {}
var reach := 1260.0
var art: Sprite2D

func _ready() -> void:
	art = Sprite2D.new()
	art.texture = preload("res://Sprites/effects/jump_slash/ground_cut.png")
	art.hframes = 6
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(art)
	art.scale = Vector2(direction * 2.7, 3.0)
	# Atlas content occupies the lower half of each cell.
	art.position = Vector2(direction * 540.0, -300.0)
	z_index = 8

func _physics_process(delta: float) -> void:
	if not is_instance_valid(caster) or not caster.is_inside_tree() or caster._dead:
		queue_free()
		return
	elapsed += delta
	art.frame = mini(5, int(elapsed * 9.0))
	var query := PhysicsRayQueryParameters2D.create(global_position - Vector2(0, 70), global_position + Vector2(direction * skill.range_x, -70), 1)
	var wall := get_world_2d().direct_space_state.intersect_ray(query)
	reach = skill.range_x if wall.is_empty() else maxf(0.0, absf(wall.position.x-global_position.x)-8.0)
	var front := reach * minf(1.0, elapsed / 0.20)
	art.scale.x = direction * 2.7 * reach / skill.range_x
	art.position.x = direction * 540.0 * reach / skill.range_x
	var box := Rect2(Vector2(global_position.x if direction > 0 else global_position.x-front, global_position.y-skill.range_y), Vector2(front, skill.range_y+20))
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if hit.size() >= skill.max_targets_at(level): break
		if hit.has(enemy.get_instance_id()) or not enemy.has_method("take_damage_from_player"): continue
		if enemy.has_method("is_dead") and enemy.is_dead(): continue
		if not box.intersects(caster.enemy_rect(enemy)): continue
		hit[enemy.get_instance_id()] = true
		enemy.take_damage_from_player(skill.damage_mult(level), false, direction, 0.0, 0.0, &"jump_slash")
	if elapsed >= 0.67: queue_free()
