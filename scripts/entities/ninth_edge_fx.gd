extends Node2D
## Procedural energy, not a replacement for the retained character animation.
var facing:=1
var reach:=560.0
var lifetime:=.48
var age:=0.0
var burst:=false
static func spawn(parent:Node,at:Vector2,direction:int,length:float,is_burst:bool=false)->Node2D:
	var fx=load("res://scripts/entities/ninth_edge_fx.gd").new()
	fx.position=at;fx.facing=direction;fx.reach=length;fx.burst=is_burst
	fx.set_meta("ignore_map_bounds",true);parent.add_child(fx);return fx
func _ready()->void:z_index=15
func _process(delta:float)->void:
	age+=delta
	if age>=lifetime:queue_free();return
	queue_redraw()
func _draw()->void:
	var t:=clampf(age/lifetime,0,1)
	var fade:=sin(PI*t)
	var blade:=PackedVector2Array()
	for i in range(33):
		var k:=i/32.0
		blade.append(Vector2(reach*(.12+k*.88)*facing,-75-sin(k*PI)*125))
	for i in range(32,-1,-1):
		var k:=i/32.0
		blade.append(Vector2(reach*(.12+k*.88)*facing,-75-sin(k*PI)*125+sin(k*PI)*23))
	if not burst:draw_colored_polygon(blade,Color(.93,.83,1,fade*.85))
	for j in range(3):
		var pts:=PackedVector2Array()
		for i in range(33):
			var k:=i/32.0
			var x:=reach*(.12+k*.88)
			var y:=-sin(k*PI)*155*(1-j*.16)-20-j*14
			if burst:x=lerpf(-reach,reach,k);y=-sin(k*PI)*230*(1-j*.18)
			pts.append(Vector2(x*facing,y)*(1+t*.08))
		draw_polyline(pts,Color(.47,.25,1,.22*fade),20-j*3,true)
		draw_polyline(pts,Color(.78,.66,1,.85*fade),6-j,true)
		if j==0:draw_polyline(pts,Color(1,.96,1,fade),2.5,true)
	for i in range(18):
		var k:=i/17.0
		var at:=Vector2(reach*(.15+.85*k)*facing,-35-sin(k*PI)*120-90*t)
		if burst:at.x=lerpf(-reach,reach,k)
		draw_line(at,at+Vector2(-10*facing,-10-t*15),Color(.94,.84,1,fade*(1-k*.4)),2,true)
