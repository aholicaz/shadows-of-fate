extends Node2D
## World-space, fixed danger area. Its outline matches the damage footprint.
var radius := 450.0
var duration := 1.35
var elapsed := 0.0
func _ready() -> void:
	z_index=1
	set_meta("ignore_map_bounds",true)
func _process(delta: float) -> void:
	elapsed+=delta;queue_redraw()
func _draw() -> void:
	var points:=PackedVector2Array()
	for i in 65:
		var a:=TAU*i/64.0
		points.append(Vector2(cos(a)*radius,sin(a)*38))
	draw_colored_polygon(points,Color(1,.18,.035,.12+.12*minf(elapsed/duration,1)))
	draw_polyline(points,Color(1,.55,.16,.9),3,true)
	for x in [-radius,radius]:draw_line(Vector2(x,-18),Vector2(x,18),Color(1,.8,.35),4,true)
	var pulse:=PackedVector2Array()
	for p in points:pulse.append(p*clampf(elapsed/duration,0,1))
	draw_polyline(pulse,Color(1,.85,.45,.8),2,true)
