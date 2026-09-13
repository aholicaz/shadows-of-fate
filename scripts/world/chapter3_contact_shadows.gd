@tool
extends Node2D
## World-space contact patches, baked from each prop's opaque foot silhouette.
@export var patches: Array[Rect2] = []
@export var tint := Color(0.055, 0.045, 0.03, 0.18)
func _draw() -> void:
	for patch in patches:
		for ring in range(6):
			var shrink := 1.0-float(ring)*0.11
			draw_set_transform(patch.get_center(),0,patch.size*0.5*shrink)
			draw_circle(Vector2.ZERO,1.0,Color(tint,tint.a/4.0))
	draw_set_transform(Vector2.ZERO)
