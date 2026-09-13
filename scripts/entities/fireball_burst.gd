extends Node2D
## Short-lived native canvas glow and sparks at the hand or impact point.
var age := 0.0
var duration := .35
var radius := 45.0
var facing := 1
var impact := false

static func spawn(parent: Node, at: Vector2, direction: int, hit: bool = false) -> Node2D:
	var fx = load("res://scripts/entities/fireball_burst.gd").new()
	fx.facing = direction
	fx.impact = hit
	fx.radius = 68.0 if hit else 40.0
	fx.duration = .42 if hit else .24
	parent.add_child(fx)
	fx.global_position = at
	fx.z_index = 72
	return fx

func _process(delta: float) -> void:
	age += delta
	if age >= duration: queue_free()
	else: queue_redraw()

func _draw() -> void:
	var u := clampf(age/duration,0.0,1.0)
	var fade := pow(1.0-u,2.0)
	for i in range(12,0,-1):
		var ring := float(i)/12.0
		draw_circle(Vector2.ZERO,radius*ring*(.4+u),Color(1.0,.24+.45*(1.0-ring),.04,.035*fade))
	draw_circle(Vector2.ZERO,radius*.15*(1.0-u),Color(1.0,.93,.56,.85*fade))
	for i in range(12):
		var angle := float(i)*2.39996
		var dir := Vector2(cos(angle),sin(angle))
		if not impact: dir = (dir*.6+Vector2(facing,0)).normalized()
		var speed := radius*(.6+float(i%4)*.22)
		var at := dir*speed*u + Vector2(0,18.0*u*u)
		draw_line(at-dir*(7.0+8.0*u),at,Color(1.0,.48+.035*(i%5),.07,fade),2.0*(1.0-u)+.5,true)
