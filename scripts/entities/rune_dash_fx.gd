## Standalone procedural effect; replace its drawing with an AnimatedSprite2D later.
extends Node2D
var caster: Node2D
var facing := 1
var age := 0.0
var trail: Array[Vector2] = []

func _ready() -> void:
	set_as_top_level(true)
	global_position = Vector2.ZERO
	z_index = 65

func _process(delta: float) -> void:
	age += delta
	if not is_instance_valid(caster) or caster._dead or age > 0.55:
		queue_free()
		return
	trail.append(caster.foot_position() - Vector2(0, 105))
	if trail.size() > 14: trail.pop_front()
	queue_redraw()

func _draw() -> void:
	if trail.is_empty(): return
	var alpha := clampf((0.55-age)/0.18,0,1)
	var tip: Vector2 = trail.back()
	for i in range(1, trail.size()):
		var c := Color("#63ddff")
		c.a = alpha * i / trail.size() * 0.6
		for offset in [-40,0,40]:
			draw_line(trail[i-1]+Vector2(0,offset),trail[i]+Vector2(0,offset),c,5,true)
	var points := PackedVector2Array([tip+Vector2(facing*170,0),tip+Vector2(facing*80,-23),tip+Vector2(-facing*55,0),tip+Vector2(facing*80,23)])
	draw_colored_polygon(points,Color(0.45,0.87,1,alpha*0.7))
	draw_line(tip+Vector2(-facing*65,0),tip+Vector2(facing*170,0),Color(1,1,1,alpha),3,true)
